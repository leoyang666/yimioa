<%@ page contentType="text/html; charset=utf-8" language="java" errorPage="" %>
<%@ page import = "com.cloudwebsoft.framework.db.*"%>
<%@ page import = "cn.js.fan.db.*"%>
<%@ page import = "cn.js.fan.util.*"%>
<%@ page import = "cn.js.fan.web.*"%>
<%@ page import = "org.json.*"%>
<%@ page import = "java.util.*"%>
<%@ page import = "com.redmoon.oa.sms.*"%>
<%@ page import = "com.redmoon.oa.flow.*"%>
<%@ page import = "com.redmoon.oa.pvg.*"%>
<%@ page import = "com.redmoon.oa.person.*"%>
<%
Privilege pvg = new Privilege();
if (!pvg.isUserLogin(request))
	return;

String userName = pvg.getUser(request);

UserDb user = new UserDb();
user = user.getUserDb(userName);

int flowId = ParamUtil.getInt(request,"flowId");
//System.out.println("flowId:"+flowId);
String rootpath = request.getContextPath();

int file_id = ParamUtil.getInt(request, "file_id", -1);

String editable = ParamUtil.get(request, "editable");
if (editable.equals(""))
	editable = "true";
boolean isEditable = editable.equals("true");

WorkflowDb wf = new WorkflowDb();
wf = wf.getWorkflowDb(flowId);

String typeCode = wf.getTypeCode();
Leaf lf = new Leaf();
lf = lf.getLeaf(typeCode);

int doc_id = wf.getDocId();

Attachment att = new Attachment(file_id);

WorkflowPredefineDb wfp = new WorkflowPredefineDb();
wfp = wfp.getPredefineFlowOfFree(wf.getTypeCode());
// System.out.println(getClass() + " flowId=" + flowId + " file_id=" + file_id);

String ntkoFieldName = ParamUtil.get(request, "ntkoFieldName");
String flag = "";
int isRevise = 0;
int actionId = ParamUtil.getInt(request, "actionId", -1);

WorkflowActionDb wad = new WorkflowActionDb();
if (actionId!=-1) {
	wad = wad.getWorkflowActionDb(actionId);
	if (wad.getIsStart()==0) {
		isRevise = 1;
	}
	
	flag = wad.getFlag();
}

long myActionId = ParamUtil.getLong(request, "myActionId", -1);
%>

isTangerOCX = true;

var TANGER_OCX;

function initNtko(){
    //获取文档控件对象
    TANGER_OCX = document.getElementById('TANGER_OCX');
    TANGER_OCX.IsUseUTF8Data = true;
    //创建新文档
    //TANGER_OCX.CreateNew("Word.Document");
    TANGER_OCX.OpenFromURL("<%=request.getContextPath()%>/flow_getfile.jsp?attachId=<%=file_id%>&flowId=<%=flowId%>");
    TANGER_OCX_SetDocUser("<%=user.getRealName()%>");
    <%
    if(isRevise!=0){
    %>
    TANGER_OCX_SetMarkModify(true);
    <%}%>
	<%if (!isEditable) {%>
    // TANGER_OCX.FileSave=false;
    // TANGER_OCX.FileSaveAs=false;
    TANGER_OCX.SetReadOnly(true,"");
    <%}%>
}

$(document).ready(function() {
	initNtko();
    AddMyMenuItems();
});

function TANGER_OCX_SetDocUser(cuser)
{
	with(TANGER_OCX.ActiveDocument.Application)
	{
		UserName = cuser;
	}	
}

function TANGER_OCX_SetMarkModify(boolvalue)
{
	TANGER_OCX_SetReviewMode(boolvalue);
	//TANGER_OCX_EnableReviewBar(!boolvalue);
}

function TANGER_OCX_SetReviewMode(boolvalue)
{
	try {
		TANGER_OCX.ActiveDocument.TrackRevisions = boolvalue;
	}
	catch (e) {}
}

