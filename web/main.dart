import 'dart:convert';
import 'dart:html' hide MimeType;

import 'package:apollovm/apollovm.dart';
import 'package:collection/collection.dart';
import 'package:dom_tools/dom_tools.dart';
import 'package:swiss_knife/swiss_knife.dart';
import 'package:data_serializer/data_serializer.dart';

const initialCodeDart = r'''

class Foo {

  void main(List<Object> args) {
    var title = args[0];
    var a = args[1];
    var b = args[2] ~/ 2;
    var c = args[3] * 3;
    
    if (c > 120) {
      c = 120 ;
    }
    
    var str = 'variables> a: $a ; b: $b ; c: $c' ;
    var sumAB = a + b ;
    var sumABC = a + b + c;
    
    print(str);
    print(title);
    print(sumAB);
    print(sumABC);
    
    // Map:
    var map = <String,int>{
    'a': a,
    'b': b,
    'c': c,
    };
    
    print('Map: $map');
    print('Map `b`: ${map['b']}');
  }
  
}
''';

final initialPositionalParameters = ' [ "Sums:" , 10 , 30 , 50 ] ';
final initialNamedParameters = '';

/// A ready-to-run code example for the playground.
///
/// [positionalParameters] is the JSON typed into the field (it's wrapped in
/// `[ ... ]` before decoding), so a single-array entry point like Dart's
/// `main(List<Object> args)` uses `'[ "Sums:", 10, 30, 50 ]'`, while a
/// multi-arg entry point uses `'"Sums:", 10, 20, 30'`.
class CodeExample {
  final String name;
  final String language;
  final String code;
  final String className;
  final String functionName;
  final String positionalParameters;
  final String namedParameters;

  const CodeExample(
    this.name,
    this.language,
    this.code,
    this.className,
    this.functionName,
    this.positionalParameters, [
    this.namedParameters = '',
  ]);
}

/// Examples shown in the "Example" selector. Every entry is verified to run.
const codeExamples = <CodeExample>[
  CodeExample('Dart — Class (maps & strings)', 'dart', initialCodeDart, 'Foo',
      'main', '[ "Sums:", 10, 30, 50 ]'),
  CodeExample('Dart — Fibonacci (Interpreted + Wasm)', 'dart', _exDartFib, '',
      'fibonacci', '10'),
  CodeExample('Java11 — Class', 'java11', _exJava, 'Foo', 'main',
      '[ "Sums:", 10, 20, 30 ]'),
  CodeExample('Kotlin — Class', 'kotlin', _exKotlin, 'Foo', 'main',
      '"Sums:", 10, 20, 30'),
  CodeExample('JavaScript — Class', 'javascript', _exJs, 'Foo', 'main',
      '"Sums:", 10, 20, 30'),
  CodeExample('TypeScript — Class', 'typescript', _exTs, 'Foo', 'main',
      '"Sums:", 10, 20, 30'),
  CodeExample(
      'Lua — Class', 'lua', _exLua, 'Foo', 'main', '"Sums:", 10, 20, 30'),
];

const _exDartFib =
    r'''// Top-level function: runs both Interpreted and Wasm-compiled.
// The returned value is shown in the OUTPUT "result" panel.
int fibonacci(int n) {
  if (n <= 1) {
    return n;
  }
  var a = 0;
  var b = 1;
  var i = 2;
  while (i <= n) {
    var c = a + b;
    a = b;
    b = c;
    i = i + 1;
  }
  return b;
}
''';

const _exJava = r'''class Foo {
   static public void main(Object[] args) {
     var title = args[0];
     var a = args[1];
     var b = args[2];
     var c = args[3];
     var sumAB = a + b ;
     var sumABC = a + b + c;
     print(title);
     print(sumAB);
     print(sumABC);
   }
}
''';

const _exKotlin = r'''class Foo {
    fun main(title: String, a: Int, b: Int, c: Int) {
      val sumAB = a + b
      val sumABC = a + b + c
      println(title)
      println(sumAB)
      println(sumABC)
    }
}
''';

const _exJs = r'''class Foo {
  main(title, a, b, c) {
    let sumAB = a + b;
    let sumABC = a + b + c;
    print(title);
    print(sumAB);
    print(sumABC);
  }
}
''';

const _exTs = r'''class Foo {
  main(title: string, a: number, b: number, c: number): void {
    let sumAB: number = a + b;
    let sumABC: number = a + b + c;
    print(title);
    print(sumAB);
    print(sumABC);
  }
}
''';

