import 'dart:async';
import 'dart:ui';

import 'chat_configuration.dart';
import 'chat_controller.dart';
import 'message/entity/message.dart';
import 'message/entity/message_group.dart';
import 'message/message_bubble.dart';
import 'size_detected_widget.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class Chat extends StatefulWidget {
  const Chat({
    super.key,
    this.readOnly = false,
    this.chatController,
    this.configuration = const ChatConfiguration(),
    this.onScrollToTop,
    this.customInputField,
    this.onDeleteFailedMessage,
  });
  final bool readOnly;
  final ChatController? chatController;
  final ChatConfiguration configuration;
  final Widget Function(BuildContext, ChatController)? customInputField;
  final Future<void> Function()? onScrollToTop;

  // Called when the X on a failed bubble is tapped. This widget knows neither the room id
  // nor the API, so the host screen is responsible for the actual deletion.
  final Future<bool> Function(Message)? onDeleteFailedMessage;
  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  late final ChatController chatController;
  ValueNotifier<Message?> showNewReceiveMessageIndicator = ValueNotifier(null);
  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 100);
  bool _isScrollable = false;
  bool _olderEndCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    chatController = widget.chatController ?? ChatController();
    chatController.addListener(_onScroll);

    if (widget.configuration.newReceiveMessageNotificationBuilder != null) {
      chatController.newReceiveMessageStream.listen((message) {
        _isScrollable = true;
        if (chatController.isAtBottom(threshold: widget.configuration.newMessageScrollThreshold)) {
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
    if (widget.configuration.newReceiveMessageNotificationBuilder != null && _isScrollable) {
      if (chatController.isAtBottom(threshold: widget.configuration.newMessageScrollThreshold)) {
        chatController.scrollToBottom();
        showNewReceiveMessageIndicator.value = null;
        _isScrollable = false;
      }
    }
    if (_debounceTimer?.isActive ?? false) return;
    // setMessages notifies once per message, so schedule the oldest-end check only once per frame.
    // Otherwise, in a room that doesn't fill the screen, onScrollToTop fires once per message.
    if (_olderEndCheckScheduled) return;
    _olderEndCheckScheduled = true;

    // Restart the debounce timer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _olderEndCheckScheduled = false;
      if (!mounted || !chatController.hasClients) return;
      final position = chatController.position;
      // If messages don't fill the screen, maxScrollExtent is 0 and the list can't scroll,
      // so scrolling can never trigger loading older messages.
      // In that case treat the list as being at the oldest end and call onScrollToTop. Once the loaded
      // messages are added this runs again, repeating until the screen is filled.
      // The oldest end differs by mode: maxScrollExtent for a reversed list, 0 for a normal one.
      final atOlderEnd =
          position.maxScrollExtent <= 0 ||
          (chatController.reverse
              ? position.pixels >= position.maxScrollExtent - 20
              : position.pixels <= 20);
      if (atOlderEnd) {
        widget.onScrollToTop?.call().then((value) async {
          _debounceTimer?.cancel();
        });
        _debounceTimer = Timer(_debounceDuration, () {});
      }
    });
  }

  void _onSizeChanged(Size? oldSize, Size? newSize) {
    if (newSize != null && oldSize != null) {
      if (newSize.height < oldSize.height) {
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
              if (widget.configuration.newReceiveMessageNotificationBuilder != null) ...[
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ValueListenableBuilder(
                    valueListenable: showNewReceiveMessageIndicator,
                    builder: (context, value, child) {
                      return value == null
                          ? const SizedBox.shrink()
                          : widget.configuration.newReceiveMessageNotificationBuilder!(
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
            listenable: chatController.messagesRevision,
            builder: _buildMessageSliverList,
          ),
          const SliverGap(30),
        ],
      ),
    );
  }

  // Called only when the message list changes. This only computes the group list and whether
  // each needs a date separator; widgets are built lazily by SliverChildBuilderDelegate,
  // which calls _buildGroupItem only for the indices that enter the viewport.
  Widget _buildMessageSliverList(BuildContext context, Widget? child) {
    final groups = List<MessageGroup>.of(chatController.messageGroups);
    final showDateDivider = List<bool>.generate(
      groups.length,
      (i) =>
          i == 0 ||
          chatController.isDateChangedComparedTo(
            groups[i - 1].messages.first,
            groups[i].messages.first,
          ),
    );
    final reverse = chatController.reverse;
    int groupIndexAt(int index) => reverse ? groups.length - 1 - index : index;

    // In a reversed list, adding a new message shifts every group's index by one.
    // If findChildIndexCallback finds the new index via ObjectKey(group), the existing Element
    // is moved to that slot; otherwise every visible group is rebuilt from scratch.
    final indexOfGroup = Map<MessageGroup, int>.identity();
    for (int i = 0; i < groups.length; i++) {
      indexOfGroup[groups[i]] = reverse ? groups.length - 1 - i : i;
    }

    return SliverPadding(
      padding: widget.configuration.padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final groupIndex = groupIndexAt(index);
            return _buildGroupItem(
              context,
              groups[groupIndex],
              showDateDivider: showDateDivider[groupIndex],
            );
          },
          childCount: groups.length,
          findChildIndexCallback: (key) =>
              key is ObjectKey && key.value is MessageGroup ? indexOfGroup[key.value] : null,
        ),
      ),
    );
  }

  Widget _buildGroupItem(
    BuildContext context,
    MessageGroup group, {
    required bool showDateDivider,
  }) {
    final bool isPrevProfile =
        (group.isSender && widget.configuration.senderAlignment == ChatAlignment.start) ||
        (!group.isSender && widget.configuration.senderAlignment == ChatAlignment.end);

    return Column(
      key: ObjectKey(group),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDateDivider)
          widget.configuration.buildDateDivider(context, group.messages.first.timestamp)
        else
          const Gap(24),
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
                      showTime: i == group.messages.length - 1,
                      onDelete: () async {
                        final message = group.messages[i];
                        final onDelete = widget.onDeleteFailedMessage;
                        if (onDelete != null && !await onDelete(message)) return;
                        chatController.removeMessageFromGroup(group, message);
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
      ],
    );
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
    return widget.customInputField?.call(context, chatController) ?? const SizedBox.shrink();
  }
}
