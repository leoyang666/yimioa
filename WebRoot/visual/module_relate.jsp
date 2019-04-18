<%@ page contentType="text/html;charset=utf-8"%>
<%@ page import="java.util.*"%>
<%@ page import="cn.js.fan.util.*"%>
<%@ page import="com.redmoon.oa.fileark.*"%>
<%@ page import="cn.js.fan.web.*"%>
<%@ page import="com.cloudwebsoft.framework.db.*"%>
<%@ page import="com.redmoon.oa.pvg.*"%>
<%@ page import="com.redmoon.oa.person.*"%>
<%@ page import="com.redmoon.oa.ui.*"%>
<%@ page import="com.redmoon.oa.flow.*"%>
<%@ page import="com.redmoon.oa.visual.*"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>关联模块</title>
<link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/css.css" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<script src="../inc/common.js"></script>

<link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/flexbox/flexbox.css" />

<script src="<%=request.getContextPath()%>/js/jquery-1.9.1.min.js"></script>
<script src="<%=request.getContextPath()%>/js/jquery-migrate-1.2.1.min.js"></script>
<script type="text/javascript" src="../js/jquery.flexbox.js"></script>

<script src="../js/jquery-alerts/jquery.alerts.js" type="text/javascript"></script>
<script src="../js/jquery-alerts/cws.alerts.js" type="text/javascript"></script>
<link href="../js/jquery-alerts/jquery.alerts.css" rel="stylesheet"	type="text/css" media="screen" />
</head>
<body>
<jsp:useBean id="privilege" scope="page" class="com.redmoon.oa.pvg.Privilege"/>
<%
if (!privilege.isUserPrivValid(request, "admin.flow")) {
	out.print(cn.js.fan.web.SkinUtil.makeErrMsg(request, cn.js.fan.web.SkinUtil.LoadString(request, "pvg_invalid")));
	return;
}
String formCode = ParamUtil.get(request, "formCode");
FormDb fd = new FormDb(formCode);
if (!fd.isLoaded()) {
	out.print(StrUtil.jAlert_Back("该表单不存在！","提示"));
	return;
}

String op = StrUtil.getNullString(request.getParameter("op"));
String code = ParamUtil.get(request, "code");

if (op.equals("add")) {
	double order = ParamUtil.getDouble(request, "order", -1);
	if (order==-1) {
		out.print(StrUtil.jAlert_Back("请填写顺序号！","提示"));
		return;
	}
	String relateCode = ParamUtil.get(request, "relateCode");
	String field = ParamUtil.get(request, "field");
	int type = ParamUtil.getInt(request, "type");
	
	int cwsStatus = ParamUtil.getInt(request, "cwsStatus", com.redmoon.oa.flow.FormDAO.STATUS_NOT);
	
	String conds = ParamUtil.get(request, "conds");
	
	ModuleRelateDb mrd = new ModuleRelateDb();
	mrd = mrd.getModuleRelateDb(formCode, relateCode);
	if (mrd!=null) {
		out.print(StrUtil.jAlert_Back("模块已关联！","提示"));
		return;
	}
	mrd = new ModuleRelateDb();
	boolean re = mrd.create(new JdbcTemplate(), new Object[]{formCode, relateCode, field, new Integer(type), new Double(order), new Integer(cwsStatus), conds});
	if (re) {
		out.print(StrUtil.jAlert_Redirect("操作成功！","提示", "module_relate.jsp?formCode=" + formCode + "&code=" + code));
	}
	else {
		out.print(StrUtil.jAlert_Back("操作失败！","提示"));
	}
	return;
}
else if (op.equals("del")) {
	String relateCode = ParamUtil.get(request, "relateCode");
	ModuleRelateDb mrd = new ModuleRelateDb();
	mrd = mrd.getModuleRelateDb(formCode, relateCode);
	boolean re = mrd.del();
	if (re) {
		out.print(StrUtil.jAlert_Redirect("操作成功！","提示", "module_relate.jsp?formCode=" + formCode + "&code=" + code));
	}
	else {
		out.print(StrUtil.jAlert_Back("操作失败！","提示"));
	}
	return;
}
else if (op.equals("modify")) {
	String relateCode = ParamUtil.get(request, "relateCode");
	String order = ParamUtil.get(request, "order");
	String field = ParamUtil.get(request, "field");
	int type = ParamUtil.getInt(request, "type");
	int cwsStatus = ParamUtil.getInt(request, "cwsStatus", com.redmoon.oa.flow.FormDAO.STATUS_NOT);

	ModuleRelateDb mrd = new ModuleRelateDb();
	mrd = mrd.getModuleRelateDb(formCode, relateCode);
	
	int isOnTab = ParamUtil.getInt(request, "is_on_tab", 0);
	
	String conds = ParamUtil.get(request, "conds");
	
	boolean re = mrd.save(new JdbcTemplate(), new Object[]{field,new Integer(type),new Double(order), new Integer(cwsStatus), isOnTab, conds, formCode, relateCode});

	if (re) {
		out.print(StrUtil.jAlert_Redirect("操作成功！","提示", "module_relate.jsp?formCode=" + formCode + "&code=" + code));
	}
	else {
		out.print(StrUtil.jAlert_Back("操作失败！","提示"));
	}
	return;
}

