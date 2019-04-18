<%@ page contentType="text/html; charset=utf-8" %>
<%@ page import="cn.js.fan.util.*"%>
<%@ page import="java.util.*"%>
<%@ page import="cn.js.fan.web.*"%>
<%@ page import="com.redmoon.oa.visual.*"%>
<%@ page import="com.redmoon.oa.flow.*"%>
<%@ page import="com.redmoon.oa.ui.*"%>
<%@ page import="com.redmoon.oa.visual.FormDAO" %>
<%@ page import="org.json.JSONObject" %>
<jsp:useBean id="privilege" scope="page" class="com.redmoon.oa.pvg.Privilege"/>
<%
/*
- 功能描述：嵌套表格2中编辑行
- 访问规则：从nest_sheet_view.jsp中访问
- 过程描述：
- 注意事项：
- 创建者：fgf 
- 创建时间：2013-5-29
==================
- 修改者：
- 修改时间：
- 修改原因：
- 修改点：
*/

String priv="read";
if (!privilege.isUserPrivValid(request,priv)) {
	out.print(SkinUtil.makeErrMsg(request, SkinUtil.LoadString(request, "pvg_invalid")));
	return;
}

String myname = privilege.getUser( request );
String op = ParamUtil.get(request, "op");

String formCode = ParamUtil.get(request, "formCode"); // 主模块编码
if (formCode.equals("")) {
	out.print(SkinUtil.makeErrMsg(request, "编码不能为空！"));
	return;
}

String formCodeRelated = ParamUtil.get(request, "formCodeRelated"); // 从模块编码
String menuItem = ParamUtil.get(request, "menuItem");

com.redmoon.oa.Config cfg = new com.redmoon.oa.Config();
boolean isNestSheetCheckPrivilege = cfg.getBooleanProperty("isNestSheetCheckPrivilege");

ModulePrivDb mpd = new ModulePrivDb(formCodeRelated);
if (isNestSheetCheckPrivilege && !mpd.canUserManage(privilege.getUser(request))) {
	%>
	<link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/css.css" />	
	<%
	out.print(cn.js.fan.web.SkinUtil.makeErrMsg(request, cn.js.fan.web.SkinUtil.LoadString(request, "pvg_invalid")));
	return;
}

int id = ParamUtil.getInt(request, "id");
// 置嵌套表需要用到的cwsId
request.setAttribute("cwsId", "" + id);
// 置页面类型
request.setAttribute("pageType", "edit");

// 这里是为了使嵌套表格2表单中又存在嵌套表格2宏控件时，在getNestSheet方法中，传递给当前编辑的表单中的嵌套表格2宏控件
// 同时也用于查询选择宏控件
request.setAttribute("formCode", formCodeRelated);

long actionId = ParamUtil.getLong(request, "actionId", -1);
// 用于com.redmoon.oa.visual.Render
request.setAttribute("pageKind", "nest_sheet_relate");
request.setAttribute("actionId", String.valueOf(actionId));

int parentId = ParamUtil.getInt(request, "parentId", -1); // 父模块的ID，仅用于导航，如果导航不显示，则不用传递该参数，用例：module_show_realte.jsp编辑按钮

FormMgr fm = new FormMgr();
FormDb fd = fm.getFormDb(formCodeRelated);

com.redmoon.oa.visual.FormDAOMgr fdm = new com.redmoon.oa.visual.FormDAOMgr(fd);
com.redmoon.oa.visual.FormDAO fdao = fdm.getFormDAO(id);

int isShowNav = ParamUtil.getInt(request, "isShowNav", 1);

String moduleCode = ParamUtil.get(request, "moduleCode");
// System.out.println(getClass() + " moduleCode=" + moduleCode);
if (moduleCode.equals(""))
	moduleCode = formCodeRelated;
ModuleSetupDb msd = new ModuleSetupDb();
msd = msd.getModuleSetupDbOrInit(moduleCode);

