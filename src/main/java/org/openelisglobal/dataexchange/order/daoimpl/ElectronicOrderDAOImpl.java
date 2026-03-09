/**
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations under
 * the License.
 *
 * The Original Code is OpenELIS code.
 *
 * Copyright (C) ITECH, University of Washington, Seattle WA.  All Rights Reserved.
 *
 */
package org.openelisglobal.dataexchange.order.daoimpl;

import java.sql.Date;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import javax.persistence.Tuple;

import org.apache.commons.validator.GenericValidator;
import org.hibernate.HibernateException;
import org.hibernate.Session;
import org.hibernate.query.Query;
import org.openelisglobal.common.daoimpl.BaseDAOImpl;
import org.openelisglobal.common.exception.LIMSRuntimeException;
import org.openelisglobal.common.util.DateUtil;
import org.openelisglobal.dataexchange.order.dao.ElectronicOrderDAO;
import org.openelisglobal.dataexchange.order.valueholder.VlOrderDisplayItem;
import org.openelisglobal.dataexchange.order.valueholder.ElectronicOrder;
import org.openelisglobal.dataexchange.order.valueholder.ElectronicOrder.SortOrder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@Transactional
public class ElectronicOrderDAOImpl extends BaseDAOImpl<ElectronicOrder, String> implements ElectronicOrderDAO {

	public ElectronicOrderDAOImpl() {
		super(ElectronicOrder.class);
	}

	@Override
	@Transactional(readOnly = true)
	public List<ElectronicOrder> getElectronicOrdersByExternalId(String id) throws LIMSRuntimeException {
		if (GenericValidator.isBlankOrNull(id)) {
			return new ArrayList<>();
		}
		String sql = "from ElectronicOrder eo where eo.externalId = :externalid order by id";

		try {
			Query<ElectronicOrder> query = entityManager.unwrap(Session.class).createQuery(sql, ElectronicOrder.class);
			query.setParameter("externalid", id);

			List<ElectronicOrder> eOrders = query.list();
			return eOrders;
		} catch (HibernateException e) {
			handleException(e, "getElectronicOrderByExternalId");
		}
		return null;
	}

	@Override
	@Transactional(readOnly = true)
	public List<ElectronicOrder> getAllElectronicOrdersOrderedBy(SortOrder order) {
		List<ElectronicOrder> list = new Vector<>();
		try {
			if (order.equals(ElectronicOrder.SortOrder.LAST_UPDATED_DESC)) {
				String sql = "from ElectronicOrder eo order by lastupdated desc";
				list = entityManager.unwrap(Session.class).createQuery(sql, ElectronicOrder.class).list();
			} else {
				String sql = "from ElectronicOrder eo order by " + order.getValue() + "asc, lastupdated desc";
				list = entityManager.unwrap(Session.class).createQuery(sql, ElectronicOrder.class).list();
			}
		} catch (RuntimeException e) {
			handleException(e, "getAllElectronicOrdersOrderedBy");
		}

		return list;
	}

	@Override
	public List<ElectronicOrder> getAllElectronicOrdersContainingValueOrderedBy(String searchValue, SortOrder order) {

		String sql = "from ElectronicOrder eo " + "join eo.patient patient " + "join patient.person person  "
				+ "where lower(eo.data) like concat('%', lower(:searchValue), '%') "
				+ "or lower(person.firstName) like concat('%', lower(:searchValue), '%') "
				+ "or lower(person.lastName) like concat('%', lower(:searchValue), '%') "
				+ "or patient.id in (SELECT identity.patientId FROM PatientIdentity identity WHERE identity.identityData like concat('%', :searchValue, '%')) "
				+ "or patient.nationalId like concat('%', :searchValue, '%') "
				+ "or lower(concat(person.firstName, ' ', person.lastName)) like concat('%', lower(:searchValue), '%') order by ";

		switch (order.getValue()) {
		case "statusId":
			sql = sql + "eo.statusId asc";
			break;
		case "lastupdatedasc":
			sql = sql + "eo.statusId asc, eo.lastupdated asc";
			break;
		case "lastupdateddesc":
			sql = sql + "eo.statusId asc, eo.lastupdated desc";
			break;
		case "externalId":
			sql = sql + "eo.externalId asc";
			break;
		case "orderTimestampdesc":
			sql = sql + "eo.statusId asc, eo.orderTimestamp desc";
			break;
		default:
			//
			break;
		}
		try {

			Query query = entityManager.unwrap(Session.class).createQuery(sql);
			query.setParameter("searchValue", searchValue);
			// query.setParameter("order", order.getValue());
			List records = query.list();
			List<ElectronicOrder> eOrders = new ArrayList<>();
			for (int i = 0; i < records.size(); i++) {
				Object[] oArray = (Object[]) records.get(i);
				ElectronicOrder eo = (ElectronicOrder) oArray[0];
				eOrders.add(eo);
			}
			return eOrders;
		} catch (HibernateException e) {
			handleException(e, "getAllElectronicOrdersContainingValue");
		}
		return null;
	}

