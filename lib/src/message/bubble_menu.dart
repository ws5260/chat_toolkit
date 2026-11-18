import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:material_ui/material_ui.dart';

import 'entity/message.dart';

/// Information about the bubble a context menu was requested for.
///
/// Passed to every menu callback ([BubbleMenuItemsBuilder],
/// [BubbleMenuHandler] and [BubbleMenuItemCallback]) so a single builder can
/// serve many bubbles. Created by the toolkit when a bubble is long-pressed.
class BubbleMenuRequest {
  /// Creates a [BubbleMenuRequest].
  const BubbleMenuRequest({
    required this.message,
    required this.isSender,
    required this.globalPosition,
    required this.bubbleRect,
  });

  /// The message the menu was opened for, as it was when the menu opened.
  ///
  /// It may be loading or failed (see [Message.isLoading] and
  /// [Message.isFailed]); check those to offer different entries. Pass it to
  /// [ChatController.retryMessage] or [ChatController.removeMessageEverywhere]
  /// to act on it.
  final Message message;

  /// `true` for a sender bubble, `false` for a receiver bubble.
  final bool isSender;

  /// Global position of the pointer that opened the menu (the finger, or the
  /// mouse cursor for a held mouse button).
  final Offset globalPosition;

  /// Global bounds of the bubble, useful for anchoring a custom menu to it.
  final Rect bubbleRect;
}

/// Builds the entries of the default context menu for one bubble.
///
/// Called each time the menu is opened, so the entries can depend on
/// [BubbleMenuRequest.message]. Return an empty list to suppress the menu
/// for that message (e.g. while it is still sending).
typedef BubbleMenuItemsBuilder =
    List<BubbleMenuItem> Function(
      BuildContext context,
      BubbleMenuRequest request,
    );

/// Presents a completely custom menu (bottom sheet, dialog, overlay, ...).
///
/// When provided it replaces the default popup menu for that side; the items
/// builder of that side is then not used. [BuildContext] is the bubble's
/// context, and [BubbleMenuRequest.bubbleRect] and
/// [BubbleMenuRequest.globalPosition] can anchor your UI to the bubble.
///
/// ```dart
/// BubbleMenuConfiguration(
///   receiverMenuHandler: (context, request) async {
///     await showModalBottomSheet<void>(
///       context: context,
///       builder: (context) => MyMenuSheet(message: request.message),
///     );
///   },
/// )
/// ```
typedef BubbleMenuHandler =
    Future<void> Function(BuildContext context, BubbleMenuRequest request);

/// Called when a [BubbleMenuItem] is chosen.
///
/// Receives the bubble's [BuildContext] (not the closed menu's) and the
/// request the menu was opened with.
typedef BubbleMenuItemCallback =
    void Function(BuildContext context, BubbleMenuRequest request);

/// A single entry of the default bubble context menu.
///
/// Provide either a [label] (optionally with an [icon]) or a fully custom
/// [child]; providing neither fails an assertion. Returned by a
/// [BubbleMenuItemsBuilder] and shown as a Material popup menu entry.
///
/// ```dart
/// BubbleMenuItem(
///   label: 'Copy',
///   icon: const Icon(Icons.copy, size: 18),
///   onSelected: (context, request) => copyToClipboard(request.message),
/// )
/// ```
class BubbleMenuItem {
  /// Creates a menu entry.
  const BubbleMenuItem({
    this.label,
    this.icon,
    this.child,
    this.onSelected,
    this.enabled = true,
    this.textStyle,
    this.height = kMinInteractiveDimension,
    this.padding,
  }) : assert(
         label != null || child != null,
         'BubbleMenuItem needs either a label or a child.',
       );

  /// Text of the entry. Ignored when [child] is set.
  final String? label;

  /// Optional leading widget shown before [label].
  final Widget? icon;

  /// Fully custom content. Takes precedence over [label] and [icon].
  final Widget? child;

