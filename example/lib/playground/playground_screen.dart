import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../rooms/fake_chat_server.dart';
import '../site/site_theme.dart';

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
  fail('실패'),
  block('차단');

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
  double bubbleMaxWidth = 260; // >= _unlimitedWidth means no limit
  double bubbleRadius = 18;
  Color senderColor = _palette.first;
  bool customTime = true;
  bool receiverProfile = true;
  bool readIndicator = true;
  bool newMessageNotification = true;
  bool customDateSeparator = true;
  bool bubbleMenu = true;
  bool readOnly = false;

  PlaygroundHistory history = PlaygroundHistory.page;
  int latencyMs = 600;
  bool images = false;
  PlaygroundSendResult sendResult = PlaygroundSendResult.success;
  bool autoReply = true;

  bool get unlimitedWidth => bubbleMaxWidth >= _unlimitedWidth;
}

const double _unlimitedWidth = 340;

const List<Color> _palette = [
  SiteColors.blue,
  Color(0xFF7C5CFA),
  Color(0xFF15B886),
  Color(0xFFFF8A3D),
  Color(0xFFF04452),
  SiteColors.grey900,
];

/// Try the chat with live settings: a phone preview next to grouped settings cards (a toggle
/// between them on narrow screens). Messages come from [FakeChatServer], so no backend is needed
/// and the site can be served as static files.
class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
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
  bool _showSettings = false; // narrow layout only

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
    final messages =
        s.history.total == 0 ? <Message>[] : await _server.fetchMessages(_room);
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
        elements: [DemoTextElement(text ?? '새로 도착한 메시지예요 ($_incomingCount)')],
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
                  _receive('"$text" 잘 받았어요.');
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
                  child: Material(
                    color: SiteColors.grey900,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: controller.scrollToBottom,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.arrow_downward_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text('${message.name}님의 새 메시지',
                              style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ]),
                      ),
                    ),
                  ),
                )
            : null,
        dateSeparatorBuilder: s.customDateSeparator
            ? (context, timestamp) {
                final t = DateTime.parse(timestamp);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: SiteColors.grey100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('${t.month}월 ${t.day}일',
                          style: const TextStyle(fontSize: 12, color: SiteColors.grey600)),
                    ),
                  ),
                );
              }
            : null,
        readOnlyWidget: Container(
          padding: const EdgeInsets.all(18),
          alignment: Alignment.center,
          color: SiteColors.grey50,
          child: const Text('상담이 끝나서 메시지를 보낼 수 없어요',
              style: TextStyle(color: SiteColors.grey500, fontSize: 14)),
        ),
        bubbleConfiguration: BubbleConfiguration(
          maxWidth: s.unlimitedWidth ? double.infinity : s.bubbleMaxWidth,
          senderBubbleBuilder: (context, child) =>
              _bubble(child, s.senderColor, Colors.white),
          receiverBubbleBuilder: (context, child) =>
              _bubble(child, SiteColors.grey100, SiteColors.grey900),
          // My own messages need no avatar.
          senderProfileBuilder: (context, name) => const SizedBox.shrink(),
          timeBuilder: s.customTime
              ? (context, timestamp) {
                  final t = DateTime.parse(timestamp);
                  final pm = t.hour >= 12;
                  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
                  return Text(
                    '${pm ? '오후' : '오전'} $h:${t.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: SiteColors.grey500),
                  );
                }
              : null,
          receiverProfileBuilder: s.receiverProfile
              ? (context, name) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: SiteColors.blueWeak,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.support_agent_rounded,
                            size: 16, color: SiteColors.blue),
                      ),
                      const SizedBox(width: 8),
                      Text(name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: SiteColors.grey700)),
                    ]),
                  )
              : null,
          readIndicatorBuilder: s.readIndicator
              ? (context, isRead) => isRead
                  ? const SizedBox.shrink()
                  : const Text('1',
                      style: TextStyle(
                          fontSize: 11, color: SiteColors.blue, fontWeight: FontWeight.w700))
              : null,
          menuConfiguration: s.bubbleMenu
              ? BubbleMenuConfiguration(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  senderItemsBuilder: (context, request) => [
                    if (request.message.isFailed)
                      _menuItem('다시 보내기', Icons.refresh_rounded,
                          (_, r) => _chatController.retryMessage(r.message)),
                    _menuItem('삭제하기', Icons.delete_outline_rounded,
                        (_, r) => _chatController.removeMessageEverywhere(r.message),
                        danger: true),
                  ],
                  receiverItemsBuilder: (context, request) => [
                    _menuItem('복사하기', Icons.copy_rounded, (ctx, r) {
                      Clipboard.setData(ClipboardData(
                          text: r.message.elements
                              .whereType<DemoTextElement>()
                              .map((e) => e.text)
                              .join('\n')));
                    }),
                  ],
                )
              : null,
        ),
      );

  BubbleMenuItem _menuItem(String label, IconData icon, BubbleMenuItemCallback onSelected,
          {bool danger = false}) =>
      BubbleMenuItem(
        label: label,
        icon: Icon(icon, size: 18, color: danger ? SiteColors.red : SiteColors.grey600),
        height: 40,
        textStyle: TextStyle(
            fontSize: 14, color: danger ? SiteColors.red : SiteColors.grey900),
        onSelected: onSelected,
      );

  Widget _bubble(Widget child, Color color, Color textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(s.bubbleRadius),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: textColor, fontSize: 15, height: 1.45),
          child: child,
        ),
      );

  // ---------------------------------------------------------------------------
  // Layout

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 1024) return _wide();
      return _narrow();
    });
  }

  Widget _wide() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Flexible(child: PhoneFrame(child: _phoneScreen())),
                    const SizedBox(height: 20),
                    _previewActions(),
                  ]),
                ),
              ),
              SizedBox(width: 460, child: _settingsList(withIntro: true)),
            ],
          ),
        ),
      );

  Widget _narrow() => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SegmentedChoice<bool>(
            value: _showSettings,
            options: const {false: '미리보기', true: '설정'},
            onChanged: (v) => setState(() => _showSettings = v),
          ),
        ),
        Expanded(
          // IndexedStack keeps the chat alive while the settings are shown.
          child: IndexedStack(index: _showSettings ? 1 : 0, children: [
            Column(children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: SiteShadows.card,
                  ),
                  child: _phoneScreen(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _previewActions(),
              ),
            ]),
            _settingsList(withIntro: false),
          ]),
        ),
      ]);

  Widget _previewActions() => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          SiteButton(
              label: '메시지 받기',
              icon: Icons.mark_chat_unread_outlined,
              primary: true,
              onPressed: _receive),
          SiteButton(
              label: '모두 읽음',
              icon: Icons.done_all_rounded,
              onPressed: () => _chatController.updateMessageAllRead()),
          SiteButton(label: '처음부터', icon: Icons.refresh_rounded, onPressed: _reloadRoom),
        ],
      );

  Widget _phoneScreen() => Column(children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: SiteColors.grey100)),
          ),
          child: Row(children: [
            const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: SiteColors.grey700),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('상담사',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('보통 1분 안에 답해요',
                      style: TextStyle(fontSize: 12, color: SiteColors.grey500)),
                ],
              ),
            ),
            if (_loadingInitial || _loadingOlder)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: SiteColors.blue),
              ),
          ]),
        ),
        Expanded(child: _chat()),
      ]);

  Widget _chat() {
    if (_loadingInitial) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5, color: SiteColors.blue),
      );
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
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '메시지를 입력해 주세요',
                  hintStyle: const TextStyle(color: SiteColors.grey400),
                  filled: true,
                  fillColor: SiteColors.grey100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: SiteColors.blue,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _send,
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Settings

  void _set(VoidCallback change, {bool reload = false}) {
    change();
    if (reload) {
      _reloadRoom();
    } else {
      setState(() {});
    }
  }

  Widget _settingsList({required bool withIntro}) {
    return ListView(
      key: const Key('playground-settings'),
      padding: EdgeInsets.fromLTRB(16, withIntro ? 32 : 8, 16, 48),
      children: [
        if (withIntro) ...[
          Text('플레이그라운드', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            '옵션을 바꾸면 왼쪽 채팅에 바로 반영돼요.\n메시지는 가짜 서버에서 불러오니 마음껏 보내 보세요.',
            style: TextStyle(fontSize: 15, color: SiteColors.grey600, height: 1.6),
          ),
          const SizedBox(height: 24),
        ],
        _group('레이아웃', [
          _SwitchRow(
            title: '최신 메시지를 offset 0에',
            api: 'ChatController(reverse:)',
            description: '바꾸면 채팅방을 다시 불러와요',
            value: s.reverse,
            onChanged: (v) => _set(() => s.reverse = v, reload: true),
          ),
          _SwitchRow(
            title: '메시지가 적으면 위에서부터',
            api: 'messagesStartAtTop',
            description: 'reverse 일 때만 적용돼요',
            value: s.messagesStartAtTop,
            onChanged: (v) => _set(() => s.messagesStartAtTop = v),
          ),
          _FieldRow(
            title: '내 메시지 위치',
            api: 'senderAlignment',
            child: SegmentedChoice<ChatAlignment>(
              value: s.senderAlignment,
              options: const {ChatAlignment.end: '오른쪽', ChatAlignment.start: '왼쪽'},
              onChanged: (v) => _set(() => s.senderAlignment = v),
            ),
          ),
          _SliderRow(
            title: '좌우 여백',
            api: 'padding',
            valueLabel: '${s.horizontalPadding.round()}px',
            value: s.horizontalPadding,
            min: 0,
            max: 40,
            onChanged: (v) => _set(() => s.horizontalPadding = v),
          ),
        ]),
        _group('말풍선', [
          _FieldRow(
            title: '내 말풍선 색',
            child: Wrap(spacing: 10, runSpacing: 10, children: [
              for (final c in _palette)
                GestureDetector(
                  onTap: () => _set(() => s.senderColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: s.senderColor == c ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (s.senderColor == c) BoxShadow(color: c, spreadRadius: 2),
                      ],
                    ),
                  ),
                ),
            ]),
          ),
          _SliderRow(
            title: '모서리 둥글기',
            valueLabel: '${s.bubbleRadius.round()}px',
            value: s.bubbleRadius,
            min: 0,
            max: 24,
            onChanged: (v) => _set(() => s.bubbleRadius = v),
          ),
          _SliderRow(
            title: '최대 너비',
            api: 'maxWidth',
            valueLabel: s.unlimitedWidth ? '제한 없음' : '${s.bubbleMaxWidth.round()}px',
            value: s.bubbleMaxWidth,
            min: 160,
            max: _unlimitedWidth,
            onChanged: (v) => _set(() => s.bubbleMaxWidth = v),
          ),
          _FieldRow(
            title: '등장 애니메이션',
            api: 'messageAppearAnimationDuration',
            child: SegmentedChoice<int>(
              value: s.appearMs,
              options: const {0: '끄기', 150: '150ms', 250: '250ms', 500: '500ms'},
              onChanged: (v) => _set(() => s.appearMs = v),
            ),
          ),
        ]),
        _group('표시 요소', [
          _SwitchRow(
            title: '보낸 시간',
            api: 'timeBuilder',
            description: '끄면 기본 형식으로 보여요',
            value: s.customTime,
            onChanged: (v) => _set(() => s.customTime = v),
          ),
          _SwitchRow(
            title: '상대 프로필',
            api: 'receiverProfileBuilder',
            value: s.receiverProfile,
            onChanged: (v) => _set(() => s.receiverProfile = v),
          ),
          _SwitchRow(
            title: '안 읽음 표시',
            api: 'readIndicatorBuilder',
            description: '새로 보내는 메시지부터 보여요',
            value: s.readIndicator,
            onChanged: (v) => _set(() => s.readIndicator = v),
          ),
          _SwitchRow(
            title: '길게 눌러 메뉴 열기',
            api: 'menuConfiguration',
            value: s.bubbleMenu,
            onChanged: (v) => _set(() => s.bubbleMenu = v),
          ),
          _SwitchRow(
            title: '새 메시지 알림',
            api: 'newReceiveMessageNotificationBuilder',
            description: '위로 올려 둔 채 메시지를 받으면 보여요',
            value: s.newMessageNotification,
            onChanged: (v) => _set(() => s.newMessageNotification = v),
          ),
          _SwitchRow(
            title: '날짜 구분선 꾸미기',
            api: 'dateSeparatorBuilder',
            value: s.customDateSeparator,
            onChanged: (v) => _set(() => s.customDateSeparator = v),
          ),
          _SwitchRow(
            title: '읽기 전용',
            api: 'readOnly',
            description: '입력창 대신 안내 문구를 보여요',
            value: s.readOnly,
            onChanged: (v) => _set(() => s.readOnly = v),
          ),
        ]),
        _group('가짜 서버', [
          _FieldRow(
            title: '저장된 메시지',
            child: SegmentedChoice<PlaygroundHistory>(
              value: s.history,
              options: {for (final h in PlaygroundHistory.values) h: h.label},
              onChanged: (v) => _set(() => s.history = v, reload: true),
            ),
          ),
          _SliderRow(
            title: '응답 시간',
            valueLabel: '${(s.latencyMs / 1000).toStringAsFixed(1)}초',
            value: s.latencyMs.toDouble(),
            min: 0,
            max: 3000,
            onChanged: (v) => setState(() => s.latencyMs = (v / 100).round() * 100),
            onChangeEnd: (_) => _reloadRoom(),
          ),
          _SwitchRow(
            title: '이미지 메시지 섞기',
            description: '30%가 늦게 로드되는 이미지예요',
            value: s.images,
            onChanged: (v) => _set(() => s.images = v, reload: true),
          ),
          _FieldRow(
            title: '보내기 결과',
            child: SegmentedChoice<PlaygroundSendResult>(
              value: s.sendResult,
              options: {for (final r in PlaygroundSendResult.values) r: r.label},
              onChanged: (v) => _set(() => s.sendResult = v),
            ),
          ),
          _SwitchRow(
            title: '자동 답장',
            description: '보내기에 성공하면 상대가 읽고 답해요',
            value: s.autoReply,
            onChanged: (v) => _set(() => s.autoReply = v),
          ),
        ]),
      ],
    );
  }

  Widget _group(String title, List<Widget> rows) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SiteCard(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            ...rows,
          ]),
        ),
      );
}

