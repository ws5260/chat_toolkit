import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'chat_controller.dart';
import 'message/bubble_menu.dart';
import 'message/entity/message.dart';
import 'message/message_loading.dart';
import 'search/chat_search.dart';
import 'search/chat_search_controller.dart';

/// Appearance options for message bubbles, profiles and timestamps.
///
/// Passed to [Chat] through [ChatConfiguration.bubbleConfiguration].
/// Every builder is optional; when one is `null` a simple default is used.
/// Sender and receiver bubbles and profiles are built separately, so each
/// side can have its own look.
///
/// Each bubble shows its [Message.elements] inside the bubble builder, and a
/// trailing area beside it with the [readIndicatorBuilder] (if set), the
/// timestamp (on the last bubble of each [MessageGroup] only), or the retry
/// and delete buttons of a failed message. The profile is shown once per
/// group.
///
/// ```dart
/// Chat(
///   chatController: controller,
///   configuration: ChatConfiguration(
///     bubbleConfiguration: BubbleConfiguration(
///       maxWidth: 280,
///       receiverProfileBuilder: (context, name) => CircleAvatar(child: Text(name[0])),
///       senderProfileBuilder: (context, name) => const SizedBox.shrink(),
///       senderBubbleBuilder: (context, child) => DecoratedBox(
///         decoration: BoxDecoration(
///           color: Colors.blue.shade100,
///           borderRadius: BorderRadius.circular(16),
///         ),
///         child: Padding(padding: const EdgeInsets.all(12), child: child),
///       ),
///       timeBuilder: (context, timestamp) =>
///           Text(DateFormat.Hm().format(DateTime.parse(timestamp).toLocal())),
///       readIndicatorBuilder: (context, isRead) =>
///           Icon(isRead ? Icons.done_all : Icons.done, size: 14),
///       timeStyle: const TextStyle(fontSize: 11, color: Colors.grey),
///     ),
///   ),
/// )
/// ```
class BubbleConfiguration {
  /// Builds the profile shown next to a group of sender messages.
  ///
  /// Receives the sender's [Message.name] (the group's [MessageGroup.name]).
  /// Defaults to a grey avatar icon with the name below it. Return
  /// `SizedBox.shrink()` to hide the profile of your own messages.
  final Widget Function(BuildContext context, String name)? senderProfileBuilder;

  /// Builds the profile shown next to a group of receiver messages.
  ///
  /// Receives the receiver's [Message.name]. Defaults to a grey avatar icon
  /// with the name below it.
  final Widget Function(BuildContext context, String name)? receiverProfileBuilder;

  /// Wraps the content of a sender message in a bubble.
  ///
  /// [child] is the message content built from its [MessageElement]s (or
  /// [loadingWidget] while sending), already limited to [maxWidth]. Defaults
  /// to a light grey rounded container using [padding].
  final Widget Function(BuildContext context, Widget child)? senderBubbleBuilder;

  /// Wraps the content of a receiver message in a bubble.
  ///
  /// [child] is the message content built from its [MessageElement]s (or
  /// [loadingWidget] while loading), already limited to [maxWidth]. Defaults
  /// to a light blue rounded container using [padding].
  final Widget Function(BuildContext context, Widget child)? receiverBubbleBuilder;

  /// Builds the timestamp shown beside the last bubble of a group.
  ///
  /// Receives the raw [Message.timestamp] string of that bubble's message.
  /// Not shown while the message is loading or failed. Defaults to the date
  /// formatted as `yyyy.MM.dd` (which throws a [FormatException] for a
  /// timestamp [DateTime.parse] cannot parse); provide a builder to show the
  /// time of day.
  final Widget Function(BuildContext context, String timestamp)? timeBuilder;

  /// Builds a read/unread indicator beside a bubble.
  ///
  /// Called with [Message.isRead] for every bubble whose [Message.isRead] is
  /// not `null` (not only the last of a group), except while the message is
  /// loading or failed. Shown above the timestamp when both are present.
  /// When `null`, no indicator is shown.
  /// [ChatController.updateMessageAllRead] marks unread messages as read.
  final Widget Function(BuildContext context, bool isRead)? readIndicatorBuilder;

  /// Widget shown inside a bubble while its message is being sent
  /// ([Message.isLoading] is `true`).
  ///
  /// Defaults to an animated three-dot indicator.
  final Widget loadingWidget;