function TANGER_OCX_EnableReviewBar(boolvalue)
{
	TANGER_OCX.ActiveDocument.CommandBars("Reviewing").Enabled = boolvalue;
	TANGER_OCX.ActiveDocument.CommandBars("Track Changes").Enabled = boolvalue;
	TANGER_OCX.IsShowToolMenu = boolvalue;	//关闭或打开工具菜单
}
//接受所有修订
function TANGER_OCX_AcceptAllRevisions()
{
   TANGER_OCX.ActiveDocument.AcceptAllRevisions();
}
function AddMyMenuItems()
{
 	try
	{
		// 在自定义主菜单中增加菜单项目，在NTKOCtl宏控件中，加入事件的处理脚本
		TANGER_OCX.AddCustomMenuItem('图片签章',false,false,1);
		TANGER_OCX.AddCustomMenuItem('手写签名',false,false,2);

		TANGER_OCX.AddCustomMenuItem('公文套红',false,false,3);
		<%if (actionId!=-1 && wad.canReceiveRevise()) {%>
		TANGER_OCX.AddCustomMenuItem('文件定稿',false,false,4);
		<%}%>
	}
   	catch(err){
		alert("不能创建新对象："+ err.number +":" + err.description);
	}
	finally{
	}
}

function edit() {
	var msg = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_document_check.jsp","some.doc","flowId=<%=flowId%>&doc_id=<%=doc_id%>&file_id=<%=file_id%>","some.doc","myForm");
	alert(msg);
}

function createWPS(){
 TANGER_OCX.CreateNew("WPS.Document");
 document.getElementById("exts").value = "WPS";
}
function creatDOC(){
 TANGER_OCX.CreateNew("Word.Document");
 document.getElementById("exts").value = "DOC";
}

//图片印章
function userStamp()
{
   openChooseStamp("getstamp");
   //alert(URL);
}

function openWinForFlowAccess(url,width,height)
{
	var newwin = window.open(url,"_blank","toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,top=400,left=550,width="+width+",height="+height);
}

function openWinStamp(obj) {
	inputObj = obj;
	openWinForFlowAccess("<%=rootpath%>/flow/flow_ntko_stamp_win.jsp?stampId="+obj, 200, 10);
	
}

function openChooseStamp(obj) {
	inputObj = obj;
	openWinForFlowAccess("<%=rootpath%>/flow/flow_ntko_stamp_choose.jsp", 200, 10);
	
}

function test() {
	AddSignFromURL(URL);
}

function AddSignFromURL(URL)
{
     alert(URL);
//   alert(TANGER_OCX_key);
      TANGER_OCX.AddSignFromURL(
	'<%=user.getRealName()%>',//当前登陆用户
	URL,//URL
	50,//left
	50,
	"1",
1,
100,
0) 
}

function AddPictureFromURL(URL)
{

    TANGER_OCX.AddPicFromURL(
		URL,//URL 注意；URL必须返回Word支持的图片类型。
		true,//是否浮动图片
		0, 
		0,
        1, //当前光标处
		100,//无缩放
		1 //文字上方
	)
};

function useHandSign()
{
   DoHandSign();
}

function DoHandSign()
{
//   alert(TANGER_OCX_key);
	TANGER_OCX.DoHandSign(
	'<%=user.getRealName()%>',//当前登陆用户 必须
	0,//笔型0－实线 0－4 //可选参数
	0x000000ff, //颜色 0x00RRGGBB//可选参数
	2,//笔宽//可选参数
	100,//left//可选参数
	50,//top//可选参数
	false,//可选参数
	1
	);
}

