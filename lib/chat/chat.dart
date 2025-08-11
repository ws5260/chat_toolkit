import 'dart:async';
import 'dart:ui';

import 'package:chat_toolkit/chat/chat_configuration.dart';
import 'package:chat_toolkit/chat/chat_controller.dart';
import 'package:chat_toolkit/chat/message/entity/message.dart';
import 'package:chat_toolkit/chat/message/entity/message_group.dart';
import 'package:chat_toolkit/chat/message/message_bubble.dart';
import 'package:chat_toolkit/chat/size_detected_widget.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class Chat extends StatefulWidget {
  const Chat(
      {super.key,
      this.readOnly = false,
      this.chatController,
      this.configuration = const ChatConfiguration(),
      this.onScrollToTop});
  final bool readOnly;
  final ChatController? chatController;
  final ChatConfiguration configuration;
  final Future<void> Function()? onScrollToTop;
  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  late final ChatController chatController;
  bool _isOnScrollCallbackRunning = false;
  ValueNotifier<Message?> showNewReceiveMessageIndicator = ValueNotifier(null);
  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 300);
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
            threshold: widget.configuration.newMessageScrollThreshold)) {
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
          threshold: widget.configuration.newMessageScrollThreshold)) {
        chatController.scrollToBottom();
        showNewReceiveMessageIndicator.value = null;
        _isScrollable = false;
      }
    }

    if (_isOnScrollCallbackRunning) return;

    // 기존 타이머가 있다면 취소
    _debounceTimer?.cancel();

    // 새로운 디바운스 타이머 시작
    _debounceTimer = Timer(_debounceDuration, () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (chatController.position.pixels >=
            chatController.position.maxScrollExtent - 20) {
          _isOnScrollCallbackRunning = true;
          widget.onScrollToTop?.call().then((value) async {
            _isOnScrollCallbackRunning = false;
          });
        }
      });
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
                            context, value);
                  },
                ),
              ),
            ],
          ],
        )),
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
        scrollBehavior:
            const ScrollBehavior().copyWith(scrollbars: false, dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        }),
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
    final messageGroups = chatController.reverse
        ? chatController.messageGroups.reversed.toList()
        : chatController.messageGroups;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      sliver: SliverList.separated(
        itemCount: messageGroups.length,
        itemBuilder: (context, index) {
          final group = messageGroups[index];
          bool isPrevProfile = (group.isSender &&
                  widget.configuration.senderAlignment ==
                      ChatAlignment.start) ||
              (!group.isSender &&
                  widget.configuration.senderAlignment == ChatAlignment.end);

          return SelectionArea(
            selectionControls: MaterialTextSelectionControls(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPrevProfile) ...[
                  widget.configuration.bubbleConfiguration
                      .buildProfile(context, group.name),
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
                                group, group.messages[i]);
                          },
                          onRetry: () {
                            chatController.retryMessage(group.messages[i]);
                          },
                        ),
                        if (i < group.messages.length - 1) const Gap(8)
                      ]
                    ],
                  ),
                ),
                if (!isPrevProfile) ...[
                  const Gap(12),
                  widget.configuration.bubbleConfiguration
                      .buildProfile(context, group.name),
                ],
              ],
            ),
          );
        },
        separatorBuilder: (context, index) {
          return _buildDateOrGap(context, messageGroups, index);
        },
      ),
    );
  }

  Widget _buildDateOrGap(
      BuildContext context, List<MessageGroup> messageGroups, int index) {
    if (index + 1 < messageGroups.length &&
        chatController.isDateChangedComparedTo(
            messageGroups[index].messages.first,
            messageGroups[index + 1].messages.first)) {
      return widget.configuration.buildDateDivider(
          context, messageGroups[index].messages.first.timestamp);
    }

    return const Gap(24);
  }

  Widget _buildInputOrBanner() {
    if (widget.readOnly) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: const Color(0xFFF4F4F4)),
        child: const Text(
          "내 상담채팅이 아니여서 조회만 가능해요",
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF151515),
              letterSpacing: -0.02),
        ),
      );
    }
    return widget.configuration.buildInputField(context, chatController);
  }
}
