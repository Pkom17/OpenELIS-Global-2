<%@page import="org.openelisglobal.common.util.SystemConfiguration"%>
<%@page import="org.openelisglobal.common.action.IActionConstants"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
	import="org.openelisglobal.common.formfields.FormFields,
	org.openelisglobal.sample.util.AccessionNumberUtil,
	        org.openelisglobal.common.formfields.FormFields.Field,
	        org.openelisglobal.common.services.PhoneNumberService,
	        org.openelisglobal.common.util.ConfigurationProperties,
	        org.openelisglobal.common.util.IdValuePair,
	        org.openelisglobal.common.util.ConfigurationProperties.Property,
	        org.openelisglobal.common.util.DateUtil,
	        org.openelisglobal.internationalization.MessageUtil,
	        org.openelisglobal.common.util.Versioning"%>
<%@ page isELIgnored="false"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%@ taglib prefix="ajax" uri="/tags/ajaxtags"%>

<c:set var="formName" value="${form.formName}" />
<c:set var="entryDate" value="${form.currentDate}" />

<script type="text/javascript" src="scripts/utilities.js?"></script>
<script type="text/javascript" src="scripts/tbUtilities.js"></script>
<script type="text/javascript" src="scripts/additional_utilities.js"></script>
<script type="text/javascript" src="scripts/jquery.asmselect.js?"></script>
<script type="text/javascript" src="scripts/ajaxCalls.js?"></script>
<script type="text/javascript" src="scripts/laborder.js?"></script>

<link rel="stylesheet" type="text/css" href="css/jquery.asmselect.css?" />
<script type="text/javascript" src="select2/js/select2.min.js"></script>
<link rel="stylesheet" type="text/css"
	href="select2/css/select2.min.css">
<script type="text/javascript" src="scripts/jquery_ui/jquery-ui.min.js"></script>
<link rel="stylesheet" type="text/css"
	href="scripts/jquery_ui/jquery-ui.min.css" />
<link rel="stylesheet" type="text/css"
	href="scripts/jquery_ui/jquery-ui.theme.min.css" />


<script type="text/javascript">
fieldValidator = new FieldValidator();
fieldValidator.setRequiredFields(
		new Array('labNo','requestDate','receivedDate','referringSiteCode',
				'lastNameID','dateOfBirthID','genderID',
				'tbSpecimenNature_0','tbOrderReasons','tbDiagnosticMethods_0'));
		