<%if (isEditable) {
	// 当可编辑时，才覆盖脚本中的相关方法
%>
function saveDraft() {
<%
	if(lf.getType()==Leaf.TYPE_FREE){
%>
	if (!LiveValidation.massValidate(lv_cwsWorkflowResult.formObj.fields)) {
		// jAlert("请检查表单中的内容填写是否正常！", "提示");
		// return;
	}
			
	var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_free_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
	$('#bodyBox').hideLoading();
    showResponse(data);	
<%}else{%>
	hideDesigner();
	
	if (!LiveValidation.massValidate(lv_cwsWorkflowResult.formObj.fields)) {
		// jAlert("请检查表单中的内容填写是否正常！", "提示");
		// return;
	}
	$('#bodyBox').showLoading();				
	var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
	
    showResponse(data);	
<%} %>			
}

function SubmitResult(isAfterSaveformvalueBeforeXorCondSelect) {
<%
if(lf.getType()==Leaf.TYPE_FREE) {
%>
    // 先ajax保存表单，然后再ajax弹出对话框选择用户，然后才交办
    flowForm.op.value = "finish";
        
    if (o('flowForm').onsubmit) {
        if (o('flowForm').onsubmit()) {			
            var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_free_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
            showResponse(data);
        }
        else {
            toolbar.setDisabled(1, false);				
            $('#bodyBox').hideLoading();
        }
    }
    else {			
        var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_free_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
        showResponse(data);
    }
        
    return;
<%}else{%>
	hideDesigner();
	
	if (hasCond && !isAfterSaveformvalueBeforeXorCondSelect) {
		// 先ajax保存表单，然后再ajax弹出对话框选择用户，然后才交办
		flowForm.op.value = "saveformvalueBeforeXorCondSelect";
			
		if (o('flowForm').onsubmit) {
			if (o('flowForm').onsubmit()) {
				$('#bodyBox').showLoading();				
                var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
                showResponse(data);
			}
			else {
				toolbar.setDisabled(1, false);				
				$('#bodyBox').hideLoading();
			}
		}
		else {
            $('#bodyBox').showLoading();				
            var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
            showResponse(data);
        }
			
		return;
	}
	
	// 如果本节点是异或节点，且是条件鉴别节点，如果未满足条件，则在此提醒用户先保存结果，然后继续往下进行
	if (isXorRadiate && (hasCond && !isCondSatisfied) ) {
		// 2011-11-13 改为当不满足条件时，可排除掉不满足的分支，如果有条件为空的分支（且空的分支线大于2条，如果只有一条则表示为默认分支线），则使用户可以选择分支线
		// 因而此处不再提醒，如果一个条件也不满足，则在setXorRadiateNextBranch中会检测后提示，请选择后继节点
		// alert("当前处理不满足往下进行的条件（具体条件请见流程图），请先点击保存，待满足条件后继续！");
		// return;
	}
	// 如果是自动存档节点，则先保存表单，然后回到此页面，在onload的时候再FinishActoin
	<%if (flag.length()>=5 && flag.substring(4, 5).equals("2")) {%>
		flowForm.op.value = "AutoSaveArchiveNodeCommit";
	<%}else{%>
		flowForm.op.value = 'finish';
	<%}%>
	
	<%if (flag.length()>=5 && flag.substring(4, 5).equals("2")) {%>			  
	flowForm.formReportContent.value = hidFrame.getFormReportContent();
	<%}%>
	
	getXorSelect();
	
	var re = true;
	try {
		// 在嵌套表格页面中，定义了onsubmit方法
		re = flowForm.onsubmit();
	}
	catch (e) {}
	if (re) {
		if (isAfterSaveformvalueBeforeXorCondSelect)
			o("isAfterSaveformvalueBeforeXorCondSelect").value = "" + isAfterSaveformvalueBeforeXorCondSelect;
		
        $('#bodyBox').showLoading();
        
        var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
        showResponse(data);
	}
	else {
		toolbar.setDisabled(1, false);
		$('#bodyBox').hideLoading();				
	}
<%}%>
	
}

function returnFlow() {
	<%if (wfp.getReturnStyle()==WorkflowPredefineDb.RETURN_STYLE_FREE) {%>
		$.ajax({
			type: "post",
			url: "flow_dispose_ajax_return.jsp",
			data : {
				myActionId: "<%=myActionId%>",
				actionId: "<%=actionId%>",
				flowId: "<%=flowId%>"
			},
			dataType: "html",
			beforeSend: function(XMLHttpRequest){
				o("spanLoad").innerHTML = "<img src='<%=request.getContextPath()%>/inc/ajaxtabs/loading.gif' />";	
			},
			success: function(data, status){
				o("spanLoad").innerHTML = "";
				$("#dlg").html(data);
				hideDesigner();				
				$("#dlg").dialog({title:"请选择需返回的用户", modal: true,
									buttons: {
										"取消":function() {
											$(this).dialog("close");
										},
										"确定": function() {
											// 必须要用clone，否则checked属性在IE9、chrome中会丢失
											// o("dlgReturn").innerHTML = $("#dlg").html();
											
											if (confirm('您确定要返回么？')) {
												// 因为radio是成组的，所以不能直接用$("#dlgReturn").html($("#dlg").clone())
												// 某一组radio只会有一个被选中，所以这里可能会导致第一次选中返回时报请选择用户，而刷新以后，再选择用户返回就可以了
												var tmp = $("#dlg").clone().html();
												$("#dlg").html();
												$("#dlgReturn").html(tmp);
												// alert($("#dlgReturn").html());
												
												flowForm.op.value='return';

												if (o('flowForm').onsubmit) {
													if (o('flowForm').onsubmit()) {
                                                        $('#bodyBox').showLoading();
														<%
                                                        if (lf.getType()==Leaf.TYPE_FREE) {
                                                        %>                                                        			
                                                        var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_free_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
                                                        <%}else{%>
                                                        var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
                                                        <%}%>
                                                        showResponse(data);
													}
												}
												else {
                                                    $('#bodyBox').showLoading();
													<%
                                                    if (lf.getType()==Leaf.TYPE_FREE) {
                                                    %>                                                    		
                                                    var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_free_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
                                                    <%}else{%>
                                                    var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
                                                    <%}%>
                                                    showResponse(data);
                                                }
											}
											$(this).dialog("close");
										}
									},
									closeOnEscape: true,
									draggable: true,
									resizable:true,
									width:500
								});
			},
			complete: function(XMLHttpRequest, status){
				//HideLoading();
			},
			error: function(XMLHttpRequest, textStatus){
				// 请求出错处理
				alert(XMLHttpRequest.responseText);
			}
		});	
	<%}else{%>
		$("#dlg").html(o("dlgReturn").innerHTML);
		hideDesigner();
		$("#dlg").dialog({title:"请选择需返回的用户", modal: true,
							buttons: {
								"取消":function() {
									$(this).dialog("close");
								},
								"确定": function() {
									$("#dlgReturn").html($("#dlg").clone());
									
									if (confirm('您确定要返回么？')) {
										flowForm.op.value='return';

										if (o('flowForm').onsubmit) {
											if (o('flowForm').onsubmit()) {
                                                $('#bodyBox').showLoading();
												<%
                                                if (lf.getType()==Leaf.TYPE_FREE) {
                                                %>                                                			
                                                var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_free_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
                                                <%}else{%>
                                                var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
                                                <%}%>
                                                showResponse(data);
											}
										}
										else {
                                              $('#bodyBox').showLoading();				
                                              var data = TANGER_OCX.SaveToURL("<%=Global.getFullRootPath(request)%>/flow_dispose_do.jsp", "<%=ntkoFieldName%>", "", "<%=att.getName()%>", "flowForm");
                                              showResponse(data);
                                        }
									}
									$(this).dialog("close");
								}							
							}, 
							closeOnEscape: true,
							draggable: true, 
							resizable:true,
							width:500
						});
	<%}%>
}
<%}%>