// 用于区分嵌套表是在流程还是智能模块
boolean isVisual = false;
if (op.equals("saveformvalue")) {
	JSONObject json = new JSONObject();
	boolean re = false;
	try {
		re = fdm.update(application, request, msd);
	}
	catch (ErrMsgException e) {
		json.put("ret","0");
		json.put("msg", e.getMessage());
		out.print(json);
		return;
	}
	if (re) {
		String tds = "";
		String token = "#@#";
		if (fdao.getCwsId().equals("" + com.redmoon.oa.visual.FormDAO.TEMP_CWS_ID) || fdao.getCwsId().equals("" + FormDAO.NAME_TEMP_CWS_IDS)) {
			String listField = StrUtil.getNullStr(msd.getString("list_field"));
			String[] fields = StrUtil.split(listField, ",");
			int len = 0;
			if (fields!=null)
				len = fields.length;
			fdao = fdm.getFormDAO(id);

			for (int i=0; i<len; i++) {
				String fieldName = fields[i];
				String v = fdao.getFieldHtml(request, fieldName); // fdao.getFieldValue(fieldName);
				if (i==0)
					tds = v;
				else
					tds += token + v;
			}
			isVisual = true;
		}
		else {
		    isVisual = false;
		}
			json.put("ret", "1");
			json.put("msg", "操作成功！");
			json.put("isVisual",isVisual);
			json.put("token",token);
			json.put("tds",tds);
	}
	else{
		json.put("ret", "0");
		json.put("msg", "操作失败！");
	}
	out.print(json);
	return;
}
else if (op.equals("delAttach")) {
	int attachId = ParamUtil.getInt(request, "attachId");
	com.redmoon.oa.visual.Attachment att = new com.redmoon.oa.visual.Attachment(attachId);
	att.del();
}
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>智能设计-编辑内容</title>
<meta name="renderer" content="ie-stand" />
<link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/css.css" />
<script src="../inc/common.js"></script>
<script src="../js/jquery-1.9.1.min.js"></script>
<script src="../js/jquery-migrate-1.2.1.min.js"></script>
<script src="../inc/map.js"></script>
<script src="../js/jquery.raty.min.js"></script>
<script src="../inc/livevalidation_standalone.js"></script>
<script src="../inc/upload.js"></script>
<script src="<%=request.getContextPath()%>/inc/flow_dispose_js.jsp"></script>
<script src="<%=request.getContextPath()%>/inc/flow_js.jsp"></script>
<script src="<%=request.getContextPath()%>/inc/ajax_getpage.jsp"></script>
<script src="<%=request.getContextPath() %>/js/jquery-alerts/jquery.alerts.js" type="text/javascript"></script>
<script src="<%=request.getContextPath() %>/js/jquery-alerts/cws.alerts.js" type="text/javascript"></script>
<link href="<%=request.getContextPath() %>/js/jquery-alerts/jquery.alerts.css" rel="stylesheet" type="text/css" media="screen" />
<link rel="stylesheet" type="text/css" href="../js/datepicker/jquery.datetimepicker.css"/>
<script src="../js/datepicker/jquery.datetimepicker.js"></script>
<link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/flexbox/flexbox.css" />
<script type="text/javascript" src="<%=request.getContextPath()%>/js/jquery.flexbox.js"></script>
<script src="<%=request.getContextPath()%>/flow/form_js/form_js_<%=formCodeRelated%>.jsp"></script>

<link href="../js/select2/select2.css" rel="stylesheet" />
<script src="../js/select2/select2.js"></script>
<script src="../js/select2/i18n/zh-CN.js"></script>

<script src="../js/jquery.form.js"></script>
<link href="../js/jquery-showLoading/showLoading.css" rel="stylesheet" media="screen" />
<script type="text/javascript" src="../js/jquery-showLoading/jquery.showLoading.js"></script>
<script src="../js/jquery-alerts/jquery.alerts.js" type="text/javascript"></script>
<script src="../js/jquery-alerts/cws.alerts.js" type="text/javascript"></script>
<link href="../js/jquery-alerts/jquery.alerts.css" rel="stylesheet"	type="text/css" media="screen" />

<script>
$(function() {
	SetNewDate();
});

function setradio(myitem,v) {
     var radioboxs = document.all.item(myitem);
     if (radioboxs!=null)
     {
       for (i=0; i<radioboxs.length; i++)
          {
            if (radioboxs[i].type=="radio")
              {
                 if (radioboxs[i].value==v)
				 	radioboxs[i].checked = true;
              }
          }
     }
}

function SubmitResult() {
	// 检查是否已选择意见
	if (getradio("resultValue")==null || getradio("resultValue")=="") {
		alert("您必须选择一项意见!");
		return false;
	}
	visualForm.op.value='finish';
	visualForm.submit();
}

