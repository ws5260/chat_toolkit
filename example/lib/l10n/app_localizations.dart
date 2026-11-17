import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @navPlayground.
  ///
  /// In en, this message translates to:
  /// **'Playground'**
  String get navPlayground;

  /// No description provided for @navExamples.
  ///
  /// In en, this message translates to:
  /// **'Examples'**
  String get navExamples;

  /// No description provided for @navGettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get navGettingStarted;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @playgroundIntro.
  ///
  /// In en, this message translates to:
  /// **'Change an option and the chat updates right away. Messages are simulated, so send as many as you like.'**
  String get playgroundIntro;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @receiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receiveMessage;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get restart;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @inputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get inputHint;

  /// No description provided for @incomingMessage.
  ///
  /// In en, this message translates to:
  /// **'New message ({count})'**
  String incomingMessage(int count);

  /// No description provided for @autoReply.
  ///
  /// In en, this message translates to:
  /// **'Got it: \"{text}\"'**
  String autoReply(String text);

  /// No description provided for @newMessageFrom.
  ///
  /// In en, this message translates to:
  /// **'New message from {name}'**
  String newMessageFrom(String name);

  /// No description provided for @readOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'This chat is read-only'**
  String get readOnlyNotice;

  /// No description provided for @menuRetry.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get menuRetry;

  /// No description provided for @menuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get menuDelete;

  /// No description provided for @menuCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get menuCopy;

  /// No description provided for @sectionLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get sectionLayout;

  /// No description provided for @startAtTopTitle.
  ///
  /// In en, this message translates to:
  /// **'Few messages start at the top'**
  String get startAtTopTitle;

  /// No description provided for @startAtTopDesc.
  ///
  /// In en, this message translates to:
  /// **'Instead of sitting at the bottom'**
  String get startAtTopDesc;

  /// No description provided for @senderSideTitle.
  ///
  /// In en, this message translates to:
  /// **'My messages on'**
  String get senderSideTitle;

  /// No description provided for @sideRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get sideRight;

  /// No description provided for @sideLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get sideLeft;

  /// No description provided for @sidePadding.
  ///
  /// In en, this message translates to:
  /// **'Side padding'**
  String get sidePadding;

  /// No description provided for @sectionBubble.
  ///
  /// In en, this message translates to:
  /// **'Bubbles'**
  String get sectionBubble;

  /// No description provided for @bubbleColor.
  ///
  /// In en, this message translates to:
  /// **'My bubble color'**
  String get bubbleColor;

  /// No description provided for @cornerRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner radius'**
  String get cornerRadius;

  /// No description provided for @maxWidth.
  ///
  /// In en, this message translates to:
  /// **'Max width'**
  String get maxWidth;

  /// No description provided for @noLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimit;

  /// No description provided for @appearAnimation.
  ///
  /// In en, this message translates to:
  /// **'Entrance animation'**
  String get appearAnimation;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @sectionDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get sectionDisplay;

  /// No description provided for @timeTitle.
  ///
  /// In en, this message translates to:
  /// **'Sent time'**
  String get timeTitle;

  /// No description provided for @timeDesc.
  ///
  /// In en, this message translates to:
  /// **'Off shows the default format'**
  String get timeDesc;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Other person\'s profile'**
  String get profileTitle;

  /// No description provided for @unreadTitle.
  ///
  /// In en, this message translates to:
  /// **'Unread indicator'**
  String get unreadTitle;

  /// No description provided for @unreadDesc.
  ///
  /// In en, this message translates to:
  /// **'Shown on messages you send from now on'**
  String get unreadDesc;

  /// No description provided for @longPressMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Long-press menu'**
  String get longPressMenuTitle;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'New message notice'**
  String get notificationTitle;

  /// No description provided for @notificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Shown when a message arrives while you are scrolled up'**
  String get notificationDesc;

  /// No description provided for @dateSeparatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom date separator'**
  String get dateSeparatorTitle;

  /// No description provided for @readOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get readOnlyTitle;

  /// No description provided for @readOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Shows a notice instead of the input field'**
  String get readOnlyDesc;

  /// No description provided for @sectionServer.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get sectionServer;

  /// No description provided for @storedMessages.
  ///
  /// In en, this message translates to:
  /// **'Stored messages'**
  String get storedMessages;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @messageCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String messageCount(int count);

  /// No description provided for @responseTime.
  ///
  /// In en, this message translates to:
  /// **'Response time'**
  String get responseTime;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'{value}s'**
  String seconds(String value);

  /// No description provided for @imagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Mix in image messages'**
  String get imagesTitle;

  /// No description provided for @imagesDesc.
  ///
  /// In en, this message translates to:
  /// **'30% are images that load late'**
  String get imagesDesc;

  /// No description provided for @sendResult.
  ///
  /// In en, this message translates to:
  /// **'Send result'**
  String get sendResult;

  /// No description provided for @resultSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get resultSuccess;

  /// No description provided for @resultFail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get resultFail;

  /// No description provided for @resultBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get resultBlock;

  /// No description provided for @autoReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto reply'**
  String get autoReplyTitle;

  /// No description provided for @autoReplyDesc.
  ///
  /// In en, this message translates to:
  /// **'After a successful send, the other person reads it and replies'**
  String get autoReplyDesc;

  /// No description provided for @examplesIntro.
  ///
  /// In en, this message translates to:
  /// **'Chat rooms that load their messages from a server. Each room has a different size and response time, so you can see how scrolling behaves.'**
  String get examplesIntro;

  /// No description provided for @roomShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Short room'**
  String get roomShortTitle;

  /// No description provided for @roomShortDesc.
  ///
  /// In en, this message translates to:
  /// **'5 messages, not enough to fill the screen'**
  String get roomShortDesc;

  /// No description provided for @roomNormalTitle.
  ///
  /// In en, this message translates to:
  /// **'Normal room'**
  String get roomNormalTitle;

  /// No description provided for @roomNormalDesc.
  ///
  /// In en, this message translates to:
  /// **'60 messages in 2 pages of 30'**
  String get roomNormalDesc;

  /// No description provided for @roomLongTitle.
  ///
  /// In en, this message translates to:
  /// **'Long room'**
  String get roomLongTitle;

  /// No description provided for @roomLongDesc.
  ///
  /// In en, this message translates to:
  /// **'500 messages, 30 more each time you reach the top'**
  String get roomLongDesc;

  /// No description provided for @roomImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Image room'**
  String get roomImagesTitle;

  /// No description provided for @roomImagesDesc.
  ///
  /// In en, this message translates to:
  /// **'120 messages, 40% are images that load late and grow'**
  String get roomImagesDesc;

  /// No description provided for @roomSlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Slow server'**
  String get roomSlowTitle;

  /// No description provided for @roomSlowDesc.
  ///
  /// In en, this message translates to:
  /// **'200 messages, responses take 2 seconds'**
  String get roomSlowDesc;

  /// No description provided for @loadingOlder.
  ///
  /// In en, this message translates to:
  /// **'Loading older messages'**
  String get loadingOlder;

  /// No description provided for @gsIntro.
  ///
  /// In en, this message translates to:
  /// **'Grouping, date separators, failed sends and retries, and loading older messages, all handled by one ChatController.'**
  String get gsIntro;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Install the package'**
  String get step1Title;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'Define how message content is drawn'**
  String get step2Title;

  /// No description provided for @step2Desc.
  ///
  /// In en, this message translates to:
  /// **'Describe what goes inside a bubble, such as text or images, as a MessageElement.'**
  String get step2Desc;

  /// No description provided for @step3Title.
  ///
  /// In en, this message translates to:
  /// **'Add the chat'**
  String get step3Title;

  /// No description provided for @step3Desc.
  ///
  /// In en, this message translates to:
  /// **'Put messages from the server in with setMessages, and older ones loaded on scroll with appendMessages.'**
  String get step3Desc;

  /// No description provided for @step4Title.
  ///
  /// In en, this message translates to:
  /// **'Send messages'**
  String get step4Title;

  /// No description provided for @step4Desc.
  ///
  /// In en, this message translates to:
  /// **'Returning null marks the message as failed; long-press it to send again.'**
  String get step4Desc;

  /// No description provided for @gsCtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Want to try the options?'**
  String get gsCtaTitle;

  /// No description provided for @gsCtaDesc.
  ///
  /// In en, this message translates to:
  /// **'See how each setting changes the chat in the playground.'**
  String get gsCtaDesc;

  /// No description provided for @gsCtaButton.
  ///
  /// In en, this message translates to:
  /// **'Open playground'**
  String get gsCtaButton;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
