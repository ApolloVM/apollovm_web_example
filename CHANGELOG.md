## 1.5.1

- Refactored the playground: split the monolithic `web/main.dart` into a
  `part`-based library under `web/src/`:
  - `code_examples.dart`: `CodeExample` data + category helpers.
  - `ui_builder.dart`: `buildUI()` — HTML template + event wiring.
  - `dom.dart`: `_listen()` + DOM `selectX()` helpers.
  - `code_editor.dart`: line-numbered code editor.
  - `vm.dart`: ApolloVM execute / compile / convert.
  - `actions.dart`: UI action handlers + output panel.
- Removed the unused `dart:js_interop` import and the IDE module file
  `apollovm_web_example.iml`.
- No functional changes.

## 1.5.0

- Updated to ApolloVM 0.1.40, folding in 0.1.38 and 0.1.39:
  - 0.1.38: `switch`/`case`, `do`/`while`, `break`/`continue`, bitwise operators,
    C# lambda parsing and enum declarations.
  - 0.1.39: enum runtime value access and generic classes (Box<T>).
  - 0.1.40: Wasm now compiles `switch`/`case`, `do`/`while` and the bitwise
    operators; Kotlin/Lua gain bitwise operators; Kotlin member visibility.
- Added "Example" picker entries (all verified to run — interpreted via ApolloVM,
  Wasm examples executed end-to-end in the browser):
  - "C# — Lambdas": anonymous functions bound to a `Func` delegate.
  - "Switch/case" for Dart, Java11, JavaScript, TypeScript and C#, "When (switch)"
    for Kotlin and "Match/case" for Python (each mapped to the language's idiom).
    Run with `2`.
  - "Do/while loop" for Dart and Kotlin, and "Repeat/until loop" for Lua. Run
    with `3`.
  - "Bitwise" for Dart, Java11, C# (`& | ^ << >> ~`), Kotlin (`and/or/xor/shl/shr`)
    and Lua (`& | ~ << >>`). Run with `12, 10` (Lua uses literals).
  - "Enum (ordinal value)" for Dart, Java11, Kotlin and Python, and
    "Enum (explicit values)" for C# — an enum entry resolves to its value.
  - "Generics (Box<T>)" for Dart, Java11, Kotlin, TypeScript and C#: a generic
    class instantiated with a type argument. Run with `10`.
  - Wasm: "Switch/case (n % 3)", "Bit count (& >>)" and "Do/while sum 1..N",
    exercising the new 0.1.40 Wasm control-flow / bitwise support.

- apollovm: ^0.1.40

## 1.4.0

- Updated to ApolloVM 0.1.37, which adds C# language support and lambda/anonymous
  function parsing for Java, Kotlin and Lua (plus Wasm fixes for host-import call
  indices and closure capture-by-reference).
- Added C# to the language selectors (example category and run language) and to
  the "Convert to all languages" transpilation targets.
- Added "Example" picker entries (all verified to run):
  - "C# — Class", "C# — Conditional (a > b ? a : b)" and
    "C# — Exceptions (try/catch/finally)".
  - "Java11 — Lambdas", "Kotlin — Lambdas" and "Lua — Lambdas": anonymous
    functions stored in variables and invoked — these now parse in 0.1.37 (they
    were previously interpreter-unsupported and omitted from the lambdas group).

- apollovm: ^0.1.37

## 1.3.0

- Updated to ApolloVM 0.1.36, which adds Python language support (0.1.35) and
  conditional/ternary expressions plus anonymous functions (lambdas/closures)
  (0.1.36).
- Language selector now offers Python (Dart, Java11, Kotlin, JavaScript,
  TypeScript, Lua and Python).
- Added "Example" picker entries (all verified to run):
  - "Python — Class": a class with a method, idiomatic snake_case and `self`.
  - "Conditional (ternary)" for Dart, Java11, Kotlin, JavaScript, TypeScript and
    Python, each using its native idiom (`?:`, Kotlin `if`/`else` expression,
    Python `a if c else b`). Run with `40, 130`.
  - "Lambdas (closures)" for Dart, JavaScript, TypeScript and Python: function
    values stored in variables and invoked. Run with `5`.
  - "Dart — Async/await (Future)": a class whose `async` methods `await` one
    another (run with `5`), and a top-level `async` function returning a
    `Future<int>` whose awaited value lands in the "result" panel (run with
    `10, 20`). Currently only Dart's async/await parses in ApolloVM.
- The example picker is now two linked selectors: a "Language" selector that
  filters a "Example" selector to that language's snippets (the redundant
  `<Language> — ` name prefix is dropped). Switching language loads that
  language's first example.
- Added a "Wasm" category to the example Language selector with extra
  Wasm-compatible examples (Fibonacci, Factorial, GCD, Power, Sum 1..N, Collatz
  steps, Prime check, and a single-class instance method). Selecting a Wasm
  example enables the "Wasm compiled" run mode automatically; all are verified
  end-to-end in the browser via the Wasm-compiled path (including `print`
  marshalling from the module and a class instantiated inside the entry point).
- New "Convert to all languages" button: transpiles the current code into every
  other supported language at once (Dart, Java11, Kotlin, JavaScript,
  TypeScript, Lua, Python) and shows the results in a tabbed panel — making
  ApolloVM's cross-language code generation a first-class, one-click feature
  (the source is parsed once and generated for each target).
- Migrated the web UI from the deprecated `dart:html` to `package:web` +
  `dart:js_interop` (DOM access via `document.querySelector`, events via
  `addEventListener`, `innerHTML`/`textContent`/`classList`). Verified end-to-end
  in a headless browser (UI builds and RUN executes the VM).

- apollovm: ^0.1.36
- web: ^1.1.0

## 1.2.2

- Updated to ApolloVM 0.1.34 (compiles `throw` and `try`/`catch`/`finally`
  exception handling to WebAssembly, on top of the interpreted support added in
  0.1.33).

- apollovm: ^0.1.34

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
