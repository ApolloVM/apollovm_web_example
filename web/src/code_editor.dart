part of '../main.dart';

/// Wires up the code editor: a line-number gutter (with diagnostic markers), a
/// squiggle overlay layer behind the textarea, scroll sync, Tab/Shift+Tab
/// indentation, hover info, and live cursor position — the IDE-like behaviour.
void setupCodeEditor() {
  var codeTextArea = selectCodeTextArea();

  _listen(codeTextArea, 'input', (_) {
    renderSyntax();
    renderDiagnosticsOverlay();
    updateCodeGutter();
    _syncScroll();
    updateCursorStatus();
    scheduleLspAnalysis();
    updateCompletionOnInput();
  });

  _listen(codeTextArea, 'scroll', (_) {
    _syncScroll();
    hideCompletionPopup();
  });

  _listen(codeTextArea, 'keydown',
      (event) => handleCodeEditorKeyDown(event as KeyboardEvent));

  _listen(codeTextArea, 'keyup', (_) => updateCursorStatus());
  _listen(codeTextArea, 'click', (_) {
    updateCursorStatus();
    hideCompletionPopup();
  });
  _listen(codeTextArea, 'blur', (_) => hideCompletionPopup());

  _listen(codeTextArea, 'mousemove', (event) {
    var m = event as MouseEvent;
    handleEditorHover(m.offsetX, m.offsetY, m.clientX, m.clientY);
  });
  _listen(codeTextArea, 'mouseleave', (_) => hideHoverTip());
}

/// Sets the editor content and refreshes syntax colors, gutter, overlay, cursor.
void setCodeEditorText(String text) {
  selectCodeTextArea().value = text;
  renderSyntax();
  renderDiagnosticsOverlay();
  updateCodeGutter();
  _syncScroll();
  updateCursorStatus();
}

/// Rebuilds the syntax-highlight layer for the current buffer + language.
void renderSyntax() {
  var code = selectCodeTextArea().value;
  selectCodeSyntax().innerHTML =
      highlightCode(code, _currentBufferLanguage).toJS;
}

/// Rebuilds the gutter: one numbered line each, marked with a colored dot when
/// a diagnostic starts on that line.
void updateCodeGutter() {
  var codeTextArea = selectCodeTextArea();
  var gutter = selectCodeGutter();

  var lineCount = '\n'.allMatches(codeTextArea.value).length + 1;

  // Worst (lowest severity number) diagnostic per line.
  var lineSev = <int, int>{};
  for (var d in _diagnostics) {
    var l = d.range.start.line;
    var s = d.severity;
    if (!lineSev.containsKey(l) || s < lineSev[l]!) lineSev[l] = s;
  }

  var buf = StringBuffer();
  for (var i = 0; i < lineCount; i++) {
    var cls = 'gln';
    if (lineSev.containsKey(i)) cls += ' ${_severityClass(lineSev[i]!)}';
    buf.write('<div class="$cls">${i + 1}</div>');
  }
  gutter.innerHTML = buf.toString().toJS;
  gutter.scrollTop = codeTextArea.scrollTop;
}

/// Rebuilds the squiggle overlay: a transparent-text mirror of the code where
/// diagnostic ranges get a wavy underline that lines up under the textarea.
void renderDiagnosticsOverlay() {
  var code = selectCodeTextArea().value;
  var hl = selectCodeHighlight();

  if (_diagnostics.isEmpty) {
    hl.innerHTML = _escForPre(code).toJS;
    return;
  }

  var starts = _lineStarts(code);
  var sev = List<int>.filled(code.length, 0);
  for (var d in _diagnostics) {
    var s = _offsetOfPosition(starts, code.length, d.range.start);
    var e = _offsetOfPosition(starts, code.length, d.range.end);
    if (e <= s) e = (s + 1).clamp(0, code.length).toInt();
    for (var i = s; i < e && i < code.length; i++) {
      if (sev[i] == 0 || d.severity < sev[i]) sev[i] = d.severity;
    }
  }

  var buf = StringBuffer();
  var i = 0;
  while (i < code.length) {
    var s = sev[i];
    var j = i;
    var run = StringBuffer();
    while (j < code.length && sev[j] == s) {
      run.write(code[j]);
      j++;
    }
    if (s == 0) {
      buf.write(_escForPre(run.toString()));
    } else {
      buf.write(
          '<span class="sq ${_severityClass(s)}">${_escForPre(run.toString())}</span>');
    }
    i = j;
  }
  hl.innerHTML = buf.toString().toJS;
}

/// Keeps the gutter and squiggle overlay aligned with the textarea's scroll.
void _syncScroll() {
  var ta = selectCodeTextArea();
  selectCodeGutter().scrollTop = ta.scrollTop;
  var transform = 'translate(${-ta.scrollLeft}px, ${-ta.scrollTop}px)';
  selectCodeSyntax().style.transform = transform;
  selectCodeHighlight().style.transform = transform;
}

/// Updates the `Ln x, Col y` status-bar readout from the caret position.
void updateCursorStatus() {
  var ta = selectCodeTextArea();
  var text = ta.value;
  var idx = ta.selectionStart.clamp(0, text.length).toInt();
  var upTo = text.substring(0, idx);
  var line = '\n'.allMatches(upTo).length;
  var col = idx - (upTo.lastIndexOf('\n') + 1);
  selectStatusCursor().textContent = 'Ln ${line + 1}, Col ${col + 1}';
}

/// Moves the caret to [pos] and scrolls it into view.
void jumpToPosition(Position pos) {
  var ta = selectCodeTextArea();
  ta.focus();

  var offset = _offsetOfPosition(_lineStarts(ta.value), ta.value.length, pos);
  ta.selectionStart = offset;
  ta.selectionEnd = offset;

  var lineHeight = _lineHeight(ta);
  var target = pos.line * lineHeight - ta.clientHeight / 3;
  ta.scrollTop = target < 0 ? 0.0 : target;

  _syncScroll();
  updateCursorStatus();
}

