part of '../main.dart';

// A small, language-aware syntax highlighter. It renders the code as colored
// token `<span>`s into a layer behind the (transparent-text) textarea, so the
// editor shows syntax colors that adapt to the selected language.
//
// It is deliberately lightweight — a single generic scanner parameterized per
// language (comment styles, string delimiters, keyword/type sets) rather than a
// full grammar. Good enough for a playground; every character is preserved so
// the colored layer lines up exactly under the editable text.

class _LangSyntax {
  final Set<String> keywords;
  final Set<String> types;
  final List<String> lineComments;
  final String? blockOpen;
  final String? blockClose;
  final bool triple; // ''' / """ multiline strings (Dart, Python, Kotlin)
  final bool backtick; // ` template strings (JS/TS)
  final bool luaLongStrings; // [[ ... ]]

  const _LangSyntax({
    required this.keywords,
    required this.types,
    this.lineComments = const ['//'],
    this.blockOpen = '/*',
    this.blockClose = '*/',
    this.triple = false,
    this.backtick = false,
    this.luaLongStrings = false,
  });
}

Set<String> _words(String s) => s.split(RegExp(r'\s+')).toSet();

final Map<String, _LangSyntax> _langSyntaxes = {
  'dart': _LangSyntax(
    triple: true,
    keywords: _words(
      'abstract as assert async await break case catch class const continue '
      'covariant default deferred do dynamic else enum export extends extension '
      'external factory false final finally for get hide if implements import in '
      'interface is late library mixin new null on operator part required rethrow '
      'return set show static super switch sync this throw true try typedef var '
      'void while with yield Function',
    ),
    types: _words(
      'int double num String bool Object List Map Set Iterable Future Stream '
      'Runes Symbol Duration DateTime',
    ),
  ),
  'java': _LangSyntax(
    keywords: _words(
      'abstract assert boolean break byte case catch char class const continue '
      'default do double else enum extends final finally float for goto if '
      'implements import instanceof int interface long native new package private '
      'protected public return short static strictfp super switch synchronized '
      'this throw throws transient try var void volatile while true false null',
    ),
    types: _words(
      'String Integer Boolean Object List Map System Double Long Float Character '
      'Exception StringBuilder Math ArrayList HashMap',
    ),
  ),
  'kotlin': _LangSyntax(
    triple: true,
    keywords: _words(
      'package import class interface fun val var if else when for while do '
      'return break continue object companion data sealed enum override open '
      'abstract final private protected public internal in is as null true false '
      'this super throw try catch finally constructor init by get set vararg '
      'inline lateinit typealias out suspend',
    ),
    types: _words(
      'Int String Boolean Double Long Float Char Any Unit List Map Set Array '
      'MutableList MutableMap Pair',
    ),
  ),
  'javascript': _LangSyntax(
    backtick: true,
    keywords: _words(
      'var let const function return if else for while do switch case default '
      'break continue new delete typeof instanceof in of this class extends super '
      'import export from as try catch finally throw async await yield null '
      'undefined true false void static get set',
    ),
    types: _words(
      'Object Array String Number Boolean Map Set Promise Math JSON',
    ),
  ),
  'typescript': _LangSyntax(
    backtick: true,
    keywords: _words(
      'var let const function return if else for while do switch case default '
      'break continue new delete typeof instanceof in of this class extends super '
      'import export from as try catch finally throw async await yield null '
      'undefined true false interface type enum implements private public '
      'protected readonly abstract namespace declare keyof static get set',
    ),
    types: _words(
      'number string boolean any unknown never void object Object Array Map Set '
      'Promise Record',
    ),
  ),
  'csharp': _LangSyntax(
    keywords: _words(
      'abstract as base bool break byte case catch char checked class const '
      'continue decimal default delegate do double else enum event explicit extern '
      'false finally fixed float for foreach goto if implicit in int interface '
      'internal is lock long namespace new null object operator out override params '
      'private protected public readonly ref return sbyte sealed short sizeof '
      'stackalloc static string struct switch this throw true try typeof uint ulong '
      'unchecked unsafe ushort using var virtual void volatile while async await '
      'get set value',
    ),
    types: _words(
      'String Int32 Boolean Object List Dictionary Console Math Exception Task '
      'IEnumerable StringBuilder',
    ),
  ),
  'lua': _LangSyntax(
    lineComments: ['--'],
    blockOpen: '--[[',
    blockClose: ']]',
    luaLongStrings: true,
    keywords: _words(
      'and break do else elseif end false for function goto if in local nil not '
      'or repeat return then true until while',
    ),
    types: _words('string table math io os coroutine'),
  ),
  'python': _LangSyntax(
    lineComments: ['#'],
    blockOpen: null,
    blockClose: null,
    triple: true,
    keywords: _words(
      'and as assert async await break class continue def del elif else except '
      'False finally for from global if import in is lambda None nonlocal not or '
      'pass raise return True try while with yield',
    ),
    types: _words(
      'int float str bool list dict set tuple bytes object range print len',
    ),
  ),
};

