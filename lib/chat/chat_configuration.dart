import 'package:chat_toolkit/chat/chat_controller.dart';
import 'package:chat_toolkit/chat/chat_input_field.dart';
import 'package:chat_toolkit/chat/message/entity/message.dart';
import 'package:chat_toolkit/chat/message/message_loading.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class BubbleConfiguration {
  final Widget Function(BuildContext context, String name)? profileBuilder;
  final Widget Function(BuildContext context, Widget child)?
      senderBubbleBuilder;
  final Widget Function(BuildContext context, Widget child)?
      receiverBubbleBuilder;
  final Widget Function(BuildContext context, String timestamp)? timeBuilder;

  final Widget loadingWidget;

  final double maxWidth;

  const BubbleConfiguration({
    this.profileBuilder,
    this.senderBubbleBuilder,
    this.receiverBubbleBuilder,
    this.timeBuilder,
    this.loadingWidget = const MessageLoading(),
    this.maxWidth = double.infinity,
  });

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

  Widget buildTime(BuildContext context, String timestamp) {
    return timeBuilder?.call(context, timestamp) ?? Text(timestamp);
  }
}

enum ChatAlignment {
  start,
  end,
}


/*
  채팅
*/
class ChatConfiguration {
  final ChatAlignment senderAlignment;
 
  final Widget Function(BuildContext, ChatController)? customInputField;
  final Widget Function(BuildContext, Message)?
      newReceiveMessageNotificationBuilder;
  final BubbleConfiguration bubbleConfiguration;
  final double newMessageScrollThreshold;

  const ChatConfiguration({
    this.senderAlignment = ChatAlignment.end,
    this.customInputField,
    this.newReceiveMessageNotificationBuilder,
    this.bubbleConfiguration = const BubbleConfiguration(),
    this.newMessageScrollThreshold = 300,
  });

  bool get isPrevProfile => senderAlignment == ChatAlignment.start;

  Widget buildInputField(BuildContext context, ChatController controller) {
    return customInputField?.call(context, controller) ??
        const ChatInputField();
  }
}
