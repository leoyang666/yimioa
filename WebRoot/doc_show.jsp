<%@ page contentType="text/html;charset=utf-8" language="java" errorPage="" %>
<%@ page import = "cn.js.fan.web.*"%>
<%@ page import = "cn.js.fan.util.*"%>
<%@ page import = "cn.js.fan.db.*"%>
<%@ page import = "com.redmoon.oa.fileark.*"%>
<%@ page import = "com.redmoon.oa.person.*"%>
<%@ page import = "com.redmoon.oa.pvg.*"%>
<%@ page import = "com.redmoon.oa.kernel.*"%>
<%@ page import = "cn.js.fan.security.*"%>
<%@ page import = "com.redmoon.oa.ui.*"%>
<%@ page import = "com.redmoon.oa.basic.*"%>
<%@ page import = "java.io.*"%>
<%
	com.redmoon.oa.pvg.Privilege privilege = new com.redmoon.oa.pvg.Privilege();

	int id = 0;
	String dirCode = ParamUtil.get(request, "dir_code");
	boolean isDirArticle = false;
	Leaf lf = new Leaf();

	Document doc = null;
	DocumentMgr docmgr = new DocumentMgr();
	UserMgr um = new UserMgr();

	if (!dirCode.equals("")) {
		lf = lf.getLeaf(dirCode);
		if (lf != null) {
			if (lf.getType() == 1) {
				// id = lf.getDocID();
				doc = docmgr.getDocumentByCode(request, dirCode,
						privilege);
				if (doc == null) {
					out.print(SkinUtil.makeErrMsg(request,
							"该文章不存在，请删除目录并重建！"));
					return;
				}
				id = doc.getID();
				isDirArticle = true;
			}
		}
	}

	if (id == 0) {
		try {
			id = ParamUtil.getInt(request, "id");
			doc = docmgr.getDocument(id);
		} catch (ErrMsgException e) {
			out.print(SkinUtil.makeErrMsg(request, e.getMessage()));
			return;
		}
	}

	if (!doc.isLoaded()) {
		out.print(SkinUtil.makeErrMsg(request, "该文章不存在！"));
		return;
	}
	if (!isDirArticle)
		lf = lf.getLeaf(doc.getDirCode());

	String CPages = ParamUtil.get(request, "CPages");
	int pageNum = 1;
	if (StrUtil.isNumeric(CPages))
		pageNum = Integer.parseInt(CPages);

	String op = ParamUtil.get(request, "op");
	String view = ParamUtil.get(request, "view");
	CommentMgr cm = new CommentMgr();
	
	com.redmoon.oa.Config cfg = new com.redmoon.oa.Config();
	boolean filearkHighlightDirShow = cfg.getBooleanProperty("filearkHighlightDirShow");	
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title><%=Global.AppName%> - <%=doc.getTitle()%></title>
<link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/css.css" />
<style>
.docImg {max-width:500px;_width:500px;}
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

.doc_show_toolbar{
	width:100%;
	height:40px;
	background-color:#daeaf8;
	border-bottom:2px solid #92b4d2;
}
.doc_show_f1{
	color:#9a9a9a;
}
.mybtn {
	background-color: #87c3f1;
	font-weight: bold;
	text-align: center;
	line-height: 35px;
	height: 35px;
	width:120px;
	padding-right: 8px;
	padding-left: 8px;
	-moz-border-radius: 3px;
	-webkit-border-radius: 3px;
	border-radius: 3px;
	behavior: url(skin/common/ie-css3.htc);
	cursor:pointer;
	color:#fff;
	border-top-width: 0px;
	border-right-width: 0px;
	border-bottom-width: 0px;
	border-left-width: 0px;
	border-top-style: none;
	border-right-style: none;
	border-bottom-style: none;
	border-left-style: none;
}

#dir ul {
	margin:0 0 0 17px;
	list-style-type:none;
}
#dir ul li a{
	cursor:pointer;
}
#dir {
	float:left;
	width:249px;
	border:1px solid #99BEEF;
	background:#D2E4FC;
	color:inherit;
	margin: 10px 10px 10px 0px;
	padding:3px;
}
.tab-bar {
	border-bottom: 1px dashed #cccccc;
	height: 40px;
	margin-bottom: 10px;
	padding-left: 10px;
	font-weight: bold;
}
.tab {
	cursor:pointer;
	display:block;
	float:left;
	padding: 3px;
	margin-left:5px;
}
</style>
<script src="inc/common.js"></script>
<script src="js/jquery-1.9.1.min.js"></script>
<script src="js/jquery-migrate-1.2.1.min.js"></script>

<script type="text/javascript" src="js/goToTop/goToTop.js"></script>
<link type="text/css" rel="stylesheet" href="js/goToTop/goToTop.css" />

<link href="js/jquery-showLoading/showLoading.css" rel="stylesheet" media="screen" /> 
<script type="text/javascript" src="js/jquery-showLoading/jquery.showLoading.js"></script>
<script type="text/javascript" src="js/jquery.toaster.js"></script>

<script src="js/jquery-alerts/jquery.alerts.js" type="text/javascript"></script>
<script src="js/jquery-alerts/cws.alerts.js" type="text/javascript"></script>
<link href="js/jquery-alerts/jquery.alerts.css" rel="stylesheet" type="text/css" media="screen" />

<script type="text/javascript" charset="utf-8" src="ueditor/js/ueditor/ueditor.config.js?2023"></script>
<script type="text/javascript" charset="utf-8" src="ueditor/js/ueditor/ueditor.all.js?2023"> </script>
<script type="text/javascript" charset="utf-8" src="ueditor/js/ueditor/lang/zh-cn/zh-cn.js?2023"></script>

<script src="inc/livevalidation_standalone.js"></script>
<script src="netdisk/showDialog/showDialog.js"></script>
<link type="text/css" rel="stylesheet" href="netdisk/showDialog/showDialog.css" />

<link type="text/css" rel="stylesheet" href="ueditor/js/ueditor/third-party/video-js/video-js.css"/>
<script language="javascript" type="text/javascript" src="ueditor/js/ueditor/third-party/video-js/video.js"></script>
<script language="javascript" type="text/javascript" src="ueditor/js/ueditor/third-party/video-js/html5media.min.js"></script>

<script src="<%=request.getContextPath()%>/fileark/doc_show_js.jsp?id=<%=id%>"></script>

