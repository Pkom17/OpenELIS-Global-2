package spring.unused.typeofsample.form;

import java.util.List;

import spring.mine.common.form.BaseForm;

public class TypeOfSamplePanelMenuForm extends BaseForm {
	private List menuList;

	private String[] selectedIDs;

	public TypeOfSamplePanelMenuForm() {
		setFormName("typeOfSamplePanelMenuForm");
	}

	public List getMenuList() {
		return menuList;
	}

	public void setMenuList(List menuList) {
		this.menuList = menuList;
	}

	public String[] getSelectedIDs() {
		return selectedIDs;
	}

	public void setSelectedIDs(String[] selectedIDs) {
		this.selectedIDs = selectedIDs;
	}
}