import 'package:chat_toolkit/chat/chat_configuration.dart';
import 'package:chat_toolkit/chat/message/entity/message.dart';
import 'package:chat_toolkit/chat/message/message_container.dart';
import 'package:flutter/material.dart';

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
