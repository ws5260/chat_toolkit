import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../message/entity/message.dart';
import 'chat_search_controller.dart';

/// Makes a [ChatSearchController] available below a [Chat].
///
/// [Chat] adds it when `Chat.searchController` is set. Widgets that depend
/// on it rebuild whenever the search changes.
class ChatSearchScope extends InheritedNotifier<ChatSearchController> {
  /// Provides [controller] to [child].
  const ChatSearchScope({super.key, required ChatSearchController controller, required super.child})
    : super(notifier: controller);

  /// The nearest search controller, or `null` outside a [Chat] with one.
  static ChatSearchController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatSearchScope>()?.notifier;
}

/// Makes the message being built available to its [MessageElement]s.
///
/// [Chat] wraps every message in one, so `MessageElement.toWidget` can tell
/// which message it belongs to, e.g. to mark the current search result.
class ChatMessageScope extends InheritedWidget {
  /// Provides [message] to [child].
  const ChatMessageScope({super.key, required this.message, required super.child});

  /// The message being built.
  final Message message;

  /// The nearest message, or `null` outside a message of a [Chat].
  static Message? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatMessageScope>()?.message;

  @override
  bool updateShouldNotify(ChatMessageScope oldWidget) => message != oldWidget.message;
}

/// Text that marks the query of the enclosing [ChatSearchController].
///
/// Use it in `MessageElement.toWidget` for text messages. While a search is
/// shown, every match gets [matchStyle], and the current one gets
/// [currentMatchStyle]: the match at `ChatSearchController.currentMatchIndex`
/// in the current result's message, or all its matches when that is `null`.
/// Without a search it is a plain [Text].
///
/// Use one per message: the match index counts the matches of this text only.
///
/// ```dart
/// class TextElement extends MessageElement {
///   const TextElement(this.text);
///   final String text;
///
///   @override
///   Widget toWidget(BuildContext context) => SearchHighlightedText(text);
///
///   @override
///   TextElement copyWith() => TextElement(text);
/// }
/// ```
class SearchHighlightedText extends StatelessWidget {
  /// Creates text that marks the search query in [text].
  const SearchHighlightedText(
    this.text, {
    super.key,
    this.style,
    this.matchStyle,
    this.currentMatchStyle,
    this.maxLines,
    this.overflow,
  });

  /// The text to show.
  final String text;

  /// Style of the text. Inherits the surrounding [DefaultTextStyle] when
  /// `null`.
  final TextStyle? style;

  /// Style of a match. Defaults to a light yellow background.
  final TextStyle? matchStyle;

  /// Style of the current match. Defaults to an orange background.
  final TextStyle? currentMatchStyle;

  /// See [Text.maxLines].
  final int? maxLines;

  /// See [Text.overflow].
  final TextOverflow? overflow;

  static const _defaultMatchStyle = TextStyle(
    backgroundColor: Color(0xFFFFE58F),
    color: Color(0xFF191F28),
  );
  static const _defaultCurrentMatchStyle = TextStyle(
    backgroundColor: Color(0xFFFFB020),
    color: Color(0xFF191F28),
  );

