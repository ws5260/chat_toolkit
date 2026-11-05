import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import 'entity/message.dart';

/// Information about the bubble a context menu was requested for.
///
/// Passed to every menu callback so a single builder can serve many bubbles.
class BubbleMenuRequest {
  const BubbleMenuRequest({
    required this.message,
    required this.isSender,
    required this.globalPosition,
    required this.bubbleRect,
  });

  /// The message the menu was opened for.
  final Message message;

  /// `true` for a sender bubble, `false` for a receiver bubble.
  final bool isSender;

  /// Global position of the pointer that opened the menu
  /// (the finger for a long press, the cursor for a right click).
  final Offset globalPosition;

  /// Global bounds of the bubble, useful for anchoring a custom menu to it.
  final Rect bubbleRect;
}

/// Builds the entries of the default context menu for one bubble.
///
/// Return an empty list to suppress the menu for that message
/// (e.g. while it is still sending).
typedef BubbleMenuItemsBuilder =
    List<BubbleMenuItem> Function(BuildContext context, BubbleMenuRequest request);

/// Presents a completely custom menu (bottom sheet, dialog, overlay, ...).
///
/// When provided it replaces the default popup menu for that side.
typedef BubbleMenuHandler =
    Future<void> Function(BuildContext context, BubbleMenuRequest request);

/// Called when a [BubbleMenuItem] is chosen.
typedef BubbleMenuItemCallback =
    void Function(BuildContext context, BubbleMenuRequest request);

/// A single entry of the default bubble context menu.
///
/// Provide either a [label] (optionally with an [icon]) or a fully custom [child].
class BubbleMenuItem {
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
  final BubbleMenuItemCallback? onSelected;

  /// Whether the entry can be chosen.
  final bool enabled;

  /// Text style applied to [label].
  final TextStyle? textStyle;

  /// Height of the entry.
  final double height;

  /// Padding of the entry.
  final EdgeInsets? padding;

  /// Builds the widget shown inside the popup menu entry.
  Widget buildContent(BuildContext context) {
    if (child != null) return child!;

    final text = Text(label!, style: textStyle);
    if (icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [icon!, const Gap(12), Flexible(child: text)],
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
/// A side without an items builder and without a handler has no menu.
class BubbleMenuConfiguration {
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
  final BubbleMenuItemsBuilder? senderItemsBuilder;

  /// Entries of the default menu for receiver bubbles.
  final BubbleMenuItemsBuilder? receiverItemsBuilder;

  /// Custom presentation for sender bubbles. Replaces [senderItemsBuilder].
  final BubbleMenuHandler? senderMenuHandler;

  /// Custom presentation for receiver bubbles. Replaces [receiverItemsBuilder].
  final BubbleMenuHandler? receiverMenuHandler;

  /// Open the menu on a long press. Defaults to `true`.
  final bool enableLongPress;

  /// Vibrate when the menu opens. Defaults to `true`.
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

  /// Push the default menu onto the root navigator.
  final bool useRootNavigator;

  /// Items builder for the given side.
  BubbleMenuItemsBuilder? itemsBuilderFor(bool isSender) =>
      isSender ? senderItemsBuilder : receiverItemsBuilder;

  /// Custom handler for the given side.
  BubbleMenuHandler? handlerFor(bool isSender) =>
      isSender ? senderMenuHandler : receiverMenuHandler;

  /// Whether the given side has a menu at all.
  bool isEnabledFor(bool isSender) =>
      handlerFor(isSender) != null || itemsBuilderFor(isSender) != null;

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

/// Shows the default popup menu for [request] at the pointer position.
///
/// Returns the chosen entry, or `null` when the menu was dismissed, had no
/// entries, or the side has no items builder.
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

  // Anchor the menu to the pointer so a long press and a right click both open
  // it where the user acted.
  final position = RelativeRect.fromRect(
    Rect.fromPoints(request.globalPosition, request.globalPosition),
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
class BubbleMenuDetector extends StatelessWidget {
  const BubbleMenuDetector({
    super.key,
    required this.child,
    required this.message,
    required this.isSender,
    this.configuration,
  });

  final Widget child;
  final Message message;
  final bool isSender;
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