<script>
var isLeftMenuShow = true;
function closeLeftMenu() {
	if (isLeftMenuShow) {
		window.parent.setCols("0,*");
		isLeftMenuShow = false;
		btnName.innerHTML = "打开菜单";
	}
	else {
		window.parent.setCols("200,*");
		isLeftMenuShow = true;
		btnName.innerHTML = "关闭菜单";		
	}
}
</script>
</head>
<body>
<div id="treeBackground" class="treeBackground"></div>
<div id='loading' class='loading'><img src='images/loading.gif'/></div>
<% 
	if (op.equals("addcomment")) { 
		try { 
%>
		<script>
			$(".treeBackground").addClass("SD_overlayBG2");
			$(".treeBackground").css({"display":"block"});
			$(".loading").css({"display":"block"});
		</script>
		<%
			cm.insert(request);
		} catch (ErrMsgException e) {
			out.print(StrUtil.jAlert(e.getMessage(), "提示"));
		}
		%>
		<script>
			$(".loading").css({"display":"none"});
			$(".treeBackground").css({"display":"none"});
			$(".treeBackground").removeClass("SD_overlayBG2");
		</script>
		<%
			out.print(StrUtil.jAlert_Redirect("操作成功！", "提示",
						"doc_show.jsp?id=" + id));
				return;
			}

			if (op.equals("vote")) {
				try {
		%>
		<script>
			$(".treeBackground").addClass("SD_overlayBG2");
			$(".treeBackground").css({"display":"block"});
			$(".loading").css({"display":"block"});
		</script>
		<%
			docmgr.vote(request, id);
		%>
			<script>
				$(".loading").css({"display":"none"});
				$(".treeBackground").css({"display":"none"});
				$(".treeBackground").removeClass("SD_overlayBG2");
			</script>
			<%
				out.print(StrUtil.jAlert_Redirect("投票成功！", "提示",
								"doc_show.jsp?op=view&id=" + id));
						return;
					} catch (ErrMsgException e) {
						out.print(StrUtil.jAlert_Back(e.getMessage(), "提示"));
						return;
					}
				}

				if (op.equals("delCmt")) {
					try {
			%>
		<script>
			$(".treeBackground").addClass("SD_overlayBG2");
			$(".treeBackground").css({"display":"block"});
			$(".loading").css({"display":"block"});
		</script>
		<%
			int cmtId = ParamUtil.getInt(request, "cmtId");
					if (cm.del(request, privilege, cmtId)) {
		%>
				<script>
					$(".loading").css({"display":"none"});
					$(".treeBackground").css({"display":"none"});
					$(".treeBackground").removeClass("SD_overlayBG2");
				</script>
				<%
					out.print(StrUtil.jAlert_Redirect("操作成功！", "提示",
										"doc_show.jsp?id=" + id));
							}
						} catch (ErrMsgException e) {
							out.print(StrUtil.jAlert_Back(e.getMessage(), "提示"));
							return;
						}
					}
					if (!privilege.isUserPrivValid(request, "read")) {
						out.println(cn.js.fan.web.SkinUtil.makeErrMsg(request,
								cn.js.fan.web.SkinUtil.LoadString(request,
										"pvg_invalid")));
						return;
					}

					LeafPriv lp = new LeafPriv();
					lp.setDirCode(doc.getDirCode());
					
					boolean isValid = lp.canUserSee(privilege.getUser(request));
					if (!isValid) {
						if (doc.getFlowId()!=0) {
							com.redmoon.oa.flow.WorkflowDb wf = new com.redmoon.oa.flow.WorkflowDb();
							wf = wf.getWorkflowDb((int)doc.getFlowId());
							if (wf.isUserAttended(privilege.getUser(request))) {
								isValid = true;
							}
						}
					}
											
					if (!isValid) {
						out.print(SkinUtil.makeErrMsg(request, SkinUtil.LoadString(
								request, "pvg_invalid")));
						return;
					} else {
						// 检查文件权限
						DocPriv dp = new DocPriv();
						if (!dp.canUserSee(request, id)) {
							out.println(cn.js.fan.web.SkinUtil.makeErrMsg(request,
									cn.js.fan.web.SkinUtil.LoadString(request,
											"pvg_invalid")));
							return;
						}

						if (doc != null && pageNum == 1) {
							// 使点击量增1
							doc.increaseHit();
						}

						// 记录访问日志
						String uName = privilege.getUser(request);
						String ip = com.cloudwebsoft.framework.util.IPUtil
								.getRemoteAddr(request);
						DocLogDb dld = new DocLogDb();
						if (lf.isLog()) {
							dld.setUserName(uName);
							dld.setDoc_id(id);
							dld.setIp(ip);
							dld.setLogDate(new java.util.Date());
							dld.create();
						}
						String myname = privilege.getUser(request);
				%>
<table class="doc_show_toolbar" align="center">
  <tr>
    <td width="74%" style="padding-left:10px">
	<%
		String pageUrl = "fileark/fileark_main.jsp?";
			if (lf.getCode().indexOf("cws_prj_") == 0) {
				String projectId = lf.getCode().substring(8);
				// 如果projectId中含有下划线_，则截取出其ID
				int p = projectId.indexOf("_");
				if (p != -1) {
					projectId = projectId.substring(0, p);
				}
				pageUrl = "project/project_doc_list.jsp?projectId="
						+ projectId;
			}
	%>
	<%=lf.getName()%>
      <script>
		if (typeof(window.parent.leftFileFrame)=="object"){
			var btnN = "关闭菜单";
			if (window.parent.getCols()!="200,*"){
				btnN = "打开菜单";
				isLeftMenuShow=false;
			}
			document.write("&nbsp;&nbsp;<a href=\"javascript:closeLeftMenu()\"><span id=\"btnName\">");
			document.write(btnN);
			document.write("</span></a>");
		}
		</script>
        </td>
    <td width="26%" align="right" >
	<a href="#" onclick="showFormReport()">打印</a>&nbsp;&nbsp;
	<%
		if (lp.canUserModify(myname)) {
				UserSetupDb usd = new UserSetupDb();
				usd = usd.getUserSetupDb(myname);
				pageUrl = usd.isWebedit() ? "fwebedit.jsp"
						: "fwebedit_new.jsp";
	%>
      <a href="javascript:;" onclick="addTab('<%=doc.getTitle()%>', '<%=pageUrl%>?op=edit&id=<%=doc.getID()%>&dir_code=<%=StrUtil.UrlEncode(doc.getDirCode())%>&dir_name=<%=StrUtil.UrlEncode(lf.getName())%>')">编辑</a>&nbsp;&nbsp;
	<%
		}
	%>
	<%
		if ((lp.canUserExamine(myname) || dp.canUserManage(request, id) || doc
					.getAuthor().equals(myname))
					&& lf.isLog()) {
	%>
        <a href="javascript:;" onclick="addTab('<%=doc.getTitle()%>', '<%=request.getContextPath()%>/fileark/doc_log.jsp?id=<%=doc.getId()%>&title=<%=StrUtil.UrlEncode(doc.getTitle())%>')">日志</a>&nbsp;&nbsp;
    <%
    	}
    %>
    </td>
  </tr>
</table>

<table cellSpacing="0" cellPadding="5" align="center" border="0" style="border-bottom:1px solid #c0d0dd" width="80%">
  <tbody>
    <tr>
      <td height="30" align="center"><%
      	if (doc.isLoaded()) {
      %>
          <b><font size="3" > <%=doc.getTitle()%></font></b>&nbsp; </td>
    </tr>
  </tbody>
</table >
	<table width="80%" align="center" >
    <tr>
      <td height="22" align="right" >
	  <%
	  	if (!doc.getKind().equals("")) {
	  				SelectOptionDb sod = new SelectOptionDb();
	  %>
		&nbsp;&nbsp;类别：<span class="doc_show_f1"><%=sod.getOptionName("fileark_kind", doc
								.getKind())%></span>
		<%
			}
		%>
	  <%
	  	if (!doc.getAuthor().equals("")) {
			String realName = doc.getAuthor();
			UserDb ud = um.getUserDb(doc.getAuthor());
			if (ud.isLoaded()) {
				realName = ud.getRealName();
			}
	  %>
       	  &nbsp;&nbsp;作者：<span class="doc_show_f1"><%=realName%></span>
        <%
        	}
        %>
       	 &nbsp;&nbsp;日期：<span class="doc_show_f1"><%=DateUtil.format(doc.getModifiedDate(),
							"yyyy-MM-dd HH:mm")%></span>
    	 &nbsp;&nbsp;访问次数：<span class="doc_show_f1"><%=doc.getHit()%></span>
        <%
        	} else {
        %>
        未找到该文章！
        <%
        	}
        %>     
        &nbsp;&nbsp;ID：<span class="doc_show_f1"><%=doc.getId()%></span>
      </td>
    </tr>
</table>
<%
		java.util.Vector attachments = doc.getAttachments(pageNum);
		java.util.Iterator ir = attachments.iterator();
		String str = "";
		int m = 0;
		while (ir.hasNext()) {
			Attachment am = (Attachment) ir.next();
			// 根据其diskName取出ext
			String ext = StrUtil.getFileExt(am.getDiskName());
			String link = am.getVisualPath() + "/" + am.getDiskName();
			if (ext.equals("mp3") || ext.equals("wma")) {
				// 使用realplay会导致IE崩溃
				// str += "<div><OBJECT classid=clsid:CFCDAA03-8BE4-11cf-B84B-0020AFBBCCFA class=OBJECT id=RAOCX width=500 height=80><PARAM NAME=SRC VALUE='" + link + "'><PARAM NAME=CONSOLE VALUE=Clip1><PARAM NAME=CONTROLS VALUE=imagewindow><PARAM NAME=AUTOSTART VALUE=true></OBJECT><br><OBJECT classid=CLSID:CFCDAA03-8BE4-11CF-B84B-0020AFBBCCFA height=32 id=video2 width=500><PARAM NAME=SRC VALUE='" + link + "'><PARAM NAME=AUTOSTART VALUE=-1><PARAM NAME=CONTROLS VALUE=controlpanel><PARAM NAME=CONSOLE VALUE=Clip1></OBJECT></div>";
				if (m == 0) {
					str += "<table align=center width=500><object align=middle classid=CLSID:22d6f312-b0f6-11d0-94ab-0080c74c7e95 class=OBJECT id=MediaPlayer width=500 height=70><param name=ShowStatusBar value=-1><param name=Filename value='"
							+ link
							+ "'><embed type=application/x-oleobject codebase=http://activex.microsoft.com/activex/controls/mplayer/en/nsmp2inf.cab#Version=5,1,52,701 flename=mp src='"
							+ link
							+ "'  width=500 height=70></embed></object></td></tr></table><BR>";
				} else {
					str += "<table align=center width=500><object align=middle classid=CLSID:22d6f312-b0f6-11d0-94ab-0080c74c7e95 class=OBJECT id=MediaPlayer width=500 height=70><param name=ShowStatusBar value=-1><param name=Filename value='"
							+ link
							+ "'><param name='AutoStart' value=0><embed type=application/x-oleobject codebase=http://activex.microsoft.com/activex/controls/mplayer/en/nsmp2inf.cab#Version=5,1,52,701 flename=mp src='"
							+ link
							+ "'  width=500 height=70></embed></object></td></tr></table><BR>";
				}
			} else if (ext.equals("wmv") || ext.equals("mpg")
					|| ext.equals("avi")) {
				// 使用realplay会导致IE崩溃
				// str += "<div><OBJECT classid=clsid:CFCDAA03-8BE4-11cf-B84B-0020AFBBCCFA class=OBJECT id=RAOCX width=500 height=80><PARAM NAME=SRC VALUE='" + link + "'><PARAM NAME=CONSOLE VALUE=Clip1><PARAM NAME=CONTROLS VALUE=imagewindow><PARAM NAME=AUTOSTART VALUE=true></OBJECT><br><OBJECT classid=CLSID:CFCDAA03-8BE4-11CF-B84B-0020AFBBCCFA height=32 id=video2 width=500><PARAM NAME=SRC VALUE='" + link + "'><PARAM NAME=AUTOSTART VALUE=-1><PARAM NAME=CONTROLS VALUE=controlpanel><PARAM NAME=CONSOLE VALUE=Clip1></OBJECT></div>";
				if (m == 0) {
					str += "<table align=center width=500><object align=middle classid=CLSID:22d6f312-b0f6-11d0-94ab-0080c74c7e95 class=OBJECT id=MediaPlayer width=500 height=400><param name=ShowStatusBar value=-1><param name=Filename value='"
							+ link
							+ "'><embed type=application/x-oleobject codebase=http://activex.microsoft.com/activex/controls/mplayer/en/nsmp2inf.cab#Version=5,1,52,701 flename=mp src='"
							+ link
							+ "'  width=500 height=70></embed></object></td></tr></table><BR>";
				} else {
					str += "<table align=center width=500><object align=middle classid=CLSID:22d6f312-b0f6-11d0-94ab-0080c74c7e95 class=OBJECT id=MediaPlayer width=500 height=400><param name=ShowStatusBar value=-1><param name=Filename value='"
							+ link
							+ "'><param name='AutoStart' value=0><embed type=application/x-oleobject codebase=http://activex.microsoft.com/activex/controls/mplayer/en/nsmp2inf.cab#Version=5,1,52,701 flename=mp src='"
							+ link
							+ "'  width=500 height=70></embed></object></td></tr></table><BR>";
				}
			} else if (ext.equals("rm") || ext.equals("rmvb")) {
				if (m == 0)
					str += "<table align=center width=500><OBJECT classid=clsid:CFCDAA03-8BE4-11cf-B84B-0020AFBBCCFA class=OBJECT id=RAOCX width=500 height=380><PARAM NAME=SRC VALUE='"
							+ link
							+ "'><PARAM NAME=CONSOLE VALUE=Clip1><PARAM NAME=CONTROLS VALUE=imagewindow><PARAM NAME=AUTOSTART VALUE=true></OBJECT><br><OBJECT classid=CLSID:CFCDAA03-8BE4-11CF-B84B-0020AFBBCCFA height=32 id=video2 width=500><PARAM NAME=SRC VALUE='"
							+ link
							+ "'><PARAM NAME=AUTOSTART VALUE=-1><PARAM NAME=CONTROLS VALUE=controlpanel><PARAM NAME=CONSOLE VALUE=Clip1></OBJECT></td></tr></table><BR>";
				else
					str += "<table align=center width=500><OBJECT classid=clsid:CFCDAA03-8BE4-11cf-B84B-0020AFBBCCFA class=OBJECT id=RAOCX width=500 height=380><PARAM NAME=SRC VALUE='"
							+ link
							+ "'><PARAM NAME=CONSOLE VALUE=Clip1><PARAM NAME=CONTROLS VALUE=imagewindow><PARAM NAME=AUTOSTART VALUE=false></OBJECT><br><OBJECT classid=CLSID:CFCDAA03-8BE4-11CF-B84B-0020AFBBCCFA height=32 id=video2 width=500><PARAM NAME=SRC VALUE='"
							+ link
							+ "'><PARAM NAME=AUTOSTART VALUE=0><PARAM NAME=CONTROLS VALUE=controlpanel><PARAM NAME=CONSOLE VALUE=Clip1></OBJECT></td></tr></table><BR>";
			}
			m++;
		}
		out.print(str);
%>
<%
	if (doc.isLoaded()) {
%>
<table width="80%" align="center">
<tr>
<td style="line-height:200%">
<%
if (filearkHighlightDirShow) {
%>
<div id="dir">
	<div class="tab-bar">
		<span id='tabHigh' class='tab'>高亮导航</span>
	</div>
</div>
<%} %>
<span id="remark" name="remark">
<%=doc.getContent(pageNum)%>
</span>
<%
	if (lf.isOfficeNTKOShow()) {
				if (doc != null) {
					ir = attachments.iterator();
					while (ir.hasNext()) {
						Attachment am = (Attachment) ir.next();
						// System.out.println(getClass() + " am.getExt()=" + am.getExt());
						// 因为在iframe中的ntko控件刷新存在问题，所以不能嵌于页面中显示
						if (dp.canUserSee(request, id)
								&& (am.getExt().equals("doc")
										|| am.getExt().equals("docx")
										|| am.getExt().equals("xls") || am
										.getExt().equals("xlsx"))) {
%>
            <object id="TANGER_OCX" classid="clsid:C9BC4DFF-4248-4a3c-8A49-63A7D317F404" codebase="activex/OfficeControl.cab#version=5,0,2,1" width="100%" height="100%" >
            <param name="CustomMenuCaption" value="操作">
            <param name="Caption" value="Office - 查看">
            <param name="MakerCaption" value="cloudweb">
            <param name="MakerKey" value="0727BEFE0CCD576DFA15807DA058F1AC691E1904">
			<%
            if (com.redmoon.oa.kernel.License.getInstance().isOem()) {%>
            <param name="ProductCaption" value="<%=License.getInstance().getCompany()%>">
            <param name="ProductKey" value="<%=License.getInstance().getOfficeControlKey()%>">
            <%}else{ %>
            <param name="ProductCaption" value="YIMIOA">
            <param name="ProductKey" value="D026585BDAFC28B18C8E01C0FC4C0AA29B6226B5">
            <%} %>
            <param name="ToolBars" value="0">
			<param name="Menubar" value="0">
			<param name="FileNew" value="0">
			<param name="FileOpen" value="0">
			<param name="FileSave" value="0">
			<param name="FileSaveAs" value="0">
			<param name="FilePageSetup" value="0"> 
			<%
 				if (!dp.canUserOfficePrint(request, id)) {
 			%>
			<param name="FilePrint" value="0">
			<param name="FilePrintPreview" value="0">
			<%
				}
			%>
            <SPAN STYLE="color:red">该网页需要控件浏览.浏览器无法装载所需要的文档控件.请检查浏览器选项中的安全设置.</SPAN>
            </object>
            <script>
			$(document).ready(function () {
				// 获取文档控件对象
				TANGER_OCX = document.getElementById('TANGER_OCX');
				TANGER_OCX.IsUseUTF8Data = true;
				
				TANGER_OCX.OpenFromURL("fileark/getfile.jsp?docId=<%=doc.getId()%>&attachId=<%=am.getId()%>", true);

				// 禁用右键菜单
				TANGER_OCX.ActiveDocument.CommandBars("Text").Enabled = false;
				TANGER_OCX.Menubar = true;
				TANGER_OCX.IsNoCopy = true;
				TANGER_OCX.SetReadOnly(true);
				
				TANGER_OCX.ActiveDocument.ActiveWindow.DocumentMap = false ;//隐藏导航窗格 
				// TANGER_OCX.ActiveDocument.ActiveWindow.View.Type=6;  // web视图
				TANGER_OCX.ActiveDocument.ActiveWindow.ActivePane.DisplayRulers=false; 
				TANGER_OCX.height = document.body.clientHeight;
			});
			</script>
<%
	// 只显示第一个Office附件
							break;
						} else if (am.getExt().equals("pdf")) {
%>
            <DIV id="IfNoAcrobat" style="text-align:right">  
            如果不能正常浏览文件，请先下载Adobe Reader.  
            </DIV>  
			<object id="acro" classid="clsid:CA8A9780-280D-11CF-A24D-444553540000" width="100%" height="768" border="0">  
			<param name="_Version" value="65539"> 
			<param name="_ExtentX" value="20108"> 
			<param name="_ExtentY" value="10866"> 
			<param name="_StockProps" value="0"> 
			<param name="SRC" value="<%=request.getContextPath()%>/<%=am.getVisualPath() + "/"
											+ am.getDiskName()%>">
			</object> 		
			<script>
			$(function() {
				try {
					acro.setShowToolbar(false);
				} catch (e) {
				}
			});
			</script>
            
		<%
    			// 只显示第一个pdf附件
    									break;
    								}
    							}
    						}
    					}
        		%>
</td></tr></table>
<%
	}

	StringBuffer ids = new StringBuffer();
	boolean canDownload = lp.canUserDownLoad(privilege.getUser(request)) && dp.canUserDownload(request, id);
	if (doc != null) {
		ir = attachments.iterator();
		while (ir.hasNext()) {
			Attachment am = (Attachment) ir.next();
			Attachment att = doc.getAttachment(pageNum, am.getId());
			StrUtil.concat(ids, String.valueOf(att.getId()), ",");
			String s = Global.getRealPath() + att.getVisualPath() + "/" + att.getDiskName();
			String htmlfile = s.substring(0, s.lastIndexOf(".")) + ".html";
			File fileExist = new File(htmlfile);
			boolean resultValue = false;
			if (fileExist.exists()) {
				resultValue = true;
			}
%>
<table width="80%"  border="0" cellspacing="0" cellpadding="0" align="center" style="margin-top:10px;">
  <tr>
    <td align="left">
    <%
    	boolean isOffice = am.getExt().equals("doc")
    						|| am.getExt().equals("docx")
    						|| am.getExt().equals("xls")
    						|| am.getExt().equals("xlsx")
    						|| am.getExt().equals("ppt")
    						|| am.getExt().equals("pptx");
    				boolean isImage = false;
    				boolean isPdf = am.getExt().equals("pdf");
    				if (canDownload) {
    					if (!am.isEmbedded()) {
    						if (StrUtil.isImage(StrUtil.getFileExt(am.getDiskName()))) {
    							isImage = true;
    %>
				<!-- <div style="margin-bottom:5px"><img class="docImg" src="<%=att.getVisualPath() + "/"
											+ att.getDiskName()%>" /></div> -->
				<%
							}
						}
					}

			if (canDownload) {
			%>
	        	&nbsp;&nbsp;<img src=images/attach.gif />&nbsp;&nbsp;&nbsp;&nbsp;<a href="javascript:;" onclick="downLoadDoc(<%=doc.getID()%>, <%=am.getId()%>)"><%=am.getName()%></a>&nbsp;&nbsp;&nbsp;&nbsp;下载次数&nbsp;&nbsp;<%=am.getDownloadCount()%>
	        	&nbsp;&nbsp;<a target=_blank id="previewId" style="display: <%=resultValue? "inline" : "none"%>;" href="doc_show_preview.jsp?pageNum=<%=pageNum%>&id=<%=doc.getID()%>&attachId=<%=am.getId()%>">预览</a>
	        <%
	        	if (isImage) {
	        %>
	        		&nbsp;&nbsp;<a href="javascript:;" onclick="showImg(<%=doc.getID()%>,<%=am.getId()%>);">图片预览</a>
			<%
				}
				if (isOffice) {
			%>
	            &nbsp;&nbsp;<a target=_blank href="fileark/fileark_ntko_show.jsp?pageNum=<%=pageNum%>&docId=<%=doc.getID()%>&attachId=<%=am.getId()%>">查看</a>
	    	<%
	    		}
	    		if(isPdf){
	    	%>
				&nbsp;&nbsp;<a target=_blank href="fileark/pdf_js/viewer.html?file=<%=request.getContextPath()+"/"+am.getVisualPath()+"/"+am.getDiskName()%>">查看</a>
	    	<%}
    		} else {
    			if (isOffice) {
    	%>
            	&nbsp;&nbsp;<img src=images/attach.gif />&nbsp;&nbsp;&nbsp;&nbsp;<a target=_blank href="fileark/fileark_ntko_show.jsp?pageNum=<%=pageNum%>&docId=<%=doc.getID()%>&attachId=<%=am.getId()%>"><%=am.getName()%></a>&nbsp;&nbsp;&nbsp;&nbsp;浏览次数&nbsp;&nbsp;<%=am.getDownloadCount()%>
            	&nbsp;&nbsp;<a target=_blank id="previewId" style="display: <%=resultValue == true ? "inline"
										: "none"%>;" href="doc_show_preview.jsp?pageNum=<%=pageNum%>&id=<%=doc.getID()%>&attachId=<%=am.getId()%>">预览</a>
    	<%
    			}
    		}
    	%>
    </td>
  </tr>
</table>
<%
	}
	if (canDownload) {
		if (attachments.size() > 1) {
%>
<table width="80%"  border="0" cellspacing="0" cellpadding="0" align="center">
  <tr>
    <td align="left">
    <div style="margin-top:10px;">&nbsp;&nbsp;<img src="images/zip.png" />
    &nbsp;&nbsp;
    <a href="javascript:;" onclick="addTabZip('<%=ids.toString() %>')">打包下载</a></div>
	</td>
	</tr>
</table>
<%
		}
	}
}
%>
<script>
// 下载文件
function downLoadDoc(doc_id, file_id) {
	$.ajax({
		type: "post",
		url: "fileark/downloadValidate.do",
		contentType:"application/x-www-form-urlencoded; charset=iso8859-1",		
		data : {
			ids: doc_id
		},
		dataType: "html",
		beforeSend: function(XMLHttpRequest) {
			$('body').showLoading();
		},
		success: function(data, status) {
			data = $.parseJSON(data);
			if (data.ret==2) {
				window.open("fileark/doc_getfile.jsp?pageNum=1&id=" + doc_id + "&attachId=" + file_id + "&op=download");			
			}
			else if (data.ret==0) {
				$.toaster({
					"priority" : "info",
					"message" : data.msg
				});
			}
			else {
				jConfirm(data.msg + '\n您确定要下载么？', '提示', function(r) {
					if (r) {	
						window.open("doc_getfile.jsp?pageNum=1&id=" + doc_id + "&attachId=" + file_id + "&op=download");
					}
				});			
			}
		},
		complete: function(XMLHttpRequest, status){
			$('body').hideLoading();				
		},
		error: function(XMLHttpRequest, textStatus){
			// 请求出错处理
			jAlert(XMLHttpRequest.responseText,"提示");
		}
	});	   
}

function addTabZip(ids) {
	$.ajax({
		type: "post",
		url: "fileark/downloadValidate.do",
		contentType:"application/x-www-form-urlencoded; charset=iso8859-1",		
		data : {
			ids: "<%=ids%>"
		},
		dataType: "html",
		beforeSend: function(XMLHttpRequest) {
			$('body').showLoading();
		},
		success: function(data, status) {
			data = $.parseJSON(data);
			if (data.ret==2) {
				window.open("zip_getfile.jsp?id=<%=id%>");
			}
			else if (data.ret==0) {
				$.toaster({
					"priority" : "info",
					"message" : data.msg
				});
			}
			else {
				jConfirm(data.msg + '\n您确定要打包下载么？', '提示', function(r) {
					if (r) {	
						window.open("zip_getfile.jsp?id=<%=id%>");
					}
				});			
			}
		},
		complete: function(XMLHttpRequest, status){
			$('body').hideLoading();				
		},
		error: function(XMLHttpRequest, textStatus){
			// 请求出错处理
			jAlert(XMLHttpRequest.responseText,"提示");
		}
	});	   		
}
</script>
<%
	if (doc.getType() == 1) {
			DocPollDb mpd = new DocPollDb();
			mpd = (DocPollDb) mpd
					.getQObjectDb(new Integer(doc.getId()));
			if (mpd != null) {
				String ctlType = "radio";
				if (mpd.getInt("max_choice") > 1)
					ctlType = "checkbox";
				java.util.Vector options = mpd.getOptions(doc.getId());
				int len = options.size();

				int[] re = new int[len];
				int[] bfb = new int[len];
				int total = 0;
				int k = 0;
				for (k = 0; k < len; k++) {
					DocPollOptionDb opt = (DocPollOptionDb) options
							.elementAt(k);
					re[k] = opt.getInt("vote_count");
					total += re[k];
				}
				if (total != 0) {
					for (k = 0; k < len; k++) {
						bfb[k] = (int) Math.round((double) re[k]
								/ total * 100);
					}
				}

				str = "";
				str += "<table>";
				str += "<form action='" + request.getContextPath()
						+ "/doc_show.jsp?op=vote&id=" + doc.getId()
						+ "' name=formvote method='post'>";
				str += "<tr><td colspan='2'>";
				java.util.Date epDate = mpd.getDate("expire_date");
				if (epDate != null) {
					str += "到期时间："
							+ DateUtil.format(epDate, "yyyy-MM-dd");
				}
				str += "</td><tr>";
				for (k = 0; k < len; k++) {
					DocPollOptionDb opt = (DocPollOptionDb) options
							.elementAt(k);

					str += "<tr>";
					str += "<td width=26>" + (k + 1) + "、</td>";
					str += "<td width=720><input class='n' type="
							+ ctlType + " name=votesel value='" + k
							+ "'>";
					str += opt.getString("content") + "</td>";
					str += "</tr>";
				}
				str += "<tr>";
				str += "<td colspan='2' align=center><input class='btn' type='submit' value=' 投  票 '>";
				str += "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
				str += "<input class='btn' name='btn' type='button' value='查看结果' onClick=\"window.location.href='"
						+ request.getContextPath()
						+ "/doc_show.jsp?id="
						+ doc.getId()
						+ "&op=view'\"></td>";
				str += "</tr>";
				str += "</form>";
				str += "</table>";
				out.print(str);
			}
		}
%>
<br />
<%
	if (op.equals("view")) {
			DocPollDb mpd = new DocPollDb();
			mpd = (DocPollDb) mpd
					.getQObjectDb(new Integer(doc.getId()));
			java.util.Vector options = mpd.getOptions(doc.getId());
			int len = options.size();

			int[] re = new int[len];
			int[] bfb = new int[len];
			int total = 0;
			int k = 0;
			for (k = 0; k < len; k++) {
				DocPollOptionDb opt = (DocPollOptionDb) options
						.elementAt(k);
				re[k] = opt.getInt("vote_count");
				total += re[k];
			}

			if (total != 0) {
				for (k = 0; k < len; k++) {
					bfb[k] = (int) Math.round((double) re[k] / total
							* 100);
				}
			}
%>
<table class="tabStyle_1 percent80" width="80%" align="center">
  <tr>
    <td class="tabStyle_1_title" colspan="4">投票结果：</td>
  </tr>
  <%
  	int barId = 0;
  			String showVoteUser = ParamUtil
  					.get(request, "showVoteUser");
  			for (k = 0; k < len; k++) {
  %>
  <tr>
    <td width="5%"><%=k + 1%>、</td>
    <td width="59%"><img src="forum/images/vote/bar<%=barId%>.gif" width=<%=bfb[k] * 2%> height=10 />
    <%
    	if (showVoteUser.equals("1")) {
    					out.print("<div>");
    					String[] userAry = StrUtil.split(
    							((DocPollOptionDb) options.elementAt(k))
    									.getString("vote_user"), ",");
    					if (userAry != null) {
    						int userLen = userAry.length;
    						String userNames = "";
    						for (int n = 0; n < userLen; n++) {
    							UserDb ud = um.getUserDb(userAry[n]);
    							if (userNames.equals(""))
    								userNames = ud.getRealName();
    							else
    								userNames += ",&nbsp;"
    										+ ud.getRealName();
    						}
    						out.print(userNames);
    					}
    					out.print("</div>");
    				}
    %></td>
    <td width="17%" align="right"><%=re[k]%>人</td>
    <td width="19%" align="right"><%=bfb[k]%>%</td>
  </tr>
  <%
  	barId++;
  				if (barId == 10)
  					barId = 0;
  			}
  %>
  <tr>
    <td colspan="4" align="center">共有<%=total%>人参加调查&nbsp;&nbsp;
        <input class="btn" name="button" type="button" onclick="window.location.href='doc_show.jsp?id=<%=doc.getId()%>&op=view&showVoteUser=1'" value="查看投票人员"/></td>
  </tr>
</table>
<%
	}
%>
<table width="80%" border="0" cellspacing="0" cellpadding="0" align="center">
  <tr>
    <td height="24" align="right">文章共<%=doc.getPageCount()%>页&nbsp;&nbsp;页码
      <%
    		int pagesize = 1;
    		int total = DocContent.getContentCount(doc.getID());
    		int curpage, totalpages;
    		Paginator paginator = new Paginator(request, total, pagesize);
    		// 设置当前页数和总页数
    		totalpages = paginator.getTotalPages();
    		curpage = paginator.getCurrentPage();
    		if (totalpages == 0) {
    			curpage = 1;
    			totalpages = 1;
    		}

    		String querystr = "op=edit&id=" + id;
    		out.print(paginator.getCurPageBlock("doc_show.jsp?" + querystr));
    %></td>
  </tr>
</table>
<table width="80%" style="padding-left:5px" cellSpacing="0" cellPadding="0" border="0" height="25" align="center">
  <tbody>
    <tr>
      <td>
      	<%
      	if (doc.getCanComment()) {
      	%>
          <img height="15" src="images/comment.gif" width="19" align="absMiddle"/><a href="#comment">发表评论</a>
		<%
		}
		%>
        <!--<img height="15" src="images/question.gif" width="19" align="absMiddle"><a target="_blank" href="jump.jsp?fromWhere=oa&toWhere=forum">提出问题</a>-->
	  </td>
    </tr>
  </tbody>
</table>
<%
	ir = cm.getList(id);
		if (ir.hasNext()) {
%>
<table style="padding-left:5px"  width="80%" border="0" cellpadding="0" cellspacing="0" align="center">
  <tr>
    <td height="25">评论：</td>
  </tr>
<%
	while (ir.hasNext()) {
				Comment cmt = (Comment) ir.next();
%>
  <tr>
    <td height="25" style="border-bottom:1px dashed #cccccc"><a target="_blank" href="user_info.jsp?userName=<%=StrUtil.UrlEncode(cmt.getNick())%>"><%=um.getUserDb(cmt.getNick()).getRealName()%></a>&nbsp;发表于&nbsp;<%=cmt.getAddDate()%>
	<%
		if (privilege.getUser(request).equals(cmt.getNick())
							|| privilege.isUserPrivValid(request,
									PrivDb.PRIV_ADMIN)) {
	%>
	
	&nbsp;&nbsp;[<a href="javascript:;" onclick="delComment(<%=id%>,<%=cmt.getId()%>)">删除</a>]
	<%
			}
		%>
	</td>
  </tr>
  <tr>
    <td style="padding-top:5px;word-break:break-all;"><%=cmt.getContent()%></td>
  </tr>
<%
	}
%>
</table>
<%
	}
%>

<br>
<%
	if (doc.isCanComment()) {
%>
<form name="form1" method="post" action="?op=addcomment">
  <table width="80%" border="0" align="center" cellpadding="0" cellspacing="0" >
    <tr>
      <td class="tabStyle_1_title">发表评论<a name="comment"></a></td>
    </tr>
    <tr>
      <td align="left" style="line-height:300%">&nbsp;&nbsp;姓名： <%=um.getUserDb(privilege.getUser(request)).getRealName()%>
          <input type="hidden" name="nick" size="15" value="<%=privilege.getUser(request)%>"/>
          <input type="hidden" name="doc_id" value="<%=doc.getID()%>"/>
          <input type="hidden" name="id" value="<%=doc.getID()%>"/>
          <input name="link" type="hidden" value="<%=Global.AppName%>"/>
</td>
    </tr>
    <tr>
      <td align="center">
      <textarea id="content" name="content" style="width:100%;" cols="45" rows="3"></textarea>
<script>
var uEditor;
$(function() {
	uEditor = UE.getEditor('content',{
				//allowDivTransToP: false,//阻止转换div 为p
				toolleipi:true,//是否显示，设计器的 toolbars
				textarea: 'content',
				enableAutoSave: false,  
				toolbars: [[
		            'fullscreen', 'source', '|', 'undo', 'redo', '|',
		            'bold', 'italic', 'underline', 'fontborder', 'strikethrough', 'superscript', 'subscript', 'removeformat', 'formatmatch', 'autotypeset', 'blockquote', 'pasteplain', '|', 'forecolor', 'backcolor', 'insertorderedlist', 'selectall', '|',
		            'paragraph', 'fontfamily', 'fontsize', '|',
		            'directionalityltr', 'directionalityrtl', 'indent', '|',
		            'justifyleft', 'justifycenter', 'justifyright', 'justifyjustify'
		        ]],				
				//focus时自动清空初始化时的内容
				//autoClearinitialContent:true,
				//关闭字数统计
				wordCount:false,
				//关闭elementPath
				elementPathEnabled:false,
				//默认的编辑区域高度
				initialFrameHeight:200,
				disabledTableInTable:false 
				///,iframeCssUrl:"css/bootstrap/css/bootstrap.css" //引入自身 css使编辑器兼容你网站css
				//更多其他参数，请参考ueditor.config.js中的配置项
			});
			
	UE.Editor.prototype._bkGetActionUrl = UE.Editor.prototype.getActionUrl;
	UE.Editor.prototype.getActionUrl = function(action) {
	    if (action == 'uploadimage' || action == 'uploadscrawl') {
	        return '<%=request.getContextPath()%>/ueditor/UploadFile?op=fileark';
	    } else if (action == 'uploadvideo') {
	        return '<%=request.getContextPath()%>/ueditor/UploadFile?op=fileark';
	    } else {
	        return this._bkGetActionUrl.call(this, action);
	    }
	}
});
</script>
      </td>
    </tr>
    <tr><td><br/></td></tr>
    <tr>
      <td align="center">
      	<input name="Submit" type="submit" class="mybtn" value="提交" />
      </td>
    </tr>
    <tr><td><br/></td></tr>
  </table>
</form>
<%
	}
%>
<%
	}
