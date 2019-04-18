package com.redmoon.oa.flow.macroctl;

import java.util.Iterator;
import java.util.Vector;

import javax.servlet.http.*;

import org.apache.struts2.ServletActionContext;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.cloudwebsoft.framework.util.LogUtil;
import com.opensymphony.xwork2.ActionContext;
import com.redmoon.oa.dept.DeptUserDb;
import com.redmoon.oa.flow.*;

import cn.js.fan.util.ErrMsgException;
import cn.js.fan.util.StrUtil;

import com.redmoon.oa.person.UserDb;
import com.redmoon.oa.visual.FormDAO;
import cn.js.fan.util.ParamUtil;
import cn.js.fan.web.Global;

import com.redmoon.oa.android.Constant;
import com.redmoon.oa.android.Privilege;
import com.redmoon.oa.base.IFormDAO;

/**
 * <p>
 * Title:
 * </p>
 * 
 * <p>
 * Description:
 * </p>
 * 
 * <p>
 * Copyright: Copyright (c) 2006
 * </p>
 * 
 * <p>
 * Company:
 * </p>
 * 
 * @author not attributable
 * @version 1.0
 */
public class SalesCustomerListWinCtl extends AbstractMacroCtl {
	public SalesCustomerListWinCtl() {
	}

	public Object getValueForCreate(FormField ff) {
		return ff.getValue();
	}

	public FormDAO getFormDAOOfCustomer(int id) {
		FormDb fd = new FormDb();
		fd = fd.getFormDb("sales_customer");
		FormDAO fdao = new FormDAO(id, fd);
		return fdao;
	}

	/**
	 * 用于列表中显示宏控件的值
	 * 
	 * @param request
	 *            HttpServletRequest
	 * @param ff
	 *            FormField
	 * @param fieldValue
	 *            String
	 * @return String
	 */
	public String converToHtml(HttpServletRequest request, FormField ff,
			String fieldValue) {
		String v = StrUtil.getNullStr(fieldValue);
		if (!v.equals("")) {
			// LogUtil.getLog(getClass()).info("StrUtil.toInt(v)=" +
			// StrUtil.toInt(v));
			FormDAO fdao = getFormDAOOfCustomer(StrUtil.toInt(v));
			String str = fdao.getFieldValue("customer");
			return str;
		} else
			return "";
	}

	/**
	 * convertToHTMLCtl
	 * 
	 * @param request
	 *            HttpServletRequest
	 * @param ff
	 *            FormField
	 * @return String
	 * @todo Implement this com.redmoon.oa.base.IFormMacroCtl method
	 */
	public String convertToHTMLCtl(HttpServletRequest request, FormField ff) {
		String str = "";
		String v = "";
		if (!StrUtil.getNullStr(ff.getValue()).equals("")) {
			// LogUtil.getLog(getClass()).info("StrUtil.toInt(ff.getValue())=" +
			// StrUtil.toInt(ff.getValue()));
			FormDAO fdao = getFormDAOOfCustomer(StrUtil.toInt(ff.getValue()));
			// LogUtil.getLog(getClass()).info("mobile=" +
			// fdao.getFieldValue("mobile"));
			v = fdao.getFieldValue("customer");
		}

		int customerId = ParamUtil.getInt(request, "customerId", -1);
		boolean isCustomerLoaded = false;
		if (customerId != -1) {
			FormDb fdCustomer = new FormDb();
			fdCustomer = fdCustomer.getFormDb("sales_customer");
			FormDAO fdaoCustomer = new FormDAO();
			fdaoCustomer = fdaoCustomer.getFormDAO(customerId, fdCustomer);
			if (fdaoCustomer.isLoaded()) {
				isCustomerLoaded = true;

				str += "<input id='" + ff.getName() + "_realshow' name='"
						+ ff.getName() + "_realshow' value='"
						+ fdaoCustomer.getFieldValue("customer")
						+ "' size=15 readonly>";
				str += "<input id='" + ff.getName() + "' name='" + ff.getName()
						+ "' value='" + customerId + "' style='display:none'>";
			}
		}
		if (!isCustomerLoaded) {
			str += "<input id='" + ff.getName() + "_realshow' name='"
					+ ff.getName() + "_realshow' value='" + v
					+ "' size=15 readonly>";
			str += "<input id='" + ff.getName() + "' name='" + ff.getName()
					+ "' value='' style='display:none'>";
		}

		str += "&nbsp;<input id=\""
				+ ff.getName()
				+ "_btn\" type=button class=btn value=\"选择\" onClick=\"openWinCustomerList(document.getElementById('"
				+ ff.getName() + "'))\">";
		return str;
	}

	public String getDisableCtlScript(FormField ff, String formElementId) {
		FormDb fdCustomer = new FormDb();
		fdCustomer = fdCustomer.getFormDb("sales_customer");
		FormDAO fdaoCustomer = new FormDAO();
		fdaoCustomer = fdaoCustomer.getFormDAO(StrUtil.toLong(ff.getValue()), fdCustomer);
		String str = "";
		if (fdaoCustomer.isLoaded()) {
			str = "DisableCtl('" + ff.getName() + "', '" + ff.getType() + "','"
					+ fdaoCustomer.getFieldValue("customer") + "','"
					+ ff.getValue() + "');\n";
		}
		str += "if (o('" + ff.getName() + "_btn')) o('" + ff.getName()
				+ "_btn').outerHTML='';";
		str += "o('" + ff.getName() + "_realshow').style.display='none';\n";
		return str;
	}

