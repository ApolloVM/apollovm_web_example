## 1.2.1

- Updated to ApolloVM 0.1.33 (adds `throw` and `try`/`catch`/`finally` exception
  handling for Dart, Java, Kotlin, JavaScript and TypeScript).
- Added "Exceptions (try/catch/finally)" examples to the Example picker for Dart,
  Java11, Kotlin, JavaScript and TypeScript (run with `b = 0` to take the
  throwing path); all examples are verified to run.

- apollovm: ^0.1.33

## 1.2.0

- Updated to ApolloVM 0.1.32 (adds Kotlin, JavaScript, TypeScript and Lua).
- Language selector now offers Dart, Java11, Kotlin, JavaScript, TypeScript and Lua.
- Added an "Example" picker with ready-to-run snippets for every language
  (including a Wasm-compilable Dart example); all examples are verified to run.
- New line-numbered code editor: gutter, scroll sync and Tab/Shift+Tab indentation.
- Improved dark theme: JetBrains Mono, refined palette, focus/hover states.
- Wasm-compiled run accepts a class-method entry point (via `allowClassMethod`),
  with a clear message when the entry point isn't present in the compiled module.

- apollovm: ^0.1.32
- dom_tools: ^3.0.0

## 1.1.2

- apollovm: ^0.0.53

## 1.1.1

- apollovm: ^0.0.52

## 1.1.0

- sdk: '>=3.3.0 <4.0.0'

- apollovm: ^0.0.51
- dom_tools: ^2.3.0
- swiss_knife: ^3.2.0
- data_serializer: ^1.1.0

- build_runner: ^2.4.8
- build_web_compilers: ^4.0.9
- lints: ^3.0.0

## 1.0.8

- apollovm: ^0.0.49

## 1.0.7

- apollovm: ^0.0.47

## 1.0.6

- apollovm: ^0.0.46

## 1.0.5

- apollovm: ^0.0.45

## 1.0.4

- apollovm: ^0.0.44

## 1.0.3

- Add option to run compiled to Wasm.
- apollovm: ^0.0.42

## 1.0.2

- apollovm: ^0.0.41

## 1.0.1

- Added `compileToWasm`.
- Added "Download Wasm" button.
- apollovm: ^0.0.40

## 1.0.0

- Initial Web Example version.
- apollovm: ^0.0.30
- collection: ^1.15.0
