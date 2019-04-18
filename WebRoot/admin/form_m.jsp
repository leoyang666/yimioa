<%@ page contentType="text/html;charset=utf-8"%>
<%@ page import = "java.net.URLEncoder"%>
<%@ page import = "cn.js.fan.util.*"%>
<%@ page import = "java.util.*"%>
<%@ page import = "com.redmoon.oa.flow.*"%>
<%@ page import = "com.redmoon.oa.dept.*"%>
<%@ page import = "com.redmoon.oa.ui.*"%>
<%@ page import = "com.redmoon.oa.kernel.*"%>
<%@ page import = "com.redmoon.oa.visual.*"%>
<jsp:useBean id="privilege" scope="page" class="com.redmoon.oa.pvg.Privilege"/>
<%
String isFlow = ParamUtil.get(request, "isFlow");

String curUnitCode = ParamUtil.get(request, "unitCode");
if (curUnitCode.equals("")) {
	curUnitCode = privilege.getUserUnitCode(request);
}

/*
if (!privilege.canUserAdminUnit(request, curUnitCode)) {
	// 检查用户能否管理该单位
	out.print(cn.js.fan.web.SkinUtil.makeErrMsg(request, cn.js.fan.web.SkinUtil.LoadString(request, "pvg_invalid")));
	return;
}
*/
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>表单管理</title>
<link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/css.css" />
<%@ include file="../inc/nocache.jsp"%>
<script src="../inc/common.js"></script>
<script src="../js/jquery.js"></script>
<script src="../js/jquery-alerts/jquery.alerts.js" type="text/javascript"></script>
<script src="../js/jquery-alerts/cws.alerts.js" type="text/javascript"></script>
<link href="../js/jquery-alerts/jquery.alerts.css" rel="stylesheet"	type="text/css" media="screen" />
<script type="text/javascript" src="../js/flexigrid.js"></script>
<link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/flexigrid/flexigrid.css" />

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
<script language="JavaScript" type="text/JavaScript">
<!--
function presskey(eventobject) {
	if(event.ctrlKey && window.event.keyCode==13)
	{
		<%if (isFlow.equals("")) {%>
			window.location.href="?isFlow=0";
		<%}else{%>
			window.location.href="?";
		<%}%>
	}
}

document.onkeydown = presskey;
//-->
</script>
</head>
<body>
<%		
if (!privilege.isUserPrivValid(request, "admin.flow")) {
	out.print(cn.js.fan.web.SkinUtil.makeErrMsg(request, cn.js.fan.web.SkinUtil.LoadString(request, "pvg_invalid")));
	return;
}

