package org.openelisglobal.sample.service;

import javax.servlet.http.HttpServletRequest;

import org.openelisglobal.sample.form.SampleTbEntryForm;
import org.openelisglobal.sample.valueholder.Sample;

public interface TbSampleService {
	boolean persistTbData(SampleTbEntryForm form, HttpServletRequest request);
	
	SampleTbEntryForm getTBSampleFormData(String labnoForSearch);
}
