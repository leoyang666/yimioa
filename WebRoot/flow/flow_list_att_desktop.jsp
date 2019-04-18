<%@ page contentType="text/html;charset=utf-8"%>
<%@ page import="java.util.*"%>
<%@ page import="cn.js.fan.util.*"%>
<%@ page import="cn.js.fan.db.*"%>
<%@ page import="com.redmoon.oa.person.*"%>
<%@ page import="com.redmoon.oa.flow.*"%>
<%@ page import="com.redmoon.oa.dept.*"%>
<%@ page import = "com.redmoon.oa.ui.*"%>
<jsp:useBean id="docmanager" scope="page" class="com.redmoon.oa.fileark.DocumentMgr"/>
<jsp:useBean id="privilege" scope="page" class="com.redmoon.oa.pvg.Privilege"/>
<%
String priv="read";
if (!privilege.isUserPrivValid(request,priv)) {
	out.println(cn.js.fan.web.SkinUtil.makeErrMsg(request, cn.js.fan.web.SkinUtil.LoadString(request, "pvg_invalid")));
	return;
}

int id = ParamUtil.getInt(request, "id");
UserDesktopSetupDb udsd = new UserDesktopSetupDb();
udsd = udsd.getUserDesktopSetupDb(id);

String op = ParamUtil.get(request, "op");

String typeCode = ParamUtil.get(request, "typeCode");
typeCode = "fawen";
String typeName = "";
if (!typeCode.equals("")) {
	Leaf lf = new Leaf();
	lf = lf.getLeaf(typeCode);
	if (lf!=null)
		typeName = "&nbsp;-&nbsp;"+lf.getName()+"&nbsp;";
}

String strcurpage = StrUtil.getNullString(request.getParameter("CPages"));
if (strcurpage.equals(""))
	strcurpage = "1";
if (!StrUtil.isNumeric(strcurpage)) {
	out.print(StrUtil.makeErrMsg("标识非法！"));
	return;
}
int pagesize = 20;
int curpage = Integer.parseInt(strcurpage);

WorkflowDb wf = new WorkflowDb();

String sql = "select id from flow where type_code=" + StrUtil.sqlstr(typeCode) + " and status=" + WorkflowDb.STATUS_FINISHED;
sql += " order by begin_date desc";

ListResult lr = wf.listResult(sql, curpage, pagesize);
int total = lr.getTotal();
Paginator paginator = new Paginator(request, total, pagesize);
// 设置当前页数和总页数
int totalpages = paginator.getTotalPages();
if (totalpages==0) {
	curpage = 1;
	totalpages = 1;
}

Vector v = lr.getResult();
Iterator ir = v.iterator();
%>
<div id="<%=id%>" class="portlet">
<div class="portlet_topper">
<a href="flow/flow_list_att.jsp"><%=udsd.getTitle()%></a>
</div>
<div class="portlet_content">
<ul>
<%
Leaf ft = new Leaf();
UserMgr um = new UserMgr();
DocumentMgr dm = new DocumentMgr();
while (ir.hasNext()) {
 	WorkflowDb wfd = (WorkflowDb)ir.next();
	Document doc = dm.getDocument(wfd.getDocId());
	java.util.Vector attachments = doc.getAttachments(1);
	if (attachments.size()==0)
		continue;
	UserDb user = null;
	if (wfd.getUserName()!=null)
		user = um.getUserDb(wfd.getUserName());
	String userRealName = "";
	if (user!=null)
		userRealName = user.getRealName();
		
	java.util.Iterator ir2 = attachments.iterator();
	if (ir2.hasNext()) {
		Attachment am = (Attachment) ir2.next();
		%>
    <li>
	<a href="flow_getfile.jsp?attachId=<%=am.getId()%>&amp;flowId=<%=wfd.getId()%>" target="_blank"><%=am.getName()%>&nbsp;[<%=DateUtil.format(wfd.getEndDate(), "yy-MM-dd HH:mm:ss")%>]</a>
    </li>		
<%
	}
}%>
</ul>
</div>
</div>