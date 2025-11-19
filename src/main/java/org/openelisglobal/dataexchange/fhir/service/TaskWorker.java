package org.openelisglobal.dataexchange.fhir.service;

import java.sql.Timestamp;
import java.util.Date;
import java.util.List;

import org.apache.commons.lang3.ObjectUtils;
import org.hl7.fhir.r4.model.Encounter;
import org.hl7.fhir.r4.model.Extension;
import org.hl7.fhir.r4.model.Identifier;
import org.hl7.fhir.r4.model.Patient;
import org.hl7.fhir.r4.model.Period;
import org.hl7.fhir.r4.model.Reference;
import org.hl7.fhir.r4.model.ServiceRequest;
import org.hl7.fhir.r4.model.Task;
import org.openelisglobal.common.action.IActionConstants;
import org.openelisglobal.common.log.LogEvent;
import org.openelisglobal.common.services.IStatusService;
import org.openelisglobal.common.services.StatusService.AnalysisStatus;
import org.openelisglobal.common.services.StatusService.ExternalOrderStatus;
import org.openelisglobal.common.services.StatusService.OrderStatus;
import org.openelisglobal.common.util.ConfigurationProperties;
import org.openelisglobal.common.util.ConfigurationProperties.Property;
import org.openelisglobal.common.util.DateUtil;
import org.openelisglobal.dataexchange.fhir.FhirUtil;
import org.openelisglobal.dataexchange.order.action.IOrderExistanceChecker;
import org.openelisglobal.dataexchange.order.action.IOrderExistanceChecker.CheckResult;
import org.openelisglobal.dataexchange.order.action.IOrderInterpreter.InterpreterResults;
import org.openelisglobal.dataexchange.order.action.IOrderInterpreter.OrderType;
import org.openelisglobal.dataexchange.order.action.IOrderPersister;
import org.openelisglobal.dataexchange.order.action.MessagePatient;
import org.openelisglobal.dataexchange.order.valueholder.ElectronicOrder;
import org.openelisglobal.dataexchange.order.valueholder.ElectronicOrderType;
import org.openelisglobal.organization.service.OrganizationService;
import org.openelisglobal.organization.service.OrganizationTypeService;
import org.openelisglobal.organization.valueholder.Organization;
import org.openelisglobal.organization.valueholder.OrganizationType;
import org.openelisglobal.sample.service.SampleService;
import org.openelisglobal.sample.valueholder.OrderPriority;
import org.openelisglobal.sample.valueholder.Sample;
import org.openelisglobal.spring.util.SpringContext;
import org.openelisglobal.test.valueholder.Test;

import ca.uhn.fhir.rest.client.api.IGenericClient;

public class TaskWorker {

	public enum TaskResult {
		OK, DUPLICATE_ORDER, NON_CANCELABLE_ORDER, MESSAGE_ERROR, ORDER_IN_PROGRESS, ORDER_REJECTED, ORDER_COMPLETED,
		ORDER_CANCELED
	}

	private String message = "";
	private Task task = new Task();
	private ServiceRequest serviceRequest = null;
	private Patient fhirPatient = new Patient();
	private TaskInterpreter interpreter;
	private IOrderExistanceChecker existanceChecker;
	private IOrderPersister persister;
	private IStatusService statusService;
	private List<InterpreterResults> interpretResults;
	private CheckResult checkResult;
	Timestamp collectionDate = null;
	private Organization referringFacility = null;
	protected FhirUtil fhirUtil = SpringContext.getBean(FhirUtil.class);
	protected SampleService sampleService = SpringContext.getBean(SampleService.class);
	protected OrganizationService organizationService = SpringContext.getBean(OrganizationService.class);
	protected OrganizationTypeService organizationTypeService = SpringContext.getBean(OrganizationTypeService.class);

	public static final String REFERRING_ORG_TYPE = "referring clinic";
	public static final String ARV_ORG_TYPE = "ARV Service Loc";

	public TaskWorker(Task incomingTask, String incomingMessage, ServiceRequest incomingServiceRequest,
			Patient incomingPatient) {
		task = incomingTask;
		message = incomingMessage;
		serviceRequest = incomingServiceRequest;
		fhirPatient = incomingPatient;
	}

	public void setInterpreter(TaskInterpreter interpreter) {
		this.interpreter = interpreter;
	}

	public void setExistanceChecker(IOrderExistanceChecker orderExistanceChecker) {
		existanceChecker = orderExistanceChecker;
	}

