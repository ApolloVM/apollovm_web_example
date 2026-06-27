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

HTMLButtonElement selectConvertButton() =>
    document.querySelector('#convert') as HTMLButtonElement;

HTMLDivElement selectConversionsPanel() =>
    document.querySelector('#conversionsPanel') as HTMLDivElement;

HTMLButtonElement selectConversionsClose() =>
    document.querySelector('#conversionsClose') as HTMLButtonElement;

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

HTMLPreElement selectVMResult() =>
    document.querySelector('#vmResult') as HTMLPreElement;

HTMLPreElement selectVMOutput() =>
    document.querySelector('#vmOutput') as HTMLPreElement;

HTMLPreElement selectVMExecutedCode() =>
    document.querySelector('#vmExecutedCode') as HTMLPreElement;
