package org.openelisglobal.dataexchange.order.api;

import java.util.Collections;
import java.util.List;

public class RejectionReasonDto {
	public static class Coding {
		private String system;
		private String code;
		private String display;

		public Coding() {
		}

		public Coding(String system, String code, String display) {
			this.system = system;
			this.code = code;
			this.display = display;
		}

		public String getSystem() {
			return system;
		}

		public void setSystem(String system) {
			this.system = system;
		}

		public String getCode() {
			return code;
		}

		public void setCode(String code) {
			this.code = code;
		}

		public String getDisplay() {
			return display;
		}

		public void setDisplay(String display) {
			this.display = display;
		}
	}

	private List<Coding> coding = Collections.emptyList();
	private String text;

	public RejectionReasonDto() {
	}

	public RejectionReasonDto(List<Coding> coding, String text) {
		this.coding = coding;
		this.text = text;
	}

	public List<Coding> getCoding() {
		return coding;
	}

	public void setCoding(List<Coding> coding) {
		this.coding = coding;
	}

	public String getText() {
		return text;
	}

	public void setText(String text) {
		this.text = text;
	}
}