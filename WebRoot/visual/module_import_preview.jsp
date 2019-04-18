<%@ page contentType="text/html; charset=utf-8"%>
<%@ page import = "java.util.*"%>
<%@ page import = "java.io.*"%>
<%@ page import = "cn.js.fan.web.*"%>
<%@ page import = "cn.js.fan.db.*"%>
<%@ page import = "cn.js.fan.util.*"%>
<%@ page import = "com.redmoon.oa.address.*"%>
<%@ page import = "com.redmoon.oa.pvg.Privilege"%>
<%@ page import = "com.redmoon.oa.ui.*"%>
<%@ page import = "org.json.*"%>
<%@page import="com.redmoon.oa.flow.FormDb"%>
<%@page import="com.redmoon.oa.visual.FuncUtil"%>
<%@page import="com.redmoon.oa.visual.ModuleSetupDb"%>
<%@page import="com.redmoon.oa.visual.ModuleImportTemplateDb"%>
<%@page import="org.apache.poi.hssf.usermodel.HSSFWorkbook"%>
<%@page import="org.apache.poi.hssf.usermodel.HSSFSheet"%>
<%@page import="org.apache.poi.ss.usermodel.WorkbookFactory"%>
<%@page import="org.apache.poi.hssf.usermodel.HSSFCell"%>
<%@page import="com.redmoon.oa.flow.FormField"%>
<%@page import="org.apache.poi.hssf.usermodel.HSSFRow"%>
<%@page import="com.redmoon.oa.visual.FormDAO"%> 
<%@page import="org.apache.poi.xssf.usermodel.XSSFWorkbook"%>
<%@page import="org.apache.poi.xssf.usermodel.XSSFSheet"%>
<%@page import="org.apache.poi.xssf.usermodel.XSSFCell"%>
<%@page import="org.apache.poi.xssf.usermodel.XSSFRow"%>
<%@page import="com.cloudwebsoft.framework.db.*"%>
<%@page import="com.cloudwebsoft.framework.util.LogUtil"%>
<%@ page import = "com.redmoon.oa.flow.macroctl.*"%>
<%@ page import="org.apache.poi.hssf.usermodel.*" %>
<%@page import="com.redmoon.oa.person.UserDb"%>
<%@page import="com.redmoon.oa.dept.DeptUserDb"%>
<%@page import="com.redmoon.oa.dept.DeptDb"%>
<%@page import="com.redmoon.oa.person.UserCache"%>
<%@ page import="com.redmoon.oa.sys.DebugUtil" %>
<jsp:useBean id="privilege" scope="page" class="com.redmoon.oa.pvg.Privilege"/>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>导入预览</title>
<link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/css.css" />
<script type="text/javascript" src="../js/jquery1.7.2.min.js"></script>
<script src="../js/jquery-alerts/jquery.alerts.js" type="text/javascript"></script>
<script src="../js/jquery-alerts/cws.alerts.js" type="text/javascript"></script>
<link href="../js/jquery-alerts/jquery.alerts.css" rel="stylesheet"	type="text/css" media="screen" />
<%
	MacroCtlMgr mm = new MacroCtlMgr();
	String code = (String) request.getAttribute("code");
	String formCode = (String) request.getAttribute("formCode");
	int templateId = -1;
	Integer templateIdObj = ((Integer) request
			.getAttribute("templateId"));
	if (templateIdObj != null) {
		templateId = templateIdObj.intValue();
	}
	String parentId = (String) request.getAttribute("parentId");
	String menuItem = StrUtil.getNullStr((String) request
			.getAttribute("menuItem"));
	JSONArray rowAry = (JSONArray) request
			.getAttribute("importRecords");
	FormDb fd = new FormDb();
	fd = fd.getFormDb(formCode);

	String userName = privilege.getUser(request);

	if (!fd.isLoaded()) {
		out.print(StrUtil.jAlert_Back("表单不存在！", "提示"));
		return;
	}
%>
<style>
.errCanNotRepeat {
	background-color:#FFACAE;
}

.errCanNotEmpty {
	background-color:yellow;
}

