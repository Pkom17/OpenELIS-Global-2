package org.openelisglobal.dataexchange.service.order;

import java.sql.Date;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang3.ObjectUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.validator.GenericValidator;
import org.openelisglobal.common.service.BaseObjectServiceImpl;
import org.openelisglobal.common.services.IStatusService;
import org.openelisglobal.common.services.StatusService.ExternalOrderStatus;
import org.openelisglobal.common.util.DateUtil;
import org.openelisglobal.dataexchange.order.dao.ElectronicOrderDAO;
import org.openelisglobal.dataexchange.order.form.ElectronicOrderViewForm;
import org.openelisglobal.dataexchange.order.valueholder.VlOrderDisplayItem;
import org.openelisglobal.dataexchange.order.valueholder.ElectronicOrder;
import org.openelisglobal.dataexchange.order.valueholder.ElectronicOrder.SortOrder;
import org.openelisglobal.statusofsample.service.StatusOfSampleService;
import org.openelisglobal.statusofsample.valueholder.StatusOfSample;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ElectronicOrderServiceImpl extends BaseObjectServiceImpl<ElectronicOrder, String>
		implements ElectronicOrderService {
	@Autowired
	protected ElectronicOrderDAO baseObjectDAO;
	@Autowired
	protected IStatusService statusService;
	@Autowired
	private StatusOfSampleService statusOfSampleService;

	ElectronicOrderServiceImpl() {
		super(ElectronicOrder.class);
	}

	@Override
	protected ElectronicOrderDAO getBaseObjectDAO() {
		return baseObjectDAO;
	}

	@Override
	@Transactional(readOnly = true)
	public List<ElectronicOrder> getAllElectronicOrdersOrderedBy(SortOrder order) {
		return getBaseObjectDAO().getAllElectronicOrdersOrderedBy(order);
	}

	@Override
	@Transactional(readOnly = true)
	public List<ElectronicOrder> getElectronicOrdersByExternalId(String id) {
		return getBaseObjectDAO().getElectronicOrdersByExternalId(id);
	}

	@Override
	public List<ElectronicOrder> getAllElectronicOrdersContainingValueOrderedBy(String searchValue, SortOrder order) {

		List<ElectronicOrder> searchResult = getBaseObjectDAO()
				.getAllElectronicOrdersContainingValueOrderedBy(searchValue, order);

		if (searchResult != null && searchResult.size() > 0) {
			return searchResult;
		}
		// this is done in case sample lab number was used to search instead of the
		// order lab number
		if (searchValue != null && searchValue.contains(".")) {
			searchValue = searchValue.substring(0, searchValue.indexOf('.'));
		}
		return getBaseObjectDAO().getAllElectronicOrdersContainingValueOrderedBy(searchValue, order);
	}

	@Override
	public List<ElectronicOrder> getAllElectronicOrdersContainingValuesOrderedBy(String accessionNumber,
			String patientLastName, String patientFirstName, String gender, SortOrder order) {
		return getBaseObjectDAO().getAllElectronicOrdersContainingValuesOrderedBy(accessionNumber, patientLastName,
				patientFirstName, gender, order);
	}

	@Override
	public List<ElectronicOrder> getElectronicOrdersContainingValueExludedByOrderedBy(String searchValue,
			List<ExternalOrderStatus> excludedStatuses, SortOrder sortOrder) {
		List<Integer> exludedStatusIds = new ArrayList<>();
		for (ExternalOrderStatus status : excludedStatuses) {
			String statusId = statusService.getStatusID(status);
			if (!GenericValidator.isBlankOrNull(statusId)) {
				exludedStatusIds.add(Integer.parseInt(statusId));
			}
		}

		return getBaseObjectDAO().getElectronicOrdersContainingValueExludedByOrderedBy(searchValue, exludedStatusIds,
				sortOrder);
	}

	@Override
	public List<ElectronicOrder> getAllElectronicOrdersByDateAndStatus(Date startDate, Date endDate, String statusId,
			SortOrder sortOrder) {
		return getBaseObjectDAO().getAllElectronicOrdersByDateAndStatus(startDate, endDate, statusId, sortOrder);
	}

	@Override
	public List<ElectronicOrder> getAllElectronicOrdersByTimestampAndStatus(Timestamp startTimestamp,
			Timestamp endTimestamp, String statusId, SortOrder sortOrder) {
		return getBaseObjectDAO().getAllElectronicOrdersByTimestampAndStatus(startTimestamp, endTimestamp, statusId,
				sortOrder);
	}

	@Override
	@Transactional(readOnly = true)
	public List<ElectronicOrder> searchForElectronicOrders(ElectronicOrderViewForm form) {
		switch (form.getSearchType()) {
		case IDENTIFIER:
			List<String> identifierValues = new ArrayList<>();
			identifierValues.add(form.getSearchValue());
			String nameValue = form.getSearchValue();

			List<ElectronicOrder> eOrders = baseObjectDAO.getAllElectronicOrdersMatchingAnyValue(identifierValues,
					nameValue, SortOrder.RECEPTION_DATE);

			return eOrders;
		case DATE_STATUS:
			String startDate = form.getStartDate();
			String endDate = form.getEndDate();
			if (GenericValidator.isBlankOrNull(startDate) && !GenericValidator.isBlankOrNull(endDate)) {
				startDate = endDate;
			}
			if (GenericValidator.isBlankOrNull(endDate) && !GenericValidator.isBlankOrNull(startDate)) {
				endDate = startDate;
			}
			java.sql.Timestamp startTimestamp = GenericValidator.isBlankOrNull(startDate) ? null
					: DateUtil.convertStringDateStringTimeToTimestamp(startDate, "00:00:00.0");
			java.sql.Timestamp endTimestamp = GenericValidator.isBlankOrNull(endDate) ? null
					: DateUtil.convertStringDateStringTimeToTimestamp(endDate, "23:59:59");
			return getAllElectronicOrdersByTimestampAndStatus(startTimestamp, endTimestamp, form.getStatusId(),
					SortOrder.RECEPTION_DATE);
		default:
			return null;
		}

	}

	@Override
	@Transactional(readOnly = true)
	public List<ElectronicOrder> searchForStudyElectronicOrders(ElectronicOrderViewForm form) {
		switch (form.getSearchType()) {
		case IDENTIFIER:
			List<String> identifierValues = new ArrayList<>();
			identifierValues.add(form.getSearchValue());
			String nameValue = form.getSearchValue();

			List<ElectronicOrder> eOrders = baseObjectDAO.getAllElectronicOrdersMatchingAnyValue(identifierValues,
					nameValue, SortOrder.RECEPTION_DATE);

			return eOrders;
		case DATE_STATUS:
			String startDate = form.getStartDate();
			String endDate = form.getEndDate();
			if (GenericValidator.isBlankOrNull(startDate) && !GenericValidator.isBlankOrNull(endDate)) {
				startDate = endDate;
			}
			if (GenericValidator.isBlankOrNull(endDate) && !GenericValidator.isBlankOrNull(startDate)) {
				endDate = startDate;
			}
			java.sql.Timestamp startTimestamp = GenericValidator.isBlankOrNull(startDate) ? null
					: DateUtil.convertStringDateStringTimeToTimestamp(startDate, "00:00:00.0");
			java.sql.Timestamp endTimestamp = GenericValidator.isBlankOrNull(endDate) ? null
					: DateUtil.convertStringDateStringTimeToTimestamp(endDate, "23:59:59");
			return getAllElectronicOrdersByTimestampAndStatus(startTimestamp, endTimestamp, form.getStatusId(),
					SortOrder.RECEPTION_DATE);
		default:
			return null;
		}

	}

	public String getEnteredElectronicOrderByPatient(String patientIdentifier) {
		ElectronicOrder eOrder = getBaseObjectDAO().getLastEnteredByPatientIdentifier(patientIdentifier);
		return ObjectUtils.isNotEmpty(eOrder) ? eOrder.getExternalId() : null;
	}

	@Override
	@Transactional(readOnly = true)
	public List<VlOrderDisplayItem> searchCvOrders(ElectronicOrderViewForm form) {
		String searchValue = null;
		java.sql.Timestamp startTimestamp = null;
		java.sql.Timestamp endTimestamp = null;
		String statusId = form.getStatusId();

		switch (form.getSearchType()) {
		case IDENTIFIER:
			searchValue = form.getSearchValue();
			break;
		case DATE_STATUS:
			String startDate = form.getStartDate();
			String endDate = form.getEndDate();
			if (GenericValidator.isBlankOrNull(startDate) && !GenericValidator.isBlankOrNull(endDate)) {
				startDate = endDate;
			}
			if (GenericValidator.isBlankOrNull(endDate) && !GenericValidator.isBlankOrNull(startDate)) {
				endDate = startDate;
			}
			startTimestamp = GenericValidator.isBlankOrNull(startDate) ? null
					: DateUtil.convertStringDateStringTimeToTimestamp(startDate, "00:00:00.0");
			endTimestamp = GenericValidator.isBlankOrNull(endDate) ? null
					: DateUtil.convertStringDateStringTimeToTimestamp(endDate, "23:59:59");
			break;
		default:
			return new ArrayList<>();
		}

		List<VlOrderDisplayItem> items = baseObjectDAO.searchCvOrders(
				searchValue, startTimestamp, endTimestamp, statusId);

		// Résoudre les statusId numériques en texte lisible
		if (items != null) {
			for (VlOrderDisplayItem item : items) {
				if (StringUtils.isNumeric(item.getStatus())) {
					try {
						StatusOfSample sos = statusOfSampleService.get(item.getStatus());
						if (sos != null) {
							item.setStatus(sos.getDefaultLocalizedName());
						}
					} catch (Exception e) {
						// laisser le statusId brut si non résolu
					}
				}
			}
		}
		return items != null ? items : new ArrayList<>();
	}

}