	@Override
	public List<ElectronicOrder> getAllElectronicOrdersMatchingAnyValue(List<String> identifierValues,
			String patientValue, SortOrder order) {

		String hql = "from ElectronicOrder eo " + "join eo.patient patient " + "join patient.person person "
				+ "where lower(eo.externalId) in (:identifierValues) "
				+ "or lower(person.firstName) = lower(:patientValue) "
				+ "or lower(person.lastName) = lower(:patientValue) "
				+ "or patient.id in (SELECT identity.patientId FROM PatientIdentity identity WHERE lower(identity.identityData) = lower(:patientValue)) "
				+ "or lower(patient.nationalId) = lower(:patientValue) "
				+ "or lower(concat(person.firstName, ' ', person.lastName)) = lower(:patientValue) order by ";

		switch (order.getValue()) {
		case "statusId":
			hql = hql + "eo.statusId asc";
			break;
		case "lastupdatedasc":
			hql = hql + "eo.statusId asc, eo.lastupdated asc";
			break;
		case "lastupdateddesc":
			hql = hql + "eo.statusId asc, eo.lastupdated desc";
			break;
		case "externalId":
			hql = hql + "eo.externalId asc";
			break;
		case "orderTimestampdesc":
			hql = hql + "eo.statusId asc, eo.orderTimestamp desc";
			break;
		default:
			//
			break;
		}
		try {

			Query<?> query = entityManager.unwrap(Session.class).createQuery(hql);
			query.setParameterList("identifierValues", identifierValues);
			query.setParameter("patientValue", patientValue);
			// query.setParameter("order", order.getValue());
			List<?> records = query.list();
			List<ElectronicOrder> eOrders = new ArrayList<>();
			for (int i = 0; i < records.size(); i++) {
				Object[] oArray = (Object[]) records.get(i);
				ElectronicOrder eo = (ElectronicOrder) oArray[0];
				eOrders.add(eo);
			}
			return eOrders;
		} catch (HibernateException e) {
			handleException(e, "getAllElectronicOrdersMatchingAnyValue");
		}
		return null;
	}

	@Override
	public List<ElectronicOrder> getElectronicOrdersContainingValueExludedByOrderedBy(String searchValue,
			List<Integer> excludedStatuses, SortOrder sortOrder) {

		String sql = "from ElectronicOrder eo " + "join eo.patient patient " + "join patient.person person  "
				+ "where lower(eo.data) like concat('%', lower(:searchValue), '%') "
				+ "or lower(person.firstName) like concat('%', lower(:searchValue), '%') "
				+ "or lower(person.lastName) like concat('%', lower(:searchValue), '%') "
				+ "or lower(concat(person.firstName, ' ', person.lastName)) like concat('%', lower(:searchValue), '%')"
				+ "or patient.id in (SELECT identity.patientId FROM PatientIdentity identity WHERE identity.identityData like concat('%', :searchValue, '%')) "
				+ "or patient.nationalId like concat('%', :searchValue, '%') "
				+ "and eo.statusId not in (:excludedStatuses) order by ";

		switch (sortOrder) {
		case STATUS_ID:
			sql = sql + "eo.statusId asc";
			break;
		case LAST_UPDATED_ASC:
			sql = sql + "eo.statusId asc, eo.lastupdated asc";
			break;
		case LAST_UPDATED_DESC:
			sql = sql + "eo.statusId asc, eo.lastupdated desc";
			break;
		case EXTERNAL_ID:
			sql = sql + "eo.externalId asc";
			break;
		case RECEPTION_DATE:
			sql = sql + "eo.statusId asc, eo.orderTimestamp desc";
			break;
		default:
			//
			break;
		}
		try {

			Query<?> query = entityManager.unwrap(Session.class).createQuery(sql);
			query.setParameter("searchValue", searchValue);
			query.setParameter("excludedStatuses", excludedStatuses);
			// query.setParameter("order", order.getValue());
			List<?> records = query.list();
			List<ElectronicOrder> eOrders = new ArrayList<>();
			for (int i = 0; i < records.size(); i++) {
				Object[] oArray = (Object[]) records.get(i);
				ElectronicOrder eo = (ElectronicOrder) oArray[0];
				eOrders.add(eo);
			}
			return eOrders;
		} catch (HibernateException e) {
			handleException(e, "getAllElectronicOrdersContainingValue");
		}
		return null;
	}

