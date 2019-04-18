<%@ page contentType="text/html;charset=utf-8"%>
<%@ page import = "java.net.URLEncoder"%>
<%@ page import = "cn.js.fan.util.*"%>
<%@ page import = "java.util.*"%>
<%@ page import = "org.json.*"%>
<%@ page import = "com.cloudwebsoft.framework.db.*"%>
<%@ page import = "com.redmoon.oa.flow.*"%>
<%@ page import = "com.redmoon.oa.visual.*"%>
<%@ page import = "com.redmoon.oa.ui.*"%>
<%@ page import = "com.redmoon.oa.kernel.*"%>
<jsp:useBean id="privilege" scope="page" class="com.redmoon.oa.pvg.Privilege"/>
<%
String action = ParamUtil.get(request, "action");
String op = ParamUtil.get(request, "op");
String formCode = ParamUtil.get(request, "formCode");

if (action.equals("add")) {
	String name = ParamUtil.get(request, "name");
	String code = RandomSecquenceCreator.getId(20);
	String list_field = "", query_field="";
	ModuleSetupDb vsd = new ModuleSetupDb();
	boolean re = vsd.create(new JdbcTemplate(), new Object[]{code, list_field, query_field, name, new Integer(ModuleSetupDb.KIND_SUB), formCode,"","","", "", "", "", ModuleSetupDb.VIEW_DEFAULT, "", "", "", "", "", "", "", ""});
	JSONObject json = new JSONObject();
	if (re) {
		json.put("ret", "1");
		json.put("msg", "操作成功");
		json.put("code", code);
		out.print(json);
	}
	else {
		json.put("ret", "0");
		json.put("msg", "操作失败");
		json.put("code", code);
		out.print(json);
	}
	return;
}
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>表单模块</title>
<link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/css.css" />
<%@ include file="../inc/nocache.jsp"%>
<script src="../inc/common.js"></script>
<script src="../js/jquery.js"></script>
<script src="../js/jquery-alerts/jquery.alerts.js" type="text/javascript"></script>
<script src="../js/jquery-alerts/cws.alerts.js" type="text/javascript"></script>
<link href="../js/jquery-alerts/jquery.alerts.css" rel="stylesheet"	type="text/css" media="screen" />
<script src="../js/jquery-ui/jquery-ui.js"></script>
<script src="../js/jquery.bgiframe.js"></script>
<link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/jquery-ui/jquery-ui.css" />
<style>
	.loading{
	display: none;
	position: fixed;
	z-index:1801;
	top: 45%;
	left: 45%;
	width: 100%;
	margin: auto;
	height: 100%;
	}
	.SD_overlayBG2 {
	background: #FFFFFF;
	filter: alpha(opacity = 20);
	-moz-opacity: 0.20;
	opacity: 0.20;
	z-index: 1500;
	}
	.treeBackground {
	display: none;
	position: absolute;
	top: -2%;
	left: 0%;
	width: 100%;
	margin: auto;
	height: 200%;
	background-color: #EEEEEE;
	z-index: 1800;
	-moz-opacity: 0.8;
	opacity: .80;
	filter: alpha(opacity = 80);
	}
</style>
</head>
<body>
<div id="treeBackground" class="treeBackground"></div>
<div id='loading' class='loading'><img src='../images/loading.gif' /></div>
<%		
if (!privilege.isUserPrivValid(request, "admin.flow")) {
	out.print(cn.js.fan.web.SkinUtil.makeErrMsg(request, cn.js.fan.web.SkinUtil.LoadString(request, "pvg_invalid")));
	return;
}

FormDb fd = new FormDb();
fd = fd.getFormDb(formCode);