	public void setPersister(IOrderPersister taskPersister) {
		persister = taskPersister;
	}

	private IStatusService getStatusService() {
		if (statusService == null) {
			statusService = SpringContext.getBean(IStatusService.class);
		}
		return statusService;
	}

	public void setStatusService(IStatusService statusService) {
		this.statusService = statusService;
	}

	public List<InterpreterResults> getMessageErrors() {
		return interpretResults;
	}

	public List<String> getUnsupportedTests() {
		return interpreter.getUnsupportedTests();
	}

	public List<String> getUnsupportedPanels() {
		return interpreter.getUnsupportedPanels();
	}

	public CheckResult getExistanceCheckResult() {
		return checkResult;
	}

	public TaskResult handleOrderRequest() throws IllegalStateException {
		if (interpreter == null || persister == null || existanceChecker == null) {
			throw new IllegalStateException("Interpreter, existanceChecker or persister have not been set");
		}

		interpretResults = interpreter.interpret(task, serviceRequest, fhirPatient);

		String referringOrderNumber = interpreter.getReferringOrderNumber();
		OrderType orderType = interpreter.getOrderType();
		OrderPriority priority = interpreter.getOrderPriority();
		MessagePatient patient = interpreter.getMessagePatient();
		checkResult = existanceChecker.check(referringOrderNumber);
		Test test = interpreter.getTest();
		boolean shouldAnonymize = false;
		if ((ConfigurationProperties.getInstance().isPropertyValueEqual(Property.configurationName, "CI RetroCI")
				|| ConfigurationProperties.getInstance().isCaseInsensitivePropertyValueEqual(Property.configurationName,
						"CI LNSP")
				|| ConfigurationProperties.getInstance().isCaseInsensitivePropertyValueEqual(Property.configurationName,
						"CI IPCI")
				|| ConfigurationProperties.getInstance().isCaseInsensitivePropertyValueEqual(Property.configurationName,
						"CI_REGIONAL")
				|| ConfigurationProperties.getInstance().isCaseInsensitivePropertyValueEqual(Property.configurationName,
						"RETROCI")
				|| ConfigurationProperties.getInstance().isCaseInsensitivePropertyValueEqual(Property.configurationName,
						"CI_GENERAL"))
				&& test.getLoinc().equals("25836-8"))// LOINC for viralload
		{
			shouldAnonymize = true;
		}
		// getEncounter to get collectionDate
		IGenericClient localFhirClient = fhirUtil.getLocalFhirClient();
		Encounter encounter = localFhirClient.read().resource(Encounter.class)
				.withId(serviceRequest.getEncounter().getReferenceElement().getIdPart()).execute();
		if (ObjectUtils.isNotEmpty(encounter)) { // get Collection Date
			Period period = encounter.getPeriod();
			if (ObjectUtils.isNotEmpty(period)) {
				try {
					Date startDate = encounter.getPeriod().getStart();
					collectionDate = DateUtil.convertSqlDateToTimestamp(new java.sql.Date(startDate.getTime()));
				} catch (Exception e) {
					LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest - getCollectionDate()",
							e.getMessage());
				}
			}
		}

		// get location
		for (Identifier identifier : fhirPatient.getIdentifier()) {
			if (("http://fhir.openmrs.org/ext/patient/identifier#location")
					.equals(identifier.getExtensionFirstRep().getUrl())) {
				Extension extension = identifier.getExtensionFirstRep();
				Reference locationReference = (Reference) extension.getValue();
				String reference = locationReference.getReference();
				// the short code can be 5 ou 4 digits base code
				String centerCode = reference.substring(reference.length() - 5);
				try {
					Integer.parseInt(centerCode);
				} catch (Exception e) {
					centerCode = reference.substring(reference.length() - 4);
				}
				String display = locationReference.getDisplay();

				referringFacility = organizationService.getOrganizationByShortName(centerCode, true);
				try {
					if (ObjectUtils.isEmpty(referringFacility)) {
						// create a new Organization
						referringFacility = new Organization();
						referringFacility.setOrganizationName(display);
						referringFacility.setName(display);
						referringFacility.setShortName(centerCode);
						referringFacility.setIsActive(IActionConstants.YES);
						referringFacility.setMlsSentinelLabFlag(IActionConstants.NO);
						referringFacility.setLastupdated(DateUtil.getNowAsTimestamp());
						organizationService.insert(referringFacility);
						OrganizationType referringClinicSiteType = organizationTypeService
								.getOrganizationTypeByName(REFERRING_ORG_TYPE);
						OrganizationType arvSiteType = organizationTypeService.getOrganizationTypeByName(ARV_ORG_TYPE);
						organizationService.linkOrganizationAndType(referringFacility, referringClinicSiteType.getId());
						organizationService.linkOrganizationAndType(referringFacility, arvSiteType.getId());
					}
				} catch (Exception e) {
					LogEvent.logDebug(this.getClass().getName(), "setOrganizationFromFhirObject", e.getMessage());
				}
			}
		}

