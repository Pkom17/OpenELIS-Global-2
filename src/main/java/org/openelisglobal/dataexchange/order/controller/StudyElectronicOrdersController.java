package org.openelisglobal.dataexchange.order.controller;

import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;

import org.apache.commons.lang3.StringUtils;
import org.openelisglobal.common.controller.BaseController;
import org.openelisglobal.common.log.LogEvent;
import org.openelisglobal.common.services.DisplayListService;
import org.openelisglobal.common.services.DisplayListService.ListType;
import org.openelisglobal.common.services.IStatusService;
import org.openelisglobal.common.services.StatusService.ExternalOrderStatus;
import org.openelisglobal.dataexchange.order.ElectronicOrderSortOrderCategoryConvertor;
import org.openelisglobal.dataexchange.order.form.ElectronicOrderViewForm;
import org.openelisglobal.dataexchange.order.valueholder.ElectronicOrder;
import org.openelisglobal.dataexchange.order.valueholder.VlOrderDisplayItem;
import org.openelisglobal.dataexchange.service.order.EorderFlatQueryService;
import org.openelisglobal.dataexchange.service.order.ElectronicOrderService;
import org.openelisglobal.organization.util.OrganizationTypeList;
import org.openelisglobal.qaevent.service.QaEventService;
import org.openelisglobal.qaevent.valueholder.QaEvent;
import org.openelisglobal.spring.util.SpringContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.annotation.InitBinder;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;

@Controller
public class StudyElectronicOrdersController extends BaseController {

	private static final String[] ALLOWED_FIELDS = new String[] { "searchType", "searchValue", "startDate", "endDate",
			"testIds", "statusId", "useAllInfo", "organizationId", "organizationList" };

	@Autowired
	private ElectronicOrderService electronicOrderService;
	@Autowired
	private QaEventService qaEventService;
	@Autowired
	private EorderFlatQueryService eorderFlatQueryService;

	private String searchParameters = "";

	@InitBinder
	public void initBinder(final WebDataBinder webdataBinder) {
		webdataBinder.registerCustomEditor(ElectronicOrder.SortOrder.class,
				new ElectronicOrderSortOrderCategoryConvertor());
		webdataBinder.setAllowedFields(ALLOWED_FIELDS);
	}

	@RequestMapping(value = "/StudyElectronicOrders", method = RequestMethod.GET)
	public ModelAndView showElectronicOrders(HttpServletRequest request,
			@ModelAttribute("form") @Valid ElectronicOrderViewForm form, BindingResult result) {
		form.setReferralFacilitySelectionList(
				DisplayListService.getInstance().getList(ListType.REFERRAL_ORGANIZATIONS));
		form.setTestSelectionList(DisplayListService.getInstance().getList(ListType.ORDERABLE_TESTS));
		form.setStatusSelectionList(DisplayListService.getInstance().getList(ListType.ELECTRONIC_ORDER_STATUSES));
		form.setOrganizationList(OrganizationTypeList.ARV_ORGS.getList());
		form.setQaEvents(DisplayListService.getInstance().getList(ListType.QA_EVENTS));
		if (form.getSearchType() != null) {
			List<VlOrderDisplayItem> cvOrders = electronicOrderService.searchCvOrders(form);
			form.setSearchFinished(true);
			form.setCvOrders(cvOrders);
		}

		return findForward(FWD_SUCCESS, form);
	}

