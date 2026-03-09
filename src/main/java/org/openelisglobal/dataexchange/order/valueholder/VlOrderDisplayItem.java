package org.openelisglobal.dataexchange.order.valueholder;

import java.util.List;

/**
 * DTO optimisé pour l'affichage des demandes électroniques Charge Virale.
 * Résultat direct d'un LEFT JOIN entre vl_eorder_request_flat (prioritaire)
 * et electronic_order (statut labo, priorité, qaEventId).
 */
public class VlOrderDisplayItem {

	// --- Identifiants ---
	private String requestUuid;          // vl_eorder_request_flat.request_uuid (= electronic_order.external_id)
	private String electronicOrderId;    // electronic_order.id

	// --- Patient ---
	private String patientCode;          // vl_eorder_request_flat.patient_code
	private String patientSubjectNumber; // vl_eorder_request_flat.patient_subject_number
	private String gender;               // vl_eorder_request_flat.gender
	private String birthDate;            // vl_eorder_request_flat.birth_date (formaté)
	private Integer ageYear;             // vl_eorder_request_flat.age_year
	private Integer ageMonth;            // vl_eorder_request_flat.age_month

	// --- Site demandeur ---
	private String requestingSiteCode;   // vl_eorder_request_flat.requesting_site_code
	private String requestingSiteName;   // vl_eorder_request_flat.requesting_site_name
	private String requestingDistrict;   // vl_eorder_request_flat.requesting_district
	private String requestingRegion;     // vl_eorder_request_flat.requesting_region
	private String implementingPartner;  // vl_eorder_request_flat.implementing_partner

	// --- Clinique ---
	private String orderReason;          // vl_eorder_request_flat.order_reason
	private String otherOrderReason;     // vl_eorder_request_flat.other_order_reason
	private Boolean pregnancy;
	private Boolean suckle;
	private String hivStatus;
	private Boolean currentArvTreatment;
	private String arvTreatmentRegime;
	private String arvTreatmentInitDate; // formaté
	private String currentArvTreatmentInns;
	private String vlBenefit;
	private String priorVlValue;
	private String priorVlDate;          // formaté
	private String priorVlLab;

	// --- Spécimen & dates ---
	private String sampleType;
	private String collectionDateDisplay;
	private String receivedDateDisplay;
	private String requestDateDisplay;
	private String creationDateDisplay;  // authored_on / electronic_order.order_timestamp

	// --- Résultat labo ---
	private String labno;                // vl_eorder_request_flat.labno
	private String labStatus;            // vl_eorder_request_flat.lab_status
	private String testResult;           // vl_eorder_request_flat.test_result
	private String resultUnit;           // vl_eorder_request_flat.result_unit
	private String resultComment;        // vl_eorder_request_flat.result_comment
	private String completedDateDisplay;

	// --- Statut OpenELIS (electronic_order) ---
	private String status;               // statusOfSample.defaultLocalizedName
	private String priority;             // electronic_order.priority
	private Integer qaEventId;           // electronic_order.reject_reason_id

	// --- Interop ---
	private String interopStatus;        // vl_eorder_request_flat.interop_status
	private String localStatus;          // vl_eorder_request_flat.local_status (si présent)

	// --- Infos plateforme ---
	private String destinationPlatformName;

	private List<String> warnings;

	// ===================== Getters / Setters =====================

	public String getRequestUuid() { return requestUuid; }
	public void setRequestUuid(String requestUuid) { this.requestUuid = requestUuid; }

	public String getElectronicOrderId() { return electronicOrderId; }
	public void setElectronicOrderId(String electronicOrderId) { this.electronicOrderId = electronicOrderId; }

	public String getPatientCode() { return patientCode; }
	public void setPatientCode(String patientCode) { this.patientCode = patientCode; }

	public String getPatientSubjectNumber() { return patientSubjectNumber; }
	public void setPatientSubjectNumber(String patientSubjectNumber) { this.patientSubjectNumber = patientSubjectNumber; }

	public String getGender() { return gender; }
	public void setGender(String gender) { this.gender = gender; }

	public String getBirthDate() { return birthDate; }
	public void setBirthDate(String birthDate) { this.birthDate = birthDate; }

	public Integer getAgeYear() { return ageYear; }
	public void setAgeYear(Integer ageYear) { this.ageYear = ageYear; }

	public Integer getAgeMonth() { return ageMonth; }
	public void setAgeMonth(Integer ageMonth) { this.ageMonth = ageMonth; }

	public String getRequestingSiteCode() { return requestingSiteCode; }
	public void setRequestingSiteCode(String requestingSiteCode) { this.requestingSiteCode = requestingSiteCode; }

	public String getRequestingSiteName() { return requestingSiteName; }
	public void setRequestingSiteName(String requestingSiteName) { this.requestingSiteName = requestingSiteName; }

	public String getRequestingDistrict() { return requestingDistrict; }
	public void setRequestingDistrict(String requestingDistrict) { this.requestingDistrict = requestingDistrict; }

