<%@ page language="java" contentType="text/html; charset=UTF-8"
	import="org.openelisglobal.common.action.IActionConstants,
				org.openelisglobal.sample.util.AccessionNumberUtil,
				org.openelisglobal.login.valueholder.UserSessionData,
	            org.openelisglobal.common.util.*, org.openelisglobal.internationalization.MessageUtil,
	            org.openelisglobal.common.util.ConfigurationProperties.Property,java.util.HashSet,
	            org.owasp.encoder.Encode"%>
<%@ page isELIgnored="false"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%@ taglib prefix="ajax" uri="/tags/ajaxtags"%>

<c:set var="formName" value="${form.formName}" />
<c:set var="requestType" value="${type}" />
<c:set var="genericDomain" value="" />

<%
String requestType = (String) request.getParameter("type");
HashSet accessMap = (HashSet) request.getSession().getAttribute(IActionConstants.PERMITTED_ACTIONS_MAP);
boolean isAdmin = ((UserSessionData) request.getSession().getAttribute(IActionConstants.USER_SESSION_DATA)).isAdmin();
// no one should edit patient numbers at this time.  PAH 11/05/2010
boolean canEditPatientSubjectNos = isAdmin
		|| accessMap.contains(IActionConstants.MODULE_ACCESS_PATIENT_SUBJECTNOS_EDIT);
boolean canEditAccessionNo = isAdmin || accessMap.contains(IActionConstants.MODULE_ACCESS_SAMPLE_ACCESSIONNO_EDIT);
boolean acceptExternalOrders = ConfigurationProperties.getInstance()
		.isPropertyValueEqual(Property.ACCEPT_EXTERNAL_ORDERS, "true");
boolean serologyControl = ConfigurationProperties.getInstance()
		.isPropertyValueEqual(Property.SEROLOGY_CONTROL, "true");
%>

<script type="text/javascript" src="scripts/utilities.js?"></script>
<script type="text/javascript" src="scripts/ajaxCalls.js?"></script>
<script type="text/javascript" src="scripts/neon2/retroCIUtilities.js?"></script>
<script type="text/javascript" src="scripts/entryByProjectUtils.js?"></script>
<script type="text/javascript" src="select2/js/select2.min.js"></script>
<link rel="stylesheet" type="text/css" href="select2/css/select2.min.css">



<script type="text/javascript">

function clearFormElement(field) 
{
    if (field == null) return;
	var type = field.type.toLowerCase();
	switch(type) {
	case "text":
	case "password":
	case "textarea":
	case "hidden":
		field.value = "";
		break;
	case "radio":
	case "checkbox":
		if (field.checked) {
			field.checked = false;
		}
		break;
	case "select-one":
	case "select-multi":
		field.selectedIndex = -1;
		break;
	default:
		break;
	}
}

function clearFormElements(fieldIds)
{
	var fields = fieldIds.split(',');
	for (var i=0; i< fields.length; i++) {
		clearFormElement($(fields[i].trim()));
	}
}

