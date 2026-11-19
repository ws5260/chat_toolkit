import 'package:material_ui/material_ui.dart';

import '../site/site_theme.dart';

/// A part of the chat that can be designed in the playground studio.
enum Part { bubble, search, input, notice, separator, time, profile, read, readOnly }

/// Whether a part uses the toolkit's widget, one designed in the studio, or nothing.
enum Look { library, custom, hidden }

/// What a [StudioElement] is.
enum ElementKind { content, text, icon, field, button, badge, avatar, spacer, divider }

/// Where the text of a text or badge element comes from.
enum TextSource {
  literal,
  name,
  preview, // Message.previewText: a one-line summary of the message
  time,
  date,
  resultCount,
  readState,
  noticeLabel,
  readOnlyLabel,
}

/// What a button element does.
enum ButtonAction { none, send, attach, older, newer, close }

enum ButtonLook { icon, filled, text }

enum StudioAxis { row, column }

enum StudioAlign { start, center, end, between }

/// Icons offered by the studio, with the name used in code.
enum StudioIcon {
  search(Icons.search_rounded),
  manageSearch(Icons.manage_search_rounded),
  close(Icons.close_rounded),
  expandLess(Icons.expand_less_rounded),
  expandMore(Icons.expand_more_rounded),
  arrowUpward(Icons.arrow_upward_rounded),
  arrowDownward(Icons.arrow_downward_rounded),
  send(Icons.send_rounded),
  add(Icons.add_rounded),
  addCircle(Icons.add_circle_outline_rounded),
  attachFile(Icons.attach_file_rounded),
  image(Icons.image_outlined),
  mic(Icons.mic_none_rounded),
  emoji(Icons.emoji_emotions_outlined),
  chat(Icons.chat_bubble_outline_rounded),
  lock(Icons.lock_outline_rounded),
  info(Icons.info_outline_rounded),
  done(Icons.done_rounded),
  doneAll(Icons.done_all_rounded),
  schedule(Icons.schedule_rounded),
  calendar(Icons.calendar_today_rounded),
  person(Icons.person_rounded),
  star(Icons.star_rounded),
  favorite(Icons.favorite_rounded),
  bolt(Icons.bolt_rounded);

  const StudioIcon(this.data);
  final IconData data;

  /// `Icons.search_rounded` style name for code.
  String get code => switch (this) {
        StudioIcon.manageSearch => 'Icons.manage_search_rounded',
        StudioIcon.expandLess => 'Icons.expand_less_rounded',
        StudioIcon.expandMore => 'Icons.expand_more_rounded',
        StudioIcon.arrowUpward => 'Icons.arrow_upward_rounded',
        StudioIcon.arrowDownward => 'Icons.arrow_downward_rounded',
        StudioIcon.addCircle => 'Icons.add_circle_outline_rounded',
        StudioIcon.attachFile => 'Icons.attach_file_rounded',
        StudioIcon.image => 'Icons.image_outlined',
        StudioIcon.mic => 'Icons.mic_none_rounded',
        StudioIcon.emoji => 'Icons.emoji_emotions_outlined',
        StudioIcon.chat => 'Icons.chat_bubble_outline_rounded',
        StudioIcon.lock => 'Icons.lock_outline_rounded',
        StudioIcon.info => 'Icons.info_outline_rounded',
        StudioIcon.doneAll => 'Icons.done_all_rounded',
        StudioIcon.calendar => 'Icons.calendar_today_rounded',
        StudioIcon.favorite => 'Icons.favorite_rounded',
        _ => 'Icons.${name}_rounded',
      };
}

/// The box around a part: colours, border, shadow, spacing and size.
class StudioBox {
  StudioBox({
    this.background = Colors.transparent,
    this.gradientTo,
    this.borderWidth = 0,
    this.borderColor = SiteColors.grey300,
    this.radius = 0,
    this.shadow = 0,
    this.paddingH = 0,
    this.paddingV = 0,
    this.marginH = 0,
    this.marginV = 0,
    this.height = 0,
    this.fill = true,
    this.align = StudioAlign.center,
  });

