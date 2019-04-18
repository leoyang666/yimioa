package com.redmoon.forum.music;

import java.util.*;

import javax.servlet.http.*;

import cn.js.fan.util.*;
import cn.js.fan.web.*;
import org.apache.log4j.*;

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

public class MusicDirMgr {
    String connname = "";
    Logger logger = Logger.getLogger(MusicDirMgr.class.getName());

    public MusicDirMgr() {
        connname = Global.getDefaultDB();
        if (connname.equals(""))
            logger.info("Directory:默认数据库名不能为空");
    }

    public boolean AddChild(HttpServletRequest request) throws
            ErrMsgException {
        String name = "", code = "", parent_code = "";
        name = ParamUtil.get(request, "name", false);
        if (name == null)
            throw new ErrMsgException("名称不能为空！");
        code = ParamUtil.get(request, "code").trim();
        if (code.equals(""))
            throw new ErrMsgException("编码不能为空！");
        if (!StrUtil.isSimpleCode(code))
            throw new ErrMsgException("编码请使用字母、数字、-或_！");

        parent_code = ParamUtil.get(request, "parent_code").trim();
        if (parent_code.equals(""))
            throw new ErrMsgException("父结点不能为空！");
        String description = ParamUtil.get(request, "description");
        int type = ParamUtil.getInt(request, "type");

        MusicDirDb lf = new MusicDirDb();
        lf.setName(name);
        lf.setCode(code);
        lf.setParentCode(parent_code);
        lf.setDescription(description);
        lf.setType(type);

        MusicDirDb dd = getMusicDirDb(parent_code);
        return dd.AddChild(lf);
    }

    public void del(String delcode) throws ErrMsgException {
        MusicDirDb lf = getMusicDirDb(delcode);
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
            throw new ErrMsgException("code与name项必填！");
        }
        String parentCode = ParamUtil.get(request, "parentCode");

        MusicDirDb leaf = getMusicDirDb(code);
        if (code.equals(parentCode)) {
            throw new ErrMsgException("请选择正确的父节点！");
        }
        if (!parentCode.equals(leaf.getParentCode())) {
            // 节点不能改变其父节点为其子节点
            MusicDirDb lf = getMusicDirDb(parentCode); // 取得新的父节点
            while (lf!=null && !lf.getCode().equals(lf.ROOTCODE)) {
                // 从parentCode节点往上遍历，如果找到leaf.getParentCode()则证明不合法
                String pCode = lf.getParentCode();
                if (pCode.equals(leaf.getCode()))
                    throw new ErrMsgException("不能将其子节点更改为父节点");
                lf = getMusicDirDb(pCode);
            }
        }

        leaf.setName(name);
        leaf.setDescription(description);
        leaf.setIsHome(isHome);
        leaf.setType(type);
        boolean re = false;
        if (parentCode.equals(leaf.getParentCode())) {
            logger.info("update:name=" + name);
            re = leaf.save();
        }
        else
            re = leaf.save(parentCode);

        return re;
    }

    public synchronized boolean move(HttpServletRequest request) throws
            ErrMsgException {
        String code = ParamUtil.get(request, "code", false);
        String direction = ParamUtil.get(request, "direction", false);
        if (code == null || direction == null) {
            throw new ErrMsgException("编码与方向项必填！");
        }

        MusicDirDb dd = getMusicDirDb(code);
        return dd.move(direction);
    }

    public MusicDirDb getMusicDirDb(String code) {
        MusicDirDb dd = new MusicDirDb();
        return dd.getMusicDirDb(code);
    }

    public MusicDirDb getBrother(String code, String direction) throws
            ErrMsgException {
        MusicDirDb dd = getMusicDirDb(code);
        return dd.getBrother(direction);
    }

    public Vector getChildren(String code) throws ErrMsgException {
        MusicDirDb dd = getMusicDirDb(code);
        return dd.getChildren();
    }


    /**
     * 修复因为BUG或者误操作致树形结构被破坏的问题
     */
    public void repairLeaf(MusicDirDb lf) {
        Vector children = lf.getChildren();
        // 重置孩子节点数
        lf.setChildCount(children.size());
        Iterator ir = children.iterator();
        int orders = 1;
        while (ir.hasNext()) {
            MusicDirDb lfch = (MusicDirDb)ir.next();
            // 重置孩子节点的排列顺序
            lfch.setOrders(orders);
            // System.out.println(getClass() + " leaf name=" + lfch.getName() + " orders=" + orders);

            lfch.save();
            orders ++;
        }
        // 重置层数
        int layer = 2;
        String parentCode = lf.getParentCode();
        if (lf.getCode().equals(lf.ROOTCODE)) {
            layer = 1;
        }
        else {
            if (parentCode.equals(lf.ROOTCODE))
                layer = 2;
            else {
                while (!parentCode.equals(lf.ROOTCODE)) {
                    // System.out.println(getClass() + "leaf parentCode=" + parentCode);
                    MusicDirDb parentLeaf = getMusicDirDb(parentCode);
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
        lf.save();
    }

    // 修复根结点为leaf的树
    public void repairTree(MusicDirDb leaf) throws Exception {
        // System.out.println(getClass() + "leaf name=" + leaf.getName());
        repairLeaf(leaf);
        Vector children = getChildren(leaf.getCode());
        int size = children.size();
        if (size == 0)
            return;

        Iterator ri = children.iterator();
        // 写跟贴
        while (ri.hasNext()) {
            MusicDirDb childlf = (MusicDirDb) ri.next();
            repairTree(childlf);
        }
        // 刷新缓存
        MusicDirCache dc = new MusicDirCache();
        dc.removeAllFromCache();
    }
}