var dirty = false;
var type = '<%=Encode.forJavaScript(requestType)%>';
var requestType = '<%=Encode.forJavaScript(requestType)%>';
	var pageType = "Sample";
	birthDateUsageMessage = "<spring:message code='error.dob.complete.less.two.years'/>";
	previousNotMatchedMessage = "<spring:message code='error.2ndEntry.previous.not.matched'/>";
	noMatchFoundMessage = "<spring:message code='patient.message.patientNotFound'/>";
	saveNotUnderInvestigationMessage = "<spring:message code='patient.project.conflicts.saveNotUnderInvestigation'/>";
	testInvalid = "<spring:message code='error.2ndEntry.test.invalid'/>";
	blankTextField = "<spring:message code='blank.text.field'/>";
	electronicOrderAvailbaleMessage = "<spring:message code='electronic.order.available'/>";

	var canEditPatientSubjectNos =<%=canEditPatientSubjectNos%>;
	var canEditAccessionNo =<%=canEditAccessionNo%>	;
	var serologyControlEnabled = <%= serologyControl %>;

	function /*void*/setMyCancelAction(form, action, validate, parameters) {
		//first turn off any further validation
		setAction(document.getElementById("mainForm"), 'Cancel', 'no', '');
	}

	function Studies() {
		this.validators = new Array();
		this.studyNames = [ "InitialARV_Id", "FollowUp_ARV_Id",
				"EID_Id", "VL_Id", "Recency_Id","HPV_Id" ];

		this.validators["InitialARV_Id"] = new FieldValidator();
		this.validators["InitialARV_Id"].setRequiredFields(new Array(
				"iarv.labNo", "iarv.receivedDateForDisplay",
				"iarv.interviewDate", "iarv.centerCode",
				"subjectOrSiteSubject", "iarv.gender", "iarv.dateOfBirth"));

		this.validators["FollowUpARV_Id"] = new FieldValidator();
		this.validators["FollowUpARV_Id"].setRequiredFields(new Array(
				"farv.labNo", "farv.receivedDateForDisplay",
				"farv.interviewDate", "farv.centerCode",
				"subjectOrSiteSubject", "farv.gender", "farv.dateOfBirth"));

		this.validators["EID_Id"] = new FieldValidator();
		this.validators["EID_Id"].setRequiredFields(new Array(
				"eid.receivedDateForDisplay", "eid.interviewDate",
				"eid.gender", "eid.dateOfBirth","eid.centerCode", "eid.centerName",
				"eid.labNo"));

		this.validators["VL_Id"] = new FieldValidator();
		this.validators["VL_Id"].setRequiredFields(new Array(
				"vl.centerCode","vl.receivedDateForDisplay", "vl.interviewDate", "vl.gender",
				"vl.dateOfBirth", "subjectOrSiteSubject", "vl.labNo"));

		//"vl.vlSuckle","vl.vlPregnancy"

		this.validators["Recency_Id"] = new FieldValidator();
		this.validators["Recency_Id"].setRequiredFields(new Array(
				"rt.centerCode", "rt.receivedDateForDisplay",
				"rt.interviewDate", "rt.gender", "rt.labno", "rt.asanteTest",
				"rt.dateOfBirth","vl.vlSuckle","vl.vlPregnancy"));
		this.validators["HPV_Id"] = new FieldValidator();
		this.validators["HPV_Id"].setRequiredFields(new Array("hpv.centerCode", "hpv.interviewDate", "hpv.siteSubjectNumber", "hpv.labNo","hpv.dateOfBirth"));

		this.getValidator = function /*FieldValidator*/(divId) {
			return this.validators[divId];
		}

		this.projectChecker = new Array();

		this.initializeProjectChecker = function() {
			this.projectChecker["InitialARV_Id"] = iarv;
			this.projectChecker["FollowUpARV_Id"] = farv;
			this.projectChecker["EID_Id"] = eid;
			this.projectChecker["VL_Id"] = vl;
			this.projectChecker["Recency_Id"] = rt;
			this.projectChecker["HPV_Id"] = hpv;
		}

		this.getProjectChecker = function(divId) {
			this.initializeProjectChecker(); // not clear why a navigating back to this page makes field checkers empty, so we'll always load.
			return this.projectChecker[divId];
		}
	}

	studies = new Studies();
	projectChecker = null;

	function /*void*/makeDirty() {
		dirty = true;
		if (typeof (showSuccessMessage) === 'function') {
			showSuccessMessage(false); //refers to last save
		}
		function formWarning() {
			return "<spring:message code="banner.menu.dataLossWarning"/>";
		}
		window.onbeforeunload = formWarning;
	}

	/*
	 * Set default tests by study, but 
	 */
	function setDefaultTests(div) {
		if (requestType != 'initial') {
			return;
		}
		var tests = new Array();
		if (div == "InitialARV_Id") {

			tests = new Array("iarv.serologyHIVTest", "iarv.creatinineTest",
					"iarv.edtaTubeTaken", "iarv.dryTubeTaken", "iarv.nfsTest",
					"iarv.cd4cd8Test");
		}

		if (div == "FollowUpARV_Id") {
			tests = new Array("farv.creatinineTest", "farv.dryTubeTaken");
		}

		if (div == "EID_Id") {
			tests = new Array("eid.dnaPCR", "eid.dbsTaken");
		}

		if (div == "VL_Id") {
			tests = new Array("vl.viralLoadTest");
		}

		if (div == "Recency_Id") {
			tests = new Array("rt.asanteTest");
		}
		if (div == "HPV_Id") {
			tests = new Array("hpv.hpvTest");
		}

		for (var i = 0; i < tests.length; i++) {
			var testId = tests[i];
			$(testId).value = true;
			$(testId).checked = true;
		}
	}

	function initializeStudySelection() {
		selectStudy(sessionStorage.getItem("selectedDivId"));
	}

	function selectStudy(divId) {
		var i = getSelectIndexFor("studyFormsId", divId);
		document.getElementById("mainForm").studyForms.selectedIndex = i;
		switchStudyForm(divId);
	}

	function switchStudyForm(divId) {
		hideAllDivs();
		if (divId != "" && divId != "0") {
			sessionStorage.setItem("selectedDivId", divId);
			$("projectFormName").value = divId;
			switch (divId) {
			case "EID_Id":
				break;
			case "VL_Id":
				break;
			}
			toggleDisabledDiv(document.getElementById(divId), true);
			document.getElementById("mainForm").project.value = divId;
			if (divId) {
				document.getElementById(divId).style.display = "block";
			}
			fieldValidator = studies.getValidator(divId); // reset the page fieldValidator for all fields to use.
			projectChecker = studies.getProjectChecker(divId);
			projectChecker.setSubjectOrSiteSubjectEntered();
			adjustFieldsForRequestType();
			setDefaultTests(divId);
			setSaveButton();
		}
	}
	function adjustFieldsForRequestType() {
		switch (requestType) {
		case "initial":
			break;
		case "verify":
			break;
		}
	}

	function hideAllDivs() {
		resetVLSerologySearch();
		toggleDisabledDiv(document.getElementById("InitialARV_Id"), false);
		toggleDisabledDiv(document.getElementById("FollowUpARV_Id"), false);
		toggleDisabledDiv(document.getElementById("EID_Id"), false);
		toggleDisabledDiv(document.getElementById("VL_Id"), false);
		toggleDisabledDiv(document.getElementById("Recency_Id"), false);
		toggleDisabledDiv(document.getElementById("HPV_Id"), false);

		document.getElementById('InitialARV_Id').style.display = "none";
		document.getElementById('FollowUpARV_Id').style.display = "none";
		document.getElementById('EID_Id').style.display = "none";
		document.getElementById('VL_Id').style.display = "none";
		document.getElementById('Recency_Id').style.display = "none";
		document.getElementById('HPV_Id').style.display = "none";
	}

	function /*boolean*/allSamplesHaveTests() {
		// based on studyType, check that at least one test is chosen
		// TODO PAHill this check is done on the server, but could be done here also.
	}

	function /*void*/savePage__(action) {
		window.onbeforeunload = null; 
		var form = document.getElementById("mainForm");
		if (action == null) {
			action = "SampleEntryByProject?type=" + type
		}
		form.action = action;
		form.submit();
	}

	function /*void*/setSaveButton() {
		var validToSave = fieldValidator.isAllValid();

		$("saveButtonId").disabled = !validToSave;

	}

	/**
	 * VL Serology search: search for patient and check if serology result exists.
	 * Shows the main VL form after search completes.
	 */
	function searchVLPatientSerology() {
		var subjectNo = document.getElementById("vl.searchSubjectNumber").value.trim();
		var siteSubjectNo = document.getElementById("vl.searchSiteSubjectNumber").value.trim();

		if (!subjectNo && !siteSubjectNo) {
			document.getElementById("vl.searchPatientStatus").innerHTML =
				'<span style="color:red;"><spring:message code="sample.entry.project.patientSearch.required" text="Veuillez saisir un Sujet No. ou Site Sujet No." /></span>';
			return;
		}

		document.getElementById("vl.searchPatientStatus").innerHTML =
			'<spring:message code="label.searching" text="Recherche en cours..." />';
		document.getElementById("vl.searchPatientButton").disabled = true;
		document.getElementById("vl.mainForm").style.display = "none";

		// Clear form subject fields for new search
		var subField = document.getElementById("vl.subjectNumber");
		var siteSubField = document.getElementById("vl.siteSubjectNumber");
		if (subField) subField.value = "";
		if (siteSubField) siteSubField.value = "";

		if (serologyControlEnabled) {
			// Serology control ON: search patient + serology via dedicated provider
			getSerologyResultForPatient(subjectNo, siteSubjectNo,
				function(xhr) { handleVLSerologySearchResult(xhr, subjectNo, siteSubjectNo); },
				function(xhr) { handleVLSerologySearchFailure(subjectNo, siteSubjectNo); }
			);
		} else {
			// Serology control OFF: search patient only via existing patient loader
			handleVLPatientOnlySearch(subjectNo, siteSubjectNo);
		}
	}

	/**
	 * When serology control is disabled: search patient by nationalID or externalID,
	 * load demographics if found, show form with hivStatus enabled for manual selection.
	 */
	function handleVLPatientOnlySearch(subjectNo, siteSubjectNo) {
		// Use the search subject number field to trigger patient lookup
		var searchField = subjectNo
			? document.getElementById("vl.subjectNumber")
			: document.getElementById("vl.siteSubjectNumber");
		var searchValue = subjectNo || siteSubjectNo;
		var searchBy = subjectNo ? "nationalID" : "externalID";

		// Temporarily set the field value for the search
		if (searchField) searchField.value = searchValue;

		patientLoader.findPatientBy(searchBy, searchField, false,
			function() {
				document.getElementById("vl.searchPatientButton").disabled = false;
				var patientFound = (patientLoader.existing != null);

				if (patientFound) {
					document.getElementById("vl.searchPatientStatus").innerHTML =
						'<span style="color:green;"><spring:message code="sample.entry.project.patientSearch.found" text="Patient trouv\u00e9" /></span>';

					// Populate VL form fields from loaded patient data
					var existing = patientLoader.existing;
					var nationalID = patientLoader.getResponseProperty(existing, "nationalID");
					var externalID = patientLoader.getResponseProperty(existing, "externalID");
					var dob = patientLoader.getResponseProperty(existing, "dob");
					var gender = patientLoader.getResponseProperty(existing, "gender");

					if (nationalID) document.getElementById("vl.subjectNumber").value = nationalID;
					if (externalID) document.getElementById("vl.siteSubjectNumber").value = externalID;

					var dobField = document.getElementById("vl.dateOfBirth");
					if (dob && dobField) {
						dobField.value = dob;
						handlePatientBirthDateChange(dobField, $("vl.interviewDate"), false, $("vl.age"));
					}

					var genderField = document.getElementById("vl.gender");
					if (gender && genderField) {
						for (var i = 0; i < genderField.options.length; i++) {
							if (genderField.options[i].value === gender) {
								genderField.selectedIndex = i;
								break;
							}
						}
					}
				} else {
					document.getElementById("vl.searchPatientStatus").innerHTML =
						'<span style="color:orange;"><spring:message code="sample.entry.project.patientSearch.notFound" text="Patient non trouv\u00e9" /></span>';
					// Prefill searched values
					if (subjectNo) document.getElementById("vl.subjectNumber").value = subjectNo;
					if (siteSubjectNo) document.getElementById("vl.siteSubjectNumber").value = siteSubjectNo;
				}

				// No serology control: hivStatus enabled for manual selection, no serology tests
				var hivStatusSelect = document.getElementById("vl.hivStatus");
				var hivStatusHidden = document.getElementById("vl.hivStatusHidden");
				var hivStatusRequired = document.getElementById("vl.hivStatusRequired");
				hivStatusSelect.disabled = false;
				hivStatusSelect.selectedIndex = 0;
				hivStatusHidden.disabled = true;
				hivStatusRequired.textContent = "*";

				// Hide serology-related rows
				document.getElementById("vl.serologyHIVTestRow").style.display = "none";
				var serologyCheckbox = document.getElementById("vl.serologyHIVTest");
				if (serologyCheckbox) { serologyCheckbox.checked = false; serologyCheckbox.disabled = true; }
				document.getElementById("vl.dryTubeTakenRow").style.display = "none";
				var dryTubeCheckbox = document.getElementById("vl.dryTubeTaken");
				if (dryTubeCheckbox) dryTubeCheckbox.checked = false;

				// Always check viral load test
				var vlTest = document.getElementById("vl.viralLoadTest");
				if (vlTest && !vlTest.checked) vlTest.checked = true;

				// Show the form and trigger validation
				document.getElementById("vl.mainForm").style.display = "block";
				vl.setSubjectOrSiteSubjectEntered();
				vl.checkAllSubjectFields(true, false);
				makeDirty();
				setSaveButton();
			}
		);
	}

	function handleVLSerologySearchResult(xhr, searchSubjectNo, searchSiteSubjectNo) {
		document.getElementById("vl.searchPatientButton").disabled = false;

		var xml = xhr.responseXML;
		var message = xml.getElementsByTagName("message").item(0);
		var formfield = xml.getElementsByTagName("formfield").item(0);

		if (!message || !formfield) {
			document.getElementById("vl.searchPatientStatus").innerHTML =
				'<span style="color:red;"><spring:message code="sample.entry.project.patientSearch.error" text="Erreur lors de la recherche" /></span>';
			showVLMainForm(searchSubjectNo, searchSiteSubjectNo, null, null, false);
			return;
		}

		var isValid = (message.firstChild.nodeValue === "valid");

		if (!isValid) {
			// Patient not found (message=invalid) — show form for new entry
			document.getElementById("vl.searchPatientStatus").innerHTML =
				'<span style="color:orange;"><spring:message code="sample.entry.project.patientSearch.notFound" text="Patient non trouv\u00e9" /></span>';
			showVLMainForm(searchSubjectNo, searchSiteSubjectNo, null, null, false);
			return;
		}

		var patientPK = getXMLValue(formfield, "patientPK");
		var subjectNumber = getXMLValue(formfield, "subjectNumber");
		var siteSubjectNumber = getXMLValue(formfield, "siteSubjectNumber");
		var serologyResult = getXMLValue(formfield, "serologyResult");

		// Clean up placeholder values from backend
		if (subjectNumber === "N/A") subjectNumber = null;
		if (siteSubjectNumber === "N/A") siteSubjectNumber = null;
		// Only consider serology valid if result is HIV1, HIV2 or HIVD
		var validSerologyResults = ["HIV1", "HIV2", "HIVD"];
		var hasSerology = (serologyResult && validSerologyResults.indexOf(serologyResult) !== -1);
		if (!hasSerology) serologyResult = null;

		document.getElementById("vl.searchPatientStatus").innerHTML =
			'<span style="color:green;"><spring:message code="sample.entry.project.patientSearch.found" text="Patient trouv\u00e9" /></span>';

		showVLMainForm(
			subjectNumber || searchSubjectNo,
			siteSubjectNumber || searchSiteSubjectNo,
			patientPK,
			serologyResult,
			hasSerology
		);
	}

	function handleVLSerologySearchFailure(searchSubjectNo, searchSiteSubjectNo) {
		document.getElementById("vl.searchPatientButton").disabled = false;
		document.getElementById("vl.searchPatientStatus").innerHTML =
			'<span style="color:orange;"><spring:message code="sample.entry.project.patientSearch.notFound" text="Patient non trouv\u00e9" /></span>';
		// Show the form anyway so the user can fill it for a new patient
		showVLMainForm(searchSubjectNo, searchSiteSubjectNo, null, null, false);
	}

	/**
	 * Show VL form with serology control logic (only called when serologyControlEnabled=true).
	 */
	function showVLMainForm(subjectNumber, siteSubjectNumber, patientPK, serologyResult, hasSerology) {
		// Prefill subject numbers
		var subField = document.getElementById("vl.subjectNumber");
		var siteSubField = document.getElementById("vl.siteSubjectNumber");

		if (subjectNumber && subField) {
			subField.value = subjectNumber;
		}
		if (siteSubjectNumber && siteSubField) {
			siteSubField.value = siteSubjectNumber;
		}

		// Set patient PK if found and load demographics
		if (patientPK) {
			document.getElementById("patientPK").value = patientPK;
			patientLoader.findPatientBy("personKey", document.getElementById("patientPK"), false,
				function() {
					populateVLFieldsFromPatientData();
					vl.setSubjectOrSiteSubjectEntered();
					vl.checkAllSubjectFields(true, false);
					makeDirty();
					setSaveButton();
				}
			);
		} else {
			vl.setSubjectOrSiteSubjectEntered();
		}

		var hivStatusSelect = document.getElementById("vl.hivStatus");
		var hivStatusHidden = document.getElementById("vl.hivStatusHidden");
		var hivStatusRequired = document.getElementById("vl.hivStatusRequired");
		var serologyRow = document.getElementById("vl.serologyHIVTestRow");
		var serologyCheckbox = document.getElementById("vl.serologyHIVTest");

		// Always ensure viral load test is checked
		var vlTest = document.getElementById("vl.viralLoadTest");
		if (vlTest && !vlTest.checked) {
			vlTest.checked = true;
		}

		if (hasSerology) {
			// Serology exists: prefill hivStatus, make it readonly
			setHivStatusFromSerologyResult(serologyResult);
			hivStatusSelect.disabled = true;
			hivStatusHidden.disabled = false;
			hivStatusHidden.value = hivStatusSelect.value;
			hivStatusRequired.textContent = "*";

			// Hide serology test row - not needed
			serologyRow.style.display = "none";
			if (serologyCheckbox) {
				serologyCheckbox.checked = false;
				serologyCheckbox.disabled = true;
			}
		} else {
			// No serology: hivStatus disabled, add serology tests
			hivStatusSelect.disabled = true;
			hivStatusSelect.selectedIndex = 0;
			hivStatusHidden.disabled = true;
			hivStatusRequired.textContent = "";

			// Show serology test row, checked and mandatory
			serologyRow.style.display = "";
			if (serologyCheckbox) {
				serologyCheckbox.checked = true;
				serologyCheckbox.disabled = false;
			}
			// Show and check dry tube row (needed for serology)
			var dryTubeRow = document.getElementById("vl.dryTubeTakenRow");
			var dryTubeCheckbox = document.getElementById("vl.dryTubeTaken");
			if (dryTubeRow) dryTubeRow.style.display = "";
			if (dryTubeCheckbox) dryTubeCheckbox.checked = true;
		}

		// Show the main form
		document.getElementById("vl.mainForm").style.display = "block";
		makeDirty();
		setSaveButton();
	}

	/**
	 * Populate VL form fields from patientLoader.existing data (shared helper).
	 */
	function populateVLFieldsFromPatientData() {
		var existing = patientLoader.existing;
		if (!existing) return;

		var nationalID = patientLoader.getResponseProperty(existing, "nationalID");
		var externalID = patientLoader.getResponseProperty(existing, "externalID");
		var dob = patientLoader.getResponseProperty(existing, "dob");
		var gender = patientLoader.getResponseProperty(existing, "gender");

		if (nationalID) document.getElementById("vl.subjectNumber").value = nationalID;
		if (externalID) document.getElementById("vl.siteSubjectNumber").value = externalID;

		var dobField = document.getElementById("vl.dateOfBirth");
		if (dob && dobField) {
			dobField.value = dob;
			handlePatientBirthDateChange(dobField, $("vl.interviewDate"), false, $("vl.age"));
		}

		var genderField = document.getElementById("vl.gender");
		if (gender && genderField) {
			for (var i = 0; i < genderField.options.length; i++) {
				if (genderField.options[i].value === gender) {
					genderField.selectedIndex = i;
					break;
				}
			}
		}
	}

	function setHivStatusFromSerologyResult(serologyResult) {
		var hivSelect = document.getElementById("vl.hivStatus");
		if (!hivSelect || !serologyResult) return;

		// Map Innolia conclusion values to VIH select option text
		var conclusionToVIH = {
			"HIV1": "VIH-1",
			"HIV2": "VIH-2",
			"HIVD": "VIH-1+2"
		};

		var targetText = conclusionToVIH[serologyResult];
		if (targetText) {
			for (var i = 0; i < hivSelect.options.length; i++) {
				if (hivSelect.options[i].text.trim() === targetText) {
					hivSelect.selectedIndex = i;
					return;
				}
			}
		}

		// Fallback: try partial text match
		for (var i = 0; i < hivSelect.options.length; i++) {
			var optText = hivSelect.options[i].text.trim().toLowerCase();
			if (optText.indexOf(serologyResult.toLowerCase()) !== -1) {
				hivSelect.selectedIndex = i;
				return;
			}
		}
	}

	function getXMLValue(xml, key) {
		if (!xml) return null;
		var nodes = xml.getElementsByTagName(key);
		if (nodes && nodes.length > 0 && nodes[0].childNodes.length > 0) {
			return nodes[0].childNodes[0].nodeValue;
		}
		return null;
	}

	/**
	 * Reset VL form when switching away from VL study
	 */
	function resetVLSerologySearch() {
		var mainForm = document.getElementById("vl.mainForm");
		if (mainForm) mainForm.style.display = "none";

		var statusSpan = document.getElementById("vl.searchPatientStatus");
		if (statusSpan) statusSpan.innerHTML = "";

		var searchSubject = document.getElementById("vl.searchSubjectNumber");
		if (searchSubject) searchSubject.value = "";

		var searchSite = document.getElementById("vl.searchSiteSubjectNumber");
		if (searchSite) searchSite.value = "";

		var hivSelect = document.getElementById("vl.hivStatus");
		if (hivSelect) {
			hivSelect.disabled = false;
			hivSelect.selectedIndex = 0;
		}
		var hivHidden = document.getElementById("vl.hivStatusHidden");
		if (hivHidden) hivHidden.disabled = true;

		var serologyRow = document.getElementById("vl.serologyHIVTestRow");
		if (serologyRow) serologyRow.style.display = "none";

		var dryTubeRow = document.getElementById("vl.dryTubeTakenRow");
		if (dryTubeRow) dryTubeRow.style.display = "none";
	}
