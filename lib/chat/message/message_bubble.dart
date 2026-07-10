import 'package:flutter/material.dart';

import '../chat_configuration.dart';
import 'entity/message.dart';
import 'message_container.dart';

class MessageBubble extends StatefulWidget {
  const MessageBubble(
    this.message, {
    super.key,
    this.customProfile,
    required this.configuration,
    required this.onDelete,
    required this.onRetry,
  });
  final Message message;
  final Widget? customProfile;
  final ChatConfiguration configuration;
  final VoidCallback onDelete;
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
          readIndicatorBuilder: bubbleConfiguration.readIndicatorBuilder,
        ),
      ],
    );
  }
}