  @override
  Widget build(BuildContext context) {
    final search = ChatSearchScope.maybeOf(context);
    final query = search != null && search.isOpen && search.hasSearched
        ? search.query.toLowerCase()
        : '';
    if (query.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }
    final message = ChatMessageScope.maybeOf(context);
    final isCurrent = message != null && message.id == search!.currentMessageId;
    final currentIndex = isCurrent ? search.currentMatchIndex : null;
    final current = currentMatchStyle ?? _defaultCurrentMatchStyle;
    final other = matchStyle ?? _defaultMatchStyle;

    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    var match = 0;
    for (var i = lower.indexOf(query); i >= 0; i = lower.indexOf(query, start), match++) {
      if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
      final style = isCurrent && (currentIndex == null || currentIndex == match) ? current : other;
      spans.add(TextSpan(text: text.substring(i, i + query.length), style: style));
      start = i + query.length;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Opens the search of the enclosing [Chat] and focuses its field.
class OpenChatSearchIntent extends Intent {
  /// Creates the intent.
  const OpenChatSearchIntent();
}

/// Closes the search of the enclosing [Chat].
class CloseChatSearchIntent extends Intent {
  /// Creates the intent.
  const CloseChatSearchIntent();
}

/// Shows the next older search result ([ChatSearchController.showOlder]).
class ShowOlderSearchResultIntent extends Intent {
  /// Creates the intent.
  const ShowOlderSearchResultIntent();
}

/// Shows the next newer search result ([ChatSearchController.showNewer]).
class ShowNewerSearchResultIntent extends Intent {
  /// Creates the intent.
  const ShowNewerSearchResultIntent();
}

/// The default keyboard shortcuts of the chat search, active while the
/// [Chat] is shown, wherever the focus is:
///
/// * Ctrl+F / ⌘F: open the search.
/// * Esc: close it.
/// * Ctrl+G / ⌘G or F3: next older result.
/// * Ctrl+Shift+G / ⌘⇧G or Shift+F3: next newer result.
///
/// In [ChatSearchBar] Enter also shows the next older result and
/// Shift+Enter the next newer one. Pass your own map to
/// `ChatConfiguration.searchShortcuts` to change them; `{}` turns them off.
///
/// A handled key is consumed, so for example the browser's own find does not
/// open on the web.
const Map<ShortcutActivator, Intent> defaultChatSearchShortcuts = {
  SingleActivator(LogicalKeyboardKey.keyF, control: true): OpenChatSearchIntent(),
  SingleActivator(LogicalKeyboardKey.keyF, meta: true): OpenChatSearchIntent(),
  SingleActivator(LogicalKeyboardKey.escape): CloseChatSearchIntent(),
  SingleActivator(LogicalKeyboardKey.keyG, control: true): ShowOlderSearchResultIntent(),
  SingleActivator(LogicalKeyboardKey.keyG, meta: true): ShowOlderSearchResultIntent(),
  SingleActivator(LogicalKeyboardKey.f3): ShowOlderSearchResultIntent(),
  SingleActivator(LogicalKeyboardKey.keyG, control: true, shift: true):
      ShowNewerSearchResultIntent(),
  SingleActivator(LogicalKeyboardKey.keyG, meta: true, shift: true): ShowNewerSearchResultIntent(),
  SingleActivator(LogicalKeyboardKey.f3, shift: true): ShowNewerSearchResultIntent(),
};

/// Runs the search intent bound to [event] in [shortcuts], if any and if it
/// applies now. Returns whether it ran. Used by [Chat].
bool handleChatSearchKey(
  KeyEvent event,
  Map<ShortcutActivator, Intent> shortcuts,
  ChatSearchController controller,
) {
  if (event is KeyUpEvent) return false;
  for (final MapEntry(key: activator, value: intent) in shortcuts.entries) {
    if (!activator.accepts(event, HardwareKeyboard.instance)) continue;
    switch (intent) {
      case OpenChatSearchIntent():
        controller.open();
        return true;
      case CloseChatSearchIntent() when controller.isOpen:
        controller.close();
        return true;
      case ShowOlderSearchResultIntent() when controller.hasOlder:
        controller.showOlder();
        return true;
      case ShowNewerSearchResultIntent() when controller.hasNewer:
        controller.showNewer();
        return true;
    }
  }
  return false;
}

/// Binds the search intents to [controller] below [child], so a custom
/// search bar can use `Actions.invoke`. Used by [Chat].
class ChatSearchActions extends StatelessWidget {
  /// Handles the search intents below [child] with [controller].
  const ChatSearchActions({super.key, required this.controller, required this.child});

  /// The search the intents act on.
  final ChatSearchController controller;

  /// The chat.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        OpenChatSearchIntent: CallbackAction<OpenChatSearchIntent>(
          onInvoke: (_) => controller.open(),
        ),
        CloseChatSearchIntent: _SearchAction<CloseChatSearchIntent>(
          enabled: () => controller.isOpen,
          onInvoke: controller.close,
        ),
        ShowOlderSearchResultIntent: _SearchAction<ShowOlderSearchResultIntent>(
          enabled: () => controller.hasOlder,
          onInvoke: controller.showOlder,
        ),
        ShowNewerSearchResultIntent: _SearchAction<ShowNewerSearchResultIntent>(
          enabled: () => controller.hasNewer,
          onInvoke: controller.showNewer,
        ),
      },
      child: child,
    );
  }
}

// Disabled actions let the key through, e.g. Esc while no search is shown.
class _SearchAction<T extends Intent> extends Action<T> {
  _SearchAction({required this.enabled, required this.onInvoke});

  final bool Function() enabled;
  final void Function() onInvoke;

