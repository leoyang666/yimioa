package com.redmoon.forum.plugin.group;

import java.sql.*;
import javax.servlet.http.*;
import cn.js.fan.db.*;
import cn.js.fan.security.*;
import cn.js.fan.util.*;
import cn.js.fan.web.*;
import org.apache.log4j.*;
import java.util.Vector;
import java.util.Iterator;

/**
 *
 * <p>Title: </p>
 *
 * <p>Description: </p>
 *
 * <p>Copyright: Copyright (c) 2004</p>
 *
 * <p>Company: </p>
 * ╋ 女性话题      一级目录
 *   ├『花样年华』  二级目录
 *   ├『花样年华』
 *   ╋ 女性话题     二级目录
 *     ├『花样年华』 三级目录
 * @author not attributable
 * @version 1.0
 */

public class Directory {
    String connname = "";
    Logger logger = Logger.getLogger(Directory.class.getName());

    public Directory() {
        connname = Global.getDefaultDB();
        if (connname.equals(""))
            logger.info("Catalog:DB is empty!");
    }

    public boolean AddChild(HttpServletRequest request) throws
            ErrMsgException {
        //取出被回复的贴子的有关信息
        int child_count = 0, orders = 1, parent_orders = 1,
                islocked = 0;
        String root_code = "", name = "", code = "", parent_code = "";

        name = ParamUtil.get(request, "name").trim();
        if (name == null || name.equals(""))
            throw new ErrMsgException(SkinUtil.LoadString(request,
                    "res.forum.plugin.group", "err_name")); //名称不能为空！
        code = ParamUtil.get(request, "code").trim();
        if (code.equals(""))
            throw new ErrMsgException(SkinUtil.LoadString(request,
                    "res.forum.plugin.group", "err_num")); //编码不能为空！

        parent_code = ParamUtil.get(request, "parent_code").trim();
        if (parent_code.equals(""))
            throw new ErrMsgException(SkinUtil.LoadString(request,
                    "res.forum.plugin.group", "err_parentCode")); //父结点不能为空！
        String description = ParamUtil.get(request, "description");
        int type = ParamUtil.getInt(request, "type");

        Leaf lf = new Leaf();
        lf = lf.getLeaf(code);
        if (lf != null && lf.isLoaded()) {
            String str = SkinUtil.LoadString(request, "res.forum.plugin.group",
                                             "err_codeIsExist");
            str = StrUtil.format(str, new Object[] {"" + lf.getName()});
            throw new ErrMsgException(str);
            //throw new ErrMsgException("已存在相同编码的节点：" + lf.getName());
        }
        lf = new Leaf();
        lf.setName(name);
        lf.setCode(code);
        lf.setParentCode(parent_code);
        lf.setDescription(description);
        lf.setType(type);

        Leaf leaf = getLeaf(parent_code);
        return leaf.AddChild(lf);
    }

    public void del(String delcode) throws ErrMsgException {
        Leaf lf = getLeaf(delcode);
        lf.del(lf);
    }

    public synchronized boolean update(HttpServletRequest request) throws
            ErrMsgException {
        String code = ParamUtil.get(request, "code", false);
        String name = ParamUtil.get(request, "name", false);
        String description = ParamUtil.get(request, "description");
        boolean isHome = ParamUtil.get(request, "isHome").equals("true") ? true : false;
        int type = ParamUtil.getInt(request, "type");
        if (code == null || name == null) {
            throw new ErrMsgException(SkinUtil.LoadString(request,
                    "res.forum.plugin.group", "err_codeName")); //code与name项必填！
        }
        int templateId = ParamUtil.getInt(request, "templateId");
        String parentCode = ParamUtil.get(request, "parentCode");

        Leaf leaf = getLeaf(code); //new Leaf();
        leaf.setName(name);
        leaf.setDescription(description);
        leaf.setIsHome(isHome);
        leaf.setType(type);
        leaf.setTemplateId(templateId);
        boolean re = false;
        if (parentCode.equals(leaf.getParentCode()))
            re = leaf.update();
        else
            re = leaf.update(parentCode);

        return re;
    }

    public synchronized boolean move(HttpServletRequest request) throws
            ErrMsgException {
        String code = ParamUtil.get(request, "code", false);
        String direction = ParamUtil.get(request, "direction", false);
        if (code == null || direction == null) {
            throw new ErrMsgException(SkinUtil.LoadString(request,
                    "res.forum.plugin.group", "err_codeDir")); //编码与方向项必填！
        }

        Leaf lf = new Leaf(code);
        return lf.move(direction);
    }

    public Leaf getLeaf(String code) {
        Leaf leaf = new Leaf();
        return leaf.getLeaf(code);
    }

    public Leaf getBrother(String code, String direction) throws
            ErrMsgException {
        Leaf lf = getLeaf(code);
        return lf.getBrother(direction);
    }

    public Vector getChildren(String code) throws ErrMsgException {
        Leaf leaf = getLeaf(code);
        return leaf.getChildren();
    }


    /**
     * 修复因为BUG或者误操作致树形结构被破坏的问题
     */
    public void repairLeaf(Leaf lf) {
        Vector children = lf.getChildren();
        // 重置孩子节点数
        lf.setChildCount(children.size());
        Iterator ir = children.iterator();
        int orders = 1;
        while (ir.hasNext()) {
            Leaf lfch = (Leaf) ir.next();
            // 重置孩子节点的排列顺序
            lfch.setOrders(orders);
            // System.out.println(getClass() + " leaf name=" + lfch.getName() + " orders=" + orders);

            lfch.update();
            orders++;
        }
        // 重置层数
        int layer = 2;
        String parentCode = lf.getParentCode();
        if (lf.getCode().equals(lf.CODE_ROOT)) {
            layer = 1;
        } else {
            if (parentCode.equals(lf.CODE_ROOT))
                layer = 2;
            else {
                while (!parentCode.equals(lf.CODE_ROOT)) {
                    // System.out.println(getClass() + "leaf parentCode=" + parentCode);
                    Leaf parentLeaf = getLeaf(parentCode);
                    if (parentLeaf == null || !parentLeaf.isLoaded())
                        break;
                    else {
                        parentCode = parentLeaf.getParentCode();
                    }
                    layer++;
                }
            }
        }
        lf.setLayer(layer);
        lf.update();
    }


    public void repairTree(Leaf leaf) throws Exception {
        // System.out.println(getClass() + "leaf name=" + leaf.getName());
        repairLeaf(leaf);
        Directory dir = new Directory();
        Vector children = dir.getChildren(leaf.getCode());
        int size = children.size();
        if (size == 0)
            return;

        Iterator ri = children.iterator();
        // 写跟贴
        while (ri.hasNext()) {
            Leaf childlf = (Leaf) ri.next();
            repairTree(childlf);
        }
        // 刷新缓存
        leaf.removeAllFromCache();
    }

}