const _exLua = r'''Foo = {}
Foo.__index = Foo

function Foo:main(title, a, b, c)
  local sumAB = a + b
  local sumABC = a + b + c
  print(title)
  print(sumAB)
  print(sumABC)
end
''';

void buildUI() {
  querySelector('#apollovmTitle')?.text = 'ApolloVM / ${ApolloVM.VERSION}';

  var exampleOptions = codeExamples
      .mapIndexed((i, e) => '<option value="$i">${e.name}</option>')
      .join('\n    ');

  querySelector('#output')?.setInnerHtml('''
<div class="toolbar">
  <label>Example:
  <select id="exampleSelect">
    $exampleOptions
  </select>
  </label>
</div>

<div class="editor">
  <div class="gutter" id="codeGutter" aria-hidden="true"></div>
  <textarea id="code" rows="30" spellcheck="false" wrap="off"></textarea>
</div>

<div style="text-align: right; padding: 2px 4px;">
  <button id="download-wasm">Download Wasm (alpha)</button>
</div>

<div style="text-align: left; padding: 2px">
  <ul>

  <li>Language:
  <select id="codeLang">
    <option value="dart" selected>Dart</option>
    <option value="java11">Java11</option>
    <option value="kotlin">Kotlin</option>
    <option value="javascript">JavaScript</option>
    <option value="typescript">TypeScript</option>
    <option value="lua">Lua</option>
  </select>
  </li>
  
  <li>Entry point: <input id="className" type="text" value="Foo" style="width: 60px"><input id="functionName" type="text" value="main" style="width: 60px"></li>
  
  <li>Parameters:</li>
  <ul>
  <li>Positional: <input id="positionalParametersJson" type="text" value='$initialPositionalParameters' style="width: 300px"> <i>*JSON</i></li>
  <li>Named: <input id="namedParametersJson" type="text" value='$initialNamedParameters' style="width: 300px"> <i>*JSON</i></li>
  </ul>
  </ul>
</div>

<button id="run">RUN - Interpreted</button>
<br>
<div style="padding: 2px 4px 8px 4px"><input type="checkbox" id="wasm-compiled"> &nbsp; <i>Wasm compiled (alpha)</i></div>

<div style="background-color: #000; color: #fff; padding: 2px; margin-top: 8px; border-radius: 8px;">
ApolloVM OUTPUT:
<div id="vmOutputDiv">
<pre id="vmResult" class="vmOutputDivEmpty" style="text-align: left">
[result]
</pre>
<hr>
<pre id="vmOutput" class="vmOutputDivEmpty">
[output]
</pre>
<hr>
<pre id="vmExecutedCode" class="vmOutputDivEmpty" style="text-align: left">
[executed code]
</pre>
</div>
</div>
  ''',
      validator: NodeValidatorBuilder()
        ..allowNavigation(AnyUriPolicy())
        ..allowInlineStyles()
        ..allowHtml5());

  setupCodeEditor();
  loadExample(0);

  var exampleSelect = selectExampleSelect();
  exampleSelect.onChange
      .listen((evt) => loadExample(int.parse(exampleSelect.value ?? '0')));

  var codeLanguage = selectCodeLanguage();
  codeLanguage.onChange.listen((evt) => changeLanguage());

  var downloadWasmButton = selectDownloadWasmButton();
  downloadWasmButton.onClick.listen((evt) => downloadWasm());

  var runButton = selectRunButton();
  runButton.onClick.listen((evt) => runCode());

  var wasmCompiledCheck = selectWasmCompiledCheckbox();
  wasmCompiledCheck.onClick.listen((evt) => wasmCompiledChecked());
}

TextInputElement selectClassName() =>
    querySelector('#className') as TextInputElement;

TextInputElement selectFunctionName() =>
    querySelector('#functionName') as TextInputElement;

TextInputElement selectPositionalParametersJson() =>
    querySelector('#positionalParametersJson') as TextInputElement;

TextInputElement selectNamedParametersJson() =>
    querySelector('#namedParametersJson') as TextInputElement;

SelectElement selectExampleSelect() =>
    querySelector('#exampleSelect') as SelectElement;

