import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter/material.dart';

import '../site/site_theme.dart';
import 'fake_chat_server.dart';

/// A chat room that loads its messages from [FakeChatServer], the same way the apps using this
/// toolkit do: setMessages when the first page arrives, scrollToBottom on the next frame, and
/// appendMessages for older pages when the list reaches its oldest end.
class RoomChatScreen extends StatefulWidget {
  const RoomChatScreen({super.key, required this.room, required this.reverse});

  final RoomInfo room;
  final bool reverse;

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final _server = FakeChatServer.instance;
  final _textController = TextEditingController();
  // Kept on the input after sending (see _sendMessage and _buildInputField).
  final _inputFocusNode = FocusNode();
  late final ChatController _chatController = ChatController(
    reverse: widget.reverse,
    customSortCallback: (a, b) => a.id.compareTo(b.id),
  );

  // Bumped when the scroll extent changes without scrolling (messages added, images loaded),
  // so the debug bar shows current values.
  final _metricsTick = ValueNotifier(0);

  bool _loadingInitial = true;
  bool _loadingOlder = false;
  bool _hasNoMoreMessage = false;
  int _onScrollToTopCalls = 0;
  int _incomingCount = 0;

  int get _loadedCount => _chatController.messageGroups.fold(
    0,
    (sum, g) => sum + g.messages.length,
  );

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _inputFocusNode.dispose();
    _metricsTick.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    final messages = await _server.fetchMessages(widget.room);
    if (!mounted) return;
    _chatController.setMessages(messages);
    _hasNoMoreMessage = messages.length < FakeChatServer.pageSize;
    setState(() => _loadingInitial = false);
    debugPrint('[ROOM ${widget.room.id}] setMessages ${messages.length}');

    // Scrolling before the list is laid out does not reach the bottom, so do it next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_chatController.isDisposed) {
        _chatController.scrollToBottom();
      }
    });
  }

  Future<void> _onScrollToTop() async {
    _onScrollToTopCalls++;
    debugPrint(
      '[ROOM ${widget.room.id}] onScrollToTop #$_onScrollToTopCalls '
      '(loading initial: $_loadingInitial)',
    );
    setState(() {});
    if (_hasNoMoreMessage || _loadingOlder) return;
    // Nothing loaded yet: there is no oldest message to page from.
    final oldest = _oldestIndex();
    if (oldest == null) return;

    _loadingOlder = true;
    try {
      final messages = await _server.fetchMessages(
        widget.room,
        beforeIndex: oldest,
      );
      if (!mounted) return;
      _hasNoMoreMessage = messages.length < FakeChatServer.pageSize;
      if (messages.isNotEmpty) _chatController.appendMessages(messages);
      debugPrint('[ROOM ${widget.room.id}] appendMessages ${messages.length}');
    } finally {
      _loadingOlder = false;
      if (mounted) setState(() {});
    }
  }

  int? _oldestIndex() {
    final groups = _chatController.messageGroups;
    if (groups.isEmpty) return null;
    return FakeChatServer.indexOf(groups.first.messages.first);
  }

  // Received messages go through dispatchMessage so Chat auto-scrolls near the bottom or shows
  // the "new message" notification (same as the apps using this toolkit).
  void _receiveMessage() {
    _incomingCount++;
    final message = _server.incomingMessage(widget.room, _incomingCount);
    _chatController.dispatchMessage(message, onDispatch: (m) async => m);
  }

  void _sendMessage() {
    // Clicking the send button moves focus to it on web/desktop; give it back to the input.
    _inputFocusNode.requestFocus();
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _chatController.dispatchMessage(
      SenderMessage(
        name: '나',
        timestamp: DateTime.now().toIso8601String(),
        elements: [DemoTextElement(text)],
      ),
      onDispatch: (message) async {
        await Future<void>.delayed(widget.room.latency);
        return message.copyWith(isLoading: false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.room.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        shape: const Border(bottom: BorderSide(color: SiteColors.grey100)),
        actions: [
          IconButton(
            tooltip: '메시지 수신 테스트',
            icon: const Icon(Icons.mark_chat_unread_outlined),
            onPressed: _loadingInitial ? null : _receiveMessage,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDebugBar(),
          Expanded(
            child: Stack(
              children: [
                NotificationListener<ScrollMetricsNotification>(
                  onNotification: (_) {
                    _metricsTick.value++;
                    return false;
                  },
                  child: Chat(
                    chatController: _chatController,
                    onScrollToTop: _onScrollToTop,
                    configuration: ChatConfiguration(
                      // In the reversed layout, a few messages start at the top instead of
                      // the bottom.
                      messagesStartAtTop: true,
                      messageAppearAnimationDuration: const Duration(
                        milliseconds: 250,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      newReceiveMessageNotificationBuilder:
                          (context, message, controller) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ActionChip(
                                avatar: const Icon(
                                  Icons.arrow_downward,
                                  size: 16,
                                ),
                                label: Text('새 메시지: ${message.name}'),
                                onPressed: controller.scrollToBottom,
                              ),
                            );
                          },
                      bubbleConfiguration: BubbleConfiguration(
                        maxWidth: 260,
                        senderProfileBuilder: (context, name) =>
                            const SizedBox.shrink(),
                        senderBubbleBuilder: (context, child) =>
                            _bubble(child, SiteColors.blue, Colors.white),
                        receiverBubbleBuilder: (context, child) =>
                            _bubble(child, SiteColors.grey100, SiteColors.grey900),
                        timeBuilder: (context, timestamp) {
                          final t = DateTime.parse(timestamp);
                          return Text(
                            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 11, color: SiteColors.grey500),
                          );
                        },
                      ),
                    ),
                    customInputField: (context, controller) =>
                        _buildInputField(),
                  ),
                ),
                if (_loadingInitial)
                  const Center(child: CircularProgressIndicator()),
                if (_loadingOlder)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Chip(
                        avatar: SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        label: Text('이전 메시지 불러오는 중'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(Widget child, Color color, Color textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: textColor, fontSize: 15, height: 1.45),
          child: child,
        ),
      );

  // Live scroll state, to spot unexpected jumps while the room opens.
  Widget _buildDebugBar() {
    return ListenableBuilder(
      listenable: Listenable.merge([_chatController, _metricsTick]),
      builder: (context, _) {
        final hasPosition = _chatController.hasClients;
        final pixels = hasPosition ? _chatController.position.pixels : 0.0;
        final max = hasPosition
            ? _chatController.position.maxScrollExtent
            : 0.0;
        final fromBottom = widget.reverse ? pixels : max - pixels;
        return Container(
          width: double.infinity,
          color: SiteColors.grey50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'reverse: ${widget.reverse}  ·  바닥까지 ${fromBottom.toStringAsFixed(0)}px  '
            '(pixels ${pixels.toStringAsFixed(0)} / max ${max.toStringAsFixed(0)})\n'
            '로드 $_loadedCount/${widget.room.totalMessages}건  ·  '
            'onScrollToTop $_onScrollToTopCalls회'
            '${_hasNoMoreMessage ? '  ·  끝까지 불러옴' : ''}',
            style: const TextStyle(
                fontSize: 11, fontFamily: 'monospace', color: SiteColors.grey600),
          ),
        );
      },
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _inputFocusNode,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: '메시지를 입력해 주세요',
                hintStyle: const TextStyle(color: SiteColors.grey400),
                isDense: true,
                filled: true,
                fillColor: SiteColors.grey100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
              // With onEditingComplete set, pressing Enter no longer unfocuses the field
              // (TextField unfocuses on submit only when it is null).
              onEditingComplete: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