/// Selects the text spanning [range] in the editor and scrolls its start into
/// view.
void selectRange(Range range) {
  var ta = selectCodeTextArea();
  ta.focus();

  var starts = _lineStarts(ta.value);
  var length = ta.value.length;
  var start = _offsetOfPosition(starts, length, range.start);
  var end = _offsetOfPosition(starts, length, range.end);
  ta.selectionStart = start;
  ta.selectionEnd = end;

  var lineHeight = _lineHeight(ta);
  var target = range.start.line * lineHeight - ta.clientHeight / 3;
  ta.scrollTop = target < 0 ? 0.0 : target;

  _syncScroll();
  updateCursorStatus();
}

// ---- Hover tooltip ----

void showHoverTip(String html, num clientX, num clientY) {
  var tip = selectHoverTip();
  tip.innerHTML = html.toJS;
  tip.classList.remove('hidden');
  tip.style.left = '${clientX + 14}px';
  tip.style.top = '${clientY + 18}px';
}

void hideHoverTip() {
  _hoverDebounce?.cancel();
  selectHoverTip().classList.add('hidden');
}

/// Maps editor pixel coordinates (relative to the textarea padding box) to an
/// LSP [Position]. Exact because the editor font is monospace.
Position? editorPositionAt(num offsetX, num offsetY) {
  var ta = selectCodeTextArea();
  var cs = window.getComputedStyle(ta);

  var padL = _px(cs.paddingLeft);
  var padT = _px(cs.paddingTop);
  var charW = _charWidth(ta, cs);
  var lineH = _lineHeight(ta);
  if (charW <= 0 || lineH <= 0) return null;

  var textX = offsetX - padL + ta.scrollLeft;
  var textY = offsetY - padT + ta.scrollTop;
  if (textX < 0 || textY < 0) return null;

  var lines = ta.value.split('\n');
  var line = (textY ~/ lineH);
  if (line < 0 || line >= lines.length) return null;

  var col = (textX / charW).round();
  if (col < 0) col = 0;
  if (col > lines[line].length) return null; // past end of line: no symbol

  return Position(line, col);
}

double _charWidthCache = 0;

double _charWidth(HTMLTextAreaElement ta, CSSStyleDeclaration cs) {
  if (_charWidthCache > 0) return _charWidthCache;
  var span = document.createElement('span') as HTMLSpanElement;
  span.style.position = 'absolute';
  span.style.visibility = 'hidden';
  span.style.whiteSpace = 'pre';
  span.style.fontFamily = cs.fontFamily;
  span.style.fontSize = cs.fontSize;
  const sample = 'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM'; // 40 chars
  span.textContent = sample;
  document.body!.appendChild(span);
  _charWidthCache = span.getBoundingClientRect().width / sample.length;
  span.remove();
  return _charWidthCache;
}

double _lineHeight(HTMLTextAreaElement ta) {
  var lh = window.getComputedStyle(ta).lineHeight;
  var v = _px(lh);
  if (v > 0) return v;
  var fs = _px(window.getComputedStyle(ta).fontSize);
  return fs > 0 ? fs * 1.5 : 21;
}

double _px(String value) {
  var m = RegExp(r'([\d.]+)').firstMatch(value);
  return m != null ? double.tryParse(m.group(1)!) ?? 0 : 0;
}

// ---- Offset helpers ----

List<int> _lineStarts(String s) {
  var starts = <int>[0];
  for (var i = 0; i < s.length; i++) {
    if (s[i] == '\n') starts.add(i + 1);
  }
  return starts;
}

int _offsetOfPosition(List<int> lineStarts, int length, Position pos) {
  if (pos.line >= lineStarts.length) return length;
  var offset = lineStarts[pos.line] + pos.character;
  return offset.clamp(0, length).toInt();
}

String _escForPre(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

const _indent = '  ';

void handleCodeEditorKeyDown(KeyboardEvent event) {
  // Let an open completion popup handle navigation/accept first.
  if (handleCompletionKeyDown(event)) return;

  // Ctrl/Cmd+Space explicitly triggers completion.
  if ((event.ctrlKey || event.metaKey) && event.key == ' ') {
    event.preventDefault();
    requestCompletion(explicit: true);
    return;
  }

  if (event.key != 'Tab') return;
  event.preventDefault();

  var codeTextArea = selectCodeTextArea();
  var value = codeTextArea.value;
  var start = codeTextArea.selectionStart;
  var end = codeTextArea.selectionEnd;

  var lineStart = value.lastIndexOf('\n', start - 1) + 1;

  if (event.shiftKey) {
    // Dedent the current line.
    var line = value.substring(lineStart);
    var removed = 0;
    if (line.startsWith(_indent)) {
      removed = _indent.length;
    } else if (line.startsWith(' ') || line.startsWith('\t')) {
      removed = 1;
    }
    if (removed == 0) return;

    codeTextArea.value =
        value.substring(0, lineStart) + value.substring(lineStart + removed);
    var newStart = start - removed < lineStart ? lineStart : start - removed;
    codeTextArea.selectionStart = newStart;
    codeTextArea.selectionEnd =
        end - removed < lineStart ? lineStart : end - removed;
  } else {
    // Insert indentation at the caret.
    codeTextArea.value =
        value.substring(0, start) + _indent + value.substring(end);
    codeTextArea.selectionStart =
        codeTextArea.selectionEnd = start + _indent.length;
  }

  renderSyntax();
  renderDiagnosticsOverlay();
  updateCodeGutter();
  updateCursorStatus();
  scheduleLspAnalysis();
}
