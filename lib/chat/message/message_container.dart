import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'bubble_menu.dart';
import 'entity/message.dart';
import 'message_failed.dart';
import 'message_loading.dart';

/// Lays out a message bubble with its timestamp, read indicator, loading
/// state, failed-message actions and context menu.
class MessageContainer extends StatelessWidget {
  /// Creates a [MessageContainer].
  const MessageContainer({
    super.key,
    required this.message,
    required this.isBaseAxisStart,
    required this.bubbleBuilder,
    required this.timeBuilder,
    required this.isSender,
    required this.maxWidth,
    this.showTime = true,
    this.loadingWidget = const MessageLoading(),
    this.readIndicatorBuilder,
    this.onDelete,
    this.onRetry,
    this.menuConfiguration,
  });

  /// Maximum width of the bubble.
  final double maxWidth;

  /// The message to display.
  final Message message;

  /// Whether the bubble is aligned to the leading side.
  final bool isBaseAxisStart;

  /// Whether the message is a sender message.
  final bool isSender;

  /// Whether to show the timestamp.
  final bool showTime;

  /// Wraps the message content in a bubble.
  final Widget Function(BuildContext context, Widget child, bool isSender)
  bubbleBuilder;

  /// Builds the timestamp.
  final Widget Function(BuildContext context, String timestamp) timeBuilder;

  /// Builds the read indicator. `null` hides it.
  final Widget Function(BuildContext context, bool isRead)?
  readIndicatorBuilder;

  /// Called when the delete button of a failed message is tapped.
  final VoidCallback? onDelete;

  /// Called when the retry button of a failed message is tapped.
  final VoidCallback? onRetry;

  /// Shown inside the bubble while the message is loading.
  final Widget loadingWidget;

  /// Context-menu settings. `null` disables the menu.
  final BubbleMenuConfiguration? menuConfiguration;

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
            if (showTime) timeBuilder(context, message.timestamp),
          ],
        );
      } else {
        if (showTime) trailWidget = timeBuilder(context, message.timestamp);
      }
    }
    return Row(
      mainAxisAlignment: isBaseAxisStart
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isBaseAxisStart) ...[trailWidget, const Gap(12)],
        Flexible(
          fit: FlexFit.loose,
          child: BubbleMenuDetector(
            message: message,
            isSender: isSender,
            configuration: menuConfiguration,
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
        ),
        if (isBaseAxisStart) ...[const Gap(12), trailWidget],
      ],
    );
  }
}