Iterator irFields = fd.getFields().iterator();
String opts = "";
while (irFields.hasNext()) {
	FormField ff = (FormField)irFields.next();
	opts += "<option value='" + ff.getName() + "'>" + ff.getTitle() + "</option>";
}
%>
<%@ include file="module_setup_inc_menu_top.jsp"%>
<script>
o("menu3").className="current"; 
</script>
<div class="spacerH"></div>
<table cellspacing="0" class="tabStyle_1 percent98" cellpadding="3" width="98%" align="center">
  <tr>
    <td class="tabStyle_1_title" nowrap="nowrap" width="4%">顺序</td>
    <td class="tabStyle_1_title" nowrap="nowrap" width="14%">从模块表单名称</td>
    <td class="tabStyle_1_title" nowrap="nowrap" width="14%">主模块关联字段</td>
    <td class="tabStyle_1_title" nowrap="nowrap" width="17%">关联方式</td>
    <td class="tabStyle_1_title" nowrap="nowrap" width="6%">顺序号</td>
    <td class="tabStyle_1_title" nowrap="nowrap" width="11%">状态</td>
    <td class="tabStyle_1_title" nowrap="nowrap" width="6%">选项卡</td>
    <td class="tabStyle_1_title" nowrap="nowrap" width="11%">条件</td>
    <td width="17%" nowrap="nowrap" class="tabStyle_1_title">操作</td>
  </tr>
<%
ModuleRelateDb mrd = new ModuleRelateDb();
Iterator ir = mrd.getModulesRelated(formCode).iterator();

