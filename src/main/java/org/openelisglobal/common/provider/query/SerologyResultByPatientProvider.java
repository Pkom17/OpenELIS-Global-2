package org.openelisglobal.common.provider.query;

import java.io.IOException;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openelisglobal.common.log.LogEvent;
import org.openelisglobal.common.services.SerologyHivTypeResolver;
import org.openelisglobal.common.servlet.validation.AjaxServlet;
import org.openelisglobal.common.util.XMLUtil;
import org.openelisglobal.dictionary.valueholder.Dictionary;
import org.openelisglobal.patient.valueholder.Patient;

/**
 * AJAX provider that searches for a finalized serology HIV type result for a
 * given patient (identified by subjectNumber or siteSubjectNumber).
 *
 * Because the same physical patient may have multiple patient entries
 * (one per program), this provider searches ALL matching patient records
 * for a "Conclusion" result in the HIVResult dictionary category.
 *
 * Returns XML with:
 * - serologyResult: the dictionary entry text of the HIV type (e.g. "HIV1")
 * - patientPK: the first patient's primary key
 * - subjectNumber: the patient's national ID
 * - siteSubjectNumber: the patient's external ID
 */
public class SerologyResultByPatientProvider extends BaseQueryProvider {

    private static final String PATIENT_PK = "patientPK";

    private SerologyHivTypeResolver serologyResolver = new SerologyHivTypeResolver();

    public SerologyResultByPatientProvider() {
        super();
    }

    public SerologyResultByPatientProvider(AjaxServlet ajaxServlet) {
        this.ajaxServlet = ajaxServlet;
    }

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String subjectNumber = request.getParameter("subjectNumber");
        String siteSubjectNumber = request.getParameter("siteSubjectNumber");

        StringBuilder xml = new StringBuilder();
        String result = INVALID;

        try {
            List<Patient> patients = serologyResolver.findMatchingPatients(subjectNumber, siteSubjectNumber);

            if (!patients.isEmpty()) {
                Patient firstPatient = patients.get(0);
                XMLUtil.appendKeyValue(PATIENT_PK, firstPatient.getId(), xml);
                XMLUtil.appendKeyValue("subjectNumber",
                        firstPatient.getNationalId() != null ? firstPatient.getNationalId() : "N/A", xml);
                XMLUtil.appendKeyValue("siteSubjectNumber",
                        firstPatient.getExternalId() != null ? firstPatient.getExternalId() : "N/A", xml);

                // Search for HIV conclusion across ALL matching patient records
                Dictionary hivResult = serologyResolver.findConclusionHivResult(patients);

                XMLUtil.appendKeyValue("serologyResult", hivResult != null ? hivResult.getDictEntry() : "none", xml);
                result = VALID;
            } else {
                XMLUtil.appendKeyValue(PATIENT_PK, "notFound", xml);
            }
        } catch (RuntimeException e) {
            LogEvent.logError(e.getMessage(), e);
            XMLUtil.appendKeyValue(PATIENT_PK, "error", xml);
        }

        ajaxServlet.sendData(xml.toString(), result, request, response);
    }
}
