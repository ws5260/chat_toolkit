import 'dart:async';
import 'dart:ui';

import 'chat_configuration.dart';
import 'chat_controller.dart';
import 'message/entity/message.dart';
import 'message/entity/message_group.dart';
import 'message/message_bubble.dart';
import 'size_detected_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gap/gap.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// A chat view that shows the messages of a [ChatController].
///
/// Consecutive messages from the same author within the same minute are
/// grouped under one profile, and a date separator is inserted when the day
/// changes. An input field supplied by [customInputField] is placed below
/// the list.
///
/// ```dart
/// Chat(
///   chatController: controller,
///   configuration: const ChatConfiguration(senderAlignment: ChatAlignment.end),
///   onScrollToTop: () => loadOlderMessages(),
///   customInputField: (context, controller) => MyInputField(controller),
/// )
/// ```
class Chat extends StatefulWidget {
  /// Creates a chat view.
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
  /// widget. When provided, you are responsible for disposing it.
  final ChatController? chatController;

  /// Appearance and behavior options.
  final ChatConfiguration configuration;

  /// Builds the input field shown below the message list.
  ///
  /// Receives the [ChatController] so the field can send messages with
  /// [ChatController.dispatchMessage]. When `null`, nothing is shown.
  final Widget Function(BuildContext, ChatController)? customInputField;

  /// Called when the user reaches the oldest end of the list, typically to
  /// load older messages.
  ///
  /// Also called when the messages do not fill the screen yet, repeatedly
  /// after each update until they do. Calls are debounced while the returned
  /// future is pending.
  final Future<void> Function()? onScrollToTop;

  /// Called when the delete button on a failed message is tapped.
  ///
  /// The chat knows nothing about your backend, so delete the message there
  /// and return `true` to also remove it from the list, or `false` to keep
  /// it. When `null`, the message is removed from the list immediately.
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

  // Non-reversed list only: whether the list has left offset 0 since messages were loaded.
  // Right after setMessages it is still at 0 (the oldest end) until the app scrolls it to the bottom,
  // and that first frame must not count as "the user reached the top" (see _onScroll).
  bool _leftOlderEndSinceLoad = false;

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
      if (chatController.messageGroups.isEmpty) {
        _leftOlderEndSinceLoad = false; // cleared, e.g. before reloading a room
      } else if (position.pixels > 20) {
        _leftOlderEndSinceLoad = true;
      }
      // If messages don't fill the screen, maxScrollExtent is 0 and the list can't scroll,
      // so scrolling can never trigger loading older messages.
      // In that case treat the list as being at the oldest end and call onScrollToTop. Once the loaded
      // messages are added this runs again, repeating until the screen is filled.
      // The oldest end differs by mode: maxScrollExtent for a reversed list, 0 for a normal one.
      // A normal list also starts at 0, so 0 only counts once the list has been elsewhere;
      // otherwise opening a room would load an older page above it and push the view off the bottom.
      final atOlderEnd =
          position.maxScrollExtent <= 0 ||
          (chatController.reverse
              ? position.pixels >= position.maxScrollExtent - 20
              : _leftOlderEndSinceLoad && position.pixels <= 20);
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
          _StartAtTop(
            enabled: chatController.reverse && widget.configuration.messagesStartAtTop,
            // The gap after the messages (above them in a reversed list) stays visible.
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
    final reverse = chatController.reverse;
    int groupIndexAt(int index) => reverse ? groups.length - 1 - index : index;

    bool showDateDividerAt(int groupIndex) =>
        groupIndex == 0 ||
        chatController.isDateChangedComparedTo(
          groups[groupIndex - 1].messages.first,
          groups[groupIndex].messages.first,
        );

    // In a reversed list, adding a new message shifts every group's index by one.
    // If findChildIndexCallback finds the new index via ObjectKey(group), the existing Element
    // is moved to that slot; otherwise every visible group is rebuilt from scratch.
    // It is called only for the children currently built (the visible ones, usually near the newest
    // end), so a search from the end is cheaper than indexing every group on each rebuild.
    int? indexOfGroup(MessageGroup group) {
      final groupIndex = groups.lastIndexWhere((g) => identical(g, group));
      if (groupIndex < 0) return null;
      return reverse ? groups.length - 1 - groupIndex : groupIndex;
    }

    return _KeepPositionOnPrepend(
      controller: chatController,
      sliver: SliverPadding(
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
      shouldFollowBottom: _shouldFollowBottomDuringAppear,
      followBottom: _followBottomDuringAppear,
      child: _buildGroupContent(context, group, isPrevProfile, showDateDivider, takeAppear),
    );
  }

  // In reverse mode the bottom is offset 0, so a growing item pushes older content up by itself.
  // Otherwise the bottom moves while it grows; follow it if the user was at the bottom.
  bool _shouldFollowBottomDuringAppear() => !chatController.reverse && chatController.isAtBottom();

  // Called on every animation tick. Jumping now uses the previous frame's extent, so also jump
  // after this frame's layout, which includes the height grown in this tick.
  void _followBottomDuringAppear() {
    chatController.scrollToBottom();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) chatController.scrollToBottom();
    });
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
                      shouldFollowBottom: _shouldFollowBottomDuringAppear,
                      followBottom: _followBottomDuringAppear,
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
class _MessageAppear extends StatefulWidget {
  const _MessageAppear({
    super.key,
    required this.animate,
    required this.duration,
    required this.shouldFollowBottom,
    required this.followBottom,
    required this.child,
  });

