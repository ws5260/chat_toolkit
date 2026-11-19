import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../site/site_theme.dart';
import 'playground_controls.dart';
import 'studio_model.dart';

/// The studio panel: designs one part of the chat. Every change calls [onChanged] so the chat
/// updates right away.
class StudioEditor extends StatefulWidget {
  const StudioEditor({
    super.key,
    required this.part,
    required this.title,
    required this.description,
    required this.variants,
    required this.code,
    required this.onChanged,
    required this.onReset,
    required this.onClose,
    this.closeIcon = Icons.close_rounded,
    this.previewLabel,
    this.onPreview,
  });

  final Part part;
  final String title;
  final String description;

  /// The designs being edited, with a label each (the bubble has mine and theirs).
  final List<(String, StudioSpec)> variants;
  final String Function() code;
  final VoidCallback onChanged;
  final VoidCallback onReset;
  final VoidCallback onClose;
  final IconData closeIcon;

  /// A button that makes the part show in the chat (e.g. the new message notice).
  final String? previewLabel;
  final VoidCallback? onPreview;

  @override
  State<StudioEditor> createState() => _StudioEditorState();
}

class _StudioEditorState extends State<StudioEditor> {
  int _variant = 0;
  int _tab = 0;
  StudioElement? _selected;

  AppLocalizations get l => AppLocalizations.of(context);
  StudioSpec get spec => widget.variants[_variant.clamp(0, widget.variants.length - 1)].$2;
  PartRules get rules => rulesOf(widget.part);

  @override
  void initState() {
    super.initState();
    _selectFirst();
  }

  @override
  void didUpdateWidget(StudioEditor old) {
    super.didUpdateWidget(old);
    if (old.part != widget.part) {
      _variant = 0;
      _selectFirst();
    }
  }

  /// Opens the first element, so its colour and size are in view right away.
  void _selectFirst() {
    final elements = spec.elements;
    _selected = elements.isEmpty ? null : elements.first;
  }

