package org.openelisglobal.sample.controller;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;

import org.apache.commons.lang3.ObjectUtils;
import org.apache.commons.lang3.StringUtils;
import org.openelisglobal.common.action.IActionConstants;
import org.openelisglobal.common.log.LogEvent;
import org.openelisglobal.common.util.ConfigurationProperties;
import org.openelisglobal.common.util.ConfigurationProperties.Property;
import org.openelisglobal.common.services.DisplayListService;
import org.openelisglobal.common.services.DisplayListService.ListType;
import org.openelisglobal.common.services.IStatusService;
import org.openelisglobal.common.services.StatusService.ExternalOrderStatus;
import org.openelisglobal.common.services.StatusService.SampleStatus;
import org.openelisglobal.common.util.DateUtil;
import org.openelisglobal.common.util.IdValuePair;
import org.openelisglobal.dataexchange.order.valueholder.ElectronicOrder;
import org.openelisglobal.dataexchange.service.order.EorderFlatQueryService;
import org.openelisglobal.dataexchange.service.order.ElectronicOrderService;
import org.openelisglobal.dictionary.ObservationHistoryList;
import org.openelisglobal.dictionary.service.DictionaryService;
import org.openelisglobal.dictionary.valueholder.Dictionary;
import org.openelisglobal.organization.service.OrganizationService;
import org.openelisglobal.organization.service.OrganizationTypeService;
import org.openelisglobal.organization.util.OrganizationTypeList;
import org.openelisglobal.organization.valueholder.Organization;
import org.openelisglobal.organization.valueholder.OrganizationType;
import org.openelisglobal.patient.saving.ISampleEntry;
import org.openelisglobal.patient.saving.ISampleEntryAfterPatientEntry;
import org.openelisglobal.patient.saving.ISampleSecondEntry;
import org.openelisglobal.patient.service.PatientService;
import org.openelisglobal.patient.valueholder.ObservationData;
import org.openelisglobal.sample.form.ProjectData;
import org.openelisglobal.sample.form.SampleEntryByProjectForm;
import org.openelisglobal.sample.valueholder.Sample;
import org.openelisglobal.sampleitem.valueholder.SampleItem;
import org.openelisglobal.spring.util.SpringContext;
import org.openelisglobal.typeofsample.valueholder.TypeOfSample;
import org.owasp.encoder.Encode;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.annotation.InitBinder;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
public class SampleEntryByProjectController extends BaseSampleEntryController {

	@Value("${org.openelisglobal.requester.identifier:}")
	private String requestFhirUuid;

	@Autowired
	private ElectronicOrderService electronicOrderService;
	@Autowired
	private EorderFlatQueryService eorderFlatQueryService;
	@Autowired
	private OrganizationService organizationService;
	@Autowired
	private OrganizationTypeService organizationTypeService;
	@Autowired
	private DictionaryService dictionaryService;
	@Autowired
	private PatientService patientService;

	public static final String REFERRING_ORG_TYPE = "referring clinic";
	public static final String ARV_ORG_TYPE = "ARV Service Loc";