		// Get existing sample for this eorder, to check if order has already been
		// entered
		// manually
		List<Sample> sampleListForEOrder = sampleService.getSampleByPatientAndTestAndCollectionDate(
				patient.getNationalId(), test, DateUtil.convertDateTimeToSqlDate(collectionDate));
		if (!sampleListForEOrder.isEmpty()) {
			Sample sample = sampleListForEOrder.get(0);
			ExternalOrderStatus newEorderStatus = ExternalOrderStatus.Cancelled; // cancelled by default
			TaskResult result = TaskResult.ORDER_CANCELED;

			if (ObjectUtils.isNotEmpty(sample)) {
				sample.setReferringId(referringOrderNumber);
				sampleService.update(sample);

				if (sample.getStatusId().equals(getStatusService().getStatusID(OrderStatus.Entered))) {
					newEorderStatus = ExternalOrderStatus.InProgress;
					result = TaskResult.ORDER_IN_PROGRESS;
				} else if (sample.getStatusId().equals(getStatusService().getStatusID(OrderStatus.Started))
						|| sample.getStatusId().equals(statusService.getStatusID(AnalysisStatus.TechnicalAcceptance))) {
					newEorderStatus = ExternalOrderStatus.InProgress;
					result = TaskResult.ORDER_IN_PROGRESS;
				} else if (sample.getStatusId()
						.equals(getStatusService().getStatusID(AnalysisStatus.TechnicalRejected))) {
					newEorderStatus = ExternalOrderStatus.NonConforming;
					result = TaskResult.ORDER_REJECTED;
				} else if (sample.getStatusId()
						.equals(getStatusService().getStatusID(OrderStatus.NonConforming_depricated))
						|| sample.getStatusId()
								.equals(getStatusService().getStatusID(AnalysisStatus.BiologistRejected))) {
					newEorderStatus = ExternalOrderStatus.NonConforming;
					result = TaskResult.ORDER_REJECTED;
				} else if (sample.getStatusId().equals(getStatusService().getStatusID(OrderStatus.Finished))) {
					newEorderStatus = ExternalOrderStatus.Completed;
					result = TaskResult.ORDER_COMPLETED;
				}
			}

			insertNewOrder(referringOrderNumber, message, patient, priority, newEorderStatus, referringFacility,
					shouldAnonymize);
			return result;
		}