  final bool animate;
  final Duration? duration;

  /// Checked when the animation starts: whether to keep the list at the bottom while it grows.
  final bool Function() shouldFollowBottom;
  final VoidCallback followBottom;
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
    if (widget.shouldFollowBottom()) {
      controller.addListener(widget.followBottom);
    }
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

/// Keeps the visible messages in place when [ChatController.appendMessages] adds older messages
/// to a normal (not reversed) list.
///
/// There the older end is offset 0, so the added messages push the content down while the offset
/// stays the same: the view jumps to the new messages, and since it is still at the older end the
/// next page loads right away, and so on. After such a layout this reports a scroll offset
/// correction of the added height, so the viewport lays out again at the shifted offset before
/// anything is painted (no one-frame flash, unlike a jumpTo afterwards).
class _KeepPositionOnPrepend extends SingleChildRenderObjectWidget {
  const _KeepPositionOnPrepend({required this.controller, required Widget sliver})
    : super(child: sliver);

  final ChatController controller;

  @override
  _RenderKeepPositionOnPrepend createRenderObject(BuildContext context) =>
      _RenderKeepPositionOnPrepend(controller);

  @override
  void updateRenderObject(BuildContext context, _RenderKeepPositionOnPrepend renderObject) {
    renderObject.controller = controller;
  }
}

class _RenderKeepPositionOnPrepend extends RenderProxySliver {
  _RenderKeepPositionOnPrepend(this.controller);

  ChatController controller;

  // From the last settled layout: a group near the top of the viewport (see _recordAnchor) and the
  // distance of its top from the top of the viewport.
  int? _anchorIndex;
  double _anchorOffset = 0;
  double? _lastScrollExtent;

  // While keeping the position after a prepend: groups added in front, and correction passes so far.
  int? _pendingGroupsAdded;
  double? _extentBeforePrepend;
  int _passes = 0;

  static const int _maxPasses = 8;