_LangSyntax _syntaxFor(String language) {
  if (language == 'java11') return _langSyntaxes['java']!;
  return _langSyntaxes[language] ?? _langSyntaxes['dart']!;
}

bool _isDigit(String c) => c.compareTo('0') >= 0 && c.compareTo('9') <= 0;
bool _isIdentStart(String c) =>
    (c.compareTo('a') >= 0 && c.compareTo('z') <= 0) ||
    (c.compareTo('A') >= 0 && c.compareTo('Z') <= 0) ||
    c == '_' ||
    c == r'$';
bool _isIdentPart(String c) => _isIdentStart(c) || _isDigit(c);
bool _isUpper(String c) => c.compareTo('A') >= 0 && c.compareTo('Z') <= 0;

/// Renders [code] as syntax-highlighted HTML for [language].
String highlightCode(String code, String language) {
  var lang = _syntaxFor(language);
  var n = code.length;
  var out = StringBuffer();
  var i = 0;

  void span(String cls, int start, int end) {
    out.write('<span class="$cls">');
    out.write(_escForPre(code.substring(start, end)));
    out.write('</span>');
  }

  bool at(String s) => code.startsWith(s, i);

  while (i < n) {
    var c = code[i];

    // Block comment.
    if (lang.blockOpen != null && at(lang.blockOpen!)) {
      var end = code.indexOf(lang.blockClose!, i + lang.blockOpen!.length);
      var stop = end < 0 ? n : end + lang.blockClose!.length;
      span('tok-comment', i, stop);
      i = stop;
      continue;
    }

    // Lua long string [[ ... ]].
    if (lang.luaLongStrings && at('[[')) {
      var end = code.indexOf(']]', i + 2);
      var stop = end < 0 ? n : end + 2;
      span('tok-string', i, stop);
      i = stop;
      continue;
    }

    // Line comment.
    var lineComment = lang.lineComments.firstWhere(at, orElse: () => '');
    if (lineComment.isNotEmpty) {
      var end = code.indexOf('\n', i);
      var stop = end < 0 ? n : end;
      span('tok-comment', i, stop);
      i = stop;
      continue;
    }

    // Triple-quoted string.
    if (lang.triple && (at("'''") || at('"""'))) {
      var q = code.substring(i, i + 3);
      var end = code.indexOf(q, i + 3);
      var stop = end < 0 ? n : end + 3;
      span('tok-string', i, stop);
      i = stop;
      continue;
    }

    // Single-line / template strings.
    if (c == "'" || c == '"' || (lang.backtick && c == '`')) {
      var j = i + 1;
      var multiline = c == '`';
      while (j < n) {
        var cj = code[j];
        if (cj == r'\') {
          j += 2;
          continue;
        }
        if (cj == c) {
          j++;
          break;
        }
        if (!multiline && cj == '\n') break;
        j++;
      }
      span('tok-string', i, j);
      i = j;
      continue;
    }

    // Number.
    if (_isDigit(c) || (c == '.' && i + 1 < n && _isDigit(code[i + 1]))) {
      var j = i + 1;
      while (j < n &&
          (_isIdentPart(code[j]) || code[j] == '.' || code[j] == 'x')) {
        j++;
      }
      span('tok-number', i, j);
      i = j;
      continue;
    }

    // Identifier / keyword / type / function.
    if (_isIdentStart(c)) {
      var j = i + 1;
      while (j < n && _isIdentPart(code[j])) {
        j++;
      }
      var word = code.substring(i, j);

      // Look ahead for a `(` to classify a call/definition as a function.
      var k = j;
      while (k < n && (code[k] == ' ' || code[k] == '\t')) {
        k++;
      }
      var isCall = k < n && code[k] == '(';

      String cls;
      if (lang.keywords.contains(word)) {
        cls = 'tok-keyword';
      } else if (lang.types.contains(word) ||
          (word.length > 1 && _isUpper(c))) {
        cls = 'tok-type';
      } else if (isCall) {
        cls = 'tok-func';
      } else {
        cls = 'tok-ident';
      }
      span(cls, i, j);
      i = j;
      continue;
    }

    // Operators / punctuation / whitespace.
    if ('+-*/%=<>!&|^~?:'.contains(c)) {
      out.write('<span class="tok-op">${_escForPre(c)}</span>');
    } else {
      out.write(_escForPre(c));
    }
    i++;
  }

  return out.toString();
}
