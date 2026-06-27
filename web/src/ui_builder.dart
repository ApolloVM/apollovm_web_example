part of '../main.dart';

void buildUI() {
  document.querySelector('#apollovmTitle')?.textContent =
      'ApolloVM / ${ApolloVM.VERSION}';

  var exampleLangOptions = exampleCategories()
      .map((c) =>
          '<option value="$c">${_exampleLanguageLabels[c] ?? c}</option>')
      .join('\n    ');

  document.querySelector('#output')?.innerHTML = '''
<div class="toolbar">
  <label>Language:
  <select id="exampleLangSelect">
    $exampleLangOptions
  </select>
  </label>
  <label>Example:
  <select id="exampleSelect"></select>
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
    <option value="python">Python</option>
    <option value="csharp">C#</option>
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
<button id="convert">Convert to all languages ⇄</button>
<br>
<div style="padding: 2px 4px 8px 4px"><input type="checkbox" id="wasm-compiled"> &nbsp; <i>Wasm compiled (alpha)</i></div>

<div id="conversionsPanel" class="conversionsPanel hidden">
  <div class="conversionsHeader">
    <span class="conversionsTitle">Transpiled with ApolloVM:</span>
    <button id="conversionsClose" class="conversionsClose" title="Close" aria-label="Close converted code">✕</button>
  </div>
  <div id="conversionTabs" class="conversionTabs"></div>
  <pre id="conversionOutput" class="conversionOutput"></pre>
</div>

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
  '''
      .toJS;

  setupCodeEditor();
  populateExampleSelect(exampleCategories().first);
  loadExample(0);

  var exampleLangSelect = selectExampleLangSelect();
  _listen(exampleLangSelect, 'change', (evt) {
    var category = exampleLangSelect.value;
    populateExampleSelect(category);
    var index = firstExampleIndexForCategory(category);
    if (index >= 0) loadExample(index);
  });

  var exampleSelect = selectExampleSelect();
  _listen(exampleSelect, 'change',
      (evt) => loadExample(int.parse(exampleSelect.value)));

  var codeLanguage = selectCodeLanguage();
  _listen(codeLanguage, 'change', (evt) => changeLanguage());

  var downloadWasmButton = selectDownloadWasmButton();
  _listen(downloadWasmButton, 'click', (evt) => downloadWasm());

  var runButton = selectRunButton();
  _listen(runButton, 'click', (evt) => runCode());

  var convertButton = selectConvertButton();
  _listen(convertButton, 'click', (evt) => runConvert());

  var conversionsClose = selectConversionsClose();
  _listen(conversionsClose, 'click', (evt) => hideConversions());

  var wasmCompiledCheck = selectWasmCompiledCheckbox();
  _listen(wasmCompiledCheck, 'click', (evt) => wasmCompiledChecked());
}
