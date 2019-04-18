<%@ page contentType="text/html; charset=utf-8" %>
<%@ page import="java.util.*" %>
<%@ page import="cn.js.fan.util.*" %>
<%@ page import="cn.js.fan.db.*" %>
<%@ page import="com.redmoon.oa.person.*" %>
<%@ page import="com.redmoon.oa.flow.*" %>
<%@ page import="com.redmoon.oa.dept.*" %>
<%@page import="com.redmoon.oa.ui.SkinMgr" %>
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>图像宏控件属性</title>
    <link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/css.css"/>
    <script src="../../../../js/jquery.js"></script>
    <script>
        $(function() {
            var win = window.opener;
            var desc = win.document.getElementById('orgvalue').value;
            if (desc=="") {
                desc = win.document.getElementById('description').value;
            }
            if (desc=="") {
                return;
            }
            if (desc.indexOf('{')==0) {
                var json = $.parseJSON(desc);
                $('#width').val(json.w);
                $('#height').val(json.h);
                $('#isOnlyCamera').prop("checked", json.isOnlyCamera);
            }
            else {
                var ary = desc.split(',');
                $('#width').val(ary[0]);
                if (ary.length==2) {
                    $('#height').val(ary[1]);
                }
            }
        })
    </script>
</head>
<body>
<jsp:useBean id="privilege" scope="page" class="com.redmoon.oa.pvg.Privilege"/>
<table width="100%" height="198" cellPadding="0" cellSpacing="0">
    <tbody>
    <tr>
        <td height="28" colspan="2" class="tabStyle_1_title">&nbsp;图像宏控件</td>
    </tr>
    <tr>
        <td width="15%" height="42" align="center">宽度</td>
        <td width="85%" align="left">
            <input id="width" name="width"/>
        </td>
    </tr>
    <tr>
      <td height="42" align="center">高度</td>
      <td align="left">
          <input id="height" name="height"/>
      </td>
    </tr>
    <tr>
      <td height="42" align="center">拍照</td>
      <td align="left">
          <input id="isOnlyCamera" name="isOnlyCamera" type="checkbox" value="1"/>
      手机端只允许拍照，不能选择照片上传（仅支持安卓） </td>
    </tr>
    <tr>
      <td height="42" colspan="2" align="center">
          <input type="button" class="btn" value="确定" onclick="ok()"/>
          &nbsp;&nbsp;
          <input type="button" class="btn" value="取消" onclick="window.close()"/>
      </td>
      </tr>
    </tbody>
</table>
</body>
<script language="javascript">
    function ok() {
        var json = {};
        json.w = $('#width').val();
        json.h = $('#height').val();
        json.isOnlyCamera = $('#isOnlyCamera').prop("checked");
        window.opener.setSequence(JSON.stringify(json), "");
        window.close();
    }
</script>
</html>