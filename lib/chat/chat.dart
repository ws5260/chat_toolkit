import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'chat_configuration.dart';
import 'chat_controller.dart';
import 'message/entity/message.dart';
import 'message/entity/message_group.dart';
import 'message/message_bubble.dart';
import 'size_detected_widget.dart';

class Chat extends StatefulWidget {
  const Chat({
    super.key,
    this.readOnly = false,
    this.chatController,
    this.configuration = const ChatConfiguration(),
    this.onScrollToTop,
    this.customInputField,
  });
  final bool readOnly;
  final ChatController? chatController;
  final ChatConfiguration configuration;
  final Widget Function(BuildContext, ChatController)? customInputField;
  final Future<void> Function()? onScrollToTop;
  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  late final ChatController chatController;
  ValueNotifier<Message?> showNewReceiveMessageIndicator = ValueNotifier(null);
  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 100);
  bool _isScrollable = false;
  @override
  void initState() {
    super.initState();
    chatController = widget.chatController ?? ChatController();
    chatController.addListener(_onScroll);

    if (widget.configuration.newReceiveMessageNotificationBuilder != null) {
      chatController.newReceiveMessageStream.listen((message) {
        _isScrollable = true;
        if (chatController.isAtBottom(
          threshold: widget.configuration.newMessageScrollThreshold,
        )) {
          showNewReceiveMessageIndicator.value = null;
          chatController.scrollToBottom();
        } else {
          showNewReceiveMessageIndicator.value = message;
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.chatController == null) {
      chatController.dispose();
    }
    showNewReceiveMessageIndicator.dispose();
    super.dispose();
  }

  void _onScroll() async {
    if (widget.configuration.newReceiveMessageNotificationBuilder != null &&
        _isScrollable) {
      if (chatController.isAtBottom(
        threshold: widget.configuration.newMessageScrollThreshold,
      )) {
        chatController.scrollToBottom();
        showNewReceiveMessageIndicator.value = null;
        _isScrollable = false;
      }
    }
    if (_debounceTimer?.isActive ?? false) return;

    // 새로운 디바운스 타이머 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatController.position.pixels >=
          chatController.position.maxScrollExtent - 20) {
        widget.onScrollToTop?.call().then((value) async {
          _debounceTimer?.cancel();
        });
        _debounceTimer = Timer(_debounceDuration, () {});
      }
    });
  }

  void _onSizeChanged(Size? oldSize, Size? newSize) {
    if (newSize != null) {
      if (newSize.height < oldSize!.height) {
        chatController.scrollToTopByValue(oldSize.height - newSize.height);
      } else if (newSize.height > oldSize.height) {
        chatController.scrollToBottomByValue(newSize.height - oldSize.height);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              _buildMessageList(),
              if (widget.configuration.newReceiveMessageNotificationBuilder !=
                  null) ...[
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ValueListenableBuilder(
                    valueListenable: showNewReceiveMessageIndicator,
                    builder: (context, value, child) {
                      return value == null
                          ? const SizedBox.shrink()
                          : widget.configuration
                              .newReceiveMessageNotificationBuilder!(
                              context,
                              value,
                              chatController,
                            );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildInputOrBanner(),
      ],
    );
  }

  Widget _buildMessageList() {
    return SizeDetectedWidget(
      type: SizeDetectedWidgetType.height,
      onChange: _onSizeChanged,
      child: CustomScrollView(
        reverse: chatController.reverse,
        scrollBehavior: const ScrollBehavior().copyWith(
          scrollbars: false,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
          },
        ),
        controller: chatController,
        slivers: [
          const SliverGap(30),
          ListenableBuilder(
            listenable: chatController,
            builder: _buildMessageSliverList,
          ),
          const SliverGap(30),
        ],
      ),
    );
  }

  Widget _buildMessageSliverList(BuildContext context, Widget? child) {
    final messageGroups = chatController.messageGroups;

    List<Widget> widgets = _buildMessageWidgetList(context, messageGroups);

    if (chatController.reverse) {
      widgets = widgets.reversed.toList();
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => widgets[index],
          childCount: widgets.length,
        ),
      ),
    );
  }

  List<Widget> _buildMessageWidgetList(
    BuildContext context,
    List<MessageGroup> messageGroups,
  ) {
    if (messageGroups.isEmpty) return [];

    final List<Widget> widgets = [];

    for (int index = 0; index < messageGroups.length; index++) {
      final group = messageGroups[index];

      // 첫 번째 그룹이거나 날짜가 변경된 경우 날짜 구분선 추가
      if (index == 0 ||
          (index > 0 &&
              chatController.isDateChangedComparedTo(
                messageGroups[index - 1].messages.first,
                messageGroups[index].messages.first,
              ))) {
        widgets.add(
          widget.configuration.buildDateDivider(
            context,
            group.messages.first.timestamp,
          ),
        );
      } else {
        // 날짜 구분선이 없는 경우 일반 간격 추가
        widgets.add(const Gap(24));
      }

      // 메시지 그룹 위젯 생성
      bool isPrevProfile = (group.isSender &&
              widget.configuration.senderAlignment == ChatAlignment.start) ||
          (!group.isSender &&
              widget.configuration.senderAlignment == ChatAlignment.end);

      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPrevProfile) ...[
              widget.configuration.bubbleConfiguration.buildProfile(
                context,
                group.name,
                group.isSender,
              ),
              const Gap(12),
            ],
            Expanded(
              child: Column(
                children: [
                  for (int i = 0; i < group.messages.length; i++) ...[
                    MessageBubble(
                      group.messages[i],
                      configuration: widget.configuration,
                      onDelete: () {
                        chatController.removeMessageFromGroup(
                          group,
                          group.messages[i],
                        );
                      },
                      onRetry: () {
                        chatController.retryMessage(group.messages[i]);
                      },
                    ),
                    if (i < group.messages.length - 1) const Gap(8),
                  ],
                ],
              ),
            ),
            if (!isPrevProfile) ...[
              const Gap(12),
              widget.configuration.bubbleConfiguration.buildProfile(
                context,
                group.name,
                group.isSender,
              ),
            ],
          ],
        ),
      );
    }

    return widgets;
  }

  Widget _buildInputOrBanner() {
    if (widget.readOnly) {
      return widget.configuration.readOnlyWidget ??
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: const Color(0xFFF4F4F4),
            ),
            child: const Text(
              "current chat is not mine",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF151515),
                letterSpacing: -0.02,
              ),
            ),
          );
    }
    return widget.customInputField?.call(context, chatController) ??
        const SizedBox.shrink();
  }
}