int i = 0;
int order = 0;
ModuleSetupDb msd = new ModuleSetupDb();
while (ir.hasNext()) {
	mrd = (ModuleRelateDb)ir.next();
	String relateCode = mrd.getString("relate_code");
	msd = msd.getModuleSetupDb(relateCode);
	String moduleCode = "", moduleFormCode="", moduleName = "", conds = "";
	if (msd == null) {
	    msd = new ModuleSetupDb();
		moduleName = "表单 " + relateCode + " 不存在";
	}
	else {
	    moduleCode = msd.getString("code");
		moduleFormCode = msd.getString("form_code");
		moduleName = msd.getString("name");
		order = mrd.getInt("relate_order");
		conds = StrUtil.getNullStr(mrd.getString("conds"));
	}
	%>
  <form action="module_relate.jsp?op=modify" method="post" name="form<%=i%>" id="form<%=i%>">
    <tr class="highlight">
      <td align="center"><%=i+1%></td>
      <td title="表单编码：<%=moduleFormCode%>">
	  	  <a href="javascript:;" onclick="addTab('<%=moduleName%>', '<%=request.getContextPath()%>/visual/module_field_list.jsp?code=<%=StrUtil.UrlEncode(moduleCode)%>&formCode=<%=StrUtil.UrlEncode(moduleFormCode)%>')"><%=moduleName%></a>
          <input name="formCode" value="<%=formCode%>" type="hidden" />
	      <input name="code" value="<%=code%>" type="hidden" />          
          <input name="relateCode" value="<%=relateCode%>" type="hidden" />
      </td>
      <td>
	  <select id="field<%=i %>" name="field">
		<option value="id">id</option>
		<option value="cwsId">cwsId</option>
        <%=opts%>
      </select>
	  <script>
	  o('field<%=i%>').value = "<%=mrd.getString("relate_field")%>";
	  </script>
	  </td>
      <td>
	  <select id="type<%=i %>" name="type">
	  <option value="<%=ModuleRelateDb.TYPE_MULTI%>">记录型(多个记录)</option>
	  <option value="<%=ModuleRelateDb.TYPE_SINGLE%>">表单型(单个记录)</option>
	  </select>
	  <script>
	  o('type<%=i%>').value = "<%=mrd.getInt("relate_type")%>";
	  </script>
	  </td>
      <td><input name="order" size="5" value="<%=mrd.getInt("relate_order")%>" /></td>
      <td>
        <select id="cwsStatus<%=i %>" name="cwsStatus">
        <option value="-100">不限</option>
        <option value='<%=com.redmoon.oa.flow.FormDAO.STATUS_DONE%>' selected>流程已结束</option>
        <option value='<%=com.redmoon.oa.flow.FormDAO.STATUS_NOT%>'>流程未走完</option>
        <option value='<%=com.redmoon.oa.flow.FormDAO.STATUS_REFUSED%>'>流程被拒绝</option>
        <option value='<%=com.redmoon.oa.flow.FormDAO.STATUS_DISCARD%>'>流程被放弃</option>
        </select> 
	  <script>
	  o('cwsStatus<%=i%>').value = "<%=mrd.getInt("cws_status")%>";
	  </script>            
      </td>
      <td align="center">
      <input id="is_on_tab" name="is_on_tab" title="是否显示于选项卡" type="checkbox" value="1" <%=mrd.getInt("is_on_tab")==1?"checked":"1"%> />
      </td>
      <td align="left">
        <img src="../admin/images/combination.png" style="margin-bottom:-5px;"/>
        <a href="javascript:;" onclick="openCondition(o('conds<%=i%>'), o('imgConds<%=i%>'))" title="当满足条件时，显示从模块">配置条件</a>
        <span style="margin:10px">
        <img src="../admin/images/gou.png" style="margin-bottom:-5px;width:20px;height:20px;display:<%="".equals(conds)?"none":""%>" id="imgConds<%=i%>"/>
        </span>
        <textarea id="conds<%=i%>" name="conds" style="display:none"><%=conds%></textarea>         
      </td>
      <td align="center"><input class="btn" type="submit" value="修改" />
        &nbsp;&nbsp;
        <input class="btn" name="button2" type="button" onclick="jConfirm('您确定要删除么？','提示',function(r){if(!r){return;}else{window.location.href='module_relate.jsp?op=del&formCode=<%=formCode%>&relateCode=<%=StrUtil.UrlEncode(relateCode)%>&code=<%=code%>'}}) " value="删除" />      </td>
    </tr>
  </form>
  <%
  	i++;
  }%>
  <form action="module_relate.jsp?op=add" method="post" name="form" id="form">
    <tr class="highlight">
      <td colspan="9" align="center">
        <table width="100%" border="0">
          <tr>
            <td width="15%" align="right">请选择从模块</td>
            <td width="14%">
              <%
				String sql = "select code from visual_module_setup where is_use=1 order by code asc"; // orders asc";
				Vector v = msd.list(sql);
				ir = v.iterator();
				String jsonStr = "";
				while (ir.hasNext()) {
					msd = (ModuleSetupDb)ir.next();
					
					if (jsonStr.equals(""))
						jsonStr = "{\"id\":\"" + msd.getString("code") + "\", \"name\":\"" + msd.getString("name") + "\"}";
					else
						jsonStr += ",{\"id\":\"" + msd.getString("code") + "\", \"name\":\"" + msd.getString("name") + "\"}";

          		}
          	%>
              <div id="relateCodeSel"></div>
              <input id="relateCode" name="relateCode" type="hidden" />
              <script>
		var relateCodeSel = $('#relateCodeSel').flexbox({        
				"results":[<%=jsonStr%>], 
				"total":<%=v.size()%>
			},{
			initialValue:'',
		    watermark: '请选择从模块',
		    paging: false,
			maxVisibleRows: 10,
			onSelect: function() {
				o("relateCode").value = $("input[name=relateCodeSel]").val();
			}
		});
		</script>             
            </td>
            <td width="71%">主模块字段
              <select name="field">
                <option value="id">id</option>
                <option value="cwsId">cwsId</option>
                <%=opts%>
              </select>
