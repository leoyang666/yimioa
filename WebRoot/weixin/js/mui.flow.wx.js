(function($,window,document,undefined){
	$.ajaxSettings.beforeSend = function(xhr, setting) {
		jQuery.myloading();
	};
	// 设置全局complete
	$.ajaxSettings.complete = function(xhr, status) {

		jQuery.myloading("hide");
	}
	var w = window;
	var self ;
	var FATTEND_DETAIL_AJAX_URL = "../../public/android/flow/modify?";// 流程详情
	var FLOW_INIT_AJAX_URL = "../../public/android/flow/init?";// 流程处理详情界面
	var FLOW_DISPOSE_AJAX_URL = "../../public/android/flow/dispose?"// 流程处理
	var FREE_FLOW_DISPOSE_AJAX_URL= "../../public/flow_dispose_free_do.jsp";// 自由流程处理
	var PRESET_FLOW_DISPOSE_AJAX_URL= "../../public/flow_dispose_do.jsp";// 预定流程处理
	var FLOW_RETURN_AJAX_URL = "../../public/android/flow/getreturn";
	var FLOW_MULTI_DEPT="../../public/android/flow/multiDept";
	var Form;
	$.Flow = $.Class.extend({
		init: function(element, options) {
					 this.element = element,
					 this.default = {
						"formSelector":".mui-input-group",
						"ulSelector":".mui-table-view"
					 }
					 this.options = $.extend(true,this.default,options);
					 Form = new $.Form(this.element, this.options);
			 },
		flowAttendDetail:function(){
				 var self = this;
				 var skey = self.options.skey;
				 var flowId = self.options.flowId;
				 var ul = jQuery(self.options.ulSelector);
				 var datas = {"skey":skey,"flowId":flowId}
				 mui.post(FATTEND_DETAIL_AJAX_URL,datas,function(data){
					Form.initFlowDetail(data);
				 },"json");
		},
		flowDisposeInit:function(){  // 待办流程初始化接口 - 发起流程初始化接口
			var self = this;
			var content = self.element;
			var url = FLOW_DISPOSE_AJAX_URL;
			var skey = self.options.skey;
			// console.log('skey=' + skey);
			var flagXorRadiate = false;
			var datas ;
			 if(myActionId == 0){
				 var extraData = self.options.extraData;
				 extraData = $.parseJSON(extraData);
				 datas = {"skey":skey,"title":self.options.title,"code":self.options.code,"type":self.options.type}
				 // 合并
				 datas = $.extend({}, datas, extraData);
				 url =  FLOW_INIT_AJAX_URL;
			 }else{
				 datas = {"skey":skey,"myActionId":myActionId};
			 }
			 
			 $.post(url,datas,function(data){
				var res = data.res;
				if(res != '0' ){
					mui.toast(data.msg);
					return;
				}
				if(res == '0'){
					var actionId = data.actionId;
					var flowId = data.flowId;
					var annexs = data.result.annexs;
					var fields = data.result.fields;
					
					var isLight = data.isLight;
					var btnContent = self.flowDisposeBtn(data);
					flagXorRadiate  = data.flagXorRadiate;

					var myAId = data.myActionId;
					var cwsWorkflowTitle = data.cwsWorkflowTitle;
					var commonParams = self.flowDisposeCommonParam(flowId,myAId,actionId,skey,cwsWorkflowTitle);
					
					if(isLight){
						// @输入框
						var at_input_box = '';
						at_input_box += '<div data-isnull="false" data-code="cwsWorkflowResult"><span style="display:none">内容</span><textarea type="text" name="cwsWorkflowResult" id="cwsWorkflowResult" class="at_textarea" placeholder="说点什么吧~"/></div>';
						at_input_box += commonParams;
						at_input_box += '<div class="at_user_div clearfix">';
						at_input_box += '<a><span class="iconfont icon-at"></span><span>提醒谁看</span>';
						at_input_box += '<div class="userDiv"></div>';
						at_input_box += '</a>';
						at_input_box += '</div>';
						jQuery("#free_flow_form").append(at_input_box);
						jQuery("#free_flow_form").addClass("submitFlow");
						var annex = data.lightDetail; // 评论
						jQuery(".mui-content").append(Form.initAtStep(annex));
						
						jQuery(".mui-content").append(btnContent);
					}else{
						var title = data.cwsWorkflowTitle;// 标题
						var c_t = '<div class="mui-input-row">';
						c_t += '<label style="color:#000;width:100%;font-weight:bold">'+title+'</label>';
						c_t += '</div>';
						jQuery(".mui-input-group").append(c_t);
						if(fields.length>0){
							Form.initForms(actionId,flowId,fields);//初始化Form表单
						}
						if("files" in data.result){
							var _files = data.result.files;
							if(_files.length>0){
								var _ul = Form.flowInitFiles(_files);
								jQuery(".mui-input-group").append(_ul);
							}
						}
						
						if("users" in data.result){
							var users = data.result.users;
							if(users.length>0){
								var _flowNextUsers = self.flowNextUsers(flagXorRadiate,users);
								jQuery(".mui-input-group").append(_flowNextUsers);
							}
						}
						if("multiDepts" in data.result){
							var multiDepts = data.result.multiDepts;
							if(multiDepts.length>0){
								self.chooseMultiDepts(multiDepts);	
							}
						}

						if ("isReply" in data) {
							if (data.isReply) {
								var annexGroup = '<ul class="mui-table-view reply-ul">';
								var annexes = data.result.annexs;
								$.each(annexes, function(index, item) {
									annexGroup += '<li class="mui-table-view-cell">';
									annexGroup += '	<div class="reply-header">';
									annexGroup += '		<span class="reply-name">' + item.annexUser + '</span>';
									// console.log("data.isProgress=" + data.isProgress);
									if (data.isProgress) {
										annexGroup += '	<span class="reply-progress">' + item.progress + '%</span>';
									}
									annexGroup += '		<span class="reply-date">' + item.add_date + '</span>';
									annexGroup += '	</div>';
									annexGroup += '	<div class="reply-content">' + item.content + '</div>';
									annexGroup += '</li>';
								});
								annexGroup += "</ul>";
								jQuery('.reply-form').show();
								jQuery('#progressLabel').text(data.progress);
								jQuery('#progress').val(data.progress);
								jQuery(".annex-group").append(annexGroup);
							}
							else {
								// 以免出现回复不能为空
								jQuery('.reply-form').remove();
							}
						}
						else {
							// 以免出现回复不能为空							
							jQuery('.reply-form').remove();							
						}
						
						var formSelector = jQuery(".mui-input-group");
						formSelector.append(btnContent);
						formSelector.append(commonParams);
						formSelector.addClass("submitFlow");
						
						if (data.viewJs) {
							formSelector.append('<div id="viewJsBox" class="mui-input-row" style="display:none"></div>');						
							jQuery('#viewJsBox').html(data.viewJs);
							// console.log(data.viewJs);
						}
					}
				}
				mui(".mui-button-row").on("tap",".back_submit",function(){
					self.flowBackServer();							
				});
				mui(".mui-button-row").on("tap",".refuse_submit",function(){
					var btnArray = ['否', '是'];
					mui.confirm('您确定要拒绝么？', '提示', btnArray, function(e) {
						if (e.index ==1 ) {
							jQuery("#op").val("manualFinish");
							self.flowSendServer();
						}
					});							
				});
				// 提交按钮绑定事件
				mui(".mui-button-row").on("tap",".flow_submit",function(){
					var btnArray = ['否', '是'];
					mui.confirm('您确定要提交么？', '提示', btnArray, function(e) {
						if (e.index ==1 ) {
							// 如果flagXorRadiate为false，有可能是条件分支，但却不带条件，所以此处仍需将所选人员对应的分支线传至服务器端，以便于手工选择
							jQuery('.cls-XorNextActionInternalNames').remove(); // 清空XorNextActionInternalNames，因为之前的提交可能会不成功，但会生成此隐藏域
							var _ckChecked = jQuery(".next_user_ck:checked");
							if (_ckChecked.length > 0) {
								_ckChecked.each(function (i) {
									var _curCk = jQuery(this);
									var _internalname = _curCk.data("internalname");
									// 如果已存在，则不生成
									if (!jQuery('name[XorNextActionInternalNames=' + _internalname + ']')[0]) {
										jQuery("#flow_form").append('<input type="hidden" class="cls-XorNextActionInternalNames" name="XorNextActionInternalNames" value="' + _internalname + '" />');
									}
								})
							}

							jQuery("#op").val("finish");
							self.flowSendServer();
						}
					});						
				});
				// 保存草稿
				mui(".mui-button-row").on("tap",".flow_draft",function(){
					jQuery("#op").val("saveformvalue");
					self.flowSendServer();
				});		
				
				// 删除按钮绑定事件
				mui(".mui-button-row").on("tap",".del_btn",function() {
					var btnArray = ['否', '是'];
					mui.confirm('您确定要删除么？', '提示', btnArray, function(e) {
						if (e.index ==1 ) {
							jQuery("#op").val("del");
							self.flowSendServer();
						}
					});					
				});						
				mui(".mui-button-row").on("tap",".finish_btn",function() {
					var btnArray = ['否', '是'];
					mui.confirm('您确定要结束么？', '提示', btnArray, function(e) {
						if (e.index ==1 ) {
							jQuery("#op").val("manualFinishAgree");
							self.flowSendServer();
						}
					});					
				});						
			},"json");
			self.bindDateEvent();
		},
		flowBackServer:function(){
			var self = this;
			var _data = {"skey":jQuery("#skey").val(),"myActionId":jQuery("#myActionId").val(),"flowId":jQuery("#flowId").val()};
			jQuery.ajax(FLOW_RETURN_AJAX_URL,{
				dataType:'json',// 服务器返回json格式数据
				type:'post',// HTTP请求类型
				data:_data ,
				beforeSend: function(XMLHttpRequest){
					jQuery.myloading();
				},
				complete: function(XMLHttpRequest, status){
					jQuery.myloading("hide");
				},
				success:function(data){
					var res = data.res;
					if(res == "0"){
						if("users" in data){
							var users = data.users;
							if(users.length > 0){
								self.backUsers(users);
							}
						}
					}else{
						var msg = data.msg;
						$.toast(msg);
					}
				},
				error:function(xhr,type,errorThrown){
					// 异常处理；
					console.log(type);
				}
			});
		},
		flowSendServer:function() {
			var self = this;		
			// console.log("jQuery('#op').val()=" + jQuery('#op').val());	
			// 防止保存草稿、退回、拒绝时报“回复 不能为空”
			if (jQuery('#op').val()!="saveformvalue" && jQuery('#op').val()!="return" && jQuery('#op').val()!="manualFinish") {
				var _tips = "";
				jQuery("div[data-isnull='false']").each(function(i){
					// 如果是嵌套表格，则不检查是否必填，由后台检查
					if(jQuery(this).find('.nestSheetSelect')[0]) {
						return false;
					}
					// console.log(jQuery(this).find('.capture_btn')[0]);
					// 如果是图像宏控件，则不检查是否必填，由后台检查
					if (jQuery(this).find('.capture_btn')[0]) {
						return false;
					}
					var _code = jQuery(this).data("code");
					var _val = jQuery("#"+_code).val();
					
					// 防止当提交时报“回复 不能为空”
					if (jQuery('#op').val()=="finish") {
						if (_code=="content") {
							// 通过判断其父节点的class是否为reply-form，确定是否为回复
							if (jQuery(this).parent().attr("class")=="reply-form") {
								return;
							}
						}
					}
					
					if(_val == undefined || _val == ""){
					   var _text = jQuery(this).find("span:first").text();
					   // console.log("_code=" + _code + " " + _text + " 不能为空！");
					   _tips += _text + " 不能为空！\n"
					}
				});
				if(_tips != null && _tips!= "") {
					$.toast(_tips);
					return;
				}
			}
			
			var isLight = jQuery(".flow_submit").attr("isLight");			
			if(isLight == 'true') {
				if (!jQuery("input[name='nextUsers']")[0]) {
					var btnArray = ['否', '是'];
					mui.confirm('您还没有选择下一步的用户，确定办理完毕了么？', '提示', btnArray, function(e) {
						if (e.index ==1 ) {
							self.flowSendServerPost();
						}
					});
				}
				else {
					self.flowSendServerPost();
				}
			}
			else {
				self.flowSendServerPost();
			}				
		},
		flowSendServerPost:function() {
			var self = this;
			var isLight = jQuery(".flow_submit").attr("isLight");
			var formData;
			var ajax_url = PRESET_FLOW_DISPOSE_AJAX_URL;
			if(isLight == 'true'){
				ajax_url = FREE_FLOW_DISPOSE_AJAX_URL;
				formData = new FormData($('#free_flow_form')[0]);
			}else{
				formData = new FormData($('#flow_form')[0]);
			}
			for (i=0;i<blob_arr.length ;i++ ) {
				var _blobObj = blob_arr[i];
				var field = "upload";
				if (_blobObj.field) {
					field = _blobObj.field; // 图像宏控件的
				}
				formData.append(field, _blobObj.blob,_blobObj.fname);
			}
			// console.info(formData);
			jQuery.ajax(ajax_url,{
					dataType:'json',// 服务器返回json格式数据
					type:'post',// HTTP请求类型
					data: formData,
					processData: false,
					contentType: false,
					beforeSend: function(XMLHttpRequest){
						jQuery.myloading();
					},
					complete: function(XMLHttpRequest, status){
						jQuery.myloading("hide");
					},
					success:function(data){
						var res = data.res;
						if(res == "0"){
							var nextMyActionId = data.nextMyActionId;
							var open_url = '';
							var title = '操作成功!'
							if("nextMyActionId" in data && nextMyActionId !=''){
								title = '操作成功！请点击确定，继续处理下一步！';
								open_url = "../flow/flow_dispose.jsp?skey="+skey+"&myActionId="+nextMyActionId;
							}else{
								open_url = "../flow/flow_doing_or_return.jsp?skey="+skey;
							}
							mui.alert(title, '提示', function() {
								mui.openWindow({
								    "url":open_url
								})		
							});	
						}else if(res == "3"){
							var users = data.users;
							if(users.length == 0){
								$.toast("没有满足条件的分支或人员");
							}else{
								self.conditionBranch(users);
							}
						}else{
							var msg = data.msg;
							$.toast(msg);
						}
					},
					error:function(xhr,type,errorThrown){
						console.log(type);
					}
				});			
		},
		// 流程提交通用参数
		flowDisposeCommonParam:function(flowId,myActionId,actionId,skey, cwsWorkflowTitle){
			var params = '<input type="hidden" name="expireHours" value="0"/>';
			params += '	<input type="hidden" name="isToMobile" value="true"/>';
			params += '	<input type="hidden" id="flowId" name="flowId" value="'+flowId+'"/>';
			params += '	<input type="hidden" id="myActionId" name="myActionId" value="'+myActionId+'"/>';
			params += '	<input type="hidden" name="isUseMsg" value="true"/>';
			params += '	<input type="hidden" name="cws_lontitude" value=""/>';
			params += '	<input type="hidden" name="cws_latitude" value=""/>';
			params += '	<input type="hidden" name="cws_address" value=""/>';
			params += '	<input type="hidden" name="actionId" value="'+actionId+'"/>';
			params += '	<input type="hidden" id="skey" name="skey" value="'+skey+'"/>';
			params += '	<input type="hidden" name="orders" value="1"/>';
			params += '	<input type="hidden" name="op" id="op" value="finish"/>';
			params +='<input type="hidden" name="cwsWorkflowTitle" value="'+ cwsWorkflowTitle+'" />'
			return params; 
		},
		flowDisposeBtn:function(data){
			var isLight = data.isLight;
			var canDecline = data.canDecline;
			var canReturn = data.canReturn;
			var hasAttach = data.hasAttach;		
			var canDel = data.canDel;	
			var canFinishAgree = data.canFinishAgree;
			var btnContent = '<div class="mui-button-row">';
			if (!isLight) {
				btnContent += '<button type="button" class="mui-btn mui-btn-primary mui-btn-outlined flow_draft">保存</button>';
			}
			btnContent += '	<button style="margin-left:5px;" type="button" class="mui-btn mui-btn-primary mui-btn-outlined flow_submit" isLight='+isLight+'>提交</button>';
			if (canDel) {
				btnContent += '	<button style="margin-left:5px;" type="button" class="mui-btn mui-btn-primary mui-btn-outlined del_btn">删除</button>';
			}
			if (hasAttach) {
				btnContent += '	<button style="margin-left:5px;" type="button" captureFieldName="upload" class="mui-btn mui-btn-primary mui-btn-outlined capture_btn">照片</button>';
			}
			if(!isLight && canDecline == 'true'){
				btnContent += '	<button style="margin-left:5px;" type="button" class="mui-btn mui-btn-primary mui-btn-outlined refuse_submit">拒绝</button>';
			}
			if(!isLight && canReturn == 'true'){
				btnContent += '	<button style="margin-left:5px;" type="button" class="mui-btn mui-btn-primary mui-btn-outlined back_submit" >退回</button>';
			}
			if (canFinishAgree) {
				btnContent += '	<button style="margin-left:5px;" type="button" class="mui-btn mui-btn-primary mui-btn-outlined finish_btn">结束</button>';
			}
			btnContent +='</div>';
			return btnContent;
		},
		chooseMultiDepts:function(multiDepts){
			var self = this;
			var deptContent = '<div class="mui-input-row dept_title"><label>请选择你所在部门:</label></div>';
			deptContent += '<div class="mui-row multi_dept_div">';
			$.each(multiDepts,function(index,item){
				var _name = item.name;
				var _code = item.code;		
				deptContent += '<span class="mui-checkbox mui-left user_ck_span " style="float: left;">' ;
				deptContent += '<label style="line-height: 45px;">';
				deptContent += _name;
				deptContent += '</lable>';
				deptContent += '<input name="multi_dept_ck" value="'+_code+' "  type="checkbox"  class="multi_dept_ck" />'
				deptContent +='</span>';
				
			});
			deptContent += '</div>';
			jQuery(".mui-input-group").append(deptContent);		
		    mui(".mui-input-group").on("tap",".multi_dept_ck",function(){
		    	var _value = jQuery(this).val();
		    	self.getUsersByDepts(_value);
		    	
		    });
			
		},
		getUsersByDepts:function(deptCode){
			var self = this;
			var _data = {"skey":jQuery("#skey").val(),"myActionId":jQuery("#myActionId").val(),"deptCode":deptCode};
			jQuery.ajax(FLOW_MULTI_DEPT,{
				dataType:'json',// 服务器返回json格式数据
				type:'post',// HTTP请求类型
				data:_data ,
				beforeSend: function(XMLHttpRequest){
					jQuery.myloading();
				},
				complete: function(XMLHttpRequest, status){
					jQuery.myloading("hide");
				},
				success:function(data){
					var res = data.res;
					if(res == "0"){
						if("users" in data.result){
							var users = data.result.users;
							if(users.length>0){
								jQuery(".multi_dept_div").remove();
								jQuery(".dept_title").remove();
								var _users = self.flowNextUsers('false',users);
								jQuery(".mui-button-row").before(_users);
							
							}
						}
					
					}
				},
				error:function(xhr,type,errorThrown){
					// 异常处理；
					console.log(type);
				}
			});
		},
		flowNextUsers:function(flagXorRadiate, users){
			// users
			var userContent = "";
			if(flagXorRadiate == 'false') {
				var isUserSelect = false; // 是否为自选用户
				userContent = '<div class="mui-input-row"><label>下一步用户:</label></div>';
				$.each(users, function(index, item) {
					var actionTitle = item.actionTitle;
					var actionUserName = item.actionUserName;
					var actionUserRealName = item.actionUserRealName;
					// 自选用户时，服务器端返回不带actionUserName及actionUserRealName
					if (actionUserName==null) {
						actionUserName = "";
						actionUserRealName = "";
					}
					var value = item.value;
					var name = item.name;
					var realName = item.realName;
					var roleName = item.roleName;
					var isSelectable = item.isSelectable === 'true';
					var isSelected = item.isSelected === 'true';
					var isGoDown = item.isGoDown === 'true';
					var canSelUser = item.canSelUser === 'true';
					// console.info( item.canSelUser);
					var disabled = isSelectable?"":"disabled";
					// 如果根据策略需选中
					var checked = isSelectable?"":"checked";
					if (isSelected) {
						checked = "checked";
					}
					// 如果根据策略为下达
					var internalname = item.internalname;
					if(actionUserName == "$userSelect" || value == "$userSelect") {
						isUserSelect = true;
		                userContent += "<input type='hidden' name='XorNextActionInternalNames' value='"+internalname+"' />";

		                checked = "checked";
						userContent += '<div id="next_user' + internalname + '" class="mui-row next_user_div">';

						var userNameAry = actionUserName.split(",");
						var realNameAry = actionUserRealName.split(",");
						// 列出其他人已选择的用户
						for (var i = 0; i < userNameAry.length; i++) {
							value = userNameAry[i];
							realName = realNameAry[i];
							userContent += '<span class="mui-checkbox mui-left user_ck_span" style="float:left;">';
							userContent += '<label style="line-height: 45px;">';
							userContent += actionTitle + ":" + realName;
							userContent += '</lable>';
							var style = "";
							if (isGoDown) {
								userContent += '<input type="checkbox" checked disabled />';
								style = " style='display:none' ";
							}
							userContent += '<input name="' + name + '" value="' + value + ' " ' + disabled + style + ' type="checkbox" ' + checked + ' class="next_user_ck" />'
						
							userContent += '</span>';
						}
						userContent += '</div>';		                
						if (isUserSelect) {
							userContent += '<div class="mui-row">';						
							userContent += '<button type="button" name="'+name+'" class="mui-btn mui-btn-primary choose_user_btn" isGoDown="' + isGoDown + '" internalName="' + internalname + '" style="margin: 10px;float:right;" >选择用户</button>';	
			                userContent += '</div>';
						}    
					}else{
						userContent += '<div id="next_user' + internalname + '" class="mui-row next_user_div">';						
						userContent += '<span class="mui-checkbox mui-left user_ck_span" style="float:left;">';
						userContent += '<label style="line-height: 45px;">';
						userContent += actionTitle+":"+realName;
						userContent += '</lable>';
						userContent += '<input data-internalname="' + internalname + '" name="'+name+'" value="'+value+' " '+disabled+' type="checkbox" '+checked+' class="next_user_ck" />'
						userContent += '</span>';
						userContent += '</div>';
					}
				});
			}
			return userContent;
		},
		conditionBranch:function(users){
			var self = this;
			var strHtml= '<ul class="mui-table-view">';
			$.each(users,function(index,item){
				strHtml += '<li class="mui-table-view-cell  mui-checkbox  mui-left">';
				if (!item.isSelectable) {
					strHtml += '<input data-internalname = "'+item.internalname+'" style="display:none" checked  data-name = "'+item.name+'" type="checkbox" value="'+item.value+'" class="return_ck"/>';
				}
				else {
					strHtml += '<input data-internalname = "'+item.internalname+'"  data-name = "'+item.name+'" type="checkbox" value="'+item.value+'" class="return_ck"/>';
				}
				strHtml += item.actionTitle+"："+item.realName;
				strHtml += '</li>';
			});
	         strHtml+='</ul>';
	         strHtml+='	<div class="mui-button-row" style="margin-top:10px;">';
	         strHtml+='<button class="mui-btn mui-btn-primary" id="return-confirm-btn" type="button" onclick="return false;">确认</button>';
	         strHtml+='</div>';
             var pop=new Popup({ contentType:2,isReloadOnClose:false,width:340,height:300});
             pop.setContent("contentHtml",strHtml);
             pop.setContent("title","下一步处理人");
             pop.build();
             pop.show();
             mui(".mui-button-row").on("tap","#return-confirm-btn",function(){
            	 var _ckChecked =  jQuery(".return_ck:checked");
            	 var _checkLen = _ckChecked.length;
            	 pop.close();
            	 if(_checkLen>0){
            		 jQuery("#flow_form").append('<input type="hidden" name="isAfterSaveformvalueBeforeXorCondSelect" value="true" />');
            		 _ckChecked.each(function(i){
            			 var _curCk = jQuery(this);
                		 var _internalname = _curCk.data("internalname");
                		 var _actionName = _curCk.data("name");
                		 var _val = _curCk.val();
                		 jQuery("#flow_form").append('<input type="hidden" name="XorNextActionInternalNames" value="'+_internalname+'" />');
                		 jQuery("#flow_form").append('<input type="hidden" name="'+_actionName+'" value="'+_val+'" />');
                	 })
                	 self.flowSendServer();
            	 }
			});
		},
		backUsers:function(users){
			var self = this;
			var strHtml= '<ul class="mui-table-view">';
			$.each(users,function(index,item){
				strHtml += '<li class="mui-table-view-cell  mui-checkbox  mui-left">';
				strHtml += '<input type="checkbox" value="'+item.id+'" class="return_ck"/>';
				strHtml += item.actionTitle+":"+item.name;
				strHtml += '</li>';
			});
	         strHtml+='</ul>';
	         strHtml+='	<div class="mui-button-row" style="margin-top:10px;">';
	         strHtml+='<button class="mui-btn mui-btn-primary" id="return-back-confirm-btn" type="button" onclick="return false;">确认</button>';
	         strHtml+='</div>';
             var pop=new Popup({ contentType:2,isReloadOnClose:false,width:340,height:300});
             pop.setContent("contentHtml",strHtml);
             pop.setContent("title","请选择要返回的给的人");
             pop.build();
             pop.show();
             mui(".mui-button-row").on("tap","#return-back-confirm-btn",function(){
            	 var _ckChecked =  jQuery(".return_ck:checked");
            	 var _checkLen = _ckChecked.length;
            	 pop.close();
            	 if(_checkLen>0){
					 // 如果进度的回复未填，会导致需填写后重新再次取返回用户，有可能会导致returnId重复，所以此处需清除
					 jQuery("input[name='returnId']").remove();
					 
            		 _ckChecked.each(function(i){
            			 var _curCk = jQuery(this);
                		 var _val = _curCk.val();
                		 jQuery("#flow_form").append('<input type="hidden" name="returnId" value="'+_val+'" />');
                	 })
					 jQuery('#op').val('return');			 
                	 self.flowSendServer();
            	 }
			});
		},
		bindDateEvent:function() {
			var self = this;
			var content = self.element;
			// 选择用户
			$(".mui-input-group").on("tap", ".choose_user_btn", function() {
				var checkedValues = [];
				jQuery(".next_user_ck").each(function(i) {
					checkedValues.push(jQuery.trim(jQuery(this).val()));
				})
				var internalName = jQuery(this).attr('internalName');
				var chooseUser = checkedValues.join(",");
				openChooseUser(chooseUser, false, internalName);
			});
			Form.bindFileDel();
			mui(".mui-input-group").on("tap", ".capture_btn", function() {
				captureFieldName = jQuery(this).attr("captureFieldName");
				// 置图像宏控件是否只允许拍照
				if (jQuery(this).attr("isOnlyCamera")) {
					setIsOnlyCamera(jQuery(this).attr("isOnlyCamera"));
				}
				else {
					// 恢复默认设置
					resetIsOnlyCamera();
				}
				var cap = jQuery("#captureFile").get(0);
				cap.click();
			});
			// @流程选择用户
			$("#free_flow_form").on("tap", ".at_user_div", function() {
				var checkedValues = [];
				jQuery(".free_next_user_ck").each(function(i) {
					checkedValues.push(jQuery(this).val());
				})
				var chooseUser = checkedValues.join(",");
				openChooseUser(chooseUser, true);

			});
		}
	})
})(mui,document,window)