  @override
  bool isEnabled(T intent) => enabled();

  @override
  Object? invoke(T intent) {
    onInvoke();
    return null;
  }
}

/// The default search bar of a [Chat] with a `Chat.searchController`.
///
/// A field with the result count, buttons for the older and newer result,
/// and a close button. Enter searches (or shows the next older result) and
/// Shift+Enter shows the next newer one. It takes the focus when the search
/// is opened.
///
/// Customize it through its parameters in
/// `ChatConfiguration.searchBarBuilder`, or build your own bar there with
/// the [ChatSearchController] it receives:
///
/// ```dart
/// ChatConfiguration(
///   searchBarBuilder: (context, search) => ChatSearchBar(
///     controller: search,
///     hintText: '대화 내용 검색',
///     noResultsText: '결과 없음',
///   ),
/// )
/// ```
class ChatSearchBar extends StatefulWidget {
  /// Creates a search bar for [controller].
  const ChatSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search',
    this.noResultsText = 'No results',
    this.resultCountBuilder,
    this.olderTooltip = 'Older result',
    this.newerTooltip = 'Newer result',
    this.closeTooltip = 'Close search',
    this.padding = const EdgeInsets.fromLTRB(16, 8, 8, 8),
    this.decoration,
    this.style,
  });

  /// The search it shows and drives.
  final ChatSearchController controller;

  /// Placeholder of the field.
  final String hintText;

  /// Shown when the search found nothing.
  final String noResultsText;

  /// Builds the result count from the 1-based [current] result and [total].
  /// Defaults to `current/total`.
  final String Function(int current, int total)? resultCountBuilder;

  /// Tooltip of the older result button.
  final String olderTooltip;

  /// Tooltip of the newer result button.
  final String newerTooltip;

  /// Tooltip of the close button.
  final String closeTooltip;

  /// Space around the bar.
  final EdgeInsetsGeometry padding;

  /// Decoration of the field. The result count is added as its suffix.
  /// Defaults to a filled, rounded field with a search icon.
  final InputDecoration? decoration;

  /// Style of the typed text.
  final TextStyle? style;

  @override
  State<ChatSearchBar> createState() => _ChatSearchBarState();
}

class _ChatSearchBarState extends State<ChatSearchBar> {
  late final TextEditingController _text = TextEditingController(text: widget.controller.query);
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.focusRequests.addListener(_focusField);
    // Opened just now: take the focus.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusField());
  }

  @override
  void didUpdateWidget(ChatSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.focusRequests.removeListener(_focusField);
      widget.controller.focusRequests.addListener(_focusField);
    }
  }

  void _focusField() {
    if (!mounted) return;
    _focus.requestFocus();
    _text.selection = TextSelection(baseOffset: 0, extentOffset: _text.text.length);
  }

  @override
  void dispose() {
    widget.controller.focusRequests.removeListener(_focusField);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = widget.controller;
    return ListenableBuilder(
      listenable: search,
      builder: (context, _) {
        final status = !search.hasSearched
            ? null
            : search.results.isEmpty
            ? widget.noResultsText
            : (widget.resultCountBuilder ?? _count)(search.index + 1, search.results.length);
        final decoration = (widget.decoration ?? _defaultDecoration()).copyWith(suffixText: status);
        return Padding(
          padding: widget.padding,
          child: Row(
            children: [
              Expanded(
                child: Shortcuts(
                  shortcuts: const {
                    SingleActivator(LogicalKeyboardKey.enter, shift: true):
                        ShowNewerSearchResultIntent(),
                  },
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
                    style: widget.style,
                    textInputAction: TextInputAction.search,
                    decoration: decoration,
                    onSubmitted: (value) {
                      search.search(value);
                      _focus.requestFocus();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: widget.olderTooltip,
                onPressed: search.hasOlder ? search.showOlder : null,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
              IconButton(
                tooltip: widget.newerTooltip,
                onPressed: search.hasNewer ? search.showNewer : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              IconButton(
                tooltip: widget.closeTooltip,
                onPressed: search.close,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _count(int current, int total) => '$current/$total';

  InputDecoration _defaultDecoration() => InputDecoration(
    isDense: true,
    hintText: widget.hintText,
    prefixIcon: const Icon(Icons.search_rounded, size: 18),
    filled: true,
    fillColor: const Color(0xFFF2F4F6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide.none,
    ),
  );
}