function /*void*/setSaveButton() {
	var validToSave = fieldValidator.isAllValid();
	$("saveButtonId").disabled = !validToSave;

}
	function showHideSection(button, targetId) {
		targetId = targetId + button.name
		if (button.value == "+") {
			showSection(button, targetId);
		} else {
			hideSection(button, targetId);
		}
	}
	
	function validatePhoneNumber( phoneElement){
	    validatePhoneNumberOnServer( phoneElement, processPhoneSuccess);
	}
	
	function  processPhoneSuccess(xhr){

	    var formField = xhr.responseXML.getElementsByTagName("formfield").item(0);
	    var message = xhr.responseXML.getElementsByTagName("message").item(0);
	    var success = false;

	    if (message.firstChild.nodeValue == "valid"){
	        success = true;
	    }
	    var labElement = formField.firstChild.nodeValue;
	    selectFieldErrorDisplay( success, $(labElement));
	    setSampleFieldValidity( success, labElement);

	    if( !success ){
	        alert( message.firstChild.nodeValue );
	    }

	    setSave();
	}

	function showSection(button, targetId) {
		jQuery("#" + targetId).show();
		button.value = "-";
	}

	function hideSection(button, targetId) {
		jQuery("#" + targetId).hide();
		button.value = "+";
	}

	function toggleField(toShow, targetId) {
		if (toShow) {
 			jQuery("#" + targetId).show();
			fieldValidator.addRequiredField(targetId.replace('Row', ''));
		} else {
			jQuery("#" + targetId.replace('Row', '')).val(null).trigger(
					'change');
			fieldValidator.removeRequiredField(targetId.replace('Row', ''));
			jQuery("#" + targetId).hide();
		}
	}

	function toggleOrderReasons() {
		var elm = jQuery("#tbOrderReasons");
		toggleField(elm[0].selectedIndex === 1, "tbDiagnosticReasonsRow");
		toggleField(elm[0].selectedIndex === 2, "tbFollowupReasonsRow");
		//toggleField(elm[0].selectedIndex === 2, "tbSubjectNumberRow");
		setOrderModified();
	}
	
	function toggleTBFollowupPeriodLine() {
		var elm = jQuery("#tbFollowupReasons");
		toggleField(elm[0].selectedIndex === 1, "tbFollowupPeriodLine1Row");
		toggleField(elm[0].selectedIndex === 2, "tbFollowupPeriodLine2Row");
		setOrderModified();
	}
	
	function toggleTBSampleAspects(index) {
		var elm = jQuery("#tbDiagnosticMethodsRow_"+index);
		var selectedIndices = jQuery("#tbDiagnosticMethodsRow_"+index+" :selected").map((_, e) => e.index).get();
				
 		toggleField(selectedIndices.includes(2), "tbAspectsRow_"+index);

		if (jQuery(".tbAspectsClass_"+index).hasClass("select2-hidden-accessible")) {
			jQuery(".tbAspectsClass_"+index).select2("destroy");
		}else{
			jQuery(".tbAspectsClass_"+index).select2();
		}
 		
		setOrderModified();
	}
	
	function removeSampleItem(index){
		var blockToRemove = document.getElementById("sampleItemEntryBlock_"+index);
		blockToRemove.remove();
		var indexField = document.getElementById('sampleItemCount');
        var indexValue = indexField.value;
        const newIndex = parseInt(indexValue) - 1;
        
        indexField.value = newIndex;
        
        if(newIndex < 2){
        	document.getElementById("addSamppleItemButton").removeAttribute("disabled");
		}
        
		//add required fields
		fieldValidator.removeRequiredField('tbSpecimenNature_'+(newIndex+1));
		fieldValidator.removeRequiredField('tbDiagnosticMethods_'+(newIndex+1));
		
	}
	 
	    function addSampleItem() {

	        var indexField = document.getElementById('sampleItemCount');
	        var indexValue = parseInt(indexField.value);
	        const newIndex = indexValue + 1;
	    	
	    	var template = '<div id="sampleItemEntryBlock_%i" class="sampleItemEntryBlock"><hr/> <div id="sampleItemEntryItem_%i" class="sampleItemEntryItem">';
	    	template+= '<table> <tr> <td colspan="4">%j<br /></td> </tr> <tr> <td> <spring:message code="sample.tb.specimen.nature" htmlEscape="true"/> :';
			template+= '<span class="requiredlabel">*</span></td><td colspan="2">';
			template+='<select name="tbSampleTests[%i].tbSpecimenNature" onchange="setOrderModified();" id="tbSpecimenNature_%i" class="tbSpecimenNatureClass_%i" style="min-width: 300px">';
			template+='<option value="">&nbsp;</option><c:forEach items="${form.tbSpecimenNatures}" var="specimenNature"> ';
			template+='<option value="${specimenNature.id}">${specimenNature.value}</option></c:forEach></select></td><td></td></tr>';
			template+='<tr id="tbDiagnosticMethodsRow_%i"><td><spring:message code="sample.tb.diagnostic.methods" htmlEscape="true"/>:';
			template+='<span class="requiredlabel">*</span></td><td colspan="2">';
			template+='<select name="tbSampleTests[%i].selectedTbMethod" onchange="toggleTBSampleAspects(%i);showPanelAndTests(this,%i);" id="tbDiagnosticMethods_%i" class="tbDiagnosticMethodsClass_%i" style="min-width: 300px">';
			template+='<option value="">&nbsp;</option> <c:forEach items="${form.tbDiagnosticMethods}" var="diagnosticMethod">';
			template+='<option value="${diagnosticMethod.id}">${diagnosticMethod.value}</option> </c:forEach> </select></td><td></td></tr>';
			template+='<tr id="tbAspectsRow_%i"> <td> <spring:message code="sample.tb.aspects" htmlEscape="true"/> : <span class="requiredlabel">*</span></td><td colspan="2">';
			template+='<select name="tbSampleTests[%i].tbAspect" onchange="setOrderModified();" id="tbAspects_%i" class="tbAspectsClass_%i" style="min-width: 300px">';
			template+='<option value="">&nbsp;</option><c:forEach items="${form.tbAspects}" var="tbAspect"><option value="${tbAspect.id}">${tbAspect.value}</option></c:forEach></select></td>';
			template+='<td></td></tr></table><br />';
			template+='<div id="testSelections_%i" class="testSelections_%i"><table style="margin-left: 1%; width: 60%;" id="addTables_%i">';
			template+='<tr><td style="width: 30%; vertical-align: top;"> <span class="caption"> <spring:message code="sample.entry.panels" /> </span></td>';
			template+='<td style="width: 70%; vertical-align: top; margin-left: 3%;"> <span class="caption"> <spring:message code="sample.entry.available.tests" />';
			template+='</span></td></tr><tr><td style="width: 30%; vertical-align: top;">';
			template+='<table style="width: 97%" id="addPanelTableContainer_%i" class="table addPanelTableContainer"> <thead>';
			template+='<tr> <th style="width: 20%">&nbsp;</th> <th style="width: 80%"><spring:message code="sample.entry.panel.name" /></th></tr></thead>';
			template+='<tbody id="addPanelTable_%i"></tbody></table></td>';
			template+='<td style="width: 70%; vertical-align: top; margin-left: 3%;"> <table style="width: 97%" id="addTestTableContainer_%i" class="table addTestTableContainer">';
			template+='<tr> <th style="width: 5%">&nbsp;</th> <th style="width: 50%"><spring:message code="sample.entry.available.test.names" /></th>';
			template+='<th style="width: 40%; display: none;" id="sectionHead_%i"> Section</th> <th style="width: 20%">&nbsp;</th> </tr>';
			template+='<tbody id="addTestTable_%i"></tbody> </table> </td></tr></table></div>';
			template+='<br/><button type="button" onclick="removeSampleItem(%i);"><spring:message code="sample.entry.sample.remove" /></button><br/><br/></div></div>';
	    	
	    	
	        const container = document.getElementById('sampleItemsContainer');
	        
	        let htmlContent = ''; 
	        htmlContent = template.replace(/%i/g, newIndex);
	        htmlContent = htmlContent.replace(/%j/g, newIndex+1);
	        
	        const tempDiv = document.createElement('div');
	        tempDiv.innerHTML = htmlContent;
	        const newBlock = tempDiv.firstChild;
	        
	        // Append the new block to the container
	        container.appendChild(newBlock);
	        indexField.value = newIndex;
	  		  jQuery('.tbSpecimenNatureClass_'+newIndex).select2();
			  jQuery('.tbSpecimenNatureClass_'+newIndex).trigger('change');
	  		  toggleTBSampleAspects(newIndex);
	  		jQuery('.tbAspectsClass_'+newIndex).select2({width: 'resolve'});
			jQuery('.tbDiagnosticMethodsClass_'+newIndex).select2();
			
			//add required fields
			fieldValidator.addRequiredField('tbSpecimenNature_'+newIndex);
			fieldValidator.addRequiredField('tbDiagnosticMethods_'+newIndex);
	        if(newIndex >= 2){
	        	document.getElementById("addSamppleItemButton").setAttribute("disabled","disabled");
			}
	    }
	
	
	//
	//laborder
	//
	function checkAccessionNumber(accessionNumber) {
        //check if empty
        if (!fieldIsEmptyById("labNo")) {
            validateAccessionNumberOnServer(false, false, accessionNumber.id, accessionNumber.value, processAccessionSuccess, null);
        }
        else {
             selectFieldErrorDisplay(false, $("labNo"));
        }

        setCorrectSave();
    }
	
	function validateTbSubjectNumber(field){
		 const tbNumberFormat = /^[0-9]{5}\/[0-9]{2}$/;
		 if(field.value){
			  if(tbNumberFormat.test(field.value)){
				  field.classList.remove("error");
				  setCorrectSave();
			  }
			  else{
				  field.classList.add("error");
			  }
		 }
	}
	
	function validateTbResistantSubjectNumber(field){
		 const tbNumberFormat = /^[0-9]{4}\/[0-9]{2}\/[0-9]{3}$/;
		 if(field.value){
			  if(tbNumberFormat.test(field.value)){
				  field.classList.remove("error");
				  setCorrectSave();
			  }
			  else{
				  field.classList.add("error");
			  }
		 }
	}
	
    function setupTbSubjectNumberFieldListeners() {
        const field1 = document.getElementById("tbSubjectNumber");
        const field2 = document.getElementById("tbSubjectNumber_rr");

        field1.addEventListener("input", function () {
            if (field1.value.length > 0) {
                field2.value = "";
            }
        });
        field2.addEventListener("input", function () {
            if (field2.value.length > 0) {
                field1.value = "";
            }
        });
    }
	
	function handleAgeChange(){
		var ageYears = jQuery("#ageYears").val();

		if( ageYears.blank()){
			$("dateOfBirthID").value = null;
		} else {
			
			var date = new Date();
			if ( !ageYears.blank() ) {
				date.setFullYear( date.getFullYear() - parseInt(ageYears));
			}
			
			var day = "01";
			var month = "01";
			var year = "xxxx";

			year = date.getFullYear();

			var datePattern = '<%=SystemConfiguration.getInstance().getPatternForDateLocale()%>';
			var splitPattern = datePattern.split("/");

			var DOB = "";

			for( var i = 0; i < 3; i++ ){
				if(splitPattern[i] == "DD"){
					DOB = DOB + day.toLocaleString('en', {minimumIntegerDigits:2}) + "/";
				}else if(splitPattern[i] == "MM" ){
					DOB = DOB + month.toLocaleString('en', {minimumIntegerDigits:2}) + "/";
				}else if(splitPattern[i] == "YYYY" ){
					DOB = DOB + year + "/";
				}
			}
			$("dateOfBirthID").value = DOB.substring(0, DOB.length - 1 );
		}
		jQuery("#dateOfBirthID").trigger('change');
	}

    function processAccessionSuccess(xhr) {
        //alert(xhr.responseText);
        var formField = xhr.responseXML.getElementsByTagName("formfield").item(0);
        var message = xhr.responseXML.getElementsByTagName("message").item(0);
        var success = false;

        if (message.firstChild.nodeValue == "valid") {
            success = true;
        }
        var labElement = formField.firstChild.nodeValue;
        selectFieldErrorDisplay(success, $(labElement));

        if (!success) {
            alert(message.firstChild.nodeValue);
        }

        setCorrectSave();
    }

    function setCorrectSave(){
        if( window.setSave){
            setSave();
        }else if(window.setSaveButton){
            setSaveButton();
        }
    }

    function getNextAccessionNumber() {
        generateNextScanNumber(processScanSuccess);
    }

    function processScanSuccess(xhr) {
        //alert(xhr.responseText);
        var formField = xhr.responseXML.getElementsByTagName("formfield").item(0);
        var returnedData = formField.firstChild.nodeValue;

        var message = xhr.responseXML.getElementsByTagName("message").item(0);

        var success = message.firstChild.nodeValue == "valid";

        if (success) {
            $("labNo").value = returnedData;

        } else {
            alert("<%=MessageUtil.getMessage("error.accession.no.next")%>");
            $("labNo").value = "";
        }

        selectFieldErrorDisplay(success, $("labNo"));
        setValidIndicaterOnField(success, "labNo");

        setCorrectSave();
    }

    function processCodeSuccess(xhr) {
        //alert(xhr.responseText);
        var code = xhr.responseXML.getElementsByTagName("code").item(0);
        var success = xhr.responseXML.getElementsByTagName("message").item(0).firstChild.nodeValue == "valid";

        if (success) {
            jQuery("#requesterCodeId").val(code.getAttribute("value"));
        }
    }
    function setOrderModified(){
        jQuery("#orderModified").val("true");
        orderChanged = true;
        if( window.makeDirty ){ makeDirty(); }

        setCorrectSave();
    }
    
    function  /*void*/ processValidateEntryDateSuccess(xhr){

        //alert(xhr.responseText);
        
        var message = xhr.responseXML.getElementsByTagName("message").item(0).firstChild.nodeValue;
        var formField = xhr.responseXML.getElementsByTagName("formfield").item(0).firstChild.nodeValue;

        var isValid = message == "<%=IActionConstants.VALID%>";

        //utilites.js
        selectFieldErrorDisplay( isValid, $(formField));
        setSampleFieldValidity( isValid, formField );
        setSaveButton();

        if( message == '<%=IActionConstants.INVALID_TO_LARGE%>' ){
            alert( '<spring:message code="error.date.inFuture"/>' );
        }else if( message == '<%=IActionConstants.INVALID_TO_SMALL%>' ){
            alert( '<spring:message code="error.date.inPast"/>' );
        }
    }
    
    function checkValidEntryDate(date, dateRange, blankAllowed)
    {   
        if((!date.value || date.value == "") && !blankAllowed){
            setSaveButton();
            return;
        } else if ((!date.value || date.value == "") && blankAllowed) {
            setSampleFieldValid(date.id);
            setValidIndicaterOnField(true, date.id);
            return;
        }
        if( !dateRange || dateRange == ""){
            dateRange = 'past';
        }
        isValidDate( date.value, processValidateEntryDateSuccess, date.id, dateRange );
    }
    
	function savePage__(action) {
		window.onbeforeunload = null; 
		var form = document.getElementById("mainForm");
		if (action == null) {
			action = "MicrobiologyTb"
		}
		form.action = action;
		form.submit();
	}
	
	function searchOrder() {
	var labno = document.getElementById("searchByLabNo").value;
		if(labno){
			labno = labno.trim();
			if ('URLSearchParams' in window) {
			    var searchParams = new URLSearchParams(window.location.search);
			    searchParams.set("labnoForSearch", labno);
			    window.location.search = searchParams.toString();
			}
		}
	}
	
	
	//var pt_invalidElements = [];
	var patientSelectID;
	var patientInfoHash = [];
	var patientChangeListeners = [];
	var newSearchInfo = false;
	
	var patientInfoChangeListeners = [];
	var dirty = false;
	
	
	function enableEnhancedSearchButton(eventCode){
		var enhancedSearchButton = jQuery("#enhancedSearchButton");
		enhancedSearchButton.removeAttr("disabled");
		
		var patientIdNumberSearch = document.getElementById("patientIdNumberSearchValue");
		patientIdNumberSearch.addEventListener("keyup", function(event) {
			if(event.keyCode === 13) {
				event.preventDefault();
				document.getElementById("enhancedSearchButton").click();
			}
		});
		var lastNameSearch = document.getElementById("lastNameSearchValue");
		lastNameSearch.addEventListener("keyup", function(event) {
			if(event.keyCode === 13) {
				event.preventDefault();
				document.getElementById("enhancedSearchButton").click();
			}
		});
		var firstNameSearch = document.getElementById("firstNameSearchValue");
		firstNameSearch.addEventListener("keyup", function(event) {
			if(event.keyCode === 13) {
				event.preventDefault();
				document.getElementById("enhancedSearchButton").click();
			}
		});
		var dateOfBirthSearch = document.getElementById("dateOfBirthSearchValue");
		dateOfBirthSearch.addEventListener("keyup", function(event) {
			if(event.keyCode === 13) {
				event.preventDefault();
				document.getElementById("enhancedSearchButton").click();
			}
		});
		var genderSearch = document.getElementById("searchGendersSearchValues");
		genderSearch.addEventListener("change", function(event) {
				document.getElementById("enhancedSearchButton").click();
		});
	}
	

	function addPatientToSearch(table, result ){

		var patient = result.getElementsByTagName("patient")[0];

		var firstName = getValueFromXmlElement( patient, "first");
		var lastName = getValueFromXmlElement( patient, "last");
		var gender = getValueFromXmlElement( patient, "gender");
		var DOB = getValueFromXmlElement( patient, "dob");
		var stNumber = getValueFromXmlElement( patient, "ST");
		var subjectNumber = getValueFromXmlElement( patient, "subjectNumber");
		var nationalID = getValueFromXmlElement( patient, "nationalID");
		var mother = getValueFromXmlElement( patient, "mother");
		var pk = getValueFromXmlElement( result, "id");
		var dataSourceName = getValueFromXmlElement( result, "dataSourceName");

		var row = createRow( table, firstName, lastName, gender, DOB, subjectNumber, nationalID, pk, dataSourceName );
		addToPatientInfo( firstName, lastName, gender, DOB, subjectNumber, nationalID, pk );

		if( row == 1 ){
			patientSelectID = pk;
			$("sel_1").checked = "true";
			selectPatient( pk );
		}
	}

	function getValueFromXmlElement( parent, tag ){
		var element = parent.getElementsByTagName( tag ).item(0);

		return element ? element.firstChild.nodeValue : "";
	}

	function createRow(table, firstName, lastName, gender, DOB, subjectNumber, nationalID, pk,  dataSourceName){

			var row = table.rows.length;

			var newRow = table.insertRow(row);

			newRow.id = "_" + row;

			var cellCounter = -1;

			var selectionCell = newRow.insertCell(++cellCounter);
			var lastNameCell = newRow.insertCell(++cellCounter);
			var firstNameCell = newRow.insertCell(++cellCounter);
			var genderCell = newRow.insertCell(++cellCounter);
			var dobCell = newRow.insertCell(++cellCounter);
			var subjectNumberCell = newRow.insertCell(++cellCounter) ;
			var nationalCell = newRow.insertCell(++cellCounter);			
			selectionCell.innerHTML = getSelectionHtml( row, pk );
			lastNameCell.innerHTML = nonNullString( lastName );
			firstNameCell.innerHTML = nonNullString( firstName );
			genderCell.innerHTML = nonNullString( gender );
			subjectNumberCell.innerHTML = nonNullString( subjectNumber );
			nationalCell.innerHTML = nonNullString( nationalID );

			
			
			dobCell.innerHTML = nonNullString( DOB );

			return row;
	}

	function getSelectionHtml( row, key){
		return "<input name='selPatient' id='sel_" + row + "' value='" + key + "' onclick='selectPatient(this.value)' type='radio'>";
	}

	function /*String*/ nonNullString( target ){
		return target == "null" ? "" : target;
	}

	function addToPatientInfo( firstName, lastName, gender, DOB, subjectNumber, nationalID, pk ){
		var info = [];
		info["first"] = nonNullString( firstName );
		info["last"] = nonNullString( lastName );
		info["gender"] = nonNullString( gender );
		info["DOB"] = nonNullString( DOB );
		info["subjectNumber"] = nonNullString( subjectNumber );
		info["national"] = nonNullString( nationalID );

		patientInfoHash[pk] = info;
	}


	function selectPatient( patientID ){
	    var i;
		if( patientID ){
			patientSelectID = patientID;

			var info = patientInfoHash[patientID];

			for(i = 0; i < patientChangeListeners.length; i++){
				patientChangeListeners[i](info["first"],info["last"],info["gender"],info["DOB"],info["subjectNumber"],info["national"], patientID);
			}
		
		}else{
			for(i = 0; i < patientChangeListeners.length; i++){
				patientChangeListeners[i]("","","","","","", null);
			}
		}
	}
 
	function /*void*/ addPatientChangedListener( listener ){
		patientChangeListeners.push( listener );
	}
	
	
	function selectedPatientChangedForManagement(firstName, lastName, gender, DOB,subjectNumber, nationalID, pk ){
		if( pk ){
			getDetailedPatientInfo();
			$("patientPK_ID").value = pk;
		}else{
			clearPatientInfo();
			//setUpdateStatus("ADD");
		}
	}

	var registered = false;

	function registerPatientChangedForManagement() {
		if (!registered) {
			if (typeof addPatientChangedListener === 'function') {
				addPatientChangedListener(selectedPatientChangedForManagement);
			}
			registered = true;
		}
	}

	registerPatientChangedForManagement();
	
	
	
	function  /*void*/ getDetailedPatientInfo()
	{
		$("patientPK_ID").value = patientSelectID;
		
		new Ajax.Request (
	                       'ajaxQueryXML',  //url
	                        {//options
	                          method: 'get', //http method
	                          parameters: "provider=PatientSearchPopulateProvider&personKey=" + patientSelectID,
	          				  requestHeaders : {
	        					 "X-CSRF-Token" : getCsrfToken()
	        				  },
	                          onSuccess:  processSearchPopulateSuccess,
	                          onFailure:  processSearchPopulateFailure
	                         }
	                          );
	}
	
	
	function  /*void*/ setUpdateStatus( newStatus )
	{
		if( updateStatus != newStatus )
		{
			updateStatus = newStatus;
			document.getElementById("processingStatus").value = newStatus;
		}
	}

	function  /*void*/ processSearchPopulateSuccess(xhr)
	{
	    //alert(xhr.responseText);
		var response = xhr.responseXML.getElementsByTagName("formfield").item(0);
		var fhirUuidValue = getXMLValue(response, "fhirUuid");
		var nationalIDValue = getXMLValue(response, "nationalID");
		var subjectNumberValue = getXMLValue(response, "subjectNumber");
		var lastNameValue = getXMLValue(response, "lastName");
		var firstNameValue = getXMLValue(response, "firstName");
		var streetValue = getXMLValue(response, "street");
		var dobValue = getXMLValue(response, "dob");
		var genderValue = getSelectIndexFor( "genderID", getXMLValue(response, "gender"));
		var patientUpdatedValue = getXMLValue(response, "patientUpdated");
		var personUpdatedValue = getXMLValue(response, "personUpdated");
		var guid = getXMLValue( response, "guid");
		var phoneNumber = getXMLValue(response, "phoneNumber");	
		var email = getXMLValue(response, "email");	
		

		setPatientInfo( nationalIDValue,
						subjectNumberValue,
						lastNameValue,
						firstNameValue,
						streetValue,
						dobValue,
						genderValue,
						patientUpdatedValue,
						personUpdatedValue,
						guid,
						phoneNumber,
						fhirUuidValue);

		<c:if test="${param.attemptAutoSave}">
			var validToSave =  patientFormValid() && sampleEntryTopValid();
			if (validToSave) {
				savePage();
			}
		</c:if>

	}
	
	function /*string*/ getXMLValue( response, key )
	{
		var field = response.getElementsByTagName(key).item(0);

		if( field != null )
		{
			 return field.firstChild.nodeValue;
		}
		else
		{
			return undefined;
		}
	}
	
	function  /*void*/ processSearchPopulateFailure(xhr) {
		//console.log(xhr.responseText);
	}
	

	function  /*void*/ clearPatientInfo(){
		setPatientInfo();
	}

	function /*void*/ clearErrors(){

		for( var i = 0; i < pt_invalidElements.length; ++i ){
			setValidIndicaterOnField( true, $(pt_invalidElements[i]).name );
		}

		pt_invalidElements = [];

	}

	function  /*void*/ setPatientInfo(nationalID, subjectNumber, lastName, firstName, street,  dob, gender,
			patientUpdated, personUpdated, guid, phoneNumber, fhirUuidValue ) {

		//clearErrors();

		//$("tbSubjectNumber").value = nationalID == undefined ? "" : nationalID;
		//$("subjectNumberID").value = subjectNumber == undefined ? "" : subjectNumber; 
		$("lastNameID").value = lastName == undefined ? "" : lastName;
		$("firstNameID").value = firstName == undefined ? "" : firstName;
		$("patientAddress").value = street == undefined ? "" : street;
		$("patientGUID_ID").value = guid == undefined ? "" : guid;
		$("patientPhone").value = phoneNumber == undefined ? "" : phoneNumber;
		$("genderID").selectedIndex = gender == undefined ? 0 : gender;

		
		if (dob == undefined) {
			document.getElementById("dateOfBirthID").value = "";
			document.getElementById("ageYears").value = "";
		} else {
			var dobElement = document.getElementById("dateOfBirthID").value = dob;
			updatePatientAge( $("dateOfBirthID") );
		}

		// run this b/c dynamically populating the fields does not constitute an onchange event to populate the patmgmt tile
		// this is the fx called by the onchange event if manually changing the fields
		updatePatientEditStatus();

	}
	

	function  /*void*/ updatePatientEditStatus() {
// 		if (updateStatus == "NO_ACTION") {
// 			setUpdateStatus("UPDATE");
// 		}
		
		for(var i = 0; i < patientInfoChangeListeners.length; i++){
				patientInfoChangeListeners[i]($("firstNameID").value,
											  $("lastNameID").value,
											  $("genderID").value,
											  $("dateOfBirthID").value,
											  $("subjectNumberID").value,
											  $("nationalID").value,
											  $("patientPK_ID").value);

			}

		makeDirty();

		//pt_setSave();
	}

	function /*void*/ makeDirty(){
		dirty=true;
		if( typeof(showSuccessMessage) === 'function' ){
			showSuccessMessage(false); //refers to last save
		}
		// Adds warning when leaving page if content has been entered into makeDirty form fields
		function formWarning(){ 
	    return "<spring:message code="banner.menu.dataLossWarning"/>";
		}
		window.onbeforeunload = formWarning;
	}

	function  /*void*/  addPatient(){
		clearPatientInfo();
		//clearErrors();
		$("subjectNumberID").disabled = false;
		$("nationalID").disabled = false;
		//setUpdateStatus( "ADD" );
		jQuery("#PatientDetail").show();
		
		for(var i = 0; i < patientInfoChangeListeners.length; i++){
				patientInfoChangeListeners[i]("", "", "", "", "", "", "");
			}
	}
	

	function /*void*/ addPatientInfoChangedListener( listener ){
		patientInfoChangeListeners.push( listener );
	}
	
	function /*void*/ handleEnterEvent( ){
			
			if( newSearchInfo ){
				searchPatients();
			}
			return false;
	}

	function /*void*/ dirtySearchInfo(e){ 
		var code = e ? e.which : window.event.keyCode;
		if( code != 13 ){
			newSearchInfo = true; 
		}
	}
	function /*void*/ doNothing(){ 
		
	}
	

	function checkIndex(select) {
		var indexVal = select.options[select.selectedIndex].value;
	    var valueElem = jQuery("#searchValue");
		if (indexVal == "5") {
			jQuery("#scanInstruction").show();
	        valueElem.attr("maxlength","<%= Integer.toString(AccessionNumberUtil.getMaxAccessionLength()) %>");
		} else {
			jQuery("#scanInstruction").hide();
	        valueElem.attr("maxlength","120");
		}
	}
	
	function enableSearchButton(eventCode){
	    var valueElem = jQuery("#searchValue");
	    var criteriaElem  = jQuery('#searchCriteria');
	    var gendersElem  = jQuery('#genders');
	    var searchButton = jQuery("#searchButton");
	    if( valueElem.val() && criteriaElem.val() != "0" && criteriaElem.val() != "5"){
	        searchButton.removeAttr("disabled");
	        if( eventCode == 13 ){
	            searchButton.click();
	        }
	    }else if(criteriaElem.val() == "5"){
	    	if (valueElem.val().length >= <%= Integer.toString(AccessionNumberUtil.getMinAccessionLength()) %>) {
	        	searchButton.removeAttr("disabled");
	            if( eventCode == 13 ){
	                searchButton.click();
	            }
	    	} else {
	            searchButton.attr("disabled", "disabled");
	    	}
	    }else{
	        searchButton.attr("disabled", "disabled");
	    }
	}
	
	function enhancedSearchPatients(localSearch) {
	    var criteria = jQuery("#searchCriteria").val();
	    var genders = jQuery("#genders").val();
	    var value = jQuery("#firstNameSearchValue").val().trim();
	    var splitName;
	    var lastName = "";
	    var firstName = "";
	    var STNumber = "";
	    var subjectNumber = "";
	    var nationalID = "";
	    var labNumber = "";
	    
	    var dateOfBirth = "";
	    var age = "";
	    var gender = "";

		newSearchInfo = false;
	    jQuery("#resultsDiv").hide();
	    jQuery("#searchLabNumber").val('');
	    
	    firstName = jQuery("#firstNameSearchValue").val().trim();
	    lastName = jQuery("#lastNameSearchValue").val().trim();
	    
	    subjectNumber = jQuery("#patientIdNumberSearchValue").val().trim();
	    nationalID = jQuery("#patientIdNumberSearchValue").val().trim(); // facilitates "or"
	    STNumber = jQuery("#patientIdNumberSearchValue").val().trim();
	    
	    dateOfBirth = jQuery("#dateOfBirthSearchValue").val().trim();
	    gender = jQuery("#searchGendersSearchValues").val().trim();
	    
	    labNumber = jQuery("#patientLabNoSearchValue").val().trim();
	    
		if (typeof altAccessionSearchFunction === "function" && labNumber !== "") {
			altAccessionSearchFunction(labNumber);
			return;
		}
		var table = $("searchResultTable");
		$("searchResultsDiv").hide();
		clearTable(table);
		clearPatientInfoCache();
		if (localSearch) {
			jQuery("#loading").addClass('local-search');
			jQuery("#loading").removeClass('external-search');
			jQuery("#enhancedExternalSearchButton").hide();
		} else {
			jQuery("#loading").removeClass('local-search');
			jQuery("#loading").addClass('external-search');
		}
		jQuery("#loading").show();

		patientSearch(lastName, firstName, STNumber, subjectNumber, nationalID, labNumber, "", dateOfBirth, gender, localSearch, processSearchSuccess, processSearchFailure, localSearch);
	}
	
	function processSearchFailure(xhr) {
		//alert( xhr.responseText );
		jQuery("#loading").hide();
		jQuery(".patientFinishSearchShow").show();
		alert("<spring:message code="error.system"/>");
	}

	function processSearchSuccess(xhr, localSearch) {
		jQuery("#loading").hide();
		jQuery(".patientFinishSearchShow").show();
		//alert( xhr.responseText );
		var formField = xhr.responseXML.getElementsByTagName("formfield").item(0);
		var message = xhr.responseXML.getElementsByTagName("message").item(0);
		var table = $("searchResultTable");

		clearTable(table);
		clearPatientInfoCache();

		if( message.firstChild.nodeValue == "valid" )
		{
			$("noPatientFound").hide();
			$("searchResultsDiv").show();

			var resultNodes = formField.getElementsByTagName("result");

			for( var i = 0; i < resultNodes.length; i++ )
			{
				addPatientToSearch( table, resultNodes.item(i) );
			}
			<c:if test="${patientEnhancedSearch.loadFromServerWithPatient}" >
			if( resultNodes.length == 1 ){
				handleSelectedPatient();
			}
			</c:if>
			showExternalSearchButton();
		} else if (localSearch){
			showExternalSearchButton();
			enhancedSearchPatients(false);
		} else {
			$("searchResultsDiv").hide();
			$("noPatientFound").show();
			selectPatient( null );
		}
	}

	function showExternalSearchButton() {
		jQuery("#enhancedExternalSearchButton").show();
	}
	
	function clearSearchResultTable() {
		var table = $("searchResultTable");
		clearTable(table);
		clearPatientInfoCache();
	}

	function clearTable(table){
		var rows = table.rows.length - 1;
		while( rows > 0 ){
			table.deleteRow( rows-- );
		}
	}

	function clearPatientInfoCache(){
		patientInfoHash = [];
	}
	
	
