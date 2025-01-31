package org.openelisglobal.dataexchange.order.controller;

import org.apache.commons.lang3.ObjectUtils;
import org.hl7.fhir.r4.model.ResourceType;
import org.openelisglobal.dataexchange.fhir.service.FhirApiWorkflowService;
import org.openelisglobal.dataexchange.service.order.ElectronicOrderService;
import org.openelisglobal.spring.util.SpringContext;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(value = "/rest_eorder")
public class StudyElectronicOrdersRestController {

	private ElectronicOrderService electronicOrderService = SpringContext.getBean(ElectronicOrderService.class);

	private FhirApiWorkflowService fhirApiWorkflowService = SpringContext.getBean(FhirApiWorkflowService.class);

	@GetMapping(value = "/external_id")
	public ResponseEntity<String> getEOrderByPatient(@RequestParam String patientCode) {
		String externalId = electronicOrderService.getEnteredElectronicOrderByPatient(patientCode);
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

}