  /// Called after the menu closes and this entry was chosen.
  ///
  /// Not called if the bubble was removed from the tree in the meantime.
  final BubbleMenuItemCallback? onSelected;

  /// Whether the entry can be chosen. A disabled entry is shown greyed out.
  ///
  /// Defaults to `true`.
  final bool enabled;

  /// Text style applied to [label].
  final TextStyle? textStyle;

  /// Minimum height of the entry. Defaults to [kMinInteractiveDimension].
  final double height;

  /// Padding of the entry. When `null`, the Material default is used.
  final EdgeInsets? padding;

  /// Builds the widget shown inside the popup menu entry.
  ///
  /// Returns [child] when set, otherwise [label] with [icon] before it.
  /// Called by the toolkit; apps rarely need to call it.
  Widget buildContent(BuildContext context) {
    if (child != null) return child!;

    final text = Text(label!, style: textStyle);
    if (icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon!,
        const Gap(12),
        Flexible(child: text),
      ],
    );
  }
}

/// Context-menu settings for message bubbles.
///
/// Sender and receiver menus are configured separately, so each side can offer
/// different entries (e.g. "Delete" only on your own messages).
///
/// The menu opens on a long press — a held touch, or a held mouse button on
/// desktop and web. Right click is deliberately not a trigger: on the web it
/// would open the browser's own context menu at the same time.
///
/// A side without an items builder and without a handler has no menu. For
/// each side, a handler ([senderMenuHandler], [receiverMenuHandler]) takes
/// precedence over an items builder ([senderItemsBuilder],
/// [receiverItemsBuilder]). The menu is available on every bubble, including
/// loading and failed ones.
///
/// Set it on [BubbleConfiguration.menuConfiguration]:
///
/// ```dart
/// BubbleConfiguration(
///   menuConfiguration: BubbleMenuConfiguration(
///     senderItemsBuilder: (context, request) => [
///       BubbleMenuItem(
///         label: 'Copy',
///         icon: const Icon(Icons.copy, size: 18),
///         onSelected: (context, request) => copyToClipboard(request.message),
///       ),
///       if (request.message.isFailed)
///         BubbleMenuItem(
///           label: 'Resend',
///           onSelected: (context, request) => controller.retryMessage(request.message),
///         ),
///       BubbleMenuItem(
///         label: 'Delete',
///         textStyle: const TextStyle(color: Colors.red),
///         onSelected: (context, request) =>
///             controller.removeMessageEverywhere(request.message),
///       ),
///     ],
///     receiverItemsBuilder: (context, request) => [
///       BubbleMenuItem(label: 'Reply', onSelected: (context, request) => reply(request.message)),
///     ],
///   ),
/// )
/// ```
class BubbleMenuConfiguration {
  /// Creates a [BubbleMenuConfiguration].
  const BubbleMenuConfiguration({
    this.senderItemsBuilder,
    this.receiverItemsBuilder,
    this.senderMenuHandler,
    this.receiverMenuHandler,
    this.enableLongPress = true,
    this.enableHapticFeedback = true,
    this.color,
    this.surfaceTintColor,
    this.shape,
    this.elevation,
    this.constraints,
    this.animationStyle,
    this.useRootNavigator = false,
  });

  /// Entries of the default menu for sender bubbles.
  ///
  /// Ignored when [senderMenuHandler] is set.
  final BubbleMenuItemsBuilder? senderItemsBuilder;

  /// Entries of the default menu for receiver bubbles.
  ///
  /// Ignored when [receiverMenuHandler] is set.
  final BubbleMenuItemsBuilder? receiverItemsBuilder;

  /// Custom presentation for sender bubbles. Replaces [senderItemsBuilder].
  final BubbleMenuHandler? senderMenuHandler;

  /// Custom presentation for receiver bubbles. Replaces [receiverItemsBuilder].
  final BubbleMenuHandler? receiverMenuHandler;

