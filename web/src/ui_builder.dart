part of '../main.dart';

void buildUI() {
  var exampleLangOptions = exampleCategories()
      .map((c) =>
          '<option value="$c">${_exampleLanguageLabels[c] ?? c}</option>')
      .join('\n      ');

  document.querySelector('#app')?.innerHTML = '''
<header class="titlebar">
  <div class="brand">
    <span class="brand-mark">◆</span>
    <span class="brand-name">ApolloVM</span>
    <span class="brand-ver" id="apollovmVersion"></span>
    <span class="brand-sub">IDE</span>
  </div>
  <div class="tb-examples">
    <label class="tb-field">Examples
      <select id="exampleLangSelect">
        $exampleLangOptions
      </select>
      <select id="exampleSelect"></select>
    </label>
  </div>
</header>

<div class="ide-body">
  <aside class="sidebar">
    <div class="panel-head">
      Outline
      <span class="panel-head-tag">LSP</span>
    </div>
    <div class="outline-lang">
      <span class="outline-lang-label">Language</span>
      <select id="codeLang" title="Source language">
        <option value="dart" selected>Dart</option>
        <option value="java11">Java 11</option>
        <option value="kotlin">Kotlin</option>
        <option value="javascript">JavaScript</option>
        <option value="typescript">TypeScript</option>
        <option value="lua">Lua</option>
        <option value="python">Python</option>
        <option value="csharp">C#</option>
      </select>
    </div>
    <div id="outline" class="outline"><div class="outline-empty">No symbols.</div></div>

    <div class="panel-head panel-head-bottom">Run Configuration</div>
    <div class="runcfg">
      <div class="runcfg-actions">
        <button id="run" class="btn-run" title="Run the code (Interpreted or Wasm)">▶&nbsp; Run</button>
        <label class="tb-check" title="Compile to WebAssembly and run that (alpha)">
          <input type="checkbox" id="wasm-compiled"> Wasm
        </label>
      </div>
      <label>Class<input id="className" type="text" value="Foo" spellcheck="false"></label>
      <label>Function<input id="functionName" type="text" value="main" spellcheck="false"></label>
      <label>Positional<input id="positionalParametersJson" type="text" value='$initialPositionalParameters' spellcheck="false"></label>
      <label>Named<input id="namedParametersJson" type="text" value='$initialNamedParameters' spellcheck="false"></label>
      <div class="runcfg-hint">Parameters are JSON.</div>
      <button id="download-wasm" class="btn runcfg-download" title="Compile to a .wasm module and download it">⤓&nbsp; Download Wasm</button>
    </div>
  </aside>

  <main class="main">
    <div class="tabbar">
      <div class="tab tab-active">
        <span class="tab-icon">◆</span>
        <span id="fileName">main.dart</span>
      </div>
      <div class="tabbar-spacer"></div>
      <div class="tabbar-hint" id="langModeHint">Language Server: on</div>
    </div>

    <div class="editor">
      <div class="gutter" id="codeGutter" aria-hidden="true"></div>
      <div class="code-wrap">
        <pre class="code-syntax" id="codeSyntax" aria-hidden="true"></pre>
        <pre class="code-highlight" id="codeHighlight" aria-hidden="true"></pre>
        <textarea id="code" spellcheck="false" wrap="off" autocapitalize="off" autocomplete="off" autocorrect="off"></textarea>
      </div>
    </div>

    <div class="bottom-resizer" id="bottomResizer" title="Drag to resize"></div>

    <section class="bottom" id="bottomDock">
      <div class="bottom-tabs">
        <button class="btab btab-active" data-panel="problems">
          Problems <span class="badge" id="problemsBadge">0</span>
        </button>
        <button class="btab" data-panel="output">Output</button>
        <button class="btab" data-panel="result">Result</button>
        <button class="btab" data-panel="translation">Translation</button>
        <span class="bottom-tabs-spacer"></span>
        <button class="bottom-max" id="bottomMaximize" title="Maximize / restore panel">▴</button>
      </div>
      <div class="bottom-body">
        <div class="bpanel bpanel-active" id="panel-problems">
          <div id="problemsList" class="problems">
            <div class="problems-empty">No problems detected in the buffer.</div>
          </div>
        </div>
        <div class="bpanel" id="panel-output">
          <pre id="vmOutput" class="term vmOutputDivEmpty">[output]</pre>
        </div>
        <div class="bpanel" id="panel-result">
          <pre id="vmResult" class="term vmOutputDivEmpty">[result]</pre>
          <pre id="vmExecutedCode" class="term muted vmOutputDivEmpty">[executed code]</pre>
        </div>
        <div class="bpanel" id="panel-translation">
          <div class="translate-bar">
            <button id="translate-btn" class="btn" title="Transpile the current buffer to every supported language">⇄&nbsp; Translate to all languages</button>
            <span class="translate-hint">Transpiles the current buffer with ApolloVM.</span>
          </div>
          <div id="conversionTabs" class="conversionTabs"></div>
          <pre id="conversionOutput" class="term muted">Click “Translate to all languages” to transpile the current code.</pre>
        </div>
      </div>
    </section>
  </main>
</div>

<footer class="statusbar">
  <span class="sb-item" id="sbCursor">Ln 1, Col 1</span>
  <span class="sb-item sb-diag">
    <span class="sev-error">✖ <span id="sbErrors">0</span></span>
    <span class="sev-warning">⚠ <span id="sbWarnings">0</span></span>
  </span>
  <span class="sb-grow"></span>
  <span class="sb-item" id="sbMode">Interpreted</span>
  <span class="sb-item"><a href="https://github.com/ApolloVM/apollovm_dart" target="_blank">ApolloVM <span id="apollovmVersion2"></span></a></span>
</footer>

<div id="hoverTip" class="hovertip hidden"></div>
<div id="completionPopup" class="completion hidden"></div>
'''
      .toJS;

  document.querySelector('#apollovmVersion')?.textContent = ApolloVM.VERSION;
  document.querySelector('#apollovmVersion2')?.textContent = ApolloVM.VERSION;

  setupCodeEditor();
  setupBottomResizer();
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

  var translateButton = selectTranslateButton();
  _listen(translateButton, 'click', (evt) => runConvert());

  var wasmCompiledCheck = selectWasmCompiledCheckbox();
  _listen(wasmCompiledCheck, 'click', (evt) => wasmCompiledChecked());

  // Bottom-panel tab switching.
  var btabs = document.querySelectorAll('.btab');
  for (var i = 0; i < btabs.length; i++) {
    var tab = btabs.item(i) as HTMLElement;
    var panel = tab.getAttribute('data-panel') ?? '';
    _listen(tab, 'click', (evt) => switchBottomPanel(panel));
  }
}

