package com.redmoon.forum;

import java.io.IOException;
import java.util.*;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;

import cn.js.fan.util.*;
import com.redmoon.forum.plugin.*;
import com.redmoon.forum.plugin.base.*;
import com.redmoon.kit.util.FileUpload;
import org.apache.log4j.Logger;
import com.redmoon.forum.plugin2.Plugin2Mgr;
import com.redmoon.forum.plugin2.Plugin2Unit;
import cn.js.fan.web.SkinUtil;
import com.redmoon.kit.util.FileInfo;
import cn.js.fan.web.Global;
import java.io.File;
import com.redmoon.forum.message.MessageDb;
import com.redmoon.forum.person.UserPrivDb;
import com.redmoon.forum.person.UserDb;
import com.redmoon.forum.search.Indexer;
import com.cloudwebsoft.framework.util.LogUtil;
import com.cloudwebsoft.framework.db.JdbcTemplate;

/**
 *
 * <p>Title: 贴子操作代理类</p>
 *
 * <p>Description: </p>
 *
 * <p>Copyright: Copyright (c) 2006</p>
 *
 * <p>Company: </p>
 *
 * @author not attributable
 * @version 1.0
 */
public class MsgMgr {
    // public: connection parameters
    boolean debug = true;
    Privilege privilege;
    Logger logger = Logger.getLogger(MsgMgr.class.getName());
    public FileUpload fileUpload = null;

    public MsgMgr() {
        privilege = new Privilege();
    }

    public FileUpload doUpload(ServletContext application, HttpServletRequest request) throws
            ErrMsgException {
        Config cfg = Config.getInstance();
        int maxAttachmentSize = cfg.getIntProperty("forum.maxAttachmentSize");
        int maxAllFileSize = cfg.getIntProperty("forum.maxAllFileSize");

        MultiFileUpload fu = new MultiFileUpload();

        String userName = Privilege.getUser(request);

        UserPrivDb upd = new UserPrivDb();
        if (Privilege.isUserLogin(request)) {
            // 取得用户贴子最大所有上传文件尺寸
            upd = upd.getUserPrivDb(userName);
            // 如果不使用新用户的默认设置
            if (upd.getInt("is_default") == 0) {
                // 取得用户贴子上传单个文件最大尺寸
                maxAttachmentSize = upd.getInt("attach_size");
            }
        }

        fu.setMaxAllFileSize(maxAllFileSize); // 最大1500K
        fu.setMaxFileSize(maxAttachmentSize);

        // String[] ext = {"jpg", "gif", "zip", "rar", "doc", "rm", "avi",
        //            "bmp",
        //            "swf", "png", "mp3", "wmv", "rmvb", "wma", "xls", "txt", "wps", "css", "htm", "html"};
        // String[] ext = cfg.getProperty("forum.ext").split(",");

        String[] ext = StrUtil.split(cfg.getProperty("forum.ext"), ",");

        if (ext!=null)
            fu.setValidExtname(ext);

        int ret = 0;
        try {
            ret = fu.doUpload(application, request);
            fileUpload = fu;
            if (ret!=FileUpload.RET_SUCCESS) {
                throw new ErrMsgException(fu.getErrMessage(request));
            }
        } catch (IOException e) {
            logger.error("doUpload:" + e.getMessage());
            throw new ErrMsgException(e.getMessage());
        }

        String boardcode = StrUtil.getNullString(fu.getFieldValue("boardcode"));
        if (boardcode.equals(""))
            throw new ErrMsgException(LoadString(request, "err_need_board"));
        // $bug 判断能否上传附件 2006.12.18 oasis发现此BUG，能够上传的附件数目比实际值小1
        if (fu.getFiles().size()>0 || fu.getAttachments().size()>0) {
            if (!privilege.canUserUpload(request, boardcode)) {
                if (Privilege.isUserLogin(request))
                    throw new ErrMsgException(SkinUtil.LoadString(request,
                            "res.forum.MsgMgr", "err_upload_count_exceed") +
                                              upd.getAttachTodayUploadCount());
                else {
                    throw new ErrMsgException(SkinUtil.LoadString(request,
                            "res.forum.MsgMgr", "err_upload_priv"));
                }
            }
        }
        // 水印处理
        boolean waterMarkImg = cfg.getBooleanProperty("forum.waterMarkImg");
        boolean isNeedWatermark = true;
        if (cfg.getBooleanProperty("forum.waterMarkOptional"))
            isNeedWatermark = StrUtil.getNullStr(fu.getFieldValue("isNeedWaterMark")).equals("1");
        if (waterMarkImg && isNeedWatermark) {
            Vector files = fu.getFiles();
            com.redmoon.forum.ImageUtil iu = new com.redmoon.forum.ImageUtil();
            iu.setRealPath(Global.getRealPath());
            if (files.size() > 0) {
                Iterator ir = files.iterator();
                while (ir.hasNext()) {
                    FileInfo fi = (FileInfo) ir.next();
                    if (fi.getExt().equalsIgnoreCase("jpg") ||
                        fi.getExt().equalsIgnoreCase("jpeg")) {
                        iu.WaterMark(fi);
                    }
                }
            }
        }
        return fu;
    }

    public String[] uploadImg(ServletContext application, HttpServletRequest request) throws
            ErrMsgException {
        // if (!privilege.isUserLogin(request))
        //    throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.ERR_NOT_LOGIN));

        UserPrivDb upd = new UserPrivDb();
        upd = upd.getUserPrivDb(privilege.getUser(request));
        if (upd.getBoolean("attach_upload") && upd.getAttachTodayUploadCount()<upd.getInt("attach_day_count"))
            ;
        else {
            throw new ErrMsgException(SkinUtil.LoadString(request, "res.forum.MsgMgr", "err_upload_count_exceed") + upd.getAttachTodayUploadCount());
        }

        Config cfg = Config.getInstance();
        int maxAttachmentSize = cfg.getIntProperty("forum.maxAttachmentSize");
        int maxAllFileSize = cfg.getIntProperty("forum.maxAllFileSize");

        // 如果不使用新用户的默认设置
        if (upd.getInt("is_default")==0) {
            // 取得用户贴子最大所有上传文件尺寸
            maxAllFileSize = upd.getInt("attach_size");
        }

        MultiFileUpload fu = new MultiFileUpload();
        fu.setMaxAllFileSize(maxAllFileSize); // 最大1500K
        fu.setMaxFileSize(maxAttachmentSize);

        String[] ext = new String[] {"jpg", "gif", "png", "bmp"};
        if (ext!=null)
            fu.setValidExtname(ext);

        int ret = 0;
        try {
            ret = fu.doUpload(application, request);
            fileUpload = fu;
            if (ret!=fu.RET_SUCCESS) {
                throw new ErrMsgException(fu.getErrMessage(request));
            }
            if (!cn.js.fan.security.Form.isTokenValid(request, fu))
                throw new ErrMsgException(SkinUtil.LoadString(request, "res.forum.MsgMgr", "err_back_refresh"));
            if (fu.getFiles().size()==0)
                throw new ErrMsgException(SkinUtil.LoadString(request, "res.forum.MsgMgr", "err_upload_none"));
        } catch (IOException e) {
            logger.error("doUpload:" + e.getMessage());
            throw new ErrMsgException(e.getMessage());
        }

        // 水印处理
        boolean waterMarkImg = cfg.getBooleanProperty("forum.waterMarkImg");
        boolean isNeedWatermark = true;
        if (cfg.getBooleanProperty("forum.waterMarkOptional"))
            isNeedWatermark = StrUtil.getNullStr(fu.getFieldValue("isNeedWaterMark")).equals("1");
        if (waterMarkImg && isNeedWatermark) {
            Vector files = fu.getFiles();
            com.redmoon.forum.ImageUtil iu = new com.redmoon.forum.ImageUtil();
            iu.setRealPath(Global.getRealPath());
            if (files.size() > 0) {
                Iterator ir = files.iterator();
                if (ir.hasNext()) {
                    FileInfo fi = (FileInfo) ir.next();
                    if (fi.getExt().equalsIgnoreCase("jpg") ||
                        fi.getExt().equalsIgnoreCase("jpeg")) {
                        iu.WaterMark(fi);
                    }
                }
            }
        }

        Calendar cal = Calendar.getInstance();
        String year = "" + (cal.get(cal.YEAR));
        String month = "" + (cal.get(cal.MONTH) + 1);
        String virtualpath = year +
                             "/" +
                             month;

        String filepath = Global.getRealPath() + Config.getInstance().getAttachmentPath() + "/" +
                          virtualpath + "/";

        File f = new File(filepath);
        if (!f.isDirectory()) {
            f.mkdirs();
        }

        fu.setSavePath(filepath); // 设置保存的目录
        // logger.info(filepath);
        String[] re = null;
        Vector v = fu.getFiles();
        Iterator ir = v.iterator();
        int orders = 0;

        String attachmentBasePath = request.getContextPath() + "/" + Config.getInstance().getAttachmentPath() + "/";
        boolean isFtpUsed = cfg.getBooleanProperty("forum.ftpUsed");
        FTPUtil ftp = new FTPUtil();
        if (isFtpUsed && v.size()>0) {
            boolean retFtp = ftp.connect(cfg.getProperty(
                    "forum.ftpServer"),
                                         cfg.getIntProperty("forum.ftpPort"),
                                         cfg.getProperty("forum.ftpUser"),
                                         cfg.getProperty("forum.ftpPwd"), true);
            if (!retFtp) {
                ftp.close();
                throw new ErrMsgException(ftp.getReplyMessage());
            }

            attachmentBasePath = cfg.getProperty("forum.ftpUrl");
            if (attachmentBasePath.lastIndexOf("/")!=attachmentBasePath.length()-1)
                attachmentBasePath += "/";
        }

        if (ir.hasNext()) {
            FileInfo fi = (FileInfo) ir.next();
            // 保存至磁盘相应路径
            String fname = FileUpload.getRandName() + "." +
                           fi.getExt();

            if (isFtpUsed) {
                try {
                    ftp.storeFile(virtualpath + "/" + fname, fi.getTmpFilePath());
                } catch (IOException e) {
                    LogUtil.getLog(getClass()).error("AddNew: storeFile - " +
                                                     e.getMessage());
                }
            } else {
                fi.write(fu.getSavePath(), fname);
            }

            // 记录于数据库
            Attachment att = new Attachment();
            att.setDiskName(fi.getDiskName());
            // logger.info(fpath);
            att.setMsgId(att.TEMP_MSG_ID);
            att.setName(fi.getName());
            att.setDiskName(fname);
            att.setOrders(orders);
            att.setVisualPath(virtualpath);
            att.setUploadDate(new java.util.Date());
            att.setSize(fi.getSize());
            att.setUserName(privilege.getUser(request));
            att.setExt(fi.getExt());
            att.setRemote(isFtpUsed);
            if (att.create()) {
                re = new String[2];
                re[0] = "" + att.getId();

                re[1] = attachmentBasePath + att.getVisualPath() + "/" + att.getDiskName();

                upd.addAttachTodayUploadCount(1);
            }
        }
        if (isFtpUsed && v.size()>0) {
            ftp.close();
        }

        return re;
    }