  /// Open the menu on a long press. Defaults to `true`.
  ///
  /// The long press is the only trigger, so `false` disables the menu on
  /// both sides while keeping the rest of the configuration.
  final bool enableLongPress;

  /// Vibrate when the menu opens. Defaults to `true`.
  ///
  /// Uses [HapticFeedback.mediumImpact]; it has no effect on platforms
  /// without haptics.
  final bool enableHapticFeedback;

  /// Background color of the default menu.
  final Color? color;

  /// Surface tint color of the default menu.
  final Color? surfaceTintColor;

  /// Shape of the default menu.
  final ShapeBorder? shape;

  /// Elevation of the default menu.
  final double? elevation;

  /// Size constraints of the default menu.
  final BoxConstraints? constraints;

  /// Duration and curve of the default menu's open/close transition.
  ///
  /// The transition itself is Material's (fade + vertical expand); this only
  /// retimes it. `AnimationStyle.noAnimation` makes the menu appear instantly.
  /// For a different kind of transition, present your own menu with
  /// [senderMenuHandler] / [receiverMenuHandler].
  final AnimationStyle? animationStyle;

  /// Push the default menu onto the root navigator. Defaults to `false`.
  ///
  /// Set it when the chat is inside a nested [Navigator] and the menu should
  /// cover the whole app. Only affects the default menu, not a handler.
  final bool useRootNavigator;

  /// Returns a copy with the given fields replaced.
  ///
  /// A field cannot be reset to `null` this way (passing `null` keeps the
  /// current value); create a new configuration instead.
  BubbleMenuConfiguration copyWith({
    BubbleMenuItemsBuilder? senderItemsBuilder,
    BubbleMenuItemsBuilder? receiverItemsBuilder,
    BubbleMenuHandler? senderMenuHandler,
    BubbleMenuHandler? receiverMenuHandler,
    bool? enableLongPress,
    bool? enableHapticFeedback,
    Color? color,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    double? elevation,
    BoxConstraints? constraints,
    AnimationStyle? animationStyle,
    bool? useRootNavigator,
  }) {
    return BubbleMenuConfiguration(
      senderItemsBuilder: senderItemsBuilder ?? this.senderItemsBuilder,
      receiverItemsBuilder: receiverItemsBuilder ?? this.receiverItemsBuilder,
      senderMenuHandler: senderMenuHandler ?? this.senderMenuHandler,
      receiverMenuHandler: receiverMenuHandler ?? this.receiverMenuHandler,
      enableLongPress: enableLongPress ?? this.enableLongPress,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      color: color ?? this.color,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      shape: shape ?? this.shape,
      elevation: elevation ?? this.elevation,
      constraints: constraints ?? this.constraints,
      animationStyle: animationStyle ?? this.animationStyle,
      useRootNavigator: useRootNavigator ?? this.useRootNavigator,
    );
  }
}

/// Toolkit-internal helpers on [BubbleMenuConfiguration].
///
/// Not exported from `package:chat_toolkit/chat_toolkit.dart`.
extension BubbleMenuConfigurationInternal on BubbleMenuConfiguration {
  /// Items builder for the given side.
  BubbleMenuItemsBuilder? itemsBuilderFor(bool isSender) =>
      isSender ? senderItemsBuilder : receiverItemsBuilder;

  /// Custom handler for the given side.
  BubbleMenuHandler? handlerFor(bool isSender) =>
      isSender ? senderMenuHandler : receiverMenuHandler;

  /// Whether the given side has a menu at all.
  bool isEnabledFor(bool isSender) =>
      handlerFor(isSender) != null || itemsBuilderFor(isSender) != null;
}

