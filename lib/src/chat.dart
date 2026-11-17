import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gap/gap.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'chat_configuration.dart';
import 'chat_controller.dart';
import 'message/entity/message.dart';
import 'message/entity/message_group.dart';
import 'message/message_bubble.dart';
import 'size_detected_widget.dart';

/// A chat view that shows the messages of a [ChatController].
///
/// Consecutive messages from the same author within the same minute are
/// grouped under one profile (see [MessageGroup]), and a date separator is
/// inserted when the day changes. The list is laid out from the newest
/// message at the bottom, scrolls lazily, and rebuilds whenever the
/// controller's messages change. An input field supplied by
/// [customInputField] (or [ChatConfiguration.readOnlyWidget] when
/// [readOnly]) is placed below the list.
///
/// [Chat] takes its height from its parent, so place it in a bounded box
/// such as the body of a [Scaffold] or an [Expanded]. It handles the
/// built-in interactions itself: the retry and delete buttons of failed
/// messages (see [ChatController.retryMessage] and [onDeleteFailedMessage]),
/// loading older messages ([onScrollToTop]), the bubble context menu
/// ([BubbleConfiguration.menuConfiguration]) and the "new message"
/// notification ([ChatConfiguration.newReceiveMessageNotificationBuilder]).
///
/// ```dart
/// class RoomScreen extends StatefulWidget {
///   const RoomScreen({super.key});
///
///   @override
///   State<RoomScreen> createState() => _RoomScreenState();
/// }
///
/// class _RoomScreenState extends State<RoomScreen> {
///   final controller = ChatController();
///
///   @override
///   void initState() {
///     super.initState();
///     api.fetchLatest().then(controller.setMessages);
///   }
///
///   @override
///   void dispose() {
///     controller.dispose(); // Chat does not dispose a controller you pass in.
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Chat(
///         chatController: controller,
///         configuration: const ChatConfiguration(senderAlignment: ChatAlignment.end),
///         onScrollToTop: () async {
///           controller.appendMessages(await api.fetchOlder());
///         },
///         customInputField: (context, controller) => MyInputField(
///           onSend: (text) => controller.dispatchMessage(
///             SenderMessage(
///               name: 'Me',
///               timestamp: DateTime.now().toIso8601String(),
///               elements: [TextElement(text)],
///             ),
///             onDispatch: api.send,
///           ),
///         ),
///       ),
///     );
///   }
/// }
/// ```
class Chat extends StatefulWidget {
  /// Creates a chat view.
  ///
  /// All arguments are optional; without a [chatController] the chat manages
  /// an internal controller that you cannot reach, so pass one to show
  /// messages.
  const Chat({
    super.key,
    this.readOnly = false,
    this.chatController,
    this.configuration = const ChatConfiguration(),
    this.onScrollToTop,
    this.customInputField,
    this.onDeleteFailedMessage,
  });

  /// Whether the chat is read-only.
  ///
  /// When `true`, [ChatConfiguration.readOnlyWidget] is shown instead of
  /// [customInputField]. Defaults to `false`.
  final bool readOnly;

  /// Controller that holds the messages and the scroll position.
  ///
  /// When `null`, an internal controller is created and disposed with this
  /// widget. When provided, you are responsible for disposing it, after this
  /// widget is removed from the tree.
  ///
  /// The controller is read once, when the chat is first built; passing a
  /// different controller to an existing [Chat] has no effect. Give the
  /// [Chat] a new [Key] (e.g. `ValueKey(roomId)`) to switch controllers.
  final ChatController? chatController;

  /// Appearance and behavior options.
  ///
  /// See [ChatConfiguration] and [ChatConfiguration.bubbleConfiguration].
  final ChatConfiguration configuration;

  /// Builds the input field shown below the message list.
  ///
  /// Receives the [ChatController] so the field can send messages with
  /// [ChatController.dispatchMessage]. When `null`, nothing is shown. Not
  /// called while [readOnly] is `true`.
  final Widget Function(BuildContext, ChatController)? customInputField;

  /// Called when the user reaches the oldest end of the list, typically to
  /// load older messages.
  ///
  /// Add the loaded messages with [ChatController.appendMessages]. Called
  /// after a frame when the list is scrolled within 20 logical pixels of the
  /// oldest message. Also called when the messages do not fill the screen
  /// yet, again after each update until they do, so with an empty or short
  /// history it is called right after the first build.
  ///
  /// Further calls are suppressed for about 100 ms after each call, or until
  /// the returned future completes if that is sooner, so the callback may be
  /// called again while a slow request is still pending. Guard against
  /// overlapping requests, and stop loading when the history is exhausted:
  ///
  /// ```dart
  /// var loading = false;
  /// var hasMore = true;
  ///
  /// Chat(
  ///   chatController: controller,
  ///   onScrollToTop: () async {
  ///     if (loading || !hasMore) return;
  ///     loading = true;
  ///     try {
  ///       final older = await api.fetchOlder(); // newest first
  ///       hasMore = older.isNotEmpty;
  ///       controller.appendMessages(older);
  ///     } finally {
  ///       loading = false;
  ///     }
  ///   },
  /// )
  /// ```
  final Future<void> Function()? onScrollToTop;

  /// Called when the delete button on a failed message is tapped.
  ///
  /// The chat knows nothing about your backend, so delete the message there
  /// and return `true` to also remove it from the list, or `false` to keep
  /// it. When `null`, the message is removed from the list immediately. A
  /// removed message can no longer be retried with
  /// [ChatController.retryMessage].
  ///
  /// ```dart
  /// Chat(
  ///   chatController: controller,
  ///   onDeleteFailedMessage: (message) async {
  ///     await localDb.deleteUnsent(message.id);
  ///     return true;
  ///   },
  /// )
  /// ```
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
      // The list is reversed, so the oldest end is maxScrollExtent.
      final atOlderEnd =
          position.maxScrollExtent <= 0 || position.pixels >= position.maxScrollExtent - 20;
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
        // Newest message at offset 0: the chat opens at the bottom, and older messages added at
        // the far end do not move what is on screen.
        reverse: true,
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
          _StartAtTop(
            enabled: widget.configuration.messagesStartAtTop,
            // The gap after the messages (above them in the reversed list) stays visible.
            trailingExtent: 30,
            sliver: ListenableBuilder(
              listenable: chatController.messagesRevision,
              builder: _buildMessageSliverList,
            ),
          ),
          const SliverGap(30),
        ],
      ),
    );
  }

  // Called only when the message list changes. It only snapshots the group list, so its cost does
  // not grow with per-group work. Widgets are built lazily by SliverChildBuilderDelegate, which calls
  // _buildGroupItem only for the indices that enter the viewport; the date separator is computed
  // there, for those indices only.
  Widget _buildMessageSliverList(BuildContext context, Widget? child) {
    final groups = List<MessageGroup>.of(chatController.messageGroups);
    // The list is reversed: index 0 is the newest group.
    int groupIndexAt(int index) => groups.length - 1 - index;

    bool showDateDividerAt(int groupIndex) =>
        groupIndex == 0 ||
        chatController.isDateChangedComparedTo(
          groups[groupIndex - 1].messages.first,
          groups[groupIndex].messages.first,
        );

    // Adding a new message shifts every group's index by one.
    // If findChildIndexCallback finds the new index via ObjectKey(group), the existing Element
    // is moved to that slot; otherwise every visible group is rebuilt from scratch.
    // It is called only for the children currently built (the visible ones, usually near the newest
    // end), so a search from the end is cheaper than indexing every group on each rebuild.
    int? indexOfGroup(MessageGroup group) {
      final groupIndex = groups.lastIndexWhere((g) => identical(g, group));
      if (groupIndex < 0) return null;
      return groups.length - 1 - groupIndex;
    }

    return SliverPadding(
      padding: widget.configuration.padding,
      sliver: SuperSliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final groupIndex = groupIndexAt(index);
            return _buildGroupItem(
              context,
              groups[groupIndex],
              showDateDivider: showDateDividerAt(groupIndex),
            );
          },
          childCount: groups.length,
          findChildIndexCallback: (key) {
            final value = key is ObjectKey ? key.value : null;
            return value is MessageGroup ? indexOfGroup(value) : null;
          },
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

    // Entrance animation for just-added messages. A new group animates as a whole (profile
    // included); a message joining an existing group animates only its own bubble. The result
    // only matters when the item is first built, which is when the pending id is taken.
    final appearDuration = widget.configuration.messageAppearAnimationDuration;
    bool takeAppear(Message message) =>
        appearDuration != null && chatController.takeAppearAnimation(message.id);

    return _MessageAppear(
      key: ObjectKey(group),
      animate: takeAppear(group.messages.first),
      duration: appearDuration,
      child: _buildGroupContent(context, group, isPrevProfile, showDateDivider, takeAppear),
    );
  }

  Widget _buildGroupContent(
    BuildContext context,
    MessageGroup group,
    bool isPrevProfile,
    bool showDateDivider,
    bool Function(Message) takeAppear,
  ) {
    final appearDuration = widget.configuration.messageAppearAnimationDuration;
    return Column(
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
                  for (int i = 0; i < group.messages.length; i++)
                    _MessageAppear(
                      key: group.messages[i].id.isEmpty ? null : ValueKey(group.messages[i].id),
                      // The first message animates with its group.
                      animate: i > 0 && takeAppear(group.messages[i]),
                      duration: appearDuration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The gap above a bubble belongs to it, so it animates in with it.
                          if (i > 0) const Gap(8),
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
                        ],
                      ),
                    ),
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

