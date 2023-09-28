import 'dart:convert';
import 'dart:html' hide MimeType;

import 'package:dom_tools/dom_tools.dart';
import 'package:apollovm/apollovm.dart';
import 'package:collection/collection.dart';
import 'package:swiss_knife/swiss_knife.dart';

final initialCodeDart = r'''

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

void buildUI() {
  querySelector('#apollovmTitle')?.text = 'ApolloVM / ${ApolloVM.VERSION}';

  querySelector('#output')?.setInnerHtml('''
<textarea id="code" rows="30"></textarea><br>

<div style="text-align: right; padding: 2px 4px;">
  <button id="download-wasm">Download Wasm (alpha)</button>
</div>

<div style="text-align: left; padding: 2px">
  <ul>
  
  <li>Language: 
  <select id="codeLang">
    <option value="dart" selected>Dart</option>
    <option value="java11">Java11</option>
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

<button id="run">RUN</button>

<div style="background-color: #000; color: #fff; padding: 2px; margin-top: 8px; border-radius: 8px;">
ApolloVM OUTPUT:
<div id="vmOutputDiv">
<pre id="vmResult" class="vmOutputDivEmpty" style="text-align: left">
</pre>
<hr>
<pre id="vmOutput" class="vmOutputDivEmpty">
...
</pre>
</div>
</div>
  ''',
      validator: NodeValidatorBuilder()
        ..allowNavigation(AnyUriPolicy())
        ..allowInlineStyles()
        ..allowHtml5());

  var codeTextArea = selectCodeTextArea();
  codeTextArea.text = initialCodeDart;
  codeTextArea.setAttribute('language', 'dart');

  var codeLanguage = selectCodeLanguage();
  codeLanguage.onChange.listen((evt) => changeLanguage());

  var downloadWasmButton = selectDownloadWasmButton();
  downloadWasmButton.onClick.listen((evt) => downloadWasm());

  var runButton = selectRunButton();
  runButton.onClick.listen((evt) => runCode());
}

TextInputElement selectClassName() =>
    querySelector('#className') as TextInputElement;

TextInputElement selectFunctionName() =>
    querySelector('#functionName') as TextInputElement;

TextInputElement selectPositionalParametersJson() =>
    querySelector('#positionalParametersJson') as TextInputElement;

TextInputElement selectNamedParametersJson() =>
    querySelector('#namedParametersJson') as TextInputElement;

SelectElement selectCodeLanguage() =>
    querySelector('#codeLang') as SelectElement;

ButtonElement selectDownloadWasmButton() =>
    querySelector('#download-wasm') as ButtonElement;

ButtonElement selectRunButton() => querySelector('#run') as ButtonElement;

TextAreaElement selectCodeTextArea() =>
    querySelector('#code') as TextAreaElement;

PreElement selectVMResult() => querySelector('#vmResult') as PreElement;

PreElement selectVMOutput() => querySelector('#vmOutput') as PreElement;

void changeLanguage() async {
  var codeTextArea = selectCodeTextArea();
  var currentCodeLanguage = codeTextArea.getAttribute('language') ?? '';
  var codeLanguage =
      selectCodeLanguage().selectedOptions.firstOrNull?.value ?? 'dart';

  print('changeLanguage> $currentCodeLanguage ; $codeLanguage');

  if (currentCodeLanguage == codeLanguage) {
    return;
  }

  var code = codeTextArea.value ?? '';

  try {
    var code2 = await convertCode(currentCodeLanguage, code, codeLanguage);

    if (code2 != null) {
      codeTextArea.value = code2;
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

  var codeUnit = CodeUnit(fromLanguage, code, 'convert');

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

  var wasm = await compileToWasm(codeLanguage, code);

  setVMResult(
      '`$codeLanguage` to Wasm Compilation: ${wasm.ok ? 'OK' : 'FAIL'}');
  setVMOutput(wasm.output.toString());

  var wasmBytes = wasm.output.output();
  var wasmID = DateTime.now().millisecondsSinceEpoch;

  var mimeType = MimeType.parse('application/wasm')!;
  var wasmFileName = 'apollovm-compilation-$wasmID-$codeLanguage-to.wasm';

  downloadBytes(wasmBytes, mimeType, wasmFileName);
}

void runCode() async {
  var className = selectClassName().value ?? '';
  var functionName = selectFunctionName().value ?? '';
  var positionalParametersJson = selectPositionalParametersJson().value ?? '';
  var namedParametersJson = selectNamedParametersJson().value ?? '';

  var code = selectCodeTextArea().value ?? '';
  var codeLanguage =
      selectCodeLanguage().selectedOptions.firstOrNull?.value ?? 'dart';

  try {
    var result = await executeVM(codeLanguage, code, className, functionName,
        positionalParametersJson, namedParametersJson);

    setVMResult(result.result);
    setVMOutput(result.output);
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

Future<({Object? result, String output})> executeVM(
    String language,
    String code,
    String className,
    String functionName,
    String positionalParametersJson,
    String namedParametersJson) async {
  print('-----------------------------------------------------');
  print('>> Execute VM:');
  print('language: $language');
  print('code: <<<\n$code\n>>>');

  var vm = ApolloVM();

  var codeUnit = CodeUnit(language, code, 'web');

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

  var dartRunner = vm.createRunner(language)!;

  var output = StringBuffer();
  dartRunner.externalPrintFunction = (o) => output.writeln(o);

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

  ASTValue astValue;
  if (className.isNotEmpty) {
    astValue = await dartRunner.executeClassMethod('', className, functionName,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters);
  } else {
    astValue = await dartRunner.executeFunction('', functionName,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters);
  }

  var result = await astValue.getValueNoContext();

  print("RESULT: $result");

  var outputStr = output.toString();
  print('OUTPUT: <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
  print(outputStr);
  print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');

  return (result: result, output: outputStr);
}

Future<({bool ok, BytesOutput output})> compileToWasm(
    String language, String code) async {
  print('-----------------------------------------------------');
  print('>> Compile to Wasm:');
  print('language: $language');
  print('code: <<<\n$code\n>>>');

  var vm = ApolloVM();

  var codeUnit = CodeUnit(language, code, 'web');

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
  return;

  //= 'ApolloVM VERSION: ${ApolloVM.VERSION}';
}