</script>



<div id="tb_container">
	<form:hidden path="modified" id="orderModified" />
	<form:hidden path="sampleId" id="sampleId" />
	<input type="hidden"
		value="${empty form.tbSampleTests ? 0 : form.tbSampleTests.size()-1}"
		id="sampleItemCount">

	 
<!-- <%-- 	maxlength='<%=Integer.toString(AccessionNumberUtil.getMaxAccessionLength())%>' --%>  -->
	<div id=orderSearchSection>
		<input type="button" name="showHide" value='-'
			onclick="showHideSection(this, 'orderSearch');" id="orderSearchId">
		<%=MessageUtil.getContextualMessage("sample.entry.search.label")%>
		<table id="orderSearchshowHide" style="display: none">
			<tr>
				<td style="width: 35%"><spring:message
						code="quick.entry.accession.number" /> :</td>
				<td style="width: 65%"><form:input path="labnoForSearch"
						onchange="" cssClass="text" id="searchByLabNo" /> <input
					type="button" name="searchButton" class="patientSearch"
					value="<%=MessageUtil.getMessage("label.patient.search")%>"
					id="searchButton" onclick="searchOrder()"></td>
			</tr>
		</table>
	</div>

	<hr style="width: 100%; height: 1px" />
	<br />


	<div id=orderEntrySection>
		<input type="button" name="showHide" value='-'
			onclick="showHideSection(this, 'orderDisplay');" id="orderSectionId">
		<%=MessageUtil.getContextualMessage("sample.entry.order.label")%>
		<span class="requiredlabel">*</span>
		<table id="orderDisplayshowHide">
			<tr>
				<td style="width: 35%"><%=MessageUtil.getContextualMessage("quick.entry.accession.number")%>
					:<span class="requiredlabel">*</span></td>
				<td style="width: 65%"><form:input path="labNo"
						maxlength='<%=Integer.toString(AccessionNumberUtil.getMaxAccessionLength())%>'
						onchange="checkAccessionNumber(this);" cssClass="text" id="labNo" />

					<spring:message code="sample.entry.scanner.instructions"
						htmlEscape="false" /> <input type="button"
					id="generateAccessionButton"
					value='<%=MessageUtil.getMessage("sample.entry.scanner.generate")%>'
					onclick="setOrderModified();getNextAccessionNumber(); "
					class="textButton"></td>
			</tr>

			<tr>
				<td><spring:message code="sample.entry.requestDate" />: <span
					class="requiredlabel">*</span><span style="font-size: xx-small;"><%=DateUtil.getDateUserPrompt()%></span></td>
				<td><form:input path="requestDate" id="requestDate"
						cssClass="required" autocomplete="off"
						onchange="setOrderModified();checkValidEntryDate(this, 'past')"
						onkeyup="addDateSlashes(this, event);" maxlength="10" />
			</tr>
			<tr>
				<td><%=MessageUtil.getContextualMessage("quick.entry.received.date")%>
					: <span class="requiredlabel">*</span> <span
					style="font-size: xx-small;"><%=DateUtil.getDateUserPrompt()%>
				</span></td>
				<td colspan="2"><form:input path="receivedDate"
						autocomplete="off"
						onchange="checkValidEntryDate(this, 'past');setOrderModified();"
						onkeyup="addDateSlashes(this, event);" maxlength="10"
						cssClass="text required" id="receivedDate" /></td>
			</tr>
			<tr>
				<td><%=MessageUtil.getContextualMessage("sample.tb.reference.unit")%>
					: <span class="requiredlabel">*</span></td>
				<td colspan="2"><form:select path="referringSiteCode"
						id="referringSiteCode" cssClass="centerCodeClass"
						onchange="setOrderModified();">
						<option value=" "></option>
						<form:options items="${form.referralOrganizations}"
							itemLabel="value" itemValue="id" />
					</form:select></td>
			</tr>
			<tr class="provider-info-row provider-extra-info-row">
				<td><%=MessageUtil.getContextualMessage("sample.entry.provider.name")%>:
				</td>
				<td><form:input path="providerLastName" id="providerLastName"
						onchange="" /></td>

			</tr>
			<tr class="provider-info-row provider-extra-info-row">
				<td><%=MessageUtil.getContextualMessage("sample.entry.provider.firstName")%>:
				</td>
				<td><form:input path="providerFirstName" id="providerFirstName"
						onchange="" /></td>
			</tr>

			<tr class="spacerRow">
				<td>&nbsp;</td>
			</tr>
		</table>
		<hr style="width: 100%; height: 2px" />
	</div>
	<br />
	
	<div id=patientEntrySection>
		<input type="button" name="showHide" value='-'
			onclick="showHideSection(this, 'patientDisplay');"
			id="patientSectionId">
		<%=MessageUtil.getContextualMessage("sample.entry.patient")%>
		<span class="requiredlabel">*</span>

		<div id="patientDisplayshowHide">
		
		<h2><spring:message code="sample.entry.search" /></h2>
		
		
		<table>
		<tr>
			<td style="text-align: left;"><spring:message
					code="patient.labno.search" /> :</td>
			<td><input
					id="patientLabNoSearchValue" 
					size="40"
					oninput="enableEnhancedSearchButton(event.which);"
					placeholder='<%=MessageUtil.getMessage("label.select.search.here")%>' />
			</td>
		</tr>
		<tr>
			<td style="text-align: left;"><spring:message
					code="patient.id.number.search" /> :</td>
			<td><input
					id="patientIdNumberSearchValue" 
					size="40" 
					oninput="enableEnhancedSearchButton(event.which);"
					placeholder='<%=MessageUtil.getMessage("label.select.search.here")%>' />
			</td>
		</tr>
		<tr>
			<td style="text-align: left;"><spring:message
					code="patient.epiLastName" /> :</td>
			<td><input 
					id="lastNameSearchValue" 
					size="40" 
					oninput="enableEnhancedSearchButton(event.which);"
					placeholder='<%=MessageUtil.getMessage("label.select.search.here")%>' />
			</td>
		</tr>
		<tr>
			<td style="text-align: left;"><spring:message
					code="patient.epiFirstName" /> :</td>
			<td><input
				id="firstNameSearchValue"
				size="40"
				oninput="enableEnhancedSearchButton(event.which);"
				placeholder='<%=MessageUtil.getMessage("label.select.search.here")%>' />
			</td>
		</tr>
		</table>
		<table>
		<tr>
			<td style="text-align: right;"><spring:message
					code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>:	</td>
			<td><input
				id="dateOfBirthSearchValue"
				name="dateOfBirthSearchValue"
				size="20"
				onkeyup="addDateSlashes(this,event); "
                onchange="checkValidAgeDate( this );"
				oninput="enableEnhancedSearchButton(event.which);"
				placeholder='<%=MessageUtil.getMessage("label.select.search.here")%>' />
				<div id="dateOfBirthSearchValueMessage" class="blank"
					style="text-align: left;"></div></td>
			<td style="text-align: left;"><spring:message code="patient.gender" />:</td>
			<td><select id="searchGendersSearchValues" style="float: left"
				onchange="enableEnhancedSearchButton(event.which); checkIndex(this)" tabindex="1"
				class="patientEnhancedSearch">
					<option value=" "></option>
					<c:forEach var="pair" items="${form.genders}">
						<option value="${pair.id}">${pair.value}</option>
					</c:forEach>
			</select></td>
			<td><input type="button" name="enhancedSearchButton"
				class="patientEnhancedSearch"
				value="<%=MessageUtil.getMessage("label.patient.search")%>"
				id="enhancedSearchButton" onclick="enhancedSearchPatients(true);"
				disabled="disabled">
				<input type="button" name="enhancedExternalSearchButton"
				class="patientEnhancedSearch"
				value="<%=MessageUtil.getMessage("label.patient.search.external")%>"
				id="enhancedExternalSearchButton" onclick="enhancedSearchPatients(false);"
				style="display:none"></td>
		</tr>
		<tr>
			<td>
			<span id="loading" class="fa-2x" hidden="hidden"><i class="fas fa-spinner fa-pulse"></i></span>
			</td>
		</tr>
	</table>
	
	
	
	
	
	
	
	<div id="noPatientFound" align="center" style="display: none" >
		<h1><spring:message code="patient.search.not.found"/></h1>
	</div>
	<div id="searchResultsDiv" class="colorFill" style="display: none;" >

		<table id="searchResultTable" width="70%">
			<tr>
				<th width="2%"></th>
				<th width="18%">
					<spring:message code="patient.epiLastName"/>
				</th>
				<th width="15%">
					<spring:message code="patient.epiFirstName"/>
				</th>
				<th width="5%">
					<spring:message code="patient.gender"/>
				</th>
				<th width="11%">
					<spring:message code="patient.birthDate"/>
				</th>
				<th width="12%">
					<spring:message code="patient.subject.number"/>
				</th>
				<th width="12%">
                    <%=MessageUtil.getContextualMessage("patient.NationalID") %>
                </th>
			</tr>
		</table>
		<br/>
		 <c:if test="${!empty patientEnhancedSearch.selectedPatientActionButtonText}">
            <input type="button"
                   value="${patientEnhancedSearch.selectedPatientActionButtonText}"
                   id="selectPatientButtonID"
                   onclick="handleSelectedPatient()" />
        </c:if> 
		</div>
	
	
	
	
	
	
	
	
	<form:hidden path="patientPK" id="patientPK_ID"/>
	<form:hidden path="guid" id="patientGUID_ID"/>	
	<br/>
	<div class="patientSearch">
		<hr style="width:100%" />
        <input type="button" value='<%= MessageUtil.getMessage("patient.new")%>' onclick="addPatient()">
	</div>
	<br />
	<table>
		<tr>
			<td style=""><spring:message code="patient.epiLastName" /> : <span
				class="requiredlabel">*</span></td>
			<td><form:input path="patientLastName" id="lastNameID"
					onchange="setOrderModified();" /></td>
			<td style=""><spring:message code="patient.epiFirstName" /> :<span
				class="requiredlabel"></span></td>
			<td><form:input path="patientFirstName" id="firstNameID"
					onchange="" size="25" /></td>
		</tr>
		<tr>
			<td style=""><spring:message code="person.phone" /> : <%=PhoneNumberService.getPhoneFormat()%>:</td>
			<td><form:input path="patientPhone" cssClass="text"
					onchange="validatePhoneNumber(this)" id="patientPhone" /></td>
			<td style=""><spring:message code="person.streetAddress" />:</td>
			<td><form:input path="patientAddress" cssClass="text" size="25"
					onchange="" id="patientAddress" /></td>
		</tr>
		<tr>
			<td style=""><spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>:
				<span class="requiredlabel">*</span></td>
			<td><form:input path="patientBirthDate"
					onkeyup="addDateSlashes(this,event);" autocomplete="off"
					onchange="checkValidEntryDate(this, 'past');convertToAge(this,'ageYears');"
					id="dateOfBirthID" cssClass="text" size="20" maxlength="10" />
				<div id="patientbirthDateMessage" class="blank"></div></td>
			<td style=""><spring:message code="patient.age" />:</td>
			<td><form:input path="patientAge" onchange="handleAgeChange();"
					id="ageYears" cssClass="text" size="3" maxlength="3"
					placeholder="years" />
				<div class="blank">
					<spring:message code="years.label" />
				</div>
				<div id="ageYearsMessage" class="blank"></div></td>
			<td style=""><spring:message code="patient.gender" />: <span
				class="requiredlabel">*</span></td>
			<td><form:select path="patientGender" id="genderID"
					onchange="setOrderModified();">

					<option value=" "></option>
					<form:options items="${form.genders}" itemLabel="value"
						itemValue="id" />
				</form:select></td>
		</tr>
		<tr class="spacerRow">
			<td>&nbsp;</td>
		</tr>
	</table>
		</div>
		<hr style="width: 100%; height: 2px" />
	</div>
	<br />
	<div id=sampleEntrySection>
		<input type="button" name="showHide" value='-'
			onclick="showHideSection(this, 'sampleDisplay');"
			id="sampleSectionId">
		<%=MessageUtil.getContextualMessage("sample.entry.sampleList.label")%>
		<span class="requiredlabel">*</span>
		<div id="sampleDisplayshowHide">
			<table>
				<tr id="tbOrderReasonsRow">
					<td><%=MessageUtil.getContextualMessage("sample.tb.order.reasons")%>
						: <span class="requiredlabel">*</span></td>
					<td colspan="2"><form:select path="tbOrderReason"
							id="tbOrderReasons" cssClass="tbOrderReasonsClass"
							style="width:300px" onchange="toggleOrderReasons();">
							<option value="">&nbsp;</option>
							<form:options items="${form.tbOrderReasons}" itemLabel="value"
								itemValue="id" />
						</form:select></td>
					<td></td>
				</tr>
				<tr id="tbSubjectNumberRow">
					<td style=""><spring:message code="patient.subject.tbnumber" />:
					</td>
					<td><form:input path="tbSubjectNumber" id="tbSubjectNumber"
							onchange="validateTbSubjectNumber(this);" cssClass="text"
							style="width:300px" /></td>
					<td></td>
					<td></td>
				</tr>
				<tr id="tbRRSubjectNumberRow">
					<td style=""><spring:message
							code="patient.subject.tbnumber_rr" />:</td>
					<td><form:input path="tbSubjectNumberRes"
							id="tbSubjectNumber_rr"
							onchange="validateTbResistantSubjectNumber(this);"
							cssClass="text" style="width:300px" /></td>
					<td></td>
					<td></td>
				</tr>
				<tr id="tbDiagnosticReasonsRow">
					<td><%=MessageUtil.getContextualMessage("sample.tb.diagnostic.reasons")%>
						: <span class="requiredlabel">*</span></td>
					<td colspan="2"><form:select path="tbDiagnosticReason"
							id="tbDiagnosticReasons" cssClass="tbDiagnosticReasonsClass"
							style="width:300px" onchange="setOrderModified();">
							<option value="">&nbsp;</option>
							<form:options items="${form.tbDiagnosticReasons}"
								itemLabel="value" itemValue="id" />
						</form:select></td>
					<td></td>
				</tr>
				<tr id="tbFollowupReasonsRow">
					<td><%=MessageUtil.getContextualMessage("sample.tb.followup.reasons")%>
						: <span class="requiredlabel">*</span></td>
					<td colspan="2"><form:select path="tbFollowupReason"
							id="tbFollowupReasons" cssClass="tbFollowupReasonsClass"
							onchange="toggleTBFollowupPeriodLine()">
							<option value="">&nbsp;</option>
							<form:options items="${form.tbFollowupReasons}" itemLabel="value"
								itemValue="id" />
						</form:select> <span id="tbFollowupPeriodLine1Row"> <form:select
								path="tbFollowupPeriodLine1" id="tbFollowupPeriodLine1"
								cssClass="tbFollowupPeriodLine1Class" style="min-width:100px"
								onchange="setOrderModified();">
								<option value="">&nbsp;</option>
								<form:options items="${form.tbFollowupPeriodsLine1}"
									itemLabel="value" itemValue="id" />
							</form:select>
					</span> <span id="tbFollowupPeriodLine2Row"> <form:select
								path="tbFollowupPeriodLine2" id="tbFollowupPeriodLine2"
								cssClass="tbFollowupPeriodLine2Class" style="min-width:100px"
								onchange="setOrderModified();">
								<option value="">&nbsp;</option>
								<form:options items="${form.tbFollowupPeriodsLine2}"
									itemLabel="value" itemValue="id" />
							</form:select>
					</span></td>
					<td></td>
				</tr>
			</table>
		</div>
		<div id=sampleItemEntrySection>

			<div id="sampleItemsContainer">
				<c:choose>
					<c:when test="${empty form.tbSampleTests}">
						<div id="sampleItemEntryBlock_0" class="sampleItemEntryBlock">
							<div id="sampleItemEntryItem_0" class="sampleItemEntryItem">
								<form:hidden path="tbSampleTests[0].selectedTests"
									id="oldSelectedTests_${status.index}" />
								<table>
									<tr>
										<td colspan="4"><br /></td>
									</tr>
									<tr>
										<td><%=MessageUtil.getContextualMessage("sample.tb.specimen.nature")%>:
											<span class="requiredlabel">*</span></td>
										<td colspan="2"><select
											name="tbSampleTests[0].tbSpecimenNature"
											onchange="setOrderModified();" id="tbSpecimenNature_0"
											class="tbSpecimenNatureClass_0" style="min-width: 300px">
												<option value="">&nbsp;</option>
												<c:forEach items="${form.tbSpecimenNatures}"
													var="specimenNature">
													<option value="${specimenNature.id}">${specimenNature.value}</option>
												</c:forEach>
										</select></td>
										<td></td>
									</tr>
									<tr id="tbDiagnosticMethodsRow_0">
										<td><%=MessageUtil.getContextualMessage("sample.tb.diagnostic.methods")%>:
											<span class="requiredlabel">*</span></td>
										<td colspan="2"><select
											name="tbSampleTests[0].selectedTbMethod"
											onchange="toggleTBSampleAspects(0);showPanelAndTests(this,0);"
											id="tbDiagnosticMethods_0" class="tbDiagnosticMethodsClass_0"
											style="min-width: 300px">
												<option value="">&nbsp;</option>
												<c:forEach items="${form.tbDiagnosticMethods}"
													var="diagnosticMethod">
													<option value="${diagnosticMethod.id}">${diagnosticMethod.value}</option>
												</c:forEach>
										</select></td>
										<td></td>
									</tr>
									<tr id="tbAspectsRow_0">
										<td><%=MessageUtil.getContextualMessage("sample.tb.aspects")%>
											: <span class="requiredlabel">*</span></td>
										<td colspan="2"><select name="tbSampleTests[0].tbAspect"
											onchange="setOrderModified();" id="tbAspects_0"
											class="tbAspectsClass_0" style="min-width: 300px">
												<option value="">&nbsp;</option>
												<c:forEach items="${form.tbAspects}" var="tbAspect">
													<option value="${tbAspect.id}">${tbAspect.value}</option>
												</c:forEach>
										</select></td>
										<td></td>
									</tr>
								</table>
								<br />
								<div id="testSelections_0" class="testSelections_0">
									<table style="margin-left: 1%; width: 60%;" id="addTables_0">
										<tr>
											<td style="width: 30%; vertical-align: top;"><span
												class="caption"> <spring:message
														code="sample.entry.panels" />
											</span></td>
											<td style="width: 70%; vertical-align: top; margin-left: 3%;">
												<span class="caption"> <spring:message
														code="sample.entry.available.tests" />
											</span>
											</td>
										</tr>
										<tr>
											<td style="width: 30%; vertical-align: top;">
												<table style="width: 97%" id="addPanelTableContainer_0"
													class="table addPanelTableContainer">
													<thead>
														<tr>
															<th style="width: 20%">&nbsp;</th>
															<th style="width: 80%"><spring:message
																	code="sample.entry.panel.name" /></th>
														</tr>
													</thead>
													<tbody id="addPanelTable_0">

													</tbody>

												</table>
											</td>
											<td style="width: 70%; vertical-align: top; margin-left: 3%;">
												<table style="width: 97%" id="addTestTableContainer_0"
													class="table addTestTableContainer">
													<tr>
														<th style="width: 5%">&nbsp;</th>
														<th style="width: 50%"><spring:message
																code="sample.entry.available.test.names" /></th>
														<th style="width: 40%; display: none;" id="sectionHead_0">
															Section</th>
														<th style="width: 20%">&nbsp;</th>
													</tr>
													<tbody id="addTestTable_0"></tbody>
												</table>
											</td>
										</tr>
									</table>
								</div>
							</div>
						</div>
					</c:when>
					<c:otherwise>
						<c:forEach var="test" items="${form.tbSampleTests}"
							varStatus="status">
							<div id="sampleItemEntryBlock_${status.index}"
								class="sampleItemEntryBlock">
								<div id="sampleItemEntryItem_${status.index}"
									class="sampleItemEntryItem">
									<form:hidden
										path="tbSampleTests[${status.index}].selectedTests"
										id="oldSelectedTests_${status.index}" />
										<form:hidden
										path="tbSampleTests[${status.index}].sampleItemId"
										id="sampleItemId_${status.index}" />
									<table>
										<tr>
											<td colspan="4"><br /></td>
										</tr>
										<tr>
											<td><%=MessageUtil.getContextualMessage("sample.tb.specimen.nature")%>:
												<span class="requiredlabel">*</span></td>
											<td colspan="2">
											<form:select
													path="tbSampleTests[${status.index}].tbSpecimenNature"
													id="tbSpecimenNature_${status.index}"
													cssClass="tbSpecimenNatureClass_${status.index}" style="width:300px"
													onchange="setOrderModified();">
													<option value="">&nbsp;</option>
													<form:options items="${form.tbSpecimenNatures}"
														itemLabel="value" itemValue="id" />
											</form:select>
											</td>
											<td></td>
										</tr>
										<tr id="tbDiagnosticMethodsRow_${status.index}">
											<td><%=MessageUtil.getContextualMessage("sample.tb.diagnostic.methods")%>:
												<span class="requiredlabel">*</span></td>
											<td colspan="2"><form:select
													path="tbSampleTests[${status.index}].selectedTbMethod"
													id="tbDiagnosticMethods_${status.index}" multiple="false"
													cssClass="tbDiagnosticMethodsClass_${status.index}"
													onchange="toggleTBSampleAspects(${status.index});showPanelAndTests(this,${status.index})"
													style="min-width:300px">
													<option value="">&nbsp;</option>
													<form:options items="${form.tbDiagnosticMethods}"
														itemLabel="value" itemValue="id" />
												</form:select>
											</td>
											<td></td>
										</tr>
										<tr id="tbAspectsRow_${status.index}">
											<td><%=MessageUtil.getContextualMessage("sample.tb.aspects")%>
												: <span class="requiredlabel">*</span></td>
											<td colspan="2"><form:select
													path="tbSampleTests[${status.index}].tbAspect"
													id="tbAspects_${status.index}"
													cssClass="tbAspectsClass_${status.index}"
													style="min-width:300px" onchange="setOrderModified();">
													<option value="">&nbsp;</option>
													<form:options items="${form.tbAspects}" itemLabel="value"
														itemValue="id" />
												</form:select></td>
											<td></td>
										</tr>
									</table>
									<br />
									<div id="testSelections_${status.index}"
										class="testSelections_${status.index}">
										<table style="margin-left: 1%; width: 60%;"
											id="addTables_${status.index}">
											<tr>
												<td style="width: 30%; vertical-align: top;"><span
													class="caption"> <spring:message
															code="sample.entry.panels" />
												</span></td>
												<td
													style="width: 70%; vertical-align: top; margin-left: 3%;">
													<span class="caption"> <spring:message
															code="sample.entry.available.tests" />
												</span>
												</td>
											</tr>
											<tr>
												<td style="width: 30%; vertical-align: top;">
													<table style="width: 97%"
														id="addPanelTableContainer_${status.index}"
														class="table addPanelTableContainer">
														<thead>
															<tr>
																<th style="width: 20%">&nbsp;</th>
																<th style="width: 80%"><spring:message
																		code="sample.entry.panel.name" /></th>
															</tr>
														</thead>
														<tbody id="addPanelTable_${status.index}">

														</tbody>

													</table>
												</td>
												<td
													style="width: 70%; vertical-align: top; margin-left: 3%;">
													<table style="width: 97%"
														id="addTestTableContainer_${status.index}"
														class="table addTestTableContainer">
														<tr>
															<th style="width: 5%">&nbsp;</th>
															<th style="width: 50%"><spring:message
																	code="sample.entry.available.test.names" /></th>
															<th style="width: 40%; display: none;"
																id="sectionHead_${status.index}">Section</th>
															<th style="width: 20%">&nbsp;</th>
														</tr>
														<tbody id="addTestTable_${status.index}"></tbody>
													</table>
												</td>
											</tr>
										</table>
									</div>
								</div>
							</div>
						</c:forEach>
					</c:otherwise>
				</c:choose>
			</div>
		</div>
		<br/><br/>
		<button id="addSamppleItemButton" type="button" onclick="addSampleItem();" ${form.tbSampleTests.size() == 3 ? "disabled=\"disabled\"" : ""}>
			<spring:message code="sample.entry.sample.new" />
		</button>
		<hr style="width: 100%; height: 5px" />
	</div>