  Color background;
  Color? gradientTo; // a top-left to bottom-right gradient when set
  double borderWidth;
  Color borderColor;
  double radius;
  double shadow; // blur radius, 0 = none
  double paddingH;
  double paddingV;
  double marginH;
  double marginV;
  double height; // 0 = as tall as the content
  bool fill; // as wide as possible, or as wide as the content
  StudioAlign align; // where a box that does not fill sits

  StudioBox copy() => StudioBox(
        background: background,
        gradientTo: gradientTo,
        borderWidth: borderWidth,
        borderColor: borderColor,
        radius: radius,
        shadow: shadow,
        paddingH: paddingH,
        paddingV: paddingV,
        marginH: marginH,
        marginV: marginV,
        height: height,
        fill: fill,
        align: align,
      );
}

/// One piece of a part: a text, an icon, the input field, a button, ...
class StudioElement {
  StudioElement(
    this.kind, {
    this.visible = true,
    this.source = TextSource.literal,
    this.text = '',
    this.text2 = '',
    this.fontSize = 14,
    this.bold = false,
    this.color = SiteColors.grey900,
    this.background = Colors.transparent,
    this.radius = 0,
    this.icon = StudioIcon.star,
    this.icon2 = StudioIcon.doneAll,
    this.size = 20,
    this.action = ButtonAction.none,
    this.look = ButtonLook.icon,
    this.expand = false,
    this.use24h = false,
    this.weekday = true,
  });

  final ElementKind kind;
  bool visible;
  TextSource source;
  String text; // literal text, hint of a field, label of a button; when unread for readState
  String text2; // when read for readState
  double fontSize;
  bool bold;
  Color color; // text or icon colour
  Color background; // badge, filled button, field or avatar fill
  double radius; // corner radius; avatar: roundness 0..0.5
  StudioIcon icon;
  StudioIcon icon2; // read icon of the read indicator
  double size; // icon size, avatar size, spacer width, divider thickness
  ButtonAction action;
  ButtonLook look;
  bool expand; // spacer: take the remaining space
  bool use24h;
  bool weekday;

  StudioElement copy() => StudioElement(
        kind,
        visible: visible,
        source: source,
        text: text,
        text2: text2,
        fontSize: fontSize,
        bold: bold,
        color: color,
        background: background,
        radius: radius,
        icon: icon,
        icon2: icon2,
        size: size,
        action: action,
        look: look,
        expand: expand,
        use24h: use24h,
        weekday: weekday,
      );
}

/// The design of a part: elements laid out in a row or column inside a box.
class StudioSpec {
  StudioSpec({
    this.axis = StudioAxis.row,
    this.main = StudioAlign.start,
    this.cross = StudioAlign.center,
    this.gap = 0,
    required this.box,
    required this.elements,
  });

  StudioAxis axis;
  StudioAlign main;
  StudioAlign cross;
  double gap;
  StudioBox box;
  List<StudioElement> elements;

  StudioSpec copy() => StudioSpec(
        axis: axis,
        main: main,
        cross: cross,
        gap: gap,
        box: box.copy(),
        elements: [for (final e in elements) e.copy()],
      );
}

/// What a part allows: element kinds, text sources and button actions.
class PartRules {
  const PartRules({required this.kinds, required this.sources, this.actions = const []});

  final List<ElementKind> kinds;
  final List<TextSource> sources;
  final List<ButtonAction> actions;
}

