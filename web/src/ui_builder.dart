part of '../main.dart';

void buildUI() {
  var exampleLangOptions = exampleCategories()
      .map(
        (c) => '<option value="$c">${_exampleLanguageLabels[c] ?? c}</option>',
      )
      .join('\n      ');

  document.querySelector('#app')?.innerHTML =
      '''
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
    <div class="side-tabs">
      <button class="side-tab" data-side="repo">Repository</button>
      <button class="side-tab side-tab-active" data-side="outline">Outline</button>
    </div>

    <div class="side-panel side-panel-active" id="outlinePanel" data-side-panel="outline">
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
          <option value="go">Go</option>
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
    </div>

    <div class="side-panel" id="repoPanel" data-side-panel="repo">
      <div class="repo-conn">
        <div class="repo-conn-row">
          <input id="repoHost" type="text" placeholder="host" value="127.0.0.1" spellcheck="false" autocomplete="off">
          <input id="repoPort" class="repo-port" type="text" placeholder="port" value="8090" spellcheck="false" autocomplete="off">
        </div>
        <div class="repo-conn-row">
          <button id="repoConnect" class="btn" title="Connect to a repository server (dart run tool/repository_server.dart)">Connect</button>
          <button id="repoSave" class="btn" title="Save the open file to the server (Ctrl/Cmd+S)">⤓ Save</button>
        </div>
        <div id="repoStatus" class="repo-status">Not connected.</div>
      </div>

      <div class="panel-head panel-head-bottom">Files</div>
      <div id="repoTree" class="tree"><div class="tree-empty">Not connected to a repository.</div></div>

      <div class="panel-head panel-head-bottom">
        Source Control
        <button id="repoRefresh" class="btn-mini" title="Refresh git status">⟳</button>
      </div>
      <div id="repoGit" class="git-list"><div class="tree-empty">Not connected.</div></div>
      <div class="repo-commit">
        <input id="repoCommitMsg" type="text" placeholder="Commit message" spellcheck="false" autocomplete="off">
        <button id="repoCommit" class="btn" title="Stage all changes and commit">Commit</button>
      </div>
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
        <button class="btab" data-panel="diff">Diff</button>
        <span class="bottom-tabs-spacer"></span>
        <button class="bottom-max" id="bottomMinimize" title="Minimize panel (more space for code)">▁</button>
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
        <div class="bpanel" id="panel-diff">
          <pre id="repoDiff" class="term muted">Select a changed file in Source Control to see its diff.</pre>
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
  setupRepository();
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
  _listen(
    exampleSelect,
    'change',
    (evt) => loadExample(int.parse(exampleSelect.value)),
  );

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

  // Sidebar tab switching (Outline / Repository share the same space).
  var sideTabs = document.querySelectorAll('.side-tab');
  for (var i = 0; i < sideTabs.length; i++) {
    var tab = sideTabs.item(i) as HTMLElement;
    var side = tab.getAttribute('data-side') ?? '';
    _listen(tab, 'click', (evt) => switchSidePanel(side));
  }
}

/// Activates the sidebar panel [name] (`outline` or `repo`) and its tab.
void switchSidePanel(String name) {
  var tabs = document.querySelectorAll('.side-tab');
  for (var i = 0; i < tabs.length; i++) {
    var tab = tabs.item(i) as HTMLElement;
    tab.classList.toggle(
      'side-tab-active',
      tab.getAttribute('data-side') == name,
    );
  }
  var panels = document.querySelectorAll('.side-panel');
  for (var i = 0; i < panels.length; i++) {
    var panel = panels.item(i) as HTMLElement;
    var active = panel.getAttribute('data-side-panel') == name;
    panel.classList.toggle('side-panel-active', active);
  }
}

bool _bottomMaximized = false;
bool _bottomMinimized = false;
double _bottomRestoreHeight = 230;

/// Wires the draggable splitter above the bottom dock (drag to resize) and the
/// minimize/maximize/restore toggles in the dock's tab bar.
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

  // Restores the dock to its last non-collapsed, non-maximized height and
  // syncs the toggle buttons/glyphs to the current state.
  void applyState(double? heightPx) {
    var minBtn = selectBottomMinimize();
    var maxBtn = selectBottomMaximize();
    dock.classList.toggle('bottom-collapsed', _bottomMinimized);
    resizer.style.display = _bottomMinimized ? 'none' : '';
    if (_bottomMinimized) {
      dock.style.height = '';
    } else if (heightPx != null) {
      dock.style.height = '${heightPx}px';
    }
    minBtn.textContent = _bottomMinimized ? '▔' : '▁';
    minBtn.title = _bottomMinimized
        ? 'Restore panel'
        : 'Minimize panel (more space for code)';
    maxBtn.textContent = _bottomMaximized ? '▾' : '▴';
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
    _bottomMinimized = false;
    applyState(null);
  });

  _listen(document, 'mouseup', (_) {
    if (!dragging) return;
    dragging = false;
    resizer.classList.remove('dragging');
    document.body?.style.userSelect = '';
  });

  _listen(selectBottomMinimize(), 'click', (_) {
    if (_bottomMinimized) {
      // Restore to the remembered height.
      _bottomMinimized = false;
      applyState(_bottomRestoreHeight);
    } else {
      // Collapse the dock to just its tab bar for maximum coding space.
      if (!_bottomMaximized) {
        _bottomRestoreHeight = dock.getBoundingClientRect().height;
      }
      _bottomMinimized = true;
      _bottomMaximized = false;
      applyState(null);
    }
  });

  _listen(selectBottomMaximize(), 'click', (_) {
    if (_bottomMaximized) {
      _bottomMaximized = false;
      applyState(_bottomRestoreHeight);
    } else {
      if (!_bottomMinimized) {
        _bottomRestoreHeight = dock.getBoundingClientRect().height;
      }
      _bottomMaximized = true;
      _bottomMinimized = false;
      applyState(maxHeight());
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
