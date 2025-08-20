import 'package:chat_toolkit/chat/chat_controller.dart';
import 'package:chat_toolkit/chat/chat_input_field.dart';
import 'package:chat_toolkit/chat/message/entity/message.dart';
import 'package:chat_toolkit/chat/message/message_loading.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// Configuration class for message bubble appearance and behavior.
///
/// This class follows the Strategy Pattern by allowing customization
/// of bubble rendering without modifying the core chat logic.
/// It provides builder functions for different UI elements while
/// maintaining sensible defaults.
///
/// Example usage:
/// ```dart
/// BubbleConfiguration(
///   profileBuilder: (context, name) => CustomProfile(name),
///   senderBubbleBuilder: (context, child) => Container(
///     decoration: BoxDecoration(color: Colors.blue),
///     child: child,
///   ),
/// )
/// ```
class BubbleConfiguration {
  /// Builder function for user profile widgets.
  ///
  /// If not provided, a default profile widget with an icon will be used.
  final Widget Function(BuildContext context, String name)? profileBuilder;

  /// Builder function for sender message bubbles.
  ///
  /// Receives the message content as a child widget and should return
  /// a styled container. If not provided, uses default styling.
  final Widget Function(BuildContext context, Widget child)?
      senderBubbleBuilder;

  /// Builder function for receiver message bubbles.
  ///
  /// Similar to senderBubbleBuilder but for incoming messages.
  final Widget Function(BuildContext context, Widget child)?
      receiverBubbleBuilder;

  /// Builder function for timestamp display widgets.
  ///
  /// If not provided, uses default date formatting.
  final Widget Function(BuildContext context, String timestamp)? timeBuilder;

  /// Widget displayed while messages are loading.
  final Widget loadingWidget;

  /// Maximum width for message bubbles.
  ///
  /// Use this to control message bubble width on larger screens.
  final double maxWidth;

  const BubbleConfiguration({
    this.profileBuilder,
    this.senderBubbleBuilder,
    this.receiverBubbleBuilder,
    this.timeBuilder,
    this.loadingWidget = const MessageLoading(),
    this.maxWidth = double.infinity,
  });

  /// Builds a profile widget for the given user name.
  ///
  /// Uses the custom profileBuilder if provided, otherwise returns
  /// a default profile widget with an icon and name.
  Widget buildProfile(BuildContext context, String name) {
    return profileBuilder?.call(context, name) ??
        Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                  color: const Color(0xFFE9E9E9),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.person)),
            ),
            const Gap(4),
            Text(
              name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.02),
            ),
          ],
        );
  }

  /// Builds a message bubble with appropriate styling.
  ///
  /// Uses custom bubble builders if provided, otherwise applies
  /// default styling based on whether the message is from sender or receiver.
  ///
  /// The [isSender] parameter determines which styling to apply.
  Widget buildBubble(BuildContext context, Widget child, bool isSender) {
    if (isSender) {
      return senderBubbleBuilder?.call(context, child) ??
          Container(
            padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(16),
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

  /// Builds a timestamp widget for the given timestamp string.
  ///
  /// Uses the custom timeBuilder if provided, otherwise returns
  /// a default formatted date display.
  Widget buildTime(BuildContext context, String timestamp) {
    return timeBuilder?.call(context, timestamp) ??
        Text(
          DateFormat("yyyy.MM.dd").format(DateTime.parse(timestamp)),
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF0D082C).withOpacity(0.4)),
        );
  }
}

/// Alignment options for chat elements.
///
/// Used to control the positioning of sender profiles and message bubbles.
enum ChatAlignment {
  /// Align to the start (left in LTR, right in RTL)
  start,

  /// Align to the end (right in LTR, left in RTL)
  end,
}

/// Main configuration class for chat appearance and behavior.
///
/// This class implements the Strategy Pattern and Dependency Injection
/// by providing customizable behaviors through builder functions and
/// configuration objects. It centralizes all chat-related configuration
/// to maintain the Single Responsibility Principle.
///
/// Example usage:
/// ```dart
/// ChatConfiguration(
///   senderAlignment: ChatAlignment.start,
///   customInputField: (context, controller) => MyCustomInput(),
///   bubbleConfiguration: BubbleConfiguration(
///     maxWidth: 200,
///   ),
/// )
/// ```
class ChatConfiguration {
  /// Alignment for sender profiles and messages.
  ///
  /// Controls whether sender elements appear on the start or end of the chat.
  final ChatAlignment senderAlignment;

  /// Builder for custom input field widget.
  ///
  /// If provided, replaces the default input field. Receives the chat
  /// controller to handle message sending.
  final Widget Function(BuildContext, ChatController)? customInputField;

  /// Builder for new message notification widget.
  ///
  /// Called when a new message is received while the user is not at the bottom.
  /// Typically shows a "new message" indicator.
  final Widget Function(BuildContext, Message)?
      newReceiveMessageNotificationBuilder;

  /// Builder for date separator widgets.
  ///
  /// Used to create custom date dividers between messages from different days.
  final Widget Function(BuildContext, String)? dateSeparatorBuilder;

  /// Widget to display when chat is in read-only mode.
  ///
  /// If not provided, shows a default "Read Only" banner.
  final Widget? readOnlyWidget;

  /// Configuration for message bubble appearance.
  final BubbleConfiguration bubbleConfiguration;

  /// Distance threshold for triggering new message scroll behavior.
  ///
  /// When a new message arrives and the user is within this distance
  /// from the bottom, the chat will auto-scroll.
  final double newMessageScrollThreshold;

  const ChatConfiguration({
    this.senderAlignment = ChatAlignment.end,
    this.customInputField,
    this.newReceiveMessageNotificationBuilder,
    this.bubbleConfiguration = const BubbleConfiguration(),
    this.newMessageScrollThreshold = 300,
    this.dateSeparatorBuilder,
    this.readOnlyWidget,
  });

  /// Whether profile should be displayed before the message bubble.
  ///
  /// Returns true if sender alignment is set to start.
  bool get isPrevProfile => senderAlignment == ChatAlignment.start;

  /// Builds the input field widget for the chat.
  ///
  /// Uses the custom input field if provided, otherwise returns
  /// the default ChatInputField.
  Widget buildInputField(BuildContext context, ChatController controller) {
    return customInputField?.call(context, controller) ??
        const ChatInputField();
  }

  /// Builds a date divider widget for the given timestamp.
  ///
  /// Uses the custom date separator builder if provided, otherwise
  /// returns a default styled divider with formatted date.
  Widget buildDateDivider(BuildContext context, String timestamp) {
    return dateSeparatorBuilder?.call(context, timestamp) ??
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            children: [
              const Expanded(child: Divider()),
              const Gap(20),
              Text(
                DateFormat("yyyy.MM.dd").format(DateTime.parse(timestamp)),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF565656)),
              ),
              const Gap(20),
              const Expanded(child: Divider()),
            ],
          ),
        );
  }
}
