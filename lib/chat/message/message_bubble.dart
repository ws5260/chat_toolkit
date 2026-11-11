import 'package:flutter/material.dart';

import '../chat_configuration.dart';
import 'entity/message.dart';
import 'message_container.dart';

/// Renders a single [Message] as a bubble, with its timestamp, read
/// indicator, loading state and retry/delete actions.
///
/// [Chat] creates these for you; use it directly only when building a custom
/// message list.
class MessageBubble extends StatefulWidget {
  /// Creates a bubble for [message].
  const MessageBubble(
    this.message, {
    super.key,
    this.customProfile,
    this.showTime = true,
    required this.configuration,
    required this.onDelete,
    required this.onRetry,
  });

  /// The message to display.
  final Message message;

  /// Custom profile widget. Currently unused.
  final Widget? customProfile;

  /// Whether to show the timestamp beside the bubble.
  ///
  /// [Chat] shows it only for the last message of each group.
  final bool showTime;

  /// Chat configuration supplying the bubble appearance.
  final ChatConfiguration configuration;

  /// Called when the delete button of a failed message is tapped.
  final VoidCallback onDelete;

  /// Called when the retry button of a failed message is tapped.
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
          showTime: widget.showTime,
          loadingWidget: bubbleConfiguration.loadingWidget,
          onDelete: widget.onDelete,
          onRetry: widget.onRetry,
          maxWidth: widget.message.width ?? bubbleConfiguration.maxWidth,
          readIndicatorBuilder: bubbleConfiguration.readIndicatorBuilder,
          menuConfiguration: bubbleConfiguration.menuConfiguration,
        ),
      ],
    );
  }
}