%>
<script>
function getPrintContent(){
	return remark.innerHTML;
}
function showFormReport() {
	// 下列方式有时会导致IE崩溃
	var preWin=window.open('fileark_print_preview.jsp','','left=0,top=0,width=550,height=400,resizable=1,scrollbars=1, status=1, toolbar=1, menubar=1');	
	/*
	preWin.document.open();
	
	// 必须要按下面的方式来写，才能引入script
	preWin.document.write('<script src="spwhitepad/createShapes.js" type="text/javascript"><\/sc'+'ript>');
	preWin.document.write('<script src="inc/common.js" type="text/javascript"><\/sc'+'ript>');
	preWin.document.write('<script src="js/jquery.js" type="text/javascript"><\/sc'+'ript>');

	var str = "<link type='text/css' rel='stylesheet' href='<%=SkinMgr.getSkinPath(request)%>/css.css' />";
	preWin.document.write(str + "<style>TD{ TABLE-LAYOUT: fixed; FONT-SIZE: 12px; WORD-BREAK: break-all; FONT-FAMILY:}</style>" + formDiv.innerHTML);
	preWin.document.close();
	preWin.document.title="表单";
	preWin.document.charset="UTF-8";
	*/
}
</script>
<script>
/*!
 * jQuery showDialog
 * befen.net
 * Date: 2013.02.08
*/