/// Shows the default popup menu for [request] at the pointer position.
///
/// Returns the chosen entry, or `null` when the menu was dismissed, had no
/// entries, or the side has no items builder.
///
/// Internal: not exported from `package:chat_toolkit/chat_toolkit.dart`.
Future<BubbleMenuItem?> showBubbleMenu({
  required BuildContext context,
  required BubbleMenuRequest request,
  required BubbleMenuConfiguration configuration,
}) async {
  final itemsBuilder = configuration.itemsBuilderFor(request.isSender);
  if (itemsBuilder == null) return null;

  final items = itemsBuilder(context, request);
  if (items.isEmpty) return null;

  final overlay = Overlay.of(
    context,
    rootOverlay: configuration.useRootNavigator,
  ).context.findRenderObject();
  if (overlay is! RenderBox || !overlay.hasSize) return null;

  // globalPosition is in screen coordinates, while showMenu's position is in
  // the Overlay's local coordinates. When the Overlay is scaled or offset (by a
  // FittedBox, for example) the two differ, so using it unconverted would place
  // the menu away from the pointer.
  final pointer = overlay.globalToLocal(request.globalPosition);
  final position = RelativeRect.fromRect(
    Rect.fromPoints(pointer, pointer),
    Offset.zero & overlay.size,
  );

  final selectedIndex = await showMenu<int>(
    context: context,
    position: position,
    color: configuration.color,
    surfaceTintColor: configuration.surfaceTintColor,
    shape: configuration.shape,
    elevation: configuration.elevation,
    constraints: configuration.constraints,
    popUpAnimationStyle: configuration.animationStyle,
    useRootNavigator: configuration.useRootNavigator,
    items: [
      for (int i = 0; i < items.length; i++)
        PopupMenuItem<int>(
          value: i,
          enabled: items[i].enabled,
          height: items[i].height,
          padding: items[i].padding,
          child: items[i].buildContent(context),
        ),
    ],
  );

  if (selectedIndex == null) return null;
  final selected = items[selectedIndex];
  if (context.mounted) selected.onSelected?.call(context, request);
  return selected;
}

/// Wraps a bubble and opens its context menu on a long press.
///
/// Returns [child] untouched when the matching side has no menu configured, so
/// bubbles without a menu keep their original gesture behavior.
///
/// Internal: not exported from `package:chat_toolkit/chat_toolkit.dart`.
class BubbleMenuDetector extends StatelessWidget {
  /// Creates a [BubbleMenuDetector].
  const BubbleMenuDetector({
    super.key,
    required this.child,
    required this.message,
    required this.isSender,
    this.configuration,
  });

  /// The bubble to wrap.
  final Widget child;

  /// The message shown by [child].
  final Message message;

  /// Whether [child] is a sender bubble.
  final bool isSender;

  /// Menu settings. `null` disables the menu.
  final BubbleMenuConfiguration? configuration;

  @override
  Widget build(BuildContext context) {
    final configuration = this.configuration;
    if (configuration == null ||
        !configuration.enableLongPress ||
        !configuration.isEnabledFor(isSender)) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) =>
          _open(context, configuration, details.globalPosition),
      child: child,
    );
  }

  Future<void> _open(
    BuildContext context,
    BubbleMenuConfiguration configuration,
    Offset globalPosition,
  ) async {
    final renderObject = context.findRenderObject();
    final Rect bubbleRect;
    if (renderObject is RenderBox && renderObject.hasSize) {
      bubbleRect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    } else {
      bubbleRect = Rect.fromPoints(globalPosition, globalPosition);
    }

    final request = BubbleMenuRequest(
      message: message,
      isSender: isSender,
      globalPosition: globalPosition,
      bubbleRect: bubbleRect,
    );

    // Not awaited: the menu should open immediately, not after the platform
    // acknowledges the vibration.
    if (configuration.enableHapticFeedback) {
      unawaited(HapticFeedback.mediumImpact());
    }

    final handler = configuration.handlerFor(isSender);
    if (handler != null) {
      await handler(context, request);
      return;
    }

    await showBubbleMenu(
      context: context,
      request: request,
      configuration: configuration,
    );
  }
}