/// Loads the [codeExamples] entry at [index] into the editor and the
/// entry-point / parameter fields, ready to RUN.
void loadExample(int index) {
  var ex = codeExamples[index];

  selectCodeLanguage().value = ex.language;

  selectCodeTextArea().setAttribute('language', ex.language);
  setCodeEditorText(ex.code);

  selectClassName().value = ex.className;
  selectFunctionName().value = ex.functionName;
  selectPositionalParametersJson().value = ex.positionalParameters;
  selectNamedParametersJson().value = ex.namedParameters;

  resetVMOutputs();
}

SelectElement selectCodeLanguage() =>
    querySelector('#codeLang') as SelectElement;

ButtonElement selectDownloadWasmButton() =>
    querySelector('#download-wasm') as ButtonElement;

ButtonElement selectRunButton() => querySelector('#run') as ButtonElement;

CheckboxInputElement selectWasmCompiledCheckbox() =>
    querySelector('#wasm-compiled') as CheckboxInputElement;

bool get wasmCompiledCheck => selectWasmCompiledCheckbox().checked ?? false;

TextAreaElement selectCodeTextArea() =>
    querySelector('#code') as TextAreaElement;

DivElement selectCodeGutter() => querySelector('#codeGutter') as DivElement;

/// Wires up the line-numbered code editor: gutter line numbers, scroll sync
/// between the gutter and the textarea, and Tab/Shift+Tab indentation.
void setupCodeEditor() {
  var codeTextArea = selectCodeTextArea();

  codeTextArea.onInput.listen((_) => updateCodeGutter());
  codeTextArea.onScroll
      .listen((_) => selectCodeGutter().scrollTop = codeTextArea.scrollTop);

  codeTextArea.onKeyDown.listen(handleCodeEditorKeyDown);
}

/// Sets the editor content and refreshes the line-number gutter.
void setCodeEditorText(String text) {
  selectCodeTextArea().value = text;
  updateCodeGutter();
}

/// Rebuilds the gutter so it has one number per line of the current code.
void updateCodeGutter() {
  var codeTextArea = selectCodeTextArea();
  var gutter = selectCodeGutter();

  var lineCount = '\n'.allMatches(codeTextArea.value ?? '').length + 1;

  gutter.text = List.generate(lineCount, (i) => '${i + 1}').join('\n');
  gutter.scrollTop = codeTextArea.scrollTop;
}

const _indent = '  ';

void handleCodeEditorKeyDown(KeyboardEvent event) {
  if (event.key != 'Tab') return;
  event.preventDefault();

  var codeTextArea = selectCodeTextArea();
  var value = codeTextArea.value ?? '';
  var start = codeTextArea.selectionStart ?? 0;
  var end = codeTextArea.selectionEnd ?? 0;

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

  updateCodeGutter();
}

PreElement selectVMResult() => querySelector('#vmResult') as PreElement;

PreElement selectVMOutput() => querySelector('#vmOutput') as PreElement;

PreElement selectVMExecutedCode() =>
    querySelector('#vmExecutedCode') as PreElement;

void changeLanguage() async {
  var codeTextArea = selectCodeTextArea();
  var currentCodeLanguage = codeTextArea.getAttribute('language') ?? '';
  var codeLanguage =
      selectCodeLanguage().selectedOptions.firstOrNull?.value ?? 'dart';

  print('changeLanguage> $currentCodeLanguage ; $codeLanguage');

  if (currentCodeLanguage == codeLanguage) {
    return;
  }

  resetVMOutputs();

  var code = codeTextArea.value ?? '';

  try {
    var code2 = await convertCode(currentCodeLanguage, code, codeLanguage);

    if (code2 != null) {
      setCodeEditorText(code2);
      codeTextArea.setAttribute('language', codeLanguage);

      setVMOutput(
          'INFO: Code successfully converted from `$currentCodeLanguage` to `$codeLanguage`.',
          info: true);
    } else {
      setVMOutput(
          "ERROR: Can't convert code from `$currentCodeLanguage` to `$codeLanguage`!",
          error: true);
    }
  } catch (e, s) {
    printError('$e');
    printError('$s');

    setVMOutput('$e', error: true);
  }
}

Future<String?> convertCode(
    String fromLanguage, String code, String toLanguage) async {
  print('Converting from `$fromLanguage` to `$toLanguage`');

  print(code);

  var vm = ApolloVM();

  var codeUnit = SourceCodeUnit(fromLanguage, code, id: 'convert');

  var loadOK = false;
  try {
    loadOK = await vm.loadCodeUnit(codeUnit);
  } catch (e, s) {
    printError('$e');
    printError('$s');
  }

  if (!loadOK) {
    throw StateError("Can't load source! Language: $fromLanguage");
  }

  var codeStorage = vm.generateAllCodeIn(toLanguage);
  var allSources = await codeStorage.writeAllSources();

  var code2 = allSources.toString();

  print(code2);

  code2 = code2.replaceAll(RegExp(r'<<<<[^>]+>>>>'), '').trim();

  return code2;
}