    /**
     * 以webedit的方式添加贴子
     * @param application ServletContext
     * @param request HttpServletRequest
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean AddNewWE(ServletContext application,
                            HttpServletRequest request) throws
            ErrMsgException {
        MultiFileUpload fu = (MultiFileUpload)doUpload(application, request);

        String boardcode;
        boardcode = fu.getFieldValue("boardcode");
        if (boardcode == null || boardcode.trim().equals(""))
            throw new ErrMsgException(LoadString(request, "err_need_board"));
        if (!privilege.canAddNew(request, boardcode, fu))
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));

        // 检查版块是否存在
        Leaf lf = new Leaf();
        lf = lf.getLeaf(boardcode);
        if (lf==null || !lf.isLoaded())
            throw new ErrMsgException(LoadString(request, "err_board_lost")); // "版块 " + boardcode + " 不存在！");

        // 插件的权限检查
        String pluginCode = StrUtil.getNullString(fu.getFieldValue("pluginCode"));
        boolean isPluginValid = false;
        PluginMgr pm = new PluginMgr();
        Vector vplugin = pm.getAllPluginUnitOfBoard(boardcode);
        if (vplugin.size() > 0) {
            Iterator irplugin = vplugin.iterator();
            while (irplugin.hasNext()) {
                PluginUnit pu = (PluginUnit) irplugin.next();
                IPluginPrivilege ipp = pu.getPrivilege();
                // logger.info("plugin name:" + pu.getName(request));
                if (!ipp.canAddNew(request, boardcode, fu)) {
                    String str = LoadString(request, "err_pvg_plugin");
                    str = str.replaceFirst("\\$p", pu.getName(request));
                    throw new ErrMsgException(str);
                }
                // 检查指定的pluginCode是否被允许
                if (!pluginCode.equals(""))
                    if (pu.getCode().equals(pluginCode))
                        isPluginValid = true;
            }
        }

        // 如果指定的pluginCode不被允许，则报错
        if (!pluginCode.equals("") && !isPluginValid) {
            throw new ErrMsgException(LoadString(request, "err_plugin_invalid"));
        }

        String name;
        if (privilege.isUserLogin(request))
            name = privilege.getUser(request); // cookiebean.getCookieValue(request, "name");
        else
            name = "";
        MsgDb md = new MsgDb();
        boolean re = false;
        try {
            re = md.AddNewWE(application, request, name, fu);
        } catch (ErrMsgException e) {
            throw e;
        }

        if (re) {
            id = md.getId();

            // 如果有plugin2Code传递过来
            String plugin2Code = StrUtil.getNullString(fu.getFieldValue("plugin2Code")).trim();
            if (!plugin2Code.equals("")) {
                Plugin2Mgr p2m = new Plugin2Mgr();
                Plugin2Unit p2u = p2m.getPlugin2Unit(plugin2Code);
                if (p2u!=null) {
                    try {
                        p2u.getMsgAction().AddNew(application, request, md, fu);
                    }
                    catch (ErrMsgException e) {
                        // 删除新发的贴子，但是贴子作者的相关经验值则不受影响
                        try {
                            md.delTopic(md.getId(), true);
                        }
                        catch (ResKeyException e1) {
                            logger.error("AddNewWE:" + e1.getMessage(request));
                        }
                        throw e;
                    }
                }
            }
        }

        if (re) {
            // 插件对应加入新贴的action
            if (vplugin.size() > 0) {
                Iterator irplugin = vplugin.iterator();
                while (irplugin.hasNext()) {
                    PluginUnit pu = (PluginUnit) irplugin.next();
                    boolean isPlugin = false;
                    if (pu.getType().equals(pu.TYPE_BOARD))
                        isPlugin = true;
                    else if (pu.getType().equals(pu.TYPE_TOPIC) && pluginCode.equals(pu.getCode()))
                        isPlugin = true;
                    if (isPlugin) {
                        IPluginMsgAction ipa = pu.getMsgAction();
                        try {
                            re = ipa.AddNew(application, request, md, fu);
                        } catch (ErrMsgException e) {
                            // 删除新发的贴子，但是贴子作者的相关经验值则不受影响
                            try {
                                md.delTopic(md.getId(), true);
                            } catch (ResKeyException e1) {
                                logger.error("AddNewWE:" +
                                             e1.getMessage(request));
                            }

                            throw e;
                        }
                    }
                }
            }
        }

        // 得分处理
        if (re) {
            if (privilege.isUserLogin(request)) {
                ScoreMgr sm = new ScoreMgr();
                Vector v = sm.getAllScore();
                Iterator ir = v.iterator();
                while (ir.hasNext()) {
                    ScoreUnit su = (ScoreUnit) ir.next();
                    IPluginScore ips = su.getScore();
                    if (ips != null)
                        ips.AddNew(application, request, md);
                }
            }
        }
        return true;
    }

    public String LoadString(HttpServletRequest request, String key) {
        return SkinUtil.LoadString(request, "res.forum.MsgMgr", key);
    }

    /**
     * 普通及UBB发贴
     * @param application ServletContext
     * @param request HttpServletRequest
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean AddNew(ServletContext application,
                          HttpServletRequest request) throws
            ErrMsgException {
        FileUpload fu = doUpload(application, request);

        String boardcode = StrUtil.getNullString(fu.getFieldValue("boardcode"));
        if (boardcode.equals(""))
            throw new ErrMsgException(LoadString(request, "err_need_board"));
        // 检查版块是否存在
        Leaf lf = new Leaf();
        lf = lf.getLeaf(boardcode);
        // System.out.println(getClass() + " boardcode=" + boardcode);
        if (lf == null || !lf.isLoaded())
            throw new ErrMsgException(LoadString(request, "err_board_lost")); // "版块 " + boardcode + " 不存在！");
        // 权限检查
        if (!privilege.canAddNew(request, boardcode, fu))
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));

        String pluginCode = StrUtil.getNullString(fu.getFieldValue("pluginCode"));

        String name;
        // 如果已登录，则先使用登录信息，如果未登录，则使用随表单一起发送的用户信息
        if (Privilege.isUserLogin(request))
            name = Privilege.getUser(request); // cookiebean.getCookieValue(request, "name");
        else
            name = "";
        boolean re = false;
        MsgDb msgDb = new MsgDb();
        try {
            re = msgDb.AddNew(application, request, name, fu);
            if (re) {
                id = msgDb.getId();
                blog = msgDb.isBlog();
                name = msgDb.getName();
            }
        }
        catch (ResKeyException e) {
            throw new ErrMsgException(e.getMessage(request));
        }

        if (re) {
            // 如果有plugin2Code传递过来
            String plugin2Code = StrUtil.getNullString(fu.getFieldValue("plugin2Code")).trim();
            if (!plugin2Code.equals("")) {
                Plugin2Mgr p2m = new Plugin2Mgr();
                Plugin2Unit p2u = p2m.getPlugin2Unit(plugin2Code);
                // logger.info("AddNew: p2u=" + p2u);
                if (p2u!=null) {
                    try {
                        p2u.getMsgAction().AddNew(application, request, msgDb,
                                                  fu);
                    }
                    catch (ErrMsgException e) {
                        // 删除新发的贴子，但是贴子作者的相关经验值则不受影响
                        try {
                            msgDb.delTopic(msgDb.getId(), true);
                        }
                        catch (ResKeyException e1) {
                            logger.error("AddNew:" + e1.getMessage(request));
                        }
                        throw e;
                    }
                }
            }
        }

        if (re) {
            PluginMgr pm = new PluginMgr();
            Vector vplugin = pm.getAllPluginUnitOfBoard(boardcode);
            // 插件对应加入新贴的action
            if (vplugin.size() > 0) {
                Iterator irplugin = vplugin.iterator();
                while (irplugin.hasNext()) {
                    PluginUnit pu = (PluginUnit) irplugin.next();
                    IPluginMsgAction ipa = pu.getMsgAction();
                    // logger.info("plugin name:" + pu.getName(request));
                    boolean isPlugin = false;
                    if (pu.getType().equals(pu.TYPE_BOARD))
                        isPlugin = true;
                    else if (pu.getType().equals(pu.TYPE_TOPIC) && pluginCode.equals(pu.getCode()))
                        isPlugin = true;
                    if (isPlugin) {
                        try {
                            re = ipa.AddNew(application, request, msgDb, fu);
                        } catch (ErrMsgException e) {
                            // 删除新发的贴子，但是贴子作者的相关经验值则不受影响
                            try {
                                msgDb.delTopic(msgDb.getId(), true);
                            } catch (ResKeyException e1) {
                                logger.error("AddNew:" + e1.getMessage(request));
                            }
                            throw e;
                        }
                    }
                }
            }
        }

        if (re) {
            if (privilege.isUserLogin(request)) {
                // 得分处理
                ScoreMgr sm = new ScoreMgr();
                Vector v = sm.getAllScore();
                Iterator ir = v.iterator();
                while (ir.hasNext()) {
                    ScoreUnit su = (ScoreUnit) ir.next();
                    IPluginScore ips = su.getScore();
                    if (ips != null)
                        ips.AddNew(application, request, msgDb);
                }
            }
        }
        return re;
    }

    public MsgDb getMsgDb(long id) {
        MsgDb md = new MsgDb();
        return md.getMsgDb(id);
    }

    /**
     * 普通及UBB方式发表回复
     * @param application ServletContext
     * @param request HttpServletRequest
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean AddReply(ServletContext application,
                            HttpServletRequest request) throws ErrMsgException {
        FileUpload fu = doUpload(application, request);
        String boardcode = StrUtil.getNullString(fu.getFieldValue("boardcode"));
        if (boardcode.equals(""))
            throw new ErrMsgException(LoadString(request, "err_need_board"));
        if (!privilege.canAddReply(request, boardcode, fu))
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));

        String name;
        if (privilege.isUserLogin(request))
            name = privilege.getUser(request); // cookiebean.getCookieValue(request, "name");
        else
            name = "";

        boolean re = false;
        MsgDb msgDb = new MsgDb();
        try {
            re = msgDb.AddReply(application, request, name, fu);
        } catch (ErrMsgException e) {
            throw e;
        }

        if (re) {
            id = msgDb.getId();

            // 插件对应加入回贴的action
            String pluginCode = StrUtil.getNullString(fu.getFieldValue("pluginCode"));

            PluginMgr pm = new PluginMgr();
            Vector vplugin = pm.getAllPluginUnitOfBoard(boardcode);
            if (vplugin.size() > 0) {
                Iterator irplugin = vplugin.iterator();
                while (irplugin.hasNext()) {
                    PluginUnit pu = (PluginUnit) irplugin.next();
                    boolean isPlugin = false;
                    if (pu.getType().equals(pu.TYPE_BOARD))
                        isPlugin = true;
                    else if (pu.getType().equals(pu.TYPE_TOPIC) && pluginCode.equals(pu.getCode()))
                        isPlugin = true;
                    if (isPlugin) {
                        IPluginMsgAction ipa = pu.getMsgAction();
                        // logger.info("plugin name:" + pu.getName(request));
                        re = ipa.AddReply(application, request, msgDb, fu);
                    }
                }
            }
        }

        // 得分处理
        if (re) {
            if (privilege.isUserLogin(request)) {
                ScoreMgr sm = new ScoreMgr();
                Vector v = sm.getAllScore();
                Iterator ir = v.iterator();
                while (ir.hasNext()) {
                    ScoreUnit su = (ScoreUnit) ir.next();
                    IPluginScore ips = su.getScore();
                    if (ips != null)
                        ips.AddReply(application, request, msgDb);
                }
            }
        }

        return true;
    }

    /**
     * 高级方式回复
     * @param application ServletContext
     * @param request HttpServletRequest
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean AddReplyWE(ServletContext application,
                            HttpServletRequest request) throws ErrMsgException {
        MultiFileUpload fu = (MultiFileUpload)doUpload(application, request);
        String boardcode = StrUtil.getNullString(fu.getFieldValue("boardcode"));
        if (boardcode.equals(""))
            throw new ErrMsgException(LoadString(request, "err_need_board"));
        if (!privilege.canAddReply(request, boardcode, fu))
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));

        String name;
        if (privilege.isUserLogin(request))
            name = privilege.getUser(request);
        else
            name = "";

        boolean re = false;
        MsgDb msgDb = new MsgDb();
        try {
            re = msgDb.AddReplyWE(application, request, name, fu);
        } catch (ErrMsgException e) {
            throw e;
        }

        if (re) {
            id = msgDb.getId();

            // 插件对应加入回贴的action
            String pluginCode = StrUtil.getNullString(fu.getFieldValue("pluginCode"));

            PluginMgr pm = new PluginMgr();
            Vector vplugin = pm.getAllPluginUnitOfBoard(boardcode);
            if (vplugin.size() > 0) {
                Iterator irplugin = vplugin.iterator();
                while (irplugin.hasNext()) {
                    PluginUnit pu = (PluginUnit) irplugin.next();
                    boolean isPlugin = false;
                    if (pu.getType().equals(pu.TYPE_BOARD))
                        isPlugin = true;
                    else if (pu.getType().equals(pu.TYPE_TOPIC) && pluginCode.equals(pu.getCode()))
                        isPlugin = true;
                    if (isPlugin) {
                        IPluginMsgAction ipa = pu.getMsgAction();
                        // logger.info("plugin name:" + pu.getName(request));
                        re = ipa.AddReply(application, request, msgDb, fu);
                    }
                }
            }
        }

        // 得分处理
        if (re) {
            if (privilege.isUserLogin(request)) {
                ScoreMgr sm = new ScoreMgr();
                Vector v = sm.getAllScore();
                Iterator ir = v.iterator();
                while (ir.hasNext()) {
                    ScoreUnit su = (ScoreUnit) ir.next();
                    IPluginScore ips = su.getScore();
                    if (ips != null)
                        ips.AddReply(application, request, msgDb);
                }
            }
        }

        return true;
    }

    /**
     * 快速回复
     * @param application ServletContext
     * @param request HttpServletRequest
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean AddQuickReply(ServletContext application,
                                 HttpServletRequest request) throws
            ErrMsgException {
        long replyid = ParamUtil.getLong(request, "replyid");
        MsgDb md = getMsgDb(replyid);
        if (!privilege.canAddQuickReply(request, md.getboardcode(), md))
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID)); // "权限非法");

        String name;
        if (privilege.isUserLogin(request))
            name = privilege.getUser(request); // 不能放在canAddQuickReply之前，这样可能会使得取得的name值为空，而在isUserLogin()中当session过期后，可以根据cookie重新登录，但之前如果取name值的话，就会为空
        else
            name = "";
        MsgDb msgDb = new MsgDb();
        boolean re = msgDb.AddQuickReply(application, request, name);

        if (re) {
            id = msgDb.getId();

            String pluginCode = ParamUtil.get(request, "pluginCode");

            // 插件对应加入新贴的action
            PluginMgr pm = new PluginMgr();
            Vector vplugin = pm.getAllPluginUnitOfBoard(msgDb.getboardcode());
            if (vplugin.size() > 0) {
                Iterator irplugin = vplugin.iterator();
                while (irplugin.hasNext()) {
                    PluginUnit pu = (PluginUnit) irplugin.next();
                    boolean isPlugin = false;
                    if (pu.getType().equals(pu.TYPE_BOARD))
                        isPlugin = true;
                    else if (pu.getType().equals(pu.TYPE_TOPIC) && pluginCode.equals(pu.getCode()))
                        isPlugin = true;
                    if (isPlugin) {
                        IPluginMsgAction ipa = pu.getMsgAction();
                        // logger.info("plugin name:" + pu.getName(request));
                        re = ipa.AddQuickReply(application, request,
                                               msgDb.getId());
                    }
                }
            }
        }

        // 得分处理
        if (re) {
            if (privilege.isUserLogin(request)) {
                ScoreMgr sm = new ScoreMgr();
                Vector v = sm.getAllScore();
                Iterator ir = v.iterator();
                while (ir.hasNext()) {
                    ScoreUnit su = (ScoreUnit) ir.next();
                    IPluginScore ips = su.getScore();
                    // 类是否存在
                    if (ips != null)
                        ips.AddQuickReply(application, request, msgDb.getId());
                }
            }
        }
        return re;
    }
    
    /**
     * 从回收站中恢复贴子
     * @param request
     * @param id
     * @return
     * @throws ErrMsgException
     */
    public boolean resumeTopic(HttpServletRequest request, long id) throws ErrMsgException {
		boolean re = checkMsg(request, id, MsgDb.CHECK_STATUS_PASS);
		if (re) {
			try {
				MsgDb.afterResumeMsg(getMsgDb(id));
			}
			catch (ResKeyException e) {
				throw new ErrMsgException(e.getMessage(request));
			}
		}
		return re;
    }