	private static final String[] ALLOWED_FIELDS = new String[] { "currentDate", "domain", "project",
			"patientLastUpdated", "personLastUpdated", "patientUpdateStatus", "patientPK", "patientFhirUuid",
			"samplePK", "observations.projectFormName", "ProjectData.ARVcenterName", "ProjectData.ARVcenterCode",
			"observations.nameOfDoctor", "receivedDateForDisplay", "receivedTimeForDisplay", "interviewDate",
			"interviewTime", "subjectNumber", "siteSubjectNumber", "upidCode", "labNo", "gender", "birthDateForDisplay",
			"ProjectData.dryTubeTaken", "ProjectData.edtaTubeTaken", "ProjectData.serologyHIVTest",
			"ProjectData.glycemiaTest", "ProjectData.creatinineTest", "ProjectData.transaminaseTest",
			"ProjectData.nfsTest", "ProjectData.cd4cd8Test", "ProjectData.viralLoadTest", "ProjectData.genotypingTest",
			"observations.underInvestigation", "ProjectData.underInvestigationNote", "observations.hivStatus",
			"ProjectData.EIDSiteName", "projectData.EIDsiteCode", "observations.whichPCR",
			"observations.reasonForSecondPCRTest", "observations.nameOfRequestor", "observations.nameOfSampler",
			"observations.eidInfantPTME", "observations.eidTypeOfClinic", "observations.eidHowChildFed",
			"observations.eidStoppedBreastfeeding", "observations.eidInfantSymptomatic", "observations.eidInfantsARV",
			"observations.eidInfantCotrimoxazole", "observations.eidMothersHIVStatus", "observations.eidMothersARV",
			"ProjectData.dbsTaken", "ProjectData.dbsvlTaken", "ProjectData.pscvlTaken", "ProjectData.dnaPCR",
			"ProjectData.INDsiteName", "ProjectData.address", "ProjectData.phoneNumber", "ProjectData.faxNumber",
			"ProjectData.email", "observations.indFirstTestDate", "observations.indFirstTestName",
			"observations.indFirstTestResult", "observations.indSecondTestDate", "observations.indSecondTestName",
			"observations.indSecondTestResult", "observations.indSiteFinalResult", "observations.reasonForRequest",
			"ProjectData.murexTest", "ProjectData.integralTest", "ProjectData.GenscreenTest",
			"ProjectData.vironostikaTest", "ProjectData.innoliaTest", "ProjectData.transaminaseALTLTest",
			"ProjectData.transaminaseASTLTest", "ProjectData.gbTest", "ProjectData.lymphTest", "ProjectData.monoTest",
			"ProjectData.eoTest", "ProjectData.basoTest", "ProjectData.grTest", "ProjectData.hbTest",
			"ProjectData.hctTest", "ProjectData.vgmTest", "ProjectData.tcmhTest", "ProjectData.ccmhTest",
			"ProjectData.plqTest", "ProjectData.cd3CountTest", "ProjectData.cd4CountTest", "observations.vlPregnancy",
			"observations.vlSuckle", "observations.currentARVTreatment", "observations.arvTreatmentInitDate",
			"observations.arvTreatmentRegime", "observations.currentARVTreatmentINNsList*",
			"observations.vlReasonForRequest", "observations.vlOtherReasonForRequest", "observations.initcd4Count",
			"observations.initcd4Percent", "observations.initcd4Date", "observations.demandcd4Count",
			"observations.demandcd4Percent", "observations.demandcd4Date", "observations.vlBenefit",
			"observations.priorVLValue", "observations.priorVLDate", "electronicOrder.externalId",
			"ProjectData.asanteTest", "ProjectData.hpvTest", "ProjectData.plasmaTaken", "ProjectData.serumTaken",
			"ProjectData.preservCytTaken", "observations.hpvSamplingMethod", "ProjectData.abbottOrRocheAnalysis",
			"ProjectData.geneXpertAnalysis", "ProjectData.hpvTest" };

	@InitBinder
	public void initBinder(WebDataBinder binder) {
		binder.setAllowedFields(ALLOWED_FIELDS);
	}

	@RequestMapping(value = "/SampleEntryByProject", method = RequestMethod.GET)
	public ModelAndView showSampleEntryByProject(HttpServletRequest request) {
		SampleEntryByProjectForm form = new SampleEntryByProjectForm();

		Date today = Calendar.getInstance().getTime();
		String dateAsText = DateUtil.formatDateAsText(today);
		form.setReceivedDateForDisplay(dateAsText);
		form.setInterviewDate(dateAsText);

		setupFormData(request, form);

		setDisplayLists(form);
		addFlashMsgsToRequest(request);

		return findForward(FWD_SUCCESS, form);
	}

