import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'entity/message.dart';
import 'message_failed.dart';
import 'message_loading.dart';

class MessageContainer extends StatelessWidget {
  const MessageContainer({
    super.key,
    required this.message,
    required this.isBaseAxisStart,
    required this.bubbleBuilder,
    required this.timeBuilder,
    required this.isSender,
    required this.maxWidth,
    this.loadingWidget = const MessageLoading(),
    this.readIndicatorBuilder,
    this.onDelete,
    this.onRetry,
  });
  final double maxWidth;
  final Message message;
  final bool isBaseAxisStart;
  final bool isSender;
  final Widget Function(BuildContext context, Widget child, bool isSender)
      bubbleBuilder;
  final Widget Function(BuildContext context, String timestamp) timeBuilder;
  final Widget Function(BuildContext context, bool isRead)?
      readIndicatorBuilder;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;
  final Widget loadingWidget;

  @override
  Widget build(BuildContext context) {
    Widget trailWidget = const SizedBox.shrink();
    if (message is SenderMessage && (message as SenderMessage).isFailed) {
      trailWidget = MessageFailed(onDelete: onDelete, onRetry: onRetry);
    } else if (!message.isLoading) {
      if (message.isRead != null && readIndicatorBuilder != null) {
        trailWidget = Column(
          crossAxisAlignment: isBaseAxisStart
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            readIndicatorBuilder!(context, message.isRead!),
            timeBuilder(context, message.timestamp),
          ],
        );
      } else {
        trailWidget = timeBuilder(context, message.timestamp);
      }
    }
    return Row(
      mainAxisAlignment:
          isBaseAxisStart ? MainAxisAlignment.start : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isBaseAxisStart) ...[trailWidget, const Gap(12)],
        Flexible(
          fit: FlexFit.loose,
          child: bubbleBuilder(
            context,
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isLoading) ...[
                    loadingWidget,
                  ] else ...[
                    for (int i = 0; i < message.elements.length; i++) ...[
                      message.elements[i].toWidget(context),
                      if (i != message.elements.length - 1) const Gap(10),
                    ],
                  ],
                ],
              ),
            ),
            isSender,
          ),
        ),
        if (isBaseAxisStart) ...[const Gap(12), trailWidget],
      ],
    );
  }
}
