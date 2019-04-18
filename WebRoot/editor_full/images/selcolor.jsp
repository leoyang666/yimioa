<%@ page contentType="text/html;charset=utf-8" %>
<%@ taglib uri="/WEB-INF/tlds/LabelTag.tld" prefix="lt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML><HEAD><TITLE><lt:Label res="res.label.editor_full.selcolor" key="page_title"/></TITLE>
<META http-equiv=Content-Type content="text/html; charset=utf-8">
<LINK href="selcolor_files/pop.css" type=text/css rel=stylesheet>
<SCRIPT language=JavaScript>
var SelRGB = '#000000';
var DrRGB = '';
var SelGRAY = '120';

var hexch = new Array('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');

function ToHex(n)
{	var h, l;

	n = Math.round(n);
	l = n % 16;
	h = Math.floor((n / 16)) % 16;
	return (hexch[h] + hexch[l]);
}

function DoColor(c, l)
{ var r, g, b;

  r = '0x' + c.substring(1, 3);
  g = '0x' + c.substring(3, 5);
  b = '0x' + c.substring(5, 7);
  
  if(l > 120)
  {
    l = l - 120;

    r = (r * (120 - l) + 255 * l) / 120;
    g = (g * (120 - l) + 255 * l) / 120;
    b = (b * (120 - l) + 255 * l) / 120;
  }else
  {
    r = (r * l) / 120;
    g = (g * l) / 120;
    b = (b * l) / 120;
  }

  return '#' + ToHex(r) + ToHex(g) + ToHex(b);
}

function EndColor()
{ var i;

  if(DrRGB != SelRGB)
  {
    DrRGB = SelRGB;
    for(i = 0; i <= 30; i ++)
      GrayTable.rows(i).bgColor = DoColor(SelRGB, 240 - i * 8);
  }

  SelColor.value = DoColor(RGB.innerText, GRAY.innerText);
  ShowColor.bgColor = SelColor.value;
}
</SCRIPT>

<SCRIPT language=JavaScript event=onclick for=ColorTable>
  SelRGB = event.srcElement.bgColor;
  EndColor();
</SCRIPT>

<SCRIPT language=JavaScript event=onmouseover for=ColorTable>
  RGB.innerText = event.srcElement.bgColor.toUpperCase();
  EndColor();
</SCRIPT>

<SCRIPT language=JavaScript event=onmouseout for=ColorTable>
  RGB.innerText = SelRGB;
  EndColor();
</SCRIPT>

<SCRIPT language=JavaScript event=onclick for=GrayTable>
  SelGRAY = event.srcElement.title;
  EndColor();
</SCRIPT>

<SCRIPT language=JavaScript event=onmouseover for=GrayTable>
  GRAY.innerText = event.srcElement.title;
  EndColor();
</SCRIPT>

<SCRIPT language=JavaScript event=onmouseout for=GrayTable>
  GRAY.innerText = SelGRAY;
  EndColor();
</SCRIPT>

<SCRIPT language=JavaScript event=onclick for=Ok>
  window.returnValue = SelColor.value;
  window.close();
</SCRIPT>

<META content="MSHTML 6.00.3790.373" name=GENERATOR></HEAD>
<BODY bgColor=menu>
<DIV align=center>
<CENTER>
<TABLE cellSpacing=10 cellPadding=0 border=0>
  <TBODY>
  <TR>
    <TD>
      <TABLE id=ColorTable style="CURSOR: pointer" cellSpacing=0 cellPadding=0 
      border=0>
        <SCRIPT language=JavaScript>
function wc(r, g, b, n)
{
	r = ((r * 16 + r) * 3 * (15 - n) + 0x80 * n) / 15;
	g = ((g * 16 + g) * 3 * (15 - n) + 0x80 * n) / 15;
	b = ((b * 16 + b) * 3 * (15 - n) + 0x80 * n) / 15;

	document.write('<TD BGCOLOR=#' + ToHex(r) + ToHex(g) + ToHex(b) + ' height=8 width=8></TD>');
}

var cnum = new Array(1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0);

  for(i = 0; i < 16; i ++)
  {
     document.write('<TR>');
     for(j = 0; j < 30; j ++)
     {
     	n1 = j % 5;
     	n2 = Math.floor(j / 5) * 3;
     	n3 = n2 + 3;

     	wc((cnum[n3] * n1 + cnum[n2] * (5 - n1)),
     		(cnum[n3 + 1] * n1 + cnum[n2 + 1] * (5 - n1)),
     		(cnum[n3 + 2] * n1 + cnum[n2 + 2] * (5 - n1)), i);
     }

     document.writeln('</TR>');
  }
</SCRIPT>

        <TBODY></TBODY></TABLE></TD>
    <TD>
      <TABLE id=GrayTable style="CURSOR: hand" cellSpacing=0 cellPadding=0 
      border=0>
        <SCRIPT language=JavaScript>
  for(i = 255; i >= 0; i -= 8.5)
     document.write('<TR BGCOLOR=#' + ToHex(i) + ToHex(i) + ToHex(i) + '><TD TITLE=' + Math.floor(i * 16 / 17) + ' height=4 width=20></TD></TR>');
</SCRIPT>

        <TBODY></TBODY></TABLE></TD></TR></TBODY></TABLE></CENTER></DIV>
<DIV align=center>
<CENTER>
<TABLE cellSpacing=10 cellPadding=0 width="100%" border=0>
  <TBODY>
  <TR>
    <TD align=middle width=70 rowSpan=2>
      <TABLE id=ShowColor height=40 cellSpacing=0 cellPadding=0 width=50 
      bgColor=#000000 border=1>
        <TBODY>
        <TR>
          <TD></TD></TR></TBODY></TABLE></TD>
    <TD rowSpan=2><lt:Label res="res.label.editor_full.selcolor" key="base"/> <SPAN id=RGB>#000000</SPAN><BR><lt:Label res="res.label.editor_full.selcolor" key="light"/><SPAN 
      id=GRAY>120</SPAN><BR><lt:Label res="res.label.editor_full.selcolor" key="code"/> <INPUT id=SelColor size=7 value=#000000></TD>
    <TD width=50><BUTTON id=Ok type=submit><lt:Label res="res.common" key="ok"/></BUTTON></TD></TR>
  <TR>
    <TD width=50><BUTTON onclick=window.close();><lt:Label res="res.common" key="cancel"/></BUTTON></TD></TR></TBODY></TABLE></CENTER></DIV></BODY></HTML>
