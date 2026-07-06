part of '../main.dart';

// Code completion for the editor, driven by the in-process language server
// (`LspService.completion`). As you type an identifier (or press Ctrl/Cmd+Space)
// a popup of ranked proposals appears at the caret; Arrow keys move, Enter/Tab
// accept, Escape dismisses, and clicking a row inserts it.

const _completionMax = 60;

List<CompletionItem> _completionItems = const [];
int _completionSelected = 0;
bool _completionOpen = false;
int _completionWordStart = 0;
Timer? _completionDebounce;

/// Called from the editor's `input` handler: (re)trigger or dismiss completion
/// based on what was just typed.
void updateCompletionOnInput() {
  var ta = selectCodeTextArea();
  var text = ta.value;
  var caret = ta.selectionStart.toInt();
  if (caret == 0) {
    hideCompletionPopup();
    return;
  }
  var prev = text[caret - 1];
  if (_isIdentPart(prev) || prev == '.') {
    requestCompletion();
  } else {
    hideCompletionPopup();
  }
}

/// Requests completion at the caret (debounced unless [explicit]).
void requestCompletion({bool explicit = false}) {
  _completionDebounce?.cancel();
  _completionDebounce = Timer(
    Duration(milliseconds: explicit ? 0 : 130),
    () => _doCompletion(explicit),
  );
}

Future<void> _doCompletion(bool explicit) async {
  var ta = selectCodeTextArea();
  var text = ta.value;
  var caret = ta.selectionStart.toInt();

  // Identifier prefix immediately before the caret.
  var start = caret;
  while (start > 0 && _isIdentPart(text[start - 1])) {
    start--;
  }
  var prefix = text.substring(start, caret);

  if (!explicit && prefix.isEmpty) {
    // With no prefix, only auto-open right after a `.`.
    if (caret == 0 || text[caret - 1] != '.') {
      hideCompletionPopup();
      return;
    }
  }

  var pos = _positionOfOffset(text, caret);

  CompletionList list;
  try {
    list = await lsp.completion(_currentUri, pos).timeout(
        const Duration(seconds: 3),
        onTimeout: () => const CompletionList());
  } catch (_) {
    hideCompletionPopup();
    return;
  }

  // Bail if the buffer/caret moved while awaiting.
  if (ta.selectionStart.toInt() != caret || ta.value != text) return;

  var lower = prefix.toLowerCase();
  var items = [
    for (var it in list.items)
      if (prefix.isEmpty || it.label.toLowerCase().startsWith(lower)) it,
  ]..sort((a, b) => (a.sortText ?? a.label).compareTo(b.sortText ?? b.label));

  if (items.isEmpty) {
    hideCompletionPopup();
    return;
  }

  _completionWordStart = start;
  _showCompletionPopup(items, pos);
}

void _showCompletionPopup(List<CompletionItem> items, Position pos) {
  _completionItems = items;
  _completionSelected = 0;
  _completionOpen = true;

  var popup = selectCompletionPopup();
  var buf = StringBuffer();
  var count = items.length > _completionMax ? _completionMax : items.length;
  for (var i = 0; i < count; i++) {
    var it = items[i];
    var detail = (it.detail != null && it.detail!.isNotEmpty)
        ? '<span class="comp-detail">${_esc(it.detail!)}</span>'
        : '';
    buf.write('<div class="comp-row${i == 0 ? ' sel' : ''}" data-i="$i">'
        '<span class="comp-icon ${_completionClass(it.kind)}">${_completionIcon(it.kind)}</span>'
        '<span class="comp-label">${_esc(it.label)}</span>$detail</div>');
  }
  popup.innerHTML = buf.toString().toJS;
  popup.classList.remove('hidden');
  popup.scrollTop = 0;

  _positionCompletionPopup(pos);

  var rows = popup.querySelectorAll('.comp-row');
  for (var i = 0; i < rows.length; i++) {
    var row = rows.item(i) as HTMLElement;
    var idx = int.parse(row.getAttribute('data-i') ?? '0');
    // mousedown (not click) so the textarea keeps focus.
    _listen(row, 'mousedown', (event) {
      event.preventDefault();
      _completionSelected = idx;
      acceptCompletion();
    });
  }
}

