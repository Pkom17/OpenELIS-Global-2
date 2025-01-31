package org.openelisglobal.sampleorganization.service;

import java.util.UUID;

import org.openelisglobal.common.service.BaseObjectServiceImpl;
import org.openelisglobal.sample.valueholder.Sample;
import org.openelisglobal.sampleitem.valueholder.SampleItem;
import org.openelisglobal.sampleorganization.dao.SampleOrganizationDAO;
import org.openelisglobal.sampleorganization.valueholder.SampleOrganization;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SampleOrganizationServiceImpl extends BaseObjectServiceImpl<SampleOrganization, String>
        implements SampleOrganizationService {
    @Autowired
    protected SampleOrganizationDAO baseObjectDAO;

    SampleOrganizationServiceImpl() {
        super(SampleOrganization.class);
        this.auditTrailLog = true;
    }

    @Override
    protected SampleOrganizationDAO getBaseObjectDAO() {
        return baseObjectDAO;
    }

    @Override
    @Transactional(readOnly = true)
    public void getData(SampleOrganization sampleOrg) {
        getBaseObjectDAO().getData(sampleOrg);

    }

    @Override
    @Transactional(readOnly = true)
    public void getDataBySample(SampleOrganization sampleOrg) {
        getBaseObjectDAO().getDataBySample(sampleOrg);

    }

    @Override
    @Transactional(readOnly = true)
    public SampleOrganization getDataBySample(Sample sample) {
        return getBaseObjectDAO().getDataBySample(sample);
    }
    
    @Transactional
    @Override
    public String insert(SampleOrganization sampleOrg) {
        return baseObjectDAO.insert(sampleOrg);
    }
   
    @Transactional
    @Override
    public SampleOrganization update(SampleOrganization sampleOrg) {
        return baseObjectDAO.update(sampleOrg);
    }
}
