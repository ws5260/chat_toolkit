import 'package:material_ui/material_ui.dart';

import 'studio_model.dart';

/// The code of a part designed in the studio, as it would be written in an app.
String studioCode(Part part, StudioSpec spec, {StudioSpec? receiver}) {
  final w = _Writer(part);
  return switch (part) {
    Part.bubble => 'BubbleConfiguration(\n'
        '  senderBubbleBuilder: (context, child) => ${_indent(w.spec(spec), 1)},\n'
        '  receiverBubbleBuilder: (context, child) => ${_indent(w.spec(receiver ?? spec), 1)},\n'
        ')',
    Part.search => '// Rebuilds when the results change; queryController is a TextEditingController.\n'
        'searchBarBuilder: (context, search) => ListenableBuilder(\n'
        '  listenable: search,\n'
        '  builder: (context, _) => ${_indent(w.spec(spec), 1)},\n'
        '),',
    Part.input => '// Sending is up to you: send() reads textController and calls\n'
        '// controller.dispatchMessage(...).\n'
        'customInputField: (context, controller) => ${w.spec(spec)},',
    Part.notice =>
      'newReceiveMessageNotificationBuilder: (context, message, controller) => GestureDetector(\n'
          '  onTap: controller.scrollToBottom,\n'
          '  child: ${_indent(w.spec(spec), 1)},\n'
          '),',
    Part.separator => 'dateSeparatorBuilder: (context, timestamp) => ${w.spec(spec)},',
    Part.time => 'timeBuilder: (context, timestamp) => ${w.spec(spec)},',
    Part.profile => 'receiverProfileBuilder: (context, name) => ${w.spec(spec)},',
    Part.read => '// Shown for SenderMessage(isRead: false / true).\n'
        'readIndicatorBuilder: (context, isRead) => ${w.spec(spec)},',
    Part.readOnly => 'readOnlyWidget: ${w.spec(spec)},',
  };
}

String _indent(String code, int depth) => code.split('\n').join('\n${'  ' * depth}');

String _c(Color c) => c.a == 0 ? 'Colors.transparent' : 'Color(${hex(c)})';

