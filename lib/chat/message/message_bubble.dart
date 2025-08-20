import 'package:chat_toolkit/chat/chat_configuration.dart';
import 'package:chat_toolkit/chat/message/entity/message.dart';
import 'package:chat_toolkit/chat/message/message_container.dart';
import 'package:flutter/material.dart';

/// Widget that displays a message bubble with appropriate styling.
///
/// This widget is responsible for rendering individual messages within
/// the chat interface. It handles:
/// - Message alignment based on sender/receiver status
/// - Custom profile display integration
/// - Bubble styling through configuration
/// - Delete and retry action callbacks
///
/// The widget follows the Presentation Layer pattern by focusing purely
/// on UI concerns while delegating business logic to the controller layer.
///
/// Example usage:
/// ```dart
/// MessageBubble(
///   message,
///   configuration: chatConfiguration,
///   onDelete: () => controller.removeMessage(message),
///   onRetry: () => controller.retryMessage(message),
/// )
/// ```
class MessageBubble extends StatefulWidget {
  /// Creates a message bubble widget.
  ///
  /// All parameters are required to ensure proper message display
  /// and interaction handling.
  const MessageBubble(
    this.message, {
    super.key,
    this.customProfile,
    required this.configuration,
    required this.onDelete,
    required this.onRetry,
  });

  /// The message to display in this bubble.
  final Message message;

  /// Optional custom profile widget to display.
  ///
  /// If not provided, uses the profile from bubble configuration.
  final Widget? customProfile;

  /// Configuration defining the bubble's appearance and behavior.
  final ChatConfiguration configuration;

  /// Callback invoked when the user requests to delete this message.
  final VoidCallback onDelete;

  /// Callback invoked when the user requests to retry this message.
  ///
  /// Only relevant for failed sender messages.
  final VoidCallback onRetry;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  @override
  Widget build(BuildContext context) {
    final bubbleConfiguration = widget.configuration.bubbleConfiguration;

    late final bool isAxisStart;
    if (widget.configuration.isPrevProfile) {
      isAxisStart = widget.message.isSender;
    } else {
      isAxisStart = !widget.message.isSender;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MessageContainer(
          bubbleBuilder: bubbleConfiguration.buildBubble,
          timeBuilder: bubbleConfiguration.buildTime,
          message: widget.message,
          isBaseAxisStart: isAxisStart,
          isSender: widget.message.isSender,
          loadingWidget: bubbleConfiguration.loadingWidget,
          onDelete: widget.onDelete,
          onRetry: widget.onRetry,
          maxWidth: widget.message.width ?? bubbleConfiguration.maxWidth,
        ),
      ],
    );
  }
}
