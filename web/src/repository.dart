part of '../main.dart';

// Remote repository integration.
//
// Connects the IDE to an ApolloVM repository server (see the package's
// `tool/repository_server.dart`) over `host:port` using a [RemoteRepositoryAdapter].
// Once connected, the sidebar Explorer shows the project's file tree; clicking a
// file loads it into the editor (with the in-process LSP), Save writes it back,
// and the Source Control panel surfaces `git status`/`diff` and can commit.
//
// The client wraps the adapter in a [RepositoryService] with a permissive
// [RepoConfig]; the server is the real authority on what is actually permitted.

/// The active repository (null until a successful [connectRepo]).
RepositoryService? _repoService;
RemoteRepositoryAdapter? _repoAdapter;

/// Workspace-relative path of the file currently open from the repository
/// (empty when the editor holds an example rather than a repo file).
String _openRepoPath = '';

/// The last full tree listing and which directories are expanded.
List<RepoEntry> _repoEntries = const [];
final Set<String> _expandedDirs = <String>{};

/// The last `git status` result (drives the Source Control panel).
List<GitStatusEntry> _gitEntries = const [];

const _repoHostKey = 'apollovm.repo.host';
const _repoPortKey = 'apollovm.repo.port';

/// Wires the repository connection controls and restores the persisted
/// `host:port`. Called once from [buildUI].
void setupRepository() {
  final host = window.localStorage.getItem(_repoHostKey);
  final port = window.localStorage.getItem(_repoPortKey);
  if (host != null && host.isNotEmpty) selectRepoHost().value = host;
  if (port != null && port.isNotEmpty) selectRepoPort().value = port;

  _listen(selectRepoConnectButton(), 'click', (_) => connectRepo());
  _listen(selectRepoPort(), 'keydown', (e) {
    if ((e as KeyboardEvent).key == 'Enter') connectRepo();
  });
  _listen(selectRepoSaveButton(), 'click', (_) => saveRepoFile());
  _listen(selectRepoRefreshButton(), 'click', (_) => refreshGit());
  _listen(selectRepoCommitButton(), 'click', (_) => commitRepo());

  // Ctrl/Cmd+S saves the open repository file (instead of the browser dialog).
  _listen(selectCodeTextArea(), 'keydown', (event) {
    final e = event as KeyboardEvent;
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() == 's') {
      e.preventDefault();
      if (_repoService != null && _openRepoPath.isNotEmpty) saveRepoFile();
    }
  });

  renderTree();
  renderGit();
}

/// Connects to the repository server named in the connection inputs, loading the
/// file tree and git status on success. Persists the `host:port`.
Future<void> connectRepo() async {
  final host = selectRepoHost().value.trim();
  final port = int.tryParse(selectRepoPort().value.trim());
  if (host.isEmpty || port == null) {
    _setRepoStatus('Enter a host and a numeric port.', error: true);
    return;
  }

  window.localStorage.setItem(_repoHostKey, host);
  window.localStorage.setItem(_repoPortKey, '$port');

  _setRepoStatus('Connecting to $host:$port…');
  try {
    _repoAdapter?.close();
    final adapter = await RemoteRepositoryAdapter.connect('http://$host:$port');
    _repoAdapter = adapter;
    _repoService = RepositoryService(
      adapter,
      config: const RepoConfig(allowWrite: true, allowGitMutation: true),
    );

    final caps = adapter.capabilities;
    _setRepoStatus(
      'Connected · ${caps.canWrite ? 'read/write' : 'read-only'}'
      '${caps.supportsGit ? ' · git' : ''}',
    );
    selectRepoPanel().classList.add('repo-connected');
    _expandedDirs.clear();
    await refreshTree();
    await refreshGit();
  } catch (e) {
    _repoService = null;
    _repoAdapter = null;
    selectRepoPanel().classList.remove('repo-connected');
    _repoEntries = const [];
    _gitEntries = const [];
    renderTree();
    renderGit();
    _setRepoStatus('$e', error: true);
  }
}

