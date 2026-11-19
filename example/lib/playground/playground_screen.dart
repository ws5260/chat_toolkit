import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../rooms/fake_chat_server.dart';
import '../site/site_theme.dart';
import 'playground_controls.dart';
import 'playground_settings.dart';
import 'studio_code.dart';
import 'studio_editor.dart';
import 'studio_render.dart';

/// Try the chat with live settings: a large chat next to grouped settings cards (a toggle
/// between them on narrow screens). Messages come from [FakeChatServer], so no backend is needed
/// and the site can be served as static files.
class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key, this.settings, this.changes});

  /// Settings to start from; for tests.
  final PlaygroundSettings? settings;

  /// Rebuilds the page when [settings] are changed from outside; for tests.
  final Listenable? changes;

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  late final _settings = widget.settings ?? PlaygroundSettings();
  final _server = FakeChatServer.instance;
  final _textController = TextEditingController();
  final _inputFocusNode = FocusNode();

  ChatController? _controller;
  late RoomInfo _room;
  String? _language;
  int _session = 0;
  static int _roomCount = 0;
  bool _loadingInitial = true;
  bool _loadingOlder = false;
  bool _loadingNewer = false;
  bool _hasNoMoreMessage = false;

  ChatSearchController? _searchController;
  ChatSearchController get _search => _searchController!;
  int _incomingCount = 0;
  bool _showSettings = false; // narrow layout only

  PlaygroundSettings get s => _settings;
  ChatController get _chatController => _controller!;
  AppLocalizations get l => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    widget.changes?.addListener(_onChanges);
  }

  void _onChanges() => setState(() {});

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
    widget.changes?.removeListener(_onChanges);
    _textController.dispose();
    _inputFocusNode.dispose();
    _searchController?.dispose();
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
      // Unique for the app run: the fake server keeps the messages posted in each room.
      id: 'pg${++_roomCount}',
      title: 'playground',
      description: '',
      totalMessages: s.history.total,
      latency: Duration(milliseconds: s.latencyMs),
      imageRatio: s.images ? 0.3 : 0,
    );
    _controller = ChatController(
      customSortCallback: (a, b) => a.timestamp.compareTo(b.timestamp),
      // Never join an existing group: every message gets its own profile and time.
      additionalGroupCondition: s.grouping ? null : (group, message) => false,
    );
    _loadingInitial = true;
    _loadingOlder = false;
    _loadingNewer = false;
    final oldSearch = _searchController;
    final room = _room;
    _searchController = ChatSearchController(
      chatController: _controller!,
      // The fake server finds indices; the search works with message ids.
      onSearch: (query) async => [
        for (final index in await _server.search(room, query)) _server.idAt(room, index),
      ],
      onLoadAround: _loadAround,
    );
    if (oldSearch != null) WidgetsBinding.instance.addPostFrameCallback((_) => oldSearch.dispose());
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
    final oldest = _server.indexIn(_room, groups.first.messages.first);
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

  // Called at the newest loaded message while ChatController.hasNewerMessages is true, i.e. after
  // jumping to a search result.
  Future<void> _onScrollToBottom() async {
    if (_loadingNewer || _loadingInitial || !_chatController.hasNewerMessages) return;
    final groups = _chatController.messageGroups;
    if (groups.isEmpty) return;
    final newest = _server.indexIn(_room, groups.last.messages.last);
    if (newest == null) return;
    final session = _session;
    setState(() => _loadingNewer = true);
    try {
      final page = await _server.fetchNewer(_room, afterIndex: newest);
      if (!mounted || session != _session) return;
      _chatController.addNewerMessages(page.messages, hasMore: page.hasMore);
    } finally {
      if (mounted && session == _session) setState(() => _loadingNewer = false);
    }
  }

  /// Reloads the latest messages after looking at an earlier part of the conversation.
  Future<void> _goToLatest() async {
    final session = _session;
    final messages = await _server.fetchMessages(_room);
    if (!mounted || session != _session) return;
    _chatController.setMessages(messages);
    _hasNoMoreMessage = messages.length < FakeChatServer.pageSize;
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Search

  /// Loads the messages around a search result that is not loaded.
  Future<void> _loadAround(String messageId) async {
    final session = _session;
    final index = _server.indexOfId(_room, messageId);
    if (index == null) return;
    final page = await _server.fetchAround(_room, index);
    if (!mounted || session != _session) return;
    _hasNoMoreMessage = !page.hasOlder;
    // The search term is marked in the text (SearchHighlightedText), so the message itself is
    // not highlighted.
    await _chatController.setMessagesAround(
      page.messages,
      anchorMessageId: messageId,
      hasNewerMessages: page.hasNewer,
      highlight: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Sending / receiving

  Future<void> _receive([String? text]) async {
    // A message from the server belongs after the newest one, so return to the present first.
    if (_chatController.hasNewerMessages) await _goToLatest();
    if (!mounted) return;
    _incomingCount++;
    final room = _room;
    final id = 'in_${DateTime.now().microsecondsSinceEpoch}';
    _chatController.dispatchMessage(
      ReceiverMessage(
        id: id,
        name: _server.otherName,
        timestamp: DateTime.now().toIso8601String(),
        elements: [DemoTextElement(text ?? l.incomingMessage(_incomingCount))],
      ),
      onDispatch: (m) async {
        _server.post(room, m);
        return m;
      },
    );
  }

  Future<void> _send() async {
    _inputFocusNode.requestFocus();
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    // A sent message belongs after the newest one, so return to the present first.
    if (_chatController.hasNewerMessages) await _goToLatest();
    if (!mounted) return;
    final room = _room;

    final controller = _chatController;
    final reply = l.autoReply(text);
    final id = 'out_${DateTime.now().microsecondsSinceEpoch}';
    controller.dispatchMessage(
      SenderMessage(
        id: id,
        name: _server.myName,
        timestamp: DateTime.now().toIso8601String(),
        elements: [DemoTextElement(text)],
        isRead: false,
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
            final sent = message.copyWith(isLoading: false);
            _server.post(room, sent);
            return sent;
        }
      },
    );
  }

  Future<bool> _confirmDelete(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteFailedTitle),
        content: Text(l.deleteFailedBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.menuDelete, style: const TextStyle(color: SiteColors.red)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  // ---------------------------------------------------------------------------
  // Configuration built from the settings

  bool _custom(Part part) => s.look(part) == Look.custom;

  /// The text of a studio text or badge element.
  String _textOf(
    StudioElement e, {
    String name = '',
    String timestamp = '',
    bool isRead = false,
    ChatSearchController? search,
  }) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    DateTime date() => DateTime.parse(timestamp);
    return switch (e.source) {
      TextSource.literal => e.text,
      TextSource.name => name,
      TextSource.time => timestamp.isEmpty
          ? ''
          : (e.use24h ? DateFormat.Hm(locale) : DateFormat.jm(locale)).format(date()),
      TextSource.date => timestamp.isEmpty
          ? ''
          : (e.weekday ? DateFormat.MMMEd(locale) : DateFormat.yMd(locale)).format(date()),
      TextSource.resultCount => search == null || !search.hasSearched
          ? ''
          : search.results.isEmpty
              ? l.searchNoResults
              : l.searchResultCount(search.index + 1, search.results.length),
      TextSource.readState => isRead ? e.text2 : e.text,
      TextSource.noticeLabel => l.newMessageFrom(name),
      TextSource.readOnlyLabel => l.readOnlyNotice,
    };
  }

  String _actionLabel(ButtonAction a) => switch (a) {
        ButtonAction.send => l.send,
        ButtonAction.attach => l.actAttach,
        ButtonAction.older => l.searchOlder,
        ButtonAction.newer => l.searchNewer,
        ButtonAction.close => l.closeSearch,
        ButtonAction.none => '',
      };

  Widget _render(Part part, {StudioSpec? spec, String name = '', String timestamp = '',
          bool isRead = false, Widget? content, VoidCallback? onTap, bool aligned = true}) =>
      renderStudio(
        spec ?? s.spec(part),
        StudioBinding(
          text: (e) => _textOf(e, name: name, timestamp: timestamp, isRead: isRead),
          content: content,
          isRead: isRead,
          actionLabel: _actionLabel,
          onTap: onTap,
        ),
        aligned: aligned,
      );

  /// Builder of a part that is custom, hidden or the toolkit's (`null`).
  T? _builder<T>(Part part, T custom, T hidden) => switch (s.look(part)) {
        Look.custom => custom,
        Look.hidden => hidden,
        Look.library => null,
      };

  ChatConfiguration _configuration(BuildContext context) {
    return ChatConfiguration(
      senderAlignment: s.senderAlignment,
      padding: EdgeInsets.symmetric(horizontal: s.horizontalPadding, vertical: s.verticalPadding),
      messagesStartAtTop: s.messagesStartAtTop,
      messageAppearAnimationDuration:
          s.appearMs == 0 ? null : Duration(milliseconds: s.appearMs),
      newMessageScrollThreshold: s.scrollThreshold,
      searchShortcuts: s.searchShortcuts ? defaultChatSearchShortcuts : const {},
      searchBarBuilder: (context, search) => _custom(Part.search)
          ? _StudioSearchBar(
              search: search,
              spec: s.spec(Part.search),
              textOf: _textOf,
              actionLabel: _actionLabel,
              hint: l.searchHint,
            )
          : ChatSearchBar(
              controller: search,
              hintText: l.searchHint,
              noResultsText: l.searchNoResults,
              olderTooltip: l.searchOlder,
              newerTooltip: l.searchNewer,
              closeTooltip: l.closeSearch,
              resultCountBuilder: l.searchResultCount,
              style: s.textStyle(Part.search),
            ),
      newReceiveMessageNotificationBuilder: _custom(Part.notice)
          ? (context, message, controller) => _render(Part.notice,
              name: message.name, timestamp: message.timestamp, onTap: controller.scrollToBottom)
          : null,
      dateSeparatorBuilder: _builder<Widget Function(BuildContext, String)>(
        Part.separator,
        (context, timestamp) => _render(Part.separator, timestamp: timestamp),
        (context, timestamp) => const SizedBox.shrink(),
      ),
      dateSeparatorStyle: s.look(Part.separator) == Look.library
          ? s.textStyle(Part.separator)
          : null,
      readOnlyWidget: _custom(Part.readOnly) ? _render(Part.readOnly) : null,
      bubbleConfiguration: BubbleConfiguration(
        maxWidth: s.unlimited ? double.infinity : s.maxWidth,
        senderBubbleBuilder: _custom(Part.bubble)
            ? (context, child) => _render(Part.bubble, content: child, aligned: false)
            : null,
        receiverBubbleBuilder: _custom(Part.bubble)
            ? (context, child) =>
                _render(Part.bubble, spec: s.receiverBubble, content: child, aligned: false)
            : null,
        loadingWidget: s.customSendingIndicator ? _sendingIndicator() : const BubbleConfiguration().loadingWidget,
        senderProfileBuilder: s.myProfile
            ? _builder<Widget Function(BuildContext, String)>(
                Part.profile,
                (context, name) => _render(Part.profile, name: name, aligned: false),
                (context, name) => const SizedBox.shrink(),
              )
            : (context, name) => const SizedBox.shrink(),
        profileNameStyle:
            s.look(Part.profile) == Look.library ? s.textStyle(Part.profile) : null,
        timeStyle: s.look(Part.time) == Look.library ? s.textStyle(Part.time) : null,
        receiverProfileBuilder: _builder<Widget Function(BuildContext, String)>(
          Part.profile,
          (context, name) => _render(Part.profile, name: name, aligned: false),
          (context, name) => const SizedBox.shrink(),
        ),
        timeBuilder: _builder<Widget Function(BuildContext, String)>(
          Part.time,
          (context, timestamp) => _render(Part.time, timestamp: timestamp, aligned: false),
          (context, timestamp) => const SizedBox.shrink(),
        ),
        readIndicatorBuilder: _custom(Part.read)
            ? (context, isRead) => _render(Part.read, isRead: isRead, aligned: false)
            : null,
        menuConfiguration: s.menu == MenuKind.off
            ? null
            : BubbleMenuConfiguration(
                enableLongPress: s.longPress,
                enableHapticFeedback: s.haptic,
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                senderItemsBuilder: (context, request) =>
                    [for (final a in _menuActions(request)) _menuItem(a)],
                receiverItemsBuilder: (context, request) =>
                    [for (final a in _menuActions(request)) _menuItem(a)],
                senderMenuHandler: s.menu == MenuKind.sheet ? _showMenuSheet : null,
                receiverMenuHandler: s.menu == MenuKind.sheet ? _showMenuSheet : null,
              ),
      ),
    );
  }

  Widget _sendingIndicator() {
    final content = s.spec(Part.bubble).elements.where((e) => e.kind == ElementKind.content);
    final color = _custom(Part.bubble) && content.isNotEmpty
        ? content.first.color
        : SiteColors.grey700;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1.6, color: color),
      ),
      const SizedBox(width: 8),
      Text(l.sending, style: TextStyle(fontSize: 13, color: color)),
    ]);
  }

  /// What the bubble menu offers for a message, shared by the popup and the sheet.
  List<_MenuAction> _menuActions(BubbleMenuRequest request) => [
        if (request.message.isFailed)
          _MenuAction(l.menuRetry, Icons.refresh_rounded,
              (_, r) => _chatController.retryMessage(r.message)),
        _MenuAction(l.menuCopy, Icons.copy_rounded, (ctx, r) {
          Clipboard.setData(ClipboardData(
              text: r.message.elements.whereType<DemoTextElement>().map((e) => e.text).join('\n')));
        }),
        if (request.isSender)
          _MenuAction(l.menuDelete, Icons.delete_outline_rounded,
              (_, r) => _chatController.removeMessageEverywhere(r.message),
              danger: true),
      ];

  BubbleMenuItem _menuItem(_MenuAction a) {
    final color = a.danger ? SiteColors.red : SiteColors.grey900;
    return BubbleMenuItem(
      label: a.label,
      icon: Icon(a.icon, size: 18, color: a.danger ? SiteColors.red : SiteColors.grey600),
      height: 40,
      textStyle: TextStyle(fontSize: 14, color: color),
      onSelected: a.onSelected,
    );
  }

  /// [BubbleMenuConfiguration.senderMenuHandler]: the same actions in a bottom sheet.
  Future<void> _showMenuSheet(BuildContext bubbleContext, BubbleMenuRequest request) async {
    final actions = _menuActions(request);
    final chosen = await showModalBottomSheet<_MenuAction>(
      context: bubbleContext,
      backgroundColor: Colors.white,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final a in actions)
            ListTile(
              leading: Icon(a.icon, color: a.danger ? SiteColors.red : SiteColors.grey600),
              title: Text(a.label,
                  style: TextStyle(color: a.danger ? SiteColors.red : SiteColors.grey900)),
              onTap: () => Navigator.pop(context, a),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (chosen != null && bubbleContext.mounted) chosen.onSelected(bubbleContext, request);
  }

  // ---------------------------------------------------------------------------
  // Layout: settings | chat (narrow screens switch); the studio opens beside the chat.

  /// The part being designed in the studio, if any.
  Part? _editing;

  void _edit(Part? part) => setState(() {
        _editing = part;
        _showPart(part);
      });

  /// Makes [part] show in the chat while it is designed.
  void _showPart(Part? part) {
    switch (part) {
      case Part.search:
        if (!_search.isOpen) _search.open();
      case Part.readOnly:
        s.readOnly = true;
      default:
    }
  }

  /// The new message notice shows when a message arrives while scrolled up: scroll up, then
  /// receive one.
  Future<void> _previewNotice() async {
    final c = _chatController;
    if (!c.hasClients) return;
    final target = (s.scrollThreshold + 400).clamp(0.0, c.position.maxScrollExtent);
    await c.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    if (mounted) await _receive();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (width >= 1360) return _desktop();
      if (width >= 1024) return _laptop();
      return _mobile();
    });
  }

  /// Studio | chat | settings.
  Widget _desktop() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1760),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: _editing == null
                  ? const SizedBox(width: 12)
                  : SizedBox(
                      width: 400,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 4, 28),
                        child: _studio(),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 12, 28),
                child: _chatCard(compact: false),
              ),
            ),
            SizedBox(width: 420, child: _settingsList(withIntro: true)),
          ]),
        ),
      );

  /// Chat | settings, with the studio in place of the settings while open.
  Widget _laptop() => Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 12, 24),
            child: _chatCard(compact: false),
          ),
        ),
        SizedBox(
          width: 420,
          child: _editing == null
              ? _settingsList(withIntro: true)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(4, 24, 24, 24),
                  child: _studio(closeIcon: Icons.arrow_back_rounded),
                ),
        ),
      ]);

  /// Preview or settings; while designing, the chat on top and the studio below.
  Widget _mobile() {
    if (_editing != null) {
      return Column(children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: _chatCard(compact: true),
          ),
        ),
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: _studio(closeIcon: Icons.arrow_back_rounded),
          ),
        ),
      ]);
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SegmentedChoice<bool>(
          value: _showSettings,
          options: {false: l.preview, true: l.settings},
          // The page background is grey100 too, so the track needs to be darker.
          trackColor: SiteColors.grey200,
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
  }

  Widget _studio({IconData closeIcon = Icons.close_rounded}) {
    final part = _editing!;
    final (title, description) = _partText(part);
    return StudioEditor(
      key: const Key('studio'),
      part: part,
      title: title,
      description: description,
      variants: part == Part.bubble
          ? [(l.bubbleColor, s.spec(Part.bubble)), (l.receiverBubbleColor, s.receiverBubble)]
          : [(title, s.spec(part))],
      code: () => studioCode(part, s.spec(part), receiver: s.receiverBubble),
      onChanged: () => setState(() {}),
      onReset: () => setState(() => s.reset(part)),
      onClose: () => _edit(null),
      closeIcon: closeIcon,
      previewLabel: part == Part.notice ? l.previewNotice : null,
      onPreview: part == Part.notice ? _previewNotice : null,
    );
  }

  (String, String) _partText(Part part) => switch (part) {
        Part.bubble => (l.partBubble, l.partBubbleDesc),
        Part.search => (l.partSearch, l.partSearchDesc),
        Part.input => (l.partInput, l.partInputDesc),
        Part.notice => (l.partNotice, l.partNoticeDesc),
        Part.separator => (l.partSeparator, l.partSeparatorDesc),
        Part.time => (l.partTime, l.partTimeDesc),
        Part.profile => (l.partProfile, l.partProfileDesc),
        Part.read => (l.partRead, l.partReadDesc),
        Part.readOnly => (l.partReadOnly, l.partReadOnlyDesc),
      };

  Widget _chatCard({required bool compact}) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: s.background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: SiteShadows.card,
        ),
        child: Column(children: [
          // Icon-only actions when the card is narrow (e.g. with the studio open).
          LayoutBuilder(
            builder: (context, c) => ColoredBox(
              color: Colors.white,
              child: _chatHeader(compact || c.maxWidth < 820),
            ),
          ),
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
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Row(children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: Color(0xFF15B886), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(l.online,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: SiteColors.grey500)),
              ),
            ]),
          ]),
        ),
        if (_loadingInitial || _loadingOlder || _loadingNewer)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: SiteColors.blue),
            ),
          ),
        ListenableBuilder(
          listenable: _search,
          builder: (context, _) => IconButton(
            tooltip: l.search,
            onPressed: () => _search.isOpen ? _search.close() : _search.open(),
            isSelected: _search.isOpen,
            visualDensity: compact ? VisualDensity.compact : null,
            icon: const Icon(Icons.search_rounded, size: 20),
            color: SiteColors.grey600,
            selectedIcon: const Icon(Icons.search_rounded, size: 20, color: SiteColors.blue),
          ),
        ),
        for (final (label, icon, onTap, primary) in actions)
          Padding(
            padding: EdgeInsets.only(left: compact ? 0 : 6),
            child: compact
                ? IconButton(
                    visualDensity: VisualDensity.compact,
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
    return Stack(children: [
      _chatView(),
      // Shown while an earlier part of the conversation is open (after a search result).
      Positioned(
        right: 16,
        bottom: s.readOnly ? 80 : 84,
        child: ListenableBuilder(
          listenable: _chatController,
          builder: (context, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _chatController.hasNewerMessages
                ? Material(
                    key: const ValueKey('jump-to-latest'),
                    color: Colors.white,
                    elevation: 3,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: _goToLatest,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.keyboard_double_arrow_down_rounded,
                              size: 18, color: SiteColors.blue),
                          const SizedBox(width: 6),
                          Text(l.jumpToLatest,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: SiteColors.grey900)),
                        ]),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ]);
  }

  Widget _chatView() {
    return Chat(
      // A new controller needs a new Chat.
      key: ObjectKey(_chatController),
      chatController: _chatController,
      readOnly: s.readOnly,
      configuration: _configuration(context),
      onScrollToTop: _onScrollToTop,
      onScrollToBottom: _onScrollToBottom,
      searchController: _search,
      onDeleteFailedMessage: s.confirmDeleteFailed ? _confirmDelete : null,
      customInputField: (context, controller) => SafeArea(
        top: false,
        child: renderStudio(
          s.spec(Part.input),
          StudioBinding(
            text: (e) => _textOf(e),
            field: _textController,
            focus: _inputFocusNode,
            onSubmitted: (_) => _send(),
            hint: l.inputHint,
            actions: {
              ButtonAction.send: _send,
              ButtonAction.attach: () {},
              ButtonAction.none: () {},
            },
            actionLabel: _actionLabel,
          ),
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

  Widget _switch(String title, bool value, ValueChanged<bool> onChanged,
          {String? api, String? description}) =>
      SwitchRow(
        title: title,
        api: api,
        description: description,
        value: value,
        onChanged: (v) => _set(() => onChanged(v)),
      );

  Widget _choice<T>(String title, T value, Map<T, String> options, ValueChanged<T> onChanged,
          {String? api}) =>
      FieldRow(
        title: title,
        api: api,
        child: SegmentedChoice<T>(
          value: value,
          options: options,
          onChanged: (v) => _set(() => onChanged(v)),
        ),
      );

  /// The looks a part can take.
  Map<Look, String> _looksOf(Part part) => {
        if (part != Part.input && part != Part.notice && part != Part.read)
          Look.library: l.lookLibrary,
        if (part == Part.notice || part == Part.read) Look.hidden: l.off,
        Look.custom: l.lookCustom,
        if (const [Part.separator, Part.time, Part.profile].contains(part))
          Look.hidden: l.hide,
      };

  /// The card of a part: its look, and an edit button that opens the studio.
  Widget _partCard(Part part, {required String api, List<Widget> extra = const []}) {
    final (title, _) = _partText(part);
    final looks = _looksOf(part);
    final editing = _editing == part;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: editing ? SiteColors.blue : SiteColors.grey100,
            width: editing ? 1.5 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: SettingLabel(title: title, api: api)),
          if (s.look(part) == Look.custom)
            TextButton.icon(
              key: ValueKey('edit-${part.name}'),
              style: TextButton.styleFrom(
                foregroundColor: editing ? Colors.white : SiteColors.blue,
                backgroundColor: editing ? SiteColors.blue : SiteColors.blueWeak,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => _edit(editing ? null : part),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: Text(l.studioEdit),
            ),
        ]),
        if (looks.length > 1) ...[
          const SizedBox(height: 10),
          SegmentedChoice<Look>(
            key: ValueKey('look-${part.name}'),
            value: s.look(part),
            options: looks,
            onChanged: (v) => setState(() {
              s.looks[part] = v;
              // Choosing custom opens the studio; leaving it closes the studio.
              if (v == Look.custom) {
                _editing = part;
                _showPart(part);
              } else if (_editing == part) {
                _editing = null;
              }
            }),
          ),
        ],
        if (s.look(part) == Look.library &&
            const [Part.search, Part.separator, Part.time, Part.profile].contains(part))
          ..._libraryText(part),
        ...extra,
      ]),
    );
  }

  /// Text colour and size of a part the toolkit draws, through its style parameter.
  List<Widget> _libraryText(Part part) {
    final api = switch (part) {
      Part.search => 'ChatSearchBar.style',
      Part.separator => 'dateSeparatorStyle',
      Part.time => 'timeStyle',
      _ => 'profileNameStyle',
    };
    final size = s.textSizes[part];
    return [
      const SizedBox(height: 4),
      ColorField(
        key: ValueKey('text-color-${part.name}'),
        title: l.designTextColor,
        color: s.textColors[part] ?? SiteColors.grey900,
        onChanged: (c) => _set(() => s.textColors[part] = c),
      ),
      SliderRow(
        key: ValueKey('text-size-${part.name}'),
        title: l.fontSize,
        api: api,
        valueLabel: size == null ? l.lookLibrary : '${size.round()}px',
        value: size ?? 14,
        min: 9,
        max: 24,
        divisions: 15,
        onChanged: (v) => _set(() => s.textSizes[part] = v.roundToDouble()),
      ),
    ];
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
        SettingsGroup(
          title: l.sectionParts,
          description: l.sectionPartsDesc,
          children: [
            const SizedBox(height: 8),
            _partCard(Part.bubble, api: 'senderBubbleBuilder'),
            _partCard(Part.search, api: 'searchBarBuilder', extra: [
              _switch(l.searchShortcutsTitle, s.searchShortcuts, (v) => s.searchShortcuts = v,
                  api: 'searchShortcuts', description: l.searchShortcutsDesc),
            ]),
            _partCard(Part.input, api: 'customInputField'),
            _partCard(Part.notice, api: 'newReceiveMessageNotificationBuilder', extra: [
              if (_custom(Part.notice))
                SliderRow(
                  title: l.scrollThresholdTitle,
                  api: 'newMessageScrollThreshold',
                  valueLabel: '${s.scrollThreshold.round()}px',
                  value: s.scrollThreshold,
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  onChanged: (v) => _set(() => s.scrollThreshold = v.roundToDouble()),
                ),
            ]),
            _partCard(Part.separator, api: 'dateSeparatorBuilder'),
            _partCard(Part.time, api: 'timeBuilder'),
            _partCard(Part.profile, api: 'receiverProfileBuilder', extra: [
              _switch(l.myProfileTitle, s.myProfile, (v) => s.myProfile = v,
                  api: 'senderProfileBuilder', description: l.myProfileDesc),
            ]),
            _partCard(Part.read, api: 'readIndicatorBuilder'),
            _partCard(Part.readOnly, api: 'readOnlyWidget', extra: [
              _switch(l.readOnlyTitle, s.readOnly, (v) => s.readOnly = v,
                  api: 'readOnly', description: l.readOnlyDesc),
            ]),
          ],
        ),
        SettingsGroup(title: l.sectionLayout, children: [
          _switch(l.startAtTopTitle, s.messagesStartAtTop, (v) => s.messagesStartAtTop = v,
              api: 'messagesStartAtTop', description: l.startAtTopDesc),
          _choice(l.senderSideTitle, s.senderAlignment,
              {ChatAlignment.end: l.sideRight, ChatAlignment.start: l.sideLeft},
              (v) => s.senderAlignment = v,
              api: 'senderAlignment'),
          SwitchRow(
            title: l.groupingTitle,
            api: 'additionalGroupCondition',
            description: l.groupingDesc,
            value: s.grouping,
            onChanged: (v) => _set(() => s.grouping = v, reload: true),
          ),
          SliderRow(
            title: l.maxWidth,
            api: 'maxWidth',
            valueLabel: s.unlimited ? l.noLimit : '${s.maxWidth.round()}px',
            value: s.maxWidth,
            min: 200,
            max: unlimitedWidth,
            onChanged: (v) => _set(() => s.maxWidth = v.roundToDouble()),
          ),
          SliderRow(
            title: l.sidePadding,
            api: 'padding',
            valueLabel: '${s.horizontalPadding.round()}px',
            value: s.horizontalPadding,
            min: 0,
            max: 64,
            onChanged: (v) => _set(() => s.horizontalPadding = v.roundToDouble()),
          ),
          SliderRow(
            title: l.verticalPadding,
            api: 'padding',
            valueLabel: '${s.verticalPadding.round()}px',
            value: s.verticalPadding,
            min: 0,
            max: 48,
            onChanged: (v) => _set(() => s.verticalPadding = v.roundToDouble()),
          ),
          FieldRow(
            title: l.backgroundTitle,
            child: ColorChoice(
              colors: chatBackgrounds,
              selected: s.background,
              onSelected: (c) => _set(() => s.background = c),
            ),
          ),
          _choice(l.appearAnimation, s.appearMs,
              {0: l.off, 150: '150ms', 250: '250ms', 500: '500ms'}, (v) => s.appearMs = v,
              api: 'messageAppearAnimationDuration'),
        ]),
        SettingsGroup(title: l.partMenu, description: l.partMenuDesc, children: [
          _choice(l.kind, s.menu, {
            MenuKind.popup: l.menuPopup,
            MenuKind.sheet: l.menuSheet,
            MenuKind.off: l.off,
          }, (v) => s.menu = v, api: 'menuConfiguration'),
          if (s.menu != MenuKind.off) ...[
            _switch(l.longPressTitle, s.longPress, (v) => s.longPress = v,
                api: 'enableLongPress', description: l.longPressDesc),
            _switch(l.hapticTitle, s.haptic, (v) => s.haptic = v, api: 'enableHapticFeedback'),
          ],
        ]),
        SettingsGroup(title: l.sectionBehavior, children: [
          _switch(l.sendingIndicatorTitle, s.customSendingIndicator,
              (v) => s.customSendingIndicator = v,
              api: 'loadingWidget', description: l.sendingIndicatorDesc),
          _switch(l.confirmDeleteTitle, s.confirmDeleteFailed, (v) => s.confirmDeleteFailed = v,
              api: 'onDeleteFailedMessage', description: l.confirmDeleteDesc),
        ]),
        SettingsGroup(title: l.sectionServer, children: [
          FieldRow(
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
          SliderRow(
            title: l.responseTime,
            valueLabel: l.seconds((s.latencyMs / 1000).toStringAsFixed(1)),
            value: s.latencyMs.toDouble(),
            min: 0,
            max: 3000,
            onChanged: (v) => setState(() => s.latencyMs = (v / 100).round() * 100),
            onChangeEnd: (_) => _reloadRoom(),
          ),
          SwitchRow(
            title: l.imagesTitle,
            description: l.imagesDesc,
            value: s.images,
            onChanged: (v) => _set(() => s.images = v, reload: true),
          ),
          _choice(l.sendResult, s.sendResult, {
            PlaygroundSendResult.success: l.resultSuccess,
            PlaygroundSendResult.fail: l.resultFail,
            PlaygroundSendResult.block: l.resultBlock,
          }, (v) => s.sendResult = v),
          _switch(l.autoReplyTitle, s.autoReply, (v) => s.autoReply = v,
              description: l.autoReplyDesc),
        ]),
      ],
    );
  }
}