/**展示图片
 * 
 * @param attId
 * @return
 */
function showImg(docId,attId) {
	$.ajax({
	 		type:"post",
	 		url:"doc_show_do.jsp",
	 		data:{
	 			"op":"showImg",
	 			"docId":docId,
	 			"attId":attId
	 		},
	 		success:function(data,status){
	 			data = $.parseJSON(data);
	 			if(data.ret == 1){
	 				showDialog("info",attId,docId,"图片预览",data.width,data.height,"showImg",data.downloadUrl,0);
	 			}else{
	 				jAlert(data.msg,"提示");
	 			}
	 		},
	 		error:function(XMLHttpRequest, textStatus){
	 			alert(XMLHttpRequest.responseText);
	 		}
	});
}


var ImgId = "";
var currentDocId = "";
var ImgWidth = "";
var ImgHeight = "";
var isSearch = "";
$(function(){

	$("#showImg_left").live("mouseover",function(){
		showNext();
	});
	$("#showImg_right").live("mouseover",function(){
		showNext();
	});
	$("#showImg_left").live("mousedown",function(){
		$(this).find("img").attr({"src":"netdisk/images/clouddisk/arrow_left_hover.png"});
	});
	$("#showImg_right").live("mousedown",function(){
		$(this).find("img").attr({"src":"netdisk/images/clouddisk/arrow_right_hover.png"});
	});
	$("#showImg_left").live("mouseup",function(){
		$(this).find("img").attr({"src":"netdisk/images/clouddisk/arrow_left.png"});
	});
	$("#showImg_right").live("mouseup",function(){
		$(this).find("img").attr({"src":"netdisk/images/clouddisk/arrow_right.png"});
	});
	$(".showImg_Next").live("click",function(){
		var arrow = $(this).attr("value");
		var isImgSearch = $(this).attr("isImgSearch");
		showImgNext("doc_show_do.jsp",arrow,isImgSearch);
	});

	$('#remark').find('input').each(function() {
		$(this).remove();
	});
})

