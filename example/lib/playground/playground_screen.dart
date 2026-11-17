import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../rooms/fake_chat_server.dart';

/// How many messages the fake server holds for the preview room.
enum PlaygroundHistory {
  empty('없음', 0),
  few('3건', 3),
  page('60건', 60),
  long('500건', 500);

  const PlaygroundHistory(this.label, this.total);
  final String label;
  final int total;
}

/// What the fake server answers when a message is sent.
enum PlaygroundSendResult {
  success('성공'),
  fail('실패 (재전송 가능)'),
  block('차단 (말풍선 제거)');

  const PlaygroundSendResult(this.label);
  final String label;
}

/// Every option the playground exposes. Changing [reverse], [history], [latencyMs] or [images]
/// reloads the room; the rest apply live.
class PlaygroundSettings {
  bool reverse = true;
  bool messagesStartAtTop = true;
  int appearMs = 250; // 0 = off
  ChatAlignment senderAlignment = ChatAlignment.end;
  double horizontalPadding = 16;
  double bubbleMaxWidth = 280; // >= _unlimitedWidth means no limit
  double bubbleRadius = 18;
  Color senderColor = _palette.first;
  bool customTime = true;
  bool receiverProfile = true;
  bool readIndicator = true;
  bool newMessageNotification = true;
  bool customDateSeparator = false;
  bool bubbleMenu = true;
  bool readOnly = false;

  PlaygroundHistory history = PlaygroundHistory.page;
  int latencyMs = 600;
  bool images = false;
  PlaygroundSendResult sendResult = PlaygroundSendResult.success;
  bool autoReply = true;

  bool get unlimitedWidth => bubbleMaxWidth >= _unlimitedWidth;
}

const double _unlimitedWidth = 520;

const List<Color> _palette = [
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF111827),
];

