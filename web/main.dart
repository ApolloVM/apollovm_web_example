import 'dart:convert';
import 'dart:html';

import 'package:apollovm/apollovm.dart';
import 'package:collection/collection.dart';

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
<pre id="vmOutput">
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

ButtonElement selectRunButton() => querySelector('#run') as ButtonElement;

TextAreaElement selectCodeTextArea() =>
    querySelector('#code') as TextAreaElement;

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
  var allSources = codeStorage.writeAllSources();

  var code2 = allSources.toString();

  print(code2);

  code2 = code2.replaceAll(RegExp(r'<<<<[^>]+>>>>'), '').trim();

  return code2;
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
    var output = await executeVM(codeLanguage, code, className, functionName,
        positionalParametersJson, namedParametersJson);
    setVMOutput(output);
  } catch (e, s) {
    printError('$e');
    printError('$s');

    setVMOutput('$e', error: true);
  }
}

void setVMOutput(String text, {bool error = false, bool info = false}) {
  var vmOutput = selectVMOutput();

  vmOutput.text = text;

  vmOutput.classes.remove('vmOutputDivInfo');
  vmOutput.classes.remove('vmOutputDivError');

  if (error) {
    vmOutput.classes.add('vmOutputDivError');
  } else if (info) {
    vmOutput.classes.add('vmOutputDivInfo');
  }
}

Future<String> executeVM(
    String language,
    String code,
    String className,
    String functionName,
    String positionalParametersJson,
    String namedParametersJson) async {
  print('language: $language');
  print('code: <<<\n$code\n>>>');

  var vm = ApolloVM();

  var codeUnit = CodeUnit(language, code, 'web');

  var loadOK = false;
  try {
    loadOK = await vm.loadCodeUnit(codeUnit);
  } catch (e, s) {
    printError('$e');
    printError('$s');
  }

  if (!loadOK) {
    throw StateError("Can't load source! Language: $language");
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

  await dartRunner.executeClassMethod('', className, functionName,
      positionalParameters: positionalParameters,
      namedParameters: namedParameters);

  return output.toString();
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
