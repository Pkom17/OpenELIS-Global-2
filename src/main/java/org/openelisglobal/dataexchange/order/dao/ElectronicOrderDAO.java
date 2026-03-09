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
package org.openelisglobal.dataexchange.order.dao;

import java.sql.Date;
import java.sql.Timestamp;
import java.util.List;

import org.openelisglobal.common.dao.BaseDAO;
import org.openelisglobal.common.exception.LIMSRuntimeException;
import org.openelisglobal.dataexchange.order.valueholder.VlOrderDisplayItem;
import org.openelisglobal.dataexchange.order.valueholder.ElectronicOrder;
import org.openelisglobal.dataexchange.order.valueholder.ElectronicOrder.SortOrder;

public interface ElectronicOrderDAO extends BaseDAO<ElectronicOrder, String> {

    public List<ElectronicOrder> getElectronicOrdersByExternalId(String id) throws LIMSRuntimeException;

//	public List<ElectronicOrder> getElectronicOrdersByPatientId(String id) throws LIMSRuntimeException;

//	public void updateData(ElectronicOrder eOrder) throws LIMSRuntimeException;

//	public List<ElectronicOrder> getAllElectronicOrders();

    List<ElectronicOrder> getAllElectronicOrdersOrderedBy(ElectronicOrder.SortOrder order);

    public List<ElectronicOrder> getAllElectronicOrdersContainingValueOrderedBy(String searchValue, SortOrder order);

    List<ElectronicOrder> getAllElectronicOrdersContainingValuesOrderedBy(String accessionNumber,
            String patientLastName, String patientFirstName, String gender, SortOrder order);

    public List<ElectronicOrder> getElectronicOrdersContainingValueExludedByOrderedBy(String searchValue,
            List<Integer> exludedStatusIds, SortOrder sortOrder);

    List<ElectronicOrder> getAllElectronicOrdersByDateAndStatus(Date startDate, Date endDate, String statusId,
            SortOrder sortOrder);

    List<ElectronicOrder> getAllElectronicOrdersByTimestampAndStatus(Timestamp startTimestamp, Timestamp endTimestamp,
            String statusId, SortOrder sortOrder);

    public List<ElectronicOrder> getAllElectronicOrdersMatchingAnyValue(List<String> identifierValues,
            String patientValue, SortOrder order);
    
    public ElectronicOrder getLastEnteredByPatientIdentifier(String patientIdentifier);

    /**
     * Recherche des demandes CV en LEFT JOIN vl_eorder_request_flat ← electronic_order.
     * vl_eorder_request_flat est la source prioritaire ; electronic_order complète
     * avec le statut labo (statusId), la priorité et l'id de rejet (qaEventId).
     *
     * @param searchValue  identifiant libre (request_uuid, labno, patient_code, patient_subject_number)
     * @param startTimestamp  borne début sur authored_on / order_timestamp (null = sans limite)
     * @param endTimestamp    borne fin (null = sans limite)
     * @param statusId        filtrer par statusId OpenELIS (null = tous)
     */
    List<VlOrderDisplayItem> searchCvOrders(String searchValue,
            java.sql.Timestamp startTimestamp,
            java.sql.Timestamp endTimestamp,
            String statusId);

}
