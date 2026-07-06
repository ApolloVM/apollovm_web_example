part of '../main.dart';

// In-process ApolloVM Language Server integration (web-safe, no `dart:io`).
//
// A single [LspService] runs an ApolloVM `LspServer`/`LspClient` pair entirely
// in the browser. As the editor buffer changes we re-analyze (debounced) and
// surface the results the way an IDE does: red/yellow squiggles + a Problems
// list (diagnostics), an Outline tree (document symbols), a hover card
// (hover), and live error/warning counts in the status bar.

/// The shared in-process language service, created lazily on first use.
LspService? _lspService;
LspService get lsp => _lspService ??= LspService();

/// The current diagnostics for the open buffer (drives squiggles + Problems).
List<Diagnostic> _diagnostics = const [];

/// The URI the buffer is currently analyzed under (its extension selects the
/// ApolloVM parser).
String _lspOpenUri = '';

/// Maps an editor language id to a document URI whose file extension the LSP
/// analyzer uses to pick a parser.
String lspUriForLanguage(String language) {
  switch (language) {
    case 'java11':
    case 'java':
      return 'file:///Main.java';
    case 'kotlin':
      return 'file:///Main.kt';
    case 'csharp':
      return 'file:///Main.cs';
    case 'javascript':
      return 'file:///main.js';
    case 'typescript':
      return 'file:///main.ts';
    case 'lua':
      return 'file:///main.lua';
    case 'python':
      return 'file:///main.py';
    case 'dart':
    default:
      return 'file:///main.dart';
  }
}

/// The file name shown on the editor tab for [language].
String fileNameForLanguage(String language) =>
    lspUriForLanguage(language).split('/').last;

/// The language the buffer is actually written in (the editor's `language`
/// attribute is the source of truth; the select can differ during a failed
/// conversion).
String get _currentBufferLanguage {
  var attr = selectCodeTextArea().getAttribute('language');
  return (attr != null && attr.isNotEmpty) ? attr : selectCodeLanguage().value;
}

String get _currentUri => lspUriForLanguage(_currentBufferLanguage);

Timer? _lspDebounce;

/// Schedules a debounced re-analysis of the current buffer.
void scheduleLspAnalysis() {
  _lspDebounce?.cancel();
  _lspDebounce = Timer(const Duration(milliseconds: 300), runLspAnalysis);
}

/// Analyzes the current buffer and refreshes diagnostics, the outline and the
/// status bar. Safe to call directly (e.g. right after loading an example).
Future<void> runLspAnalysis() async {
  _lspDebounce?.cancel();

  var uri = _currentUri;
  var code = selectCodeTextArea().value;

  // Language switched: drop the previous document so its diagnostics clear.
  if (_lspOpenUri.isNotEmpty && _lspOpenUri != uri && lsp.isOpen(_lspOpenUri)) {
    lsp.close(_lspOpenUri);
  }
  _lspOpenUri = uri;

  List<Diagnostic> diags;
  try {
    diags = await lsp
        .analyze(uri, code)
        .timeout(const Duration(seconds: 4), onTimeout: () => const []);
  } catch (_) {
    diags = const [];
  }

  // Ignore a stale result if the user kept typing / switched language.
  if (uri != _currentUri || code != selectCodeTextArea().value) return;

  _setDiagnostics(diags);
  await _refreshOutline(uri);
}

void _setDiagnostics(List<Diagnostic> diags) {
  // Errors first, then by position — matches how editors order the Problems list.
  _diagnostics = [...diags]..sort((a, b) {
      var s = a.severity.compareTo(b.severity);
      if (s != 0) return s;
      var l = a.range.start.line.compareTo(b.range.start.line);
      return l != 0 ? l : a.range.start.character.compareTo(b.range.start.character);
    });

  renderDiagnosticsOverlay(); // squiggles (code_editor.dart)
  updateCodeGutter(); // gutter error/warning dots
  _renderProblems();
  _updateStatusDiagnostics();
}

int get _errorCount =>
    _diagnostics.where((d) => d.severity == DiagnosticSeverity.error).length;
int get _warningCount =>
    _diagnostics.where((d) => d.severity == DiagnosticSeverity.warning).length;

// ---- Problems panel ----

void _renderProblems() {
  var list = selectProblemsList();

  selectProblemsBadge().textContent = '${_diagnostics.length}';

  if (_diagnostics.isEmpty) {
    list.innerHTML =
        '<div class="problems-empty">No problems detected in the buffer.</div>'
            .toJS;
    return;
  }

  var rows = <String>[];
  for (var i = 0; i < _diagnostics.length; i++) {
    var d = _diagnostics[i];
    var sev = _severityClass(d.severity);
    var icon = _severityIcon(d.severity);
    var ln = d.range.start.line + 1;
    var col = d.range.start.character + 1;
    rows.add('''
<div class="problem-row" data-diag="$i">
  <span class="problem-icon $sev">$icon</span>
  <span class="problem-msg">${_esc(d.message)}</span>
  <span class="problem-loc">[$ln:$col]</span>
</div>''');
  }
  list.innerHTML = rows.join().toJS;

  var nodes = list.querySelectorAll('.problem-row');
  for (var i = 0; i < nodes.length; i++) {
    var row = nodes.item(i) as HTMLElement;
    var idx = int.parse(row.getAttribute('data-diag') ?? '0');
    _listen(row, 'click', (_) => jumpToPosition(_diagnostics[idx].range.start));
  }
}

void _updateStatusDiagnostics() {
  selectStatusErrors().textContent = '$_errorCount';
  selectStatusWarnings().textContent = '$_warningCount';
}

// ---- Outline (document symbols) ----