	@Override
	public List<ElectronicOrder> getAllElectronicOrdersContainingValuesOrderedBy(String accessionNumber,
			String patientLastName, String patientFirstName, String gender, SortOrder order) {
		String sql = "from ElectronicOrder eo " + "join eo.patient patient " + "join patient.person person  ";
		boolean whereClauseStarted = false;
		if (!GenericValidator.isBlankOrNull(accessionNumber)) {
			sql += getWherePrefix(whereClauseStarted)
					+ " lower(eo.data) like concat('%', lower(:accessionNumber), '%') ";
			whereClauseStarted = true;
		}
//        if (!GenericValidator.isBlankOrNull(patientId)) {
//            sql += getWherePrefix(whereClauseStarted) + "and lower(eo.data) like concat('%', lower(:patientId), '%') ";
//     }
		if (!GenericValidator.isBlankOrNull(patientLastName)) {
			sql += getWherePrefix(whereClauseStarted)
					+ " lower(person.lastName) like concat('%', lower(:patientLastName), '%') ";
			whereClauseStarted = true;
		}
		if (!GenericValidator.isBlankOrNull(patientFirstName)) {
			sql += getWherePrefix(whereClauseStarted)
					+ " lower(person.firstName) like concat('%', lower(:patientFirstName), '%') ";
			whereClauseStarted = true;
		}
//        if (!GenericValidator.isBlankOrNull(dateOfBirth)) {
//            sql += getWherePrefix(whereClauseStarted) + "lower(patient.birthDate) like concat('%', lower(:dateOfBirth), '%') ";
//        }
		if (!GenericValidator.isBlankOrNull(gender)) {
			sql += getWherePrefix(whereClauseStarted) + " lower(patient.gender) = lower(:gender) ";
			whereClauseStarted = true;
		}
		sql += " order by ";

		switch (order.getValue()) {
		case "statusId":
			sql = sql + "eo.statusId asc";
			break;
		case "lastupdatedasc":
			sql = sql + "eo.statusId asc, eo.lastupdated asc";
			break;
		case "lastupdateddesc":
			sql = sql + "eo.statusId asc, eo.lastupdated desc";
			break;
		case "externalId":
			sql = sql + "eo.externalId asc";
			break;
		case "orderTimestampdesc":
			sql = sql + "eo.statusId asc, eo.orderTimestamp desc";
			break;
		default:
			//
			break;
		}
		try {

			Query<?> query = entityManager.unwrap(Session.class).createQuery(sql);
			if (!GenericValidator.isBlankOrNull(accessionNumber)) {
				query.setParameter("accessionNumber", accessionNumber);
			}
			if (!GenericValidator.isBlankOrNull(patientLastName)) {
				query.setParameter("patientLastName", patientLastName);
			}
			if (!GenericValidator.isBlankOrNull(patientFirstName)) {
				query.setParameter("patientFirstName", patientFirstName);
			}
			if (!GenericValidator.isBlankOrNull(gender)) {
				query.setParameter("gender", gender);
			}
			// query.setParameter("order", order.getValue());
			List<?> records = query.list();
			List<ElectronicOrder> eOrders = new ArrayList<>();
			for (int i = 0; i < records.size(); i++) {
				Object[] oArray = (Object[]) records.get(i);
				ElectronicOrder eo = (ElectronicOrder) oArray[0];
				eOrders.add(eo);
			}
			return eOrders;
		} catch (HibernateException e) {
			handleException(e, "getAllElectronicOrdersContainingValue");
		}
		return null;
	}

	private String getWherePrefix(boolean whereClauseStarted) {
		if (!whereClauseStarted) {
			return " where ";
		} else {
			return " and ";
		}
	}

