package com.redmoon.forum.security.flood;

/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2003</p>
 * <p>Company: </p>
 * @author not attributable
 * @version 1.0
 */

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.net.URL;
import java.net.URLDecoder;

import javax.servlet.http.HttpServletRequest;

import org.jdom.Document;
import org.jdom.Element;
import org.jdom.input.SAXBuilder;
import org.jdom.output.Format;
import org.jdom.output.XMLOutputter;

import cn.js.fan.util.StrUtil;
import cn.js.fan.util.XMLProperties;
import cn.js.fan.web.SkinUtil;

import com.cloudwebsoft.framework.util.LogUtil;


/**
 *
 * <p>Title: 论坛防洪水攻击配置</p>
 *
 * <p>Description: </p>
 *
 * <p>Copyright: Copyright (c) 2005</p>
 *
 * <p>Company: </p>
 *
 * @author not attributable
 * @version 1.0
 */
public class FloodConfig {
    private XMLProperties properties;
    private final String CONFIG_FILENAME = "config_forum_flood.xml";
    private String cfgpath;
    Document doc = null;
    Element root = null;
    final String rootChild = "flood";
    public static FloodConfig config;
    private static Object initLock = new Object();

    public static FloodConfig getInstance() {
        if (config == null) {
            synchronized (initLock) {
                config = new FloodConfig();
                config.init();
            }
        }
        return config;
    }

    public void init() {
        URL cfgURL = getClass().getClassLoader().getResource(
                "/" + CONFIG_FILENAME);
        cfgpath = cfgURL.getFile();
        cfgpath = URLDecoder.decode(cfgpath);

        properties = new XMLProperties(cfgpath);

        SAXBuilder sb = new SAXBuilder();
        try {
            FileInputStream fin = new FileInputStream(cfgpath);
            doc = sb.build(fin);
            root = doc.getRootElement();
            fin.close();
        } catch (org.jdom.JDOMException e) {
            LogUtil.getLog(getClass()).error("Config:" + e.getMessage());
        } catch (java.io.IOException e) {
            LogUtil.getLog(getClass()).error("Config:" + e.getMessage());
        }
    }

    public void refresh() {
        init();
        properties.refresh();
    }

    public Element getRootElement() {
        return root;
    }

    public String getProperty(String name) {
        return properties.getProperty(name);
    }

    public int getIntProperty(String name) {
        String p = getProperty(name);
        if (StrUtil.isNumeric(p)) {
            return Integer.parseInt(p);
        } else
            return -65536;
    }

    public boolean getBooleanProperty(String name) {
        String p = getProperty(name);
        return p.equals("true");
    }

    public void setProperty(String name, String value) {
        properties.setProperty(name, value);
    }

    public String getDescription(String name) {
        Element which = root.getChild(rootChild).getChild(name);
        // System.out.println("name=" + name + " which=" + which);
        if (which == null)
            return null;
        return which.getAttribute("desc").getValue();
    }

    public String getDescription(HttpServletRequest request, String name) {
        return SkinUtil.LoadString(request, "res.config.config_forum_flood", name);
    }

    /**
     * 更新name项的值，并保存至文件
     * @param name String
     * @param value String
     * @return boolean
     */
    public boolean put(String name, String value) {
        Element which = root.getChild(rootChild).getChild(name);
        if (which == null)
            return false;
        which.setText(value);
        writemodify();
        return true;
    }

    public void writemodify() {
        String indent = "    ";
        Format format = Format.getPrettyFormat();
        format.setIndent(indent);
        format.setEncoding("utf-8");
        XMLOutputter outp = new XMLOutputter(format);
        try {
            FileOutputStream fout = new FileOutputStream(cfgpath);
            outp.output(doc, fout);
            fout.close();
        } catch (java.io.IOException e) {}
        refresh();
    }
}
