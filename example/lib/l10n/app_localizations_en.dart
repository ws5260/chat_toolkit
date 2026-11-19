// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navPlayground => 'Playground';

  @override
  String get navExamples => 'Examples';

  @override
  String get navGettingStarted => 'Getting started';

  @override
  String get menu => 'Menu';

  @override
  String get playgroundIntro =>
      'Change an option and the chat updates right away. Messages are simulated, so send as many as you like.';

  @override
  String get preview => 'Preview';

  @override
  String get settings => 'Settings';

  @override
  String get receiveMessage => 'Receive';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get restart => 'Start over';

  @override
  String get online => 'Online';

  @override
  String get inputHint => 'Type a message';

  @override
  String incomingMessage(int count) {
    return 'New message ($count)';
  }

  @override
  String autoReply(String text) {
    return 'Got it: \"$text\"';
  }

  @override
  String newMessageFrom(String name) {
    return 'New message from $name';
  }

  @override
  String get readOnlyNotice => 'This chat is read-only';

  @override
  String get menuRetry => 'Send again';

  @override
  String get menuDelete => 'Delete';

  @override
  String get menuCopy => 'Copy';

  @override
  String get sectionLayout => 'Layout';

  @override
  String get startAtTopTitle => 'Few messages start at the top';

  @override
  String get startAtTopDesc => 'Instead of sitting at the bottom';

  @override
  String get senderSideTitle => 'My messages on';

  @override
  String get sideRight => 'Right';

  @override
  String get sideLeft => 'Left';

  @override
  String get sidePadding => 'Side padding';

  @override
  String get bubbleColor => 'My bubble color';

  @override
  String get maxWidth => 'Max width';

  @override
  String get noLimit => 'No limit';

  @override
  String get appearAnimation => 'Entrance animation';

  @override
  String get off => 'Off';

  @override
  String get readOnlyTitle => 'Read-only';

  @override
  String get readOnlyDesc => 'Shows a notice instead of the input field';

  @override
  String get sectionServer => 'Simulation';

  @override
  String get storedMessages => 'Stored messages';

  @override
  String get none => 'None';

  @override
  String messageCount(int count) {
    return '$count';
  }

  @override
  String get responseTime => 'Response time';

  @override
  String seconds(String value) {
    return '${value}s';
  }

  @override
  String get imagesTitle => 'Mix in image messages';

  @override
  String get imagesDesc => '30% are images that load late';

  @override
  String get sendResult => 'Send result';

  @override
  String get resultSuccess => 'Success';

  @override
  String get resultFail => 'Fail';

  @override
  String get resultBlock => 'Block';

  @override
  String get autoReplyTitle => 'Auto reply';

  @override
  String get autoReplyDesc =>
      'After a successful send, the other person reads it and replies';

  @override
  String get examplesIntro =>
      'Chat rooms that load their messages from a server. Each room has a different size and response time, so you can see how scrolling behaves.';

  @override
  String get roomShortTitle => 'Short room';

  @override
  String get roomShortDesc => '5 messages, not enough to fill the screen';

  @override
  String get roomNormalTitle => 'Normal room';

  @override
  String get roomNormalDesc => '60 messages in 2 pages of 30';

  @override
  String get roomLongTitle => 'Long room';

  @override
  String get roomLongDesc =>
      '500 messages, 30 more each time you reach the top';

  @override
  String get roomImagesTitle => 'Image room';

  @override
  String get roomImagesDesc =>
      '120 messages, 40% are images that load late and grow';

  @override
  String get roomSlowTitle => 'Slow server';

  @override
  String get roomSlowDesc => '200 messages, responses take 2 seconds';

  @override
  String get loadingOlder => 'Loading older messages';

  @override
  String get gsIntro =>
      'Grouping, date separators, failed sends and retries, and loading older messages, all handled by one ChatController.';

  @override
  String get step1Title => 'Install the package';

  @override
  String get step2Title => 'Define how message content is drawn';

  @override
  String get step2Desc =>
      'Describe what goes inside a bubble, such as text or images, as a MessageElement.';

  @override
  String get step3Title => 'Add the chat';

  @override
  String get step3Desc =>
      'Put messages from the server in with setMessages, and older ones loaded on scroll with appendMessages.';

  @override
  String get step4Title => 'Send messages';

  @override
  String get step4Desc =>
      'Returning null marks the message as failed; long-press it to send again.';

  @override
  String get gsCtaTitle => 'Want to try the options?';

  @override
  String get gsCtaDesc =>
      'See how each setting changes the chat in the playground.';

  @override
  String get gsCtaButton => 'Open playground';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search messages';

  @override
  String get searchNoResults => 'No results';

  @override
  String get searchOlder => 'Older result';

  @override
  String get searchNewer => 'Newer result';

  @override
  String get closeSearch => 'Close search';

  @override
  String get jumpToLatest => 'Jump to latest';

  @override
  String get receiverBubbleColor => 'Their bubble color';

  @override
  String get groupingTitle => 'Group messages';

  @override
  String get groupingDesc =>
      'Messages from the same person in the same minute share one profile';

  @override
  String get sendingIndicatorTitle => 'Custom sending indicator';

  @override
  String get sendingIndicatorDesc =>
      'Shown in the bubble until the server answers';

  @override
  String get sending => 'Sending…';

  @override
  String searchResultCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String get searchShortcutsTitle => 'Keyboard shortcuts';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get send => 'Send';

  @override
  String get verticalPadding => 'Top and bottom padding';

  @override
  String get backgroundTitle => 'Chat background';

  @override
  String get lookCustom => 'Custom';

  @override
  String get lookLibrary => 'Default';

  @override
  String get fontSize => 'Text size';

  @override
  String get bubblePaddingH => 'Inner padding, sides';

  @override
  String get bubblePaddingV => 'Inner padding, top and bottom';

  @override
  String get hide => 'Hide';

  @override
  String get myProfileTitle => 'My profile';

  @override
  String get myProfileDesc => 'Show a profile next to my messages too';

  @override
  String get scrollThresholdTitle => 'Auto-scroll range';

  @override
  String get menuPopup => 'Popup';

  @override
  String get menuSheet => 'Bottom sheet';

  @override
  String get longPressTitle => 'Open on long press';

  @override
  String get longPressDesc => 'Off: right-click only';

  @override
  String get hapticTitle => 'Haptic feedback';

  @override
  String get confirmDeleteTitle => 'Confirm deleting a failed message';

  @override
  String get confirmDeleteDesc => 'Set Send result to Fail and try deleting';

  @override
  String get deleteFailedTitle => 'Delete this message?';

  @override
  String get deleteFailedBody =>
      'It was not sent, so the other person never saw it.';

  @override
  String get kind => 'Type';

  @override
  String get designBackground => 'Background';

  @override
  String get designTextColor => 'Text color';

  @override
  String get designRadius => 'Corner radius';

  @override
  String get designHeight => 'Height';

  @override
  String get designSize => 'Size';

  @override
  String get designShape => 'Shape';

  @override
  String get roundness => 'Roundness';

  @override
  String get roundFull => 'Round';

  @override
  String get weekdayTitle => 'Show the weekday';

  @override
  String get use24hTitle => '24-hour clock';

  @override
  String get searchShortcutsDesc =>
      'Ctrl/⌘ + F opens, Enter goes to the next result, Esc closes';

  @override
  String get sectionBehavior => 'Behavior';

  @override
  String get partBubble => 'Bubble';

  @override
  String get partBubbleDesc =>
      'senderBubbleBuilder and receiverBubbleBuilder get the message content as child; wrap it in any container you like.';

  @override
  String get partSearch => 'Search bar';

  @override
  String get partSearchDesc =>
      'Open it with the search button above the chat. Style the toolkit\'s ChatSearchBar, or build your own bar on the ChatSearchController: search(), showOlder(), showNewer(), close().';

  @override
  String get partInput => 'Input field';

  @override
  String get partInputDesc =>
      'The chat only places customInputField at the bottom. The field and sending (controller.dispatchMessage) are yours.';

  @override
  String get partNotice => 'New message notice';

  @override
  String get partNoticeDesc =>
      'Shown when a message arrives while you are scrolled up. Scroll up, then press Receive above the chat.';

  @override
  String get partSeparator => 'Date separator';

  @override
  String get partSeparatorDesc =>
      'Shown between messages of different days; the builder gets the timestamp of the day.';

  @override
  String get partTime => 'Time';

  @override
  String get partTimeDesc =>
      'Shown next to the last bubble of a group; the builder gets the message timestamp.';

  @override
  String get partProfile => 'Profile';

  @override
  String get partProfileDesc =>
      'Shown once per group of messages; the builder gets the sender name.';

  @override
  String get partRead => 'Read indicator';

  @override
  String get partReadDesc =>
      'Shown for SenderMessage(isRead: false/true). Send a message, then press Mark all read.';

  @override
  String get partMenu => 'Bubble menu';

  @override
  String get partMenuDesc =>
      'Long-press or right-click a bubble. Use the toolkit\'s popup with your items, or a handler that shows anything.';

  @override
  String get partReadOnly => 'Read-only notice';

  @override
  String get partReadOnlyDesc =>
      'With Chat(readOnly: true), readOnlyWidget replaces the input field.';

  @override
  String get studioEdit => 'Edit';

  @override
  String get studioReset => 'Start over';

  @override
  String get tabStructure => 'Structure';

  @override
  String get tabStyle => 'Box';

  @override
  String get tabCode => 'Code';

  @override
  String get layoutAxis => 'Direction';

  @override
  String get axisRow => 'Row';

  @override
  String get axisColumn => 'Column';

  @override
  String get layoutMain => 'Align along';

  @override
  String get layoutCross => 'Align across';

  @override
  String get layoutGap => 'Gap';

  @override
  String get alignStart => 'Start';

  @override
  String get alignCenter => 'Center';

  @override
  String get alignEnd => 'End';

  @override
  String get alignBetween => 'Spread';

  @override
  String get elements => 'Elements';

  @override
  String get elementsHint => 'Drag ⋮⋮ to reorder, tap an element to style it';

  @override
  String get addElement => 'Add';

  @override
  String get elementVisible => 'Show or hide';

  @override
  String get elContent => 'Message content';

  @override
  String get elText => 'Text';

  @override
  String get elIcon => 'Icon';

  @override
  String get elField => 'Input field';

  @override
  String get elButton => 'Button';

  @override
  String get elBadge => 'Badge';

  @override
  String get elAvatar => 'Avatar';

  @override
  String get elSpacer => 'Space';

  @override
  String get elDivider => 'Line';

  @override
  String get propSource => 'Shows';

  @override
  String get propText => 'Text';

  @override
  String get propTextUnread => 'Text before read';

  @override
  String get propTextRead => 'Text after read';

  @override
  String get propIconUnread => 'Icon before read';

  @override
  String get propIconRead => 'Icon after read';

  @override
  String get propHint => 'Hint';

  @override
  String get propAction => 'Does';

  @override
  String get propBold => 'Bold';

  @override
  String get propColor => 'Color';

  @override
  String get propExpand => 'Fill the remaining space';

  @override
  String get propWidth => 'Width';

  @override
  String get propThickness => 'Thickness';

  @override
  String get lookFilled => 'Filled';

  @override
  String get srcLiteral => 'Typed';

  @override
  String get srcName => 'Name';

  @override
  String get srcTime => 'Time';

  @override
  String get srcDate => 'Date';

  @override
  String get srcCount => 'Result count';

  @override
  String get srcRead => 'Read state';

  @override
  String get srcNotice => 'Notice text';

  @override
  String get srcReadOnly => 'Notice text';

  @override
  String get actNone => 'Nothing';

  @override
  String get actAttach => 'Attach';

  @override
  String get boxGradient => 'Gradient';

  @override
  String get boxGradientTo => 'Gradient end';

  @override
  String get boxBorder => 'Border width';

  @override
  String get boxBorderColor => 'Border color';

  @override
  String get boxShadow => 'Shadow';

  @override
  String get boxMarginH => 'Outer margin, sides';

  @override
  String get boxMarginV => 'Outer margin, top and bottom';

  @override
  String get boxAuto => 'Auto';

  @override
  String get boxFill => 'Full width';

  @override
  String get boxAlign => 'Position';

  @override
  String get colorHue => 'Hue';

  @override
  String get colorSaturation => 'Saturation';

  @override
  String get colorBrightness => 'Brightness';

  @override
  String get colorOpacity => 'Opacity';

  @override
  String get colorHexHint => 'RRGGBB or AARRGGBB, then Enter';

  @override
  String get sectionParts => 'Design the parts';

  @override
  String get sectionPartsDesc =>
      'Choose Custom and the studio opens next to the chat: add, remove and reorder elements, and style each one and the box freely. Every change shows in the chat right away.';

  @override
  String studioTitle(String part) {
    return 'Design: $part';
  }

  @override
  String get previewNotice => 'Show it: scroll up and receive';

  @override
  String get boxMinHeight => 'Minimum height';
}