	private void setupFormData(HttpServletRequest request, SampleEntryByProjectForm form) {
		try {
			String externalOrderNumber = request.getParameter("ID");
			if (StringUtils.isNotBlank(externalOrderNumber)) {
				ElectronicOrder eOrder = null;
				List<ElectronicOrder> eOrders = electronicOrderService
						.getElectronicOrdersByExternalId(externalOrderNumber);
				if (eOrders.size() > 0)
					eOrder = eOrders.get(eOrders.size() - 1);
				if (eOrder != null) {
					form.setElectronicOrder(eOrder);

					// Charger depuis la table plate au lieu de FHIR
					Map<String, Object> flat = eorderFlatQueryService.findByRequestUuid(externalOrderNumber);
					if (flat != null) {
						loadDataFromFlatTable(form, flat);
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private void loadDataFromFlatTable(SampleEntryByProjectForm form, Map<String, Object> flat) {
		ProjectData projectData = new ProjectData();
		ObservationData observationData = new ObservationData();

		// Patient
		String gender = (String) flat.get("gender");
		if (StringUtils.isNotBlank(gender)) {
			form.setGender(gender.substring(0, 1).toUpperCase());
		}
		Date birthDate = toDate(flat.get("birth_date"));
		if (birthDate != null) {
			form.setBirthDateForDisplay(DateUtil.formatDateAsText(birthDate));
		}
		// patient_subject_number → subjectNumber (N° de dossier)
		String subjectNumber = (String) flat.get("patient_subject_number");
		if (StringUtils.isNotBlank(subjectNumber)) {
			form.setSubjectNumber(subjectNumber);
		}
		// patient_code → siteSubjectNumber (code UPI) ET upidCode
		String patientCode = (String) flat.get("patient_code");
		if (StringUtils.isNotBlank(patientCode)) {
			form.setUpidCode(patientCode);
			form.setSiteSubjectNumber(patientCode);
		}

		// Organisation (site demandeur)
		String rawSiteCode = (String) flat.get("requesting_site_code");
		String siteName = (String) flat.get("requesting_site_name");
		String siteCode = normalizeSiteCode(rawSiteCode);
		if (StringUtils.isNotBlank(siteCode)) {
			Organization org = organizationService.getOrganizationByShortName(siteCode, true);
			try {
				if (ObjectUtils.isEmpty(org) && StringUtils.isNotBlank(siteName)) {
					org = new Organization();
					org.setOrganizationName(siteName);
					org.setName(siteName);
					org.setShortName(siteCode);
					org.setIsActive(IActionConstants.YES);
					org.setMlsSentinelLabFlag(IActionConstants.NO);
					org.setLastupdated(DateUtil.getNowAsTimestamp());
					organizationService.insert(org);
					OrganizationType referringClinicSiteType = organizationTypeService
							.getOrganizationTypeByName(REFERRING_ORG_TYPE);
					OrganizationType arvSiteType = organizationTypeService.getOrganizationTypeByName(ARV_ORG_TYPE);
					organizationService.linkOrganizationAndType(org, referringClinicSiteType.getId());
					organizationService.linkOrganizationAndType(org, arvSiteType.getId());
				}
				if (org != null) {
					projectData.setARVcenterCode(org.getId());
					projectData.setARVcenterName(org.getId());
				}
			} catch (Exception e) {
				LogEvent.logDebug(this.getClass().getName(), "loadDataFromFlatTable", e.getMessage());
			}
		}

		// Collection date
		Timestamp collectionDate = (Timestamp) flat.get("collection_date");
		if (collectionDate != null) {
			form.setInterviewDate(DateUtil.formatDateAsText(new Date(collectionDate.getTime())));
		}

		// Sample type
		String sampleType = (String) flat.get("sample_type");
		if (StringUtils.isNotBlank(sampleType)) {
			if (sampleType.equalsIgnoreCase("Plasma")) {
				projectData.setEdtaTubeTaken(true);
			} else if (sampleType.equalsIgnoreCase("DBS")) {
				projectData.setdbsvlTaken(true);
			} else if (sampleType.equalsIgnoreCase("PSC")) {
				projectData.setPscvlTaken(true);
			}
		}

		// ARV treatment
		Boolean currentArvTreatment = (Boolean) flat.get("current_arv_treatment");
		if (Boolean.TRUE.equals(currentArvTreatment)) {
			Dictionary dict = dictionaryService.getDictionaryByDictEntry("Demographic Response Yes (in Yes or No)");
			if (ObjectUtils.isNotEmpty(dict)) {
				observationData.setCurrentARVTreatment(dict.getId());
			}
		}

		// ARV treatment init date
		Date arvInitDate = toDate(flat.get("arv_treatment_init_date"));
		if (arvInitDate != null) {
			observationData.setArvTreatmentInitDate(DateUtil.formatDateAsText(arvInitDate));
		}

		// ARV treatment regime
		String arvRegime = (String) flat.get("arv_treatment_regime");
		if (StringUtils.isNotBlank(arvRegime)) {
			Dictionary dict = null;
			if (arvRegime.equalsIgnoreCase("Première")) {
				dict = dictionaryService.getDictionaryByDictEntry("1st Line");
			} else if (arvRegime.equalsIgnoreCase("Deuxième")) {
				dict = dictionaryService.getDictionaryByDictEntry("2nd Line");
			} else if (arvRegime.equalsIgnoreCase("Troisième")) {
				dict = dictionaryService.getDictionaryByDictEntry("3rd Line");
			}
			if (ObjectUtils.isNotEmpty(dict)) {
				observationData.setArvTreatmentRegime(dict.getId());
			}
		}

		// ARV INNs
		String arvInns = (String) flat.get("current_arv_treatment_inns");
		if (StringUtils.isNotBlank(arvInns)) {
			String[] parts = arvInns.split(" ");
			for (int i = 0; i < parts.length && i < 3; i++) {
				observationData.setCurrentARVTreatmentINNs(i, parts[i].trim());
			}
		}

		// VL reason for request
		String orderReason = (String) flat.get("order_reason");
		if (StringUtils.isNotBlank(orderReason)) {
			Dictionary dict = null;
			switch (orderReason.trim()) {
			case "Charge Virale de controle":
			case "Charge virale sous contrôle ARV":
				dict = dictionaryService.getDictionaryByDictEntry("VL under ARV control");
				break;
			case "Echec Virologique":
				dict = dictionaryService.getDictionaryByDictEntry("Virological Failure");
				break;
			case "Echec immunologique":
				dict = dictionaryService.getDictionaryByDictEntry("Immunological Failure");
				break;
			case "Echec clinique":
			case "GB J0":
				dict = dictionaryService.getDictionaryByDictEntry("Clinical Failure");
				break;
			default:
				break;
			}
			if (ObjectUtils.isNotEmpty(dict)) {
				observationData.setVlReasonForRequest(dict.getId());
			}
		}

		// Other reason
		String otherReason = (String) flat.get("other_order_reason");
		if (StringUtils.isNotBlank(otherReason)) {
			observationData.setVlOtherReasonForRequest(otherReason);
		}

		// HIV status - skip when serology control is enabled (serology result takes precedence)
		boolean serologyControl = ConfigurationProperties.getInstance()
				.isPropertyValueEqual(Property.SEROLOGY_CONTROL, "true");
		if (!serologyControl) {
			String hivStatus = (String) flat.get("hiv_status");
			if (StringUtils.isNotBlank(hivStatus)) {
				Dictionary dict = null;
				if (hivStatus.equalsIgnoreCase("VIH-1")) {
					dict = dictionaryService.getDictionaryByDictEntry("HIV Status HIV-1 infection");
				} else if (hivStatus.equalsIgnoreCase("VIH-1+2")) {
					dict = dictionaryService.getDictionaryByDictEntry("HIV Status HIV-1 and HIV-2");
				} else if (hivStatus.equalsIgnoreCase("VIH-2")) {
					dict = dictionaryService.getDictionaryByDictEntry("HIV Status HIV-2 infection");
				}
				if (ObjectUtils.isNotEmpty(dict)) {
					observationData.setHivStatus(dict.getId());
				}
			}
		}

		// Pregnancy
		Boolean pregnancy = (Boolean) flat.get("pregnancy");
		if (pregnancy != null) {
			Dictionary dict = pregnancy
					? dictionaryService.getDictionaryByDictEntry("Demographic Response Yes (in Yes or No)")
					: dictionaryService.getDictionaryByDictEntry("Demographic Response No (in Yes or No)");
			if (ObjectUtils.isNotEmpty(dict)) {
				observationData.setVlPregnancy(dict.getId());
			}
		}

		// Breastfeeding
		Boolean suckle = (Boolean) flat.get("suckle");
		if (suckle != null) {
			Dictionary dict = suckle
					? dictionaryService.getDictionaryByDictEntry("Demographic Response Yes (in Yes or No)")
					: dictionaryService.getDictionaryByDictEntry("Demographic Response No (in Yes or No)");
			if (ObjectUtils.isNotEmpty(dict)) {
				observationData.setVlSuckle(dict.getId());
			}
		}

		// VL benefit
		String vlBenefit = (String) flat.get("vl_benefit");
		if (StringUtils.isNotBlank(vlBenefit)) {
			Dictionary dict = null;
			if (vlBenefit.equalsIgnoreCase("Oui") || vlBenefit.equalsIgnoreCase("Yes")) {
				dict = dictionaryService.getDictionaryByDictEntry("Demographic Response Yes (in Yes or No)");
			} else if (vlBenefit.equalsIgnoreCase("Non") || vlBenefit.equalsIgnoreCase("No")) {
				dict = dictionaryService.getDictionaryByDictEntry("Demographic Response No (in Yes or No)");
			}
			if (ObjectUtils.isNotEmpty(dict)) {
				observationData.setVlBenefit(dict.getId());
			}
		}

		// CD4 counts
		Double initCd4Count = toDouble(flat.get("init_cd4_count"));
		if (initCd4Count != null) {
			observationData.setInitcd4Count(initCd4Count.toString());
		}
		Double initCd4Percent = toDouble(flat.get("init_cd4_percent"));
		if (initCd4Percent != null) {
			observationData.setInitcd4Percent(initCd4Percent.toString());
		}
		Date initCd4Date = toDate(flat.get("init_cd4_date"));
		if (initCd4Date != null) {
			observationData.setInitcd4Date(DateUtil.formatDateAsText(initCd4Date));
		}
		Double demandCd4Count = toDouble(flat.get("demand_cd4_count"));
		if (demandCd4Count != null) {
			observationData.setDemandcd4Count(demandCd4Count.toString());
		}
		Double demandCd4Percent = toDouble(flat.get("demand_cd4_percent"));
		if (demandCd4Percent != null) {
			observationData.setDemandcd4Percent(demandCd4Percent.toString());
		}
		Date demandCd4Date = toDate(flat.get("demand_cd4_date"));
		if (demandCd4Date != null) {
			observationData.setDemandcd4Date(DateUtil.formatDateAsText(demandCd4Date));
		}

		// Prior VL
		String priorVlValue = (String) flat.get("prior_vl_value");
		if (StringUtils.isNotBlank(priorVlValue)) {
			observationData.setPriorVLValue(priorVlValue);
		}
		Date priorVlDate = toDate(flat.get("prior_vl_date"));
		if (priorVlDate != null) {
			observationData.setPriorVLDate(DateUtil.formatDateAsText(priorVlDate));
		}
		String priorVlLab = (String) flat.get("prior_vl_lab");
		if (StringUtils.isNotBlank(priorVlLab)) {
			observationData.setPriorVLLab(priorVlLab);
		}

		// Personnel
		String nameOfSampler = (String) flat.get("name_of_sampler");
		if (StringUtils.isNotBlank(nameOfSampler)) {
			observationData.setNameOfSampler(nameOfSampler);
		}
		String nameOfRequestor = (String) flat.get("name_of_requestor");
		if (StringUtils.isNotBlank(nameOfRequestor)) {
			observationData.setNameOfDoctor(nameOfRequestor);
		}

		projectData.setViralLoadTest(true);
		form.setProjectData(projectData);
		form.setObservations(observationData);
	}

	/**
	 * Normalise le code site provenant de la demande électronique en un code sur 5 caractères.
	 *
	 * Cas 1 — code SSSS (ex: "SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS0538") :
	 *   Extraire les chiffres finaux, padder à 5 chiffres si nécessaire.
	 *
	 * Cas 2 — UUID (ex: "9d1b819e-b74b-11eb-afef-c8f75041a8b5") :
	 *   Prendre les 5 derniers caractères après suppression des tirets.
	 *
	 * Cas 3 — code déjà normalisé : retourner tel quel.
	 */
	private String normalizeSiteCode(String rawCode) {
		if (StringUtils.isBlank(rawCode)) {
			return rawCode;
		}
		// Cas 1 : commence par S (format SSSS...NNNN)
		if (rawCode.startsWith("S") || rawCode.matches("S+\\d+")) {
			// Extraire les chiffres finals
			String digits = rawCode.replaceAll("^[Ss]+", "");
			// Garder uniquement les chiffres (au cas où il y aurait des chars parasites)
			digits = digits.replaceAll("[^0-9]", "");
			if (digits.isEmpty()) {
				return rawCode;
			}
			// Prendre les 5 derniers chiffres si trop long, sinon padder à 5
			if (digits.length() > 5) {
				digits = digits.substring(digits.length() - 5);
			} else {
				digits = String.format("%05d", Long.parseLong(digits));
			}
			return digits;
		}
		// Cas 2 : UUID (contient des tirets et longueur ~36)
		if (rawCode.matches("[0-9a-fA-F\\-]{36}")) {
			String noHyphens = rawCode.replace("-", "");
			return noHyphens.substring(noHyphens.length() - 5);
		}
		// Cas 3 : code déjà court (≤ 5 chars) ou autre format — retourner tel quel
		return rawCode;
	}

	private Date toDate(Object value) {
		if (value instanceof Date) {
			return (Date) value;
		}
		if (value instanceof java.sql.Date) {
			return new Date(((java.sql.Date) value).getTime());
		}
		if (value instanceof Timestamp) {
			return new Date(((Timestamp) value).getTime());
		}
		return null;
	}

	private Double toDouble(Object value) {
		if (value instanceof Number) {
			return ((Number) value).doubleValue();
		}
		return null;
	}

	@RequestMapping(value = "/SampleEntryByProject", method = RequestMethod.POST)
	public ModelAndView postSampleEntryByProject(HttpServletRequest request,
			@ModelAttribute("form") @Valid SampleEntryByProjectForm form, BindingResult result,
			RedirectAttributes redirectAttributes) {
		if (result.hasErrors()) {
			saveErrors(result);
			setDisplayLists(form);
			return findForward(FWD_FAIL_INSERT, form);
		}
		String forward;

		ISampleSecondEntry sampleSecondEntry = SpringContext.getBean(ISampleSecondEntry.class);
		sampleSecondEntry.setFieldsFromForm(form);
		sampleSecondEntry.setSysUserId(getSysUserId(request));
		sampleSecondEntry.setRequest(request);
		if (sampleSecondEntry.canAccession()) {
			forward = handleSave(request, sampleSecondEntry, form);
			updateElectronicOrderStatus(form);
			if (forward != null) {
				if (FWD_SUCCESS_INSERT.equals(forward)) {
					redirectAttributes.addFlashAttribute(FWD_SUCCESS, true);
				} else {
					setDisplayLists(form);
				}
				return findForward(forward, form);
			}
		}
		ISampleEntry sampleEntry = SpringContext.getBean(ISampleEntry.class);
		sampleEntry.setFieldsFromForm(form);
		sampleEntry.setSysUserId(getSysUserId(request));
		sampleEntry.setRequest(request);
		if (sampleEntry.canAccession()) {
			forward = handleSave(request, sampleEntry, form);
			updateElectronicOrderStatus(form);
			if (forward != null) {
				if (FWD_SUCCESS_INSERT.equals(forward)) {
					redirectAttributes.addFlashAttribute(FWD_SUCCESS, true);
				} else {
					setDisplayLists(form);
				}
				return findForward(forward, form);
			}
		}
		ISampleEntryAfterPatientEntry sampleEntryAfterPatientEntry = SpringContext
				.getBean(ISampleEntryAfterPatientEntry.class);
		sampleEntryAfterPatientEntry.setFieldsFromForm(form);
		sampleEntryAfterPatientEntry.setSysUserId(getSysUserId(request));
		sampleEntryAfterPatientEntry.setRequest(request);
		if (sampleEntryAfterPatientEntry.canAccession()) {
			forward = handleSave(request, sampleEntryAfterPatientEntry, form);
			updateElectronicOrderStatus(form);
			if (forward != null) {
				if (FWD_SUCCESS_INSERT.equals(forward)) {
					redirectAttributes.addFlashAttribute(FWD_SUCCESS, true);
				} else {
					setDisplayLists(form);
				}
				return findForward(forward, form);
			}
		}
		logAndAddMessage(request, "postSampleEntryByProject", "errors.UpdateException");

		setDisplayLists(form);
		return findForward(FWD_FAIL_INSERT, form);
	}

	private void updateElectronicOrderStatus(SampleEntryByProjectForm form) {
		try {
			if (ObjectUtils.isNotEmpty(form.getElectronicOrder())) {
				String externalOrderId = form.getElectronicOrder().getExternalId();
				List<ElectronicOrder> eOrders = electronicOrderService.getElectronicOrdersByExternalId(externalOrderId);
				if (eOrders.size() > 0) {
					ElectronicOrder eOrder = eOrders.get(eOrders.size() - 1);
					eOrder.setStatusId(
							SpringContext.getBean(IStatusService.class).getStatusID(ExternalOrderStatus.InProgress));
					eOrder.setSyncFlag(0);
					electronicOrderService.update(eOrder);
					form.setElectronicOrder(eOrder);

					// Mettre à jour la table plate pour remontée vers le serveur consolidé
					eorderFlatQueryService.updateLocalStatus(
							externalOrderId, "IN_PROGRESS", null, null, null);
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
			LogEvent.logError(e);
		}
	}

	public SampleItem getSampleItem(Sample sample, TypeOfSample typeofsample) {
		SampleItem item = new SampleItem();
		item.setSample(sample);
		item.setTypeOfSample(typeofsample);
		item.setSortOrder(Integer.toString(1));
		item.setStatusId(SpringContext.getBean(IStatusService.class).getStatusID(SampleStatus.Entered));

		return item;
	}

	private void setDisplayLists(SampleEntryByProjectForm form) {
		Map<String, List<Dictionary>> formListsMapOfLists = new HashMap<>();
		List<Dictionary> listOfDictionary = new ArrayList<>();
		List<IdValuePair> genders = DisplayListService.getInstance().getList(ListType.GENDERS);

		for (IdValuePair i : genders) {
			Dictionary dictionary = new Dictionary();
			dictionary.setId(i.getId());
			dictionary.setDictEntry(i.getValue());
			listOfDictionary.add(dictionary);
		}

		formListsMapOfLists.put("GENDERS", listOfDictionary);
		form.setFormLists(formListsMapOfLists);

		// Get Lists
		Map<String, List<Dictionary>> observationHistoryMapOfLists = new HashMap<>();
		observationHistoryMapOfLists.put("EID_WHICH_PCR", ObservationHistoryList.EID_WHICH_PCR.getList());
		observationHistoryMapOfLists.put("EID_SECOND_PCR_REASON",
				ObservationHistoryList.EID_SECOND_PCR_REASON.getList());
		observationHistoryMapOfLists.put("EID_TYPE_OF_CLINIC", ObservationHistoryList.EID_TYPE_OF_CLINIC.getList());
		observationHistoryMapOfLists.put("EID_HOW_CHILD_FED", ObservationHistoryList.EID_HOW_CHILD_FED.getList());
		observationHistoryMapOfLists.put("EID_STOPPED_BREASTFEEDING",
				ObservationHistoryList.EID_STOPPED_BREASTFEEDING.getList());
		observationHistoryMapOfLists.put("YES_NO", ObservationHistoryList.YES_NO.getList());
		observationHistoryMapOfLists.put("EID_INFANT_PROPHYLAXIS_ARV",
				ObservationHistoryList.EID_INFANT_PROPHYLAXIS_ARV.getList());
		observationHistoryMapOfLists.put("YES_NO_UNKNOWN", ObservationHistoryList.YES_NO_UNKNOWN.getList());
		observationHistoryMapOfLists.put("EID_MOTHERS_HIV_STATUS",
				ObservationHistoryList.EID_MOTHERS_HIV_STATUS.getList());
		observationHistoryMapOfLists.put("EID_MOTHERS_ARV_TREATMENT",
				ObservationHistoryList.EID_MOTHERS_ARV_TREATMENT.getList());
		observationHistoryMapOfLists.put("HIV_STATUSES", ObservationHistoryList.HIV_STATUSES.getList());
		observationHistoryMapOfLists.put("HIV_TYPES", ObservationHistoryList.HIV_TYPES.getList());
		observationHistoryMapOfLists.put("SPECIAL_REQUEST_REASONS",
				ObservationHistoryList.SPECIAL_REQUEST_REASONS.getList());
		observationHistoryMapOfLists.put("ARV_REGIME", ObservationHistoryList.ARV_REGIME.getList());
		observationHistoryMapOfLists.put("ARV_REASON_FOR_VL_DEMAND",
				ObservationHistoryList.ARV_REASON_FOR_VL_DEMAND.getList());
		observationHistoryMapOfLists.put("HPV_SAMPLING_METHOD", ObservationHistoryList.HPV_SAMPLING_METHOD.getList());

		form.setDictionaryLists(observationHistoryMapOfLists);

		// Get EID Sites
		Map<String, List<Organization>> organizationTypeMapOfLists = new HashMap<>();
		organizationTypeMapOfLists.put("ARV_ORGS", OrganizationTypeList.ARV_ORGS.getList());
		organizationTypeMapOfLists.put("ARV_ORGS_BY_NAME", OrganizationTypeList.ARV_ORGS_BY_NAME.getList());
		organizationTypeMapOfLists.put("EID_ORGS_BY_NAME", OrganizationTypeList.EID_ORGS_BY_NAME.getList());
		organizationTypeMapOfLists.put("EID_ORGS", OrganizationTypeList.EID_ORGS.getList());
		form.setOrganizationTypeLists(organizationTypeMapOfLists);
	}

	@Override
	protected String findLocalForward(String forward) {
		if (FWD_SUCCESS.equals(forward)) {
			return "sampleEntryByProjectDefinition";
		} else if (FWD_FAIL.equals(forward)) {
			return "homePageDefinition";
		} else if (FWD_SUCCESS_INSERT.equals(forward)) {
			return "redirect:/SampleEntryByProject?type=" + Encode.forUriComponent(request.getParameter("type"));
		} else if (FWD_FAIL_INSERT.equals(forward)) {
			return "sampleEntryByProjectDefinition";
		} else {
			return "PageNotFound";
		}
	}

	@Override
	protected String getPageTitleKey() {
		return null;
	}

	@Override
	protected String getPageSubtitleKey() {
		return null;
	}
}