function delComment(id,cmtId){
	jConfirm("确定要删除评论吗？","提示",function(r){
		if(!r){return;}
		else{
			window.location.href="doc_show.jsp?op=delCmt&id="+id+"&cmtId="+cmtId;
		}
	})
}

function showImgNext(url,arrow,isImgSearch){
	$.ajax({
		type:"post",
		url:url,
		data:{
			"op":"showNextImg", 
			"attId":ImgId,
			"docId":currentDocId,
			"arrow":arrow
		},
		success:function(data,status){
			data = $.parseJSON(data);
			if(data.ret == "1" ){
				showDialog("info",data.newId,currentDocId,"图片预览",data.width,data.height,"showNextImg",data.downloadUrl);
			}
			
		},
		error:function(XMLHttpRequest, textStatus){
			alert(XMLHttpRequest.responseText);
		}
	});
}

function showDialog(mode, msg,docId, t, sd_width, sd_height,type,url,isImgSearch) {
	if(isImgSearch != null){
		isSearch = isImgSearch;
	}
	var window_height = document.documentElement.clientHeight;
	var window_width = document.documentElement.clientWidth;
	if(type == "showNextImg"){
		img_w = sd_width;
		img_h = sd_height;
		img_w = (img_w > ImgWidth )? ImgWidth : img_w;
		img_h = (img_h > ImgHeight)? ImgHeight : img_h;
		var left = (window_width - ImgWidth)/2 - 100;
		var top = (window_height - ImgHeight)/2 - 70;
	}else{
		var img_w = sd_width; 
		var img_h = sd_height;
		sd_width = (sd_width < 550) ? 550 : ((sd_width > 750) ? 750 : sd_width);
		sd_height = (sd_height < 380) ? 380 : ((sd_height > 450) ? 450 : sd_height);
		ImgWidth = sd_width;  
		ImgHeight = sd_height;
		img_w = (img_w > sd_width )? sd_width : img_w;
		img_h = (img_h > sd_height)? sd_height : img_h;
		var left = (window_width - sd_width)/2 - 100;
		var top = (window_height - sd_height)/2 - 70;
	}
	
	var mode = in_array(mode, ['confirm', 'window', 'info', 'loading']) ? mode : 'alert';
	var t = t ? t : "提示信息";
	var msg = msg ? msg : "";
	ImgId = msg;          	//为左右切换图片id赋值
	currentDocId = docId;	//为左右切换图片所在文档id赋值
	var confirmtxt = confirmtxt ? confirmtxt : "确定";
	var canceltxt = canceltxt ? canceltxt : "取消";
	sd_remove();
	try {
		if(typeof document.body.style.maxHeight === "undefined") {
			$("body","html").css({height: "100%", width: "100%"});
			if(document.getElementById("SD_HideSelect") === null) {
				$("body").append("<iframe id='SD_HideSelect'></iframe><div id='SD_overlay'></div>");
			}
		} else {
			if(document.getElementById("SD_overlay") === null) {
				$("body").append("<div id='SD_overlay'></div>");
			}
		}
		if(mode == "alert") {
			if(detectMacXFF()) {
				$("#SD_overlay").addClass("SD_overlayMacFFBGHack");
			} else {
				$("#SD_overlay").addClass("SD_overlayBG");
			}
		} else {
			if(detectMacXFF()) {
				$("#SD_overlay").addClass("SD_overlayMacFFBGHack2");
			} else {
				$("#SD_overlay").addClass("SD_overlayBG2");
			}
		}
		$("body").append("<div id='SD_window' style='height:700px;'></div>");
		var SD_html;
		SD_html = "";
		SD_html += "<table cellspacing='0' cellpadding='0'  style='position:fixed;  z-index:1911; top:"+top+"px; left:"+left+"px;'><tbody ><tr><td class='SD_bg'></td><td class='SD_bg'></td><td class='SD_bg'></td></tr>";
		SD_html += "<tr><td class='SD_bg'></td>";
		SD_html += "<td id='SD_container'>";
		SD_html += "<h3 id='SD_title' style='margin-top:0px;'>" + t + "</h3>";
		if(type == "showImg"){
			SD_html += "<div id='SD_body' onmouseover='showNext()'  onmouseout = 'hiddenNext()' style='margin-top:-15px; height:"+ (sd_height+10)+"px; width:"+ (50+sd_width)+"px !important;overflow:auto; border:#999 4px solid;text-align:center;'>";
			SD_html += "<div class='showImg_Next' id='showImg_left' value='left' isImgSearch='"+isSearch+"' style='display:none;position:absolute; top:"+((sd_height+40)/2)+"px; left:10px;'><img src='netdisk/images/clouddisk/arrow_left.png'></div>";
			SD_html += "<img style='padding-top:"+ ((sd_height-img_h)/2-15) +"px;height:"+img_h+"px; width:"+img_w+"px;' src='"+ url+ "'/>";
			SD_html += "<div class='showImg_Next' id='showImg_right' value='right' isImgSearch='"+isSearch+"' style='display:none;position:absolute; top:"+((sd_height+40)/2)+"px; right:10px'><img src='netdisk/images/clouddisk/arrow_right.png'></div>";
			SD_html += "</div>";
		}else if(type == "showNextImg"){
			SD_html += "<div id='SD_body' onmouseover='showNext()'  onmouseout = 'hiddenNext()' style='height:"+ (ImgHeight +10)+"px; width:"+ (50+ImgWidth)+"px;overflow:auto; border:#999 4px solid;text-align:center;'>";
			SD_html += "<div class='showImg_Next' id='showImg_left' value='left' isImgSearch='"+isSearch+"' style='display:none;position:absolute; top:"+((ImgHeight+40)/2)+"px; left:10px;'><img src='netdisk/images/clouddisk/arrow_left.png'></div>";
			SD_html += "<img style='padding-top:"+ ((ImgHeight-img_h)/2-15) +"px;height:"+img_h+"px; width:"+img_w+"px;' src='"+url+ "'/>";
			SD_html += "<div class='showImg_Next' id='showImg_right' value='right' isImgSearch='"+isSearch+"' style='display:none;position:absolute; top:"+((ImgHeight+40)/2)+"px; right:10px'><img src='netdisk/images/clouddisk/arrow_right.png'></div>";
			SD_html += "</div>";
		}
		else{
		SD_html += "<div id='SD_body' style='height:"+ sd_height+"px; width:"+ sd_width +"px;overflow:auto; border:#999 4px solid;'><div id='SD_content' >" + msg + "</div></div>";
		}
		SD_html += "<div id='SD_button'><div class='SD_button'>";
		if(type == "movefile"){
			SD_html += "<a id='SD_confirm1' >"+ confirmtxt + "</a>";
			SD_html += "<a id='SD_cancel' onclick='closeDialog();'>"+ canceltxt + "</a>";
		}else{
			SD_html += "<a id='SD_confirm' >"+ confirmtxt + "</a>";
			SD_html += "<a id='SD_cancel' >"+ canceltxt + "</a>";
		}
		SD_html += "</div></div>";
		if(type == "movefile"){
			SD_html += "<a href='javascript:void(0);' id='SD_close' onclick='closeBackGround();' title='关闭'></a>";
		}else{
			SD_html += "<a href='javascript:void(0);' id='SD_close' title='关闭'></a>";
		}
		SD_html += "</td>";
		SD_html += "<td class='SD_bg'></td></tr>";
		SD_html += "<tr><td class='SD_bg'></td><td class='SD_bg'></td><td class='SD_bg'></td></tr></tbody></table>";
		$("#SD_window").append(SD_html);
		$("#SD_confirm,#SD_cancel,#SD_close").live("click", function(){
			//sd_remove();
			//sd_closeWindow();
			$("#SD_window,#SD_overlay,#SD_HideSelect").remove();
		});
		if(mode == "info" || mode == "alert") {
			$("#SD_cancel").show();
			$("#SD_confirm").hide();
		}
		if(mode == "window") {
			$("#SD_close").show();
			$("#SD_cancel").show();
			$("#SD_button").show();
		}
		if(mode == "confirm") {
			$("#SD_button").show();
		}
		var sd_move = false;
		var sd_x, sd_y;
		$("#SD_container > h3").click(function(){}).mousedown(function(e){
			sd_move = true;
			sd_x = e.pageX - parseInt($("#SD_window").css("left"));
			sd_y = e.pageY - parseInt($("#SD_window").css("top"));
		});
		$(document).mousemove(function(e){
			if(sd_move){
				var x = e.pageX - sd_x;
				var y = e.pageY - sd_y;
				$("#SD_window").css({left:x, top:y});
			}
		}).mouseup(function(){
			sd_move = false;
		});
		//$("#SD_body").width(sd_width - 50);
		sd_load(sd_width);
		$("#SD_window").show();
		$("#SD_window").focus();
	} catch(e) {
		jAlert("System Error !","提示");
	}
}