	@RequestMapping(value = "/rejectElectronicOrders", method = RequestMethod.GET)
	public ModelAndView rejectElectronicOrders(HttpServletRequest request,
			@ModelAttribute("form") @Valid ElectronicOrderViewForm form, BindingResult result) {
		try {
			String externalOrderNumber = request.getParameter("externalOrderId");
			String qaEventIdString = request.getParameter("qaEventId");
			Integer qaEventId = null;
			try {
				qaEventId = Integer.parseInt(qaEventIdString);
			} catch (Exception e) {
			}
			String qaAuthorizer = request.getParameter("qaAuthorizer");
			String qaNote = request.getParameter("qaNote");
			String searchType = request.getParameter("searchType");
			String startDate = request.getParameter("startDate");
			String endDate = request.getParameter("endDate");
			String statusId = request.getParameter("statusId");
			searchParameters = "?searchType=" + searchType + "&startDate=" + startDate + "&endDate=" + endDate
					+ "&statusId=" + statusId;

			if (StringUtils.isNotBlank(externalOrderNumber)) {
				ElectronicOrder eOrder = null;
				List<ElectronicOrder> eOrders = electronicOrderService
						.getElectronicOrdersByExternalId(externalOrderNumber);
				if (eOrders.size() > 0)
					eOrder = eOrders.get(eOrders.size() - 1);
				if (eOrder != null) {

					eOrder.setStatusId(
							SpringContext.getBean(IStatusService.class).getStatusID(ExternalOrderStatus.NonConforming));
					eOrder.setRejectReasonId(qaEventId);
					eOrder.setRejectComment(qaNote);
					eOrder.setQaAuthorizer(qaAuthorizer);
					eOrder.setSyncFlag(0);
					electronicOrderService.update(eOrder);

					// Mettre à jour la table plate pour remontée vers le serveur consolidé
					String rejectReasonText = null;
					if (qaEventId != null) {
						try {
							QaEvent qaEvent = qaEventService.get(String.valueOf(qaEventId));
							if (qaEvent != null) {
								rejectReasonText = qaEvent.getQaEventName();
							}
						} catch (Exception ex) {
							// silent
						}
					}
					eorderFlatQueryService.updateLocalStatus(
							externalOrderNumber, "REJECTED", rejectReasonText, qaNote, qaAuthorizer);
				}
			}
		} catch (Exception e) {
			LogEvent.logErrorStack(e);
			e.printStackTrace();
		}
		return findForward(FWD_SUCCESS_INSERT, form);

	}

	@RequestMapping(value = "/cancelElectronicOrders", method = RequestMethod.GET)
	public ModelAndView cancelElectronicOrders(HttpServletRequest request,
			@ModelAttribute("form") @Valid ElectronicOrderViewForm form, BindingResult result) {
		try {
			String externalOrderNumber = request.getParameter("externalOrderId");
			String searchType = request.getParameter("searchType");
			String startDate = request.getParameter("startDate");
			String endDate = request.getParameter("endDate");
			String statusId = request.getParameter("statusId");
			searchParameters = "?searchType=" + searchType + "&startDate=" + startDate + "&endDate=" + endDate
					+ "&statusId=" + statusId;

			if (StringUtils.isNotBlank(externalOrderNumber)) {
				ElectronicOrder eOrder = null;
				List<ElectronicOrder> eOrders = electronicOrderService
						.getElectronicOrdersByExternalId(externalOrderNumber);
				if (eOrders.size() > 0)
					eOrder = eOrders.get(eOrders.size() - 1);
				if (eOrder != null) {

					eOrder.setStatusId(
							SpringContext.getBean(IStatusService.class).getStatusID(ExternalOrderStatus.Cancelled));
					eOrder.setSyncFlag(0);
					electronicOrderService.update(eOrder);

					// Mettre à jour la table plate pour remontée vers le serveur consolidé
					eorderFlatQueryService.updateLocalStatus(
							externalOrderNumber, "CANCELLED", null, null, null);
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return findForward(FWD_SUCCESS_INSERT, form);
	}


	@Override
	protected String findLocalForward(String forward) {
		if (FWD_SUCCESS.equals(forward)) {
			return "studyElectronicOrderViewDefinition";
		} else if (FWD_SUCCESS_INSERT.equals(forward)) {
			return "redirect:/StudyElectronicOrders" + searchParameters;
		} else {
			return "PageNotFound";
		}
	}

	@Override
	protected String getPageTitleKey() {
		return "eorder.browse.title";
	}

	@Override
	protected String getPageSubtitleKey() {
		return "study.eorder.browse.title";
	}

}
