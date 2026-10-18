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
* Copyright (C) CIRG, University of Washington, Seattle WA.  All Rights Reserved.
*
*/
package org.openelisglobal.reports.action.implementation;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.sql.SQLException;
import java.text.ParseException;
import java.util.List;

import javax.xml.ws.Response;

import org.openelisglobal.common.log.LogEvent;
import org.openelisglobal.reports.action.implementation.reportBeans.CSVColumnBuilder;

import net.sf.jasperreports.engine.JRException;

public abstract class CSVSampleExportReport extends CSVExportReport {

	protected String lowDateStr;
	protected String highDateStr;
	protected List<Object> reportItems;
	protected int iReportItem = -1;

	protected CSVColumnBuilder csvColumnBuilder;
	protected DateRange dateRange;

	@Override
	public String getResponseHeaderName() {
		return "Content-Disposition";
	}

	@Override
	public String getResponseHeaderContent() {
		return "attachment;filename=" + getReportFileName() + ".csv";
	}

	/**
	 * Do everything necessary for to generate a CSV text file.
	 *
	 * @param reportDefinitionName full path to the definition for the report.
	 * @throws IOException
	 * @throws UnsupportedEncodingException
	 * @throws SQLException
	 * @throws JRException
	 * @throws IllegalStateException
	 * @throws ParseException
	 * @see org.openelisglobal.reports.action.implementation.IReportCreator#runReport(java.lang.String,
	 *      Response)
	 */
	@Override
	public byte[] runReport() {
		if (errorFound) {
			try {
				return super.runReport();
			} catch (IllegalStateException | IOException | SQLException | JRException | ParseException e) {
				LogEvent.logErrorStack(e);
			}
		}

		ByteArrayOutputStream buffer = new ByteArrayOutputStream(100000);
		try {
			buffer.write(csvColumnBuilder.getColumnNamesLine().getBytes("utf-8"));
			writeResultsToBuffer(buffer);
		} catch (IOException e) {
			LogEvent.logErrorStack(e);
		} finally {
			// always give the database connection back
			try {
				csvColumnBuilder.closeResultSet();
			} catch (SQLException e) {
				LogEvent.logErrorStack(e);
			}
		}

		return buffer.toByteArray();
	}

	protected void writeResultsToBuffer(ByteArrayOutputStream buffer) {

		try {
			while (csvColumnBuilder.next()) {
				buffer.write(csvColumnBuilder.nextLine().getBytes("utf-8"));
			}
		} catch (SQLException | IOException | ParseException e) {
			LogEvent.logErrorStack(e);
		}
	}

}