</div>

<br />
<script type="text/javascript">
	function pageOnLoad() {
		jQuery('.centerCodeClass').select2();
		jQuery('.centerCodeClass').val(${form.referringSiteId});
		jQuery('.centerCodeClass').trigger('change');
		
	    <c:forEach var="test" items="${form.tbSampleTests}" varStatus="status">
		  jQuery('.tbSpecimenNatureClass_${status.index}').select2();
		  jQuery('.tbSpecimenNatureClass_${status.index}').trigger('change');
      	  jQuery('.tbSpecimenNatureClass_${status.index}').eq(${status.index}).val('${test.tbSpecimenNature}');
  		  toggleTBSampleAspects(${status.index});
  		  
    	jQuery('.tbAspectsClass_${status.index}').select2({width: 'resolve'});
		jQuery('.tbDiagnosticMethodsClass_${status.index}').select2();
		
		showPanelAndTests($('tbDiagnosticMethods_${status.index}'), ${status.index});
    	</c:forEach>
	
		jQuery('.tbOrderReasonsClass').select2();
		jQuery('.tbDiagnosticReasonsClass').select2();
		jQuery('.tbFollowupReasonsClass').select2();
		jQuery('.tbFollowupPeriodLine1Class').select2();
		jQuery('.tbFollowupPeriodLine2Class').select2();

 		jQuery('.tbSpecimenNatureClass_0').select2();
		jQuery('.tbDiagnosticMethodsClass_0').select2();
  		jQuery('.tbAspectsClass_0').select2({width: 'resolve'});
		toggleTBSampleAspects(0);
		
		
		toggleOrderReasons();
		toggleTBFollowupPeriodLine();
		setupTbSubjectNumberFieldListeners();
		jQuery("#requestDate").datepicker({
			dateFormat: 'dd/mm/yy',
			yearRange: "-1:+00"
		});
		jQuery("#receivedDate").datepicker({
			dateFormat: 'dd/mm/yy',
		     changeMonth: true,
		     changeYear: true,
		     yearRange: "-1:+00"
		});
		jQuery("#dateOfBirthID").datepicker({
			dateFormat: 'dd/mm/yy',
		     changeMonth: true,
		     changeYear: true,
		     yearRange: "-120:+00",
		     maxDate: new Date(),
		});
		
 		showPanelAndTests($('tbDiagnosticMethods_0'),0);
		
		
		hideSection(document.getElementById('orderSearchId') ,'orderSearch');
		
		setSaveButton();
	}
	
	function showPanelAndTests(input,index){	
		if(!input){
			return;
		}
		if(input.value){
			selectedMethod = input.value;
			let testHtml='';
			let panelHtml='';
			jQuery.get( "MicrobiologyTb/panel_test?method="+selectedMethod, function(data) {
				if(data){
					jQuery("#addPanelTable_"+index).html('');
					jQuery("#addTestTable_"+index).html('');
					 for (const [key, value] of Object.entries(data.tests)) { 
							let d = '<tr>';
							d+='<td><input type="checkbox" value="'+value.id+'" name="tbSampleTests['+index+'].newSelectedTests['+key+']" id="test_'+index+'_'+value.id+'" class="tb_test" /></td>';
							d+='<td><label for="test_'+index+'_'+value.id+'">'+value.name+'</label></td>';
							d+='</tr>';
							testHtml+=d;
				         } 
					 jQuery("#addTestTable_"+index).append(testHtml);
					 
					 for (const [key, value] of Object.entries(data.panels)) { 
							let d = '<tr>';
							d+='<td><input type="checkbox" value="'+value.id+'" name="tbSampleTests['+index+'].testSelected" id="panel_'+index+'_'+value.id+'" '+ 
							'onclick="togglePanelSelected(this,'+index+',\''+value.test_ids+'\')"/></td>';
							d+='<td><label for="panel_'+index+'_'+value.id+'">'+value.name+'</label></td>';
							d+='</tr>';
							panelHtml+=d;
				         } 
					 jQuery("#addPanelTable_"+index).append(panelHtml);
					 
					 
					 //
					 var oldSelectedTests = jQuery('#oldSelectedTests_'+index).val();
					 if(oldSelectedTests){
					 oldSelectedTestsArray = oldSelectedTests.split(",");
						if(oldSelectedTestsArray){							
							oldSelectedTestsArray.forEach(function (id) {
								jQuery('#test_'+index+'_'+ id).prop('checked', true).change();
						    });
						}
					 }
				}
				else{
					jQuery("#addPanelTable_"+index).html('');
					jQuery("#addTestTable_"+index).html('');
				}
				});
		}
		else{
			jQuery("#addPanelTable_"+index).html('');
			jQuery("#addTestTable_"+index).html('');
		}
	}
	
	function togglePanelSelected(panel,index,testIds){
		var testList = testIds.split(',');
			for (test of testList){
				document.getElementById('test_'+index+'_'+test).click();
		}
	}
	
	
</script>