void downloadWasm() async {
  var code = selectCodeTextArea().value ?? '';
  var codeLanguage =
      selectCodeLanguage().selectedOptions.firstOrNull?.value ?? 'dart';

  resetVMOutputs();

  var wasm = await compileToWasm(codeLanguage, code);

  setVMResult('[not executed]');

  setVMOutput('`$codeLanguage` to Wasm Compilation: ${wasm.ok ? 'OK' : 'FAIL'}',
      info: true);

  setVMExecutedCode(wasm.output.toString());

  var wasmBytes = wasm.output.output();
  var wasmID = DateTime.now().millisecondsSinceEpoch;

  var mimeType = MimeType.parse('application/wasm')!;
  var wasmFileName = 'apollovm-compilation-$wasmID-$codeLanguage-to.wasm';

  downloadBytes(wasmBytes, mimeType, wasmFileName);
}

void wasmCompiledChecked() async {
  var runButton = selectRunButton();

  if (wasmCompiledCheck) {
    runButton.text = 'RUN - Wasm compiled';
  } else {
    runButton.text = 'RUN - Interpreted';
  }
}

void runCode() async {
  var className = selectClassName().value ?? '';
  var functionName = selectFunctionName().value ?? '';
  var positionalParametersJson = selectPositionalParametersJson().value ?? '';
  var namedParametersJson = selectNamedParametersJson().value ?? '';
  var wasmCompiled = wasmCompiledCheck;

  var code = selectCodeTextArea().value ?? '';
  var codeLanguage =
      selectCodeLanguage().selectedOptions.firstOrNull?.value ?? 'dart';

  resetVMOutputs();

  try {
    var result = await executeVM(codeLanguage, code, className, functionName,
        positionalParametersJson, namedParametersJson, wasmCompiled);

    setVMResult(result.result);
    setVMOutput(result.output);
    setVMExecutedCode(result.executedCode);
  } catch (e, s) {
    printError('$e');
    printError('$s');

    setVMOutput('$e', error: true);
  }
}

void setVMResult(Object? result, {bool error = false, bool info = false}) {
  var pre = selectVMResult();

  _setPre(pre, '$result', error, info);
}

void setVMOutput(String text, {bool error = false, bool info = false}) {
  var pre = selectVMOutput();

  _setPre(pre, text, error, info);
}

void setVMExecutedCode(String code) {
  var pre = selectVMExecutedCode();

  _setPre(pre, code, false, false);
}

void resetVMOutputs() {
  _setPre(selectVMResult(), '[result]', false, false);
  _setPre(selectVMOutput(), '[output]', false, false);
  _setPre(selectVMExecutedCode(), '[executed code]', false, false);
}

void _setPre(PreElement pre, String text, bool error, bool info) {
  pre.text = text;

  pre.classes.remove('vmOutputDivEmpty');
  pre.classes.remove('vmOutputDivInfo');
  pre.classes.remove('vmOutputDivError');

  if (error) {
    pre.classes.add('vmOutputDivError');
  } else if (info) {
    pre.classes.add('vmOutputDivInfo');
  }
}