function replaceText()
{
	<%
	FormDb fd = new FormDb();
	fd = fd.getFormDb(lf.getFormCode());	
	Iterator irff = fd.getFields().iterator();
	while (irff.hasNext()) {
		FormField ff = (FormField)irff.next();
		%>
		var obj = o("<%=ff.getName()%>"); // document.getElementById(bname);
		if (obj) {
			var val = "";
			if (obj.value)
				val = obj.value;
			else
				val = obj.innerHTML;
				
			var bookmarkname = "<%=ff.getName()%>";
			if(TANGER_OCX.ActiveDocument.BookMarks.Exists(bookmarkname)) { 
				TANGER_OCX.SetBookmarkValue(bookmarkname, val);
			}
		}
		<%
	}
	%>	
    
    rangeWord = TANGER_OCX.ActiveDocument.Content; // 获取当前文档文字部分
	<%
	irff = fd.getFields().iterator();
	while (irff.hasNext()) {
		FormField ff = (FormField)irff.next();
		%>
		var obj = o("<%=ff.getName()%>"); // document.getElementById(bname);
		if (obj) {
			var val = "";
			if (obj.value)
				val = obj.value;
			else
				val = obj.innerHTML;
			searchStr = "【<%=ff.getTitle()%>】";
			rangeWord.Find.Execute(searchStr,false,false,false,false,false,true,1,false,val,2); // 执行查找替换方法
		}
		<%
	}
	%>
}