	public String getRequestingRegion() { return requestingRegion; }
	public void setRequestingRegion(String requestingRegion) { this.requestingRegion = requestingRegion; }

	public String getImplementingPartner() { return implementingPartner; }
	public void setImplementingPartner(String implementingPartner) { this.implementingPartner = implementingPartner; }

	public String getOrderReason() { return orderReason; }
	public void setOrderReason(String orderReason) { this.orderReason = orderReason; }

	public String getOtherOrderReason() { return otherOrderReason; }
	public void setOtherOrderReason(String otherOrderReason) { this.otherOrderReason = otherOrderReason; }

	public Boolean getPregnancy() { return pregnancy; }
	public void setPregnancy(Boolean pregnancy) { this.pregnancy = pregnancy; }

	public Boolean getSuckle() { return suckle; }
	public void setSuckle(Boolean suckle) { this.suckle = suckle; }

	public String getHivStatus() { return hivStatus; }
	public void setHivStatus(String hivStatus) { this.hivStatus = hivStatus; }

	public Boolean getCurrentArvTreatment() { return currentArvTreatment; }
	public void setCurrentArvTreatment(Boolean currentArvTreatment) { this.currentArvTreatment = currentArvTreatment; }

	public String getArvTreatmentRegime() { return arvTreatmentRegime; }
	public void setArvTreatmentRegime(String arvTreatmentRegime) { this.arvTreatmentRegime = arvTreatmentRegime; }

	public String getArvTreatmentInitDate() { return arvTreatmentInitDate; }
	public void setArvTreatmentInitDate(String arvTreatmentInitDate) { this.arvTreatmentInitDate = arvTreatmentInitDate; }

	public String getCurrentArvTreatmentInns() { return currentArvTreatmentInns; }
	public void setCurrentArvTreatmentInns(String currentArvTreatmentInns) { this.currentArvTreatmentInns = currentArvTreatmentInns; }

	public String getVlBenefit() { return vlBenefit; }
	public void setVlBenefit(String vlBenefit) { this.vlBenefit = vlBenefit; }

	public String getPriorVlValue() { return priorVlValue; }
	public void setPriorVlValue(String priorVlValue) { this.priorVlValue = priorVlValue; }

	public String getPriorVlDate() { return priorVlDate; }
	public void setPriorVlDate(String priorVlDate) { this.priorVlDate = priorVlDate; }

	public String getPriorVlLab() { return priorVlLab; }
	public void setPriorVlLab(String priorVlLab) { this.priorVlLab = priorVlLab; }

	public String getSampleType() { return sampleType; }
	public void setSampleType(String sampleType) { this.sampleType = sampleType; }

	public String getCollectionDateDisplay() { return collectionDateDisplay; }
	public void setCollectionDateDisplay(String collectionDateDisplay) { this.collectionDateDisplay = collectionDateDisplay; }

	public String getReceivedDateDisplay() { return receivedDateDisplay; }
	public void setReceivedDateDisplay(String receivedDateDisplay) { this.receivedDateDisplay = receivedDateDisplay; }

	public String getRequestDateDisplay() { return requestDateDisplay; }
	public void setRequestDateDisplay(String requestDateDisplay) { this.requestDateDisplay = requestDateDisplay; }

	public String getCreationDateDisplay() { return creationDateDisplay; }
	public void setCreationDateDisplay(String creationDateDisplay) { this.creationDateDisplay = creationDateDisplay; }

	public String getLabno() { return labno; }
	public void setLabno(String labno) { this.labno = labno; }

	public String getLabStatus() { return labStatus; }
	public void setLabStatus(String labStatus) { this.labStatus = labStatus; }

	public String getTestResult() { return testResult; }
	public void setTestResult(String testResult) { this.testResult = testResult; }

	public String getResultUnit() { return resultUnit; }
	public void setResultUnit(String resultUnit) { this.resultUnit = resultUnit; }

	public String getResultComment() { return resultComment; }
	public void setResultComment(String resultComment) { this.resultComment = resultComment; }

	public String getCompletedDateDisplay() { return completedDateDisplay; }
	public void setCompletedDateDisplay(String completedDateDisplay) { this.completedDateDisplay = completedDateDisplay; }

	public String getStatus() { return status; }
	public void setStatus(String status) { this.status = status; }

	public String getPriority() { return priority; }
	public void setPriority(String priority) { this.priority = priority; }

	public Integer getQaEventId() { return qaEventId; }
	public void setQaEventId(Integer qaEventId) { this.qaEventId = qaEventId; }

	public String getInteropStatus() { return interopStatus; }
	public void setInteropStatus(String interopStatus) { this.interopStatus = interopStatus; }

	public String getLocalStatus() { return localStatus; }
	public void setLocalStatus(String localStatus) { this.localStatus = localStatus; }

	public String getDestinationPlatformName() { return destinationPlatformName; }
	public void setDestinationPlatformName(String destinationPlatformName) { this.destinationPlatformName = destinationPlatformName; }

	public List<String> getWarnings() { return warnings; }
	public void setWarnings(List<String> warnings) { this.warnings = warnings; }
}