if (action.equals("del")) {
	String code = ParamUtil.get(request, "code");
	ModuleSetupDb vsd = new ModuleSetupDb();
	vsd = vsd.getModuleSetupDbOrInit(code);	
	%>
	<script>
		$(".treeBackground").addClass("SD_overlayBG2");
		$(".treeBackground").css({"display":"block"});
		$(".loading").css({"display":"block"});
	</script>
	<%
	boolean re = vsd.del();
	%>
	<script>
		$(".loading").css({"display":"none"});
		$(".treeBackground").css({"display":"none"});
		$(".treeBackground").removeClass("SD_overlayBG2");
	</script>
	<%
	if (re) {
		out.print(StrUtil.jAlert_Redirect("删除成功！","提示", "module_setup_list.jsp?op=" + op + "&formCode=" + StrUtil.UrlEncode(formCode)));
	}
	else {
		out.print(StrUtil.jAlert_Back("删除失败！","提示"));
	}

	return;
}
else if (action.equals("importModule")) {
	try {%>
	<script>
		$(".treeBackground").addClass("SD_overlayBG2");
		$(".treeBackground").css({"display":"block"});
		$(".loading").css({"display":"block"});
	</script>
	<%
		ModuleUtil.importModule(application, request);
		%>
	<script>
		$(".loading").css({"display":"none"});
		$(".treeBackground").css({"display":"none"});
		$(".treeBackground").removeClass("SD_overlayBG2");
	</script>
	<%
	}
	catch (ErrMsgException e) {
		out.print(StrUtil.jAlert_Back(e.getMessage(),"提示"));
	}
	out.print(StrUtil.jAlert_Redirect("操作成功！","提示", "module_setup_list.jsp?op=" + op + "&formCode=" + StrUtil.UrlEncode(formCode)));
	return;
}

String name = ParamUtil.get(request, "name");

ModuleSetupDb vsd = new ModuleSetupDb();
vsd = vsd.getModuleSetupDbOrInit(formCode);	
String searchName = fd.getName();
if(searchName == null){
	searchName = "";
}
%>
<table cellspacing="0" cellpadding="0" width="100%">
  <tbody>
    <tr>
      <td class="tdStyle_1">模块&nbsp;-&nbsp;<%=searchName%></td>
    </tr>
  </tbody>
</table>
<table width="98%" class="percent98"><tr>
  <td align="center">
<form id="searchForm" name="searchForm" method="get">
名称
<input type="hidden" name="op" value="search" />
<input name="name" value="<%=name%>" />
<input name="formCode" value="<%=formCode%>" type="hidden"/>
<input type="submit" class="btn" value="搜索" />
&nbsp;
<input class="btn" value="添加副模块" type="button" onclick="addModule()"  />
<!-- <input class="btn" value="导入" type="button" onclick="importModule()" /> --> 
</form>
</td>
</tr></table>
<%
String sql = "select code from " + vsd.getTable().getName() + " where form_code=" + StrUtil.sqlstr(formCode);
if (op.equals("search")) {
	if (!"".equals(name)) {
		sql += " and name like " + StrUtil.sqlstr("%" + name + "%");
	}
}

sql += " order by kind asc, name asc";
%>
<form action="module_setup_list.jsp" method=post>
  <table id="mainTable" class="tabStyle_1 percent98" width="93%" align="center" cellpadding="3" cellspacing="0">
	  <thead>
	  <tr>
		  <td class="tabStyle_1_title" width="16%" align="center">编码</td>
		  <td class="tabStyle_1_title" width="22%" height="25" align="center">名称</td>
		  <td class="tabStyle_1_title" width="32%" align="center">描述</td>
		  <td class="tabStyle_1_title" width="8%" align="center">类型</td>
		  <td class="tabStyle_1_title" width="8%" align="center">状态</td>
		  <td class="tabStyle_1_title" width="19%" align="center">操作</td>
	  </tr>
	  </thead>
    <%
	Iterator ir = vsd.list(sql).iterator();
	Directory dir = new Directory();
	while (ir.hasNext()) {
		vsd = (ModuleSetupDb) ir.next();
	%>
	  <tr class="highlight">
		  <td height="24"><%=vsd.getString("code")%>
		  </td>
		  <td height="24"><%=vsd.getString("name")%>
		  </td>
		  <td align="left"><%=StrUtil.getNullStr(vsd.getString("description"))%>
		  </td>
		  <td align="center">
			  <%=vsd.getInt("kind") == ModuleSetupDb.KIND_MAIN ? "主模块" : "副模块"%>
		  </td>
		  <td align="center"><%=vsd.getInt("is_use") == 1 ? "启用" : "停用"%>
		  </td>
		  <td align="center">
			  <a href="javascript:;"
				 onclick="addTab('<%=vsd.getString("name")%>', '<%=request.getContextPath()%>/visual/module_field_list.jsp?formCode=<%=formCode%>&code=<%=vsd.getString("code")%>')">维护</a>
			  <%if (vsd.getInt("kind") == 1) {%>
			  &nbsp;&nbsp;<a href="javascript:;"
							 onclick="jConfirm('您确定要删除<%=vsd.getString("name")%>吗？','提示',function(r){ if(!r){return;}else{window.location.href='module_setup_list.jsp?action=del&formCode=<%=StrUtil.UrlEncode(formCode)%>&code=<%=vsd.getString("code")%>'}}) "
							 style="cursor:pointer">删除</a>
			  <%}%>
			  <%
				  String moduleUrlList = request.getContextPath() + "/visual/module_list.jsp?code=" + vsd.getString("code") + "&formCode=" + StrUtil.UrlEncode(vsd.getString("form_code"));
				  License license = License.getInstance();
				  if (license.isPlatformSrc() && vsd.getInt("is_use") == 1) {
			  %>
			  &nbsp;&nbsp;<a href="javascript:;"
							 onclick="addTab('<%=StrUtil.getNullStr(vsd.getString("name"))%>', '<%=moduleUrlList%>');">打开</a>
			  <%} %>
			  <!-- &nbsp;&nbsp;<a href="<%=request.getContextPath()%>/visual/module_export.jsp?code=<%=vsd.getString("code")%>&formCode=<%=formCode%>" target="_blank">导出</a>-->
		  </td>
	  </tr>
	  <%}%>
  </table>
