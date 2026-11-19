// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get navPlayground => '演示区';

  @override
  String get navExamples => '示例';

  @override
  String get navGettingStarted => '快速开始';

  @override
  String get menu => '菜单';

  @override
  String get playgroundIntro => '更改选项后，聊天内容会立即更新。消息为模拟数据，可以随意发送。';

  @override
  String get preview => '预览';

  @override
  String get settings => '设置';

  @override
  String get receiveMessage => '接收';

  @override
  String get markAllRead => '全部标为已读';

  @override
  String get restart => '重新开始';

  @override
  String get online => '在线';

  @override
  String get inputHint => '请输入消息';

  @override
  String incomingMessage(int count) {
    return '新消息（$count）';
  }

  @override
  String autoReply(String text) {
    return '收到：“$text”';
  }

  @override
  String newMessageFrom(String name) {
    return '来自 $name 的新消息';
  }

  @override
  String get readOnlyNotice => '此聊天为只读';

  @override
  String get menuRetry => '重新发送';

  @override
  String get menuDelete => '删除';

  @override
  String get menuCopy => '复制';

  @override
  String get sectionLayout => '布局';

  @override
  String get startAtTopTitle => '消息较少时从顶部开始';

  @override
  String get startAtTopDesc => '不贴在底部显示';

  @override
  String get senderSideTitle => '我的消息位于';

  @override
  String get sideRight => '右侧';

  @override
  String get sideLeft => '左侧';

  @override
  String get sidePadding => '左右边距';

  @override
  String get bubbleColor => '我的气泡颜色';

  @override
  String get maxWidth => '最大宽度';

  @override
  String get noLimit => '不限';

  @override
  String get appearAnimation => '出现动画';

  @override
  String get off => '关闭';

  @override
  String get readOnlyTitle => '只读';

  @override
  String get readOnlyDesc => '显示提示文字，替代输入框';

  @override
  String get sectionServer => '模拟';

  @override
  String get storedMessages => '已存储消息';

  @override
  String get none => '无';

  @override
  String messageCount(int count) {
    return '$count 条';
  }

  @override
  String get responseTime => '响应时间';

  @override
  String seconds(String value) {
    return '$value 秒';
  }

  @override
  String get imagesTitle => '混入图片消息';

  @override
  String get imagesDesc => '30% 为加载较慢的图片';

  @override
  String get sendResult => '发送结果';

  @override
  String get resultSuccess => '成功';

  @override
  String get resultFail => '失败';

  @override
  String get resultBlock => '拦截';

  @override
  String get autoReplyTitle => '自动回复';

  @override
  String get autoReplyDesc => '发送成功后，对方会读取并回复';

  @override
  String get examplesIntro => '从服务器加载消息的聊天室。每个聊天室的消息数量和响应时间各不相同，便于观察滚动效果。';

  @override
  String get roomShortTitle => '短聊天室';

  @override
  String get roomShortDesc => '5 条消息，不足以填满屏幕';

  @override
  String get roomNormalTitle => '普通聊天室';

  @override
  String get roomNormalDesc => '60 条消息，分 2 页加载，每页 30 条';

  @override
  String get roomLongTitle => '长聊天室';

  @override
  String get roomLongDesc => '500 条消息，每次滚动到顶部加载 30 条';

  @override
  String get roomImagesTitle => '图片聊天室';

  @override
  String get roomImagesDesc => '120 条消息，其中 40% 为加载较慢且会变大的图片';

  @override
  String get roomSlowTitle => '慢速服务器';

  @override
  String get roomSlowDesc => '200 条消息，响应需要 2 秒';

  @override
  String get loadingOlder => '正在加载更早的消息';

  @override
  String get gsIntro => '消息分组、日期分隔线、发送失败与重试、加载更早的消息，都可以通过一个 ChatController 完成。';

  @override
  String get step1Title => '安装包';

  @override
  String get step2Title => '定义消息内容的绘制方式';

  @override
  String get step2Desc => '将气泡内的内容（如文本或图片）定义为 MessageElement。';

  @override
  String get step3Title => '添加聊天界面';

  @override
  String get step3Desc =>
      '使用 setMessages 放入服务器消息，滚动时使用 appendMessages 加载更早的消息。';

  @override
  String get step4Title => '发送消息';

  @override
  String get step4Desc => '返回 null 会将消息标记为失败，长按即可重新发送。';

  @override
  String get gsCtaTitle => '想试试这些选项吗？';

  @override
  String get gsCtaDesc => '在演示区查看每项设置如何改变聊天效果。';

  @override
  String get gsCtaButton => '打开演示区';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get search => '搜索';

  @override
  String get searchHint => '搜索消息';

  @override
  String get searchNoResults => '没有结果';

  @override
  String get searchOlder => '上一个结果';

  @override
  String get searchNewer => '下一个结果';

  @override
  String get closeSearch => '关闭搜索';

  @override
  String get jumpToLatest => '跳到最新消息';

  @override
  String get receiverBubbleColor => '对方气泡颜色';

  @override
  String get groupingTitle => '消息分组';

  @override
  String get groupingDesc => '同一分钟内同一人发送的消息共用一个头像资料';

  @override
  String get sendingIndicatorTitle => '自定义发送中指示';

  @override
  String get sendingIndicatorDesc => '在气泡中显示，直到服务器响应';

  @override
  String get sending => '发送中…';

  @override
  String searchResultCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String get searchShortcutsTitle => '键盘快捷键';

  @override
  String get close => '关闭';

  @override
  String get cancel => '取消';

  @override
  String get send => '发送';

  @override
  String get verticalPadding => '上下边距';

  @override
  String get backgroundTitle => '聊天背景';

  @override
  String get lookCustom => '自定义';

  @override
  String get lookLibrary => '默认';

  @override
  String get fontSize => '文字大小';

  @override
  String get bubblePaddingH => '内边距（左右）';

  @override
  String get bubblePaddingV => '内边距（上下）';

  @override
  String get hide => '隐藏';

  @override
  String get myProfileTitle => '我的头像';

  @override
  String get myProfileDesc => '在我的消息旁也显示头像';

  @override
  String get scrollThresholdTitle => '自动滚动范围';

  @override
  String get menuPopup => '弹出菜单';

  @override
  String get menuSheet => '底部面板';

  @override
  String get longPressTitle => '长按打开';

  @override
  String get longPressDesc => '关闭后仅右键打开';

  @override
  String get hapticTitle => '触感反馈';

  @override
  String get confirmDeleteTitle => '删除失败消息前确认';

  @override
  String get confirmDeleteDesc => '将发送结果设为失败后试着删除';

  @override
  String get deleteFailedTitle => '删除这条消息？';

  @override
  String get deleteFailedBody => '消息未发送，对方没有看到。';

  @override
  String get kind => '类型';

  @override
  String get designBackground => '背景色';

  @override
  String get designTextColor => '文字颜色';

  @override
  String get designRadius => '圆角';

  @override
  String get designHeight => '高度';

  @override
  String get designSize => '大小';

  @override
  String get designShape => '样式';

  @override
  String get roundness => '圆润度';

  @override
  String get roundFull => '全圆';

  @override
  String get weekdayTitle => '显示星期';

  @override
  String get use24hTitle => '24 小时制';

  @override
  String get searchShortcutsDesc => 'Ctrl/⌘ + F 打开，Enter 下一个结果，Esc 关闭';

  @override
  String get sectionBehavior => '行为';

  @override
  String get partBubble => '气泡';

  @override
  String get partBubbleDesc =>
      'senderBubbleBuilder 和 receiverBubbleBuilder 以 child 接收消息内容，用任意容器包裹即可。';

  @override
  String get partSearch => '搜索栏';

  @override
  String get partSearchDesc =>
      '用聊天上方的搜索按钮打开。可以美化工具包的 ChatSearchBar，也可以用 ChatSearchController 的 search()、showOlder()、showNewer()、close() 连接自定义搜索栏。';

  @override
  String get partInput => '输入框';

  @override
  String get partInputDesc =>
      '聊天只负责把 customInputField 放在底部，输入框和发送（controller.dispatchMessage）由你实现。';

  @override
  String get partNotice => '新消息提示';

  @override
  String get partNoticeDesc => '向上滚动时收到消息会显示。先向上滚动，再点聊天上方的接收按钮。';

  @override
  String get partSeparator => '日期分隔';

  @override
  String get partSeparatorDesc => '显示在日期变化处，构建器会收到当天的 timestamp。';

  @override
  String get partTime => '时间';

  @override
  String get partTimeDesc => '显示在一组最后一个气泡旁，构建器会收到消息的 timestamp。';

  @override
  String get partProfile => '头像';

  @override
  String get partProfileDesc => '每组消息显示一次，构建器会收到发送者名字。';

  @override
  String get partRead => '已读标记';

  @override
  String get partReadDesc =>
      '用于 SenderMessage(isRead: false/true)。发送消息后点击全部已读试试。';

  @override
  String get partMenu => '气泡菜单';

  @override
  String get partMenuDesc => '长按或右键点击气泡。可以给工具包弹出菜单添加项目，也可以用处理函数显示任意界面。';

  @override
  String get partReadOnly => '只读提示';

  @override
  String get partReadOnlyDesc =>
      'Chat(readOnly: true) 时，用 readOnlyWidget 代替输入框。';

  @override
  String get studioEdit => '编辑';

  @override
  String get studioReset => '恢复初始';

  @override
  String get tabStructure => '结构';

  @override
  String get tabStyle => '容器';

  @override
  String get tabCode => '代码';

  @override
  String get layoutAxis => '排列方向';

  @override
  String get axisRow => '横向';

  @override
  String get axisColumn => '纵向';

  @override
  String get layoutMain => '主轴对齐';

  @override
  String get layoutCross => '交叉轴对齐';

  @override
  String get layoutGap => '元素间距';

  @override
  String get alignStart => '开始';

  @override
  String get alignCenter => '居中';

  @override
  String get alignEnd => '末尾';

  @override
  String get alignBetween => '两端';

  @override
  String get elements => '元素';

  @override
  String get elementsHint => '拖动 ⋮⋮ 调整顺序，点按元素修改样式';

  @override
  String get addElement => '添加';

  @override
  String get elementVisible => '显示/隐藏';

  @override
  String get elContent => '消息内容';

  @override
  String get elText => '文字';

  @override
  String get elIcon => '图标';

  @override
  String get elField => '输入框';

  @override
  String get elButton => '按钮';

  @override
  String get elBadge => '徽章';

  @override
  String get elAvatar => '头像';

  @override
  String get elSpacer => '空白';

  @override
  String get elDivider => '线条';

  @override
  String get propSource => '显示内容';

  @override
  String get propText => '文字';

  @override
  String get propTextUnread => '已读前文字';

  @override
  String get propTextRead => '已读后文字';

  @override
  String get propIconUnread => '已读前图标';

  @override
  String get propIconRead => '已读后图标';

  @override
  String get propHint => '提示文字';

  @override
  String get propAction => '动作';

  @override
  String get propBold => '加粗';

  @override
  String get propColor => '颜色';

  @override
  String get propExpand => '填满剩余空间';

  @override
  String get propWidth => '宽度';

  @override
  String get propThickness => '粗细';

  @override
  String get lookFilled => '填充';

  @override
  String get srcLiteral => '自定义';

  @override
  String get srcName => '名字';

  @override
  String get srcTime => '时间';

  @override
  String get srcDate => '日期';

  @override
  String get srcCount => '结果数';

  @override
  String get srcRead => '已读状态';

  @override
  String get srcNotice => '提示文字';

  @override
  String get srcReadOnly => '提示文字';

  @override
  String get actNone => '无';

  @override
  String get actAttach => '附件';

  @override
  String get boxGradient => '渐变';

  @override
  String get boxGradientTo => '渐变结束色';

  @override
  String get boxBorder => '边框粗细';

  @override
  String get boxBorderColor => '边框颜色';

  @override
  String get boxShadow => '阴影';

  @override
  String get boxMarginH => '外边距（左右）';

  @override
  String get boxMarginV => '外边距（上下）';

  @override
  String get boxAuto => '自动';

  @override
  String get boxFill => '铺满宽度';

  @override
  String get boxAlign => '位置';

  @override
  String get colorHue => '色相';

  @override
  String get colorSaturation => '饱和度';

  @override
  String get colorBrightness => '亮度';

  @override
  String get colorOpacity => '不透明度';

  @override
  String get colorHexHint => '输入 RRGGBB 或 AARRGGBB 后按回车';

  @override
  String get sectionParts => '组件设计';

  @override
  String get sectionPartsDesc =>
      '选择自定义后，聊天旁会打开编辑面板。可以添加、删除、排序元素，自由修改元素和容器样式，修改会立即反映到聊天中。';

  @override
  String studioTitle(String part) {
    return '设计：$part';
  }

  @override
  String get previewNotice => '预览：向上滚动并接收消息';

  @override
  String get boxMinHeight => '最小高度';
}