/// Reloads the whole file tree from the server.
Future<void> refreshTree() async {
  final svc = _repoService;
  if (svc == null) return;
  try {
    _repoEntries = await svc.list('', recursive: true);
  } catch (e) {
    _repoEntries = const [];
    _setRepoStatus('$e', error: true);
  }
  renderTree();
}

/// Renders the (partially expanded) file tree into the Explorer panel.
void renderTree() {
  final container = selectRepoTree();
  if (_repoService == null) {
    container.innerHTML =
        '<div class="tree-empty">Not connected to a repository.</div>'.toJS;
    return;
  }
  if (_repoEntries.isEmpty) {
    container.innerHTML =
        '<div class="tree-empty">Empty repository.</div>'.toJS;
    return;
  }

  final entries = [..._repoEntries]..sort((a, b) => a.path.compareTo(b.path));
  final buf = StringBuffer();
  for (final e in entries) {
    if (!_isVisible(e.path)) continue;
    final depth = '/'.allMatches(e.path).length;
    final expanded = _expandedDirs.contains(e.path);
    final twist = e.isDir ? (expanded ? '▾' : '▸') : '';
    final icon = e.isDir ? '📁' : '📄';
    final active = e.path == _openRepoPath ? ' tree-row-active' : '';
    buf.write(
      '<div class="tree-row$active" data-path="${_esc(e.path)}" '
      'data-dir="${e.isDir}" style="padding-left:${6 + depth * 14}px">'
      '<span class="tree-twist">$twist</span>'
      '<span class="tree-icon">$icon</span>'
      '<span class="tree-name">${_esc(e.name)}</span>'
      '</div>',
    );
  }
  container.innerHTML = buf.toString().toJS;

  final rows = container.querySelectorAll('.tree-row');
  for (var i = 0; i < rows.length; i++) {
    final row = rows.item(i) as HTMLElement;
    final path = row.getAttribute('data-path') ?? '';
    final isDir = row.getAttribute('data-dir') == 'true';
    _listen(row, 'click', (_) {
      if (isDir) {
        _toggleDir(path);
      } else {
        openRepoFile(path);
      }
    });
  }
}

/// Whether every ancestor directory of [path] is currently expanded.
bool _isVisible(String path) {
  final parts = path.split('/');
  for (var i = 1; i < parts.length; i++) {
    if (!_expandedDirs.contains(parts.sublist(0, i).join('/'))) return false;
  }
  return true;
}

void _toggleDir(String path) {
  if (!_expandedDirs.remove(path)) _expandedDirs.add(path);
  renderTree();
}

/// Opens the repository file at [path] in the editor and runs the LSP when the
/// extension maps to a supported ApolloVM language.
Future<void> openRepoFile(String path) async {
  final svc = _repoService;
  if (svc == null) return;
  try {
    final file = await svc.read(path);
    _openRepoPath = path;

    final language = _languageForPath(path);
    if (language != null) {
      selectCodeLanguage().value = language;
      selectCodeTextArea().setAttribute('language', language);
    } else {
      // No ApolloVM parser for this extension: show it as plain text.
      selectCodeTextArea().setAttribute('language', '');
    }

    setCodeEditorText(file.content);
    selectFileName().textContent = path;

    if (language != null) {
      await runLspAnalysis();
    } else {
      _setDiagnostics(const []);
      selectOutline().innerHTML =
          '<div class="outline-empty">No language server for this file.</div>'
              .toJS;
    }

    await _loadGitBase(path); // draw the git change bar
    renderTree(); // refresh the active-row highlight
    _setRepoStatus(
      'Opened $path${file.truncated ? ' (truncated)' : ''}',
    );
  } catch (e) {
    _setRepoStatus('$e', error: true);
  }
}

/// Writes the editor buffer back to the open repository file.
Future<void> saveRepoFile() async {
  final svc = _repoService;
  if (svc == null || _openRepoPath.isEmpty) {
    _setRepoStatus('No repository file is open.', error: true);
    return;
  }
  try {
    await svc.write(_openRepoPath, selectCodeTextArea().value);
    _setRepoStatus('Saved $_openRepoPath');
    await refreshGit();
  } catch (e) {
    _setRepoStatus('$e', error: true);
  }
}

