import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../rooms/fake_chat_server.dart';
import '../site/site_theme.dart';

/// How many messages the fake server holds for the preview room.
enum PlaygroundHistory {
  empty(0),
  few(3),
  page(60),
  long(500);

  const PlaygroundHistory(this.total);
  final int total;
}

/// What the fake server answers when a message is sent.
enum PlaygroundSendResult { success, fail, block }

/// Every option the playground exposes. Changing [history], [latencyMs] or [images] reloads the
/// room; the rest apply live. The chat always runs reversed (newest message at offset 0).
class PlaygroundSettings {
  bool messagesStartAtTop = true;
  int appearMs = 250; // 0 = off
  ChatAlignment senderAlignment = ChatAlignment.end;
  double horizontalPadding = 24;
  double bubbleMaxWidth = 420; // >= _unlimitedWidth means no limit
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

const double _unlimitedWidth = 640;

const List<Color> _palette = [
  SiteColors.blue,
  Color(0xFF7C5CFA),
  Color(0xFF15B886),
  Color(0xFFFF8A3D),
  Color(0xFFF04452),
  SiteColors.grey900,
];

/// Try the chat with live settings: a large chat next to grouped settings cards (a toggle
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

  ChatController? _controller;
  late RoomInfo _room;
  String? _language;
  int _session = 0;
  bool _loadingInitial = true;
  bool _loadingOlder = false;
  bool _hasNoMoreMessage = false;
  int _incomingCount = 0;
  bool _showSettings = false; // narrow layout only