关联方式
<select name="type">
  <option value="<%=ModuleRelateDb.TYPE_MULTI%>">记录型(多个记录)</option>
  <option value="<%=ModuleRelateDb.TYPE_SINGLE%>">表单型(单个记录)</option>
</select>
顺序号
<input name="order" size="5" value="<%=order+1%>" />
<input name="formCode" value="<%=formCode%>" type="hidden" />
<input name="code" value="<%=code%>" type="hidden" />
<select id="cwsStatus" name="cwsStatus">
<option value="-100">不限</option>
<option value='<%=com.redmoon.oa.flow.FormDAO.STATUS_DONE%>' selected>流程已结束</option>
<option value='<%=com.redmoon.oa.flow.FormDAO.STATUS_NOT%>'>流程未走完</option>
<option value='<%=com.redmoon.oa.flow.FormDAO.STATUS_REFUSED%>'>流程被拒绝</option>
<option value='<%=com.redmoon.oa.flow.FormDAO.STATUS_DISCARD%>'>流程被放弃</option>
</select>
<input id="is_on_tab2" name="is_on_tab2" title="是否显示于选项卡" type="checkbox" value="1" checked />
选项卡

<img src="../admin/images/combination.png" style="margin-bottom:-5px;"/>
<a href="javascript:;" onclick="openCondition(o('condsAdd'), o('imgCondsAdd'))" title="当满足条件时，显示从模块">配置条件</a>
<span style="margin:10px">
<img src="../admin/images/gou.png" style="margin-bottom:-5px;width:20px;height:20px;display:none" id="imgCondsAdd"/>
</span>
<textarea id="condsAdd" name="conds" style="display:none"></textarea>      

<input class="btn" type="submit" value="添加" />
			</td>
          </tr>
        </table>
        (&nbsp;所选从模块的字段cws_id等于本模块id字段&nbsp;) </td>
    </tr>
  </form>
</table>
</body>
<script>
var curCondsObj, curImgObj;
function openWin(url,width,height) {
	var newwin=window.open(url,"fieldWin","toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,top=50,left=120,width="+width+",height="+height);
	return newwin;
}

function openCondition(condsObj, imgObj){
	curCondsObj = condsObj;
	curImgObj = imgObj
	
    openWin("",1024,568);

	var url = "module_combination_condition.jsp";
	var tempForm = document.createElement("form");
	tempForm.id="tempForm1";  
	tempForm.method="post";
	tempForm.action=url;  
	   
	var hideInput = document.createElement("input");  
	hideInput.type="hidden";
	hideInput.name= "condition";
	hideInput.value = curCondsObj.value;
	tempForm.appendChild(hideInput);   
	    
	hideInput = document.createElement("input");
	hideInput.type="hidden";  
	hideInput.name= "fromValue";
	hideInput.value=  "" ;
	tempForm.appendChild(hideInput);   
			  
	hideInput = document.createElement("input");  
	hideInput.type="hidden";  
	hideInput.name= "toValue";
	hideInput.value=  ""
	tempForm.appendChild(hideInput);   
	    
	hideInput = document.createElement("input");  
	hideInput.type="hidden";  
	hideInput.name= "moduleCode";
	hideInput.value=  "<%=code %>";
	tempForm.appendChild(hideInput);   
	    
	hideInput = document.createElement("input");  
	hideInput.type="hidden";  
	hideInput.name= "operate";
	hideInput.value=  "validate";
	tempForm.appendChild(hideInput);   
	
	document.body.appendChild(tempForm);
	tempForm.target="fieldWin";
	tempForm.submit();
	document.body.removeChild(tempForm);
}

function setCondition(val) {
	curCondsObj.value = val;
	if (val=="") {
		$(curImgObj).hide();
	}
	else {
		$(curImgObj).show();
	}
}
</script>
</html>