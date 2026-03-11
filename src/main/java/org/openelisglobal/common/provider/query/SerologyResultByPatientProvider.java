package org.openelisglobal.common.provider.query;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openelisglobal.analysis.service.AnalysisService;
import org.openelisglobal.analysis.valueholder.Analysis;
import org.openelisglobal.analyte.service.AnalyteService;
import org.openelisglobal.analyte.valueholder.Analyte;
import org.openelisglobal.common.log.LogEvent;
import org.openelisglobal.common.services.StatusService;
import org.openelisglobal.common.servlet.validation.AjaxServlet;
import org.openelisglobal.common.util.XMLUtil;
import org.openelisglobal.dictionary.service.DictionaryService;
import org.openelisglobal.dictionary.valueholder.Dictionary;
import org.openelisglobal.patient.service.PatientService;
import org.openelisglobal.patient.valueholder.Patient;
import org.openelisglobal.result.service.ResultService;
import org.openelisglobal.result.valueholder.Result;
import org.openelisglobal.sample.valueholder.Sample;
import org.openelisglobal.samplehuman.service.SampleHumanService;
import org.openelisglobal.spring.util.SpringContext;

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
    private static final String CONCLUSION_ANALYTE_NAME = "Conclusion";
    private static final String HIV_RESULT_CATEGORY = "HIVResult";

    private PatientService patientService = SpringContext.getBean(PatientService.class);
    private SampleHumanService sampleHumanService = SpringContext.getBean(SampleHumanService.class);
    private AnalysisService analysisService = SpringContext.getBean(AnalysisService.class);
    private ResultService resultService = SpringContext.getBean(ResultService.class);
    private DictionaryService dictionaryService = SpringContext.getBean(DictionaryService.class);
    private AnalyteService analyteService = SpringContext.getBean(AnalyteService.class);

    private String conclusionAnalyteId;

    public SerologyResultByPatientProvider() {
        super();
        initConclusionAnalyteId();
    }

    public SerologyResultByPatientProvider(AjaxServlet ajaxServlet) {
        this.ajaxServlet = ajaxServlet;
        initConclusionAnalyteId();
    }

    private void initConclusionAnalyteId() {
        Analyte searchAnalyte = new Analyte();
        searchAnalyte.setAnalyteName(CONCLUSION_ANALYTE_NAME);
        Analyte conclusionAnalyte = analyteService.getAnalyteByName(searchAnalyte, false);
        conclusionAnalyteId = conclusionAnalyte != null ? conclusionAnalyte.getId() : null;
    }

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String subjectNumber = request.getParameter("subjectNumber");
        String siteSubjectNumber = request.getParameter("siteSubjectNumber");

        StringBuilder xml = new StringBuilder();
        String result = INVALID;

        try {
            List<Patient> patients = findAllMatchingPatients(subjectNumber, siteSubjectNumber);

            if (!patients.isEmpty()) {
                Patient firstPatient = patients.get(0);
                XMLUtil.appendKeyValue(PATIENT_PK, firstPatient.getId(), xml);
                XMLUtil.appendKeyValue("subjectNumber",
                        firstPatient.getNationalId() != null ? firstPatient.getNationalId() : "N/A", xml);
                XMLUtil.appendKeyValue("siteSubjectNumber",
                        firstPatient.getExternalId() != null ? firstPatient.getExternalId() : "N/A", xml);

                // Search for HIV conclusion across ALL matching patient records
                String hivType = null;
                for (Patient patient : patients) {
                    hivType = findConclusionHivResult(patient);
                    if (hivType != null) {
                        break;
                    }
                }

                XMLUtil.appendKeyValue("serologyResult", hivType != null ? hivType : "none", xml);
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

    /**
     * Find ALL patient records matching the given subjectNumber or siteSubjectNumber.
     * The same physical patient may have multiple entries (one per program).
     */
    private List<Patient> findAllMatchingPatients(String subjectNumber, String siteSubjectNumber) {
        Set<String> seenIds = new HashSet<>();
        List<Patient> allPatients = new ArrayList<>();

        if (subjectNumber != null && !subjectNumber.trim().isEmpty()) {
            List<Patient> byNationalId = patientService.getPatientsByNationalId(subjectNumber.trim());
            if (byNationalId != null) {
                for (Patient p : byNationalId) {
                    if (seenIds.add(p.getId())) {
                        allPatients.add(p);
                    }
                }
            }
        }

        if (siteSubjectNumber != null && !siteSubjectNumber.trim().isEmpty()) {
            Patient byExternalId = patientService.getPatientByExternalId(siteSubjectNumber.trim());
            if (byExternalId != null && seenIds.add(byExternalId.getId())) {
                allPatients.add(byExternalId);
            }
            List<Patient> byNationalId2 = patientService.getPatientsByNationalId(siteSubjectNumber.trim());
            if (byNationalId2 != null) {
                for (Patient p : byNationalId2) {
                    if (seenIds.add(p.getId())) {
                        allPatients.add(p);
                    }
                }
            }
        }

        // Cross-search: for each patient found, also look for other patients
        // sharing the same nationalId or externalId
        List<Patient> additionalPatients = new ArrayList<>();
        for (Patient p : allPatients) {
            if (p.getNationalId() != null && !p.getNationalId().trim().isEmpty()) {
                List<Patient> related = patientService.getPatientsByNationalId(p.getNationalId());
                if (related != null) {
                    for (Patient r : related) {
                        if (seenIds.add(r.getId())) {
                            additionalPatients.add(r);
                        }
                    }
                }
            }
            if (p.getExternalId() != null && !p.getExternalId().trim().isEmpty()) {
                Patient byExt = patientService.getPatientByExternalId(p.getExternalId());
                if (byExt != null && seenIds.add(byExt.getId())) {
                    additionalPatients.add(byExt);
                }
            }
        }
        allPatients.addAll(additionalPatients);

        return allPatients;
    }

    /**
     * Search all finalized analyses for this patient to find an HIV type result.
     * Strategy:
     * 1. First look for a result with the "Conclusion" analyte in HIVResult category
     * 2. Fallback: look for any Dictionary result in the HIVResult category
     */
    private String findConclusionHivResult(Patient patient) {
        String finalizedStatusId = StatusService.getInstance()
                .getStatusID(StatusService.AnalysisStatus.Finalized);

        List<Sample> samples = sampleHumanService.getSamplesForPatient(patient.getId());
        String fallbackHivEntry = null;

        for (int i = samples.size() - 1; i >= 0; i--) {
            Sample sample = samples.get(i);
            List<Analysis> analyses = analysisService.getAnalysesBySampleId(sample.getId());

            for (Analysis analysis : analyses) {
                if (!finalizedStatusId.equals(analysis.getStatusId())) {
                    continue;
                }

                List<Result> results = resultService.getResultsByAnalysis(analysis);
                if (results == null || results.isEmpty()) {
                    continue;
                }

                for (Result r : results) {
                    // Strategy 1: Conclusion analyte match (priority)
                    if (conclusionAnalyteId != null && r.getAnalyte() != null
                            && conclusionAnalyteId.equals(r.getAnalyte().getId())) {
                        String hivEntry = resolveHivResultDictionaryEntry(r.getValue());
                        if (hivEntry != null) {
                            return hivEntry;
                        }
                    }

                    // Strategy 2: Any Dictionary result in HIVResult category
                    if ("D".equals(r.getResultType()) && fallbackHivEntry == null) {
                        String hivEntry = resolveHivResultDictionaryEntry(r.getValue());
                        if (hivEntry != null) {
                            fallbackHivEntry = hivEntry;
                        }
                    }
                }
            }
        }

        return fallbackHivEntry;
    }

    /**
     * Resolve a dictionary ID to its entry text, but only if it belongs
     * to the HIVResult category.
     */
    private String resolveHivResultDictionaryEntry(String dictionaryId) {
        if (dictionaryId == null || dictionaryId.trim().isEmpty()) {
            return null;
        }
        try {
            Dictionary dict = dictionaryService.getDictionaryById(dictionaryId);
            if (dict != null
                    && dict.getDictEntry() != null
                    && dict.getDictionaryCategory() != null
                    && HIV_RESULT_CATEGORY.equals(dict.getDictionaryCategory().getCategoryName())) {
                return dict.getDictEntry();
            }
        } catch (RuntimeException e) {
            LogEvent.logError(e.getMessage(), e);
        }
        return null;
    }
}