/// Plays the entrance animation of a just-added message or group: it grows from zero height (so
/// the list moves smoothly instead of jumping), slides up and fades in.
///
/// Whether to animate is decided once, when the item is first built; later rebuilds keep it.
/// The bottom of the reversed list is offset 0, so a growing item pushes older content up and the
/// list stays at the bottom by itself.
class _MessageAppear extends StatefulWidget {
  const _MessageAppear({
    super.key,
    required this.animate,
    required this.duration,
    required this.child,
  });

  final bool animate;
  final Duration? duration;
  final Widget child;

  @override
  State<_MessageAppear> createState() => _MessageAppearState();
}

class _MessageAppearState extends State<_MessageAppear> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _curve;

  @override
  void initState() {
    super.initState();
    final duration = widget.duration;
    if (!widget.animate || duration == null || duration <= Duration.zero) return;

    final controller = AnimationController(vsync: this, duration: duration);
    _controller = controller;
    _curve = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = _curve;
    if (curve == null) return widget.child;
    // Same as SizeTransition, written out so it works on all supported Flutter versions
    // (SizeTransition's alignment parameter only exists on newer ones).
    final content = FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: curve.drive(Tween(begin: const Offset(0, 0.3), end: Offset.zero)),
        child: widget.child,
      ),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: curve.value.clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: content,
    );
  }
}

