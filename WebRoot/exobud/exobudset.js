<!--
//
// ■ 播放程式的基本设定
//
// ▽自动播放？
//   设定当播放器载入页面时，是否自动播放(Auto Start)媒体档案：
//      true = 自动播放 (一般站长会选择这个方式)
//     false = 不要自动播放，等待使用者启动播放器
var blnAutoStart = true;

// ▽随机播放？
//   设定曲目的预设播放顺序，是否随机(乱数/Random Playing)播放媒体档案：
//      true = 随机播放 (一般站长会选择这个方式)
//     false = 根据我所排列的顺序，循序播放
var blnRndPlay = false;

// ▽在状态列显示文字讯息？
//   设定是否要在浏览器的状态列(Status Bar)，显示播放器的目前动作：
//      true = 在状态列显示播放器文字讯息 (适合在隐藏媒体标题/时间长度方块的情况下使用)
//     false = 不要在状态列显示播放器文字讯息
//   (如果您在设定播放清单项目时，使用了像 ? 的‘＆控制码’，必须将此项设为 false)
var blnStatusBar = false;

// ▽显示音量控制按钮？
//   设定播放面板上是否要显示音量控制(Volume Control-包括静音模式)的按钮：
//      true = 显示音量控制，容许使用者调校音量
//     false = 不显示音量控制，将按钮隐藏起来
var blnShowVolCtrl = true;

// ▽显示播放清单按钮？
//   设定播放面板上是否要显示播放清单(Playlist)按钮：
//      true = 显示播放清单按钮，让使用者检视播放清单内容及挑选曲目
//     false = 不显示播放清单按钮，使用者无法检视播放清单内容及挑选曲目
var blnShowPlist = true;

// ▽使用字幕功能，开启字幕框？
//   设定是否使用SMIL字幕功能(Closed Captioning-须配合副档名为"SMI"的纯文字档案使用)：
//      true = 使用字幕功能，在字幕框中显示同步歌词或文字讯息(也可以包含图片等资讯)
//     false = 关闭字幕功能
var blnUseSmi = false;

// ▽循环播放？
//   设定当所有曲目播放完毕后，是否重新播放所有曲目(循环播放/Loop Tracks)：
//      true = 使用循环播放功能 (一般站长会选择这个方式)
//     false = 不使用循环播放功能，当所有曲目播放完毕后停止播放
var blnLoopTrk = false;

// ▽弹出视窗显示媒体档案资讯？
//   设定在开始播放每一首曲目时，是否弹出视窗显示媒体档案资讯(Media Info)：
//      true = 显示媒体档案资讯 (请认真考虑清楚，因为浏览者可能会感到厌烦的，此功能只适合测试用)
//     false = 不显示媒体档案资讯
var blnShowMmInfo = false;

//-->