/// Try the chat with live settings: options on the left, a phone preview in the middle and the
/// matching code on the right (tabs on narrow screens). Messages come from [FakeChatServer], so
/// no backend is needed and it can be deployed as a static web site.
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key, this.onOpenExamples});

  /// Opens the other examples (room list); hidden when `null`.
  final VoidCallback? onOpenExamples;

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  final _settings = PlaygroundSettings();
  final _server = FakeChatServer.instance;
  final _textController = TextEditingController();
  final _inputFocusNode = FocusNode();

  late ChatController _chatController;
  late RoomInfo _room;
  int _session = 0;
  bool _loadingInitial = true;
  bool _loadingOlder = false;
  bool _hasNoMoreMessage = false;
  int _incomingCount = 0;

  PlaygroundSettings get s => _settings;

  @override
  void initState() {
    super.initState();
    _openRoom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _inputFocusNode.dispose();
    _chatController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Room loading (same flow as an app talking to a real server)

  void _openRoom() {
    _session++;
    _room = RoomInfo(
      id: 'pg$_session',
      title: 'playground',
      description: '',
      totalMessages: s.history.total,
      latency: Duration(milliseconds: s.latencyMs),
      imageRatio: s.images ? 0.3 : 0,
    );
    _chatController = ChatController(
      reverse: s.reverse,
      customSortCallback: (a, b) => a.timestamp.compareTo(b.timestamp),
    );
    _loadingInitial = true;
    _loadingOlder = false;
    _hasNoMoreMessage = s.history.total == 0;
    _loadInitialMessages(_session);
  }

  void _reloadRoom() {
    final old = _chatController;
    setState(_openRoom);
    // After the old Chat is gone.
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  Future<void> _loadInitialMessages(int session) async {
    final messages = s.history.total == 0
        ? <Message>[]
        : await _server.fetchMessages(_room);
    if (!mounted || session != _session) return;
    _chatController.setMessages(messages);
    _hasNoMoreMessage = messages.length < FakeChatServer.pageSize;
    setState(() => _loadingInitial = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_chatController.isDisposed) _chatController.scrollToBottom();
    });
  }

  Future<void> _onScrollToTop() async {
    if (_hasNoMoreMessage || _loadingOlder || _loadingInitial) return;
    final groups = _chatController.messageGroups;
    if (groups.isEmpty) return;
    final oldest = FakeChatServer.indexOf(groups.first.messages.first);
    if (oldest == null) return;
    final session = _session;
    setState(() => _loadingOlder = true);
    try {
      final messages = await _server.fetchMessages(_room, beforeIndex: oldest);
      if (!mounted || session != _session) return;
      _hasNoMoreMessage = messages.length < FakeChatServer.pageSize;
      if (messages.isNotEmpty) _chatController.appendMessages(messages);
    } finally {
      if (mounted && session == _session) setState(() => _loadingOlder = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Sending / receiving

  void _receive([String? text]) {
    _incomingCount++;
    _chatController.dispatchMessage(
      ReceiverMessage(
        id: 'in_${DateTime.now().microsecondsSinceEpoch}',
        name: '상담사',
        timestamp: DateTime.now().toIso8601String(),
        elements: [DemoTextElement(text ?? '새로 도착한 메시지 $_incomingCount')],
      ),
      onDispatch: (m) async => m,
    );
  }

  void _send() {
    _inputFocusNode.requestFocus();
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    final controller = _chatController;
    controller.dispatchMessage(
      SenderMessage(
        name: '나',
        timestamp: DateTime.now().toIso8601String(),
        elements: [DemoTextElement(text)],
        isRead: s.readIndicator ? false : null,
      ),
      onDispatch: (message) async {
        await Future<void>.delayed(Duration(milliseconds: s.latencyMs));
        switch (s.sendResult) {
          case PlaygroundSendResult.fail:
            return null;
          case PlaygroundSendResult.block:
            throw MessageBlockedException(code: 'BLOCKED', message: '차단된 메시지');
          case PlaygroundSendResult.success:
            if (s.autoReply) {
              Future<void>.delayed(const Duration(milliseconds: 700), () {
                if (identical(controller, _chatController) && !controller.isDisposed) {
                  controller.updateMessageAllRead();
                  _receive('"$text" 잘 받았습니다.');
                }
              });
            }
            return message.copyWith(isLoading: false);
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Configuration built from the settings

  ChatConfiguration get _configuration => ChatConfiguration(
        senderAlignment: s.senderAlignment,
        padding: EdgeInsets.symmetric(horizontal: s.horizontalPadding),
        messagesStartAtTop: s.messagesStartAtTop,
        messageAppearAnimationDuration:
            s.appearMs == 0 ? null : Duration(milliseconds: s.appearMs),
        newReceiveMessageNotificationBuilder: s.newMessageNotification
            ? (context, message, controller) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActionChip(
                    avatar: const Icon(Icons.arrow_downward, size: 16),
                    label: Text('새 메시지: ${message.name}'),
                    onPressed: controller.scrollToBottom,
                  ),
                )
            : null,
        dateSeparatorBuilder: s.customDateSeparator
            ? (context, timestamp) {
                final t = DateTime.parse(timestamp);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${t.year}년 ${t.month}월 ${t.day}일',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              }
            : null,
        readOnlyWidget: Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          color: Colors.grey.shade100,
          child: const Text('읽기 전용 채팅방입니다', style: TextStyle(color: Colors.grey)),
        ),
        bubbleConfiguration: BubbleConfiguration(
          maxWidth: s.unlimitedWidth ? double.infinity : s.bubbleMaxWidth,
          senderBubbleBuilder: (context, child) =>
              _bubble(child, s.senderColor, Colors.white),
          receiverBubbleBuilder: (context, child) =>
              _bubble(child, const Color(0xFFF1F1F4), Colors.black87),
          timeBuilder: s.customTime
              ? (context, timestamp) {
                  final t = DateTime.parse(timestamp);
                  return Text(
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  );
                }
              : null,
          receiverProfileBuilder: s.receiverProfile
              ? (context, name) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.teal.shade100,
                        child: Text(name.characters.first, style: const TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 6),
                      Text(name, style: const TextStyle(fontSize: 12)),
                    ]),
                  )
              : null,
          readIndicatorBuilder: s.readIndicator
              ? (context, isRead) => isRead
                  ? const SizedBox.shrink()
                  : const Text('1',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold))
              : null,
          menuConfiguration: s.bubbleMenu
              ? BubbleMenuConfiguration(
                  senderItemsBuilder: (context, request) => [
                    if (request.message.isFailed)
                      BubbleMenuItem(
                        label: '재전송',
                        icon: const Icon(Icons.refresh, size: 18),
                        onSelected: (_, r) => _chatController.retryMessage(r.message),
                      ),
                    BubbleMenuItem(
                      label: '삭제',
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onSelected: (_, r) => _chatController.removeMessageEverywhere(r.message),
                    ),
                  ],
                  receiverItemsBuilder: (context, request) => [
                    BubbleMenuItem(
                      label: '복사',
                      icon: const Icon(Icons.copy, size: 18),
                      onSelected: (ctx, r) => Clipboard.setData(ClipboardData(
                          text: r.message.elements
                              .whereType<DemoTextElement>()
                              .map((e) => e.text)
                              .join('\n'))),
                    ),
                  ],
                )
              : null,
        ),
      );

  Widget _bubble(Widget child, Color color, Color textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(s.bubbleRadius),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: textColor, fontSize: 15),
          child: child,
        ),
      );

  // ---------------------------------------------------------------------------
  // Layout

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1100;
      final medium = constraints.maxWidth >= 760;
      final appBar = AppBar(
        title: const Text('chat_toolkit playground'),
        actions: [
          if (widget.onOpenExamples != null)
            TextButton.icon(
              onPressed: widget.onOpenExamples,
              icon: const Icon(Icons.list_alt),
              label: const Text('다른 예제'),
            ),
          const SizedBox(width: 8),
        ],
        bottom: medium
            ? null
            : const TabBar(tabs: [Tab(text: '미리보기'), Tab(text: '설정'), Tab(text: '코드')]),
      );

      if (!medium) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: appBar,
            body: Builder(builder: (context) {
              final tabs = DefaultTabController.of(context);
              // IndexedStack (not TabBarView) keeps the chat alive while a tab is hidden.
              return ListenableBuilder(
                listenable: tabs,
                builder: (context, _) => IndexedStack(
                  index: tabs.index,
                  children: [_preview(), _settingsPanel(), _codePanel()],
                ),
              );
            }),
          ),
        );
      }

      return Scaffold(
        appBar: appBar,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 320, child: _settingsPanel()),
            const VerticalDivider(width: 1),
            Expanded(child: _preview()),
            if (wide) ...[
              const VerticalDivider(width: 1),
              SizedBox(width: 420, child: _codePanel()),
            ],
          ],
        ),
        floatingActionButton: wide
            ? null
            : FloatingActionButton.extended(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.8,
                    child: _codePanel(),
                  ),
                ),
                icon: const Icon(Icons.code),
                label: const Text('코드 보기'),
              ),
      );
    });
  }

  Widget _preview() {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerLow,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _receive,
                  icon: const Icon(Icons.mark_chat_unread_outlined, size: 18),
                  label: const Text('메시지 수신'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _chatController.updateMessageAllRead(),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('모두 읽음'),
                ),
                OutlinedButton.icon(
                  onPressed: _reloadRoom,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('다시 불러오기'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400, maxHeight: 800),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: colors.outlineVariant, width: 6),
                      boxShadow: const [
                        BoxShadow(blurRadius: 24, color: Colors.black12, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _phoneHeader(),
                        Expanded(child: _chat()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneHeader() => Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEDEDED))),
        ),
        child: Row(children: [
          const CircleAvatar(radius: 14, child: Icon(Icons.support_agent, size: 16)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('상담사', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (_loadingInitial || _loadingOlder)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ]),
      );

  Widget _chat() {
    if (_loadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    return Chat(
      // A new controller needs a new Chat.
      key: ObjectKey(_chatController),
      chatController: _chatController,
      readOnly: s.readOnly,
      configuration: _configuration,
      onScrollToTop: _onScrollToTop,
      customInputField: (context, controller) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _inputFocusNode,
                textInputAction: TextInputAction.send,
                // Set, so Enter does not unfocus the field.
                onEditingComplete: _send,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '메시지 입력',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(onPressed: _send, icon: const Icon(Icons.send, size: 18)),
          ]),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Settings panel

  void _set(VoidCallback change, {bool reload = false}) {
    change();
    if (reload) {
      _reloadRoom();
    } else {
      setState(() {});
    }
  }

  Widget _settingsPanel() {
    return ListView(
      key: const Key('playground-settings'),
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        const _Section('레이아웃'),
        _switch('reverse', '최신 메시지가 offset 0. 바꾸면 방을 다시 불러옵니다', s.reverse,
            (v) => _set(() => s.reverse = v, reload: true)),
        _switch('messagesStartAtTop', 'reverse 에서 메시지가 적을 때 위에서부터 표시',
            s.messagesStartAtTop, (v) => _set(() => s.messagesStartAtTop = v)),
        _choice<ChatAlignment>('senderAlignment', s.senderAlignment, {
          ChatAlignment.end: 'end (오른쪽)',
          ChatAlignment.start: 'start (왼쪽)',
        }, (v) => _set(() => s.senderAlignment = v)),
        _slider('padding (좌우)', s.horizontalPadding, 0, 48,
            (v) => _set(() => s.horizontalPadding = v)),
        const _Section('애니메이션'),
        _choice<int>('messageAppearAnimationDuration', s.appearMs, {
          0: '끄기',
          150: '150ms',
          250: '250ms',
          500: '500ms',
        }, (v) => _set(() => s.appearMs = v)),
        const _Section('말풍선'),
        _slider(
            'maxWidth${s.unlimitedWidth ? ' (제한 없음)' : ''}',
            s.bubbleMaxWidth,
            160,
            _unlimitedWidth,
            (v) => _set(() => s.bubbleMaxWidth = v)),
        _slider('모서리 둥글기', s.bubbleRadius, 0, 28, (v) => _set(() => s.bubbleRadius = v)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 6, children: [
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Text('보낸 말풍선 색'),
            ),
            for (final c in _palette)
              GestureDetector(
                onTap: () => _set(() => s.senderColor = c),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: s.senderColor == c ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ]),
        ),
        _switch('timeBuilder', '끄면 기본 시간 표시', s.customTime,
            (v) => _set(() => s.customTime = v)),
        _switch('receiverProfileBuilder', '받은 메시지 위에 프로필', s.receiverProfile,
            (v) => _set(() => s.receiverProfile = v)),
        _switch('readIndicatorBuilder', '보낸 메시지의 안 읽음 표시 (새로 보낸 메시지부터)',
            s.readIndicator, (v) => _set(() => s.readIndicator = v)),
        _switch('menuConfiguration', '말풍선을 길게 누르면 메뉴', s.bubbleMenu,
            (v) => _set(() => s.bubbleMenu = v)),
        const _Section('기타'),
        _switch('newReceiveMessageNotificationBuilder', '위로 스크롤한 상태에서 수신 시 알림',
            s.newMessageNotification, (v) => _set(() => s.newMessageNotification = v)),
        _switch('dateSeparatorBuilder', '끄면 기본 날짜 구분선', s.customDateSeparator,
            (v) => _set(() => s.customDateSeparator = v)),
        _switch('readOnly', '입력창 대신 readOnlyWidget', s.readOnly,
            (v) => _set(() => s.readOnly = v)),
        const _Section('가짜 서버'),
        _choice<PlaygroundHistory>('저장된 메시지', s.history, {
          for (final h in PlaygroundHistory.values) h: h.label,
        }, (v) => _set(() => s.history = v, reload: true)),
        _slider('응답 지연 ${s.latencyMs}ms', s.latencyMs.toDouble(), 0, 3000,
            (v) => setState(() => s.latencyMs = (v / 100).round() * 100),
            onChangeEnd: (_) => _reloadRoom(), showValue: false),
        _switch('이미지 메시지', '30%를 늦게 로드되는 이미지로 (다시 불러옴)', s.images,
            (v) => _set(() => s.images = v, reload: true)),
        _choice<PlaygroundSendResult>('전송 결과', s.sendResult, {
          for (final r in PlaygroundSendResult.values) r: r.label,
        }, (v) => _set(() => s.sendResult = v)),
        _switch('자동 답장', '전송 성공 후 상대가 읽고 답장', s.autoReply,
            (v) => _set(() => s.autoReply = v)),
      ],
    );
  }

  Widget _switch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        dense: true,
        title: Text(title, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      );

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged,
          {ValueChanged<double>? onChangeEnd, bool showValue = true}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(showValue ? '$label  ${value.round()}' : label,
              style: const TextStyle(fontSize: 13)),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ]),
      );

  Widget _choice<T>(String label, T value, Map<T, String> options, ValueChanged<T> onChanged) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final entry in options.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: entry.key == value,
                onSelected: (_) => onChanged(entry.key),
              ),
          ]),
        ]),
      );

  // ---------------------------------------------------------------------------
  // Code panel

  Widget _codePanel() {
    final code = playgroundCode(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(children: [
            const Expanded(
              child: Text('코드', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('코드를 복사했습니다')));
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('복사'),
            ),
          ]),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.5,
                  color: Color(0xFFE4E4F0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            )),
      );
}