bool _bottomMaximized = false;
double _bottomRestoreHeight = 230;

/// Wires the draggable splitter above the bottom dock (drag to resize) and the
/// maximize/restore toggle in the dock's tab bar.
void setupBottomResizer() {
  var resizer = selectBottomResizer();
  var dock = selectBottomDock();
  var dragging = false;
  var startY = 0.0;
  var startH = 0.0;

  double maxHeight() => window.innerHeight * 0.85;

  double clampHeight(double h) {
    var mx = maxHeight();
    if (h < 90) return 90;
    if (h > mx) return mx;
    return h;
  }

  _listen(resizer, 'mousedown', (event) {
    var m = event as MouseEvent;
    dragging = true;
    startY = m.clientY.toDouble();
    startH = dock.getBoundingClientRect().height;
    resizer.classList.add('dragging');
    document.body?.style.userSelect = 'none';
    event.preventDefault();
  });

  _listen(document, 'mousemove', (event) {
    if (!dragging) return;
    var m = event as MouseEvent;
    var h = clampHeight(startH + (startY - m.clientY)); // drag up = taller
    dock.style.height = '${h}px';
    _bottomMaximized = false;
    selectBottomMaximize().textContent = '▴';
  });

  _listen(document, 'mouseup', (_) {
    if (!dragging) return;
    dragging = false;
    resizer.classList.remove('dragging');
    document.body?.style.userSelect = '';
  });

  _listen(selectBottomMaximize(), 'click', (_) {
    var btn = selectBottomMaximize();
    if (_bottomMaximized) {
      dock.style.height = '${_bottomRestoreHeight}px';
      _bottomMaximized = false;
      btn.textContent = '▴';
    } else {
      _bottomRestoreHeight = dock.getBoundingClientRect().height;
      dock.style.height = '${maxHeight()}px';
      _bottomMaximized = true;
      btn.textContent = '▾';
    }
  });
}

/// Activates the bottom panel [name] (`problems`, `output`, `result`,
/// `translation`) and its tab.
void switchBottomPanel(String name) {
  var tabs = document.querySelectorAll('.btab');
  for (var i = 0; i < tabs.length; i++) {
    var tab = tabs.item(i) as HTMLElement;
    var active = tab.getAttribute('data-panel') == name;
    tab.classList.toggle('btab-active', active);
  }
  var panels = document.querySelectorAll('.bpanel');
  for (var i = 0; i < panels.length; i++) {
    var panel = panels.item(i) as HTMLElement;
    var active = panel.id == 'panel-$name';
    panel.classList.toggle('bpanel-active', active);
  }
}