  void _change(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: SiteShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            child: Row(children: [
              const Icon(Icons.tune_rounded, size: 20, color: SiteColors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l.studioTitle(widget.title),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                key: const Key('studio-reset'),
                tooltip: l.studioReset,
                onPressed: () {
                  setState(() => _selected = null);
                  widget.onReset();
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 20),
                color: SiteColors.grey600,
              ),
              IconButton(
                key: const Key('studio-close'),
                tooltip: l.close,
                onPressed: widget.onClose,
                icon: Icon(widget.closeIcon, size: 20),
                color: SiteColors.grey600,
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (widget.variants.length > 1) ...[
                SegmentedChoice<int>(
                  value: _variant,
                  options: {
                    for (var i = 0; i < widget.variants.length; i++) i: widget.variants[i].$1,
                  },
                  onChanged: (v) => setState(() {
                    _variant = v;
                    _selectFirst();
                  }),
                ),
                const SizedBox(height: 8),
              ],
              SegmentedChoice<int>(
                value: _tab,
                options: {0: l.tabStructure, 1: l.tabStyle, 2: l.tabCode},
                onChanged: (v) => setState(() => _tab = v),
              ),
              if (widget.onPreview != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('studio-preview'),
                  onPressed: widget.onPreview,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(widget.previewLabel ?? ''),
                ),
              ],
            ]),
          ),
          const Divider(height: 1, color: SiteColors.grey100),
          Expanded(
            child: ListView(
              key: const Key('studio-body'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: switch (_tab) {
                0 => _structure(),
                1 => _style(),
                _ => _code(),
              },
            ),
          ),
        ]),
      );

  // ---------------------------------------------------------------------------
  // Structure: layout and elements

  List<Widget> _structure() => [
        FieldRow(
          title: l.layoutAxis,
          child: SegmentedChoice<StudioAxis>(
            value: spec.axis,
            options: {StudioAxis.row: l.axisRow, StudioAxis.column: l.axisColumn},
            onChanged: (v) => _change(() => spec.axis = v),
          ),
        ),
        // Lining up along the row only shows when the row is wider than its elements and no
        // element (an input field, a line) takes the remaining space.
        if (spec.axis == StudioAxis.row && spec.box.fill && !_stretches)
          FieldRow(
            title: l.layoutMain,
            child: SegmentedChoice<StudioAlign>(
              value: spec.main,
              options: _aligns(withBetween: true),
              onChanged: (v) => _change(() => spec.main = v),
            ),
          ),
        FieldRow(
          title: l.layoutCross,
          child: SegmentedChoice<StudioAlign>(
            value: spec.cross == StudioAlign.between ? StudioAlign.center : spec.cross,
            options: _aligns(),
            onChanged: (v) => _change(() => spec.cross = v),
          ),
        ),
        _slider(l.layoutGap, spec.gap, 0, 24, (v) => spec.gap = v),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: Text(l.elements,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: SiteColors.grey900)),
          ),
          if (_addable.isNotEmpty) _addButton(),
        ]),
        const SizedBox(height: 4),
        Text(l.elementsHint, style: const TextStyle(fontSize: 12, color: SiteColors.grey500)),
        const SizedBox(height: 8),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) => _change(() {
            spec.elements.insert(to, spec.elements.removeAt(from));
          }),
          children: [
            for (var i = 0; i < spec.elements.length; i++)
              _elementTile(i, spec.elements[i]),
          ],
        ),
      ];

  bool get _stretches => spec.elements
      .any((e) => e.visible && (e.kind == ElementKind.field || e.kind == ElementKind.divider));

  Map<StudioAlign, String> _aligns({bool withBetween = false}) => {
        StudioAlign.start: l.alignStart,
        StudioAlign.center: l.alignCenter,
        StudioAlign.end: l.alignEnd,
        if (withBetween) StudioAlign.between: l.alignBetween,
      };

  /// Kinds that can still be added: one content and one field at most, and a button only while
  /// an action has no button.
  List<ElementKind> get _addable {
    final single = {ElementKind.content, ElementKind.field};
    final buttons = spec.elements.where((e) => e.kind == ElementKind.button).length;
    return [
      for (final k in rules.kinds)
        if ((!single.contains(k) || spec.elements.every((e) => e.kind != k)) &&
            (k != ElementKind.button || buttons < rules.actions.length))
          k,
    ];
  }

  Widget _addButton() {
    final kinds = _addable;
    return PopupMenuButton<ElementKind>(
      key: const Key('studio-add'),
      tooltip: l.addElement,
      color: Colors.white,
      onSelected: (kind) => _change(() {
        final e = newElement(widget.part, kind, existing: spec.elements);
        spec.elements.add(e);
        _selected = e;
      }),
      itemBuilder: (context) => [
        for (final k in kinds)
          PopupMenuItem(
            value: k,
            child: Row(children: [
              Icon(_kindIcon(k), size: 18, color: SiteColors.grey600),
              const SizedBox(width: 10),
              Text(_kindLabel(k)),
            ]),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: SiteColors.blueWeak,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add_rounded, size: 18, color: SiteColors.blue),
          const SizedBox(width: 4),
          Text(l.addElement,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: SiteColors.blue)),
        ]),
      ),
    );
  }

  Widget _elementTile(int index, StudioElement e) {
    final selected = identical(_selected, e);
    return Container(
      key: ObjectKey(e),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF5F9FF) : SiteColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? SiteColors.blue : SiteColors.grey100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selected = selected ? null : e),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: Row(children: [
              ReorderableDragStartListener(
                index: index,
                child: const MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_indicator_rounded, size: 18, color: SiteColors.grey400),
                  ),
                ),
              ),
              Icon(_kindIcon(e.kind), size: 18,
                  color: e.visible ? SiteColors.grey700 : SiteColors.grey300),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_kindLabel(e.kind),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: e.visible ? SiteColors.grey900 : SiteColors.grey400)),
                  if (_summary(e).isNotEmpty)
                    Text(_summary(e),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: SiteColors.grey500)),
                ]),
              ),
              Icon(selected ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18, color: SiteColors.grey400),
              IconButton(
                tooltip: l.elementVisible,
                visualDensity: VisualDensity.compact,
                onPressed: () => _change(() => e.visible = !e.visible),
                icon: Icon(
                    e.visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18),
                color: SiteColors.grey500,
              ),
              IconButton(
                tooltip: l.menuDelete,
                visualDensity: VisualDensity.compact,
                onPressed: () => _change(() {
                  spec.elements.remove(e);
                  if (selected) _selected = null;
                }),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: SiteColors.grey500,
              ),
            ]),
          ),
        ),
        if (selected)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _properties(e),
            ),
          ),
      ]),
    );
  }

  IconData _kindIcon(ElementKind k) => switch (k) {
        ElementKind.content => Icons.notes_rounded,
        ElementKind.text => Icons.title_rounded,
        ElementKind.icon => Icons.star_outline_rounded,
        ElementKind.field => Icons.edit_note_rounded,
        ElementKind.button => Icons.smart_button_outlined,
        ElementKind.badge => Icons.label_outline_rounded,
        ElementKind.avatar => Icons.account_circle_outlined,
        ElementKind.spacer => Icons.space_bar_rounded,
        ElementKind.divider => Icons.horizontal_rule_rounded,
      };

  String _kindLabel(ElementKind k) => switch (k) {
        ElementKind.content => l.elContent,
        ElementKind.text => l.elText,
        ElementKind.icon => l.elIcon,
        ElementKind.field => l.elField,
        ElementKind.button => l.elButton,
        ElementKind.badge => l.elBadge,
        ElementKind.avatar => l.elAvatar,
        ElementKind.spacer => l.elSpacer,
        ElementKind.divider => l.elDivider,
      };

  String _sourceLabel(TextSource s) => switch (s) {
        TextSource.literal => l.srcLiteral,
        TextSource.name => l.srcName,
        TextSource.time => l.srcTime,
        TextSource.date => l.srcDate,
        TextSource.resultCount => l.srcCount,
        TextSource.readState => l.srcRead,
        TextSource.noticeLabel => l.srcNotice,
        TextSource.readOnlyLabel => l.srcReadOnly,
      };

  String _actionLabel(ButtonAction a) => switch (a) {
        ButtonAction.none => l.actNone,
        ButtonAction.send => l.send,
        ButtonAction.attach => l.actAttach,
        ButtonAction.older => l.searchOlder,
        ButtonAction.newer => l.searchNewer,
        ButtonAction.close => l.close,
      };

  String _summary(StudioElement e) => switch (e.kind) {
        ElementKind.text || ElementKind.badge => e.source == TextSource.literal
            ? '"${e.text}"'
            : _sourceLabel(e.source),
        ElementKind.button => _actionLabel(e.action),
        ElementKind.field => e.text,
        _ => '',
      };

  List<Widget> _properties(StudioElement e) {
    final text = [ElementKind.text, ElementKind.badge].contains(e.kind);
    return [
      if (text) ...[
        if (rules.sources.length > 1)
          _segments<TextSource>(l.propSource, e.source, {
            for (final s in rules.sources) s: _sourceLabel(s),
          }, (v) {
            e.source = v;
            // Typed text starts with something to see.
            if (v == TextSource.literal && e.text.isEmpty) e.text = _kindLabel(e.kind);
          }),
        if (e.source == TextSource.literal) _textInput(l.propText, e.text, (v) => e.text = v),
        if (e.source == TextSource.readState) ...[
          _textInput(l.propTextUnread, e.text, (v) => e.text = v),
          _textInput(l.propTextRead, e.text2, (v) => e.text2 = v),
        ],
        if (e.source == TextSource.time)
          _switch(l.use24hTitle, e.use24h, (v) => e.use24h = v),
        if (e.source == TextSource.date)
          _switch(l.weekdayTitle, e.weekday, (v) => e.weekday = v),
      ],
      if (e.kind == ElementKind.button) ...[
        if (rules.actions.length > 1)
          _segments<ButtonAction>(l.propAction, e.action, {
            for (final a in rules.actions) a: _actionLabel(a),
          }, (v) => e.action = v),
        _segments<ButtonLook>(l.designShape, e.look, {
          ButtonLook.icon: l.elIcon,
          ButtonLook.filled: l.lookFilled,
          ButtonLook.text: l.elText,
        }, (v) => e.look = v),
        if (e.look == ButtonLook.text)
          _textInput(l.propText, e.text, (v) => e.text = v, hint: _actionLabel(e.action)),
      ],
      if (e.kind == ElementKind.field)
        _textInput(l.propHint, e.text, (v) => e.text = v),
      if (e.kind == ElementKind.icon || (e.kind == ElementKind.button && e.look != ButtonLook.text))
        _iconPicker(widget.part == Part.read && e.kind == ElementKind.icon
            ? l.propIconUnread
            : l.elIcon, e.icon, (v) => e.icon = v),
      if (e.kind == ElementKind.icon && widget.part == Part.read)
        _iconPicker(l.propIconRead, e.icon2, (v) => e.icon2 = v),
      if (const [
        ElementKind.content,
        ElementKind.text,
        ElementKind.badge,
        ElementKind.field,
      ].contains(e.kind) ||
          (e.kind == ElementKind.button && e.look == ButtonLook.text)) ...[
        _slider(l.fontSize, e.fontSize, 9, 28, (v) => e.fontSize = v),
        if (e.kind != ElementKind.field) _switch(l.propBold, e.bold, (v) => e.bold = v),
      ],
      if (const [ElementKind.icon, ElementKind.button].contains(e.kind) &&
          e.look != ButtonLook.text)
        _slider(l.designSize, e.size, 10, 40, (v) => e.size = v),
      if (e.kind == ElementKind.avatar) ...[
        _slider(l.designSize, e.size, 16, 64, (v) => e.size = v),
        SliderRow(
          title: l.roundness,
          valueLabel: '${(e.radius * 200).round()}%',
          value: e.radius,
          min: 0,
          max: 0.5,
          divisions: 10,
          onChanged: (v) => _change(() => e.radius = v),
        ),
      ],
      if (e.kind != ElementKind.spacer)
        ColorField(
          title: const [ElementKind.icon, ElementKind.divider].contains(e.kind) ||
                  (e.kind == ElementKind.button && e.look != ButtonLook.text)
              ? l.propColor
              : l.designTextColor,
          color: e.color,
          onChanged: (c) => _change(() => e.color = c),
        ),
      if (const [ElementKind.badge, ElementKind.field, ElementKind.avatar].contains(e.kind) ||
          (e.kind == ElementKind.button && e.look != ButtonLook.icon))
        ColorField(
          title: l.designBackground,
          color: e.background,
          onChanged: (c) => _change(() => e.background = c),
        ),
      // Corners only show on a filled field, badge or button.
      if ((e.kind == ElementKind.badge) ||
          (e.kind == ElementKind.field && e.background.a > 0) ||
          (e.kind == ElementKind.button && e.look != ButtonLook.icon))
        _slider(l.designRadius, e.radius.clamp(0, 30), 0, 30,
            (v) => e.radius = v >= 30 ? 999 : v,
            label: e.radius >= 30 ? l.roundFull : null),
      if (e.kind == ElementKind.spacer) ...[
        _switch(l.propExpand, e.expand, (v) => e.expand = v),
        if (!e.expand) _slider(l.propWidth, e.size, 0, 64, (v) => e.size = v),
      ],
      if (e.kind == ElementKind.divider)
        _slider(l.propThickness, e.size, 1, 6, (v) => e.size = v),
    ];
  }

  // ---------------------------------------------------------------------------
  // Style: the box

  List<Widget> _style() {
    final box = spec.box;
    return [
      ColorField(
        title: l.designBackground,
        color: box.background,
        onChanged: (c) => _change(() => box.background = c),
      ),
      _switch(l.boxGradient, box.gradientTo != null,
          (v) => box.gradientTo = v ? SiteColors.blueWeak : null),
      if (box.gradientTo != null)
        ColorField(
          title: l.boxGradientTo,
          color: box.gradientTo!,
          onChanged: (c) => _change(() => box.gradientTo = c),
        ),
      _slider(l.designRadius, box.radius, 0, 40, (v) => box.radius = v),
      _slider(l.boxBorder, box.borderWidth, 0, 6, (v) => box.borderWidth = v),
      if (box.borderWidth > 0)
        ColorField(
          title: l.boxBorderColor,
          color: box.borderColor,
          onChanged: (c) => _change(() => box.borderColor = c),
        ),
      _slider(l.boxShadow, box.shadow, 0, 32, (v) => box.shadow = v),
      _slider(l.bubblePaddingH, box.paddingH, 0, 40, (v) => box.paddingH = v),
      _slider(l.bubblePaddingV, box.paddingV, 0, 40, (v) => box.paddingV = v),
      // Side margins of a centred box that only wraps its content change nothing.
      if (box.fill || box.align != StudioAlign.center)
        _slider(l.boxMarginH, box.marginH, 0, 40, (v) => box.marginH = v),
      _slider(l.boxMarginV, box.marginV, 0, 40, (v) => box.marginV = v),
      _slider(l.boxMinHeight, box.height, 0, 96, (v) => box.height = v,
          label: box.height == 0 ? l.boxAuto : null),
      // Only the date separator is placed by its own box; the toolkit places the others, and the
      // bars (search, input, read-only) always span the chat.
      if (widget.part == Part.separator) ...[
        _switch(l.boxFill, box.fill, (v) => box.fill = v),
        if (!box.fill)
          _segments<StudioAlign>(l.boxAlign, box.align == StudioAlign.between
              ? StudioAlign.center
              : box.align, _aligns(), (v) => box.align = v),
      ],
    ];
  }

  // ---------------------------------------------------------------------------
  // Code

  List<Widget> _code() => [
        const SizedBox(height: 8),
        Text(widget.description,
            style: const TextStyle(fontSize: 13, color: SiteColors.grey600, height: 1.55)),
        const SizedBox(height: 12),
        CodeBlock(code: widget.code(), copyLabel: l.copy, copiedLabel: l.copied),
      ];

  // ---------------------------------------------------------------------------
  // Rows

  Widget _slider(String title, double value, double min, double max, ValueChanged<double> set,
          {String? label}) =>
      SliderRow(
        title: title,
        valueLabel: label ?? '${value.round()}px',
        value: value,
        min: min,
        max: max,
        onChanged: (v) => _change(() => set(v.roundToDouble())),
      );

  Widget _switch(String title, bool value, ValueChanged<bool> set) => SwitchRow(
        title: title,
        value: value,
        onChanged: (v) => _change(() => set(v)),
      );

  Widget _segments<T>(String title, T value, Map<T, String> options, ValueChanged<T> set) =>
      FieldRow(
        title: title,
        child: SegmentedChoice<T>(
          value: value,
          options: options,
          onChanged: (v) => _change(() => set(v)),
        ),
      );

  Widget _textInput(String title, String value, ValueChanged<String> set, {String? hint}) =>
      FieldRow(
        title: title,
        child: _TextInput(
          // Keyed by the element so switching elements shows the right text.
          key: ValueKey((identityHashCode(_selected), title)),
          value: value,
          hint: hint,
          onChanged: (v) => _change(() => set(v)),
        ),
      );

  Widget _iconPicker(String title, StudioIcon value, ValueChanged<StudioIcon> set) => FieldRow(
        title: title,
        child: Wrap(spacing: 4, runSpacing: 4, children: [
          for (final icon in StudioIcon.values)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _change(() => set(icon)),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: icon == value ? SiteColors.blueWeak : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: icon == value ? SiteColors.blue : Colors.transparent),
                ),
                child: Icon(icon.data,
                    size: 18, color: icon == value ? SiteColors.blue : SiteColors.grey600),
              ),
            ),
        ]),
      );
}

