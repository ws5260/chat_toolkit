import 'package:flutter/foundation.dart';

import '../chat_controller.dart';

/// Finds the matches of [query] on your server.
///
/// Return the ids of the matching messages, newest first. The chat knows only
/// the loaded messages, so the search itself is up to your backend.
///
/// Return a message's id once per match in it, e.g. twice for "1" in "#411",
/// to step through its matches one at a time (see
/// [ChatSearchController.currentMatchIndex]). Returned once, the message is a
/// single result and all its matches are marked as current.
typedef ChatSearchCallback = Future<List<String>> Function(String query);

/// Loads the messages around [messageId] when it is not loaded.
///
/// Fetch them from your server and pass them to
/// [ChatController.setMessagesAround]. Use `highlight: false` there when the
/// search term is already marked in the text (see `SearchHighlightedText`).
typedef ChatSearchLoadAroundCallback = Future<void> Function(String messageId);

/// Search in a [Chat]: the query, its results and which one is shown.
///
/// The search runs on your server through [onSearch]. Showing a result
/// scrolls to it with [ChatController.scrollToMessage] when it is loaded,
/// and calls [onLoadAround] otherwise.
///
/// Pass it to `Chat.searchController` to get a search bar above the list
/// (see `ChatConfiguration.searchBarBuilder`) and keyboard shortcuts (see
/// `ChatConfiguration.searchShortcuts`). Every action is also a method here,
/// so the search can be driven by your own buttons, menus or key bindings:
///
/// ```dart
/// final search = ChatSearchController(
///   chatController: controller,
///   onSearch: (query) => api.search(roomId, query), // ids, newest first
///   onLoadAround: (id) async {
///     final page = await api.fetchAround(roomId, id);
///     await controller.setMessagesAround(
///       page.messages,
///       anchorMessageId: id,
///       hasNewerMessages: page.hasNewer,
///       highlight: false,
///     );
///   },
/// );
///
/// IconButton(onPressed: search.open, icon: const Icon(Icons.search));
/// ```
///
/// Call [dispose] when you no longer need it.
class ChatSearchController extends ChangeNotifier {
  /// Creates a search for the messages of [chatController].
  ChatSearchController({
    required this.chatController,
    required this.onSearch,
    required this.onLoadAround,
  });

  /// The chat whose messages are searched and scrolled to.
  final ChatController chatController;

  /// Runs the search on your server. See [ChatSearchCallback].
  final ChatSearchCallback onSearch;

  /// Loads a result that is not loaded. See [ChatSearchLoadAroundCallback].
  final ChatSearchLoadAroundCallback onLoadAround;

  bool _isOpen = false;
  bool _isSearching = false;
  String _query = '';
  List<String> _results = const [];
  int _index = -1;
  // Each search or move bumps it, so a slower earlier request does not win.
  int _request = 0;
  bool _disposed = false;

  /// Whether the search bar is shown.
  bool get isOpen => _isOpen;

  /// Whether [onSearch] is running.
  bool get isSearching => _isSearching;

  /// The query of the last [search], or `''` before any.
  String get query => _query;

  /// The results of [query], newest first: a message id per result, repeated
  /// in a row for a message with several matches (see [ChatSearchCallback]).
  List<String> get results => _results;

  /// Index of the shown result in [results], or `-1` when there is none.
  int get index => _index;

  /// Id of the shown result, or `null` when there is none.
  String? get currentMessageId => _index < 0 ? null : _results[_index];

  /// Which match in the message of the shown result is current, counted in
  /// reading order from `0`, or `null` when all its matches are (the message
  /// is listed once in [results]).
  ///
  /// [results] runs newest first, i.e. up the screen, so stepping to older
  /// results goes through a message's matches from its last to its first.
  int? get currentMatchIndex {
    if (_index < 0) return null;
    final id = _results[_index];
    var first = _index;
    while (first > 0 && _results[first - 1] == id) {
      first--;
    }
    var last = _index;
    while (last < _results.length - 1 && _results[last + 1] == id) {
      last++;
    }
    if (first == last) return null;
    return last - _index;
  }

  /// Whether [search] has run for the current [query] (results may be empty).
  bool get hasSearched => _searched;
  bool _searched = false;

  /// Whether an older result than the shown one exists.
  bool get hasOlder => _index >= 0 && _index < _results.length - 1;

  /// Whether a newer result than the shown one exists.
  bool get hasNewer => _index > 0;

  /// Changes whenever [open] is called, even while the search is open.
  ///
  /// [ChatSearchBar] focuses its field on it; listen to it in a search bar of
  /// your own to do the same.
  ValueListenable<int> get focusRequests => _focusRequests;
  final ValueNotifier<int> _focusRequests = ValueNotifier(0);

  /// Shows the search bar and asks it to focus its field.
  void open() {
    _focusRequests.value++;
    if (_isOpen) return;
    _isOpen = true;
    _notify();
  }

  /// Hides the search bar and clears the query and results.
  void close() {
    if (!_isOpen && !_searched) return;
    _isOpen = false;
    _request++;
    _pendingIndex = null;
    _query = '';
    _results = const [];
    _index = -1;
    _searched = false;
    _isSearching = false;
    _notify();
  }

  /// Searches [query] and shows its newest result.
  ///
  /// Searching the same query again shows the next older result instead,
  /// like pressing Enter again in a search field.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    if (_searched && trimmed == _query) {
      if (_results.isEmpty) return;
      return showResult((_index + 1) % _results.length);
    }
    final request = ++_request;
    _isOpen = true;
    _query = trimmed;
    _isSearching = true;
    _notify();
    final List<String> results;
    try {
      results = await onSearch(trimmed);
    } finally {
      if (request == _request) {
        _isSearching = false;
        _notify();
      }
    }
    if (request != _request) return;
    _results = List.unmodifiable(results);
    _searched = true;
    _index = -1;
    _notify();
    if (results.isNotEmpty) await showResult(0);
  }

  /// Shows the next older result. Does nothing at the oldest one.
  Future<void> showOlder() async {
    if (hasOlder) await showResult(_index + 1);
  }

  /// Shows the next newer result. Does nothing at the newest one.
  Future<void> showNewer() async {
    if (hasNewer) await showResult(_index - 1);
  }

  /// Shows result [index] of [results]: scrolls to it when it is loaded,
  /// otherwise calls [onLoadAround].
  ///
  /// Moves run one at a time. While one is running, only the latest
  /// requested result is shown after it, so quickly stepping through results
  /// never lets a slower earlier load win.
  Future<void> showResult(int index) async {
    if (index < 0 || index >= _results.length) return;
    _index = index;
    _notify();
    _pendingIndex = index;
    if (_moving) return;
    _moving = true;
    try {
      while (_pendingIndex != null && !_disposed) {
        final next = _pendingIndex!;
        _pendingIndex = null;
        if (next >= _results.length) break;
        final id = _results[next];
        if (chatController.containsMessageId(id)) {
          await chatController.scrollToMessage(id, highlight: false);
        } else {
          await onLoadAround(id);
        }
      }
    } finally {
      _moving = false;
    }
  }

  int? _pendingIndex;
  bool _moving = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _focusRequests.dispose();
    super.dispose();
  }
}