	@Override
	public List<ElectronicOrder> getAllElectronicOrdersByDateAndStatus(Date startDate, Date endDate, String statusId,
			SortOrder sortOrder) {
		String hql = "From ElectronicOrder eo WHERE 1 = 1 ";
		if (startDate != null) {
			hql += "AND eo.orderTimestamp BETWEEN :startDate AND :endDate ";
		}
		if (!GenericValidator.isBlankOrNull(statusId)) {
			hql += "AND eo.statusId = :statusId ";
		}

		switch (sortOrder) {
		case STATUS_ID:
			hql += "ORDER BY eo.statusId asc ";
			break;
		case LAST_UPDATED_ASC:
			hql += "ORDER BY eo.lastUpdated asc ";
			break;
		case LAST_UPDATED_DESC:
			hql += "ORDER BY eo.lastUpdated desc ";
			break;
		case EXTERNAL_ID:
			hql += "ORDER BY eo.externalId asc ";
			break;
		case RECEPTION_DATE:
			hql = hql + "ORDER BY eo.statusId asc, eo.orderTimestamp desc";
			break;
		default:
			//
			break;
		}

		try {
			Query<ElectronicOrder> query = entityManager.unwrap(Session.class).createQuery(hql, ElectronicOrder.class);
			if (startDate != null) {
				query.setParameter("startDate", startDate);
				query.setParameter("endDate", endDate);
			}
			if (!GenericValidator.isBlankOrNull(statusId)) {
				query.setParameter("statusId", Integer.parseInt(statusId));
			}
			return query.list();
		} catch (HibernateException e) {
			handleException(e, "getAllElectronicOrdersByDateAndStatus");
		}
		return null;
	}

	@Override
	public List<ElectronicOrder> getAllElectronicOrdersByTimestampAndStatus(java.sql.Timestamp startTimestamp,
			java.sql.Timestamp endTimestamp, String statusId, SortOrder sortOrder) {
		String hql = "From ElectronicOrder eo WHERE 1 = 1 ";
		if (startTimestamp != null) {
			hql += "AND eo.orderTimestamp BETWEEN :startDate AND :endDate ";
		}
		if (!GenericValidator.isBlankOrNull(statusId)) {
			hql += "AND eo.statusId = :statusId ";
		}

		switch (sortOrder) {
		case STATUS_ID:
			hql += "ORDER BY eo.statusId asc ";
			break;
		case LAST_UPDATED_ASC:
			hql += "ORDER BY eo.lastUpdated asc ";
			break;
		case LAST_UPDATED_DESC:
			hql += "ORDER BY eo.lastUpdated desc ";
			break;
		case EXTERNAL_ID:
			hql += "ORDER BY eo.externalId asc ";
			break;
		case RECEPTION_DATE:
			hql = hql + "ORDER BY eo.statusId asc, eo.orderTimestamp desc";
			break;
		default:
			//
			break;
		}

		try {
			Query<ElectronicOrder> query = entityManager.unwrap(Session.class).createQuery(hql, ElectronicOrder.class);
			if (startTimestamp != null) {
				query.setParameter("startDate", startTimestamp);
				query.setParameter("endDate", endTimestamp);
			}
			if (!GenericValidator.isBlankOrNull(statusId)) {
				query.setParameter("statusId", Integer.parseInt(statusId));
			}
			return query.list();
		} catch (HibernateException e) {
			handleException(e, "getAllElectronicOrdersByDateAndStatus");
		}
		return null;
	}

