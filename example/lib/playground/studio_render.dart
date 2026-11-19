import 'package:material_ui/material_ui.dart';

import 'studio_model.dart';

/// What a part is showing: the values and callbacks its elements are bound to.
class StudioBinding {
  const StudioBinding({
    required this.text,
    this.content,
    this.isRead = false,
    this.field,
    this.focus,
    this.onSubmitted,
    this.hint = '',
    this.actions = const {},
    this.actionLabel,
    this.onTap,
  });

  /// The text of a text or badge element; empty hides a badge.
  final String Function(StudioElement element) text;

  /// The message content, for [ElementKind.content].
  final Widget? content;

  /// For the read indicator: which of `text`/`text2` and `icon`/`icon2` to show.
  final bool isRead;

  final TextEditingController? field;
  final FocusNode? focus;
  final ValueChanged<String>? onSubmitted;
  final String hint;

  /// Callbacks of the button actions; a missing or `null` one disables the button.
  final Map<ButtonAction, VoidCallback?> actions;

  /// The default label of a text button with no label of its own.
  final String Function(ButtonAction action)? actionLabel;

  /// Tapping the whole part (the new message notice).
  final VoidCallback? onTap;
}

MainAxisAlignment _main(StudioAlign a) => switch (a) {
      StudioAlign.start => MainAxisAlignment.start,
      StudioAlign.center => MainAxisAlignment.center,
      StudioAlign.end => MainAxisAlignment.end,
      StudioAlign.between => MainAxisAlignment.spaceBetween,
    };

CrossAxisAlignment _cross(StudioAlign a) => switch (a) {
      StudioAlign.start => CrossAxisAlignment.start,
      StudioAlign.end => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.center,
    };

Alignment _align(StudioAlign a) => switch (a) {
      StudioAlign.start => AlignmentDirectional.centerStart.resolve(TextDirection.ltr),
      StudioAlign.end => AlignmentDirectional.centerEnd.resolve(TextDirection.ltr),
      _ => Alignment.center,
    };

/// The decoration of [box].
BoxDecoration studioDecoration(StudioBox box) => BoxDecoration(
      color: box.gradientTo == null ? box.background : null,
      gradient: box.gradientTo == null
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [box.background, box.gradientTo!],
            ),
      border: box.borderWidth > 0
          ? Border.all(color: box.borderColor, width: box.borderWidth)
          : null,
      borderRadius: box.radius > 0 ? BorderRadius.circular(box.radius) : null,
      boxShadow: box.shadow > 0
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: box.shadow,
                offset: Offset(0, box.shadow / 4),
              ),
            ]
          : null,
    );

/// Builds [spec] with the values of [b].
///
/// [aligned] places a box that does not fill the width (centre, start or end); turn it off where
/// the toolkit already places the part (bubbles, time).
Widget renderStudio(StudioSpec spec, StudioBinding b, {bool aligned = true}) {
  final row = spec.axis == StudioAxis.row;
  final box = spec.box;
  final visible = spec.elements.where((e) => e.visible).toList();
  // A row without stretching elements wraps onto the next line instead of overflowing.
  final stretches = visible.any((e) =>
      e.kind == ElementKind.field ||
      e.kind == ElementKind.divider ||
      (e.kind == ElementKind.spacer && e.expand));
  final wrap = row && !stretches;
  final children = <Widget>[];
  for (final e in visible) {
    final child = _element(e, b, row: row, wrap: wrap);
    if (child == null) continue;
    if (!wrap && children.isNotEmpty && spec.gap > 0) {
      children.add(row ? SizedBox(width: spec.gap) : SizedBox(height: spec.gap));
    }
    children.add(child);
  }
  Widget flex;
  if (wrap) {
    flex = Wrap(
      spacing: spec.gap,
      runSpacing: spec.gap,
      alignment: switch (spec.main) {
        StudioAlign.start => WrapAlignment.start,
        StudioAlign.center => WrapAlignment.center,
        StudioAlign.end => WrapAlignment.end,
        StudioAlign.between => WrapAlignment.spaceBetween,
      },
      crossAxisAlignment: switch (spec.cross) {
        StudioAlign.start => WrapCrossAlignment.start,
        StudioAlign.end => WrapCrossAlignment.end,
        _ => WrapCrossAlignment.center,
      },
      children: children,
    );
    // A full-width box: the wrap spans it, so its alignment shows.
    if (box.fill) flex = SizedBox(width: double.infinity, child: flex);
  } else {
    flex = row
        ? Row(
            mainAxisSize: box.fill ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: _main(spec.main),
            crossAxisAlignment: _cross(spec.cross),
            children: children,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: _main(spec.main),
            crossAxisAlignment: _cross(spec.cross),
            children: children,
          );
    // A full-width column spans the box, so its cross alignment shows.
    if (!row && box.fill) flex = SizedBox(width: double.infinity, child: flex);
  }
  Widget result = Container(
    // A minimum, so a taller content (bigger text, a column) grows the box instead of overflowing.
    constraints: box.height > 0 ? BoxConstraints(minHeight: box.height) : null,
    padding: EdgeInsets.symmetric(horizontal: box.paddingH, vertical: box.paddingV),
    decoration: studioDecoration(box),
    clipBehavior: box.radius > 0 ? Clip.antiAlias : Clip.none,
    child: flex,
  );
  if (b.onTap != null) {
    result = GestureDetector(
      onTap: b.onTap,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: result),
    );
  }
  result = Padding(
    padding: EdgeInsets.symmetric(horizontal: box.marginH, vertical: box.marginV),
    child: result,
  );
  if (aligned && !box.fill) {
    result = Align(alignment: _align(box.align), widthFactor: 1, heightFactor: 1, child: result);
  }
  return result;
}