  /// Maximum width of a bubble.
  ///
  /// Overridden per message by [Message.width]. Defaults to [double.infinity].
  final double maxWidth;

  /// Inner padding of the default bubbles.
  ///
  /// Ignored when [senderBubbleBuilder] / [receiverBubbleBuilder] is set.
  /// Defaults to `EdgeInsets.all(16)`.
  final EdgeInsetsGeometry? padding;

  /// Text style for the name in the profile.
  ///
  /// Also applied as the [DefaultTextStyle] of custom profile builders.
  final TextStyle? profileNameStyle;

  /// Text style for the timestamp.
  ///
  /// Also applied as the [DefaultTextStyle] of a custom [timeBuilder].
  final TextStyle? timeStyle;

  /// Context menu opened by a long press on a bubble.
  ///
  /// Sender and receiver menus are configured separately. `null` (the
  /// default) disables it. See [BubbleMenuConfiguration].
  final BubbleMenuConfiguration? menuConfiguration;

  /// Creates a [BubbleConfiguration].
  const BubbleConfiguration({
    this.senderProfileBuilder,
    this.receiverProfileBuilder,
    this.senderBubbleBuilder,
    this.receiverBubbleBuilder,
    this.timeBuilder,
    this.loadingWidget = const MessageLoading(),
    this.maxWidth = double.infinity,
    this.padding = const EdgeInsets.all(16),
    this.profileNameStyle,
    this.timeStyle,
    this.menuConfiguration,

    this.readIndicatorBuilder,
  });

  /// Builds the profile for a group, using [senderProfileBuilder] or
  /// [receiverProfileBuilder] depending on [isSender], or the default profile.
  ///
  /// Called by [Chat]; apps rarely need to call it. A custom builder is
  /// wrapped in a [DefaultTextStyle] of [profileNameStyle] when that is set.
  Widget buildProfile(BuildContext context, String name, bool isSender) {
    final profileBuilder = isSender ? senderProfileBuilder : receiverProfileBuilder;

    if (profileBuilder != null) {
      if (profileNameStyle == null) return profileBuilder.call(context, name);
      return DefaultTextStyle(style: profileNameStyle!, child: profileBuilder.call(context, name));
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: const Color(0xFFE9E9E9),
            width: 40,
            height: 40,
            child: const Icon(Icons.person),
          ),
        ),
        const Gap(4),
        Text(name, style: profileNameStyle),
      ],
    );
  }

  /// Wraps [child] in a bubble, using [senderBubbleBuilder] or
  /// [receiverBubbleBuilder] depending on [isSender], or the default bubble.
  ///
  /// Called by [Chat]; apps rarely need to call it.
  Widget buildBubble(BuildContext context, Widget child, bool isSender) {
    if (isSender) {
      return senderBubbleBuilder?.call(context, child) ??
          Container(
            padding: padding,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F4F4),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: child,
          );
    } else {
      return receiverBubbleBuilder?.call(context, child) ??
          Container(
            padding: padding,
            decoration: const BoxDecoration(
              color: Color(0xFFE9EEFF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
                topLeft: Radius.circular(16),
              ),
            ),
            child: child,
          );
    }
  }

  /// Builds the timestamp widget with [timeBuilder] or the default format.
  ///
  /// Called by [Chat]; apps rarely need to call it. A custom builder is
  /// wrapped in a [DefaultTextStyle] of [timeStyle] when that is set.
  Widget buildTime(BuildContext context, String timestamp) {
    if (timeBuilder != null) {
      if (timeStyle == null) {
        return timeBuilder!.call(context, timestamp);
      }
      return DefaultTextStyle(style: timeStyle!, child: timeBuilder!.call(context, timestamp));
    }
    return Text(DateFormat("yyyy.MM.dd").format(DateTime.parse(timestamp)), style: timeStyle);
  }
}

/// Horizontal side of the chat on which sender messages are placed.
enum ChatAlignment {
  /// The leading side (left in left-to-right layouts).
  start,

  /// The trailing side (right in left-to-right layouts).
  end,
}