Future<void> _refreshOutline(String uri) async {
  List<DocumentSymbol> symbols;
  try {
    symbols = await lsp
        .documentSymbols(uri)
        .timeout(const Duration(seconds: 4), onTimeout: () => const []);
  } catch (_) {
    symbols = const [];
  }
  if (uri != _currentUri) return;

  var outline = selectOutline();
  if (symbols.isEmpty) {
    outline.innerHTML =
        '<div class="outline-empty">No symbols.</div>'.toJS;
    return;
  }

  var buf = StringBuffer();
  _flatSymbols = [];
  for (var s in symbols) {
    _renderSymbol(s, 0, buf);
  }
  outline.innerHTML = buf.toString().toJS;

  var nodes = outline.querySelectorAll('.outline-row');
  for (var i = 0; i < nodes.length; i++) {
    var row = nodes.item(i) as HTMLElement;
    var idx = int.parse(row.getAttribute('data-sym') ?? '0');
    _listen(
        row, 'click', (_) => jumpToPosition(_flatSymbols[idx].selectionRange.start));
  }
}

/// Flattened symbols, indexed by the `data-sym` attribute on each outline row.
List<DocumentSymbol> _flatSymbols = [];

void _renderSymbol(DocumentSymbol s, int depth, StringBuffer buf) {
  var idx = _flatSymbols.length;
  _flatSymbols.add(s);

  var pad = 8 + depth * 14;
  var detail = (s.detail != null && s.detail!.isNotEmpty)
      ? '<span class="outline-detail">${_esc(s.detail!)}</span>'
      : '';
  buf.write('''
<div class="outline-row" data-sym="$idx" style="padding-left: ${pad}px">
  <span class="outline-icon ${_symbolClass(s.kind)}">${_symbolIcon(s.kind)}</span>
  <span class="outline-name">${_esc(s.name)}</span>$detail
</div>''');

  for (var c in s.children) {
    _renderSymbol(c, depth + 1, buf);
  }
}

// ---- Hover ----

Timer? _hoverDebounce;

/// Handles a hover: `offsetX/offsetY` are relative to the textarea (used to map
/// to an LSP position); `clientX/clientY` are viewport coords (used to place the
/// tooltip).
void handleEditorHover(num offsetX, num offsetY, num clientX, num clientY) {
  _hoverDebounce?.cancel();

  var pos = editorPositionAt(offsetX, offsetY);
  if (pos == null) {
    hideHoverTip();
    return;
  }

  // A diagnostic under the cursor wins — show its message immediately.
  var diag = _diagnosticAt(pos);
  if (diag != null) {
    showHoverTip(
      '<span class="hover-sev ${_severityClass(diag.severity)}">'
      '${_severityIcon(diag.severity)}</span> ${_esc(diag.message)}',
      clientX,
      clientY,
    );
    return;
  }

  // Otherwise ask the language server for hover info (debounced).
  _hoverDebounce = Timer(const Duration(milliseconds: 120), () async {
    Hover? hover;
    try {
      hover = await lsp.hover(_currentUri, pos);
    } catch (_) {
      hover = null;
    }
    var value = hover?.contents.value.trim() ?? '';
    if (value.isEmpty) {
      hideHoverTip();
      return;
    }
    showHoverTip(
        '<pre class="hover-body">${_esc(value)}</pre>', clientX, clientY);
  });
}

Diagnostic? _diagnosticAt(Position pos) {
  for (var d in _diagnostics) {
    if (_rangeContains(d.range, pos)) return d;
  }
  return null;
}

bool _rangeContains(Range r, Position p) {
  bool afterStart = p.line > r.start.line ||
      (p.line == r.start.line && p.character >= r.start.character);
  bool beforeEnd = p.line < r.end.line ||
      (p.line == r.end.line && p.character <= r.end.character);
  // Zero-width ranges: match the single character at the start.
  if (r.start.line == r.end.line && r.start.character == r.end.character) {
    return p.line == r.start.line && p.character == r.start.character;
  }
  return afterStart && beforeEnd;
}

// ---- Severity / symbol presentation ----

String _severityClass(int severity) {
  switch (severity) {
    case DiagnosticSeverity.error:
      return 'sev-error';
    case DiagnosticSeverity.warning:
      return 'sev-warning';
    default:
      return 'sev-info';
  }
}

String _severityIcon(int severity) {
  switch (severity) {
    case DiagnosticSeverity.error:
      return '✖';
    case DiagnosticSeverity.warning:
      return '⚠';
    default:
      return 'ℹ';
  }
}

String _symbolClass(int kind) {
  switch (kind) {
    case SymbolKind.classKind:
      return 'sym-class';
    case SymbolKind.method:
    case SymbolKind.function:
    case SymbolKind.constructor:
      return 'sym-func';
    case SymbolKind.field:
    case SymbolKind.property:
    case SymbolKind.variable:
      return 'sym-field';
    case SymbolKind.enumKind:
    case SymbolKind.enumMember:
      return 'sym-enum';
    default:
      return 'sym-other';
  }
}

String _symbolIcon(int kind) {
  switch (kind) {
    case SymbolKind.classKind:
      return 'C';
    case SymbolKind.method:
    case SymbolKind.function:
      return 'ƒ';
    case SymbolKind.constructor:
      return '⊕';
    case SymbolKind.field:
    case SymbolKind.property:
      return '▪';
    case SymbolKind.variable:
      return 'v';
    case SymbolKind.enumKind:
      return 'E';
    case SymbolKind.enumMember:
      return 'e';
    case SymbolKind.namespace:
      return '{}';
    default:
      return '•';
  }
}

/// HTML-escapes [s] for safe interpolation into element `innerHTML`.
String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