Future<({Object? result, String output, String executedCode})> executeVM(
  String language,
  String code,
  String className,
  String functionName,
  String positionalParametersJson,
  String namedParametersJson,
  bool wasmCompiled,
) async {
  print('-----------------------------------------------------');
  print('>> Execute VM:');
  print('language: $language');
  print('code: <<<\n$code\n>>>');

  var vm = ApolloVM();

  var codeUnit = SourceCodeUnit(language, code, id: 'web');

  Object? loadError;
  var loadOK = false;
  try {
    loadOK = await vm.loadCodeUnit(codeUnit);
  } catch (e, s) {
    loadError = e;
    printError('$e');
    printError('$s');
  }

  if (!loadOK) {
    throw StateError("Can't load source! Language: $language\n\n$loadError");
  }

  positionalParametersJson = positionalParametersJson.trim();
  namedParametersJson = namedParametersJson.trim();

  List? positionalParameters = positionalParametersJson.isNotEmpty
      ? json.decode('[ $positionalParametersJson ]')
      : [];

  Map? namedParameters = namedParametersJson.isNotEmpty
      ? json.decode('{ $namedParametersJson }')
      : {};

  print('positionalParameters: $positionalParameters');
  print('namedParameters: $namedParameters');

  String executedCode;
  var output = StringBuffer();
  ASTValue astValue;

  if (wasmCompiled) {
    var storageWasm = vm.generateAllIn<BytesOutput>('wasm');
    var wasmModules = await storageWasm.allEntries();

    var wasmModule = wasmModules.values.first.entries.first;
    var wasmOutput = wasmModule.value;

    print('Wasm bytes (HEX): \n${hex.encode(wasmOutput.output())}');

    executedCode = wasmOutput.toString(hex: true);
    print('Wasm bytes: <<<\n\n$executedCode\n>>>');

    var vmWasm = ApolloVM();

    var wasmCodeUnit = BinaryCodeUnit('wasm', wasmOutput.output(),
        id: 'test.wasm', namespace: '');

    var wasmLoad = await vmWasm.loadCodeUnit(wasmCodeUnit);
    if (!wasmLoad) {
      throw StateError("Can't load compiled Wasm!");
    }

    var wasmRunner = vmWasm.createRunner('wasm')!;

    // Map the `print` function in the VM:
    wasmRunner.externalPrintFunction = (o) => output.writeln(o);

    var parameters = [...?positionalParameters, ...?namedParameters?.values];

    var entryPoint =
        className.isNotEmpty ? '$className.$functionName' : functionName;

    // The Wasm runner resolves a class method (e.g. `Foo.main`) as an entry
    // point by its method name via `allowClassMethod`, mirroring the
    // interpreted path. (ApolloVM's Wasm backend is alpha and currently
    // compiles only top-level functions, so class methods may not yet be
    // present in the compiled module.)
    try {
      astValue = await wasmRunner.executeFunction('', functionName,
          positionalParameters: parameters, allowClassMethod: true);
    } on StateError catch (e) {
      if (e.message.contains('find function')) {
        throw StateError(
            "Wasm entry point `$entryPoint` not found in the compiled module.\n"
            "ApolloVM's Wasm backend (alpha) currently compiles only top-level "
            "functions, so class methods like `$entryPoint` may not be compiled "
            "to Wasm yet.\nTip: use a top-level `$functionName(...)` function "
            "(clear the class field), or run in interpreted mode.");
      }
      rethrow;
    }
  } else {
    executedCode = code;

    var dartRunner = vm.createRunner(language)!;

    dartRunner.externalPrintFunction = (o) => output.writeln(o);

    if (className.isNotEmpty) {
      astValue = await dartRunner.executeClassMethod(
          '', className, functionName,
          positionalParameters: positionalParameters,
          namedParameters: namedParameters);
    } else {
      astValue = await dartRunner.executeFunction('', functionName,
          positionalParameters: positionalParameters,
          namedParameters: namedParameters);
    }
  }

  var result = await astValue.getValueNoContext();

  print("RESULT: $result");

  var outputStr = output.toString();
  print('OUTPUT: <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
  print(outputStr);
  print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');

  return (result: result, output: outputStr, executedCode: executedCode);
}

Future<({bool ok, BytesOutput output})> compileToWasm(
    String language, String code) async {
  print('-----------------------------------------------------');
  print('>> Compile to Wasm:');
  print('language: $language');
  print('code: <<<\n$code\n>>>');

  var vm = ApolloVM();

  var codeUnit = SourceCodeUnit(language, code, id: 'web');

  Object? loadError;
  var loadOK = false;
  try {
    loadOK = await vm.loadCodeUnit(codeUnit);
  } catch (e, s) {
    loadError = e;
    printError('$e');
    printError('$s');
  }

  if (!loadOK) {
    throw StateError("Can't load source! Language: $language\n\n$loadError");
  }

  var storageWasm = vm.generateAllIn<BytesOutput>('wasm');
  var wasmModules = await storageWasm.allEntries();

  var wasmModule = wasmModules.values.first.entries.first;
  var wasmOutput = wasmModule.value;

  print('Wasm bytes: <<<\n\n${wasmOutput.toString(hex: true)}\n>>>');

  return (ok: true, output: wasmOutput);
}

void printError(Object? o) {
  window.console.error(o);
}

class AnyUriPolicy implements UriPolicy {
  @override
  bool allowsUri(String uri) => true;
}

void main() async {
  buildUI();
}