// Only what does something in that part: the gap between elements replaces spacers, and a
// button needs an action the part has.
PartRules rulesOf(Part part) => switch (part) {
      // The bubble builder only gets the content (child), so no name or time.
      Part.bubble => const PartRules(kinds: [ElementKind.content], sources: []),
      Part.search => const PartRules(
          kinds: [ElementKind.field, ElementKind.button, ElementKind.badge, ElementKind.icon],
          sources: [TextSource.resultCount],
          actions: [ButtonAction.older, ButtonAction.newer, ButtonAction.close],
        ),
      Part.input => const PartRules(
          kinds: [ElementKind.field, ElementKind.button],
          sources: [],
          actions: [ButtonAction.send],
        ),
      Part.notice => const PartRules(
          kinds: [ElementKind.text, ElementKind.icon, ElementKind.avatar],
          sources: [TextSource.preview, TextSource.name, TextSource.noticeLabel, TextSource.literal],
        ),
      Part.separator => const PartRules(
          kinds: [ElementKind.text, ElementKind.icon, ElementKind.divider],
          sources: [TextSource.date],
        ),
      Part.time => const PartRules(
          kinds: [ElementKind.text, ElementKind.icon],
          sources: [TextSource.time],
        ),
      Part.profile => const PartRules(
          kinds: [ElementKind.avatar, ElementKind.text],
          sources: [TextSource.name],
        ),
      Part.read => const PartRules(
          kinds: [ElementKind.icon, ElementKind.text],
          sources: [TextSource.readState],
        ),
      Part.readOnly => const PartRules(
          kinds: [ElementKind.text, ElementKind.icon],
          sources: [TextSource.readOnlyLabel, TextSource.literal],
        ),
    };

/// A new element of [kind] for [part], with sensible values.
StudioElement newElement(Part part, ElementKind kind, {List<StudioElement> existing = const []}) {
  final rules = rulesOf(part);
  // A button gets an action the part does not have a button for yet.
  final used = {for (final e in existing) if (e.kind == ElementKind.button) e.action};
  final action = rules.actions.firstWhere((a) => !used.contains(a),
      orElse: () => rules.actions.isEmpty ? ButtonAction.none : rules.actions.first);
  return switch (kind) {
    ElementKind.content => StudioElement(kind, fontSize: 15),
    ElementKind.text => StudioElement(kind,
        source: rules.sources.first,
        text: part == Part.read ? '1' : 'Text',
        color: part == Part.read ? SiteColors.blue : SiteColors.grey900,
        fontSize: part == Part.read ? 11 : 14),
    ElementKind.icon => part == Part.read
        ? StudioElement(kind,
            icon: StudioIcon.done, icon2: StudioIcon.doneAll, size: 14, color: SiteColors.blue)
        : StudioElement(kind, icon: StudioIcon.star, color: SiteColors.grey500),
    ElementKind.field => StudioElement(kind,
        fontSize: 15, background: SiteColors.grey100, radius: 12),
    ElementKind.button => StudioElement(kind,
        action: action,
        icon: switch (action) {
          ButtonAction.older => StudioIcon.expandLess,
          ButtonAction.newer => StudioIcon.expandMore,
          ButtonAction.close => StudioIcon.close,
          _ => StudioIcon.send,
        },
        color: SiteColors.grey600,
        background: SiteColors.blue,
        radius: 999),
    ElementKind.badge => StudioElement(kind,
        source: rules.sources.first,
        text: 'New',
        fontSize: 12,
        color: Colors.white,
        background: SiteColors.blue,
        radius: 999),
    ElementKind.avatar => StudioElement(kind,
        size: 28, radius: 0.36, background: SiteColors.blueWeak, color: SiteColors.blue),
    ElementKind.spacer => StudioElement(kind, size: 8),
    ElementKind.divider => StudioElement(kind, size: 1, color: SiteColors.grey200),
  };
}