// 控件完成上传后，调用Operate()
function Operate() {
	// alert(redmoonoffice.ReturnMessage);
}
</script>
</head>
<body>
<form action="nest_sheet_edit_relate.jsp?op=saveformvalue&parentId=<%=parentId%>&id=<%=id%>&moduleCode=<%=moduleCode%>&formCodeRelated=<%=formCodeRelated%>&formCode=<%=StrUtil.UrlEncode(formCode)%>&isShowNav=<%=isShowNav%>&actionId=<%=actionId %>" method="post" enctype="multipart/form-data" name="visualForm" id="visualForm">
<table width="98%" border="0" align="center" cellpadding="0" cellspacing="0">
    <tr>
      <td align="left"><table width="100%">
        <tr>
          <td><%
			com.redmoon.oa.visual.Render rd = new com.redmoon.oa.visual.Render(request, id, fd);
			out.print(rd.rend(msd));
		  %></td>
        </tr>
      </table></td>
    </tr>
	<%if (fd.isHasAttachment()) {%>	
    <tr>
      <td align="left"><script>initUpload()</script>
	  </td>
    </tr>
    <tr>
      <td align="left">
      <%
		Iterator ir = fdao.getAttachments().iterator();
		while (ir.hasNext()) {
			com.redmoon.oa.visual.Attachment am = (com.redmoon.oa.visual.Attachment) ir.next(); %>
          <table width="82%"  border="0" cellpadding="0" cellspacing="0">
            <tr>
              <td width="5%" height="31" align="right"><img src="<%=Global.getRootPath()%>/images/attach.gif" /></td>
              <td>&nbsp; <a target="_blank" href="<%=Global.getRootPath()%>/visual_getfile.jsp?attachId=<%=am.getId()%>"><%=am.getName()%></a>&nbsp;&nbsp;&nbsp;&nbsp;[<a href="javascript:;" onclick="jConfirm('您确定要删除吗？','提示',function(r){window.location.href='?op=delAttach&parentId=<%=parentId%>&id=<%=id%>&formCode=<%=StrUtil.UrlEncode(formCode)%>&formCodeRelated=<%=formCodeRelated%>&attachId=<%=am.getId()%>'}) ">删除</a>]<br />              </td>
            </tr>
          </table>
        <%}%>
        </td>
    </tr>
	<%}%>
    <tr>
      <td height="30" align="center"><input name="id" value="<%=id%>" type="hidden" />
      	<input type="submit" class="btn" name="Submit" value="确定" />
		</td>
    </tr>
</table>
</form>
</body>
<script>
    $(function() {
        var options = {
            //target:        '#output2',   // target element(s) to be updated with server response
            beforeSubmit:  preSubmit,  // pre-submit callback
            success:       showResponse  // post-submit callback

            // other available options:
            //url:       url         // override for form's 'action' attribute
            //type:      type        // 'get' or 'post', override for form's 'method' attribute
            //dataType:  null        // 'xml', 'script', or 'json' (expected server response type)
            //clearForm: true        // clear all form fields after successful submit
            //resetForm: true        // reset the form after successful submit

            // $.ajax options can be used here too, for example:
            //timeout:   3000
        };

        // bind to the form's submit event
        var lastSubmitTime = new Date().getTime();
        $('#visualForm').submit(function() {
            // 通过判断时间，禁多次重复提交
            var curSubmitTime = new Date().getTime();
            // 在0.5秒内的点击视为连续提交两次，实际当出现重复提交时，测试时间差为0
            if (curSubmitTime - lastSubmitTime < 500) {
                lastSubmitTime = curSubmitTime;
                $('#visualForm').hideLoading();
                return false;
            }
            else {
                lastSubmitTime = curSubmitTime;
            }

            $(this).ajaxSubmit(options);
            return false;
        });
    });

    function preSubmit() {
        $('#visualForm').showLoading();
    }

    function showResponse(responseText, statusText, xhr, $form) {
        $('#visualForm').hideLoading();
        var data = $.parseJSON($.trim(responseText));
        if(data.ret === "1"){
            if (data.isVisual){
                doVisual(data.tds,data.token);
            } else {
                doFlow();
            }
        }
        jAlert(data.msg, "提示");
    }

    function doVisual(tds,token){
		// 如果有父窗口，则自动刷新父窗口
        if (window.opener!=null) {
            window.opener.updateRow("<%=formCodeRelated%>", <%=fdao.getId()%>, tds, token);
            window.close();
        }
    }
    function doFlow(){
        // 如果有父窗口，则自动刷新父窗口
        if (window.opener!=null) {
            window.opener.refreshNestSheetCtl<%=moduleCode%>();
            window.close();
        }
    }
</script>
</html>