String _hex(Color c) =>
    '0x${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

/// Dart code for [s]. Lists only the options that differ from the defaults.
String playgroundCode(PlaygroundSettings s) {
  final b = StringBuffer();
  b.writeln('final chatController = ChatController(reverse: ${s.reverse});');
  b.writeln();
  b.writeln('Chat(');
  b.writeln('  chatController: chatController,');
  if (s.readOnly) b.writeln('  readOnly: true,');
  b.writeln('  onScrollToTop: loadOlderMessages,');
  b.writeln('  configuration: ChatConfiguration(');
  if (s.senderAlignment != ChatAlignment.end) {
    b.writeln('    senderAlignment: ChatAlignment.${s.senderAlignment.name},');
  }
  if (s.horizontalPadding != 30) {
    b.writeln(
        '    padding: const EdgeInsets.symmetric(horizontal: ${s.horizontalPadding.round()}),');
  }
  if (s.messagesStartAtTop) b.writeln('    messagesStartAtTop: true,');
  if (s.appearMs > 0) {
    b.writeln(
        '    messageAppearAnimationDuration: const Duration(milliseconds: ${s.appearMs}),');
  }
  if (s.newMessageNotification) {
    b.writeln('    newReceiveMessageNotificationBuilder: (context, message, controller) =>');
    b.writeln('        ActionChip(');
    b.writeln("          label: Text('새 메시지: \${message.name}'),");
    b.writeln('          onPressed: controller.scrollToBottom,');
    b.writeln('        ),');
  }
  if (s.customDateSeparator) {
    b.writeln('    dateSeparatorBuilder: (context, timestamp) => MyDateChip(timestamp),');
  }
  if (s.readOnly) {
    b.writeln("    readOnlyWidget: const Text('읽기 전용 채팅방입니다'),");
  }
  b.writeln('    bubbleConfiguration: BubbleConfiguration(');
  if (!s.unlimitedWidth) b.writeln('      maxWidth: ${s.bubbleMaxWidth.round()},');
  b.writeln('      senderBubbleBuilder: (context, child) => Container(');
  b.writeln('        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),');
  b.writeln('        decoration: BoxDecoration(');
  b.writeln('          color: const Color(${_hex(s.senderColor)}),');
  b.writeln('          borderRadius: BorderRadius.circular(${s.bubbleRadius.round()}),');
  b.writeln('        ),');
  b.writeln('        child: child,');
  b.writeln('      ),');
  b.writeln('      receiverBubbleBuilder: (context, child) => Container(');
  b.writeln('        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),');
  b.writeln('        decoration: BoxDecoration(');
  b.writeln('          color: const Color(0xFFF1F1F4),');
  b.writeln('          borderRadius: BorderRadius.circular(${s.bubbleRadius.round()}),');
  b.writeln('        ),');
  b.writeln('        child: child,');
  b.writeln('      ),');
  if (s.customTime) {
    b.writeln('      timeBuilder: (context, timestamp) => Text(formatHHmm(timestamp)),');
  }
  if (s.receiverProfile) {
    b.writeln('      receiverProfileBuilder: (context, name) => MyProfile(name),');
  }
  if (s.readIndicator) {
    b.writeln("      readIndicatorBuilder: (context, isRead) => isRead ? const SizedBox() : const Text('1'),");
  }
  if (s.bubbleMenu) {
    b.writeln('      menuConfiguration: BubbleMenuConfiguration(');
    b.writeln('        senderItemsBuilder: (context, request) => [');
    b.writeln("          BubbleMenuItem(label: '삭제', onSelected: (_, r) =>");
    b.writeln('              chatController.removeMessageEverywhere(r.message)),');
    b.writeln('        ],');
    b.writeln('      ),');
  }
  b.writeln('    ),');
  b.writeln('  ),');
  b.writeln(');');
  return b.toString();
}