	/**
	 * 当report时，取得用来替换控件的脚本
	 * 
	 * @param ff
	 *            FormField
	 * @return String
	 */
	public String getReplaceCtlWithValueScript(FormField ff) {
		String v = "";
		if (ff.getValue() != null && !ff.getValue().equals("")) {
			// LogUtil.getLog(getClass()).info("StrUtil.toInt(v)=" +
			// StrUtil.toInt(v));
			FormDAO fdao = getFormDAOOfCustomer(StrUtil.toInt(ff.getValue()));
			v = fdao.getFieldValue("customer");
		}
		return "ReplaceCtlWithValue('" + ff.getName() + "', '" + ff.getType()
				+ "','" + v + "');\n";
	}

	/**
	 * 获取用来保存宏控件原始值的表单中的HTML元素中保存的值，生成用以给控件赋值的脚本
	 * 
	 * @return String
	 */
	public String getSetCtlValueScript(HttpServletRequest request,
			IFormDAO IFormDao, FormField ff, String formElementId) {
		int customerId = ParamUtil.getInt(request, "customerId", -1);
		if (customerId != -1) {
			FormDb fd = new FormDb();
			fd = fd.getFormDb("sales_customer");
			FormDAO fdao = new FormDAO();
			fdao = fdao.getFormDAO(customerId, fd);
			if (fdao.isLoaded()) {
				String str = "setCtlValue('" + ff.getName() + "', '"
						+ ff.getType() + "', '" + customerId + "');\n";
				return str;
			} else
				return super.getSetCtlValueScript(request, IFormDao, ff,
						formElementId);
		} else
			return super.getSetCtlValueScript(request, IFormDao, ff,
					formElementId);
	}

	public String getControlType() {
		return "customerSelect";//客户下拉列表
	}

	public String getControlOptions(String userName, FormField ff) {
		return "";
		/*com.redmoon.oa.pvg.Privilege priv = new com.redmoon.oa.pvg.Privilege();
		ActionContext ctx = ActionContext.getContext();
		HttpServletRequest request = (HttpServletRequest)ctx.get(ServletActionContext.HTTP_REQUEST);
		HttpSession session = request.getSession();
		UserDb userDb = new UserDb(userName);
		session.setAttribute(Constant.OA_NAME,userName);
		session.setAttribute(Constant.OA_UNITCODE, userDb
				.getUnitCode());
		if (!priv.isUserPrivValid(request, "sales.user")
				&& !priv.isUserPrivValid(request, "sales")
				&& !priv.isUserPrivValid(request, "sales.manager")) {
			return new JSONArray().toString();
		}
		StringBuilder sqlSb = new StringBuilder();
		sqlSb.append("select id from form_table_").append("sales_customer")
				.append(" where 1 = 1 ");
		sqlSb.append(" and unit_code = ").append("'").append(
				priv.getUserUnitCode(request)).append("' ");
		if(!priv.isUserPrivValid(request, "admin")
				&& !priv.isUserPrivValid(request, "sales")
				&& !priv.isUserPrivValid(request, "sales.manager") && priv.isUserPrivValid(request, "sales.user")){
			sqlSb.append(" and sales_person = ").append(
					StrUtil.sqlstr(userName));
		}else if(priv.isUserPrivValid(request, "sales.manager")
				&& !priv.isUserPrivValid(request, "admin")
				&& !priv.isUserPrivValid(request, "sales")){
			// 根据部门管理权限，查看所属部门的客户
			DeptUserDb dud = new DeptUserDb(priv.getUser(request));
			String dept = dud.getDeptCode();
			Vector vec = dud.getAllUsersOfUnit(dept);
			Iterator it = vec.iterator();
			String salesPerson = "";
			while (it.hasNext()) {
				UserDb ud = (UserDb) it.next();
				if (salesPerson.equals("")) {
					salesPerson = StrUtil.sqlstr(ud.getName());
				} else {
					salesPerson += ","
							+ StrUtil.sqlstr(ud.getName());
				}
			}
			if (!salesPerson.equals("")) {
				sqlSb.append(" and sales_person in ( ").append(
						salesPerson).append(")");
			}
		}
		FormDAO fdao = new FormDAO();
		JSONArray options = new JSONArray();
		try {
			Vector vector = fdao.list("sales_customer",sqlSb.toString());
			if(vector != null && vector.size()>0){
				Iterator ir = null;
				ir = vector.iterator();
				while(ir.hasNext()){
					fdao = (FormDAO)ir.next();
					JSONObject customer = new JSONObject();
					customer.put("value",fdao.getId());
					customer.put("name",fdao.getFieldValue("customer"));//客户名称
					options.put(customer);
				}
			}
		} catch (ErrMsgException e) {
			// TODO Auto-generated catch block
			LogUtil.getLog(CustomerListWinCtl.class).error(e.getMessage());
		} catch (JSONException e) {
			// TODO Auto-generated catch block
			LogUtil.getLog(CustomerListWinCtl.class).error(e.getMessage());
		}
		return options.toString();*/
	}

	public String getControlValue(String userName, FormField ff) {
		if (!StrUtil.getNullStr(ff.getValue()).equals("")) {
			return ff.getValue();
		}
		return "";
	}

	public String getControlText(String userName, FormField ff) {
		String v = "";
		if (!StrUtil.getNullStr(ff.getValue()).equals("")) {
			FormDAO fdao = getFormDAOOfCustomer(StrUtil.toInt(ff.getValue()));
			v = fdao.getFieldValue("customer");
		}
		return v;
	}

	public String convertToHTMLCtlForQuery(HttpServletRequest request,
			FormField ff) {
		return convertToHTMLCtl(request, ff);
	}
	
	/**
	 * 根据名称取值，用于导入Excel数据
	 * 
	 * @return
	 */
	public String getValueByName(FormField ff, String name) {
		UserDb user = new UserDb();
		user = user.getUserDbByRealName(name);
		return user.getName();
	}
}
