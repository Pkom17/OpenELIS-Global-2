package org.openelisglobal.dataexchange.order.controller;

import java.util.Locale;

import org.apache.commons.lang3.ObjectUtils;
import org.hl7.fhir.r4.model.CodeableConcept;
import org.hl7.fhir.r4.model.Coding;
import org.hl7.fhir.r4.model.ResourceType;
import org.openelisglobal.dataexchange.fhir.service.FhirApiWorkflowService;
import org.openelisglobal.dataexchange.order.api.RejectionReasonDto;
import org.openelisglobal.dataexchange.service.order.EorderFlatQueryService;
import org.openelisglobal.dataexchange.service.order.ElectronicOrderService;
import org.openelisglobal.qaevent.service.QaEventService;
import org.openelisglobal.qaevent.valueholder.QaEvent;
import org.openelisglobal.spring.util.SpringContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.MessageSource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(value = "/rest_eorder")
public class StudyElectronicOrdersRestController {

	private ElectronicOrderService electronicOrderService = SpringContext.getBean(ElectronicOrderService.class);

	private FhirApiWorkflowService fhirApiWorkflowService = SpringContext.getBean(FhirApiWorkflowService.class);

	@Autowired
	private QaEventService qaEventService;

	@Autowired
	private MessageSource messageSource;

	@Autowired
	private EorderFlatQueryService eorderFlatQueryService;

	@GetMapping(value = "/external_id")
	public ResponseEntity<String> getEOrderByPatient(@RequestParam String patientCode,
			@RequestParam String collectionDate) {
		// Recherche dans la table plate par patient + date (± 2 jours)
		String externalId = eorderFlatQueryService.findByPatientAndCollectionDate(patientCode, collectionDate);
		if (ObjectUtils.isNotEmpty(externalId))
			return new ResponseEntity<String>(externalId, HttpStatus.OK);
		else
			return new ResponseEntity<String>("", HttpStatus.NOT_FOUND);
	}

	@GetMapping(value = "/refreshEOrders")
	public ResponseEntity<String> refreshEOrderList() {
		try {
			fhirApiWorkflowService.processWorkflow(ResourceType.Task);
			return new ResponseEntity<String>("", HttpStatus.OK);
		} catch (Exception e) {
			return new ResponseEntity<String>(e.getMessage(), HttpStatus.EXPECTATION_FAILED);
		}

	}

	@GetMapping("/{id}/rejection-reason")
	public ResponseEntity<RejectionReasonDto> getRejectionReason(@PathVariable("id") Integer qaEventId,
			@RequestParam(value = "note", required = false) String qaNote,
			@RequestParam(value = "lang", required = false) String lang) {

		Locale locale = (lang != null && !lang.isEmpty()) ? Locale.forLanguageTag(lang) : Locale.getDefault();
		RejectionReasonDto dto = new RejectionReasonDto();

		QaEvent event = null;
		if (qaEventId != null) {
			try {
				event = qaEventService.get(qaEventId.toString());
			} catch (Exception e) {
				// silent fallback : event reste null
			}
		}

		String nameKey = (ObjectUtils.isNotEmpty(event)) ? event.getNameKey() : null;
		String localized = "";
		if (nameKey != null && !nameKey.isEmpty()) {
			try {
				localized = messageSource.getMessage(nameKey, null, nameKey, locale);
			} catch (Exception e) {
				localized = nameKey;
			}
		}

		String displayText = (localized != null ? localized : "");
		if (qaNote != null && !qaNote.trim().isEmpty()) {
			if (!displayText.isEmpty())
				displayText += " / ";
			displayText += qaNote.trim();
		}

		RejectionReasonDto.Coding coding = new RejectionReasonDto.Coding(
				"http://terminology.hl7.org/CodeSystem/task-rejection-reason", "invalid-sample", displayText);
		dto.setCoding(java.util.Collections.singletonList(coding));
		dto.setText(displayText);
		return ResponseEntity.ok(dto);
	}

}
