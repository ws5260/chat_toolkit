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
  String get sectionBubble => 'Bubbles';

  @override
  String get bubbleColor => 'My bubble color';

  @override
  String get cornerRadius => 'Corner radius';

  @override
  String get maxWidth => 'Max width';

  @override
  String get noLimit => 'No limit';

  @override
  String get appearAnimation => 'Entrance animation';

  @override
  String get off => 'Off';

  @override
  String get sectionDisplay => 'Display';

  @override
  String get timeTitle => 'Sent time';

  @override
  String get timeDesc => 'Off shows the default format';

  @override
  String get profileTitle => 'Other person\'s profile';

  @override
  String get unreadTitle => 'Unread indicator';

  @override
  String get unreadDesc => 'Shown on messages you send from now on';

  @override
  String get longPressMenuTitle => 'Long-press menu';

  @override
  String get notificationTitle => 'New message notice';

  @override
  String get notificationDesc =>
      'Shown when a message arrives while you are scrolled up';

  @override
  String get dateSeparatorTitle => 'Custom date separator';

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
}
