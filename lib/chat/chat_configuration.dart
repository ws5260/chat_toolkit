import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'chat_controller.dart';
import 'message/entity/message.dart';
import 'message/message_loading.dart';

class BubbleConfiguration {
  final Widget Function(BuildContext context, String name)?
      senderProfileBuilder;
  final Widget Function(BuildContext context, String name)?
      receiverProfileBuilder;
  final Widget Function(BuildContext context, Widget child)?
      senderBubbleBuilder;
  final Widget Function(BuildContext context, Widget child)?
      receiverBubbleBuilder;
  final Widget Function(BuildContext context, String timestamp)? timeBuilder;

  final Widget Function(BuildContext context, bool isRead)?
      readIndicatorBuilder;
  final Widget loadingWidget;

  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  final TextStyle? profileNameStyle;

  final TextStyle? timeStyle;

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
    this.readIndicatorBuilder,
  });

  Widget buildProfile(BuildContext context, String name, bool isSender) {
    final profileBuilder =
        isSender ? senderProfileBuilder : receiverProfileBuilder;

    if (profileBuilder != null) {
      if (profileNameStyle == null) return profileBuilder.call(context, name);
      return DefaultTextStyle(
        style: profileNameStyle!,
        child: profileBuilder.call(context, name),
      );
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

  Widget buildTime(BuildContext context, String timestamp) {
    if (timeBuilder != null) {
      if (timeStyle == null) {
        return timeBuilder!.call(context, timestamp);
      }
      return DefaultTextStyle(
        style: timeStyle!,
        child: timeBuilder!.call(context, timestamp),
      );
    }
    return Text(
      DateFormat("yyyy.MM.dd").format(DateTime.parse(timestamp)),
      style: timeStyle,
    );
  }
}

enum ChatAlignment { start, end }

/*
  채팅
*/
class ChatConfiguration {
  final ChatAlignment senderAlignment;
  final Widget Function(BuildContext, Message, ChatController)?
      newReceiveMessageNotificationBuilder;
  final Widget Function(BuildContext, String)? dateSeparatorBuilder;
  final Widget? readOnlyWidget;

  final BubbleConfiguration bubbleConfiguration;
  final double newMessageScrollThreshold;

  final TextStyle? dateSeparatorStyle;

  const ChatConfiguration({
    this.senderAlignment = ChatAlignment.end,
    this.newReceiveMessageNotificationBuilder,
    this.bubbleConfiguration = const BubbleConfiguration(),
    this.readOnlyWidget,
    this.newMessageScrollThreshold = 300,
    this.dateSeparatorBuilder,
    this.dateSeparatorStyle,
  });

  bool get isPrevProfile => senderAlignment == ChatAlignment.start;

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