/// Visual and behavioral options for the chat UI.
///
/// Passed to [Chat.configuration]. Bubble-level appearance (bubbles,
/// profiles, timestamps, context menu) lives in [bubbleConfiguration]; this
/// class covers the list as a whole: which side messages are on, date
/// separators, the "new message" notification, the read-only banner,
/// padding and the entrance animation.
///
/// ```dart
/// Chat(
///   chatController: controller,
///   configuration: ChatConfiguration(
///     senderAlignment: ChatAlignment.end,
///     padding: const EdgeInsets.symmetric(horizontal: 16),
///     messageAppearAnimationDuration: const Duration(milliseconds: 250),
///     dateSeparatorBuilder: (context, timestamp) => Center(
///       child: Text(DateFormat.yMMMd().format(DateTime.parse(timestamp))),
///     ),
///     newReceiveMessageNotificationBuilder: (context, message, controller) =>
///         TextButton(
///           onPressed: controller.scrollToBottom,
///           child: Text('New message from ${message.name}'),
///         ),
///     bubbleConfiguration: const BubbleConfiguration(maxWidth: 280),
///   ),
/// )
/// ```
class ChatConfiguration {
  /// Side on which sender messages ([SenderMessage]) are shown.
  ///
  /// Receiver messages are placed on the opposite side. Defaults to
  /// [ChatAlignment.end].
  final ChatAlignment senderAlignment;

  /// Builds a "new message" notification shown at the bottom of the chat
  /// when a receiver message arrives while the user has scrolled up.
  ///
  /// Receives the new message and the [ChatController] (e.g. to call
  /// [ChatController.scrollToBottom] on tap). When the user is within
  /// [newMessageScrollThreshold] of the bottom, the chat scrolls down
  /// automatically instead. The notification is hidden once the user
  /// scrolls back within that distance.
  ///
  /// Only messages emitted on [ChatController.newReceiveMessageStream]
  /// trigger it, that is [ReceiverMessage]s returned by the callback of
  /// [ChatController.dispatchMessage]; messages added with
  /// [ChatController.addMessage] do not.
  ///
  /// When `null`, this feature, including the auto-scroll, is disabled.
  /// [Chat] decides whether to listen when it is first built, so switching
  /// between `null` and a builder later has no effect.
  final Widget Function(BuildContext, Message, ChatController)?
  newReceiveMessageNotificationBuilder;

  /// Builds the separator shown between messages from different days.
  ///
  /// Receives the raw [Message.timestamp] of the first message of the new
  /// day. A separator is also shown above the oldest loaded group. Days are
  /// compared on the parsed [DateTime] values as given (no time zone
  /// conversion). Defaults to a divider with the date formatted as
  /// `yyyy.MM.dd`.
  final Widget Function(BuildContext, String)? dateSeparatorBuilder;

  /// Widget shown in place of the input field when [Chat.readOnly] is `true`.
  ///
  /// Defaults to a small grey banner.
  final Widget? readOnlyWidget;

  /// Appearance options for bubbles, profiles and timestamps.
  final BubbleConfiguration bubbleConfiguration;

  /// Distance in logical pixels from the newest message within which the
  /// chat auto-scrolls to a newly received message, instead of showing the
  /// notification.
  ///
  /// Only used together with [newReceiveMessageNotificationBuilder].
  /// Defaults to `300`.
  final double newMessageScrollThreshold;

  /// Text style for the date separator.
  ///
  /// Also applied as the [DefaultTextStyle] of a custom [dateSeparatorBuilder].
  final TextStyle? dateSeparatorStyle;

  /// Padding around the message list.
  ///
  /// Defaults to `EdgeInsets.symmetric(horizontal: 30)`.
  final EdgeInsets padding;

  /// Duration of the entrance animation for newly added messages.
  ///
  /// A message added with [ChatController.addMessage] or
  /// [ChatController.dispatchMessage] grows from zero height (pushing the
  /// list smoothly), slides up and fades in. A new group animates as a whole,
  /// including its profile. Messages loaded with [ChatController.setMessages]
  /// or [ChatController.appendMessages] do not animate, and each message
  /// animates at most once (not again when scrolled back into view).
  ///
  /// `null` (the default) disables the animation.
  final Duration? messageAppearAnimationDuration;

  /// Whether the chat shows its messages from the top while they do not fill the screen.
  ///
  /// The list is laid out from the bottom (newest message at scroll offset `0`), so two or three
  /// messages sit at the bottom with empty space above them. With this set, the empty space goes
  /// below them instead. Once the messages fill the screen nothing changes: the newest message
  /// stays at the bottom. Defaults to `false`.
  final bool messagesStartAtTop;

