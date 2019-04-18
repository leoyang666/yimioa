package com.redmoon.oa.job;

import org.quartz.*;

import com.redmoon.oa.flow.MyActionDb;
import com.redmoon.oa.flow.WorkflowActionDb;
import com.redmoon.oa.flow.WorkflowMgr;
import cn.js.fan.util.ErrMsgException;
import com.redmoon.oa.flow.WorkflowPredefineDb;
import com.cloudwebsoft.framework.util.LogUtil;
import com.redmoon.oa.flow.Leaf;
import java.util.Vector;
import java.util.Iterator;
import com.redmoon.oa.person.UserDb;
import com.cloudwebsoft.framework.aop.ProxyFactory;
import com.cloudwebsoft.framework.aop.base.Advisor;
import com.cloudwebsoft.framework.aop.Pointcut.MethodNamePointcut;
import com.redmoon.oa.message.IMessage;
import com.redmoon.oa.message.MessageDb;
import com.redmoon.oa.message.MobileAfterAdvice;
import com.redmoon.oa.flow.WorkflowDb;
import com.redmoon.oa.sms.SMSFactory;
import com.redmoon.oa.sms.IMsgUtil;

/**
 * <p>Title: </p>
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
public class WorkflowJob implements Job {
    public WorkflowJob() {
    }

    /**
     * execute
     *
     * @param jobExecutionContext JobExecutionContext
     * @throws JobExecutionException
     * @todo Implement this org.quartz.Job method
     */
    public void execute(JobExecutionContext jobExecutionContext) throws
            JobExecutionException {
        JobDataMap data = jobExecutionContext.getJobDetail().getJobDataMap();
        String flowCode = data.getString("flowCode");
        // System.out.println(getClass() + " execute：flowCode = " + data.getString("flowCode"));

        Leaf lf = new Leaf();
        lf = lf.getLeaf(flowCode);

        WorkflowPredefineDb wpd = new WorkflowPredefineDb();
        wpd = wpd.getDefaultPredefineFlow(flowCode);
        boolean isPredefined = wpd != null && wpd.isLoaded();
        if (!isPredefined) {
            LogUtil.getLog(getClass()).error(flowCode + " 预定义流程不存在！");
            return;
        }

        Vector v = wpd.getStarters();
        if (v.size() == 0) {
            LogUtil.getLog(getClass()).error(lf.getName() +
                                             " 预定义流程中的发起者无效，不能用于调度！");
            return;
        }
        
        WorkflowDb wf = new WorkflowDb();
        MyActionDb mad = new MyActionDb();
        Iterator ir = v.iterator();
        WorkflowMgr wm = new WorkflowMgr();
        while (ir.hasNext()) {
            UserDb ud = (UserDb) ir.next();
            long myActionId = -1;
            try {
            	myActionId = wm.initWorkflow(ud.getName(), flowCode, lf.getName(), -1, WorkflowDb.LEVEL_NORMAL);
        		
            	mad = mad.getMyActionDb(myActionId);
                wf = wf.getWorkflowDb((int)mad.getFlowId());
        		wf.setStatus(WorkflowDb.STATUS_NOT_STARTED);
                wf.save();
            } catch (ErrMsgException e) {
                LogUtil.getLog(getClass()).error("execute:" + e.getMessage());
            }

            // 发送消息通知
            boolean isToMobile = SMSFactory.isUseSms;
            // 发送信息
            MessageDb md = new MessageDb();
            String t = "系统调度：" + lf.getName();
            String c = "系统已自动为您发起流程：" + lf.getName() + " 请及时办理！";
            try {
                String action = "action=" + MessageDb.ACTION_FLOW_DISPOSE + "|myActionId=" + myActionId;
                md.sendSysMsg(ud.getName(), t, c, action);

                if (isToMobile) {
                    IMsgUtil imu = SMSFactory.getMsgUtil();
                    if (imu != null) {
                        imu.send(ud, c, MessageDb.SENDER_SYSTEM);
                    }
                }
            }
            catch (ErrMsgException e) {
                LogUtil.getLog(getClass()).error("execute2:" + e.getMessage());
            }
        }
    }

}