</script>

<form:hidden path="currentDate" id="currentDate" />
<form:hidden path="domain" value="${genericDomain}" id="domain" />
<form:hidden path="project" id="project" />
<form:hidden path="patientLastUpdated" id="patientLastUpdated" />
<form:hidden path="personLastUpdated" id="personLastUpdated" />
<form:hidden path="patientUpdateStatus" id="processingStatus" />
<form:hidden path="patientPK" id="patientPK" />
<form:hidden path="samplePK" id="samplePK" />
<form:hidden path="observations.projectFormName" id="projectFormName" />
<form:hidden path="" id="subjectOrSiteSubject" value="" />
<form:hidden path="patientFhirUuid" id="patientFhirUuid" />

<b><spring:message code="sample.entry.project.form" /></b>
<select name="studyForms" onchange="switchStudyForm(this.value);"
	id="studyFormsId" autofocus="autofocus">
	<option value="0" selected></option>
	<option value="InitialARV_Id"><spring:message
			code="sample.entry.project.initialARV.title" /></option>
	<option value="FollowUpARV_Id"><spring:message
			code="sample.entry.project.followupARV.title" /></option>
	<option value="EID_Id"><spring:message
			code="sample.entry.project.EID.title" /></option>
	<option value="VL_Id"><spring:message
			code="sample.entry.project.VL.title" /></option>
	<option value="Recency_Id"><spring:message
			code="sample.entry.project.RT.title" /></option>
	<option value="HPV_Id"><spring:message
			code="sample.entry.project.HPV.title" /></option>
</select>
<br />
<hr>

<div id="studies">
	<div id="InitialARV_Id" style="display: none;">
		<h2>
			<spring:message code="sample.entry.project.initialARV.title" />
		</h2>
		<table width="100%">
			<tr>
				<td class="required" width="2%">*</td>
				<td width="28%"><spring:message
						code="sample.entry.project.ARV.centerName" /></td>
				<td width="70%"><form:select path="ProjectData.ARVcenterName"
						id="iarv.centerName" onchange="iarv.checkCenterName(true)">
						<option value="">&nbsp;</option>
						<form:options
							items="${form.organizationTypeLists['ARV_ORGS_BY_NAME']}"
							itemLabel="organizationName" itemValue="id" />
					</form:select><div id="iarv.centerNameMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.project.centerCode" /></td>
				<td><form:select path="ProjectData.ARVcenterCode"
						id="iarv.centerCode" onchange="iarv.checkCenterCode(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.organizationTypeLists['ARV_ORGS']}"
							itemLabel="doubleName" itemValue="id" />
					</form:select><div id="iarv.centerCodeMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.doctor" /></td>
				<td><form:input path="observations.nameOfDoctor"
						cssClass="text" id="iarv.nameOfDoctor" size="50"
						onchange="compareAllObservationHistoryFields(true)" /></td>
				<div id="iarv.nameOfDoctorMessage" class="blank"></div>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.receivedDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="receivedDateForDisplay" cssClass="text"
						onkeyup="addDateSlashes(this, event);"
						onchange="iarv.checkReceivedDate(false);"
						id="iarv.receivedDateForDisplay" maxlength="10" />
					<div id="iarv.receivedDateForDisplayMessage" class="blank" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.receivedTime" />&nbsp;<spring:message
						code="sample.military.time.format" /></td>
				<td><form:input path="receivedTimeForDisplay"
						onkeyup="filterTimeKeys(this, event);"
						onblur="iarv.checkReceivedTime(true);" cssClass="text"
						id="iarv.receivedTimeForDisplay" maxlength="5" />
					<div id="iarv.receivedTimeForDisplayMessage" class="blank" /></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.dateTaken" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="interviewDate"
						onkeyup="addDateSlashes(this, event);"
						onchange="iarv.checkInterviewDate(false)" cssClass="text"
						id="iarv.interviewDate" maxlength="10" />
					<div id="iarv.interviewDateMessage" class="blank" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.timeTaken" />&nbsp;<spring:message
						code="sample.military.time.format" /></td>
				<td><form:input path="interviewTime"
						onkeyup="filterTimeKeys(this, event);"
						onblur="iarv.checkInterviewTime(true);" cssClass="text"
						id="iarv.interviewTime" maxlength="5" />
					<div id="iarv.interviewTimeMessage" class="blank" /></td>
			</tr>
			<tr>
				<td class="required">+</td>
				<td><spring:message code="sample.entry.project.subjectNumber" /></td>
				<td><form:input path="subjectNumber" id="iarv.subjectNumber"
						cssClass="text" maxlength="7"
						onchange="iarv.checkSubjectNumber(true)" />
					<div id="iarv.subjectNumberMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">+</td>
				<td><spring:message code="patient.site.subject.number" /></td>
				<td><form:input path="siteSubjectNumber"
						id="iarv.siteSubjectNumber" cssClass="text"
						onchange="iarv.checkSiteSubjectNumber(true);" />
						<div id="iarv.siteSubjectNumberMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><%=MessageUtil.getContextualMessage("quick.entry.accession.number")%>
				</td>
				<td>
					<div class="blank">
						<spring:message code="sample.entry.project.LART" />
					</div> <INPUT type="text" name="iarv.labNoForDisplay"
					id="iarv.labNoForDisplay" size="5" class="text"
					onchange="handleLabNoChange( this, '<spring:message code="sample.entry.project.LART"/>', 'false' );makeDirty();"
					maxlength="5" /> <form:input path="labNo" cssClass="text"
						style="display:none;" id="iarv.labNo" />
					<div id="iarv.labNoMessage" class="blank"></div>
				</td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.gender" /></td>
				<td><form:select path="gender" id="iarv.gender"
						onchange="iarv.checkGender(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.formLists['GENDERS']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="iarv.genderMessage" class="blank" /></td>
			</tr>

			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="birthDateForDisplay" cssClass="text"
						size="20" maxlength="10" onkeyup="addDateSlashes(this, event);"
						onchange="iarv.checkDateOfBirth(false)" id="iarv.dateOfBirth" />
					<div id="iarv.dateOfBirthMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="patient.age" /></td>
				<td><label for="iarv.age"><spring:message
							code="label.year" /></label> <INPUT type="text" name="ageYear"
					id="iarv.age" size="3"
					onchange="iarv.checkAge( this, true, 'year' );" maxlength="2" />
					<div id="iarv.ageMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.specimen" />
						</td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.dryTubeTaken" /></td>
				<td><form:checkbox path="ProjectData.dryTubeTaken"
						id="iarv.dryTubeTaken" onchange="iarv.checkSampleItem(this);" />
						<div id="iarv.dryTubeTakenMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.edtaTubeTaken" /></td>
				<td><form:checkbox path="ProjectData.edtaTubeTaken"
						id="iarv.edtaTubeTaken" onchange="iarv.checkSampleItem(this);" />
						<div id="iarv.edtaTubeTakenMessage" class="blank"></div>
				</td>
			</tr>
			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.dryTube" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.serologyHIVTest" /></td>
				<td><form:checkbox path="ProjectData.serologyHIVTest"
						id="iarv.serologyHIVTest"
						onchange="iarv.checkSampleItem($('iarv.dryTubeTaken'), this)" />
						<div id="iarv.serologyHIVTestMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.glycemiaTest" /></td>
				<td><form:checkbox path="ProjectData.glycemiaTest"
						id="iarv.glycemiaTest"
						onchange="iarv.checkSampleItem($('iarv.dryTubeTaken'), this)" />
						<div id="iarv.glycemiaTestMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.creatinineTest" /></td>
				<td><form:checkbox path="ProjectData.creatinineTest"
						id="iarv.creatinineTest"
						onchange="iarv.checkSampleItem($('iarv.dryTubeTaken'), this);" />
						<div id="iarv.creatinineTestMessage" class="blank"></div>
				</td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.transaminaseTest" /></td>
				<td><form:checkbox path="ProjectData.transaminaseTest"
						id="iarv.transaminaseTest"
						onchange="iarv.checkSampleItem($('iarv.dryTubeTaken'), this)" />
						<div id="iarv.transaminaseTestMessage" class="blank"></div>
				</td>
			</tr>
			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.edtaTube" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.ARV.nfsTest" /></td>
				<td><form:checkbox path="ProjectData.nfsTest" id="iarv.nfsTest"
						onchange="iarv.checkSampleItem($('iarv.edtaTubeTaken'), this)" />
						<div id="iarv.nfsTestMessage" class="blank"></div>
				</td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.ARV.cd4cd8Test" /></td>
				<td><form:checkbox path="ProjectData.cd4cd8Test"
						id="iarv.cd4cd8Test"
						onchange="iarv.checkSampleItem($('iarv.edtaTubeTaken'), this)" />
						<div id="iarv.cd4cd8TestMessage" class="blank"></div>
				</td>
			</tr>
			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.otherTests" /></td>
			</tr>