  /// Builds the highlight of a message revealed by
  /// [ChatController.scrollToMessage] or [ChatController.setMessagesAround].
  ///
  /// [animation] runs from `1.0` down to `0.0` over
  /// [messageHighlightDuration]; wrap [child] (the message bubble row) in
  /// something that fades with it. When `null`, a translucent yellow
  /// background fades out behind the message.
  ///
  /// ```dart
  /// ChatConfiguration(
  ///   messageHighlightBuilder: (context, child, animation) => FadeTransition(
  ///     opacity: Tween(begin: 1.0, end: 0.4).animate(animation),
  ///     child: child,
  ///   ),
  /// )
  /// ```
  final Widget Function(BuildContext context, Widget child, Animation<double> animation)?
      messageHighlightBuilder;

  /// How long the highlight of [messageHighlightBuilder] lasts. Defaults to
  /// 1.5 seconds.
  final Duration messageHighlightDuration;

  /// Builds the search bar shown above the messages while the
  /// `Chat.searchController` is open.
  ///
  /// Return a [ChatSearchBar] with your texts and styles, or a bar of your
  /// own driven by the [ChatSearchController]. Return a `SizedBox.shrink()`
  /// to place the search elsewhere (e.g. in your app bar). When `null`, a
  /// default [ChatSearchBar] is shown.
  ///
  /// ```dart
  /// ChatConfiguration(
  ///   searchBarBuilder: (context, search) => ChatSearchBar(
  ///     controller: search,
  ///     hintText: 'Search this chat',
  ///   ),
  /// )
  /// ```
  final Widget Function(BuildContext context, ChatSearchController search)? searchBarBuilder;

  /// Keyboard shortcuts of the search, active while the chat is shown,
  /// wherever the focus is. Map key combinations to [OpenChatSearchIntent],
  /// [CloseChatSearchIntent], [ShowOlderSearchResultIntent] and
  /// [ShowNewerSearchResultIntent]. Defaults to
  /// [defaultChatSearchShortcuts]; pass `{}` to turn them off.
  ///
  /// To bind keys outside the chat, call the [ChatSearchController] methods
  /// from your own [Shortcuts] or key handler.
  final Map<ShortcutActivator, Intent> searchShortcuts;

  /// Creates a [ChatConfiguration].
  const ChatConfiguration({
    this.senderAlignment = ChatAlignment.end,
    this.newReceiveMessageNotificationBuilder,
    this.bubbleConfiguration = const BubbleConfiguration(),
    this.readOnlyWidget,
    this.newMessageScrollThreshold = 300,
    this.dateSeparatorBuilder,
    this.dateSeparatorStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 30),
    this.messageAppearAnimationDuration,
    this.messagesStartAtTop = false,
    this.messageHighlightBuilder,
    this.messageHighlightDuration = const Duration(milliseconds: 1500),
    this.searchBarBuilder,
    this.searchShortcuts = defaultChatSearchShortcuts,
  });

  /// Whether sender messages are on the leading side
  /// ([senderAlignment] is [ChatAlignment.start]).
  ///
  /// Used by the toolkit's layout; apps can read [senderAlignment] instead.
  bool get isPrevProfile => senderAlignment == ChatAlignment.start;

  /// Builds the highlight of a message with [messageHighlightBuilder] or the
  /// default one.
  ///
  /// Called by [Chat]; apps rarely need to call it.
  Widget buildMessageHighlight(BuildContext context, Widget child, Animation<double> animation) {
    final builder = messageHighlightBuilder;
    if (builder != null) return builder(context, child, animation);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.45 * animation.value),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  /// Builds the date separator with [dateSeparatorBuilder] or the default one.
  ///
  /// Called by [Chat]; apps rarely need to call it. A custom builder is
  /// wrapped in a [DefaultTextStyle] of [dateSeparatorStyle] when that is
  /// set.
  Widget buildDateDivider(BuildContext context, String timestamp) {
    if (dateSeparatorBuilder != null) {
      if (dateSeparatorStyle == null) {
        return dateSeparatorBuilder!.call(context, timestamp);
      }
      return DefaultTextStyle(
        style: dateSeparatorStyle!,
        child: dateSeparatorBuilder!.call(context, timestamp),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          const Gap(20),
          Text(
            DateFormat("yyyy.MM.dd").format(DateTime.parse(timestamp)),
            style: dateSeparatorStyle,
          ),
          const Gap(20),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