void _positionCompletionPopup(Position pos) {
  var ta = selectCodeTextArea();
  var cs = window.getComputedStyle(ta);
  var rect = ta.getBoundingClientRect();
  var x = rect.left +
      _px(cs.paddingLeft) +
      pos.character * _charWidth(ta, cs) -
      ta.scrollLeft;
  var y = rect.top +
      _px(cs.paddingTop) +
      (pos.line + 1) * _lineHeight(ta) -
      ta.scrollTop;

  var maxX = window.innerWidth - 340;
  if (x > maxX) x = maxX.toDouble();
  if (x < 0) x = 0;

  var popup = selectCompletionPopup();
  popup.style.left = '${x}px';
  popup.style.top = '${y}px';
}

/// Handles a keydown while the popup is open. Returns true if it consumed the
/// event.
bool handleCompletionKeyDown(KeyboardEvent event) {
  if (!_completionOpen) return false;
  switch (event.key) {
    case 'ArrowDown':
      event.preventDefault();
      _moveCompletion(1);
      return true;
    case 'ArrowUp':
      event.preventDefault();
      _moveCompletion(-1);
      return true;
    case 'Enter':
    case 'Tab':
      event.preventDefault();
      acceptCompletion();
      return true;
    case 'Escape':
      event.preventDefault();
      hideCompletionPopup();
      return true;
    case 'ArrowLeft':
    case 'ArrowRight':
    case 'Home':
    case 'End':
      hideCompletionPopup();
      return false;
    default:
      return false;
  }
}

void _moveCompletion(int delta) {
  var n = _completionItems.length > _completionMax
      ? _completionMax
      : _completionItems.length;
  if (n == 0) return;
  _completionSelected = (_completionSelected + delta) % n;
  if (_completionSelected < 0) _completionSelected += n;

  var popup = selectCompletionPopup();
  var rows = popup.querySelectorAll('.comp-row');
  for (var i = 0; i < rows.length; i++) {
    (rows.item(i) as HTMLElement)
        .classList
        .toggle('sel', i == _completionSelected);
  }

  // Keep the selected row visible.
  const rowH = 22;
  var top = _completionSelected * rowH;
  if (top < popup.scrollTop) {
    popup.scrollTop = top.toDouble();
  } else if (top + rowH > popup.scrollTop + popup.clientHeight) {
    popup.scrollTop = (top + rowH - popup.clientHeight).toDouble();
  }
}

/// Inserts the selected proposal, replacing the identifier prefix.
void acceptCompletion() {
  if (_completionSelected >= _completionItems.length) {
    hideCompletionPopup();
    return;
  }
  var item = _completionItems[_completionSelected];
  var ta = selectCodeTextArea();
  var text = ta.value;
  var caret = ta.selectionStart.toInt();

  ta.value = text.substring(0, _completionWordStart) +
      item.label +
      text.substring(caret);
  var newCaret = _completionWordStart + item.label.length;
  ta.selectionStart = newCaret;
  ta.selectionEnd = newCaret;

  hideCompletionPopup();

  renderSyntax();
  renderDiagnosticsOverlay();
  updateCodeGutter();
  _syncScroll();
  updateCursorStatus();
  scheduleLspAnalysis();
}

void hideCompletionPopup() {
  _completionDebounce?.cancel();
  if (!_completionOpen) return;
  _completionOpen = false;
  _completionItems = const [];
  selectCompletionPopup().classList.add('hidden');
}

Position _positionOfOffset(String text, int offset) {
  var upTo = text.substring(0, offset);
  var line = '\n'.allMatches(upTo).length;
  var col = offset - (upTo.lastIndexOf('\n') + 1);
  return Position(line, col);
}

// CompletionItemKind values (LSP): method=2, function=3, constructor=4,
// field=5, variable=6, class=7, property=10, enum=13, keyword=14, enumMember=20.
String _completionClass(int kind) {
  switch (kind) {
    case 7:
      return 'sym-class';
    case 2:
    case 3:
    case 4:
      return 'sym-func';
    case 5:
    case 6:
    case 10:
      return 'sym-field';
    case 13:
    case 20:
      return 'sym-enum';
    case 14:
      return 'comp-keyword';
    default:
      return 'sym-other';
  }
}

String _completionIcon(int kind) {
  switch (kind) {
    case 7:
      return 'C';
    case 2:
    case 3:
      return 'ƒ';
    case 4:
      return '⊕';
    case 5:
    case 10:
      return '▪';
    case 6:
      return 'v';
    case 13:
      return 'E';
    case 20:
      return 'e';
    case 14:
      return 'K';
    default:
      return '•';
  }
}
