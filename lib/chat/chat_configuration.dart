import 'chat_controller.dart';
import 'message/bubble_menu.dart';
import 'message/entity/message.dart';
import 'message/message_loading.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// Appearance options for message bubbles, profiles and timestamps.
///
/// Passed to [Chat] through [ChatConfiguration.bubbleConfiguration].
/// Every builder is optional; when one is `null` a simple default is used.
class BubbleConfiguration {
  /// Builds the profile shown next to a group of sender messages.
  ///
  /// Receives the sender's [Message.name]. Defaults to a grey avatar icon
  /// with the name below it.
  final Widget Function(BuildContext context, String name)? senderProfileBuilder;

  /// Builds the profile shown next to a group of receiver messages.
  ///
  /// Receives the receiver's [Message.name]. Defaults to a grey avatar icon
  /// with the name below it.
  final Widget Function(BuildContext context, String name)? receiverProfileBuilder;

  /// Wraps the content of a sender message in a bubble.
  ///
  /// [child] is the message content built from its [MessageElement]s.
  /// Defaults to a light grey rounded container using [padding].
  final Widget Function(BuildContext context, Widget child)? senderBubbleBuilder;

  /// Wraps the content of a receiver message in a bubble.
  ///
  /// [child] is the message content built from its [MessageElement]s.
  /// Defaults to a light blue rounded container using [padding].
  final Widget Function(BuildContext context, Widget child)? receiverBubbleBuilder;

  /// Builds the timestamp shown beside the last bubble of a group.
  ///
  /// Receives the raw [Message.timestamp] string. Defaults to the date
  /// formatted as `yyyy.MM.dd`.
  final Widget Function(BuildContext context, String timestamp)? timeBuilder;

  /// Builds a read/unread indicator beside a bubble.
  ///
  /// Only shown for messages whose [Message.isRead] is not `null`.
  /// When `null`, no indicator is shown.
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

  /// Context menu opened by a long press or a right click on a bubble.
  /// Sender and receiver menus are configured separately. `null` disables it.
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
/// Passed to [Chat.configuration].
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
  /// automatically instead. When `null`, this feature is disabled.
  final Widget Function(BuildContext, Message, ChatController)?
  newReceiveMessageNotificationBuilder;

  /// Builds the separator shown between messages from different days.
  ///
  /// Receives the raw [Message.timestamp] of the first message of the new
  /// day. Defaults to a divider with the date formatted as `yyyy.MM.dd`.
  final Widget Function(BuildContext, String)? dateSeparatorBuilder;

  /// Widget shown in place of the input field when [Chat.readOnly] is `true`.
  ///
  /// Defaults to a small grey banner.
  final Widget? readOnlyWidget;

  /// Appearance options for bubbles, profiles and timestamps.
  final BubbleConfiguration bubbleConfiguration;

  /// Distance in logical pixels from the bottom within which the chat
  /// auto-scrolls to a newly received message.
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
  });

  /// Whether sender messages are on the leading side
  /// ([senderAlignment] is [ChatAlignment.start]).
  bool get isPrevProfile => senderAlignment == ChatAlignment.start;

  /// Builds the date separator with [dateSeparatorBuilder] or the default one.
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