// -----------------------------------------------------------------------------
// Setting rows

class _RowLabel extends StatelessWidget {
  const _RowLabel({required this.title, this.api, this.description});

  final String title;
  final String? api;
  final String? description;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500, color: SiteColors.grey800)),
              if (api != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SiteColors.grey100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(api!,
                      style: const TextStyle(
                          fontSize: 11, fontFamily: 'monospace', color: SiteColors.grey600)),
                ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(description!,
                style: const TextStyle(fontSize: 13, color: SiteColors.grey500)),
          ],
        ],
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    this.api,
    this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? api;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Expanded(child: _RowLabel(title: title, api: api, description: description)),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: onChanged),
          ]),
        ),
      );
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.title, this.api, required this.child});

  final String title;
  final String? api;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _RowLabel(title: title, api: api),
          const SizedBox(height: 10),
          child,
        ]),
      );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.title,
    this.api,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
  });

  final String title;
  final String? api;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _RowLabel(title: title, api: api)),
            Text(valueLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SiteColors.blue,
                  fontFeatures: [FontFeature.tabularFigures()],
                )),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ]),
      );
}

/// Mutually exclusive choice: a grey track with the selected segment raised in white.
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: SiteColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          for (final entry in options.entries)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: const Cubic(0.22, 0.61, 0.36, 1),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: entry.key == value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: entry.key == value ? SiteShadows.card : null,
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: entry.key == value ? FontWeight.w600 : FontWeight.w500,
                      color: entry.key == value ? SiteColors.grey900 : SiteColors.grey500,
                    ),
                  ),
                ),
              ),
            ),
        ]),
      );
}