</form>
<div id="dlg" style="display:none">
<div>名称&nbsp;<input id="name" name="name" /></div>
</div>
<div id="dlgImport" style="display:none">
<div style="margin-bottom:10px">请选择导入文件</div>
<form id="formImport" action="module_setup_list.jsp?action=importModule&formCode=<%=formCode%>" method=post enctype="multipart/form-data">
<input type="file" name="file" /> 
<input type="hidden" name="formCode" value="<%=formCode%>" />
</form>
</div>

<script>
$(document).ready( function() {
	$("#mainTable td").mouseout( function() {
		if ($(this).parent().parent().get(0).tagName!="THEAD")
			$(this).parent().find("td").each(function(i){ $(this).removeClass("tdOver"); });
	});  
	
	$("#mainTable td").mouseover( function() {
		if ($(this).parent().parent().get(0).tagName!="THEAD")
			$(this).parent().find("td").each(function(i){ $(this).addClass("tdOver"); });  
	});  
});

function addModule() {
	$("#dlg").dialog({
		title: "添加副模块",
		modal: true,
		// bgiframe:true,
		buttons: {
			"取消": function() {
				$(this).dialog("close");
			},
			"确定": function() {
				if (o("name").value=="") {
					jAlert("名称不能为空！","提示");
					return;
				}
				$.ajax({
					type: "post",
					url: "module_setup_list.jsp",
					data : {
						action: "add",
						formCode: "<%=formCode%>",
						name: o('name').value
					},
					dataType: "json",
					beforeSend: function(XMLHttpRequest){
						//ShowLoading();
					},
					success: function(data, status){
						var code = data.code;
						window.location.reload();
						addTab(o('name').value, "<%=request.getContextPath()%>/visual/module_field_list.jsp?formCode=<%=formCode%>&code=" + code);
					},
					complete: function(XMLHttpRequest, status){
						// HideLoading();
					},
					error: function(XMLHttpRequest, textStatus){
						// 请求出错处理
						jAlert(XMLHttpRequest.responseText,"提示");
					}
				});	

				$(this).dialog("close");						
			}
		},
		closeOnEscape: true,
		draggable: true,
		resizable:true,
		width:300					
		});
}

function importModule() {
	$("#dlgImport").dialog({
		title: "导入模块",
		modal: true,
		// bgiframe:true,
		buttons: {
			"取消": function() {
				$(this).dialog("close");
			},
			"确定": function() {
            	$('#formImport').submit();
				$(this).dialog("close");						
			}
		},
		closeOnEscape: true,
		draggable: true,
		resizable:true,
		width:300					
		});
}
</script>
</body>
</html>