/// Reloads `git status` into the Source Control panel.
Future<void> refreshGit() async {
  final svc = _repoService;
  if (svc == null || !svc.capabilities.supportsGit) {
    _gitEntries = const [];
    renderGit();
    return;
  }
  try {
    _gitEntries = await svc.gitStatus();
  } catch (e) {
    _gitEntries = const [];
    _setRepoStatus('$e', error: true);
  }
  renderGit();
}

/// Renders the Source Control (git) panel.
void renderGit() {
  final container = selectRepoGit();
  final svc = _repoService;
  if (svc == null) {
    container.innerHTML = '<div class="tree-empty">Not connected.</div>'.toJS;
    return;
  }
  if (!svc.capabilities.supportsGit) {
    container.innerHTML =
        '<div class="tree-empty">Not a git repository.</div>'.toJS;
    return;
  }
  if (_gitEntries.isEmpty) {
    container.innerHTML =
        '<div class="tree-empty">No changes — working tree clean.</div>'.toJS;
    return;
  }

  final buf = StringBuffer();
  for (final e in _gitEntries) {
    final code = e.status.trim().isEmpty ? '·' : e.status.trim();
    buf.write(
      '<div class="git-row" data-path="${_esc(e.path)}" title="git status: ${_esc(e.status)}">'
      '<span class="git-code">${_esc(code)}</span>'
      '<span class="git-path">${_esc(e.path)}</span>'
      '</div>',
    );
  }
  container.innerHTML = buf.toString().toJS;

  final rows = container.querySelectorAll('.git-row');
  for (var i = 0; i < rows.length; i++) {
    final row = rows.item(i) as HTMLElement;
    final path = row.getAttribute('data-path') ?? '';
    _listen(row, 'click', (_) {
      openRepoFile(path);
      showRepoDiff(path);
    });
  }
}

/// Shows the diff of [path] in the bottom dock's Diff tab.
Future<void> showRepoDiff(String path) async {
  final svc = _repoService;
  if (svc == null) return;
  switchBottomPanel('diff');
  final pre = selectRepoDiff();
  pre.textContent = 'Loading diff…';
  try {
    final diff = await svc.gitDiff(path: path);
    pre.textContent = diff.isEmpty ? '(no differences)' : diff;
  } catch (e) {
    pre.textContent = '$e';
  }
}

/// Stages every changed path and commits with the message in the commit input.
Future<void> commitRepo() async {
  final svc = _repoService;
  if (svc == null) {
    _setRepoStatus('Not connected.', error: true);
    return;
  }
  final message = selectRepoCommitMsg().value.trim();
  if (message.isEmpty) {
    _setRepoStatus('Enter a commit message.', error: true);
    return;
  }
  try {
    final paths = _gitEntries.map((e) => e.path).toList();
    if (paths.isNotEmpty) await svc.gitAdd(paths);
    final result = await svc.gitCommit(message);
    if (result.ok) {
      _setRepoStatus('Committed: $message');
      selectRepoCommitMsg().value = '';
    } else {
      _setRepoStatus('Commit failed: ${result.output}', error: true);
    }
    await refreshGit();
    // HEAD moved: refresh the change bar against the new baseline.
    if (_openRepoPath.isNotEmpty) await _loadGitBase(_openRepoPath);
  } catch (e) {
    _setRepoStatus('$e', error: true);
  }
}

// ---- Editor git change bar (VS Code-style gutter markers) ----

/// HEAD content of the open repository file, diffed against the live editor
/// buffer to draw per-line change bars. Null when the buffer isn't a
/// git-tracked repository file (e.g. an example, or a non-git server).
String? _gitBase;

/// 0-based buffer line → change kind (`added` | `modified`).
final Map<int, String> _gitLineStatus = {};

/// 0-based buffer lines that have deleted line(s) immediately above them.
final Set<int> _gitDeletionsAbove = {};

/// Whether line(s) were deleted after the last buffer line.
bool _gitDeletionAtEnd = false;

