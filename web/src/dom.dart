part of '../main.dart';

/// Adds [handler] for DOM events of [type] on [target] (replaces dart:html's
/// `element.onX.listen(...)` Stream API).
void _listen(EventTarget target, String type, void Function(Event) handler) =>
    target.addEventListener(type, handler.toJS);

HTMLInputElement selectClassName() =>
    document.querySelector('#className') as HTMLInputElement;

HTMLInputElement selectFunctionName() =>
    document.querySelector('#functionName') as HTMLInputElement;

HTMLInputElement selectPositionalParametersJson() =>
    document.querySelector('#positionalParametersJson') as HTMLInputElement;

HTMLInputElement selectNamedParametersJson() =>
    document.querySelector('#namedParametersJson') as HTMLInputElement;

HTMLSelectElement selectExampleLangSelect() =>
    document.querySelector('#exampleLangSelect') as HTMLSelectElement;

HTMLSelectElement selectExampleSelect() =>
    document.querySelector('#exampleSelect') as HTMLSelectElement;

HTMLSelectElement selectCodeLanguage() =>
    document.querySelector('#codeLang') as HTMLSelectElement;

HTMLButtonElement selectDownloadWasmButton() =>
    document.querySelector('#download-wasm') as HTMLButtonElement;

HTMLButtonElement selectRunButton() =>
    document.querySelector('#run') as HTMLButtonElement;

HTMLButtonElement selectTranslateButton() =>
    document.querySelector('#translate-btn') as HTMLButtonElement;

HTMLDivElement selectConversionTabs() =>
    document.querySelector('#conversionTabs') as HTMLDivElement;

HTMLPreElement selectConversionOutput() =>
    document.querySelector('#conversionOutput') as HTMLPreElement;

HTMLInputElement selectWasmCompiledCheckbox() =>
    document.querySelector('#wasm-compiled') as HTMLInputElement;

bool get wasmCompiledCheck => selectWasmCompiledCheckbox().checked;

HTMLTextAreaElement selectCodeTextArea() =>
    document.querySelector('#code') as HTMLTextAreaElement;

HTMLDivElement selectCodeGutter() =>
    document.querySelector('#codeGutter') as HTMLDivElement;

HTMLPreElement selectCodeHighlight() =>
    document.querySelector('#codeHighlight') as HTMLPreElement;

HTMLPreElement selectCodeSyntax() =>
    document.querySelector('#codeSyntax') as HTMLPreElement;

HTMLElement selectFileName() =>
    document.querySelector('#fileName') as HTMLElement;

// ---- LSP panels ----

HTMLDivElement selectOutline() =>
    document.querySelector('#outline') as HTMLDivElement;

HTMLDivElement selectProblemsList() =>
    document.querySelector('#problemsList') as HTMLDivElement;

HTMLElement selectProblemsBadge() =>
    document.querySelector('#problemsBadge') as HTMLElement;

HTMLElement selectStatusCursor() =>
    document.querySelector('#sbCursor') as HTMLElement;

HTMLElement selectStatusErrors() =>
    document.querySelector('#sbErrors') as HTMLElement;

HTMLElement selectStatusWarnings() =>
    document.querySelector('#sbWarnings') as HTMLElement;

HTMLElement selectStatusMode() =>
    document.querySelector('#sbMode') as HTMLElement;

HTMLDivElement selectHoverTip() =>
    document.querySelector('#hoverTip') as HTMLDivElement;

HTMLDivElement selectCompletionPopup() =>
    document.querySelector('#completionPopup') as HTMLDivElement;

HTMLDivElement selectBottomResizer() =>
    document.querySelector('#bottomResizer') as HTMLDivElement;

HTMLElement selectBottomDock() =>
    document.querySelector('#bottomDock') as HTMLElement;

HTMLButtonElement selectBottomMaximize() =>
    document.querySelector('#bottomMaximize') as HTMLButtonElement;

HTMLButtonElement selectBottomMinimize() =>
    document.querySelector('#bottomMinimize') as HTMLButtonElement;

HTMLPreElement selectVMResult() =>
    document.querySelector('#vmResult') as HTMLPreElement;

HTMLPreElement selectVMOutput() =>
    document.querySelector('#vmOutput') as HTMLPreElement;

HTMLPreElement selectVMExecutedCode() =>
    document.querySelector('#vmExecutedCode') as HTMLPreElement;

// ---- Repository (remote workspace) ----

HTMLElement selectRepoPanel() =>
    document.querySelector('#repoPanel') as HTMLElement;

HTMLInputElement selectRepoHost() =>
    document.querySelector('#repoHost') as HTMLInputElement;

HTMLInputElement selectRepoPort() =>
    document.querySelector('#repoPort') as HTMLInputElement;

HTMLButtonElement selectRepoConnectButton() =>
    document.querySelector('#repoConnect') as HTMLButtonElement;

HTMLElement selectRepoStatus() =>
    document.querySelector('#repoStatus') as HTMLElement;

HTMLDivElement selectRepoTree() =>
    document.querySelector('#repoTree') as HTMLDivElement;

HTMLButtonElement selectRepoSaveButton() =>
    document.querySelector('#repoSave') as HTMLButtonElement;

HTMLDivElement selectRepoGit() =>
    document.querySelector('#repoGit') as HTMLDivElement;

HTMLButtonElement selectRepoRefreshButton() =>
    document.querySelector('#repoRefresh') as HTMLButtonElement;

HTMLInputElement selectRepoCommitMsg() =>
    document.querySelector('#repoCommitMsg') as HTMLInputElement;

HTMLButtonElement selectRepoCommitButton() =>
    document.querySelector('#repoCommit') as HTMLButtonElement;

HTMLPreElement selectRepoDiff() =>
    document.querySelector('#repoDiff') as HTMLPreElement;