/// Shows a short list from the top (see [ChatConfiguration.messagesStartAtTop]).
///
/// While the list does not fill the viewport, its unused space becomes padding on the side of
/// scroll offset 0 (below the messages, since the list is reversed), so the messages move to the top.
/// Once the list fills the viewport the padding is 0 and nothing changes.
class _StartAtTop extends SingleChildRenderObjectWidget {
  const _StartAtTop({required this.enabled, required this.trailingExtent, required Widget sliver})
    : super(child: sliver);

  final bool enabled;

  /// Extent of the slivers after this one, which should stay visible.
  final double trailingExtent;

  @override
  _RenderStartAtTop createRenderObject(BuildContext context) =>
      _RenderStartAtTop(enabled: enabled, trailingExtent: trailingExtent);

  @override
  void updateRenderObject(BuildContext context, _RenderStartAtTop renderObject) {
    renderObject
      ..enabled = enabled
      ..trailingExtent = trailingExtent;
  }
}

class _RenderStartAtTop extends RenderSliverEdgeInsetsPadding {
  _RenderStartAtTop({required this._enabled, required this._trailingExtent});

  bool get enabled => _enabled;
  bool _enabled;
  set enabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    markNeedsLayout();
  }

  double get trailingExtent => _trailingExtent;
  double _trailingExtent;
  set trailingExtent(double value) {
    if (value == _trailingExtent) return;
    _trailingExtent = value;
    markNeedsLayout();
  }

  EdgeInsets _padding = EdgeInsets.zero;

  @override
  EdgeInsets? get resolvedPadding => _padding;

  @override
  void performLayout() {
    _padding = EdgeInsets.zero;
    final child = this.child;
    // Only possible at offset 0: a list that does not fill the viewport cannot scroll.
    if (_enabled && child != null && constraints.scrollOffset == 0) {
      // Measure the list. When no padding is needed, the layout below passes the same
      // constraints, so the list is not laid out a second time.
      child.layout(constraints, parentUsesSize: true);
      final geometry = child.geometry!;
      if (geometry.scrollOffsetCorrection == null) {
        final unused = constraints.remainingPaintExtent - _trailingExtent - geometry.scrollExtent;
        if (unused > 0) _padding = _paddingBeforeList(unused);
      }
    }
    super.performLayout();
  }

  // Padding on the side of scroll offset 0.
  EdgeInsets _paddingBeforeList(double extent) {
    return switch (applyGrowthDirectionToAxisDirection(
      constraints.axisDirection,
      constraints.growthDirection,
    )) {
      AxisDirection.up => EdgeInsets.only(bottom: extent),
      AxisDirection.down => EdgeInsets.only(top: extent),
      AxisDirection.left => EdgeInsets.only(right: extent),
      AxisDirection.right => EdgeInsets.only(left: extent),
    };
  }
}