TextStyle _style(StudioElement e) => TextStyle(
      fontSize: e.fontSize,
      color: e.color,
      fontWeight: e.bold ? FontWeight.w700 : FontWeight.w400,
    );

Widget? _element(StudioElement e, StudioBinding b, {required bool row, bool wrap = false}) {
  switch (e.kind) {
    case ElementKind.content:
      if (b.content == null) return null;
      return DefaultTextStyle.merge(
        style: _style(e).copyWith(height: 1.45),
        child: IconTheme.merge(data: IconThemeData(color: e.color), child: b.content!),
      );
    case ElementKind.text:
      final text = b.text(e);
      if (text.isEmpty) return null;
      final label = Text(text, style: _style(e));
      return row && !wrap ? Flexible(child: label) : label;
    case ElementKind.icon:
      return Icon((b.isRead ? e.icon2 : e.icon).data, size: e.size, color: e.color);
    case ElementKind.field:
      final filled = e.background.a > 0;
      final field = TextField(
        controller: b.field,
        focusNode: b.focus,
        style: _style(e),
        cursorColor: e.color,
        textInputAction: TextInputAction.send,
        // onEditingComplete (not onSubmitted) keeps the focus in the field after Enter.
        onEditingComplete:
            b.onSubmitted == null ? null : () => b.onSubmitted!(b.field?.text ?? ''),
        decoration: InputDecoration(
          isDense: true,
          hintText: e.text.isEmpty ? b.hint : e.text,
          hintStyle: _style(e).copyWith(color: e.color.withValues(alpha: 0.45)),
          filled: filled,
          fillColor: e.background,
          contentPadding: filled
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 13)
              : const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(e.radius),
            borderSide: BorderSide.none,
          ),
        ),
      );
      return row ? Expanded(child: field) : field;
    case ElementKind.button:
      final onPressed = b.actions[e.action];
      final label = e.text.isNotEmpty ? e.text : (b.actionLabel?.call(e.action) ?? '');
      return switch (e.look) {
        ButtonLook.icon => IconButton(
            tooltip: label.isEmpty ? null : label,
            onPressed: onPressed,
            icon: Icon(e.icon.data, size: e.size),
            color: e.color,
            disabledColor: e.color.withValues(alpha: 0.3),
            visualDensity: VisualDensity.compact,
          ),
        ButtonLook.filled => IconButton.filled(
            tooltip: label.isEmpty ? null : label,
            onPressed: onPressed,
            style: IconButton.styleFrom(
              backgroundColor: e.background,
              foregroundColor: e.color,
              disabledBackgroundColor: e.background.withValues(alpha: 0.4),
              minimumSize: Size.square(e.size + 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(e.radius)),
            ),
            icon: Icon(e.icon.data, size: e.size),
          ),
        ButtonLook.text => TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: e.color,
              backgroundColor: e.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(e.radius)),
              textStyle: TextStyle(fontSize: e.fontSize, fontWeight: FontWeight.w700),
            ),
            child: Text(label),
          ),
      };
    case ElementKind.badge:
      final text = b.text(e);
      if (text.isEmpty) return null;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: e.background,
          borderRadius: BorderRadius.circular(e.radius),
        ),
        child: Text(text, style: _style(e)),
      );
    case ElementKind.avatar:
      final name = b.text(StudioElement(ElementKind.text, source: TextSource.name));
      return Container(
        width: e.size,
        height: e.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: e.background,
          borderRadius: BorderRadius.circular(e.size * e.radius),
        ),
        child: Text(
          name.isEmpty ? '?' : name.characters.first,
          style: TextStyle(fontSize: e.size * 0.42, fontWeight: FontWeight.w700, color: e.color),
        ),
      );
    case ElementKind.spacer:
      if (e.expand) return row ? const Spacer() : null;
      return row ? SizedBox(width: e.size) : SizedBox(height: e.size);
    case ElementKind.divider:
      final line = Container(height: e.size, color: e.color);
      return row ? Expanded(child: line) : SizedBox(width: double.infinity, child: line);
  }
}
