import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:material_ui/material_ui.dart';

import '../site/site_theme.dart';
import 'studio_model.dart';

export 'studio_model.dart';

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

enum MenuKind { off, popup, sheet }

/// Every option the playground exposes. Changing [history], [latencyMs], [images] or [grouping]
/// reloads the room; the rest apply live. The chat always runs reversed (newest message at
/// offset 0).
class PlaygroundSettings {
  // Layout
  bool messagesStartAtTop = true;
  int appearMs = 250; // 0 = off
  ChatAlignment senderAlignment = ChatAlignment.end;
  double horizontalPadding = 24;
  double verticalPadding = 0;
  bool grouping = true;
  Color background = Colors.white;
  double maxWidth = 420; // >= unlimitedWidth means no limit

  bool get unlimited => maxWidth >= unlimitedWidth;

  // Parts designed in the studio
  /// Each part starts as the toolkit has it: its own widget, or nothing where the toolkit shows
  /// nothing (notice, read indicator). The input field has no toolkit widget, so it is custom.
  final Map<Part, Look> looks = {
    Part.bubble: Look.library,
    Part.search: Look.library,
    Part.input: Look.custom,
    Part.notice: Look.hidden,
    Part.separator: Look.library,
    Part.time: Look.library,
    Part.profile: Look.library,
    Part.read: Look.hidden,
    Part.readOnly: Look.library,
  };
  final Map<Part, StudioSpec> specs = {for (final p in Part.values) p: defaultSpec(p)};
  StudioSpec receiverBubble = defaultSpec(Part.bubble, receiver: true);

  Look look(Part part) => looks[part]!;
  StudioSpec spec(Part part) => specs[part]!;

  void reset(Part part) {
    specs[part] = defaultSpec(part);
    if (part == Part.bubble) receiverBubble = defaultSpec(Part.bubble, receiver: true);
  }

  /// Text colour and size of a part left to the toolkit (time, profile name, date separator,
  /// search field), through `timeStyle`, `profileNameStyle`, `dateSeparatorStyle` and
  /// `ChatSearchBar.style`. Unset: the toolkit's own.
  final Map<Part, Color> textColors = {};
  final Map<Part, double> textSizes = {};

  TextStyle? textStyle(Part part) => textColors[part] == null && textSizes[part] == null
      ? null
      : TextStyle(color: textColors[part], fontSize: textSizes[part]);

  // Other options
  bool myProfile = false;
  bool searchShortcuts = true;
  double scrollThreshold = 300;
  bool readOnly = false;
  MenuKind menu = MenuKind.popup;
  bool longPress = true;
  bool haptic = true;
  bool customSendingIndicator = false;
  bool confirmDeleteFailed = true;

  // Fake server
  PlaygroundHistory history = PlaygroundHistory.page;
  int latencyMs = 600;
  bool images = false;
  PlaygroundSendResult sendResult = PlaygroundSendResult.success;
  bool autoReply = true;
}

/// The bubble max width slider's end, meaning "no limit".
const double unlimitedWidth = 640;

const List<Color> chatBackgrounds = [
  Colors.white,
  SiteColors.grey50,
  Color(0xFFEFF4FA),
  Color(0xFFFBF7F0),
  Color(0xFFDCE6F2),
];