		if (interpretResults.get(0) == InterpreterResults.OK) {

//            checkResult = existanceChecker.check(referringOrderNumber);
			switch (checkResult) {
			case ORDER_FOUND_QUEUED:
				if (orderType == OrderType.CANCEL) {
					LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest",
							"cancelling order: " + referringOrderNumber);
					cancelOrder(referringOrderNumber);
					return TaskResult.OK;
				} else {
					LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest",
							"duplicate order found: " + referringOrderNumber);
					return TaskResult.DUPLICATE_ORDER;
				}
			case ORDER_FOUND_INPROGRESS:
				LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest",
						"order: " + referringOrderNumber + " is duplicate or already in progress");
				return orderType == OrderType.CANCEL ? TaskResult.NON_CANCELABLE_ORDER : TaskResult.DUPLICATE_ORDER;
			case NOT_FOUND:
				if (orderType == OrderType.CANCEL) {
					LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest", "cant cancel order not found");
					return TaskResult.NON_CANCELABLE_ORDER;
				} else {
					LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest",
							"no order found, entering order: " + referringOrderNumber);
					insertNewOrder(referringOrderNumber, message, patient, priority, ExternalOrderStatus.Entered,
							referringFacility, shouldAnonymize);
					return TaskResult.OK;
				}
			case ORDER_FOUND_CANCELED:
				if (orderType == OrderType.CANCEL) {
					LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest",
							"can't cancel already cancelled order: " + referringOrderNumber);
					return TaskResult.NON_CANCELABLE_ORDER;
				} else {
					LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest",
							"order found cancelled, entering order: " + referringOrderNumber);
					insertNewOrder(referringOrderNumber, message, patient, priority, ExternalOrderStatus.Entered,
							referringFacility, shouldAnonymize);
					return TaskResult.OK;
				}
			default:
				LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest",
						"undetermined issue in correctly interpreted request: " + interpretResults.get(0).toString()
								+ " check result: " + checkResult + " for: " + referringOrderNumber + " " + orderType
								+ " ");
				insertNewOrder(referringOrderNumber, message, patient, priority, ExternalOrderStatus.NonConforming,
						referringFacility, shouldAnonymize);
				return TaskResult.MESSAGE_ERROR;
			}

		} else if (interpretResults.get(0) == InterpreterResults.UNSUPPORTED_TESTS
				&& checkResult == CheckResult.ORDER_FOUND_QUEUED) {
			if (orderType == OrderType.CANCEL) {
				LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest",
						"cancelling order: " + referringOrderNumber + " despite wrong test specified");
				cancelOrder(referringOrderNumber);
				return TaskResult.OK;
			} else {
				LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest",
						"order: " + referringOrderNumber + " already entered");
				return TaskResult.DUPLICATE_ORDER;
			}
		} else if (interpretResults.get(0) == InterpreterResults.UNSUPPORTED_TESTS) {
			LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest",
					"TaskWorker:unsupported tests: " + referringOrderNumber + orderType);
			insertNewOrder(referringOrderNumber, message, patient, priority, ExternalOrderStatus.NonConforming,
					referringFacility, shouldAnonymize);
			return TaskResult.MESSAGE_ERROR;
		} else if (interpretResults.get(0) == InterpreterResults.MISSING_PATIENT_GUID
				|| interpretResults.get(0) == InterpreterResults.MISSING_PATIENT_DOB
				|| interpretResults.get(0) == InterpreterResults.MISSING_PATIENT_GENDER
				|| interpretResults.get(0) == InterpreterResults.MISSING_PATIENT_IDENTIFIER) {
			LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest", "missing patient info: "
					+ interpretResults.get(0).toString() + "for" + referringOrderNumber + " " + orderType + " ");
			insertNewOrder(referringOrderNumber, message, patient, priority, ExternalOrderStatus.NonConforming,
					referringFacility, shouldAnonymize);
			return TaskResult.MESSAGE_ERROR;
		} else {
			LogEvent.logDebug(this.getClass().getName(), "handleOrderRequest", "undetermined issue: "
					+ interpretResults.get(0).toString() + " for: " + referringOrderNumber + " " + orderType + " ");
			insertNewOrder(referringOrderNumber, message, patient, priority, ExternalOrderStatus.NonConforming,
					referringFacility, shouldAnonymize);
			return TaskResult.MESSAGE_ERROR;
		}

	}

	private void cancelOrder(String referringOrderNumber) {
		LogEvent.logDebug(this.getClass().getName(), "cancelOrder", "cancelOrder: ");
		persister.cancelOrder(referringOrderNumber);
	}

	private void insertNewOrder(String referringOrderNumber, String message, MessagePatient patient,
			OrderPriority orderPriority, ExternalOrderStatus eoStatus, Organization referringFacility,
			boolean shouldAnonymize) {
		LogEvent.logDebug(this.getClass().getName(), "insertNewOrder",
				"TaskWorker:insertNewOrder: " + referringOrderNumber);
		ElectronicOrder eOrder = new ElectronicOrder();
		eOrder.setExternalId(referringOrderNumber);
		eOrder.setData(message);
		eOrder.setStatusId(getStatusService().getStatusID(eoStatus));
		eOrder.setOrderTimestamp(DateUtil.getNowAsTimestamp());
		eOrder.setSysUserId(persister.getServiceUserId());
		eOrder.setType(ElectronicOrderType.FHIR);
		eOrder.setPriority(orderPriority);
		eOrder.setCollectionDate(collectionDate);
		if (ObjectUtils.isNotEmpty(referringFacility))
			eOrder.setReferringFacilityId(Integer.parseInt(referringFacility.getId()));

		if (shouldAnonymize) {
			patient.setLastName("");
			patient.setFirstName("");
			patient.setContactPhone("");
			patient.setAddressCommune("");
			patient.setAddressStreet("");
			patient.setAddressVillage("");
			patient.setMobilePhone("");
			patient.setWorkPhone("");
			patient.setMothersFirstName("");
			patient.setEmail("");
			patient.setContactEmail("");
			patient.setContactFirstName("");
			patient.setContactLastName("");
		}

		persister.persist(patient, eOrder);
	}

}