  PlaygroundSettings get s => _settings;
  ChatController get _chatController => _controller!;
  AppLocalizations get l => AppLocalizations.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The fake server writes its messages in the site language, so reload when it changes.
    final language = Localizations.localeOf(context).languageCode;
    if (language != _language) {
      _language = language;
      _replaceRoom();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _inputFocusNode.dispose();
    _controller?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Room loading (same flow as an app talking to a real server)

  /// Opens a fresh room; the old controller is disposed once its Chat is gone.
  void _replaceRoom() {
    final old = _controller;
    _session++;
    _room = RoomInfo(
      id: 'pg$_session',
      title: 'playground',
      description: '',
      totalMessages: s.history.total,
      latency: Duration(milliseconds: s.latencyMs),
      imageRatio: s.images ? 0.3 : 0,
    );
    _controller = ChatController(
      customSortCallback: (a, b) => a.timestamp.compareTo(b.timestamp),
    );
    _loadingInitial = true;
    _loadingOlder = false;
    _hasNoMoreMessage = s.history.total == 0;
    _loadInitialMessages(_session);
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _reloadRoom() => setState(_replaceRoom);

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
        name: _server.otherName,
        timestamp: DateTime.now().toIso8601String(),
        elements: [DemoTextElement(text ?? l.incomingMessage(_incomingCount))],
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
    final reply = l.autoReply(text);
    controller.dispatchMessage(
      SenderMessage(
        name: _server.myName,
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
            throw MessageBlockedException(code: 'BLOCKED', message: 'blocked');
          case PlaygroundSendResult.success:
            if (s.autoReply) {
              Future<void>.delayed(const Duration(milliseconds: 700), () {
                if (identical(controller, _controller) && !controller.isDisposed) {
                  controller.updateMessageAllRead();
                  _receive(reply);
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

  ChatConfiguration _configuration(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return ChatConfiguration(
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
                        Text(l.newMessageFrom(message.name),
                            style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ]),
                    ),
                  ),
                ),
              )
          : null,
      dateSeparatorBuilder: s.customDateSeparator
          ? (context, timestamp) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: SiteColors.grey100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(DateFormat.MMMEd(localeName).format(DateTime.parse(timestamp)),
                        style: const TextStyle(fontSize: 12, color: SiteColors.grey600)),
                  ),
                ),
              )
          : null,
      readOnlyWidget: Container(
        padding: const EdgeInsets.all(18),
        alignment: Alignment.center,
        color: SiteColors.grey50,
        child: Text(l.readOnlyNotice,
            style: const TextStyle(color: SiteColors.grey500, fontSize: 14)),
      ),
      bubbleConfiguration: BubbleConfiguration(
        maxWidth: s.unlimitedWidth ? double.infinity : s.bubbleMaxWidth,
        senderBubbleBuilder: (context, child) => _bubble(child, s.senderColor, Colors.white),
        receiverBubbleBuilder: (context, child) =>
            _bubble(child, SiteColors.grey100, SiteColors.grey900),
        // My own messages need no avatar.
        senderProfileBuilder: (context, name) => const SizedBox.shrink(),
        timeBuilder: s.customTime
            ? (context, timestamp) => Text(
                  DateFormat.jm(localeName).format(DateTime.parse(timestamp)),
                  style: const TextStyle(fontSize: 11, color: SiteColors.grey500),
                )
            : null,
        receiverProfileBuilder: s.receiverProfile
            ? (context, name) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _Avatar(name: name, size: 28),
                    const SizedBox(height: 4),
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
                    _menuItem(l.menuRetry, Icons.refresh_rounded,
                        (_, r) => _chatController.retryMessage(r.message)),
                  _menuItem(l.menuDelete, Icons.delete_outline_rounded,
                      (_, r) => _chatController.removeMessageEverywhere(r.message),
                      danger: true),
                ],
                receiverItemsBuilder: (context, request) => [
                  _menuItem(l.menuCopy, Icons.copy_rounded, (ctx, r) {
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
  }

  BubbleMenuItem _menuItem(String label, IconData icon, BubbleMenuItemCallback onSelected,
          {bool danger = false}) =>
      BubbleMenuItem(
        label: label,
        icon: Icon(icon, size: 18, color: danger ? SiteColors.red : SiteColors.grey600),
        height: 40,
        textStyle:
            TextStyle(fontSize: 14, color: danger ? SiteColors.red : SiteColors.grey900),
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
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 12, 28),
                  child: _chatCard(compact: false),
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
            options: {false: l.preview, true: l.settings},
            onChanged: (v) => setState(() => _showSettings = v),
          ),
        ),
        Expanded(
          // IndexedStack keeps the chat alive while the settings are shown.
          child: IndexedStack(index: _showSettings ? 1 : 0, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _chatCard(compact: true),
            ),
            _settingsList(withIntro: false),
          ]),
        ),
      ]);

  Widget _chatCard({required bool compact}) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: SiteShadows.card,
        ),
        child: Column(children: [
          _chatHeader(compact),
          const Divider(height: 1, color: SiteColors.grey100),
          Expanded(child: _chat()),
        ]),
      );

  Widget _chatHeader(bool compact) {
    final actions = [
      (l.receiveMessage, Icons.mark_chat_unread_outlined, () => _receive(), true),
      (l.markAllRead, Icons.done_all_rounded, () => _chatController.updateMessageAllRead(), false),
      (l.restart, Icons.refresh_rounded, _reloadRoom, false),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: 12),
      child: Row(children: [
        _Avatar(name: _server.otherName, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_server.otherName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Row(children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: Color(0xFF15B886), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(l.online,
                  style: const TextStyle(fontSize: 12, color: SiteColors.grey500)),
            ]),
          ]),
        ),
        if (_loadingInitial || _loadingOlder)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: SiteColors.blue),
            ),
          ),
        for (final (label, icon, onTap, primary) in actions)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: compact
                ? IconButton(
                    tooltip: label,
                    onPressed: onTap,
                    icon: Icon(icon, size: 20),
                    color: primary ? SiteColors.blue : SiteColors.grey600,
                  )
                : SiteButton(label: label, icon: icon, primary: primary, onPressed: onTap),
          ),
      ]),
    );
  }

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
      configuration: _configuration(context),
      onScrollToTop: _onScrollToTop,
      customInputField: (context, controller) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                  hintText: l.inputHint,
                  hintStyle: const TextStyle(color: SiteColors.grey400),
                  filled: true,
                  fillColor: SiteColors.grey100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                  width: 46,
                  height: 46,
                  child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
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
      // Extra right padding keeps the cards clear of the scrollbar.
      padding: EdgeInsets.fromLTRB(16, withIntro ? 28 : 8, 28, 48),
      children: [
        if (withIntro) ...[
          Text(l.navPlayground, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(l.playgroundIntro,
              style: const TextStyle(fontSize: 15, color: SiteColors.grey600, height: 1.6)),
          const SizedBox(height: 24),
        ],
        _group(l.sectionServer, [
          _FieldRow(
            title: l.storedMessages,
            child: SegmentedChoice<PlaygroundHistory>(
              value: s.history,
              options: {
                for (final h in PlaygroundHistory.values)
                  h: h.total == 0 ? l.none : l.messageCount(h.total),
              },
              onChanged: (v) => _set(() => s.history = v, reload: true),
            ),
          ),
          _SliderRow(
            title: l.responseTime,
            valueLabel: l.seconds((s.latencyMs / 1000).toStringAsFixed(1)),
            value: s.latencyMs.toDouble(),
            min: 0,
            max: 3000,
            onChanged: (v) => setState(() => s.latencyMs = (v / 100).round() * 100),
            onChangeEnd: (_) => _reloadRoom(),
          ),
          _SwitchRow(
            title: l.imagesTitle,
            description: l.imagesDesc,
            value: s.images,
            onChanged: (v) => _set(() => s.images = v, reload: true),
          ),
          _FieldRow(
            title: l.sendResult,
            child: SegmentedChoice<PlaygroundSendResult>(
              value: s.sendResult,
              options: {
                PlaygroundSendResult.success: l.resultSuccess,
                PlaygroundSendResult.fail: l.resultFail,
                PlaygroundSendResult.block: l.resultBlock,
              },
              onChanged: (v) => _set(() => s.sendResult = v),
            ),
          ),
          _SwitchRow(
            title: l.autoReplyTitle,
            description: l.autoReplyDesc,
            value: s.autoReply,
            onChanged: (v) => _set(() => s.autoReply = v),
          ),
        ]),
        _group(l.sectionLayout, [
          _SwitchRow(
            title: l.startAtTopTitle,
            api: 'messagesStartAtTop',
            description: l.startAtTopDesc,
            value: s.messagesStartAtTop,
            onChanged: (v) => _set(() => s.messagesStartAtTop = v),
          ),
          _FieldRow(
            title: l.senderSideTitle,
            api: 'senderAlignment',
            child: SegmentedChoice<ChatAlignment>(
              value: s.senderAlignment,
              options: {ChatAlignment.end: l.sideRight, ChatAlignment.start: l.sideLeft},
              onChanged: (v) => _set(() => s.senderAlignment = v),
            ),
          ),
          _SliderRow(
            title: l.sidePadding,
            api: 'padding',
            valueLabel: '${s.horizontalPadding.round()}px',
            value: s.horizontalPadding,
            min: 0,
            max: 64,
            onChanged: (v) => _set(() => s.horizontalPadding = v),
          ),
        ]),
        _group(l.sectionBubble, [
          _FieldRow(
            title: l.bubbleColor,
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
            title: l.cornerRadius,
            valueLabel: '${s.bubbleRadius.round()}px',
            value: s.bubbleRadius,
            min: 0,
            max: 24,
            onChanged: (v) => _set(() => s.bubbleRadius = v),
          ),
          _SliderRow(
            title: l.maxWidth,
            api: 'maxWidth',
            valueLabel: s.unlimitedWidth ? l.noLimit : '${s.bubbleMaxWidth.round()}px',
            value: s.bubbleMaxWidth,
            min: 200,
            max: _unlimitedWidth,
            onChanged: (v) => _set(() => s.bubbleMaxWidth = v),
          ),
          _FieldRow(
            title: l.appearAnimation,
            api: 'messageAppearAnimationDuration',
            child: SegmentedChoice<int>(
              value: s.appearMs,
              options: {0: l.off, 150: '150ms', 250: '250ms', 500: '500ms'},
              onChanged: (v) => _set(() => s.appearMs = v),
            ),
          ),
        ]),
        _group(l.sectionDisplay, [
          _SwitchRow(
            title: l.timeTitle,
            api: 'timeBuilder',
            description: l.timeDesc,
            value: s.customTime,
            onChanged: (v) => _set(() => s.customTime = v),
          ),
          _SwitchRow(
            title: l.profileTitle,
            api: 'receiverProfileBuilder',
            value: s.receiverProfile,
            onChanged: (v) => _set(() => s.receiverProfile = v),
          ),
          _SwitchRow(
            title: l.unreadTitle,
            api: 'readIndicatorBuilder',
            description: l.unreadDesc,
            value: s.readIndicator,
            onChanged: (v) => _set(() => s.readIndicator = v),
          ),
          _SwitchRow(
            title: l.longPressMenuTitle,
            api: 'menuConfiguration',
            value: s.bubbleMenu,
            onChanged: (v) => _set(() => s.bubbleMenu = v),
          ),
          _SwitchRow(
            title: l.notificationTitle,
            api: 'newReceiveMessageNotificationBuilder',
            description: l.notificationDesc,
            value: s.newMessageNotification,
            onChanged: (v) => _set(() => s.newMessageNotification = v),
          ),
          _SwitchRow(
            title: l.dateSeparatorTitle,
            api: 'dateSeparatorBuilder',
            value: s.customDateSeparator,
            onChanged: (v) => _set(() => s.customDateSeparator = v),
          ),
          _SwitchRow(
            title: l.readOnlyTitle,
            api: 'readOnly',
            description: l.readOnlyDesc,
            value: s.readOnly,
            onChanged: (v) => _set(() => s.readOnly = v),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SiteColors.blueWeak,
          borderRadius: BorderRadius.circular(size * 0.36),
        ),
        child: Text(
          name.characters.first,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: SiteColors.blue,
          ),
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
                key: ValueKey('segment-${entry.key}'),
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