	/**
	 * Recherche optimisée des demandes électroniques Charge Virale.
	 *
	 * Stratégie : LEFT JOIN depuis vl_eorder_request_flat (source prioritaire)
	 * vers electronic_order (complète avec statusId, priority, reject_reason_id).
	 * Une seule requête SQL native — aucun appel FHIR.
	 *
	 * Cas searchValue non vide : recherche par request_uuid, labno,
	 *   patient_code ou patient_subject_number (ILIKE).
	 * Cas searchValue vide + dates : filtrage par période sur authored_on
	 *   (ou order_timestamp si authored_on est null).
	 */
	@Override
	@Transactional(readOnly = true)
	public List<VlOrderDisplayItem> searchCvOrders(String searchValue,
			Timestamp startTimestamp, Timestamp endTimestamp, String statusId) {

		StringBuilder sql = new StringBuilder(
			"SELECT " +
			"  f.request_uuid, " +
			"  CAST(eo.id AS VARCHAR), " +
			"  f.patient_code, " +
			"  f.patient_subject_number, " +
			"  f.gender, " +
			"  f.birth_date, " +
			"  f.age_year, " +
			"  f.age_month, " +
			"  f.requesting_site_code, " +
			"  f.requesting_site_name, " +
			"  f.requesting_district, " +
			"  f.requesting_region, " +
			"  f.implementing_partner, " +
			"  f.order_reason, " +
			"  f.other_order_reason, " +
			"  f.pregnancy, " +
			"  f.suckle, " +
			"  f.hiv_status, " +
			"  f.current_arv_treatment, " +
			"  f.arv_treatment_regime, " +
			"  f.arv_treatment_init_date, " +
			"  f.current_arv_treatment_inns, " +
			"  f.vl_benefit, " +
			"  f.prior_vl_value, " +
			"  f.prior_vl_date, " +
			"  f.prior_vl_lab, " +
			"  f.sample_type, " +
			"  f.collection_date, " +
			"  f.received_date, " +
			"  f.request_date, " +
			"  COALESCE(f.authored_on, eo.order_timestamp) AS creation_ts, " +
			"  f.labno, " +
			"  f.lab_status, " +
			"  f.test_result, " +
			"  f.result_unit, " +
			"  f.completed_date, " +
			"  f.destination_platform_name, " +
			"  eo.status_id, " +
			"  CAST(eo.ORDER_PRIORITY AS VARCHAR), " +
			"  eo.reject_reason_id,"
			+ "f.created_at " +
			"FROM clinlims.vl_eorder_request_flat f " +
			"LEFT JOIN clinlims.electronic_order eo ON eo.external_id = f.request_uuid " +
			"WHERE 1 = 1 "
		);

		boolean hasSearch = !GenericValidator.isBlankOrNull(searchValue);
		boolean hasDates  = startTimestamp != null;
		boolean hasStatus = !GenericValidator.isBlankOrNull(statusId);

		if (hasSearch) {
			sql.append(
				"AND (f.request_uuid ILIKE :sv " +
				"  OR f.labno ILIKE :sv " +
				"  OR f.patient_code ILIKE :sv " +
				"  OR f.patient_subject_number ILIKE :sv) "
			);
		}
		if (hasDates) {
			sql.append("AND COALESCE(f.authored_on, eo.order_timestamp) BETWEEN :start AND :end ");
		}
		if (hasStatus) {
			sql.append("AND eo.status_id = :statusId ");
		}
		sql.append("ORDER BY COALESCE(f.authored_on, eo.order_timestamp) DESC NULLS LAST");

		try {
			Query<Tuple> query = entityManager.unwrap(Session.class)
					.createNativeQuery(sql.toString(), Tuple.class);

			if (hasSearch) {
				query.setParameter("sv", "%" + searchValue + "%");
			}
			if (hasDates) {
				query.setParameter("start", startTimestamp);
				query.setParameter("end", endTimestamp);
			}
			if (hasStatus) {
				query.setParameter("statusId", Integer.parseInt(statusId));
			}

			List<Tuple> rows = query.list();
			List<VlOrderDisplayItem> result = new ArrayList<>(rows.size());
			for (Tuple row : rows) {
				result.add(mapTupleToVlOrderDisplayItem(row));
			}
			return result;

		} catch (HibernateException e) {
			handleException(e, "searchCvOrders");
		}
		return new ArrayList<>();
	}

