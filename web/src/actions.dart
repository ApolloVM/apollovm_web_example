part of '../main.dart';

/// Loads the [codeExamples] entry at [index] into the editor and the
/// entry-point / parameter fields, ready to RUN.
void loadExample(int index) {
  var ex = codeExamples[index];

  // Detach from any open repository file (no git change bars for examples).
  _openRepoPath = '';
  clearGitGutter();

  selectCodeLanguage().value = ex.language;

  selectCodeTextArea().setAttribute('language', ex.language);
  setCodeEditorText(ex.code);
  selectFileName().textContent = fileNameForLanguage(ex.language);

  selectClassName().value = ex.className;
  selectFunctionName().value = ex.functionName;
  selectPositionalParametersJson().value = ex.positionalParameters;
  selectNamedParametersJson().value = ex.namedParameters;

  // Wasm examples run via the Wasm-compiled path; others run interpreted.
  selectWasmCompiledCheckbox().checked = ex.wasm;
  wasmCompiledChecked();

  hideConversions();
  resetVMOutputs();
  switchBottomPanel('problems');
  runLspAnalysis();
}

void changeLanguage() async {
  var codeTextArea = selectCodeTextArea();
  var currentCodeLanguage = codeTextArea.getAttribute('language') ?? '';
  var codeLanguage = selectCodeLanguage().value;

  print('changeLanguage> $currentCodeLanguage ; $codeLanguage');

  if (currentCodeLanguage == codeLanguage) {
    return;
  }

  // The transpiled buffer is no longer the open repository file.
  _openRepoPath = '';
  clearGitGutter();

  hideConversions();
  resetVMOutputs();

  var code = codeTextArea.value;

  try {
    var code2 = await convertCode(currentCodeLanguage, code, codeLanguage);

    if (code2 != null) {
      setCodeEditorText(code2);
      codeTextArea.setAttribute('language', codeLanguage);

      setVMOutput(
        'INFO: Code successfully converted from `$currentCodeLanguage` to `$codeLanguage`.',
        info: true,
      );
    } else {
      setVMOutput(
        "ERROR: Can't convert code from `$currentCodeLanguage` to `$codeLanguage`!",
        error: true,
      );
    }
  } on UnsupportedSyntaxError catch (e) {
    printError('$e');

    // The code parsed fine, but `codeLanguage` has no equivalent construct
    // (e.g. an `extension` into Java). Keep the editor on the source language.
    if (currentCodeLanguage.isNotEmpty) {
      selectCodeLanguage().value = currentCodeLanguage;
    }

    setVMOutput(
      "UNSUPPORTED: `$codeLanguage` has no equivalent construct, so the code "
      "can't be converted from `$currentCodeLanguage`.\n\n"
      '${unsupportedSyntaxDetail(e)}',
      error: true,
    );
  } catch (e, s) {
    printError('$e');
    printError('$s');

    setVMOutput('$e', error: true);
  }

  selectFileName().textContent = fileNameForLanguage(
    codeTextArea.getAttribute('language') ?? codeLanguage,
  );
  switchBottomPanel('output');
  runLspAnalysis();
}

void downloadWasm() async {
  var code = selectCodeTextArea().value;
  var codeLanguage = selectCodeLanguage().value;

  resetVMOutputs();

  var wasm = await compileToWasm(codeLanguage, code);

  setVMResult('[not executed]');

  setVMOutput(
    '`$codeLanguage` to Wasm Compilation: ${wasm.ok ? 'OK' : 'FAIL'}',
    info: true,
  );

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
    runButton.textContent = '▶ Run · Wasm';
    selectStatusMode().textContent = 'Wasm compiled';
  } else {
    runButton.textContent = '▶ Run';
    selectStatusMode().textContent = 'Interpreted';
  }
}

