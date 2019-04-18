package com.redmoon.oa.xmpp;

/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2003</p>
 * <p>Company: </p>
 * @author not attributable
 * @version 1.0
 */

import org.jdom.*;
import org.jdom.output.*;
import org.jdom.input.*;
import java.io.*;
import java.net.URL;
import org.apache.log4j.Logger;
import java.net.URLDecoder;

public class Config {
    // public: constructor to load driver and connect db
    boolean debug = true;
    final String configxml = "config_lark.xml"; //同步配置文件
    String xmlpath = "";
    Document doc = null;
    Element root = null;
    Logger logger = Logger.getLogger(Config.class.getName());

    public Config() {
        URL confURL = getClass().getClassLoader().getResource(configxml);
        xmlpath = confURL.getFile();
        try {
            xmlpath = URLDecoder.decode(xmlpath, "utf-8");
        } catch (UnsupportedEncodingException ex) {
            ex.printStackTrace();
        }

        SAXBuilder sb = new SAXBuilder();
        try {
            FileInputStream fin = new FileInputStream(xmlpath);
            doc = sb.build(fin);
            root = doc.getRootElement();
            fin.close();
        } catch (org.jdom.JDOMException e) {} catch (java.io.IOException e) {
        }
    }

    public Element getRootElement() {
        return root;
    }

    public String getDescription(String name) {
        Element which = root.getChild("lark").getChild(name);
        // System.out.println("name=" + name + " which=" + which);
        if (which == null)
            return null;
        return which.getAttribute("desc").getValue();
    }

    public String get(String name) {
        Element which = root.getChild("lark").getChild(name);
        if (which == null)
            return null;
        return which.getText();
    }

    public int getInt(String elementName) {
        Element which = root.getChild("lark").getChild(elementName);
        if (which == null)
            return -1;
        int r = -1;
        try {
            r = Integer.parseInt(which.getText());
        } catch (Exception e) {
            logger.error("getInt:" + e.getMessage());
        }
        return r;
    }

    public boolean getBooleanProperty(String elementName) {
        Element which = root.getChild("lark").getChild(elementName);
        if (which == null)
            return false;
        return which.getText().equals("true");
    }

    public boolean put(String name, String value) {
        Element which = root.getChild("lark").getChild(name);
        if (which == null)
            return false;
        which.setText(value);
        writemodify();
        return true;
    }

    public void writemodify() {
        String indent = "    ";
        boolean newLines = true;
        // XMLOutputter outp = new XMLOutputter(indent, newLines, "gb2312");
        Format format = Format.getPrettyFormat();
        format.setIndent(indent);
        format.setEncoding("utf-8");
        XMLOutputter outp = new XMLOutputter(format);
        try {
            FileOutputStream fout = new FileOutputStream(xmlpath);
            outp.output(doc, fout);
            fout.close();
        } catch (java.io.IOException e) {}
    }
}
