import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

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
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
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

  /// No description provided for @bubbleColor.
  ///
  /// In en, this message translates to:
  /// **'My bubble color'**
  String get bubbleColor;

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

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchNoResults;

  /// No description provided for @searchOlder.
  ///
  /// In en, this message translates to:
  /// **'Older result'**
  String get searchOlder;

  /// No description provided for @searchNewer.
  ///
  /// In en, this message translates to:
  /// **'Newer result'**
  String get searchNewer;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @jumpToLatest.
  ///
  /// In en, this message translates to:
  /// **'Jump to latest'**
  String get jumpToLatest;

  /// No description provided for @receiverBubbleColor.
  ///
  /// In en, this message translates to:
  /// **'Their bubble color'**
  String get receiverBubbleColor;

  /// No description provided for @groupingTitle.
  ///
  /// In en, this message translates to:
  /// **'Group messages'**
  String get groupingTitle;

  /// No description provided for @groupingDesc.
  ///
  /// In en, this message translates to:
  /// **'Messages from the same person in the same minute share one profile'**
  String get groupingDesc;

  /// No description provided for @sendingIndicatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom sending indicator'**
  String get sendingIndicatorTitle;

  /// No description provided for @sendingIndicatorDesc.
  ///
  /// In en, this message translates to:
  /// **'Shown in the bubble until the server answers'**
  String get sendingIndicatorDesc;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @searchResultCount.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String searchResultCount(int current, int total);

  /// No description provided for @searchShortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get searchShortcutsTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @verticalPadding.
  ///
  /// In en, this message translates to:
  /// **'Top and bottom padding'**
  String get verticalPadding;

  /// No description provided for @backgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat background'**
  String get backgroundTitle;

  /// No description provided for @lookCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get lookCustom;

  /// No description provided for @lookLibrary.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get lookLibrary;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get fontSize;

  /// No description provided for @bubblePaddingH.
  ///
  /// In en, this message translates to:
  /// **'Inner padding, sides'**
  String get bubblePaddingH;

  /// No description provided for @bubblePaddingV.
  ///
  /// In en, this message translates to:
  /// **'Inner padding, top and bottom'**
  String get bubblePaddingV;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @myProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfileTitle;

  /// No description provided for @myProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Show a profile next to my messages too'**
  String get myProfileDesc;

  /// No description provided for @scrollThresholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll range'**
  String get scrollThresholdTitle;

  /// No description provided for @menuPopup.
  ///
  /// In en, this message translates to:
  /// **'Popup'**
  String get menuPopup;

  /// No description provided for @menuSheet.
  ///
  /// In en, this message translates to:
  /// **'Bottom sheet'**
  String get menuSheet;

  /// No description provided for @longPressTitle.
  ///
  /// In en, this message translates to:
  /// **'Open on long press'**
  String get longPressTitle;

  /// No description provided for @longPressDesc.
  ///
  /// In en, this message translates to:
  /// **'Off: right-click only'**
  String get longPressDesc;

  /// No description provided for @hapticTitle.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get hapticTitle;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm deleting a failed message'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Set Send result to Fail and try deleting'**
  String get confirmDeleteDesc;

  /// No description provided for @deleteFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get deleteFailedTitle;

  /// No description provided for @deleteFailedBody.
  ///
  /// In en, this message translates to:
  /// **'It was not sent, so the other person never saw it.'**
  String get deleteFailedBody;

  /// No description provided for @kind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get kind;

  /// No description provided for @designBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get designBackground;

  /// No description provided for @designTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get designTextColor;

  /// No description provided for @designRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner radius'**
  String get designRadius;

  /// No description provided for @designHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get designHeight;

  /// No description provided for @designSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get designSize;

  /// No description provided for @designShape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get designShape;

  /// No description provided for @roundness.
  ///
  /// In en, this message translates to:
  /// **'Roundness'**
  String get roundness;

  /// No description provided for @roundFull.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get roundFull;

  /// No description provided for @weekdayTitle.
  ///
  /// In en, this message translates to:
  /// **'Show the weekday'**
  String get weekdayTitle;

  /// No description provided for @use24hTitle.
  ///
  /// In en, this message translates to:
  /// **'24-hour clock'**
  String get use24hTitle;

  /// No description provided for @searchShortcutsDesc.
  ///
  /// In en, this message translates to:
  /// **'Ctrl/⌘ + F opens, Enter goes to the next result, Esc closes'**
  String get searchShortcutsDesc;

  /// No description provided for @sectionBehavior.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get sectionBehavior;

  /// No description provided for @partBubble.
  ///
  /// In en, this message translates to:
  /// **'Bubble'**
  String get partBubble;

  /// No description provided for @partBubbleDesc.
  ///
  /// In en, this message translates to:
  /// **'senderBubbleBuilder and receiverBubbleBuilder get the message content as child; wrap it in any container you like.'**
  String get partBubbleDesc;

  /// No description provided for @partSearch.
  ///
  /// In en, this message translates to:
  /// **'Search bar'**
  String get partSearch;

  /// No description provided for @partSearchDesc.
  ///
  /// In en, this message translates to:
  /// **'Open it with the search button above the chat. Style the toolkit\'s ChatSearchBar, or build your own bar on the ChatSearchController: search(), showOlder(), showNewer(), close().'**
  String get partSearchDesc;

  /// No description provided for @partInput.
  ///
  /// In en, this message translates to:
  /// **'Input field'**
  String get partInput;

  /// No description provided for @partInputDesc.
  ///
  /// In en, this message translates to:
  /// **'The chat only places customInputField at the bottom. The field and sending (controller.dispatchMessage) are yours.'**
  String get partInputDesc;

  /// No description provided for @partNotice.
  ///
  /// In en, this message translates to:
  /// **'New message notice'**
  String get partNotice;

  /// No description provided for @partNoticeDesc.
  ///
  /// In en, this message translates to:
  /// **'Shown when a message arrives while you are scrolled up. Scroll up, then press Receive above the chat.'**
  String get partNoticeDesc;

  /// No description provided for @partSeparator.
  ///
  /// In en, this message translates to:
  /// **'Date separator'**
  String get partSeparator;

  /// No description provided for @partSeparatorDesc.
  ///
  /// In en, this message translates to:
  /// **'Shown between messages of different days; the builder gets the timestamp of the day.'**
  String get partSeparatorDesc;

  /// No description provided for @partTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get partTime;

  /// No description provided for @partTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Shown next to the last bubble of a group; the builder gets the message timestamp.'**
  String get partTimeDesc;

  /// No description provided for @partProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get partProfile;

  /// No description provided for @partProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Shown once per group of messages; the builder gets the sender name.'**
  String get partProfileDesc;

  /// No description provided for @partRead.
  ///
  /// In en, this message translates to:
  /// **'Read indicator'**
  String get partRead;

  /// No description provided for @partReadDesc.
  ///
  /// In en, this message translates to:
  /// **'Shown for SenderMessage(isRead: false/true). Send a message, then press Mark all read.'**
  String get partReadDesc;

  /// No description provided for @partMenu.
  ///
  /// In en, this message translates to:
  /// **'Bubble menu'**
  String get partMenu;

  /// No description provided for @partMenuDesc.
  ///
  /// In en, this message translates to:
  /// **'Long-press or right-click a bubble. Use the toolkit\'s popup with your items, or a handler that shows anything.'**
  String get partMenuDesc;

  /// No description provided for @partReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only notice'**
  String get partReadOnly;

  /// No description provided for @partReadOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'With Chat(readOnly: true), readOnlyWidget replaces the input field.'**
  String get partReadOnlyDesc;

  /// No description provided for @studioEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get studioEdit;

  /// No description provided for @studioReset.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get studioReset;

  /// No description provided for @tabStructure.
  ///
  /// In en, this message translates to:
  /// **'Structure'**
  String get tabStructure;

  /// No description provided for @tabStyle.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get tabStyle;

  /// No description provided for @tabCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get tabCode;

  /// No description provided for @layoutAxis.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get layoutAxis;

  /// No description provided for @axisRow.
  ///
  /// In en, this message translates to:
  /// **'Row'**
  String get axisRow;

  /// No description provided for @axisColumn.
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get axisColumn;

  /// No description provided for @layoutMain.
  ///
  /// In en, this message translates to:
  /// **'Align along'**
  String get layoutMain;

  /// No description provided for @layoutCross.
  ///
  /// In en, this message translates to:
  /// **'Align across'**
  String get layoutCross;

  /// No description provided for @layoutGap.
  ///
  /// In en, this message translates to:
  /// **'Gap'**
  String get layoutGap;

  /// No description provided for @alignStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get alignStart;

  /// No description provided for @alignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get alignCenter;

  /// No description provided for @alignEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get alignEnd;

  /// No description provided for @alignBetween.
  ///
  /// In en, this message translates to:
  /// **'Spread'**
  String get alignBetween;

  /// No description provided for @elements.
  ///
  /// In en, this message translates to:
  /// **'Elements'**
  String get elements;

  /// No description provided for @elementsHint.
  ///
  /// In en, this message translates to:
  /// **'Drag ⋮⋮ to reorder, tap an element to style it'**
  String get elementsHint;

  /// No description provided for @addElement.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addElement;

  /// No description provided for @elementVisible.
  ///
  /// In en, this message translates to:
  /// **'Show or hide'**
  String get elementVisible;

  /// No description provided for @elContent.
  ///
  /// In en, this message translates to:
  /// **'Message content'**
  String get elContent;

  /// No description provided for @elText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get elText;

  /// No description provided for @elIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get elIcon;

  /// No description provided for @elField.
  ///
  /// In en, this message translates to:
  /// **'Input field'**
  String get elField;

  /// No description provided for @elButton.
  ///
  /// In en, this message translates to:
  /// **'Button'**
  String get elButton;

  /// No description provided for @elBadge.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get elBadge;

  /// No description provided for @elAvatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get elAvatar;

  /// No description provided for @elSpacer.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get elSpacer;

  /// No description provided for @elDivider.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get elDivider;

  /// No description provided for @propSource.
  ///
  /// In en, this message translates to:
  /// **'Shows'**
  String get propSource;

  /// No description provided for @propText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get propText;

  /// No description provided for @propTextUnread.
  ///
  /// In en, this message translates to:
  /// **'Text before read'**
  String get propTextUnread;

  /// No description provided for @propTextRead.
  ///
  /// In en, this message translates to:
  /// **'Text after read'**
  String get propTextRead;

  /// No description provided for @propIconUnread.
  ///
  /// In en, this message translates to:
  /// **'Icon before read'**
  String get propIconUnread;

  /// No description provided for @propIconRead.
  ///
  /// In en, this message translates to:
  /// **'Icon after read'**
  String get propIconRead;

  /// No description provided for @propHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get propHint;

  /// No description provided for @propAction.
  ///
  /// In en, this message translates to:
  /// **'Does'**
  String get propAction;

  /// No description provided for @propBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get propBold;

  /// No description provided for @propColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get propColor;

  /// No description provided for @propExpand.
  ///
  /// In en, this message translates to:
  /// **'Fill the remaining space'**
  String get propExpand;

  /// No description provided for @propWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get propWidth;

  /// No description provided for @propThickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness'**
  String get propThickness;

  /// No description provided for @lookFilled.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get lookFilled;

  /// No description provided for @srcLiteral.
  ///
  /// In en, this message translates to:
  /// **'Typed'**
  String get srcLiteral;

  /// No description provided for @srcName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get srcName;

  /// No description provided for @srcTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get srcTime;

  /// No description provided for @srcDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get srcDate;

  /// No description provided for @srcCount.
  ///
  /// In en, this message translates to:
  /// **'Result count'**
  String get srcCount;

  /// No description provided for @srcRead.
  ///
  /// In en, this message translates to:
  /// **'Read state'**
  String get srcRead;

  /// No description provided for @srcNotice.
  ///
  /// In en, this message translates to:
  /// **'Notice text'**
  String get srcNotice;

  /// No description provided for @srcReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Notice text'**
  String get srcReadOnly;

  /// No description provided for @actNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get actNone;

  /// No description provided for @actAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get actAttach;

  /// No description provided for @boxGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get boxGradient;

  /// No description provided for @boxGradientTo.
  ///
  /// In en, this message translates to:
  /// **'Gradient end'**
  String get boxGradientTo;

  /// No description provided for @boxBorder.
  ///
  /// In en, this message translates to:
  /// **'Border width'**
  String get boxBorder;

  /// No description provided for @boxBorderColor.
  ///
  /// In en, this message translates to:
  /// **'Border color'**
  String get boxBorderColor;

  /// No description provided for @boxShadow.
  ///
  /// In en, this message translates to:
  /// **'Shadow'**
  String get boxShadow;

  /// No description provided for @boxMarginH.
  ///
  /// In en, this message translates to:
  /// **'Outer margin, sides'**
  String get boxMarginH;

  /// No description provided for @boxMarginV.
  ///
  /// In en, this message translates to:
  /// **'Outer margin, top and bottom'**
  String get boxMarginV;

  /// No description provided for @boxAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get boxAuto;

  /// No description provided for @boxFill.
  ///
  /// In en, this message translates to:
  /// **'Full width'**
  String get boxFill;

  /// No description provided for @boxAlign.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get boxAlign;

  /// No description provided for @colorHue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get colorHue;

  /// No description provided for @colorSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get colorSaturation;

  /// No description provided for @colorBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get colorBrightness;

  /// No description provided for @colorOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get colorOpacity;

  /// No description provided for @colorHexHint.
  ///
  /// In en, this message translates to:
  /// **'RRGGBB or AARRGGBB, then Enter'**
  String get colorHexHint;

  /// No description provided for @sectionParts.
  ///
  /// In en, this message translates to:
  /// **'Design the parts'**
  String get sectionParts;

  /// No description provided for @sectionPartsDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose Custom and the studio opens next to the chat: add, remove and reorder elements, and style each one and the box freely. Every change shows in the chat right away.'**
  String get sectionPartsDesc;

  /// No description provided for @studioTitle.
  ///
  /// In en, this message translates to:
  /// **'Design: {part}'**
  String studioTitle(String part);

  /// No description provided for @previewNotice.
  ///
  /// In en, this message translates to:
  /// **'Show it: scroll up and receive'**
  String get previewNotice;

  /// No description provided for @boxMinHeight.
  ///
  /// In en, this message translates to:
  /// **'Minimum height'**
  String get boxMinHeight;

  /// No description provided for @srcPreview.
  ///
  /// In en, this message translates to:
  /// **'Message summary'**
  String get srcPreview;

  /// No description provided for @newMessageArrived.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessageArrived;
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
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