.errCanNotEmptyFiltered {
	background-color:green;
}
</style>
</head>
<body>
<%@ include file="module_inc_menu_top.jsp"%>
<div class="spacerH"></div>
<%
	if ("".equals(menuItem)) {
%>
<script>
o("menu1").className="current";
</script>
<%
	} else {
%>
<script>
o("<%=menuItem%>").className="current";
</script>
<%
	}

	String[] fields = null;
	String[] titles = null;
	int[] canNotEmptys = null;
	JSONArray arr = null;
	// 记录不允许重复的字段组合
	Vector vstr = new Vector();
	StringBuffer canNotRepeatTitles = new StringBuffer();
	if (templateId != -1) {
		ModuleImportTemplateDb mid = new ModuleImportTemplateDb();
		mid = mid.getModuleImportTemplateDb(templateId);
		String rules = mid.getString("rules");
		try {
			arr = new JSONArray(rules);
			if (arr.length() > 0) {
				fields = new String[arr.length()];
				titles = new String[arr.length()];
				canNotEmptys = new int[arr.length()];
				for (int i = 0; i < arr.length(); i++) {
					JSONObject json = (JSONObject) arr.get(i);
					fields[i] = json.getString("name");
					titles[i] = json.getString("title");
					int canNotRepeat = json.getInt("canNotRepeat");
					if (canNotRepeat == 1) {
						vstr.addElement(fields[i]);
						StrUtil.concat(canNotRepeatTitles, "+", titles[i]);
					}
					canNotEmptys[i] = 0;
					if (json.has("canNotEmpty")) {
						canNotEmptys[i] = json.getInt("canNotEmpty");
					}
				}
			}
		} catch (JSONException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	} else {
		ModuleSetupDb msd = new ModuleSetupDb();
		msd = msd.getModuleSetupDbOrInit(formCode);

		String listField = StrUtil.getNullStr(msd.getString("list_field"));
		fields = StrUtil.split(listField, ",");
		titles = new String[fields.length];
		for (int i = 0; i < fields.length; i++) {
			FormField ff = fd.getFormField(fields[i]);
			if (ff == null) {
				continue;
			}
			titles[i] = ff.getTitle();
		}
	}
%>
<form name="form1" action="?op=import&code=<%=code%>&formCode=<%=formCode%>" method="post" enctype="multipart/form-data">
<table width="525" border="0" align="center" cellspacing="0" class="tabStyle_1 percent98">
	<thead>
    <tr>
      <%
      	for (int i = 0; i < titles.length; i++) {
      %>
      	<td class="tabStyle_1_title"><%=titles[i]%></td>
		<%
			}
		%>
    </tr>
    </thead>
      <%
      	Map rowFiltered = new HashMap();
      	boolean hasNest = false;
      	StringBuffer tables = new StringBuffer();
      	Iterator ir = vstr.iterator();
      	while (ir.hasNext()) {
      		String fieldName = (String) ir.next();
      		// 解析出表单编码
      		if (fieldName.startsWith("nest.")) {
      			hasNest = true;
      			int p = fieldName.indexOf(".");
      			int q = fieldName.lastIndexOf(".");
      			String nestFormCode = fieldName.substring(p + 1, q);
      			String nestFieldName = fieldName.substring(q + 1);
      			// 使tables中的表名唯一
      			if (("," + tables.toString() + ",").indexOf("," + FormDb.getTableName(nestFormCode) + ",")==-1) {      			
      				StrUtil.concat(tables, ",", FormDb.getTableName(nestFormCode));
      			}
      		} else {
      			if (("," + tables.toString() + ",").indexOf("," + FormDb.getTableName(formCode) + ",")==-1) {
      				StrUtil.concat(tables, ",", FormDb.getTableName(formCode));
      			}
      		}
      	}
      	
		// 如果主表不存在于tables中，即规则中没有设置主表中的字段，则强制加上主表，因为cws_id条件需用到
		if (hasNest && ("," + tables.toString() + ",").indexOf("," + FormDb.getTableName(formCode) + ",")==-1) {
      		StrUtil.concat(tables, ",", FormDb.getTableName(formCode));			
		}

      	boolean hasErr = false;
      	JdbcTemplate jt = new JdbcTemplate();
      	jt.setAutoClose(false);
      	int len = rowAry.length();
      	String cls = "";
      	// 遍历每行导入的数据
      	for (int row = 0; row < len; row++) {
      		JSONObject jo = (JSONObject) rowAry.get(row);
			// 过滤掉空行
      		if (jo.length()==0)
      			continue;

      		StringBuffer conds = new StringBuffer();
      		ir = vstr.iterator();
      		while (ir.hasNext()) {
      			String fieldName = (String) ir.next();
      			// 解析出表单编码
      			if (fieldName.startsWith("nest.")) {
      				int p = fieldName.indexOf(".");
      				int q = fieldName.lastIndexOf(".");
      				String nestFormCode = fieldName.substring(p + 1, q);
      				String nestFieldName = fieldName.substring(q + 1);
      				StrUtil.concat(conds, " and ", FormDb
      						.getTableName(nestFormCode)
      						+ "."
      						+ nestFieldName
      						+ "="
      						+ StrUtil.sqlstr(jo.getString(fieldName)));
      			} else {
      				StrUtil.concat(conds, " and ", FormDb
      						.getTableName(formCode)
      						+ "."
      						+ fieldName
      						+ "="
      						+ StrUtil.sqlstr(jo.getString(fieldName)));
      			}
      		}
      		
      		if (tables.length() > 0) {
      			// 检查是否有重复
      			ModuleRelateDb mrd = new ModuleRelateDb();
      			String sql = "select id from " + tables + " where " + conds;
      			if (hasNest) {
	      			String[] tabAry = StrUtil.split(tables.toString(), ",");
	      			for (int m = 0; m < tabAry.length; m++) {
	      				if (FormDb.getTableName(formCode).equals(tabAry[m])) {
	      					;
	      				} else {
	      					// 加上所关联的主模块的字段
	      					mrd = mrd.getModuleRelateDb(formCode, tabAry[m]
	      							.substring("form_table_".length()));
	      					sql += " and " + tabAry[m] + ".cws_id="
	      							+ FormDb.getTableName(formCode) + "."
	      							+ mrd.getString("relate_field");
	      				}
	      			}
      			}

      			// 此时还没有导入表中，所以表中无重复记录，但是如果待导入记录中对应主表有多条重复记录，那么在实际插入时主表仍会出现重复记录
				// 所以在实际导入的时候针对主表加入了判重的处理，如果主表中已存在记录，则不再插入
      			ResultIterator ri = jt.executeQuery(sql);
				DebugUtil.i("module_import_preview.jsp", "检查是否重复" + ri.size(), sql);
      			if (ri.size()>0) {
      				cls = "errCanNotRepeat";
      				hasErr = true;
      			}
      			else {
      				cls = "";
				}

      			// System.out.println(getClass() + " " + sql);
      		}
      	%>
	  	<tr class="<%=cls%>">
	  	<%
	  	for (int i = 0; i < fields.length; i++) {
		  	String colName = fields[i];
		  	if ("".equals(colName)) {
		  		out.print("<td>&nbsp;</td>");
		  		continue;
		  	}	  	
	  		String val = "";
	  		// 因为导入的时候，可能最后一行的数据，列可能不全，可能只到最后一个有数据的CELL
	  		if (jo.has(colName)) {
	  			val = StrUtil.getNullStr(jo.getString(colName)).trim();
	  		}
	  		String tdCls = "";
	  		if (templateId!=-1) {
				if (val.equals("")) {
		  			if (canNotEmptys[i]==1) {
	  					// 不允许为空
	  					tdCls = "errCanNotEmpty";
	      				hasErr = true;
		  			}
		  			else if (canNotEmptys[i]==2) {
		  				// 为空则滤除
		  				tdCls = "errCanNotEmptyFiltered";
		  				rowFiltered.put(row, "");
		  			}
	  			}
	  		}
	  	%>
		  <td class="<%=tdCls %>">
		  <%
		  	out.print(val);
		  %>
		  </td>
		  <%
		  	}
		  %>
		</tr>
		<%
		}
		jt.close();

		if (!hasErr) {
			if (rowFiltered.size()>0) {
				JSONArray rows = new JSONArray();
				len = rowAry.length();
				// 滤掉为空则滤除的行
				for (int i=0; i<len; i++) {
					if (!rowFiltered.containsKey(i)) {
						rows.put(rowAry.get(i));
					}
				}
				rowAry = rows;
			}
			session.setAttribute("importRecords", rowAry);
		}
		%>
</table>
<%
if (templateId != -1 && canNotRepeatTitles.length() > 0) {
%>
<table border="0" align="center" cellpadding="0" cellspacing="0"><tr><td height="40">
注意：红色表示&nbsp;“<%=canNotRepeatTitles%>”&nbsp;存在有重复项
，
黄色表示不允许为空
，
绿色表示为空将会被滤掉
</td></tr></table>
<%
}
%>
<div style="text-align:center">
<%
	if (!hasErr) {
%>
<input type="button" value="确定" onclick="window.location.href='doImport.do?code=<%=code%>&formCode=<%=formCode%>&parentId=<%=parentId%>&menuItem=<%=menuItem%>&templateId=<%=templateId%>'" />
&nbsp;&nbsp;
<%
	}
%>
<input type="button" value="返回" onclick="window.location.href='module_import_excel.jsp?code=<%=code%>&formCode=<%=formCode%>&menuItem=<%=menuItem%>&parentId=<%=parentId%>'" />
</div>
</form>
</body>
</html>