    /**
     * 删贴，如果版块定义默认删至回收站，则将其置入回收站
     * @param application ServletContext
     * @param request HttpServletRequest
     * @param delId long
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean delTopic(ServletContext application,
                            HttpServletRequest request, long delId) throws
            ErrMsgException {
        // Privilege privilege = new Privilege();
        // if (!privilege.isUserLogin(request))
        //    throw new ErrMsgException(SkinUtil.LoadString(request, "err_not_login"));

        boolean isPluginValid = false;

        MsgDb msgDb = getMsgDb(delId);
        if (!msgDb.isLoaded())
            throw new ErrMsgException(LoadString(request, "err_topic_del_lost"));

        blog = msgDb.isBlog();

        PluginMgr pm = new PluginMgr();
        Vector vplugin = pm.getAllPluginUnitOfBoard(msgDb.getboardcode());
        if (vplugin.size() > 0) {
            Iterator irplugin = vplugin.iterator();
            while (irplugin.hasNext()) {
                PluginUnit pu = (PluginUnit) irplugin.next();
                IPluginPrivilege ipp = pu.getPrivilege();
                // logger.info("plugin name:" + pu.getName(request));
                if (!ipp.canManage(request, delId)) {
                    String s = LoadString(request, "err_pvg_plugin");
                    s = s.replaceFirst("\\$p", pu.getName(request));
                    throw new ErrMsgException(s);
                }
            }
            // 插件中用户有删除权限
            isPluginValid = true;
        }

        // 如果在插件的权限设置中允许管理，则不再检查用户是否为版主，反之则检查
        if (!isPluginValid) {
            if (!privilege.canDel(request, delId)) {
                throw new ErrMsgException(SkinUtil.LoadString(request,
                        SkinUtil.PVG_INVALID));
            }
        }

        Leaf lf = new Leaf();
        lf = lf.getLeaf(msgDb.getboardcode());
        boolean re = false;
        // 如果版块设置删除时放至回收站,判断lf!=null主要是为了处理垃圾数据
        if (lf!=null && lf.getDelMode() == lf.DEL_DUSTBIN) {
            try {
                // 删除至回收站
                re = msgDb.checkMsg(msgDb.CHECK_STATUS_DUSTBIN);

                if (re)
                	MsgDb.afterDeleteMsg(msgDb);
            } catch (ResKeyException e) {
                throw new ErrMsgException(e.getMessage(request));
            }
        }
        else {
            // 插件对应删贴的action
            if (vplugin.size() > 0) {
                Iterator irplugin = vplugin.iterator();
                while (irplugin.hasNext()) {
                    PluginUnit pu = (PluginUnit) irplugin.next();
                    IPluginMsgAction ipa = pu.getMsgAction();
                    // logger.info("plugin name:" + pu.getName(request));
                    ipa.delTopic(application, request, msgDb);
                }
            }

            // 删除贴子的plugin2插件
            String plugin2Code = msgDb.getPlugin2Code();
            if (!plugin2Code.equals("")) {
                Plugin2Mgr p2m = new Plugin2Mgr();
                Plugin2Unit p2u = p2m.getPlugin2Unit(plugin2Code);
                if (p2u != null) {
                    p2u.getMsgAction().delTopic(application, request, msgDb);
                }
            }

            try {
                // 删除贴子
                re = msgDb.delTopic(delId);
                
                MsgDb.afterDeleteMsg(msgDb);

                // 删除索引　@task:需优化，当删至回收站时对索引的同步删除及恢复
                Indexer idx = new Indexer();
                idx.delDocument(delId);
            } catch (ResKeyException e1) {
                throw new ErrMsgException(e1.getMessage(request));
            }
        }

        if (re) {
                // 操作记录
                try {
                    String manager = Privilege.isUserLogin(request) ?
                             Privilege.getUser(request) : "";
                    MsgOperateDb mod = new MsgOperateDb();
                    mod.create(new JdbcTemplate(), new Object[] {
                        new Long(SequenceMgr.nextID(SequenceMgr.TOPIC_OP)),
                                new Long(msgDb.getId()),
                                new Integer(MsgOperateDb.OP_TYPE_DEL), null,
                                manager,
                                new java.util.Date(),msgDb.getTitle(),msgDb.getName(),msgDb.getAddDate(),msgDb.getboardcode(), request.getRemoteAddr()
                    });
                } catch (ResKeyException e) {
                    throw new ErrMsgException(e.getMessage(request));
            }
            Config cfg = Config.getInstance();
            if (cfg.getBooleanProperty("forum.sendMsgToUserOnDelTopic")) {
                boolean isSend = true;
                // 发送短消息提醒用户主题被删除
                String s = SkinUtil.LoadString(request, "res.forum.MsgDb",
                                               "shortmsg_del_topic_content");
                if (!privilege.isUserLogin(request)) {
                    s = StrUtil.format(s, new Object[] {msgDb.getTitle(),
                                       UserDb.ADMIN}); // @task
                } else {
                    UserDb ud = new UserDb();
                    ud = ud.getUser(privilege.getUser(request));
                    s = StrUtil.format(s, new Object[] {msgDb.getTitle(),
                                       ud.getNick()});

                    BoardManagerDb bmd = privilege.getUserManagerIdentityOfBoard(request, msgDb.getboardcode());
                    if (bmd!=null) { // 为null则管理者身份是master
                        // 版主可能为本版版主，也可能是上级版主
                        if (bmd.isHide())
                            isSend = false;
                    }
                }
                if (isSend) {
                    String reason = ParamUtil.get(request, "reason");
                    if (!reason.equals("")) {
                        s +=
                                StrUtil.format(SkinUtil.LoadString(request,
                                "res.forum.MsgDb",
                                "op_reason"), new Object[] {reason});
                    }

                    MessageDb msg = new MessageDb();
                    msg.setTitle(SkinUtil.LoadString(request, "res.forum.MsgDb",
                            "shortmsg_del_topic_title"));
                    msg.setContent(s);
                    // System.out.println(getClass() + " s=" + s + " receiver=" + msgDb.getName());

                    msg.setSender(MessageDb.USER_SYSTEM);
                    msg.setReceiver(msgDb.getName());
                    msg.setIp(request.getRemoteAddr());
                    msg.setType(msg.TYPE_SYSTEM);
                    msg.create();
                }
            }
        }

        return re;
    }

    /**
     * 彻底删除贴子，用于回收站中的删除操作及批理处理等
     * @param application ServletContext
     * @param request HttpServletRequest
     * @param delId long
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean delTopicAbsolutely(ServletContext application,
                            HttpServletRequest request, long delId) throws
            ErrMsgException {
        // Privilege privilege = new Privilege();
        // if (!privilege.isUserLogin(request))
        //    throw new ErrMsgException(SkinUtil.LoadString(request, "err_not_login"));

        boolean isPluginValid = false;

        MsgDb msgDb = getMsgDb(delId);
        if (!msgDb.isLoaded())
            throw new ErrMsgException(LoadString(request, "err_topic_del_lost"));

        blog = msgDb.isBlog();

        PluginMgr pm = new PluginMgr();
        Vector vplugin = pm.getAllPluginUnitOfBoard(msgDb.getboardcode());
        if (vplugin.size() > 0) {
            Iterator irplugin = vplugin.iterator();
            while (irplugin.hasNext()) {
                PluginUnit pu = (PluginUnit) irplugin.next();
                IPluginPrivilege ipp = pu.getPrivilege();
                // logger.info("plugin name:" + pu.getName(request));
                if (!ipp.canManage(request, delId)) {
                    String s = LoadString(request, "err_pvg_plugin");
                    s = s.replaceFirst("\\$p", pu.getName(request));
                    throw new ErrMsgException(s);
                }
            }
            isPluginValid = true;
        }

        // 如果在插件的权限设置中允许管理，则不再检查用户是否为版主，反之则检查
        if (!isPluginValid) {
            if (!privilege.canDel(request, delId)) {
                throw new ErrMsgException(SkinUtil.LoadString(request,
                        SkinUtil.PVG_INVALID));
            }
        }

        // 插件对应删贴的action
        if (vplugin.size() > 0) {
            Iterator irplugin = vplugin.iterator();
            while (irplugin.hasNext()) {
                PluginUnit pu = (PluginUnit) irplugin.next();
                IPluginMsgAction ipa = pu.getMsgAction();
                // logger.info("plugin name:" + pu.getName(request));
                ipa.delTopic(application, request, msgDb);
            }
        }

        // 删除贴子的plugin2插件
        String plugin2Code = msgDb.getPlugin2Code();
        if (!plugin2Code.equals("")) {
            Plugin2Mgr p2m = new Plugin2Mgr();
            Plugin2Unit p2u = p2m.getPlugin2Unit(plugin2Code);
            if (p2u != null) {
                p2u.getMsgAction().delTopic(application, request, msgDb);
            }
        }

        boolean re = false;
        try {
            re = msgDb.delTopic(delId);
            
            MsgDb.afterDeleteMsg(msgDb);

            Config cfg = Config.getInstance();
            if (cfg.getBooleanProperty("forum.sendMsgToUserOnDelTopic")) {
                boolean isSend = true;
                // 发送短消息提醒用户主题被删除
                String s = SkinUtil.LoadString(request, "res.forum.MsgDb",
                                               "shortmsg_del_topic_content");
                if (!Privilege.isUserLogin(request)) {
                    s = StrUtil.format(s, new Object[] {msgDb.getTitle(),
                                       UserDb.ADMIN}); // @task
                } else {
                    UserDb ud = new UserDb();
                    ud = ud.getUser(privilege.getUser(request));
                    s = StrUtil.format(s, new Object[] {msgDb.getTitle(),
                                       ud.getNick()});

                    BoardManagerDb bmd = privilege.getUserManagerIdentityOfBoard(request, msgDb.getboardcode());
                    if (bmd!=null) { // 为null则管理者身份是master
                        // 版主可能为本版版主，也可能是上级版主
                        if (bmd.isHide())
                            isSend = false;
                    }
                }
                if (isSend) {
                    MessageDb msg = new MessageDb();
                    msg.setTitle(SkinUtil.LoadString(request, "res.forum.MsgDb",
                            "shortmsg_del_topic_title"));
                    msg.setContent(s);
                    msg.setSender(msg.USER_SYSTEM);
                    msg.setReceiver(msgDb.getName());
                    msg.setIp(StrUtil.getIp(request));
                    msg.setType(msg.TYPE_SYSTEM);
                    msg.create();
                }
            }
            if (re) {
                // 删除索引　@task:需优化，当删至回收站时对索引的同步删除及恢复
                Indexer idx = new Indexer();
                idx.delDocument(delId);
            }
        } catch (ResKeyException e1) {
            logger.error("delTopic:" + e1.getMessage(request));
        }

        return re;
    }

    /**
     * 管理员或版主操作置顶
     * @param request HttpServletRequest
     * @param id long
     * @param value int
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean setOnTop(HttpServletRequest request, long id, int value) throws ErrMsgException {
        if (!privilege.canManage(request, id)) {
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));
        }

        if (value==MsgDb.LEVEL_TOP_FORUM) {
            if (!privilege.isMasterLogin(request)) {
                throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));
            }
        }
        String strExpire = ParamUtil.get(request, "levelExpire");
        Date levelExpire = DateUtil.parse(strExpire, "yyyy-MM-dd HH:mm:ss");

        // 如果levelExpire为空，则会使得当调度刷新到期时间时，因为DateUtil.toLongString(levelExpire)为0值，会使得被清除置顶
        if (levelExpire==null) {
            levelExpire = DateUtil.addDate(new java.util.Date(), 365); // 默认置顶365天
        }
        return setOnTop(request, id, value, levelExpire);
    }

    /**
     * 置顶操作，当使用灌水宝贝时，需调用此方法
     * @param request HttpServletRequest
     * @param id long
     * @param value int
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean setOnTop(HttpServletRequest request, long id, int value, Date levelExpire) throws
            ErrMsgException {
        boolean re = false;

        MsgDb msg = getMsgDb(id);
        int oldlevel = msg.getLevel();
        try {
            re = msg.setOnTop(value, levelExpire);
            if (re) {
                MsgOperateDb mod = new MsgOperateDb();
                int op_type;
                if (msg.getLevel() == MsgDb.LEVEL_TOP_BOARD)
                    op_type = MsgOperateDb.OP_TYPE_TOP_BOARD;
                else if (msg.getLevel() == MsgDb.LEVEL_TOP_FORUM)
                    op_type = MsgOperateDb.OP_TYPE_TOP_FORUM;
                else
                    op_type = MsgOperateDb.OP_TYPE_TOP_CANCEL;

                String userName = privilege.isUserLogin(request)?privilege.getUser(request):"";

                mod.create(new JdbcTemplate(), new Object[] {
                    new Long(SequenceMgr.nextID(SequenceMgr.TOPIC_OP)), new Long(id),
                            new Integer(op_type), levelExpire, userName,
                            new java.util.Date(), msg.getTitle(), msg.getName(),
                            msg.getAddDate(), msg.getboardcode(), StrUtil.getIp(request)
                });
            }
        }
        catch (ResKeyException e) {
            throw new ErrMsgException(e.getMessage(request));
        }
        if (re) {
            if (msg.getLevel()==MsgDb.LEVEL_TOP_BOARD || msg.getLevel()==MsgDb.LEVEL_TOP_FORUM) {
                // 发送短消息提醒用户主题被置顶
                MessageDb shortmsg = new MessageDb();
                shortmsg.setTitle(SkinUtil.LoadString(request, "res.forum.MsgDb",
                                                 "shortmsg_set_ontop_title"));
                String s = SkinUtil.LoadString(request, "res.forum.MsgDb",
                                               "shortmsg_set_ontop_content");
                String nick;
                if (privilege.isUserLogin(request)) {
                    UserDb ud = new UserDb();
                    ud = ud.getUser(privilege.getUser(request));
                    nick = ud.getNick();
                }
                else {
                    nick = UserDb.ADMIN;
                }
                s = StrUtil.format(s, new Object[] {msg.getTitle(),
                                   nick});

                String reason = ParamUtil.get(request, "reason");
                if (!reason.equals("")) {
                    s +=
                            StrUtil.format(SkinUtil.LoadString(request,
                            "res.forum.MsgDb",
                            "op_reason"), new Object[] {reason});
                }

                shortmsg.setContent(s);
                shortmsg.setSender(shortmsg.USER_SYSTEM);
                shortmsg.setReceiver(msg.getName());
                shortmsg.setIp(StrUtil.getIp(request));
                shortmsg.setType(shortmsg.TYPE_SYSTEM);
                shortmsg.create();
            }
        }
        if (re && oldlevel == MsgDb.LEVEL_TOP_FORUM ||
            value == MsgDb.LEVEL_TOP_FORUM) {
            ForumCache rc = new ForumCache(new ForumDb());
            rc.refreshTopMsgs();
        }
        return re;
    }

    /**
     * 锁定贴子
     * @param request HttpServletRequest
     * @param id long
     * @param value int
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean setLocked(HttpServletRequest request, long id,
                             int value) throws ErrMsgException {
        MsgDb msgDb = getMsgDb(id);
        if (!privilege.canEdit(request, msgDb)) {
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));
        }

        boolean re = false;
        try {
            re = msgDb.setLocked(id, value);
        }
        catch (ResKeyException e) {
            throw new ErrMsgException(e.getMessage(request));
        }
        return re;
    }

    /**
     * 更改贴子的版块
     * @param request HttpServletRequest
     * @param id long
     * @param newboardcode String
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean ChangeBoard(HttpServletRequest request, long id,
                               String newboardcode) throws ErrMsgException {
        if (!privilege.canManage(request, id)) {
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));
        }
        MsgDb msgDb = new MsgDb();
        String userName = privilege.isUserLogin(request)?privilege.getUser(request):"";
        return msgDb.ChangeBoard(request, id, newboardcode, userName);
    }

    /**
     * 升降贴子
     * @param request HttpServletRequest
     * @param id long
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean riseOrFallTopic(HttpServletRequest request, long id) throws
            ErrMsgException {
        if (!privilege.canManage(request, id)) {
            throw new ErrMsgException(SkinUtil.LoadString(request,
                    SkinUtil.PVG_INVALID));
        }
        MsgDb msgDb = new MsgDb();
        msgDb = msgDb.getMsgDb(id);
        if (!msgDb.isLoaded())
            return false;
        String sRedate = ParamUtil.get(request, "redate");
        java.util.Date d = DateUtil.parse(sRedate, "yyyy-MM-dd HH:mm:ss");
        if (d == null)
             throw new ErrMsgException(SkinUtil.LoadString(request, "res.forum.MsgDb", "err_riseorfall_date"));

        java.util.Date oldRedate = msgDb.getRedate();
        boolean re = msgDb.riseOrFallTopic(request, id, d);
        if (re) {
            String manager = privilege.isUserLogin(request) ?
                             privilege.getUser(request) : "";
            // 操作记录
            try {
                int op = MsgOperateDb.OP_TYPE_FALL;
                if (DateUtil.compare(d, oldRedate)==1)
                    op = MsgOperateDb.OP_TYPE_RISE;

                MsgOperateDb mod = new MsgOperateDb();
                mod.create(new JdbcTemplate(), new Object[] {
                    new Long(SequenceMgr.nextID(SequenceMgr.TOPIC_OP)),
                            new Long(id),
                            new Integer(op), null,
                            manager,
                            new java.util.Date(),msgDb.getTitle(),msgDb.getName(),msgDb.getAddDate(),msgDb.getboardcode(), StrUtil.getIp(request)
                });
            } catch (ResKeyException e) {
                throw new ErrMsgException(e.getMessage(request));
            }
            // 发送短消息提醒用户
            MessageDb msg = new MessageDb();
            msg.setTitle(SkinUtil.LoadString(request, "res.forum.MsgDb",
                                             "shortmsg_riseorfall_title"));
            String s = SkinUtil.LoadString(request, "res.forum.MsgDb",
                                           "shortmsg_riseorfall_content");
            String reason = ParamUtil.get(request, "reason");

            boolean isSend = true;
            if (!privilege.isUserLogin(request)) {
                s = StrUtil.format(s, new Object[] {msgDb.getTitle(),
                                   UserDb.ADMIN,
                                   ForumSkin.formatDateTime(request,
                        msgDb.getRedate())});
            } else {
                UserDb ud = new UserDb();
                ud = ud.getUser(privilege.getUser(request));
                s = StrUtil.format(s, new Object[] {msgDb.getTitle(),
                                   ud.getNick(),
                                   ForumSkin.formatDateTime(request,
                        msgDb.getRedate())});

                BoardManagerDb bmd = privilege.getUserManagerIdentityOfBoard(
                        request, msgDb.getboardcode());
                if (bmd != null) { // 为null则管理者身份是master
                    // 版主可能为本版版主，也可能是上级版主
                    if (bmd.isHide())
                        isSend = false;
                }
            }
            if (isSend) {
                if (!reason.equals("")) {
                    s +=
                            StrUtil.format(SkinUtil.LoadString(request,
                            "res.forum.MsgDb",
                            "op_reason"), new Object[] {reason});
                }
                msg.setContent(s);
                msg.setSender(msg.USER_SYSTEM);
                msg.setReceiver(msgDb.getName());
                msg.setIp(StrUtil.getIp(request));
                msg.setType(msg.TYPE_SYSTEM);
                msg.create();
            }
        }
        return re;
    }

    /**
     * 合并贴子
     * @param request HttpServletRequest
     * @param id long
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean mergeTopic(ServletContext application, HttpServletRequest request) throws
            ErrMsgException {
        long fromId = ParamUtil.getLong(request, "fromId");
        long toId = ParamUtil.getLong(request, "toId");
        if (!privilege.canManage(request, fromId)) {
            throw new ErrMsgException(SkinUtil.LoadString(request,
                    SkinUtil.PVG_INVALID));
        }
        if (!privilege.canManage(request, toId)) {
            throw new ErrMsgException(SkinUtil.LoadString(request,
                    SkinUtil.PVG_INVALID));
        }
        MsgDb fromMd = getMsgDb(fromId);
        if (!fromMd.isLoaded())
            throw new ErrMsgException(SkinUtil.LoadString(request, "err_msg_lost"));

        MsgDb toMd = getMsgDb(toId);
        if (!toMd.isLoaded())
            throw new ErrMsgException(SkinUtil.LoadString(request, "err_msg_lost"));

        // 主题贴不能被合并至其跟贴
        if (toMd.getRootid()==fromMd.getId()) {
            throw new ErrMsgException(SkinUtil.LoadString(request, "res.forum.MsgDb", "err_merge_root_to_reply"));
        }

        // 被合并的是同一个贴子
        if (toMd.getId()==fromMd.getId()) {
            throw new ErrMsgException(SkinUtil.LoadString(request, "res.forum.MsgDb", "err_merge_equal"));
        }
        
        if (fromMd.getId()<toMd.getId()) {
        	throw new ErrMsgException(SkinUtil.LoadString(request, "res.forum.MsgDb", "err_merge_date"));
        }

		// 将fromMd的合并至toMd
		boolean re = toMd.mergeReplyMsgs(fromMd)>=0;

		// 删除贴子
		delTopic(application, request, fromMd.getId());

		if (re) {
            String manager = Privilege.isUserLogin(request) ?
            		Privilege.getUser(request) : "";
            // 操作记录
            try {
                MsgOperateDb mod = new MsgOperateDb();
                mod.create(new JdbcTemplate(), new Object[] {
                    new Long(SequenceMgr.nextID(SequenceMgr.TOPIC_OP)),
                            new Long(toMd.getId()),
                            new Integer(MsgOperateDb.OP_TYPE_MERGE), null,
                            manager,
                            new java.util.Date(),toMd.getTitle(),toMd.getName(),toMd.getAddDate(),toMd.getboardcode(), StrUtil.getIp(request)
                });
            } catch (ResKeyException e) {
                throw new ErrMsgException(e.getMessage(request));
            }
            // 发送短消息提醒用户
            MessageDb msg = new MessageDb();
            msg.setTitle(SkinUtil.LoadString(request, "res.forum.MsgDb",
                                             "shortmsg_merge_title"));
            String s = SkinUtil.LoadString(request, "res.forum.MsgDb",
                                           "shortmsg_merge_content");
            String reason = ParamUtil.get(request, "reason");

            boolean isSend = true;
            if (!Privilege.isUserLogin(request)) {
                s = StrUtil.format(s, new Object[] {fromMd.getTitle(),
                                   UserDb.ADMIN,
                                   toMd.getTitle()});
            } else {
                UserDb ud = new UserDb();
                ud = ud.getUser(privilege.getUser(request));
                s = StrUtil.format(s, new Object[] {fromMd.getTitle(),
                                   ud.getNick(),
                                   toMd.getTitle()});

                BoardManagerDb bmd = privilege.getUserManagerIdentityOfBoard(
                        request, fromMd.getboardcode());
                if (bmd != null) { // 为null则管理者身份是master
                    // 版主可能为本版版主，也可能是上级版主
                    if (bmd.isHide())
                        isSend = false;
                }
            }
            if (isSend) {
                if (!reason.equals("")) {
                    s +=
                            StrUtil.format(SkinUtil.LoadString(request,
                            "res.forum.MsgDb",
                            "op_reason"), new Object[] {reason});
                }
                msg.setContent(s);
                msg.setSender(msg.USER_SYSTEM);
                msg.setReceiver(fromMd.getName());
                msg.setIp(StrUtil.getIp(request));
                msg.setType(msg.TYPE_SYSTEM);
                msg.create();
            }
        }
        return re;
    }

    public boolean checkMsg(HttpServletRequest request, long id, int checkStatus) throws ErrMsgException {
        if (!privilege.canManage(request, id)) {
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));
        }
        boolean re = false;
        MsgDb msgDb = getMsgDb(id);
        try {
            re = msgDb.checkMsg(checkStatus);
            if (re) {
                String manager = privilege.isUserLogin(request)?privilege.getUser(request):"";        	
                MsgOperateDb mod = new MsgOperateDb();
                mod.create(new JdbcTemplate(), new Object[] {
                    new Long(SequenceMgr.nextID(SequenceMgr.TOPIC_OP)), new Long(id),
                            new Integer(MsgOperateDb.OP_TYPE_CHECK), null,
                            manager,
                            new java.util.Date(),msgDb.getTitle(),msgDb.getName(),msgDb.getAddDate(),msgDb.getboardcode(), StrUtil.getIp(request)
                });
            }            
        }
        catch (ResKeyException e) {
            throw new ErrMsgException(e.getMessage(request));
        }

        return re;
    }

    /**
     * 更换标题颜色
     * @param request HttpServletRequest
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean ChangeColor(HttpServletRequest request) throws
            ErrMsgException {
        long id = ParamUtil.getLong(request, "id");
        if (!privilege.canManage(request, id)) {
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));
        }

        String colorExpire = ParamUtil.get(request, "colorExpire");
        Date edate = null;
        try {
            edate = DateUtil.parse(colorExpire, "yyyy-MM-dd");
        }
        catch (Exception e) {
            logger.error("ChangeColor:" + e.getMessage());
        }
        if (edate==null)
            throw new ErrMsgException(LoadString(request, "err_expire_date"));

        String color = ParamUtil.get(request, "color");
        MsgDb msgDb = new MsgDb();
        msgDb = msgDb.getMsgDb(id);
        boolean re = false;
        String manager = privilege.isUserLogin(request)?privilege.getUser(request):"";
        try {
            re = msgDb.ChangeColor(manager, color, edate, StrUtil.getIp(request));
        }
        catch (ResKeyException e) {
            throw new ErrMsgException(e.getMessage(request));
        }
        return re;
    }

    /**
     * 标题加粗
     * @param request HttpServletRequest
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean ChangeBold(HttpServletRequest request) throws
            ErrMsgException {
        long id = ParamUtil.getLong(request, "id");
        if (!privilege.canManage(request, id)) {
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));
        }

        String boldExpire = ParamUtil.get(request, "boldExpire");
        Date edate = null;
        try {
            edate = DateUtil.parse(boldExpire, "yyyy-MM-dd");
        }
        catch (Exception e) {
            logger.error("ChangeBold:" + e.getMessage());
        }
        if (edate==null)
            throw new ErrMsgException(LoadString(request, "err_expire_date"));

        String sBold = ParamUtil.get(request, "isBold");
        int intBold = 0;
        if (!sBold.equals("")) {
            if (StrUtil.isNumeric(sBold))
                intBold = Integer.parseInt(sBold);
        }
        MsgDb msgDb = new MsgDb();
        msgDb = msgDb.getMsgDb(id);
        boolean re = false;
        String manager = privilege.isUserLogin(request)?privilege.getUser(request):"";
        try {
            re = msgDb.ChangeBold(manager, intBold, edate, StrUtil.getIp(request));
        }
        catch (ResKeyException e) {
            throw new ErrMsgException(e.getMessage(request));
        }
        return re;
    }

    /**
     * 置为精华
     * @param request HttpServletRequest
     * @param id long
     * @param value int
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean setElite(HttpServletRequest request, long id, int value) throws
            ErrMsgException {
        if (!privilege.canManage(request, id)) {
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));
        }
        MsgDb msgDb = new MsgDb();
        msgDb = msgDb.getMsgDb(id);
        boolean re = false;
        try {
            re = msgDb.setElite(value);
            if (re) {
                String userName = privilege.isUserLogin(request)?privilege.getUser(request):"";
                MsgOperateDb mod = new MsgOperateDb();
                mod.create(new JdbcTemplate(), new Object[] {
                    new Long(SequenceMgr.nextID(SequenceMgr.TOPIC_OP)),
                            new Long(id),
                            new Integer(value == 1 ? MsgOperateDb.OP_TYPE_ELITE :
                                        MsgOperateDb.OP_TYPE_ELITE_CANCEL), null,
                            userName,
                            new java.util.Date(), msgDb.getTitle(), name, msgDb.getAddDate(),
                            msgDb.getboardcode(), StrUtil.getIp(request)
                });
            }
            // 发送短消息提醒用户主题被置为精华
            if (value==1) {
                MessageDb shortmsg = new MessageDb();
                shortmsg.setTitle(SkinUtil.LoadString(request, "res.forum.MsgDb",
                                                      "shortmsg_set_elite_title"));
                String s = SkinUtil.LoadString(request, "res.forum.MsgDb",
                                               "shortmsg_set_elite_content");
                String nick;
                if (privilege.isUserLogin(request)) {
                    UserDb ud = new UserDb();
                    ud = ud.getUser(privilege.getUser(request));
                    nick = ud.getNick();
                }
                else {
                    nick = UserDb.ADMIN;
                }
                s = StrUtil.format(s, new Object[] {msgDb.getTitle(),
                                   nick});
                shortmsg.setContent(s);
                shortmsg.setSender(shortmsg.USER_SYSTEM);
                shortmsg.setReceiver(msgDb.getName());
                shortmsg.setIp(StrUtil.getIp(request));
                shortmsg.setType(shortmsg.TYPE_SYSTEM);
                shortmsg.create();
            }
        }
        catch (ResKeyException e) {
            throw new ErrMsgException(e.getMessage(request));
        }
        return re;
    }

    /**
     * 编辑高级方式发布的贴子
     * @param application ServletContext
     * @param request HttpServletRequest
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean editTopicWE(ServletContext application,
                               HttpServletRequest request) throws
            ErrMsgException {
        MultiFileUpload mfu = (MultiFileUpload)doUpload(application, request);

        String name, boardcode;
        boardcode = mfu.getFieldValue("boardcode");
        if (boardcode == null || boardcode.trim().equals(""))
            throw new ErrMsgException(LoadString(request, "err_need_board"));

        Privilege privilege = new Privilege();

        MsgDb md = new MsgDb();
        long editid = Long.parseLong(mfu.getFieldValue("editid"));
        md = md.getMsgDb(editid);
        if (md==null || !md.isLoaded())
            throw new ErrMsgException(SkinUtil.LoadString(request, "err_msg_lost"));

        if (!privilege.canEdit(request, md))
            return false;

        name = privilege.getUser(request);

        boolean re = md.editTopicWE(application, request, name, mfu);
        if (re)
            blog = md.isBlog();
        if (re) {
            // 编辑plugin2插件
            String plugin2Code = md.getPlugin2Code();
            if (!plugin2Code.equals("")) {
                Plugin2Mgr p2m = new Plugin2Mgr();
                Plugin2Unit p2u = p2m.getPlugin2Unit(plugin2Code);
                if (p2u != null) {
                    p2u.getMsgAction().editTopic(application, request, md,
                                                 mfu);
                }
            }
        }
        if (re) {
            // 插件对应编辑贴子的action
            String pluginCode = md.getRootMsgPluginCode();
            logger.info("edittopicwe:pluginCode=" + pluginCode);
            PluginMgr pm = new PluginMgr();
            Vector vplugin = pm.getAllPluginUnitOfBoard(boardcode);
            if (vplugin.size() > 0) {
                Iterator irplugin = vplugin.iterator();
                while (irplugin.hasNext()) {
                    PluginUnit pu = (PluginUnit) irplugin.next();
                    boolean isPlugin = false;
                    if (pu.getType().equals(pu.TYPE_BOARD))
                        isPlugin = true;
                    else if (pu.getType().equals(pu.TYPE_TOPIC) && pluginCode.equals(pu.getCode()))
                        isPlugin = true;
                    logger.info("edittopicwe: pu.getCode()=" + pu.getCode() + " pluginCode=" + pluginCode);
                    if (isPlugin) {
                        IPluginMsgAction ipa = pu.getMsgAction();
                        re = ipa.editTopic(application, request, md, mfu);
                    }
                }
            }
        }
        return re;
    }

    /**
     * 编辑普通及UBB方式发的贴子
     * @param application ServletContext
     * @param request HttpServletRequest
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean editTopic(ServletContext application,
                             HttpServletRequest request) throws ErrMsgException {
        Privilege privilege = new Privilege();
        if (!privilege.isUserLogin(request))
            throw new ErrMsgException(SkinUtil.LoadString(request, "err_not_login")); // "请先登录！");

        FileUpload fu = doUpload(application, request);
        String boardcode = fu.getFieldValue("boardcode");
        if (boardcode == null || boardcode.trim().equals(""))
            throw new ErrMsgException(LoadString(request, "err_need_board"));

        MsgDb md = new MsgDb();
        long editid = Long.parseLong(fu.getFieldValue("editid"));
        md = getMsgDb(editid);
        if (md==null || !md.isLoaded())
            throw new ErrMsgException(SkinUtil.LoadString(request, "err_msg_lost"));

        if (!privilege.canEdit(request, md))
            return false;

        String name = privilege.getUser(request);

        boolean re = md.editTopic(application, request, name, fu);
        if (re)
            blog = md.isBlog();

        if (re) {
            String plugin2Code = md.getPlugin2Code();
            if (!plugin2Code.equals("")) {
                Plugin2Mgr p2m = new Plugin2Mgr();
                Plugin2Unit p2u = p2m.getPlugin2Unit(plugin2Code);
                if (p2u != null) {
                    p2u.getMsgAction().editTopic(application, request, md,
                                                 fu);
                }
            }
        }

        if (re) {
            // 插件对应编辑贴子的action
            String pluginCode = md.getRootMsgPluginCode();

            PluginMgr pm = new PluginMgr();
            Vector vplugin = pm.getAllPluginUnitOfBoard(boardcode);
            if (vplugin.size() > 0) {
                Iterator irplugin = vplugin.iterator();
                while (irplugin.hasNext()) {
                    PluginUnit pu = (PluginUnit) irplugin.next();
                    boolean isPlugin = false;
                    if (pu.getType().equals(pu.TYPE_BOARD))
                        isPlugin = true;
                    else if (pu.getType().equals(pu.TYPE_TOPIC) && pluginCode.equals(pu.getCode()))
                        isPlugin = true;
                    if (isPlugin) {
                        IPluginMsgAction ipa = pu.getMsgAction();
                        // logger.info("plugin name:" + pu.getName(request));
                        re = ipa.editTopic(application, request, md, fu);
                    }
                }
            }
        }
        return re;
    }

    /**
     * 投票
     * @param request HttpServletRequest
     * @return boolean
     * @throws ErrMsgException
     */
    public boolean vote(HttpServletRequest request) throws ErrMsgException {
        long voteid = ParamUtil.getLong(request, "voteid");
        Privilege privilege = new Privilege();
        if (!privilege.isUserLogin(request))
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.ERR_NOT_LOGIN));
        String[] opts = ParamUtil.getParameters(request, "votesel");
        if (opts==null)
            throw new ErrMsgException(MsgDb.LoadString(request, "err_vote_none"));

        String name = privilege.getUser(request);

        MsgDb msgDb = getMsgDb(voteid);
        if (msgDb.getIsLocked()==1)
            throw new ErrMsgException(msgDb.LoadString(request, "err_locked")); // "该贴已被锁定!");

        if (!privilege.canVote(request, msgDb.getboardcode()))
            throw new ErrMsgException(SkinUtil.LoadString(request, SkinUtil.PVG_INVALID));

        MsgPollDb mpd = new MsgPollDb();
        mpd = (MsgPollDb)mpd.getQObjectDb(new Long(msgDb.getId()));

        Date d = mpd.getDate("expire_date");

        // 检查是否已过期
        if (d!=null) {
            if (DateUtil.compare(d, new java.util.Date()) != 1)
                throw new ErrMsgException(StrUtil.format(msgDb.LoadString(request,
                        "err_vote_expire"),
                                          new Object[] {ForumSkin.formatDate(request, d)}));
        }

        int len = opts.length;
        int max_choice = mpd.getInt("max_choice");
        if (len > max_choice) {
            throw new ErrMsgException(StrUtil.format(msgDb.LoadString(request,
                    "err_vote_max_count"),
                                          new Object[] {"" + max_choice}));
        }

        // 检查用户是否已投过票
        MsgPollOptionDb mpod = new MsgPollOptionDb();
        Vector v = mpd.getOptions(voteid);
        int optLen = v.size();
        for (int i=0; i<optLen; i++) {
            MsgPollOptionDb mo = mpod.getMsgPollOptionDb(voteid, i);
            String vote_user = StrUtil.getNullString(mo.getString("vote_user"));
            String[] ary = StrUtil.split(vote_user, ",");
            // System.out.println(getClass() + " ary=" + ary);
            if (ary!=null) {
                int len2 = ary.length;
                for (int k=0; k<len2; k++) {
                    if (ary[k].equals(name))
                        throw new ErrMsgException(SkinUtil.LoadString(request, "res.forum.MsgDb", "err_vote_repeat"));
                }
            }
        }

        boolean re = true;
        for (int i=0; i<len; i++) {
            MsgPollOptionDb mo = mpod.getMsgPollOptionDb(voteid, StrUtil.toInt(opts[i]));
            mo.set("vote_count", new Integer(mo.getInt("vote_count") + 1));
            String vote_user = StrUtil.getNullString(mo.getString("vote_user")).trim(); // sqlserver中可能为一个空格
            if (vote_user.equals(""))
                vote_user = name;
            else
                vote_user += "," + name;
            mo.set("vote_user", vote_user);
            try {
                re = mo.save();
            }
            catch (ResKeyException e) {
                throw new ErrMsgException(e.getMessage(request));
            }
        }

        return re;
    }

    public Vector getBoardManagers(String boardcode) {
        MsgDb msgDb = new MsgDb();
        return msgDb.getBoardManagers(boardcode);
    }

    public String getprivurl() {
        return fileUpload.getFieldValue("privurl");
    }

    public String getCurBoardCode() {
        String boardcode = StrUtil.getNullString(fileUpload.getFieldValue("boardcode"));
        return boardcode;
    }

    public void setId(long id) {
        this.id = id;
    }

    public void setBlog(boolean blog) {
        this.blog = blog;
    }

    public void setName(String name) {
        this.name = name;
    }

    public long getId() {
        return id;
    }

    public boolean isBlog() {
        return blog;
    }

    public String getName() {
        return name;
    }

    public FileUpload getFileUpload() {
        return fileUpload;
    }

    private long id = -1;
    private boolean blog;
    private String name;

}
