part of '../main.dart';

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

    var wasmCodeUnit = BinaryCodeUnit(
      'wasm',
      wasmOutput.output(),
      id: 'test.wasm',
      namespace: '',
    );

    var wasmLoad = await vmWasm.loadCodeUnit(wasmCodeUnit);
    if (!wasmLoad) {
      throw StateError("Can't load compiled Wasm!");
    }

    var wasmRunner = vmWasm.createRunner('wasm')!;

    // Map the `print` function in the VM:
    wasmRunner.externalPrintFunction = (o) => output.writeln(o);

    var parameters = [...?positionalParameters, ...?namedParameters?.values];

    var entryPoint = className.isNotEmpty
        ? '$className.$functionName'
        : functionName;

    // Mirror the interpreted path: a class method runs via `executeClassMethod`,
    // a top-level function via `executeFunction`. The Wasm runner resolves a
    // class method (e.g. `Foo.main`) by its method name. (ApolloVM's Wasm
    // backend is alpha and currently compiles only top-level functions, so a
    // class method may not yet be present in the compiled module.)
    try {
      if (className.isNotEmpty) {
        astValue = await wasmRunner.executeClassMethod(
          '',
          className,
          functionName,
          positionalParameters: parameters,
        );
      } else {
        astValue = await wasmRunner.executeFunction(
          '',
          functionName,
          positionalParameters: parameters,
        );
      }
    } on StateError catch (e) {
      if (e.message.contains('find function')) {
        throw StateError(
          "Wasm entry point `$entryPoint` not found in the compiled module.\n"
          "ApolloVM's Wasm backend (alpha) currently compiles only top-level "
          "functions, so class methods like `$entryPoint` may not be compiled "
          "to Wasm yet.\nTip: use a top-level `$functionName(...)` function "
          "(clear the class field), or run in interpreted mode.",
        );
      }
      rethrow;
    }
  } else {
    executedCode = code;

    var dartRunner = vm.createRunner(language)!;

    dartRunner.externalPrintFunction = (o) => output.writeln(o);

    if (className.isNotEmpty) {
      astValue = await dartRunner.executeClassMethod(
        '',
        className,
        functionName,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
      );
    } else {
      astValue = await dartRunner.executeFunction(
        '',
        functionName,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
      );
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
  String language,
  String code,
) async {
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

Future<String?> convertCode(
  String fromLanguage,
  String code,
  String toLanguage,
) async {
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

/// The message of an [UnsupportedSyntaxError], without the `[Unsupported
/// Syntax]` tag that its `toString()` prepends.
///
/// ApolloVM 1.9.0 throws this at *generation* time when the target language has
/// no equivalent construct — e.g. an `extension` into Java/JS/TS/Python/Go/Lua,
/// or an extension *getter* into C# (which has no extension property).
String unsupportedSyntaxDetail(UnsupportedSyntaxError e) {
  var message = '${e.message}';
  const tag = '[Unsupported Syntax] ';
  return message.startsWith(tag) ? message.substring(tag.length) : message;
}

/// Source languages ApolloVM can both parse and generate. These are the
/// transpilation targets for the "Convert to all languages" feature. Wasm is a
/// binary compile target (offered via "Download Wasm"), not a source target.
///
/// `go` is a transpile target only: apollovm 1.9.1 made Dart -> Go -> parse ->
/// run work end to end, but the LSP reports no symbols for a `.go` buffer, so Go
/// is not offered as an editor language.
const conversionLanguages = <String>[
  'dart',
  'java11',
  'kotlin',
  'javascript',
  'typescript',
  'lua',
  'python',
  'csharp',
  'go',
];

/// Transpiles [code] (parsed as [fromLanguage]) to every other language in
/// [conversionLanguages]. The source is parsed once, then generated for each
/// target. Returns a map of target language -> generated source, with an
/// `ERROR: ...` message for any target (or the parse step) that fails.
Future<Map<String, String>> convertCodeToAllLanguages(
  String fromLanguage,
  String code,
) async {
  var vm = ApolloVM();

  Object? loadError;
  var loaded = false;
  try {
    loaded = await vm.loadCodeUnit(
      SourceCodeUnit(fromLanguage, code, id: 'convert'),
    );
  } catch (e, s) {
    loadError = e;
    printError('$e');
    printError('$s');
  }

  var results = <String, String>{};
  for (var target in conversionLanguages) {
    if (target == fromLanguage) continue;

    if (!loaded) {
      results[target] =
          "ERROR: can't parse `$fromLanguage` source.\n\n$loadError";
      continue;
    }

    try {
      var codeStorage = vm.generateAllCodeIn(target);
      var allSources = await codeStorage.writeAllSources();
      var generated = allSources
          .toString()
          .replaceAll(RegExp(r'<<<<[^>]+>>>>'), '')
          .trim();
      results[target] = generated.isEmpty ? '(no output)' : generated;
    } on UnsupportedSyntaxError catch (e) {
      results[target] =
          "UNSUPPORTED: `$target` has no equivalent construct.\n\n"
          '${unsupportedSyntaxDetail(e)}';
    } catch (e) {
      results[target] = 'ERROR converting to `$target`:\n\n$e';
    }
  }

  return results;
}

void printError(Object? o) {
  console.error('$o'.toJS);
}
