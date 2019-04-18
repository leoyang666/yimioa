<%@ page contentType="text/html; charset=utf-8" language="java" errorPage="" %>
<%@ page import = "cn.js.fan.util.*"%>
<%
String fieldName = ParamUtil.get(request, "fieldName");
String formCode = ParamUtil.get(request, "formCode");
%>
$(o("<%=fieldName%>")).change(function() {
	var fieldName = "<%=fieldName%>";
	var obj = this;
	if ($(this).val=="") {
		return;
	}
    $.ajax({
        type: "post",
        url: "<%=request.getContextPath()%>/module_check/checkEmail.do",
        data : {
			fieldName: "<%=fieldName%>",
			formCode: "<%=formCode%>",
            val: $(this).val()
        },
        dataType: "html",
        beforeSend: function(XMLHttpRequest) {
            // $('body').ShowLoading();
        },
        success: function(data, status) {
			data = $.parseJSON(data);
			if (data.ret==0) {
                $('#errMsgBox_' + fieldName).remove();
				$(obj).parent().append("<span id='errMsgBox_" + fieldName + "' class='LV_validation_message LV_invalid'>" + data.msg + "</span>");
			}
			else {
				$('#errMsgBox_' + fieldName).remove();
			}
        },
        complete: function(XMLHttpRequest, status) {
            // $('body').hideLoading();
        },
        error: function(XMLHttpRequest, textStatus) {
            // 请求出错处理
            alert(XMLHttpRequest.responseText);
        }
    });		    
}) 
