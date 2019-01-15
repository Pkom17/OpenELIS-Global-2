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
* Copyright (C) The Minnesota Department of Health.  All Rights Reserved.
*
* Contributor(s): CIRG, University of Washington, Seattle WA.
*/
package us.mn.state.health.lims.workplan.reports;

import java.util.HashMap;
import java.util.List;

import spring.mine.common.form.BaseForm;
import us.mn.state.health.lims.common.util.StringUtil;
import us.mn.state.health.lims.resultvalidation.bean.AnalysisItem;

public class ElisaWorkplanReport implements IWorkplanReport {

	private final String fileName = "ElisaWorkplan";
	private final HashMap<String, Object> parameterMap = new HashMap<>();
	private String testSection = "";
	private String messageKey = "banner.menu.workplan.";
	protected String reportPath = "";

	public ElisaWorkplanReport(String testSection) {
		messageKey = messageKey + testSection;
		testSection = StringUtil.getContextualMessageForKey(messageKey);
		this.testSection = testSection;
	}

	@Override
	public String getFileName() {
		return fileName;
	}

	@Override
	public HashMap<String, Object> getParameters() {
		parameterMap.put("testSection", testSection);
		return parameterMap;

	}

	@Override
	public List<?> prepareRows(BaseForm form) {

		List<AnalysisItem> workplanTests = (List<AnalysisItem>) form.get("resultList");
		return workplanTests;
	}

	@Override
	public void setReportPath(String reportPath) {
		this.reportPath = reportPath;

	}

}