void runCode() async {
  var className = selectClassName().value;
  var functionName = selectFunctionName().value;
  var positionalParametersJson = selectPositionalParametersJson().value;
  var namedParametersJson = selectNamedParametersJson().value;
  var wasmCompiled = wasmCompiledCheck;

  var code = selectCodeTextArea().value;
  var codeLanguage = selectCodeLanguage().value;

  resetVMOutputs();

  switchBottomPanel('output');

  try {
    var result = await executeVM(
      codeLanguage,
      code,
      className,
      functionName,
      positionalParametersJson,
      namedParametersJson,
      wasmCompiled,
    );

    setVMResult(result.result);
    setVMOutput(result.output);
    setVMExecutedCode(result.executedCode);
  } catch (e, s) {
    printError('$e');
    printError('$s');

    setVMOutput('$e', error: true);
  }
}

/// The conversions currently shown, keyed by target language.
Map<String, String> _conversions = {};

/// Transpiles the editor's code into every other supported language and shows
/// the results in the conversions panel (one tab per language).
void runConvert() async {
  var code = selectCodeTextArea().value;
  var fromLanguage =
      selectCodeTextArea().getAttribute('language') ??
      selectCodeLanguage().value;

  switchBottomPanel('translation');
  selectConversionTabs().textContent = '';
  selectConversionOutput().classList.remove('muted');
  selectConversionOutput().textContent = 'Transpiling…';

  try {
    var results = await convertCodeToAllLanguages(fromLanguage, code);
    showConversions(fromLanguage, results);
  } catch (e, s) {
    printError('$e');
    printError('$s');
    selectConversionOutput().textContent = '$e';
  }
}

/// Renders the conversion [results] as a tab per target language, selecting the
/// first one. [fromLanguage] labels the source.
void showConversions(String fromLanguage, Map<String, String> results) {
  _conversions = results;

  var fromLabel = _exampleLanguageLabels[fromLanguage] ?? fromLanguage;
  var tabs = results.keys
      .map(
        (l) =>
            '<button class="conv-tab" data-lang="$l">${_exampleLanguageLabels[l] ?? l}</button>',
      )
      .join();
  selectConversionTabs().innerHTML =
      '<span class="conv-from">$fromLabel →</span>$tabs'.toJS;

  var tabNodes = selectConversionTabs().querySelectorAll('.conv-tab');
  for (var i = 0; i < tabNodes.length; i++) {
    var tab = tabNodes.item(i) as HTMLElement;
    var language = tab.getAttribute('data-lang') ?? '';
    _listen(tab, 'click', (evt) => showConversion(language));
  }

  if (results.isNotEmpty) showConversion(results.keys.first);
}

/// Shows the conversion for [language] and marks its tab active.
void showConversion(String language) {
  selectConversionOutput().classList.remove('muted');
  selectConversionOutput().textContent = _conversions[language] ?? '';

  var tabNodes = selectConversionTabs().querySelectorAll('.conv-tab');
  for (var i = 0; i < tabNodes.length; i++) {
    var tab = tabNodes.item(i) as HTMLElement;
    if (tab.getAttribute('data-lang') == language) {
      tab.classList.add('conv-tab-active');
    } else {
      tab.classList.remove('conv-tab-active');
    }
  }
}

/// Clears the Transpiled panel (e.g. after loading a new example or switching
/// language, when the shown conversions would be stale).
void hideConversions() {
  _conversions = {};
  selectConversionTabs().textContent = '';
  selectConversionOutput().classList.add('muted');
  selectConversionOutput().textContent =
      'Use ⇄ Transpile to convert to every supported language.';
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

void _setPre(HTMLPreElement pre, String text, bool error, bool info) {
  pre.textContent = text;

  pre.classList.remove('vmOutputDivEmpty');
  pre.classList.remove('vmOutputDivInfo');
  pre.classList.remove('vmOutputDivError');

  if (error) {
    pre.classList.add('vmOutputDivError');
  } else if (info) {
    pre.classList.add('vmOutputDivInfo');
  }
}