String op = ParamUtil.get(request, "op");
if (op.equals("import")) {
	try {%>
	<script>
		$(".treeBackground").addClass("SD_overlayBG2");
		$(".treeBackground").css({"display":"block"});
		$(".loading").css({"display":"block"});
	</script>
	<%
		ModuleUtil.importSolution(application, request);
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
	out.print(StrUtil.jAlert_Redirect("操作成功！","提示", "form_m.jsp"));
	return;
}

String flowTypeCode = ParamUtil.get(request, "flowTypeCode");
String flowTypeName = "";
if (!flowTypeCode.equals("")) {
	System.out.println(getClass() + " flowTypeCode=" + flowTypeCode);
	Leaf flf = new Leaf();
	flf = flf.getLeaf(flowTypeCode);
	flowTypeName = flf.getName();
	
	LeafPriv lp = new LeafPriv(flowTypeCode);
	if (!(lp.canUserExamine(privilege.getUser(request)))) {
		// out.println(cn.js.fan.web.SkinUtil.makeErrMsg(request, cn.js.fan.web.SkinUtil.LoadString(request, "pvg_invalid")));
		if (flowTypeCode.equals(Leaf.CODE_ROOT) && privilege.isUserPrivValid(request, "admin.unit")) {
		}
		// 如果是单位管理员，且流程或本单位的
		else if (!flowTypeCode.equals(Leaf.CODE_ROOT) && privilege.isUserPrivValid(request, "admin.unit") && flf.getUnitCode().equals(privilege.getUserUnitCode(request))) {
		}
		else {
			out.println(cn.js.fan.web.SkinUtil.makeInfo(request, "请选择流程"));
			return;
		}
	}
}
else {
	if (!privilege.isUserPrivValid(request, "admin") && !privilege.isUserPrivValid(request, "admin.flow")) {
		out.print(cn.js.fan.web.SkinUtil.makeErrMsg(request, cn.js.fan.web.SkinUtil.LoadString(request, "pvg_invalid")));
		return;
	}
}

String name = ParamUtil.get(request, "name");

String action = ParamUtil.get(request, "action");
if (action.equals("del")) {
	FormMgr ftm = new FormMgr();
	boolean re = false;
	try {
		re = ftm.del(request);
		if (re) {
			out.print(StrUtil.jAlert_Redirect("删除成功！","提示", "form_m.jsp?op=" + op + "&name=" + StrUtil.UrlEncode(name) + "&isFlow=" + isFlow + "&flowTypeCode=" + StrUtil.UrlEncode(flowTypeCode)));
		}
		else {
			out.print(StrUtil.jAlert_Back("删除失败！","提示"));
		}
	}
	catch (ErrMsgException e) {
		out.print(StrUtil.jAlert_Back(e.getMessage(),"提示"));
	}
	return;
}
%>
<%@ include file="form_inc_menu_top.jsp"%>
<script>
try {
<%if (!isFlow.equals("0")) {%>
o("menu1").className="current";
<%}else{%>
o("menu3").className="current";
<%}%>
}
catch (e) {}
</script>
<table id="searchTable" width="100%" border="0" cellpadding="0" cellspacing="0">
<tr>
  <td align="center">
<form id="searchForm" name="searchForm" method="get">
&nbsp;单位
<select id="searchUnitCode" name="searchUnitCode">
<option value="">不限</option>
<%
  String searchUnitCode = ParamUtil.get(request, "searchUnitCode");
  if (License.getInstance().isGroup() || License.getInstance().isPlatform()) {
      DeptDb dd = new DeptDb();
      DeptView dv = new DeptView(request, dd);
      StringBuffer sb = new StringBuffer();
      dd = dd.getDeptDb(privilege.getUserUnitCode(request));
      %>
      <%=dv.getUnitAsOptions(sb, dd, dd.getLayer())%>
      <%
  }
%>
</select>
编码或名称
<input type="hidden" name="op" value="search" />
<input type="hidden" name="flowTypeCode" value="<%=flowTypeCode%>" />
<input type="hidden" name="isFlow" value="<%=isFlow%>" />
<input name="name" value="<%=name%>" />
&nbsp;
<input class="tSearch" type=submit value="搜索">

</form>
</td>
</tr></table>
<%
FormDb ftd = new FormDb();
String sql = "";
if (!searchUnitCode.equals("")) {
	curUnitCode = searchUnitCode;
}
if (isFlow.equals("0")) {
	sql = "select code from " + ftd.getTableName() + " where isFlow=0";
}
else {
	if (!flowTypeCode.equals(""))
		sql = "select code from " + ftd.getTableName() + " where flowTypeCode=" + StrUtil.sqlstr(flowTypeCode) + " and isFlow=1";
	else {
		sql = "select code from " + ftd.getTableName() + " where isFlow=1";		
	}
}

if (op.equals("search")) {
	if (!"".equals(searchUnitCode)) {
		sql += " and unit_code=" + StrUtil.sqlstr(searchUnitCode);
	}
	if (!"".equals(name)) {
		sql += " and (name like " + StrUtil.sqlstr("%" + name + "%")
			+ "or code like " + StrUtil.sqlstr("%" + name + "%") + ")";
	}
}
else {
	sql += " and unit_code=" + StrUtil.sqlstr(curUnitCode);
}

sql += " order by code asc";

// out.print(sql + " searchUnitCode=" + searchUnitCode);
%>
  <table id="grid" width="98%" border="0" cellpadding="0" cellspacing="0">
  <thead>
    <tr>
      <th width="150" height="25" align="left" >编码</th>
      <th width="280" height="25" align="left" >名称</th>
      <th width="215" align="left" >表格名称</th>
      <th width="215" align="left" >流程类型</th>
      <th width="140" height="25" align="center" >操作</th>
    </tr>
    </thead>
    <tbody>
    <%		
		Iterator ir = ftd.list(sql).iterator();
		Directory dir = new Directory();
		while (ir.hasNext()) {
			ftd = (FormDb) ir.next();
	%>
    <tr id="<%=ftd.getCode()%>">
      <td width="18%" height="24" abbr="code"><%=ftd.getCode()%></td>
      <td width="32%"><%=ftd.getName()%></td>
      <td width="23%"><%=ftd.getTableNameByForm()%></td>
      <td width="12%"><%
			  Leaf lf = dir.getLeaf(ftd.getFlowTypeCode());
			  if (lf!=null)
			  	out.print(lf.getName(request));
			  %>
      </td>
      <td width="15%" align="center"><%if (!ftd.isSystem()) {%>
          <a href="javascript:;" onclick="addTab('<%=ftd.getName()%>', '<%=request.getContextPath()%>/admin/form_edit.jsp?code=<%=ftd.getCode()%>')">修改</a>
          &nbsp;<a href="javascript:;" onClick="jConfirm('您确定要删除表单<%=ftd.getName()%>吗？','提示',function(r){ if(!r){return;}else{ window.location.href='form_m.jsp?action=del&isFlow=<%=isFlow%>&flowTypeCode=<%=StrUtil.UrlEncode(flowTypeCode)%>&code=<%=StrUtil.UrlEncode(ftd.getCode())%>&unitCode=<%=StrUtil.UrlEncode(curUnitCode)%>'}})" >删除</a>
          <%}%>
		  <%if (com.redmoon.oa.kernel.License.getInstance().isPlatform()) {%>
          &nbsp;<a href="javascript:;" onclick="addTab('<%=ftd.getName()%>视图', '<%=request.getContextPath()%>/admin/form_view_list.jsp?formCode=<%=ftd.getCode()%>')">视图</a>
          &nbsp;<a href="javascript:;" onclick="addTab('<%=ftd.getName()%>模块', '<%=request.getContextPath()%>/visual/module_setup_list.jsp?formCode=<%=ftd.getCode()%>')">模块</a>
		  <%}%>
      </td>
    </tr>
    <%}%>
    </tbody>
  </table>

<div id="dlgImport" style="display:none">
<div style="margin-bottom:10px">请选择导入文件</div>
<form id="formImport" action="form_m.jsp?op=import" method=post enctype="multipart/form-data">
<input type="file" name="file" />
<br/>
<span styl="color:red">
注意：<br />
原有相同编码的表单将会被覆盖<br />
不存在的基础数据将会被自动创建
</span>
</form>
</div>

</body>
<script>
var flex;
$(document).ready( function() {
	flex = $("#grid").flexigrid
		(
			{
			buttons : [
			{name: '添加', bclass: 'add', onpress : action},
			<%
            if (com.redmoon.oa.kernel.License.getInstance().isPlatformSrc()) {
            %>		
			{name: '导入', bclass: 'import1', onpress : action},
			<%}%>
			<%
            if (com.redmoon.oa.kernel.License.getInstance().getType().equals(License.TYPE_SRC)) {
            %>
			{name: '导出', bclass: 'export', onpress : action},
			<%}%>
			{name: '条件', bclass: 'btnseparator', type: 'include', id: 'searchTable'}
			],
			/*
			searchitems : [
				{display: 'ISO', name : 'iso'},
				{display: 'Name', name : 'name', isdefault: true}
				],
			*/
			url: false,
			usepager: false,
			checkbox : true,
			useRp: true,
			
			// title: "通知",
			singleSelect: true,
			resizable: false,
			showTableToggleBtn: true,
			showToggleBtn: false,
			
			onReload: onReload,
			/*
			onRowDblclick: rowDbClick,
			onColSwitch: colSwitch,
			onColResize: colResize,
			onToggleCol: toggleCol,
			*/
			autoHeight: true,
			width: document.documentElement.clientWidth,
			height: document.documentElement.clientHeight - 84
			}
		);
		
	o("searchUnitCode").value = "<%=searchUnitCode%>";
		
});
function action(com, grid) {
	if (com=='添加')	{
		addTab('添加表单', '<%=request.getContextPath()%>/admin/form_add.jsp?isFlow=<%=isFlow%>&flowTypeCode=<%=StrUtil.UrlEncode(flowTypeCodeTop)%>');
	}
	else if (com=='导出') {
		selectedCount = $(".cth input[type='checkbox'][value!='on'][checked='true']", grid.bDiv).length;
		if (selectedCount == 0) {
			jAlert('请选择记录!', '提示');
			// return;
		}

		var codes = "";
		// value!='on' 过滤掉复选框按钮
		$(".cth input[type='checkbox'][value!='on'][checked='true']", grid.bDiv).each(function(i) {
			if (codes == "") {
				codes = $(this).val();
			}
			else {
				codes += "," + $(this).val();
			}
		});		
		window.open('solution_export.jsp?op=export&codes=' + codes);
	}
	else if (com=="导入") {
		importModule();
	}
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

function onReload() {
	window.location.reload();
}
</script>
</html>