  @override
  void performLayout() {
    super.performLayout(); // lays out the list and copies its geometry
    final geometry = this.geometry!;
    // The list asked for its own correction; it lays out again and this runs again.
    if (geometry.scrollOffsetCorrection != null || controller.reverse) return;
    final list = _findList();
    if (list == null) return;

    final added = controller.takeGroupsPrepended();
    if (added != null) {
      _pendingGroupsAdded = (_pendingGroupsAdded ?? 0) + added;
      _extentBeforePrepend ??= _lastScrollExtent;
      _passes = 0;
    }

    final pending = _pendingGroupsAdded;
    final anchorIndex = _anchorIndex;
    if (pending != null && anchorIndex != null) {
      double? correction;
      final target = anchorIndex + pending;
      final scrollOffset = _viewportTop(list);
      final anchor = _childWithIndex(list, target);
      final first = list.firstChild;
      final last = list.lastChild;
      if (anchor != null) {
        // Put the anchor group back at the distance from the top it had before.
        correction = list.childScrollOffset(anchor)! - _anchorOffset - scrollOffset;
      } else if (_passes == 0 && _extentBeforePrepend != null) {
        // The anchor is not laid out at this offset yet: move by the added height first, then
        // refine on the next passes once it is laid out.
        correction = geometry.scrollExtent - _extentBeforePrepend!;
      } else if (first != null && list.indexOf(first) > target) {
        // Overshot (heights above the viewport are estimates): step up to just above the first
        // laid-out group so the one before it gets laid out.
        correction = list.childScrollOffset(first)! - 1 - scrollOffset;
      } else if (last != null && list.indexOf(last) < target) {
        // Undershot: step down to the last laid-out group.
        correction = list.childScrollOffset(last)! + 1 - scrollOffset;
      }
      _passes++;
      if (correction != null && correction.abs() > 0.5 && _passes <= _maxPasses) {
        this.geometry = SliverGeometry(scrollOffsetCorrection: correction);
        return;
      }
      _pendingGroupsAdded = null;
      _extentBeforePrepend = null;
    }

    _lastScrollExtent = geometry.scrollExtent;
    _recordAnchor(list);
  }

  // Position of the top of the viewport in the list's own coordinates. Negative while space before
  // the list (e.g. the leading gap) is still visible: the list's scrollOffset is then 0 and the list
  // starts below the top of the viewport.
  double _viewportTop(RenderSliverMultiBoxAdaptor list) {
    final c = list.constraints;
    return c.scrollOffset - (c.viewportMainAxisExtent - c.remainingPaintExtent);
  }

  // The list itself, below wrappers such as SliverPadding.
  RenderSliverMultiBoxAdaptor? _findList() {
    RenderObject? object = child;
    while (object != null) {
      if (object is RenderSliverMultiBoxAdaptor) return object;
      object = object is RenderObjectWithChildMixin<RenderObject> ? object.child : null;
    }
    return null;
  }

  RenderBox? _childWithIndex(RenderSliverMultiBoxAdaptor list, int index) {
    for (var c = list.firstChild; c != null; c = list.childAfter(c)) {
      if (list.indexOf(c) == index) return c;
    }
    return null;
  }

  void _recordAnchor(RenderSliverMultiBoxAdaptor list) {
    // The first group starting below the top of the viewport (or the last laid-out one). Anchoring
    // a group that starts below the top also absorbs height changes above it, e.g. the date
    // separator of the formerly first group disappearing when older messages of the same day
    // are added before it.
    final scrollOffset = _viewportTop(list);
    RenderBox? anchor;
    for (var c = list.firstChild; c != null; c = list.childAfter(c)) {
      final offset = list.childScrollOffset(c);
      if (offset == null) continue;
      anchor = c;
      if (offset > scrollOffset) break;
    }
    if (anchor == null) {
      _anchorIndex = null;
      return;
    }
    // The first group can itself change when older messages are added (its date separator), so
    // anchor the one after it when there is one.
    if (list.indexOf(anchor) == 0) anchor = list.childAfter(anchor) ?? anchor;
    _anchorIndex = list.indexOf(anchor);
    _anchorOffset = list.childScrollOffset(anchor)! - scrollOffset;
  }
}

/// Shows a short reversed list from the top (see [ChatConfiguration.messagesStartAtTop]).
///
/// While the list does not fill the viewport, its unused space becomes padding on the side of
/// scroll offset 0 (below the messages in a reversed list), so the messages move to the top.
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
