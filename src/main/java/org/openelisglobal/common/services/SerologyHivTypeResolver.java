package org.openelisglobal.common.services;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.openelisglobal.analysis.service.AnalysisService;
import org.openelisglobal.analysis.valueholder.Analysis;
import org.openelisglobal.analyte.service.AnalyteService;
import org.openelisglobal.analyte.valueholder.Analyte;
import org.openelisglobal.common.log.LogEvent;
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
 * Resolves a patient's HIV type from finalized HIV serology results. Shared by
 * the serology control at sample entry and by the VL patient report so both
 * apply the same rule.
 */
public class SerologyHivTypeResolver {

    private static final String CONCLUSION_ANALYTE_NAME = "Conclusion";
    private static final String HIV_RESULT_CATEGORY = "HIVResult";

    /** HIVResult entries that identify an HIV type (Negative, Indeterminate... do not). */
    public static final List<String> HIV_TYPE_ENTRIES = Arrays.asList("HIV1", "HIV2", "HIVD");

    private PatientService patientService = SpringContext.getBean(PatientService.class);
    private SampleHumanService sampleHumanService = SpringContext.getBean(SampleHumanService.class);
    private AnalysisService analysisService = SpringContext.getBean(AnalysisService.class);
    private ResultService resultService = SpringContext.getBean(ResultService.class);
    private DictionaryService dictionaryService = SpringContext.getBean(DictionaryService.class);
    private AnalyteService analyteService = SpringContext.getBean(AnalyteService.class);

    private String conclusionAnalyteId;

    public SerologyHivTypeResolver() {
        Analyte searchAnalyte = new Analyte();
        searchAnalyte.setAnalyteName(CONCLUSION_ANALYTE_NAME);
        Analyte conclusionAnalyte = analyteService.getAnalyteByName(searchAnalyte, false);
        conclusionAnalyteId = conclusionAnalyte != null ? conclusionAnalyte.getId() : null;
    }

    /**
     * Patients matching the subject / site subject numbers, plus the other patient
     * records sharing their nationalId or externalId.
     */
    public List<Patient> findMatchingPatients(String subjectNumber, String siteSubjectNumber) {
        Set<String> seenIds = new HashSet<>();
        List<Patient> allPatients = new ArrayList<>();

        if (subjectNumber != null && !subjectNumber.trim().isEmpty()) {
            addAll(patientService.getPatientsByNationalId(subjectNumber.trim()), seenIds, allPatients);
        }

        if (siteSubjectNumber != null && !siteSubjectNumber.trim().isEmpty()) {
            Patient byExternalId = patientService.getPatientByExternalId(siteSubjectNumber.trim());
            if (byExternalId != null && seenIds.add(byExternalId.getId())) {
                allPatients.add(byExternalId);
            }
            addAll(patientService.getPatientsByNationalId(siteSubjectNumber.trim()), seenIds, allPatients);
        }

        addRelatedPatients(seenIds, allPatients);
        return allPatients;
    }

    /**
     * The given patient followed by the other patient records sharing its
     * nationalId or externalId.
     */
    public List<Patient> findRelatedPatients(Patient patient) {
        Set<String> seenIds = new HashSet<>();
        List<Patient> allPatients = new ArrayList<>();
        if (patient != null && seenIds.add(patient.getId())) {
            allPatients.add(patient);
        }
        addRelatedPatients(seenIds, allPatients);
        return allPatients;
    }

    /**
     * HIVResult conclusion of the most recent finalized serology, searched patient
     * by patient in list order. May be a non-type entry such as Negative.
     */
    public Dictionary findConclusionHivResult(List<Patient> patients) {
        for (Patient patient : patients) {
            Dictionary hivResult = findConclusionHivResult(patient);
            if (hivResult != null) {
                return hivResult;
            }
        }
        return null;
    }

    /**
     * HIV type (HIV1, HIV2 or HIVD) resolved by serology, or null when the
     * serology conclusion does not identify a type.
     */
    public Dictionary findSerologyHivType(List<Patient> patients) {
        Dictionary hivResult = findConclusionHivResult(patients);
        return hivResult != null && HIV_TYPE_ENTRIES.contains(hivResult.getDictEntry()) ? hivResult : null;
    }

    private void addRelatedPatients(Set<String> seenIds, List<Patient> allPatients) {
        List<Patient> additionalPatients = new ArrayList<>();
        for (Patient p : allPatients) {
            if (p.getNationalId() != null && !p.getNationalId().trim().isEmpty()) {
                addAll(patientService.getPatientsByNationalId(p.getNationalId()), seenIds, additionalPatients);
            }
            if (p.getExternalId() != null && !p.getExternalId().trim().isEmpty()) {
                Patient byExt = patientService.getPatientByExternalId(p.getExternalId());
                if (byExt != null && seenIds.add(byExt.getId())) {
                    additionalPatients.add(byExt);
                }
            }
        }
        allPatients.addAll(additionalPatients);
    }

    private void addAll(List<Patient> patients, Set<String> seenIds, List<Patient> target) {
        if (patients != null) {
            for (Patient p : patients) {
                if (seenIds.add(p.getId())) {
                    target.add(p);
                }
            }
        }
    }

    private Dictionary findConclusionHivResult(Patient patient) {
        String finalizedStatusId = StatusService.getInstance()
                .getStatusID(StatusService.AnalysisStatus.Finalized);

        List<Sample> samples = sampleHumanService.getSamplesForPatient(patient.getId());
        Dictionary fallbackHivEntry = null;

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
                        Dictionary hivEntry = resolveHivResultDictionaryEntry(r.getValue());
                        if (hivEntry != null) {
                            return hivEntry;
                        }
                    }

                    // Strategy 2: Any Dictionary result in HIVResult category
                    if ("D".equals(r.getResultType()) && fallbackHivEntry == null) {
                        Dictionary hivEntry = resolveHivResultDictionaryEntry(r.getValue());
                        if (hivEntry != null) {
                            fallbackHivEntry = hivEntry;
                        }
                    }
                }
            }
        }

        return fallbackHivEntry;
    }

    private Dictionary resolveHivResultDictionaryEntry(String dictionaryId) {
        if (dictionaryId == null || dictionaryId.trim().isEmpty()) {
            return null;
        }
        try {
            Dictionary dict = dictionaryService.getDictionaryById(dictionaryId);
            if (dict != null
                    && dict.getDictEntry() != null
                    && dict.getDictionaryCategory() != null
                    && HIV_RESULT_CATEGORY.equals(dict.getDictionaryCategory().getCategoryName())) {
                return dict;
            }
        } catch (RuntimeException e) {
            LogEvent.logError(e.getMessage(), e);
        }
        return null;
    }
}