class _TextInput extends StatefulWidget {
  const _TextInput({super.key, required this.value, required this.onChanged, this.hint});

  final String value;
  final String? hint;
  final ValueChanged<String> onChanged;

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          filled: true,
          fillColor: SiteColors.grey100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      );
}

/// Any colour: swatches, hue/saturation/brightness/opacity sliders and a hex field.
class ColorField extends StatefulWidget {
  const ColorField({super.key, required this.title, required this.color, required this.onChanged});

  final String title;
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<ColorField> {
  bool _open = false;
  late final _hex = TextEditingController(text: _hexOf(widget.color));
  // Kept apart from the colour so the hue survives grey and black.
  late HSVColor _hsv = HSVColor.fromColor(widget.color);

  static const _swatches = [
    Colors.transparent,
    Colors.white,
    SiteColors.grey50,
    SiteColors.grey100,
    SiteColors.grey200,
    SiteColors.grey400,
    SiteColors.grey600,
    SiteColors.grey900,
    Colors.black,
    SiteColors.blue,
    SiteColors.blueWeak,
    Color(0xFF7C5CFA),
    Color(0xFFF3EEFF),
    Color(0xFF15B886),
    Color(0xFFE6F8F1),
    Color(0xFFFF8A3D),
    Color(0xFFFFF4E6),
    Color(0xFFF04452),
    Color(0xFFFFEEEE),
    Color(0xFFFFD43B),
  ];

  static String _hexOf(Color c) =>
      c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();

  @override
  void didUpdateWidget(ColorField old) {
    super.didUpdateWidget(old);
    if (old.color != widget.color && widget.color != _hsv.toColor()) {
      _hsv = HSVColor.fromColor(widget.color);
      _hex.text = _hexOf(widget.color);
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _set(Color c, {HSVColor? hsv}) {
    _hsv = hsv ?? HSVColor.fromColor(c);
    _hex.text = _hexOf(c);
    widget.onChanged(c);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child: SettingLabel(title: widget.title)),
              _Swatch(color: widget.color, size: 26, selected: false),
              const SizedBox(width: 8),
              Text('#${_hexOf(widget.color)}',
                  style: const TextStyle(
                      fontSize: 12, fontFamily: 'monospace', color: SiteColors.grey600)),
              Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 20, color: SiteColors.grey500),
            ]),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final c in _swatches)
              GestureDetector(
                onTap: () => _set(c),
                child: _Swatch(color: c, size: 26, selected: c == widget.color),
              ),
          ]),
          const SizedBox(height: 4),
          for (final (label, value, max, apply) in [
            (l.colorHue, _hsv.hue, 360.0, (double v) => _hsv.withHue(v)),
            (l.colorSaturation, _hsv.saturation, 1.0, (double v) => _hsv.withSaturation(v)),
            (l.colorBrightness, _hsv.value, 1.0, (double v) => _hsv.withValue(v)),
            (l.colorOpacity, _hsv.alpha, 1.0, (double v) => _hsv.withAlpha(v)),
          ])
            Row(children: [
              SizedBox(
                width: 64,
                child: Text(label, style: const TextStyle(fontSize: 12, color: SiteColors.grey600)),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: value.clamp(0, max),
                    max: max,
                    onChanged: (v) {
                      final hsv = apply(v);
                      _set(hsv.toColor(), hsv: hsv);
                    },
                  ),
                ),
              ),
            ]),
          TextField(
            controller: _hex,
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(8),
            ],
            onSubmitted: (v) {
              final value = int.tryParse(v.length == 6 ? 'FF$v' : v, radix: 16);
              if (value != null && (v.length == 6 || v.length == 8)) _set(Color(value));
            },
            decoration: InputDecoration(
              isDense: true,
              prefixText: '#',
              helperText: l.colorHexHint,
              filled: true,
              fillColor: SiteColors.grey100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.size, required this.selected});

  final Color color;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? SiteColors.blue : SiteColors.grey200,
            width: selected ? 2.5 : 1,
          ),
        ),
        // A red slash marks "transparent".
        child: color.a == 0
            ? CustomPaint(painter: _SlashPainter())
            : null,
      );
}

class _SlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawLine(
        Offset(size.width * 0.2, size.height * 0.8),
        Offset(size.width * 0.8, size.height * 0.2),
        Paint()
          ..color = SiteColors.red
          ..strokeWidth = 1.5,
      );

  @override
  bool shouldRepaint(_SlashPainter oldDelegate) => false;
}