String _n(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

String _str(String s) => "'${s.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";

/// A constructor call with one named argument per line; `null` arguments are left out.
String _call(String name, List<(String, String?)> args, {String? positional}) {
  final present = [for (final (k, v) in args) if (v != null) (k, v)];
  if (present.isEmpty) return '$name(${positional ?? ''})';
  final b = StringBuffer('$name(\n');
  if (positional != null) b.writeln('  ${_indent(positional, 1)},');
  for (final (k, v) in present) {
    b.writeln('  $k: ${_indent(v, 1)},');
  }
  b.write(')');
  return b.toString();
}

class _Writer {
  _Writer(this.part);

  final Part part;

  String spec(StudioSpec s) {
    final row = s.axis == StudioAxis.row;
    final box = s.box;
    final children = <String>[];
    for (final e in s.elements.where((e) => e.visible)) {
      final code = element(e, row: row);
      if (code == null) continue;
      if (children.isNotEmpty && s.gap > 0) {
        children.add('const SizedBox(${row ? 'width' : 'height'}: ${_n(s.gap)})');
      }
      children.add(code);
    }
    final flex = _call(row ? 'Row' : 'Column', [
      ('mainAxisSize', box.fill && row ? null : 'MainAxisSize.min'),
      ('mainAxisAlignment', s.main == StudioAlign.start ? null : 'MainAxisAlignment.${_mainName(s.main)}'),
      ('crossAxisAlignment', s.cross == StudioAlign.center ? null : 'CrossAxisAlignment.${s.cross == StudioAlign.end ? 'end' : 'start'}'),
      ('children', '[\n  ${children.map((c) => _indent(c, 1)).join(',\n  ')},\n]'),
    ]);
    final decoration = _decoration(box);
    final wide = box.fill && (!row || !children.any((c) => c.startsWith('Expanded')));
    var result = _call('Container', [
      ('width', wide ? 'double.infinity' : null),
      ('constraints', box.height > 0 ? 'const BoxConstraints(minHeight: ${_n(box.height)})' : null),
      ('margin', _insets(box.marginH, box.marginV)),
      ('padding', _insets(box.paddingH, box.paddingV)),
      ('decoration', decoration),
      ('child', flex),
    ]);
    if (!box.fill && (part == Part.notice || part == Part.separator || part == Part.readOnly)) {
      result = _call('Align', [
        ('alignment', 'Alignment.${box.align == StudioAlign.start ? 'centerLeft' : box.align == StudioAlign.end ? 'centerRight' : 'center'}'),
        ('widthFactor', '1'),
        ('child', result),
      ]);
    }
    return result;
  }

  String _mainName(StudioAlign a) => switch (a) {
        StudioAlign.start => 'start',
        StudioAlign.center => 'center',
        StudioAlign.end => 'end',
        StudioAlign.between => 'spaceBetween',
      };

  String? _insets(double h, double v) {
    if (h == 0 && v == 0) return null;
    if (h == v) return 'const EdgeInsets.all(${_n(h)})';
    if (v == 0) return 'const EdgeInsets.symmetric(horizontal: ${_n(h)})';
    if (h == 0) return 'const EdgeInsets.symmetric(vertical: ${_n(v)})';
    return 'const EdgeInsets.symmetric(horizontal: ${_n(h)}, vertical: ${_n(v)})';
  }

  String? _decoration(StudioBox box) {
    final args = <(String, String?)>[
      ('color', box.gradientTo == null && box.background.a > 0 ? 'const ${_c(box.background)}' : null),
      (
        'gradient',
        box.gradientTo == null
            ? null
            : 'const LinearGradient(\n  begin: Alignment.topLeft,\n  end: Alignment.bottomRight,\n'
                '  colors: [${_c(box.background)}, ${_c(box.gradientTo!)}],\n)'
      ),
      (
        'border',
        box.borderWidth > 0
            ? 'Border.all(color: const ${_c(box.borderColor)}, width: ${_n(box.borderWidth)})'
            : null
      ),
      ('borderRadius', box.radius > 0 ? 'BorderRadius.circular(${_n(box.radius)})' : null),
      (
        'boxShadow',
        box.shadow > 0
            ? '[\n  BoxShadow(\n    color: Colors.black.withValues(alpha: 0.16),\n'
                '    blurRadius: ${_n(box.shadow)},\n    offset: Offset(0, ${_n(box.shadow / 4)}),\n  ),\n]'
            : null
      ),
    ];
    if (args.every((a) => a.$2 == null)) return null;
    return _call('BoxDecoration', args);
  }

  String _textStyle(StudioElement e) => 'TextStyle(fontSize: ${_n(e.fontSize)}, '
      'color: const ${_c(e.color)}${e.bold ? ', fontWeight: FontWeight.w700' : ''})';

  /// The Dart expression of a text source.
  String _text(StudioElement e) => switch (e.source) {
        TextSource.literal => _str(e.text),
        TextSource.name => part == Part.notice ? 'message.name' : 'name',
        TextSource.time => 'DateFormat.${e.use24h ? 'Hm' : 'jm'}().format(DateTime.parse(${part == Part.bubble ? 'timestamp' : 'timestamp'}))',
        TextSource.date => 'DateFormat.${e.weekday ? 'MMMEd' : 'yMd'}().format(DateTime.parse(timestamp))',
        TextSource.resultCount => "'\${search.index + 1}/\${search.results.length}'",
        TextSource.readState => 'isRead ? ${_str(e.text2)} : ${_str(e.text)}',
        TextSource.noticeLabel => "'New message from \${message.name}'",
        TextSource.readOnlyLabel => "'This chat is read-only'",
      };

  String _action(ButtonAction a) => switch (a) {
        ButtonAction.none => '() {}',
        ButtonAction.send => 'send',
        ButtonAction.attach => 'pickAttachment',
        ButtonAction.older => 'search.hasOlder ? search.showOlder : null',
        ButtonAction.newer => 'search.hasNewer ? search.showNewer : null',
        ButtonAction.close => 'search.close',
      };

  String? element(StudioElement e, {required bool row}) {
    switch (e.kind) {
      case ElementKind.content:
        return _call('DefaultTextStyle.merge', [
          ('style', 'const ${_textStyle(e)}'),
          ('child', 'child'),
        ]);
      case ElementKind.text:
        final text = 'Text(${_text(e)}, style: const ${_textStyle(e)})';
        return e.source == TextSource.resultCount
            ? 'if (search.hasSearched) $text'
            : text;
      case ElementKind.icon:
        final icon = part == Part.read
            ? 'isRead ? ${e.icon2.code} : ${e.icon.code}'
            : e.icon.code;
        return 'Icon($icon, size: ${_n(e.size)}, color: const ${_c(e.color)})';
      case ElementKind.field:
        final filled = e.background.a > 0;
        final field = _call('TextField', [
          ('controller', part == Part.search ? 'queryController' : 'textController'),
          ('onSubmitted', part == Part.search ? 'search.search' : '(_) => send()'),
          ('style', 'const ${_textStyle(e)}'),
          (
            'decoration',
            _call('InputDecoration', [
              ('hintText', e.text.isEmpty ? null : _str(e.text)),
              ('filled', filled ? 'true' : null),
              ('fillColor', filled ? 'const ${_c(e.background)}' : null),
              (
                'border',
                'OutlineInputBorder(\n  borderRadius: BorderRadius.circular(${_n(e.radius)}),\n'
                    '  borderSide: BorderSide.none,\n)'
              ),
            ])
          ),
        ]);
        return row ? 'Expanded(\n  child: ${_indent(field, 1)},\n)' : field;
      case ElementKind.button:
        final onPressed = _action(e.action);
        return switch (e.look) {
          ButtonLook.icon => _call('IconButton', [
              ('onPressed', onPressed),
              ('icon', 'Icon(${e.icon.code}, size: ${_n(e.size)})'),
              ('color', 'const ${_c(e.color)}'),
            ]),
          ButtonLook.filled => _call('IconButton.filled', [
              ('onPressed', onPressed),
              (
                'style',
                _call('IconButton.styleFrom', [
                  ('backgroundColor', 'const ${_c(e.background)}'),
                  ('foregroundColor', 'const ${_c(e.color)}'),
                  (
                    'shape',
                    'RoundedRectangleBorder(borderRadius: BorderRadius.circular(${_n(e.radius)}))'
                  ),
                ])
              ),
              ('icon', 'Icon(${e.icon.code}, size: ${_n(e.size)})'),
            ]),
          ButtonLook.text => _call('TextButton', [
              ('onPressed', onPressed),
              (
                'style',
                'TextButton.styleFrom(foregroundColor: const ${_c(e.color)})'
              ),
              ('child', 'Text(${_str(e.text.isEmpty ? _defaultLabel(e.action) : e.text)})'),
            ]),
        };
      case ElementKind.badge:
        final badge = _call('Container', [
          ('padding', 'const EdgeInsets.symmetric(horizontal: 8, vertical: 3)'),
          (
            'decoration',
            'BoxDecoration(\n  color: const ${_c(e.background)},\n'
                '  borderRadius: BorderRadius.circular(${_n(e.radius)}),\n)'
          ),
          ('child', 'Text(${_text(e)}, style: const ${_textStyle(e)})'),
        ]);
        return e.source == TextSource.resultCount ? 'if (search.hasSearched)\n  ${_indent(badge, 1)}' : badge;
      case ElementKind.avatar:
        final name = part == Part.notice ? 'message.name' : 'name';
        return _call('Container', [
          ('width', _n(e.size)),
          ('height', _n(e.size)),
          ('alignment', 'Alignment.center'),
          (
            'decoration',
            'BoxDecoration(\n  color: const ${_c(e.background)},\n'
                '  borderRadius: BorderRadius.circular(${_n(e.size * e.radius)}),\n)'
          ),
          ('child', 'Text($name.characters.first, style: const TextStyle(color: ${_c(e.color)}))'),
        ]);
      case ElementKind.spacer:
        if (e.expand) return row ? 'const Spacer()' : null;
        return 'const SizedBox(${row ? 'width' : 'height'}: ${_n(e.size)})';
      case ElementKind.divider:
        final line = 'Container(height: ${_n(e.size)}, color: const ${_c(e.color)})';
        return row ? 'Expanded(child: $line)' : line;
    }
  }

  String _defaultLabel(ButtonAction a) => switch (a) {
        ButtonAction.send => 'Send',
        ButtonAction.attach => 'Attach',
        ButtonAction.older => 'Older',
        ButtonAction.newer => 'Newer',
        ButtonAction.close => 'Close',
        ButtonAction.none => 'Button',
      };
}