/// The design each part starts with when switched to custom.
StudioSpec defaultSpec(Part part, {bool receiver = false}) => switch (part) {
      Part.bubble => StudioSpec(
          box: StudioBox(
            background: receiver ? SiteColors.grey100 : SiteColors.blue,
            radius: 18,
            paddingH: 14,
            paddingV: 10,
            fill: false,
          ),
          elements: [
            StudioElement(ElementKind.content,
                fontSize: 15, color: receiver ? SiteColors.grey900 : Colors.white),
          ],
        ),
      Part.search => StudioSpec(
          gap: 4,
          box: StudioBox(
            background: SiteColors.grey900,
            radius: 14,
            shadow: 12,
            paddingH: 14,
            marginH: 16,
            marginV: 8,
            height: 44,
          ),
          elements: [
            StudioElement(ElementKind.icon,
                icon: StudioIcon.manageSearch, size: 20, color: Colors.white70),
            StudioElement(ElementKind.field, fontSize: 14, color: Colors.white),
            StudioElement(ElementKind.badge,
                source: TextSource.resultCount,
                fontSize: 12,
                color: Colors.white,
                background: Colors.white24,
                radius: 999),
            for (final (action, icon) in [
              (ButtonAction.older, StudioIcon.expandLess),
              (ButtonAction.newer, StudioIcon.expandMore),
              (ButtonAction.close, StudioIcon.close),
            ])
              StudioElement(ElementKind.button,
                  action: action, icon: icon, size: 20, color: Colors.white),
          ],
        ),
      Part.input => StudioSpec(
          gap: 8,
          box: StudioBox(paddingH: 16, paddingV: 12),
          elements: [
            StudioElement(ElementKind.field,
                fontSize: 15, background: SiteColors.grey100, radius: 999),
            StudioElement(ElementKind.button,
                action: ButtonAction.send,
                look: ButtonLook.filled,
                icon: StudioIcon.arrowUpward,
                size: 22,
                color: Colors.white,
                background: SiteColors.blue,
                radius: 999),
          ],
        ),
      // Who wrote what, in one line: avatar, name and a summary of the message.
      Part.notice => StudioSpec(
          gap: 8,
          box: StudioBox(
            background: SiteColors.grey900,
            radius: 999,
            shadow: 8,
            paddingH: 8,
            paddingV: 6,
            marginH: 16,
            marginV: 12,
            fill: false,
          ),
          elements: [
            StudioElement(ElementKind.avatar,
                size: 24, radius: 0.5, background: SiteColors.blueWeak, color: SiteColors.blue),
            StudioElement(ElementKind.text,
                source: TextSource.name, fontSize: 13, bold: true, color: Colors.white),
            StudioElement(ElementKind.text,
                source: TextSource.preview, fontSize: 13, color: Colors.white70),
            StudioElement(ElementKind.icon,
                icon: StudioIcon.arrowDownward, size: 16, color: Colors.white70),
          ],
        ),
      Part.separator => StudioSpec(
          box: StudioBox(
            background: SiteColors.grey100,
            radius: 999,
            paddingH: 12,
            paddingV: 4,
            marginV: 14,
            fill: false,
          ),
          elements: [
            StudioElement(ElementKind.text,
                source: TextSource.date, fontSize: 12, color: SiteColors.grey600),
          ],
        ),
      Part.time => StudioSpec(
          box: StudioBox(fill: false),
          elements: [
            StudioElement(ElementKind.text,
                source: TextSource.time, fontSize: 11, color: SiteColors.grey500),
          ],
        ),
      Part.profile => StudioSpec(
          axis: StudioAxis.column,
          gap: 4,
          box: StudioBox(paddingV: 3, fill: false),
          elements: [
            StudioElement(ElementKind.avatar,
                size: 28, radius: 0.36, background: SiteColors.blueWeak, color: SiteColors.blue),
            StudioElement(ElementKind.text,
                source: TextSource.name, fontSize: 13, bold: true, color: SiteColors.grey700),
          ],
        ),
      Part.read => StudioSpec(
          box: StudioBox(fill: false),
          elements: [
            StudioElement(ElementKind.icon,
                icon: StudioIcon.done, icon2: StudioIcon.doneAll, size: 14, color: SiteColors.blue),
          ],
        ),
      Part.readOnly => StudioSpec(
          main: StudioAlign.center,
          gap: 6,
          box: StudioBox(background: SiteColors.grey50, paddingH: 18, paddingV: 18),
          elements: [
            StudioElement(ElementKind.icon,
                icon: StudioIcon.lock, size: 16, color: SiteColors.grey500),
            StudioElement(ElementKind.text,
                source: TextSource.readOnlyLabel, fontSize: 14, color: SiteColors.grey500),
          ],
        ),
    };

/// `0xFF3182F6` style hex of [c], for code.
String hex(Color c) => '0x${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
