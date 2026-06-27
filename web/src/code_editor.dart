part of '../main.dart';

/// Wires up the line-numbered code editor: gutter line numbers, scroll sync
/// between the gutter and the textarea, and Tab/Shift+Tab indentation.
void setupCodeEditor() {
  var codeTextArea = selectCodeTextArea();

  _listen(codeTextArea, 'input', (_) => updateCodeGutter());
  _listen(codeTextArea, 'scroll',
      (_) => selectCodeGutter().scrollTop = codeTextArea.scrollTop);

  _listen(codeTextArea, 'keydown',
      (event) => handleCodeEditorKeyDown(event as KeyboardEvent));
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

  var lineCount = '\n'.allMatches(codeTextArea.value).length + 1;

  gutter.textContent = List.generate(lineCount, (i) => '${i + 1}').join('\n');
  gutter.scrollTop = codeTextArea.scrollTop;
}

const _indent = '  ';

void handleCodeEditorKeyDown(KeyboardEvent event) {
  if (event.key != 'Tab') return;
  event.preventDefault();

  var codeTextArea = selectCodeTextArea();
  var value = codeTextArea.value;
  var start = codeTextArea.selectionStart;
  var end = codeTextArea.selectionEnd;

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