class _MenuAction {
  const _MenuAction(this.label, this.icon, this.onSelected, {this.danger = false});

  final String label;
  final IconData icon;
  final BubbleMenuItemCallback onSelected;
  final bool danger;
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

/// The search bar designed in the studio, wired to the [ChatSearchController]
/// ([ChatConfiguration.searchBarBuilder]).
class _StudioSearchBar extends StatefulWidget {
  const _StudioSearchBar({
    required this.search,
    required this.spec,
    required this.textOf,
    required this.actionLabel,
    required this.hint,
  });

  final ChatSearchController search;
  final StudioSpec spec;
  final String Function(StudioElement, {ChatSearchController? search}) textOf;
  final String Function(ButtonAction) actionLabel;
  final String hint;

  @override
  State<_StudioSearchBar> createState() => _StudioSearchBarState();
}

class _StudioSearchBarState extends State<_StudioSearchBar> {
  late final _text = TextEditingController(text: widget.search.query);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Take the focus when the search is opened, e.g. with Ctrl/⌘ + F.
    widget.search.focusRequests.addListener(_focus.requestFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    widget.search.focusRequests.removeListener(_focus.requestFocus);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = widget.search;
    return ListenableBuilder(
      listenable: search,
      builder: (context, _) => renderStudio(
        widget.spec,
        StudioBinding(
          text: (e) => widget.textOf(e, search: search),
          field: _text,
          focus: _focus,
          hint: widget.hint,
          onSubmitted: (value) {
            search.search(value);
            _focus.requestFocus();
          },
          actions: {
            ButtonAction.older: search.hasOlder ? search.showOlder : null,
            ButtonAction.newer: search.hasNewer ? search.showNewer : null,
            ButtonAction.close: search.close,
          },
          actionLabel: widget.actionLabel,
        ),
      ),
    );
  }
}