<!-- 			<tr> -->
<!-- 				<td></td> -->
<%-- 				<td><spring:message --%>
<%-- 						code="sample.entry.project.ARV.viralLoadTest" /></td> --%>
<%-- 				<td><form:checkbox path="ProjectData.viralLoadTest" --%>
<%-- 						id="iarv.viralLoadTest" --%>
<%-- 						onchange="iarv.checkSampleItem($('iarv.edtaTubeTaken'), this);" /> --%>
<!-- 						<div id="iarv.viralLoadTestMessage" class="blank"></div> -->
<!-- 				</td> -->
<!-- 			</tr> -->
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.genotypingTest" /></td>
				<td><form:checkbox path="ProjectData.genotypingTest"
						id="iarv.genotypingTest"
						onchange="iarv.checkSampleItem($('iarv.edtaTubeTaken'), this)" />
						<div id="iarv.genotypingTestMessage" class="blank"></div>
				</td>
			</tr>


			<tr>
				<td></td>
				<td><spring:message code="patient.project.underInvestigation" />
				</td>
				<td><form:select path="observations.underInvestigation"
						id="iarv.underInvestigation"
						onchange="makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="iarv.underInvestigationMessage" class="blank"></div></td>
			</tr>

			<tr id="iarv.underInvestigationCommentRow">
				<td class="required"></td>
				<td><spring:message
						code="patient.project.underInvestigationComment" /></td>
				<td colspan="3"><form:input
						path="ProjectData.underInvestigationNote" maxlength="1000"
						size="80" onchange="makeDirty();"
						id="iarv.underInvestigationComment" />
						<div id="iarv.underInvestigationCommentMessage" class="blank"></div></td>
			</tr>
		</table>

	</div>

	<div id="FollowUpARV_Id" style="display: none;">
		<h2>
			<spring:message code="sample.entry.project.followupARV.title" />
		</h2>
		<table width="100%">
			<tr>
				<td class="required" width="2%">*</td>
				<td width="28%"><spring:message
						code="sample.entry.project.ARV.centerName" /></td>
				<td width="70%"><form:select path="ProjectData.ARVcenterName"
						id="farv.centerName" onchange="farv.checkCenterName(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options
							items="${form.organizationTypeLists['ARV_ORGS_BY_NAME']}"
							itemLabel="organizationName" itemValue="id" />
					</form:select><div id="farv.centerNameMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.project.centerCode" /></td>
				<td><form:select path="ProjectData.ARVcenterCode"
						id="farv.centerCode" onchange="farv.checkCenterCode(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.organizationTypeLists['ARV_ORGS']}"
							itemLabel="doubleName" itemValue="id" />
					</form:select><div id="farv.centerCodeMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.doctor" /></td>
				<td><form:input path="observations.nameOfDoctor"
						cssClass="text" id="farv.nameOfDoctor" size="50"
						onchange="compareAllObservationHistoryFields(true)" />
						<div id="farv.nameOfDoctorMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.receivedDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="receivedDateForDisplay" cssClass="text"
						id="farv.receivedDateForDisplay" maxlength="10"
						onkeyup="addDateSlashes(this, event);"
						onchange="farv.checkReceivedDate(false);" />
					<div id="farv.receivedDateForDisplayMessage" class="blank" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.receivedTime" />&nbsp;<spring:message
						code="sample.military.time.format" /></td>
				<td><form:input path="receivedTimeForDisplay" cssClass="text"
						onkeyup="filterTimeKeys(this, event);"
						id="farv.receivedTimeForDisplay" maxlength="5"
						onblur="farv.checkReceivedTime(true);" />
					<div id="farv.receivedTimeForDisplayMessage" class="blank" /></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.dateTaken" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="interviewDate"
						onkeyup="addDateSlashes(this, event);"
						onchange="farv.checkInterviewDate(false)" cssClass="text"
						id="farv.interviewDate" maxlength="10" />
					<div id="farv.interviewDateMessage" class="blank" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.timeTaken" />&nbsp;<spring:message
						code="sample.military.time.format" /></td>
				<td><form:input path="interviewTime"
						onkeyup="filterTimeKeys(this, event);"
						onblur="farv.checkInterviewTime(true);" cssClass="text"
						id="farv.interviewTime" maxlength="5" />
					<div id="farv.interviewTimeMessage" class="blank" /></td>
			</tr>

			<tr>
				<td class="required">+</td>
				<td><spring:message code="sample.entry.project.subjectNumber" /></td>
				<td><form:input path="subjectNumber" id="farv.subjectNumber"
						cssClass="text" maxlength="7"
						onchange="farv.checkSubjectNumber(true);" />
					<div id="farv.subjectNumberMessage" class="blank" /></td>
			</tr>
			<tr>
				<td class="required">+</td>
				<td><spring:message code="patient.site.subject.number" /></td>
				<td><form:input path="siteSubjectNumber"
						id="farv.siteSubjectNumber" cssClass="text"
						onchange="farv.checkSiteSubjectNumber(true);" />
					<div id="farv.siteSubjectNumberMessage" class="blank" /></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><%=MessageUtil.getContextualMessage("quick.entry.accession.number")%>

				</td>
				<td>
					<div class="blank">
						<spring:message code="sample.entry.project.LART" />
					</div> <INPUT type=text name="farv.labNoForDisplay"
					id="farv.labNoForDisplay" size="5" class="text"
					onchange="handleLabNoChange( this, '<spring:message code="sample.entry.project.LART"/>', false );makeDirty();"
					maxlength="5" /> <form:input path="labNo" cssClass="text"
						style="display:none;" id="farv.labNo" />
					<div id="farv.labNoMessage" class="blank"></div>
				</td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.gender" /></td>
				<td><form:select path="gender" id="farv.gender"
						onchange="farv.checkGender(false)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.formLists['GENDERS']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="farv.genderIDMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="birthDateForDisplay" cssClass="text"
						size="20" maxlength="10" id="farv.dateOfBirth"
						onkeyup="addDateSlashes(this, event);"
						onchange="farv.checkDateOfBirth(false)" />
					<div id="farv.dateOfBirthMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="patient.age" /></td>
				<td><label for="farv.age"><spring:message
							code="label.year" /></label> <INPUT type="text" name="ageYear"
					id="farv.age" size="3"
					onchange="farv.checkAge( this, true, 'year' );" maxlength="2" />
					<div id="farv.ageMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="patient.project.hivStatus" /></td>
				<td><form:select path="observations.hivStatus"
						onchange="farv.checkHivStatus(true);" id="farv.hivStatus">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['HIV_STATUSES']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="farv.hivStatusMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.specimen" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.dryTubeTaken" /></td>
				<td><form:checkbox path="ProjectData.dryTubeTaken"
						id="farv.dryTubeTaken" onchange="farv.checkSampleItem(this)" />
					<div id="farv.dryTubeTakenMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.edtaTubeTaken" /></td>
				<td><form:checkbox path="ProjectData.edtaTubeTaken"
						id="farv.edtaTubeTaken" onchange="farv.checkSampleItem(this);" />
					<div id="farv.edtaTubeTakenMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.dryTube" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.serologyHIVTest" /></td>
				<td><form:checkbox path="ProjectData.serologyHIVTest"
						id="farv.serologyHIVTest"
						onchange="farv.checkSampleItem($('farv.dryTubeTaken'), $('farv.serologyHIVTest'))" />
					<div id="farv.serologyHIVTestMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.glycemiaTest" /></td>
				<td><form:checkbox path="ProjectData.glycemiaTest"
						id="farv.glycemiaTest"
						onchange="farv.checkSampleItem($('farv.dryTubeTaken'), $('farv.glycemiaTest'))" />
					<div id="farv.glycemiaTestMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.creatinineTest" /></td>
				<td><form:checkbox path="ProjectData.creatinineTest"
						id="farv.creatinineTest"
						onchange="farv.checkSampleItem($('farv.dryTubeTaken'), $('farv.creatinineTest'))" />
					<div id="farv.creatinineTest" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.transaminaseTest" /></td>
				<td><form:checkbox path="ProjectData.transaminaseTest"
						id="farv.transaminaseTest"
						onchange="farv.checkSampleItem($('farv.dryTubeTaken'), $('farv.transaminaseTest'))" />
					<div id="farv.transaminaseTestMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.edtaTube" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.ARV.nfsTest" /></td>
				<td><form:checkbox path="ProjectData.nfsTest" id="farv.nfsTest"
						onchange="farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.nfsTest'))" />
					<div id="farv.nfsTestMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.ARV.cd4cd8Test" /></td>
				<td><form:checkbox path="ProjectData.cd4cd8Test"
						id="farv.cd4cd8Test"
						onchange="farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.cd4cd8Test'))" />
					<div id="farv.cd4cd8TestMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.otherTests" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.viralLoadTest" /></td>
				<td><form:checkbox path="ProjectData.viralLoadTest"
						id="farv.viralLoadTest"
						onchange="farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.viralLoadTest'))" />
					<div id="farv.viralLoadTestMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.genotypingTest" /></td>
				<td><form:checkbox path="ProjectData.genotypingTest"
						id="farv.genotypingTest"
						onchange="farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.genotypingTest'))" />
					<div id="farv.genotypingTestMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td colspan="6"><hr /></td>
			</tr>
			<tr id="farv.underInvestigationRow">
				<td class="required"></td>
				<td><spring:message code="patient.project.underInvestigation" />
				</td>
				<td><form:select path="observations.underInvestigation"
						onchange="makeDirty();compareAllObservationHistoryFields(true)"
						id="farv.underInvestigation">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="farv.underInvestigationMessage" class="blank"></div></td>
			</tr>
			<tr id="farv.underInvestigationCommentRow">
				<td class="required"></td>
				<td><spring:message
						code="patient.project.underInvestigationComment" /></td>
				<td colspan="3"><form:input
						path="ProjectData.underInvestigationNote" maxlength="1000"
						size="80" onchange="makeDirty();"
						id="farv.underInvestigationComment" />
						<div id="farv.underInvestigationCommentMessage" class="blank"></div></td>
			</tr>
		</table>
	</div>

	<div id="EID_Id" style="display: none;">
		<h2>
			<spring:message code="sample.entry.project.EID.title" />
		</h2>
		<table width="100%">
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.receivedDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="receivedDateForDisplay" cssClass="text"
						onkeyup="addDateSlashes(this, event);"
						onchange="eid.checkReceivedDate(false);"
						id="eid.receivedDateForDisplay" maxlength="10" />
					<div id="eid.receivedDateForDisplayMessage" class="blank" ></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.receivedTime" />&nbsp;<spring:message
						code="sample.military.time.format" /></td>
				<td><form:input path="receivedTimeForDisplay"
						onkeyup="filterTimeKeys(this, event);"
						onblur="eid.checkReceivedTime(true);" cssClass="text"
						id="eid.receivedTimeForDisplay" maxlength="5" />
						<div id="eid.receivedTimeForDisplayMessage" class="blank" ></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.dateTaken" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="interviewDate"
						onkeyup="addDateSlashes(this, event);"
						onchange="eid.checkInterviewDate(false)" cssClass="text"
						id="eid.interviewDate" maxlength="10" />
					<div id="eid.interviewDateMessage" class="blank" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.timeTaken" />&nbsp;<spring:message
						code="sample.military.time.format" /></td>
				<td><form:input path="interviewTime"
						onkeyup="filterTimeKeys(this, event);"
						onblur="eid.checkInterviewTime(true);" cssClass="text"
						id="eid.interviewTime" maxlength="5" />
					<div id="eid.interviewTimeMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.siteName" /></td>
				<td><form:select path="ProjectData.EIDSiteName"
						id="eid.centerName" onchange="eid.checkCenterName(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options
							items="${form.organizationTypeLists['EID_ORGS_BY_NAME']}"
							itemLabel="organizationName" itemValue="id" />
					</form:select><div id="eid.centerNameMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.siteCode" /></td>
				<td><form:select path="projectData.EIDsiteCode"
						id="eid.centerCode" onchange="eid.checkCenterCode(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.organizationTypeLists['EID_ORGS']}"
							itemLabel="doubleName" itemValue="id" />
					</form:select><div id="eid.centerCodeMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td class="required">+</td>
				<td><spring:message
						code="sample.entry.project.EID.infantNumber" /></td>
				<td>
					<div class="blank">DBS</div> <INPUT type="text"
					name="eid.codeSiteId" id="eid.codeSiteID" size="5" class="text"
					onchange="handleDBSSubjectId(); makeDirty();" maxlength="5" /> <INPUT
					type="text" name="eid.infantID" id="eid.infantID" size="5"
					class="text" onchange="handleDBSSubjectId(); makeDirty();"
					maxlength="5" /> <form:input id="eid.subjectNumber"
						path="subjectNumber" style="display:none;"
						onchange="checkRequiredField(this); makeDirty();" />
					<div id="eid.subjectNumberMessage" class="blank"></div>
				</td>
			</tr>
			<tr>
				<td class="required">+</td>
				<td><spring:message
						code="sample.entry.project.EID.siteInfantNumber" /></td>
				<td><form:input path="siteSubjectNumber"
						id="eid.siteSubjectNumber"
						onchange="eid.checkSiteSubjectNumber(true);" cssClass="text"/>
					<div id="eid.siteSubjectNumberMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td class="required">*</td>
				<td><%=MessageUtil.getContextualMessage("quick.entry.accession.number")%>
				</td>
				<td>
					<div class="blank">
						<spring:message code="sample.entry.project.LDBS" />
					</div> <input type="text" name="eid.labNoForDisplay"
					id="eid.labNoForDisplay" size="5" class="text"
					onchange="handleLabNoChange( this, '<spring:message code="sample.entry.project.LDBS"/>', false );makeDirty();"
					maxlength="5" /> <form:input path="labNo" id="eid.labNo"
						styleClass="text" style="display:none;" />
					<div id="eid.labNoMessage" class="blank"></div>
				</td>
			</tr>


			<tr>
				<td></td>
				<td><spring:message code="patient.project.eidWhichPCR" /></td>
				<td><form:select path="observations.whichPCR" id="eid.whichPCR"
						onchange="eid.checkEIDWhichPCR(this)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['EID_WHICH_PCR']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.whichPCRMessage" class="blank" ></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.EID.reasonForPCRTest" /></td>
				<td><form:select path="observations.reasonForSecondPCRTest"
						id="eid.reasonForSecondPCRTest"
						onchange="makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options
							items="${form.dictionaryLists['EID_SECOND_PCR_REASON']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.reasonForSecondPCRTestMessage" class="blank" ></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.project.nameOfRequestor" /></td>
				<td><form:input path="observations.nameOfRequestor"
						onchange="makeDirty();compareAllObservationHistoryFields(true)"
						cssClass="text" />
					<div id="eid.nameOfRequestorMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.project.nameOfSampler" /></td>
				<td><form:input path="observations.nameOfSampler"
						onchange="makeDirty();compareAllObservationHistoryFields(true)"
						cssClass="text" />
					<div id="eid.nameOfSamplerMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.infantInformation" /></td>
			</tr>

			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="birthDateForDisplay" cssClass="text"
						onkeyup="addDateSlashes(this, event);"
						onchange="eid.checkDateOfBirth(false);" id="eid.dateOfBirth"
						maxlength="10" />
					<div id="eid.dateOfBirthMessage" class="blank" /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.age" /></td>
				<td>
					<div class="blank">
						<spring:message code="label.month" />
					</div> <INPUT type="text" name="age" id="eid.month" size="3" class="text"
					onchange="eid.checkAge( this, true, 'month' ); clearField('eid.ageWeek');"
					maxlength="2" />
					<div class="blank">
						<spring:message code="label.week" />
					</div> <INPUT type="text" name="ageWeek" id="eid.ageWeek" size="3"
					class="text"
					onchange="eid.checkAge( this, true, 'week' ); clearField('eid.month');"
					maxlength="2" />
					<div id="eid.ageMessage" class="blank"></div>
				</td>
			</tr>

			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.gender" /></td>
				<td><form:select path="gender" id="eid.gender"
						onchange="eid.checkGender(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.formLists['GENDERS']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.genderMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.project.eidBenefitPTME" /></td>
				<td><form:select path="observations.eidInfantPTME"
						id="eid.eidInfantPTME"
						onchange="makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.eidInfantPTMEMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.project.eidTypeOfClinic" /></td>
				<td><form:select path="observations.eidTypeOfClinic"
						id="eid.eidTypeOfClinic"
						onchange="makeDirty();projectChecker.displayTypeOfClinicOther();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options
							items="${form.dictionaryLists['EID_TYPE_OF_CLINIC']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.eidTypeOfClinicMessage" class="blank"></div></td>
			</tr>
		    <tr id="eid.eidTypeOfClinicOtherRow" style="display: none">
		        <td>
		        </td>
		        <td class="observationsSubquestion"><em><spring:message code="patient.project.specify" /></em></td>
		        <td>
		            <form:input path="observations.eidTypeOfClinicOther"
		                      onchange="makeDirty();compareAllObservationHistoryFields(true)"
		                      cssClass="text"
		                      id="eid.eidTypeOfClinicOther" />
		            <div id="eid.eidTypeOfClinicOtherMessage" class="blank"></div>
		        </td>
		    </tr>
			<tr>
				<td></td>
				<td><spring:message code="patient.project.eidHowChildFed" /></td>
				<td><form:select path="observations.eidHowChildFed"
						id="eid.eidHowChildFed"
						onchange="makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['EID_HOW_CHILD_FED']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.eidHowChildFedMessage" class="blank" ></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message
						code="patient.project.eidStoppedBreastfeeding" /></td>
				<td><form:select path="observations.eidStoppedBreastfeeding"
						id="eid.eidStoppedBreastfeedingidHowChildFed"
						onchange="makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options
							items="${form.dictionaryLists['EID_STOPPED_BREASTFEEDING']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.eidStoppedBreastfeedingidHowChildFedMessage" class="blank" ></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.project.eidInfantSymptomatic" />
				</td>
				<td><form:select path="observations.eidInfantSymptomatic"
						id="eid.eidInfantSymptomatic"
						onchange="makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.eidInfantSymptomaticMessage" class="blank" ></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.project.eidInfantProphy" /></td>
				<td><form:select path="observations.eidInfantsARV"
						id="eid.eidInfantsARV"
						onchange="makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options
							items="${form.dictionaryLists['EID_INFANT_PROPHYLAXIS_ARV']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.eidInfantsARVMessage" class="blank" ></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message
						code="patient.project.eidInfantCotrimoxazole" /></td>
				<td><form:select path="observations.eidInfantCotrimoxazole"
						id="eid.eidInfantCotrimoxazole"
						onchange="makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO_UNKNOWN']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.eidInfantCotrimoxazoleMessage" class="blank" ></div></td>
			</tr>

			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.mothersInformation" /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.project.eidMothersStatus" />
				</td>
				<td><form:select path="observations.eidMothersHIVStatus"
						id="eid.eidMothersHIVStatus"
						onchange="makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options
							items="${form.dictionaryLists['EID_MOTHERS_HIV_STATUS']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.eidMothersHIVStatusMessage" class="blank" ></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.project.eidMothersARV" /></td>
				<td><form:select path="observations.eidMothersARV"
						id="eid.eidMothersARV"
						onchange="makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options
							items="${form.dictionaryLists['EID_MOTHERS_ARV_TREATMENT']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.eidMothersARVMessage" class="blank" ></div></td>
			</tr>

			<tr>
				<td colspan="5"><hr /></td>
			</tr>

			<tr id="eid.patientRecordStatusRow" style="display: none;">
				<td class="required"></td>
				<td><spring:message code="patient.project.patientRecordStatus" />
				</td>
				<td><INPUT type="text" id="eid.PatientRecordStatus" size="20"
					class="readOnly text" disabled="disabled" readonly="readonly" />
					<div id="eid.PatientRecordStatusMessage" class="blank"></div></td>
			</tr>

			<tr id="eid.sampleRecordStatusRow" style="display: none;">
				<td class="required"></td>
				<td><spring:message code="patient.project.sampleRecordStatus" />
				</td>
				<td><INPUT type="text" id="eid.SampleRecordStatus" size="20"
					class="readOnly text" disabled="disabled" readonly="readonly" />
					<div id="eid.SampleRecordStatusMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td colspan="6"><hr /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.project.underInvestigation" />
				</td>
				<td><form:select path="observations.underInvestigation"
						id="eid.underInvestigation"
						onchange="makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="eid.underInvestigationMessage" class="blank" ></div></td>
			</tr>

			<tr id="eid.underInvestigationCommentRow">
				<td class="required"></td>
				<td><spring:message
						code="patient.project.underInvestigationComment" /></td>
				<td colspan="3"><form:input
						path="ProjectData.underInvestigationNote" maxlength="1000"
						size="80" onchange="makeDirty();"
						id="eid.underInvestigationComment" />
						<div id="eid.underInvestigationCommentMessage" class="blank" ></div></td>
			</tr>
			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.specimen" /></td>
			</tr>

			<tr>
				<td width="2%"></td>
				<td width="38%"><spring:message
						code="sample.entry.project.ARV.dryTubeTaken" /></td>
				<td width="60%"><form:checkbox path="ProjectData.dryTubeTaken"
						id="eid.dryTubeTaken"
						onchange="eid.checkSampleItem($('eid.dryTubeTaken'));" />
						<div id="eid.dryTubeTakenMessage" class="blank" ></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.title.dryBloodSpot" /></td>
				<td><form:checkbox path="ProjectData.dbsTaken"
						id="eid.dbsTaken"
						onchange="eid.checkSampleItem($('eid.dbsTaken'));" />
						<div id="eid.dbsTakenMessage" class="blank" ></div></td>
			</tr>

			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.tests" /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.dnaPCR" /></td>
				<td><form:checkbox path="ProjectData.dnaPCR" id="eid.dnaPCR"
						onchange="eid.checkSampleItem($('eid.dbsTaken'), $('eid.dnaPCR'));" />
						<div id="eid.dnaPCRMessage" class="blank" ></div>
				</td>
			</tr>

		</table>
	</div>

	<div id="VL_Id" style="display: none;">

		<h2>
			<spring:message code="sample.entry.project.VL.title" />
		</h2>

		<%-- Patient search zone - always visible --%>
		<div id="vl.patientSearchZone">
			<table width="100%">
				<tr>
					<td colspan="3" class="sectionTitle"><spring:message code="sample.entry.project.title.patientSearch" text="Recherche du patient" /></td>
				</tr>
				<tr>
					<td class="required" width="2%">+</td>
					<td width="28%"><spring:message code="sample.entry.project.subjectNumber" /></td>
					<td width="70%"><input type="text" id="vl.searchSubjectNumber" class="text" maxlength="9" />
						<div id="vl.searchSubjectNumberMessage" class="blank"></div></td>
				</tr>
				<tr>
					<td class="required">+</td>
					<td><spring:message code="patient.site.subject.number" /></td>
					<td><input type="text" id="vl.searchSiteSubjectNumber" class="text" maxlength="19"
						onkeyup="addPatientCodeSlashes(this, event);" />
						<div id="vl.searchSiteSubjectNumberMessage" class="blank"></div></td>
				</tr>
				<tr>
					<td></td>
					<td></td>
					<td>
						<input type="button" id="vl.searchPatientButton"
							value='<%=MessageUtil.getMessage("label.button.search")%>'
							onclick="searchVLPatientSerology();" />
						<span id="vl.searchPatientStatus" class="blank"></span>
					</td>
				</tr>
			</table>
			<hr />
		</div>

		<%-- Main VL form - hidden until patient search is done --%>
		<div id="vl.mainForm" style="display: none;">

		<%
		if (acceptExternalOrders) {
		%>
		<%=MessageUtil.getContextualMessage("referring.order.number")%>:
		<form:input id="externalOrderNumber" path="electronicOrder.externalId" />
		<input type="button" name="searchExternalButton"
			value='<%=MessageUtil.getMessage("label.button.search")%>'
			onclick="findEOrder();makeDirty();">
		<%=MessageUtil.getContextualMessage("referring.order.not.found")%>
		<hr />

		<%
		}
		%>

		<table width="100%">

			<tr>
				<td class="required" width="2%">*</td>
				<td width="28%"><spring:message
						code="sample.entry.project.ARV.centerName" /></td>
				<td width="70%"><form:select path="ProjectData.ARVcenterName"
						id="vl.centerName" onchange="vl.checkCenterName(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options
							items="${form.organizationTypeLists['ARV_ORGS_BY_NAME']}"
							itemLabel="organizationName" itemValue="id" />
					</form:select><div id="vl.centerNameMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.project.centerCode" /></td>
				<td><form:select path="ProjectData.ARVcenterCode"
						id="vl.centerCode" onchange="vl.checkCenterCode(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.organizationTypeLists['ARV_ORGS']}"
							itemLabel="doubleName" itemValue="id" />
					</form:select> <div id="vl.centerCodeMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.project.nameOfClinician" /></td>
				<td><form:input path="observations.nameOfDoctor"
						cssClass="text" id="vl.nameOfDoctor" size="50"
						onchange="makeDirty();compareAllObservationHistoryFields(true)" />
					<div id="vl.nameOfDoctorMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.project.nameOfSampler" /></td>
				<td><form:input path="observations.nameOfSampler"
						cssClass="text" id="vl.nameOfSampler" size="50"
						onchange="makeDirty();compareAllObservationHistoryFields(true)" />
					<div id="vl.nameOfSampler" class="blank"></div></td>
			</tr>

			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.receivedDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="receivedDateForDisplay" cssClass="text"
						onkeyup="addDateSlashes(this, event);"
						onchange="vl.checkReceivedDate(false);"
						id="vl.receivedDateForDisplay" maxlength="10" />
					<div id="vl.receivedDateForDisplayMessage" class="blank" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.receivedTime" />&nbsp;<spring:message
						code="sample.military.time.format" /></td>
				<td><form:input path="receivedTimeForDisplay"
						onkeyup="filterTimeKeys(this, event);"
						onblur="vl.checkReceivedTime(true);" cssClass="text"
						id="vl.receivedTimeForDisplay" maxlength="5" />
						<div id="vl.receivedTimeForDisplayMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.dateTaken" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="interviewDate"
						onkeyup="addDateSlashes(this, event);"
						onchange="vl.checkInterviewDate(false);searchForEOrder(this,electronicOrderAvailbaleMessage);" cssClass="text"
						id="vl.interviewDate" maxlength="10" />
					<div id="vl.interviewDateMessage" class="blank" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.timeTaken" />&nbsp;<spring:message
						code="sample.military.time.format" /></td>
				<td><form:input path="interviewTime"
						onkeyup="filterTimeKeys(this, event);"
						onblur="vl.checkInterviewTime(true);" cssClass="text"
						id="vl.interviewTime" maxlength="5" />
						<div id="vl.interviewTimeMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td class="required">+</td>
				<td><spring:message code="sample.entry.project.subjectNumber" /></td>
				<td><form:input path="subjectNumber" cssClass="text"
						id="vl.subjectNumber" maxlength="9"
						onchange="vl.checkSubjectNumber(true);searchForEOrder(this,electronicOrderAvailbaleMessage);" />
					<div id="vl.subjectIDMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">+</td>
				<td><spring:message code="patient.site.subject.number" /></td>
				<td><form:input path="siteSubjectNumber"
						id="vl.siteSubjectNumber" cssClass="text"
						onkeyup="addPatientCodeSlashes(this, event);"
						onchange="vl.checkSiteSubjectNumber(true);validateSiteSubjectNumber(this);searchForEOrder(this,electronicOrderAvailbaleMessage);" maxlength="19"/>
						<div id="vl.siteSubjectNumberMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><%=MessageUtil.getContextualMessage("quick.entry.accession.number")%>
				</td>
				<td>
					<div class="blank">
						<spring:message code="sample.entry.project.LVL" />
					</div> <c:set var="labPrefix">
						<spring:message code='sample.entry.project.LVL' />
					</c:set> <INPUT type="text" name="vl.labNoForDisplay"
					id="vl.labNoForDisplay" size="5" class="text"
					onchange="handleLabNoChange( this, '${labPrefix}', false );makeDirty();"
					maxlength="5" /> <form:input path="labNo" size="5" cssClass="text"
						style="display:none;" id="vl.labNo" />
					<div id="vl.labNoMessage" class="blank"></div>
				</td>
			</tr>

			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="birthDateForDisplay" cssClass="text"
						onkeyup="addDateSlashes(this, event);"
						onchange="vl.checkDateOfBirth(false);" id="vl.dateOfBirth"
						maxlength="10" />
					<div id="vl.dateOfBirthMessage" class="blank" /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.age" /></td>
				<td><label for="vl.age"><spring:message
							code="label.year" /></label> <INPUT type='text' name='age' id="vl.age"
					size="3"
					onchange="vl.checkAge( this, true, 'year' );clearField('vl.month');"
					maxlength="2" /> <label for="vl.month"><spring:message
							code="label.month" /></label> <INPUT type='text' name='month'
					id="vl.month" size="3"
					onchange="vl.checkAge( this, true, 'month' ); clearField('vl.age');"
					maxlength="2" />
					<div id="ageMessage" class="blank"></div> </td>
			</tr>

			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.project.gender" /></td>
				<td><form:select path="gender" id="vl.gender"
						onchange="vl.checkGender(false);makeDirty();">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.formLists['GENDERS']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="vl.genderMessage" class="blank"></div></td>
			</tr>
			<tr id="vl.vlPregnancyRow" style="display: none">
				<td class="required">*</td>
				<td><spring:message code="sample.project.vlPregnancy" /></td>
				<td><form:select path="observations.vlPregnancy"
						id="vl.vlPregnancy"
						onchange="vl.checkVlPregnancy(false);makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="vl.vlPregnancyMessage" class="blank"></div></td>
			</tr>

			<tr id="vl.vlSuckleRow" style="display: none">
				<td class="required">*</td>
				<td><spring:message code="sample.project.vlSuckle" /></td>
				<td><form:select path="observations.vlSuckle" id="vl.vlSuckle"
						onchange="vl.checkVlSuckle(false);makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="vl.vlSuckleMessage" class="blank"></div></td>
			</tr>

			<tr id="vl.hivStatusRow">
				<td class="required" id="vl.hivStatusRequired">*</td>
				<td><spring:message code="patient.project.hivType" /></td>
				<td><form:select path="observations.hivStatus"
						id="vl.hivStatus" onchange="vl.checkHivStatus(true);">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['HIV_TYPES']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<input type="hidden" id="vl.hivStatusHidden" name="observations.hivStatus" disabled="disabled" />
					<div id="vl.hivStatusMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td colspan="5"><hr /></td>
			</tr>

			<tr>
				<td></td>
				<td class="observationsQuestion"><spring:message
						code="sample.entry.project.arv.treatment" /></td>
				<td><form:select path="observations.currentARVTreatment"
						id="vl.currentARVTreatment"
						onchange="vl.checkInterruptedARVTreatment();compareAllObservationHistoryFields(true);">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="vl.currentARVTreatmentMessage" class="blank"></div></td>
			</tr>

			<tr id="vl.arvTreatmentInitDateRow" style="display: none">
				<td></td>
				<td class="observationsSubquestion"><spring:message
						code="sample.entry.project.arv.treatment.initDate" /></td>
				<td><form:input path="observations.arvTreatmentInitDate"
						cssClass="text" onkeyup="addDateSlashes(this, event);"
						onchange="vl.checkDate(false);" id="vl.arvTreatmentInitDate"
						maxlength="10" />
					<div id="vl.arvTreatmentInitDateMessage" class="blank" ></div></td>
			</tr>

			<tr id="vl.arvTreatmentTherapRow" style="display: none">
				<td></td>
				<td class="observationsSubquestion"><spring:message
						code="sample.entry.project.arv.treatment.therap.line" /></td>
				<td><form:select path="observations.arvTreatmentRegime"
						id="vl.arvTreatmentRegime"
						onchange="makeDirty();compareAllObservationHistoryFields(true);">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['ARV_REGIME']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="vl.arvTreatmentRegimeMessage" class="blank" ></div></td>
			</tr>

			<tr id="vl.onGoingARVTreatmentINNsRow" style="display: none">
				<td></td>
				<td class="observationsSubquestion"><spring:message
						code="sample.entry.project.arv.treatment.regimen" /></td>

				<c:forEach items="${form.observations.currentARVTreatmentINNsList}"
					var="ongoingARVTreatment" varStatus="iter">

					<tr id="vl.currentARVTreatmentINNRow${iter.index}"
						style="display: none">
						<td></td>
						<td class="bulletItem">${iter.index})</td>

						<td><form:input
								path="observations.currentARVTreatmentINNsList[${iter.index}]"
								cssClass="text"
								onchange="makeDirty();compareAllObservationHistoryFields(true);"
								id="vl.currentARVTreatmentINNs${iter.index}" maxlength="10" />
							<div id="vl.currentARVTreatmentINNs${iter.index}Message"
								class="blank"></div></td>
					</tr>
				</c:forEach>
			<tr>
				<td colspan="5"><hr /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.vl.reason" /></td>
				<td><form:select path="observations.vlReasonForRequest"
						id="vl.vlReasonForRequest"
						onchange="vl.checkVLRequestReason();compareAllObservationHistoryFields(true);">
						<form:option value="">&nbsp;</form:option>
						<form:options
							items="${form.dictionaryLists['ARV_REASON_FOR_VL_DEMAND']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="vlReasonForRequestMessage" class="blank"></div></td>
			</tr>

			<tr id="vl.reasonOtherRow" style="display: none">
				<td></td>
				<td class="Subquestion"><spring:message
						code="sample.entry.project.vl.specify" /></td>
				<td><form:input path="observations.vlOtherReasonForRequest"
						cssClass="text"
						onchange="compareAllObservationHistoryFields(true);"
						id="vl.vlOtherReasonForRequest" maxlength="50" />
					<div id="vlOtherReasonForRequestMessage" class="blank" /></td>
			</tr>

			<tr>
				<td colspan="5"><hr /></td>
			</tr>

			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.project.cd4init" /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="sample.project.cd4Count" /></td>
				<td><form:input path="observations.initcd4Count"
						cssClass="text"
						onchange="makeDirty();compareAllObservationHistoryFields(true);"
						id="vl.initcd4Count" maxlength="4" />
					<div id="initcd4CountMessage" class="blank" /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="sample.project.cd4Percent" /></td>
				<td><form:input path="observations.initcd4Percent"
						cssClass="text"
						onchange="makeDirty();compareAllObservationHistoryFields(true);"
						id="vl.initcd4Percent" maxlength="10" />
					<div id="initcd4PercentMessage" class="blank" /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="sample.project.Cd4Date" /></td>
				<td><form:input path="observations.initcd4Date" cssClass="text"
						onkeyup="addDateSlashes(this, event);"
						onchange="vl.checkDate(this,false);" id="vl.initcd4Date"
						maxlength="10" />
					<div id="initcd4DateMessage" class="blank" /></td>
			</tr>

			<tr>
				<td colspan="5"><hr /></td>
			</tr>

			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.project.cd4demand" /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="sample.project.cd4Count" /></td>
				<td><form:input path="observations.demandcd4Count"
						cssClass="text"
						onchange="makeDirty();compareAllObservationHistoryFields(true);"
						id="vl.demandcd4Count" maxlength="4" />
					<div id="demandcd4CountMessage" class="blank" /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="sample.project.cd4Percent" /></td>
				<td><form:input path="observations.demandcd4Percent"
						cssClass="text"
						onchange="makeDirty();compareAllObservationHistoryFields(true);"
						id="vl.demandcd4Percent" maxlength="10" />
					<div id="demandcd4PercentMessage" class="blank" /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="sample.project.Cd4Date" /></td>
				<td><form:input path="observations.demandcd4Date"
						cssClass="text" onkeyup="addDateSlashes(this, event);"
						onchange="vl.checkDate(this,false);" id="vl.demandcd4Date"
						maxlength="10" />
					<div id="demandcd4DateMessage" class="blank" ></div></td>
			</tr>

			<tr>
				<td colspan="5"><hr /></td>
			</tr>
			<tr>
				<td></td>
				<td class="observationsQuestion"><spring:message
						code="sample.project.priorVLRequest" /></td>
				<td><form:select path="observations.vlBenefit"
						id="vl.vlBenefit"
						onchange="vl.checkVLBenefit();compareAllObservationHistoryFields(true);">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select><div id="vl.vlBenefitMessage" class="blank" ></div>
					</td>
			</tr>

			<tr id="vl.priorVLLabRow" style="display: none">
				<td></td>
				<td><spring:message code="sample.project.priorVLLab" /></td>
				<td><form:input path="observations.priorVLLab" cssClass="text"
						onchange="makeDirty();compareAllObservationHistoryFields(true);"
						id="vl.priorVLLab" maxlength="100" />
					<div id="priorVLLabMessage" class="blank" /></td>
			</tr>

			<tr id="vl.priorVLValueRow" style="display: none">
				<td></td>
				<td><spring:message code="sample.project.VLValue" /></td>
				<td><form:input path="observations.priorVLValue"
						cssClass="text" onkeypress="vl.IsNumeric(this,event);"
						id="vl.priorVLValue" maxlength="10" />
					<div id="priorVLValueMessage" class="blank" /></td>
			</tr>

			<tr id="vl.priorVLDateRow" style="display: none">
				<td></td>
				<td><spring:message code="sample.project.VLDate" /></td>
				<td><form:input path="observations.priorVLDate" cssClass="text"
						onkeyup="addDateSlashes(this, event);"
						onchange="vl.checkDate(this,false);" id="vl.priorVLDate"
						maxlength="10" />
					<div id="priorVLDateMessage" class="blank" /></td>
			</tr>

			<tr>
				<td colspan="5"><hr /></td>
			</tr>

			<tr id="vl.patientRecordStatusRow" style="display: none;">
				<td class="required"></td>
				<td><spring:message code="patient.project.patientRecordStatus" />
				</td>
				<td><INPUT type="text" id="vl.PatientRecordStatus" size="20"
					class="readOnly text" disabled="disabled" readonly="readonly" />
					<div id="vl.PatientRecordStatusMessage" class="blank"></div></td>
			</tr>

			<tr id="vl.sampleRecordStatusRow" style="display: none;">
				<td class="required"></td>
				<td><spring:message code="patient.project.sampleRecordStatus" />
				</td>
				<td><INPUT type="text" id="vl.SampleRecordStatus" size="20"
					class="readOnly text" disabled="disabled" readonly="readonly" />
					<div id="vl.SampleRecordStatusMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td colspan="6"><hr /></td>
			</tr>

			<tr>
				<td></td>
				<td><spring:message code="patient.project.underInvestigation" />
				</td>
				<td><form:select path="observations.underInvestigation"
						id="vl.underInvestigation"
						onchange="makeDirty();compareAllObservationHistoryFields(true)">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="vl.underInvestigationMessage" class="blank" ></div></td>
			</tr>

			<tr id="vl.underInvestigationCommentRow">
				<td class="required"></td>
				<td><spring:message
						code="patient.project.underInvestigationComment" /></td>
				<td colspan="3"><form:input
						path="ProjectData.underInvestigationNote" maxlength="1000"
						size="80" onchange="makeDirty();"
						id="vl.underInvestigationComment" />
						<div id="vl.underInvestigationCommentMessage" class="blank" ></div></td>
			</tr>
			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.specimen" /></td>
			</tr>
			<tr id="vl.dryTubeTakenRow" style="display: none;">
				<td width="2%"></td>
				<td width="38%"><spring:message
						code="sample.entry.project.ARV.dryTubeTaken" /></td>
				<td width="60%"><form:checkbox path="ProjectData.dryTubeTaken"
						id="vl.dryTubeTaken"
						onchange="vl.checkSampleItem($('vl.dryTubeTaken'));" />
						<div id="vl.dryTubeTakenMessage" class="blank"></div>
				</td>
			</tr>
			<tr>
				<td width="2%"></td>
				<td width="38%"><spring:message
						code="sample.entry.project.ARV.edtaTubeTaken" /></td>
				<td width="60%"><form:checkbox path="ProjectData.edtaTubeTaken"
						id="vl.edtaTubeTaken"
						onchange="vl.checkSampleItem($('vl.edtaTubeTaken'));checkVLSampleType(this);" />
						<div id="vl.edtaTubeTakenMessage" class="blank" ></div>
				</td>
			</tr>

			<tr>
				<td width="2%"></td>
				<td width="38%"><spring:message
						code="sample.entry.project.title.dryBloodSpot" /></td>
				<td width="60%"><form:checkbox path="ProjectData.dbsvlTaken"
						id="vl.dbsvlTaken"
						onchange="vl.checkSampleItem($('vl.dbsvlTaken'));checkVLSampleType(this);" />
						<div id="vl.dbsvlTakenMessage" class="blank" ></div>
				</td>
			</tr>
			<tr>
				<td width="2%"></td>
				<td width="38%"><spring:message
						code="sample.entry.project.title.psc" /></td>
				<td width="60%"><form:checkbox path="ProjectData.pscvlTaken"
						id="vl.pscvlTaken"
						onchange="vl.checkSampleItem($('vl.pscvlTaken'));checkVLSampleType(this);" />
						<div id="vl.dbsvlTakenMessage" class="blank" ></div>
				</td>
			</tr>
			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.tests" /></td>
			</tr>
			<tr id="vl.serologyHIVTestRow" style="display: none;">
				<td></td>
				<td><spring:message code="sample.entry.project.serologyHIVTest" /></td>
				<td><form:checkbox path="ProjectData.serologyHIVTest"
						id="vl.serologyHIVTest" disabled="true"
						onchange="vl.checkSampleItem($('vl.dryTubeTaken'), this);" />
						<span class="requiredlabel">*</span>
						<div id="vl.serologyHIVTestMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.ARV.viralLoadTest" /></td>
				<td><form:checkbox path="ProjectData.viralLoadTest"
						id="vl.viralLoadTest"
						onchange="vl.checkSampleItem($('vl.edtaTubeTaken'), this);" />
						<div id="vl.viralLoadTestMessage" class="blank" ></div></td>
			</tr>
		</table>
		</div><%-- end vl.mainForm --%>
	</div>
	<div id="Recency_Id" style="display: none;">
		<table>
			<tr>
				<td></td>
				<td colspan="2" class="sectionTitle"><spring:message
						code="sample.entry.project.title.org" /></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.project.centerCode" /></td>
				<td><form:select path="ProjectData.ARVcenterCode"
						id="rt.centerCode" onchange="rt.checkCenterCode(true)" class="centerCodeClass">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.organizationTypeLists['ARV_ORGS']}"
							itemLabel="doubleName" itemValue="id" />
					</form:select><div id="rt.centerCodeMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td colspan="2" class="sectionTitle"><spring:message
						code="sample.entry.project.title.patientInfo" /></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><%=MessageUtil.getContextualMessage("quick.entry.accession.number")%>
				</td>
				<td>
					<div class="blank">
						<spring:message code="sample.entry.project.RT" />
					</div> <INPUT type="text" name="rt.labNoForDisplay"
					id="rt.labNoForDisplay" size="5" class="text"
					onchange="handleLabNoChange( this, '<spring:message code="sample.entry.project.RT"/>', 'false' );makeDirty();"
					maxlength="5" /> <form:input path="labNo" cssClass="text"
						style="display:none;" id="rt.labNo" />
					<div id="rt.labNoMessage" class="blank"></div>
				</td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.recencyNumber" /></td>
				<td><form:input path="siteSubjectNumber" cssClass="text"
						id="rt.siteSubjectNumber" maxlength="18" onchange="rt.checkSiteSubjectNumber(true)" />
					<div id="rt.siteSubjectNumberMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="birthDateForDisplay" cssClass="text"
						onkeyup="addDateSlashes(this, event);"
						onchange="rt.checkDateOfBirth(false);"  id="rt.dateOfBirth" maxlength="10" />
					<div id="rt.dateOfBirthMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="patient.age" /></td>
				<td><label for="age"><spring:message code="label.year" /></label>
					<INPUT type='text' name='age' id="rt.age" size="3"
					onchange="rt.checkAge( this, true, 'year' );"
					maxlength="2" />
					<div id="ageMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.project.gender" /></td>
				<td><form:select path="gender" id="rt.gender"
						onchange="rt.checkGender(true);">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.formLists['GENDERS']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="rt.genderMessage" class="blank"></div></td>
			</tr>
			<tr id="rt.vlPregnancyRow" style="display: none">
				<td></td>
				<td><spring:message code="sample.project.vlPregnancy" /></td>
				<td><form:select path="observations.vlPregnancy"
						id="rt.vlPregnancy" onchange="">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select><div id="rt.vlPregnancyMessage" class="blank"></div></td>
			</tr>
			<tr id="rt.vlSuckleRow" style="display: none">
				<td></td>
				<td><spring:message code="sample.project.vlSuckle" /></td>
				<td><form:select path="observations.vlSuckle" id="rt.vlSuckle"
						onchange="">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['YES_NO']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select><div id="rt.vlSuckleMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td></td>
				<td colspan="2" class="sectionTitle"><spring:message
						code="sample.entry.project.title.sample" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="patient.project.nameOfClinician" /></td>
				<td><form:input path="observations.nameOfDoctor"
						cssClass="text" id="rt.nameOfDoctor" size="50"
						onchange="makeDirty();compareAllObservationHistoryFields(true)" />
					<div id="rt.nameOfDoctorMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="patient.project.nameOfSampler" /></td>
				<td><form:input path="observations.nameOfSampler"
						cssClass="text" id="rt.nameOfSampler" size="50"
						onchange="makeDirty();compareAllObservationHistoryFields(true)" />
					<div id="rt.nameOfSamplerMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.receivedDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="receivedDateForDisplay" cssClass="text"
						onkeyup="" onchange="" id="rt.receivedDateForDisplay"
						maxlength="10" />
					<div id="receivedDateForDisplayMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.receivedTime" />&nbsp;<spring:message
						code="sample.military.time.format" /></td>
				<td><form:input path="receivedTimeForDisplay" cssClass="text"
						onkeyup="filterTimeKeys(this, event);" id="rt.receivedTimeForDisplay" maxlength="5" />
						<div id="rt.receivedTimeForDisplayMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.dateTaken" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="interviewDate" onkeyup="" onchange=""
						cssClass="text" id="rt.interviewDate" maxlength="10" />
					<div id="rt.interviewDateMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.timeTaken" />&nbsp;<spring:message
						code="sample.military.time.format" /></td>
				<td><form:input path="interviewTime" onblur=""
						onkeyup="filterTimeKeys(this, event);" cssClass="text" id="rt.interviewTime" maxlength="5" />
						<div id="rt.interviewTimeMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td colspan="2" class="sectionTitle"><spring:message
						code="sample.entry.project.title.sampleType" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.recency.plasma" /></td>
				<td><form:checkbox path="ProjectData.plasmaTaken"
						checked="checked" onchange="rt.checkSampleItem($('rt.plasmaTaken'));checkVLSampleType(this);"
						 id="rt.plasmataken"/>
						<div id="rt.plasmaTakenMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.recency.serum" /></td>
				<td><form:checkbox path="ProjectData.serumTaken"
						id="rt.serumTaken" onchange="rt.checkSampleItem($('rt.serumTaken'));checkVLSampleType(this);" />
						<div id="rt.serumTakenMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td colspan="2" class="sectionTitle"><spring:message
						code="sample.entry.project.title.tests" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.recency.asanteKit" /></td>
				<td><form:checkbox path="ProjectData.asanteTest"
						id="rt.asanteTest" onchange="vl.checkSampleItem($('rt.asanteTest'), this);" />
						<div id="rt.asanteTestMessage" class="blank"></div></td>
			</tr>
		</table>
	</div>
	<div id="HPV_Id" style="display: none;">
		<table>
			<tr>
				<td></td>
				<td colspan="2" class="sectionTitle"><spring:message
						code="sample.entry.project.title.org" /></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.project.centerCode" /></td>
				<td><form:select path="ProjectData.ARVcenterCode"
						id="hpv.centerCode" onchange="hpv.checkCenterCode(true)" class="centerCodeClass">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.organizationTypeLists['ARV_ORGS']}"
							itemLabel="doubleName" itemValue="id" />
					</form:select><div id="hpv.centerCodeMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td colspan="2" class="sectionTitle"><spring:message
						code="sample.entry.project.title.patientInfo" /></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><%=MessageUtil.getContextualMessage("quick.entry.accession.number")%>
				</td>
		        <td style="width:65%">
		            <INPUT  type="text" maxlength='<%= Integer.toString(AccessionNumberUtil.getMaxAccessionLength())%>'
		                      onchange="checkAccessionNumber(this);" class="text" name="hpv.labNoForDisplay"
					id="hpv.labNoForDisplay"/>
		            <form:input path="labNo" size="5" cssClass="text"
						style="display:none;" id="hpv.labNo" />
					<div id="hpv.labNoMessage" class="blank"></div>
		            <spring:message code="sample.entry.scanner.instructions" htmlEscape="false"/>
		            <input type="button" id="generateAccessionButton" value='<%=MessageUtil.getMessage("sample.entry.scanner.generate")%>'
		                   onclick="getNextAccessionNumber(); " class="textButton">
		        </td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.hpvSubjectNumber" /></td>
				<td><form:input path="siteSubjectNumber" cssClass="text"
						id="hpv.siteSubjectNumber" maxlength="18" onchange="" />
					<div id="hpv.siteSubjectNumberMessage" class="blank"></div></td>
			</tr>
 			<tr>
				<td></td>
				<td><spring:message code="patient.project.hivStatus" /></td>
				<td><form:select path="observations.hivStatus"
						onchange="hpv.checkHivStatus(true);" id="hpv.hivStatus">
						<form:option value="">&nbsp;</form:option>
						<form:options items="${form.dictionaryLists['HIV_STATUSES']}"
							itemLabel="localizedName" itemValue="id" />
					</form:select>
					<div id="hpv.hivStatusMessage" class="blank"></div></td>
			</tr>
			<tr style="display:none;">
				<td><form:hidden path="gender" id="hpv.gender" value="F" />
					<div id="hpv.genderMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="birthDateForDisplay" cssClass="text"
						onkeyup="addDateSlashes(this, event);"
						onchange="hpv.checkDateOfBirth(false);"  id="hpv.dateOfBirth" maxlength="10" />
					<div id="hpv.dateOfBirthMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="patient.age" /></td>
				<td><label for="age"><spring:message code="label.year" /></label>
					<INPUT type='text' name='age' id="hpv.age" size="3"
					onchange="hpv.checkAge( this, true, 'year' );"
					maxlength="2" />
					<div id="ageMessage" class="blank"></div></td>
			</tr>

			<tr>
				<td></td>
				<td colspan="2" class="sectionTitle"><spring:message
						code="sample.entry.project.title.sample" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="patient.project.nameOfClinician" /></td>
				<td><form:input path="observations.nameOfDoctor"
						cssClass="text" id="hpv.nameOfDoctor" size="50"
						onchange="" />
					<div id="hpv.nameOfDoctorMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.receivedDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="receivedDateForDisplay" cssClass="text"
						onkeyup="" onchange="" id="hpv.receivedDateForDisplay"
						maxlength="10" />
					<div id="receivedDateForDisplayMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.receivedTime" />&nbsp;<spring:message
						code="sample.military.time.format" /></td>
				<td><form:input path="receivedTimeForDisplay" cssClass="text"
						onkeyup="filterTimeKeys(this, event);" id="hpv.receivedTimeForDisplay" maxlength="5" />
						<div id="hpv.receivedTimeForDisplayMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td class="required">*</td>
				<td><spring:message code="sample.entry.project.dateTaken" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
				</td>
				<td><form:input path="interviewDate" onkeyup="" onchange=""
						cssClass="text" id="hpv.interviewDate" maxlength="10" />
					<div id="hpv.interviewDateMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message code="sample.entry.project.timeTaken" />&nbsp;<spring:message
						code="sample.military.time.format" /></td>
				<td><form:input path="interviewTime" onblur=""
						onkeyup="filterTimeKeys(this, event);" cssClass="text" id="hpv.interviewTime" maxlength="5" />
						<div id="hpv.interviewTimeMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td> </td>
				<td><spring:message code="sample.entry.project.title.sampleType"/></td>
				<td>
				<form:radiobuttons path="observations.hpvSamplingMethod" id="hpv.hpvSamplingMethod" 
				items="${form.dictionaryLists['HPV_SAMPLING_METHOD']}"
				itemLabel="localizedName" itemValue="id"/>
					<div id="hpv.hpvSamplingMethodMessage" class="blank"></div>
				</td>
			</tr>
			<tr>
				<td></td>
				<td colspan="3" class="sectionTitle"><spring:message
						code="sample.entry.project.title.specimen" /></td>
			</tr>
			<tr>
				<td width=""></td>
				<td width=""><spring:message
						code="sample.entry.project.HPV.preservCytTaken" /></td>
				<td width=""><form:checkbox path="ProjectData.preservCytTaken"
						id="hpv.preservCytTaken"
						onchange="hpv.checkSampleItem($('hpv.preservCytTaken'));"/>
						<div id="hpv.preservCytTakenMessage" class="blank" ></div>
				</td>
			</tr>
			<tr>
				<td></td>
				<td colspan="2" class="sectionTitle"><spring:message
						code="sample.entry.project.title.tests" /></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.hpv.hpvKit" /></td>
				<td><form:checkbox path="ProjectData.hpvTest"
						id="hpv.hpvTest" onchange="" />
						<div id="hpv.hpvTestMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.hpv.abottOrRocheAnalysis" /></td>
				<td><form:checkbox path="ProjectData.abbottOrRocheAnalysis"
						id="hpv.abbottOrRocheAnalysis" onchange="" />
						<div id="hpv.abbottOrRocheAnalysisMessage" class="blank"></div></td>
			</tr>
			<tr>
				<td></td>
				<td><spring:message
						code="sample.entry.project.hpv.geneXpertAnalysis" /></td>
				<td><form:checkbox path="ProjectData.geneXpertAnalysis"
						id="hpv.geneXpertAnalysis" onchange="" />
						<div id="hpv.geneXpertAnalysisMessage" class="blank"></div></td>
			</tr>
		</table>

	</div>