/// Loads the HEAD version of [path] (for the git change bar), then repaints the
/// gutter. A file absent from HEAD (new/untracked) counts as all-added.
Future<void> _loadGitBase(String path) async {
  final svc = _repoService;
  if (svc == null || !svc.capabilities.supportsGit) {
    _gitBase = null;
  } else {
    try {
      _gitBase = await svc.gitShow(rev: 'HEAD', path: path);
    } catch (_) {
      _gitBase = ''; // not in HEAD → treat every line as added
    }
  }
  updateCodeGutter();
}

/// Clears the editor git change bars (e.g. when loading an example).
void clearGitGutter() {
  _gitBase = null;
  _gitLineStatus.clear();
  _gitDeletionsAbove.clear();
  _gitDeletionAtEnd = false;
}

/// Signature of the last (base, buffer) the markers were computed for, so a
/// gutter rebuild that isn't triggered by a content change (e.g. a diagnostics
/// refresh) reuses the previous result instead of re-diffing.
String? _lastGitBaseRef;
String? _lastGitBufferRef;

/// Recomputes per-line git markers from [_gitBase] vs the current buffer.
/// A cheap no-op when no repository file is open or the buffer is unchanged;
/// called by [updateCodeGutter] so the bars stay live as the user types.
void computeGitDiffMarkers() {
  final base = _gitBase;
  final buffer = selectCodeTextArea().value;
  if (identical(base, _lastGitBaseRef) && buffer == _lastGitBufferRef) return;
  _lastGitBaseRef = base;
  _lastGitBufferRef = buffer;

  _gitLineStatus.clear();
  _gitDeletionsAbove.clear();
  _gitDeletionAtEnd = false;

  if (base == null) return;

  final baseLines = base.split('\n');
  final bufLines = buffer.split('\n');
  // Keep typing snappy: skip the O(n*m) diff for very large files.
  if (baseLines.length > 1500 || bufLines.length > 1500) return;

  for (final h in _diffLines(baseLines, bufLines)) {
    if (h.newCount > 0) {
      final kind = h.oldCount > 0 ? 'modified' : 'added';
      for (var i = h.newStart; i < h.newStart + h.newCount; i++) {
        _gitLineStatus[i] = kind;
      }
    } else if (h.oldCount > 0) {
      if (h.newStart >= bufLines.length) {
        _gitDeletionAtEnd = true;
      } else {
        _gitDeletionsAbove.add(h.newStart);
      }
    }
  }
}

/// A contiguous change region between two line lists.
class _Hunk {
  final int oldStart, oldCount, newStart, newCount;
  const _Hunk(this.oldStart, this.oldCount, this.newStart, this.newCount);
}

/// Minimal LCS-based line diff returning the change hunks between [a] and [b].
List<_Hunk> _diffLines(List<String> a, List<String> b) {
  final n = a.length, m = b.length;
  final lcs = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      lcs[i][j] = a[i] == b[j]
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }

  final hunks = <_Hunk>[];
  var i = 0, j = 0;
  while (i < n && j < m) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    final os = i, ns = j;
    while (i < n && j < m && a[i] != b[j]) {
      if (lcs[i + 1][j] >= lcs[i][j + 1]) {
        i++;
      } else {
        j++;
      }
    }
    hunks.add(_Hunk(os, i - os, ns, j - ns));
  }
  if (i < n || j < m) hunks.add(_Hunk(i, n - i, j, m - j));
  return hunks;
}

void _setRepoStatus(String text, {bool error = false}) {
  final el = selectRepoStatus();
  el.textContent = text;
  el.classList.toggle('repo-status-error', error);
}

/// Maps a file extension to an editor language id, or null when ApolloVM has no
/// parser for it.
String? _languageForPath(String path) {
  final dot = path.lastIndexOf('.');
  final ext = dot >= 0 ? path.substring(dot + 1).toLowerCase() : '';
  switch (ext) {
    case 'dart':
      return 'dart';
    case 'java':
      return 'java11';
    case 'kt':
    case 'kts':
      return 'kotlin';
    case 'cs':
      return 'csharp';
    case 'js':
      return 'javascript';
    case 'ts':
      return 'typescript';
    case 'lua':
      return 'lua';
    case 'py':
      return 'python';
    default:
      return null;
  }
}