<%
if (filearkHighlightDirShow) {
%>
function parseHighlight(content) {
	var ul = document.createElement("ul");
	ul.setAttribute("id", "tabHighCont");
		
	var highCount = 0;
	var reg = new RegExp('<span(.*?) style="(.*?)background-color:(.*?)">(.*?)<\/span>', "ig");
	while((result=reg.exec(content))!=null) {
		var t = RegExp.$4;
		var $t = $('<div>' + t + '</div>');
		var st = $t.text();
		var at = st;
		if (st.length>15) {
			st = st.substring(0, 15);
		}

		var li = document.createElement("li");
		li.innerHTML = "<a title='" + at + "'>" + st + "</a>";
		ul.appendChild(li);
		highCount ++;
	}
	
	$("#dir").append(ul);
	
	if (highCount==0) {
		$('#dir').hide();
	}
	
	$("#tabHighCont li a").bind("click", function() {
		var text = this.innerText;
		var span = $("#remark").find("span");
		span.each(function(){
			var html = $(this).prop('outerHTML');
			if (html.indexOf("background-color")!=-1) {
				if (html.indexOf(text)!=-1) {
					// lte界面中，滚动会导致iframe整体左移
					// $(this)[0].scrollIntoView(false);
					showSearch($(this)[0]);
				}
			}
		});
	});	
}

function showSearch(spanObj){   
	var oDiv = spanObj;
	var t = document.createElement("input");
	t.type="text";
	oDiv.insertBefore(t, oDiv.firstChild);
	t.focus();
	oDiv.removeChild(t);
}

$(function() {
	parseHighlight($('#remark').html());
});
<%}%>

$(function (){
	$(window).goToTop({
		showHeight : 1,//设置滚动高度时显示
		speed : 500 //返回顶部的速度以毫秒为单位
	});
});
</script>
</body>
</html>
