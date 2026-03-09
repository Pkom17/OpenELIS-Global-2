package org.openelisglobal.dataexchange.service.order;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Tuple;
import javax.persistence.TupleElement;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service pour lire/écrire dans la table plate vl_eorder_request_flat
 * via des requêtes SQL natives. Cette table est gérée par oedatauploader
 * et partagée dans le même schéma clinlims.
 */
@Service
public class EorderFlatQueryService {

	@PersistenceContext
	private EntityManager entityManager;

	/**
	 * Lit un enregistrement de la table plate par request_uuid.
	 * @return Map des colonnes ou null si non trouvé
	 */
	public Map<String, Object> findByRequestUuid(String requestUuid) {
		if (requestUuid == null || requestUuid.isBlank()) {
			return null;
		}

		String sql = "SELECT * FROM clinlims.vl_eorder_request_flat WHERE request_uuid = :uuid";

		@SuppressWarnings("unchecked")
		List<Tuple> results = entityManager.createNativeQuery(sql, Tuple.class)
				.setParameter("uuid", requestUuid)
				.getResultList();

		if (results.isEmpty()) {
			return null;
		}

		Tuple tuple = results.get(0);
		Map<String, Object> map = new HashMap<>();
		for (TupleElement<?> element : tuple.getElements()) {
			map.put(element.getAlias(), tuple.get(element.getAlias()));
		}
		return map;
	}

	/**
	 * Recherche une demande électronique par code patient et date de prélèvement approximative (± 2 jours).
	 * Cherche dans patient_code et patient_subject_number.
	 * Ne retourne que les demandes au statut "entered" (pas encore traitées dans OE).
	 * @return request_uuid de la demande la plus récente, ou null si non trouvée
	 */
	public String findByPatientAndCollectionDate(String patientCode, String collectionDate) {
		if (patientCode == null || patientCode.isBlank()
				|| collectionDate == null || collectionDate.isBlank()) {
			return null;
		}

		// Convertir dd/MM/yyyy en java.sql.Date
		LocalDate parsedDate;
		try {
			parsedDate = LocalDate.parse(collectionDate, DateTimeFormatter.ofPattern("dd/MM/yyyy"));
		} catch (DateTimeParseException e) {
			return null;
		}
		java.sql.Date sqlDate = java.sql.Date.valueOf(parsedDate);

		String sql = "SELECT f.request_uuid FROM clinlims.vl_eorder_request_flat f "
				+ "JOIN clinlims.electronic_order eo ON eo.external_id = f.request_uuid "
				+ "JOIN clinlims.status_of_sample sos ON sos.id = CAST(eo.status_id AS INTEGER) "
				+ "WHERE (lower(f.patient_code) = lower(:patientCode) "
				+ "   OR lower(f.patient_subject_number) = lower(:patientCode)) "
				+ "AND lower(sos.name) = 'entered' AND sos.status_type = 'EXTERNAL_ORDER' "
				+ "AND f.collection_date BETWEEN (CAST(:collDate AS DATE) - INTERVAL '2 days') "
				+ "AND (CAST(:collDate AS DATE) + INTERVAL '2 days') ";

		sql += "ORDER BY f.created_at DESC";

		var query = entityManager.createNativeQuery(sql)
				.setParameter("patientCode", patientCode)
				.setParameter("collDate", sqlDate);

		query.setMaxResults(1);

		@SuppressWarnings("unchecked")
		List<String> results = query.getResultList();
		return results.isEmpty() ? null : results.get(0);
	}

	/**
	 * Met à jour le statut local et les champs de rejet dans la table plate.
	 * Le trigger PostgreSQL sur local_status va marquer sync_flag=2
	 * pour déclencher la remontée vers le serveur consolidé.
	 */
	@Transactional
	public void updateLocalStatus(String requestUuid, String localStatus,
			String rejectReason, String rejectComment, String rejectAuthor) {
		if (requestUuid == null || requestUuid.isBlank()) {
			return;
		}

		String sql = "UPDATE clinlims.vl_eorder_request_flat SET " +
				"local_status = :status, " +
				"reject_reason = :reason, " +
				"reject_comment = :comment, " +
				"reject_author = :author, " +
				"updated_at = now() " +
				"WHERE request_uuid = :uuid";

		entityManager.createNativeQuery(sql)
				.setParameter("status", localStatus)
				.setParameter("reason", rejectReason)
				.setParameter("comment", rejectComment)
				.setParameter("author", rejectAuthor)
				.setParameter("uuid", requestUuid)
				.executeUpdate();
	}
}
