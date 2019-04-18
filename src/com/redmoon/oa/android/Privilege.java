package com.redmoon.oa.android;

import java.util.Date;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import cn.js.fan.security.ThreeDesUtil;
import cn.js.fan.util.HtmlUtil;
import cn.js.fan.util.ParamUtil;

import cn.js.fan.util.StrUtil;
import com.cloudwebsoft.framework.util.LogUtil;
import com.redmoon.dingding.service.user.UserService;
import com.redmoon.oa.LogDb;
import com.redmoon.oa.person.UserDb;
import com.redmoon.oa.sys.DebugUtil;
import com.redmoon.weixin.Config;
import com.redmoon.weixin.mgr.WXUserMgr;

public class Privilege {
    private String errMsg = "";

    // 判断skey是否过期
    public boolean Auth(String skey) {
		/*if (skey != null && !skey.equals("")) {
			CloudConfig cloudConfig = CloudConfig.getInstance();
			String str = ThreeDesUtil.decrypthexstr(cloudConfig.getProperty("key"), skey);
			int index = str.lastIndexOf("|");
			String otime = str.substring(index + 1, str.length());
			Date now = new Date();
			long defTime = now.getTime();
			long time = now.getTime() - StrUtil.toLong(otime, defTime);
			long time1 = time / 1000 / 60;
			if (time1 > 20) {
				return true;
			}

		}*/
        return false;
    }

    /**
     * 获得skey
     *
     * @param userName
     * @return
     * @Description:
     */
    public String getSkey(String userName) {
        CloudConfig cloudConfig = CloudConfig.getInstance();
        Date date = new Date();
        String skey = userName + "|" + "OA" + "|" + date.getTime();
        String key = cloudConfig.getProperty("key");
        String des = ThreeDesUtil.encrypt2hex(key, skey);
        return des;
    }

    // 取得用户所在的区域编码
    public String getUserUnitCode(String skey) {
        if (skey != null && !skey.equals("")) {
            String url;
            // url = new String(Base64.decodeBase64(skey.getBytes()));
            CloudConfig cloudConfig = CloudConfig.getInstance();
            url = ThreeDesUtil.decrypthexstr(cloudConfig.getProperty("key"), skey);
            int index = url.indexOf("|");
            String userName = url.substring(0, index);
            UserDb user = new UserDb();
            user = user.getUserDb(userName);
            return user.getUnitCode();

        }
        return "";
    }

    // 取得用户名
    public String getUserName(String skey) {
        userName = "";
        if (skey != null && !skey.equals("")) {
            String url;
            // url = new String(Base64.decodeBase64(skey.getBytes()));
            CloudConfig cloudConfig = CloudConfig.getInstance();
            url = ThreeDesUtil.decrypthexstr(cloudConfig.getProperty("key"), skey);
            int index = url.indexOf("|");
            if (index == -1) {
                return "";
            }
            userName = url.substring(0, index);
        }
        return userName;
    }

    public void doLogin(HttpServletRequest request, String sKey) {
        getUserName(sKey);
        HttpSession session = request.getSession();
        session.setAttribute(Constant.OA_NAME, userName);
        session.setAttribute(Constant.OA_UNITCODE, getUserUnitCode(sKey));
    }

    public boolean isUserLogin(HttpServletRequest request) {
        HttpSession session = request.getSession(true);
        String name = (String) session.getAttribute(Constant.OA_NAME);
        if (name == null)
            return false;
        else
            return true;
    }

    public boolean authDingDing(HttpServletRequest request) {
        String code = ParamUtil.get(request, "code");
        if (!code.equals("")) {
            UserService _userService = new UserService();
            UserDb _userDb = _userService.getUserByAvoidLogin(code);
            if (_userDb != null && _userDb.isLoaded()) {
                userName = _userDb.getName();
                String _dingding = StrUtil.getNullStr(_userDb.getDingding());
                if (_dingding.equals("")) {
                    _userDb.setDingding(code);
                    _userDb.save();
                }
            } else {
                return false;
            }
            skey = getSkey(userName);
            doLogin(request, skey);
            return true;
        } else {
            return false;
        }
    }

    public boolean auth(HttpServletRequest request) {
        // 先判断skey，如果为空，则有可能来自于微信的转发
        skey = ParamUtil.get(request, "skey");
        if (skey.equals("")) {
            // 发起流程也会传过来code，但因发起流程界面flow_initiate.jsp将转至flow_dispose.jsp?code=...
            // 而后者并非来自企业微信转发，所以当发起流程时skey不可能为空
            String code = ParamUtil.get(request, "code");
            if (!code.equals("")) {
                WXUserMgr wxUserMgr = new WXUserMgr();
                UserDb userDb = null;

                Config config = Config.getInstance();
                boolean isWork = config.getBooleanProperty("isWork");

                String agentId = "";
                if (isWork) {
                    // 企业微信
                    agentId = ParamUtil.get(request, "agentId");
                    if ("".equals(agentId)) {
                        agentId = (String) request.getAttribute("agentId");
                        if (agentId == null) {
                            agentId = config.getDefaultAgentId();
                        }
                    }
                    userDb = wxUserMgr.getUserByCode(agentId, code);
                } else {
                    // 微信企业号
                    userDb = wxUserMgr.getUserByCode(code);
                }
                if (userDb != null && userDb.isLoaded()) {
					// 如果用户已被禁用，则提示
					if (!userDb.isValid()) {
						errMsg = "帐户已被停用";
						return false;
					}
                    userName = userDb.getName();
                    // 记录登录日志
                    LogDb log = new LogDb();
                    log.setUserName(userDb.getName());
                    log.setType(LogDb.TYPE_LOGIN);
                    log.setDevice(LogDb.DEVICE_MOBILE);
                    log.setAction(com.redmoon.oa.LogUtil.get(request, "action_login"));
                    log.setIp(StrUtil.getIp(request));
                    log.setUnitCode(userDb.getUnitCode());
                    log.setRemark("企业微信");
                    log.create();
                } else {
                    DebugUtil.log(getClass(), "auth", "用户不存在，agentId=" + agentId + " code=" + code);
                    return false;
                }
                skey = getSkey(userName);
                doLogin(request, skey);
                return true;
            }

            // PC端调试
            com.redmoon.oa.pvg.Privilege pvg = new com.redmoon.oa.pvg.Privilege();
            if (pvg.isUserLogin(request)) {
                userName = pvg.getUser(request);
                skey = getSkey(userName);
                return true;
            }
        } else {
            // 如果已经登录，则不需要再验证
            if (isUserLogin(request)) {
                HttpSession session = request.getSession(true);
                userName = (String) session.getAttribute(Constant.OA_NAME);
                return true;
            }

            doLogin(request, skey);

			// 判断帐户是否已被停用
			UserDb user = new UserDb();
			user = user.getUserDb(userName);
			if (!user.isValid()) {
				errMsg = "帐户已被停用";
				return false;
			}

            if ("".equals(userName)) {
                return false;
            } else {
                return true;
            }
        }

        return false;
    }

    /**
     * @param skey the skey to set
     */
    public void setSkey(String skey) {
        this.skey = skey;
    }

    /**
     * @return the skey
     */
    public String getSkey() {
        return skey;
    }

    /**
     * @param userName the userName to set
     */
    public void setUserName(String userName) {
        this.userName = userName;
    }

    /**
     * @return the userName
     */
    public String getUserName() {
        return userName;
    }

    private String skey;
    private String userName;

    public String getErrMsg() {
        return errMsg;
    }

    public void setErrMsg(String errMsg) {
        this.errMsg = errMsg;
    }
}