</div>

<script type="text/javascript">
	yesesInDiseases = [
<%=Encode.forJavaScript(org.openelisglobal.dictionary.ObservationHistoryList.YES_NO.getList().get(0).getId())%>
	,
<%=Encode
		.forJavaScript(org.openelisglobal.dictionary.ObservationHistoryList.YES_NO_UNKNOWN.getList().get(0).getId())%>
	];

	function ArvInitialProjectChecker() {
		this.idPre = "iarv.";

		this.checkAllSampleItemFields = function() {
			this.checkSampleItem($("iarv.dryTubeTaken"));
			this.checkSampleItem($("iarv.edtaTubeTaken"));
			this.checkSampleItem($('iarv.dryTubeTaken'),
					$('iarv.serologyHIVTest'));
			this
					.checkSampleItem($('iarv.dryTubeTaken'),
							$('iarv.glycemiaTest'));
			this.checkSampleItem($('iarv.dryTubeTaken'),
					$('iarv.creatinineTest'));
			this.checkSampleItem($('iarv.dryTubeTaken'),
					$('iarv.transaminaseTest'));
			this.checkSampleItem($('iarv.edtaTubeTaken'), $('iarv.nfsTest'));
			this.checkSampleItem($('iarv.edtaTubeTaken'), $('iarv.cd4cd8Test'));
			this.checkSampleItem($('iarv.edtaTubeTaken'),
					$('iarv.viralLoadTest'));
			this.checkSampleItem($('iarv.edtaTubeTaken'),
					$('iarv.genotypingTest'));
		}
	}
	ArvInitialProjectChecker.prototype = new BaseProjectChecker();
	iarv = new ArvInitialProjectChecker();

	function ArvFollowupProjectChecker() {

		this.idPre = "farv.";

		this.checkAllSampleItemFields = function() {
			farv.checkSampleItem($('farv.dryTubeTaken'));
			farv.checkSampleItem($('farv.edtaTubeTaken'));
			farv.checkSampleItem($('farv.dryTubeTaken'),
					$('farv.serologyHIVTest'));
			farv
					.checkSampleItem($('farv.dryTubeTaken'),
							$('farv.glycemiaTest'));
			farv.checkSampleItem($('farv.dryTubeTaken'),
					$('farv.creatinineTest'));
			farv.checkSampleItem($('farv.dryTubeTaken'),
					$('farv.transaminaseTest'));
			farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.nfsTest'));
			farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.cd4cd8Test'));
			farv.checkSampleItem($('farv.edtaTubeTaken'),
					$('farv.viralLoadTest'));
			farv.checkSampleItem($('farv.edtaTubeTaken'),
					$('farv.genotypingTest'));
		}
	}

	ArvFollowupProjectChecker.prototype = new BaseProjectChecker();
	farv = new ArvFollowupProjectChecker();

	function EidProjectChecker() {
		this.idPre = "eid.";
		
	    this.displayTypeOfClinicOther = function () {
	        var field = $("eid.eidTypeOfClinic");
	        enableSelectedRequiredSubfield(field, $("eid.eidTypeOfClinicOther"), -1, "eid.eidTypeOfClinicOtherRow" );
	    }
	    
	    this.checkEIDWhichPCR = function (field) {
	        makeDirty();
	        if (field.selectedIndex == 1) {
	            var otherField = $("eid.reasonForSecondPCRTest"); 
	            otherField.selectedIndex = otherField.options.length - 1;  
	        }
	        compareAllObservationHistoryFields(true)
	    }
	    	    
	}

	EidProjectChecker.prototype = new BaseProjectChecker();
	eid = new EidProjectChecker();

	function VLProjectChecker() {

		this.idPre = "vl.";
		var specialKeys = new Array();
		specialKeys.push(8);

		this.checkDate = function(field, blanksAllowed) {
			makeDirty();
			if (field == null)
				return; 
			checkValidDate(field);
			checkRequiredField(field, blanksAllowed);
			compareSampleField(field.id, false, blanksAllowed);
		};

		this.checkVLRequestReason = function() {
			clearFormElements("vl.vlOtherReasonForRequest");
			this.displayedByReasonOther();
		};
		this.displayedByReasonOther = function() {
			var field = $("vl.vlReasonForRequest");
			showElements((field.selectedIndex == 5), "vl.reasonOtherRow");
		};

		this.checkInterruptedARVTreatment = function() {
			clearFormElements("vl.arvTreatmentInitDate,vl.arvTreatmentRegime,vl.currentARVTreatmentINNs0,vl.currentARVTreatmentINNs1,vl.currentARVTreatmentINNs2,vl.currentARVTreatmentINNs3");
			this.displayedByInterruptedARVTreatment();
		};

		this.displayedByInterruptedARVTreatment = function() {
			var field = $("vl.currentARVTreatment");
			showElements(
					(field.selectedIndex == 1),
					"vl.arvTreatmentInitDateRow,vl.arvTreatmentTherapRow,vl.onGoingARVTreatmentINNsRow,vl.currentARVTreatmentINNRow0,vl.currentARVTreatmentINNRow1,vl.currentARVTreatmentINNRow2,vl.currentARVTreatmentINNRow3");
		};

		this.checkVLBenefit = function() {
			clearFormElements("vl.priorVLLab,vl.priorVLValue,vl.priorVLDate");
			this.displayedByVLBenefit();
		};
		this.displayedByVLBenefit = function() {
			var field = $("vl.vlBenefit");
			showElements((field.selectedIndex == 1),
					"vl.priorVLLabRow,vl.priorVLValueRow,vl.priorVLDateRow");
		};

		function IsNumeric(field, e) {
			var keyCode = e.which ? e.which : e.keyCode
			var ret = ((keyCode >= 48 && keyCode <= 57) || specialKeys
					.indexOf(keyCode) != -1);
			document.getElementById("error").style.display = ret ? "none"
					: "inline";
			return ret;
		}
		;

		this.refresh = function() {
			this.refreshBase();
			this.displayedByVLBenefit();
			this.displayedByReasonOther();
			this.displayedByInterruptedARVTreatment();
		};

	}

	function RecencyProjectChecker() {
		this.idPre = "rt.";
	}

	VLProjectChecker.prototype = new BaseProjectChecker();
	vl = new VLProjectChecker();
	RecencyProjectChecker.prototype = new BaseProjectChecker();
	rt = new RecencyProjectChecker();
	
	function HPVProjectChecker() {
		this.idPre = "hpv.";
	}

	HPVProjectChecker.prototype = new BaseProjectChecker();
	hpv = new HPVProjectChecker();

	function pageOnLoad() {
		initializeStudySelection();
		studies.initializeProjectChecker();
		projectChecker == null || projectChecker.refresh();
		//vl.checkGenderForVlPregnancyOrSuckle();
		//rt.checkGenderForVlPregnancyOrSuckle();
		jQuery('.centerCodeClass').select2();
	}

</script>