	private VlOrderDisplayItem mapTupleToVlOrderDisplayItem(Tuple row) {
		VlOrderDisplayItem item = new VlOrderDisplayItem();

		item.setRequestUuid(row.get(0, String.class));
		item.setElectronicOrderId(row.get(1, String.class));
		item.setPatientCode(row.get(2, String.class));
		item.setPatientSubjectNumber(row.get(3, String.class));
		item.setGender(row.get(4, String.class));

		// birth_date -> String formaté
		java.sql.Date birthDate = row.get(5, java.sql.Date.class);
		if (birthDate != null) {
			item.setBirthDate(DateUtil.formatDateAsText(birthDate));
		}

		item.setAgeYear(row.get(6, Integer.class));
		item.setAgeMonth(row.get(7, Integer.class));
		item.setRequestingSiteCode(row.get(8, String.class));
		item.setRequestingSiteName(row.get(9, String.class));
		item.setRequestingDistrict(row.get(10, String.class));
		item.setRequestingRegion(row.get(11, String.class));
		item.setImplementingPartner(row.get(12, String.class));
		item.setOrderReason(row.get(13, String.class));
		item.setOtherOrderReason(row.get(14, String.class));
		item.setPregnancy(row.get(15, Boolean.class));
		item.setSuckle(row.get(16, Boolean.class));
		item.setHivStatus(row.get(17, String.class));
		item.setCurrentArvTreatment(row.get(18, Boolean.class));
		item.setArvTreatmentRegime(row.get(19, String.class));

		// arv_treatment_init_date
		java.sql.Date arvDate = row.get(20, java.sql.Date.class);
		if (arvDate != null) {
			item.setArvTreatmentInitDate(DateUtil.formatDateAsText(arvDate));
		}

		item.setCurrentArvTreatmentInns(row.get(21, String.class));
		item.setVlBenefit(row.get(22, String.class));
		item.setPriorVlValue(row.get(23, String.class));

		// prior_vl_date
		java.sql.Date priorVlDate = row.get(24, java.sql.Date.class);
		if (priorVlDate != null) {
			item.setPriorVlDate(DateUtil.formatDateAsText(priorVlDate));
		}

		item.setPriorVlLab(row.get(25, String.class));
		item.setSampleType(row.get(26, String.class));

		// collection_date (Timestamp)
		Timestamp collDate = row.get(27, Timestamp.class);
		if (collDate != null) {
			item.setCollectionDateDisplay(DateUtil.formatDateAsText(new java.util.Date(collDate.getTime())));
		}

		// received_date (Timestamp)
		Timestamp recvDate = row.get(28, Timestamp.class);
		if (recvDate != null) {
			item.setReceivedDateDisplay(DateUtil.formatDateAsText(new java.util.Date(recvDate.getTime())));
		}

		// request_date
		java.sql.Date reqDate = row.get(29, java.sql.Date.class);
		if (reqDate != null) {
			item.setRequestDateDisplay(DateUtil.formatDateAsText(reqDate));
		}

		// creation_ts = COALESCE(authored_on, order_timestamp)
		Timestamp creationTs = row.get(30, Timestamp.class);
		if (creationTs != null) {
			item.setCreationDateDisplay(DateUtil.formatDateTimeAsText(new java.util.Date(creationTs.getTime())));
		}

		item.setLabno(row.get(31, String.class));
		item.setLabStatus(row.get(32, String.class));
		item.setTestResult(row.get(33, String.class));
		item.setResultUnit(row.get(34, String.class));

		// completed_date
		Timestamp completedDate = row.get(35, Timestamp.class);
		if (completedDate != null) {
			item.setCompletedDateDisplay(DateUtil.formatDateAsText(new java.util.Date(completedDate.getTime())));
			}
		item.setDestinationPlatformName(row.get(36, String.class));

		// status_id OpenELIS — BigDecimal en natif PostgreSQL
		java.math.BigDecimal statusIdBd = row.get(37, java.math.BigDecimal.class);
		if (statusIdBd != null) {
			item.setStatus(String.valueOf(statusIdBd.intValue())); // résolu en texte dans le service
		}

		item.setPriority(row.get(38, String.class));

		java.math.BigDecimal qaEventBd = row.get(39, java.math.BigDecimal.class);
		if (qaEventBd != null) {
			item.setQaEventId(qaEventBd.intValue());
		}
		if (item.getReceivedDateDisplay() == null) {			
			recvDate = row.get(40, Timestamp.class);
			if (recvDate != null) {
				item.setReceivedDateDisplay(DateUtil.formatDateAsText(new java.util.Date(recvDate.getTime())));
			}
			
		}

		return item;
	}

	public ElectronicOrder getLastEnteredByPatientIdentifier(String patientIdentifier) {
		String hql = " from ElectronicOrder eo join eo.patient patient "
				+ " where (lower(eo.externalId) = (:patientIdentifier) "
				+ " or lower(patient.nationalId) = lower(:patientIdentifier) "
				+ " or lower(patient.externalId) = lower(:patientIdentifier)) "
				+ " AND eo.statusId = (SELECT sampleStatus.id FROM StatusOfSample sampleStatus WHERE lower(name) = 'entered' "
				+ " AND status_type='EXTERNAL_ORDER' ) order by eo.lastupdated DESC ";
		try {
			Query<?> query = entityManager.unwrap(Session.class).createQuery(hql);
			query.setParameter("patientIdentifier", patientIdentifier);
			query.setMaxResults(1);
			List<?> records = query.list();
			if (records.size() > 0) {
				Object[] oArray = (Object[]) records.get(0);
				return (ElectronicOrder) oArray[0];
			} else
				return null;
		} catch (HibernateException e) {
			handleException(e, "getLastEnteredByPatientIdentifier");
		}
		return null;
	}

}
