## 1.15.0

### Remote repository support — open, edit and version-control a real project

- **Connect to a repository server** (`host:port`) served by ApolloVM 1.8.0's
  `tool/repository_server.dart`, via the new `RemoteRepositoryAdapter`. The
  connection `host:port` is remembered across reloads (localStorage).
- **File tree explorer**: browse the served project, expand directories, and open
  files into the editor with syntax highlighting + the in-process language server.
- **Edit & save**: write changes back to the server (Save button / `Ctrl`+`S`).
- **Source Control panel**: `git status` of the working tree, per-file `git diff`
  in a new bottom-dock **Diff** tab, and stage-all + **commit**.
- **Editor git change bar**: VS Code-style per-line markers at the gutter's edge —
  green (added), blue (modified), red triangle (deleted) — diffed live against
  `HEAD` as you type.
- **Sidebar tabs**: the **Repository** and **Outline** panels now share one column
  as selectable tabs (Repository first); Run Configuration lives inside the
  Outline tab.
- Updated to **ApolloVM 1.8.0**.

## 1.14.3

- Updated to **ApolloVM 1.6.3**: the Outline now fully selects body-less
  constructors (and abstract methods) — including their parameters/signature —
  for both classes and enums.
- apollovm: ^1.6.3

## 1.14.2

- Updated to **ApolloVM 1.6.2**: the Outline now fully selects methods with an
  expression body (`=> expr;`) — for both classes and enums — instead of just
  their signature.
- apollovm: ^1.6.2

## 1.14.1

- Updated to **ApolloVM 1.6.1**: the Outline now handles members declared after
  an enum's constant list — selecting an enum method includes its body, and enum
  constructors/fields are recognized (previously they were mis-parsed as enum
  constants). Class members were already handled correctly.
- apollovm: ^1.6.1

## 1.14.0

- **Bottom dock: minimize.** Added a minimize button beside the existing
  maximize toggle. It collapses the dock (Problems / Output / Result /
  Translation) down to just its tab bar, giving the editor the maximum vertical
  space; clicking it again — or Maximize, or dragging the splitter — restores it.
  The minimize and maximize toggles are mutually exclusive and stay in sync.
- **Outline: click to jump, click again to select.** The first click on an
  Outline entry moves the caret to the symbol's name (as before); clicking the
  same entry again selects the element's whole text in the editor. For methods
  this now includes the body (see the ApolloVM 1.6.0 note below).
- Updated to **ApolloVM 1.6.0**, which powers the LSP improvements:
  - `documentSymbol` ranges now span a member's whole body, so selecting a
    method from the Outline selects the entire method, not just its signature.
  - Completion on `this.` / `super.` proposes the enclosing type's members
    (fields and methods, with their real kinds), and completions keep their
    proper kinds even while the buffer does not parse.
- Verified: `dart analyze` is clean and the release build compiles against 1.6.0.
- apollovm: ^1.6.0

## 1.13.1

- Apply `dart format` to the new IDE sources (`web/src/lsp.dart`,
  `highlight.dart`, `completion.dart`) — fixes the failing formatting check in CI
  for 1.13.0. No functional changes.

## 1.13.0

- **Reworked the playground into an IDE-like layout** (VS Code / IntelliJ style)
  driven by ApolloVM's in-process Language Server (`LspService` from
  `package:apollovm/apollovm_lsp.dart`) — everything runs client-side, no backend:
  - **Title bar** (brand + Examples pickers), an **Outline** sidebar fed by LSP
    document symbols (click to jump) with the **Language** selector, a
    **Run Configuration** box at the sidebar bottom (Run + Wasm toggle, entry
    point / parameters, Download Wasm), the editor, a resizable/maximizable
    bottom dock (**Problems / Output / Result / Translation**), and a status bar
    (cursor Ln/Col, error/warning counts, run mode, version).
  - **Live diagnostics**: red/yellow squiggles under the code, gutter markers, a
    Problems list (click to jump) and status-bar counts, re-analyzed as you type.
  - **Hover** info, **document-symbol Outline**, and **code completion** (a popup
    at the caret; ↑/↓ to move, Enter/Tab to accept, Esc to dismiss,
    Ctrl/Cmd+Space to trigger).
  - **Per-language syntax highlighting** (keywords, types, strings, numbers,
    functions, comments) rendered under the editable text, switching with the
    selected language.
  - The **Translation** panel holds the transpile control and per-language tabs.
- Updated to **ApolloVM 1.5.0**, which powers the new editor features:
  - Completion now surfaces in-scope identifiers (local variables/parameters) and
    keeps working while the buffer does not parse — so the completion popup is
    useful mid-edit, not just keyword-only.
  - Parse-error diagnostics locate a missing `;` on the offending line (Dart/
    Java/C#) instead of defaulting to the top of the file.
- Verified: `dart analyze` is clean and the release build compiles against 1.5.0.
- apollovm: ^1.5.0

## 1.12.1

- Docs: fix the live demo URL — the playground is served at the site root
  (`https://apollovm.github.io/apollovm_web_example/`), not the old `/www/`
  path.

## 1.12.0

- Updated to ApolloVM 1.4.1 (from 1.3.0), folding in 1.4.0. This is a
  tooling/API release — the core `package:apollovm/apollovm.dart` surface this
  playground uses is unchanged, so no example code changed:
  - 1.4.0: the MCP server now exposes ApolloVM's LSP features as `apollovm.lsp.*`
    tools (diagnostics, symbols, hover, definition, references, completion,
    workspace-symbol search), so an AI agent can inspect code like an editor;
    plus a new in-process `LspService` in `package:apollovm/apollovm_lsp.dart`
    (no socket/handshake, `dart:io`-free).
  - 1.4.1: the MCP server and all its tools are now web-compatible —
    `package:apollovm/apollovm_mcp.dart` is free of `dart:io`/`dart:isolate`, so
    they compile and run under dart2js/DDC (the `dart:io`-only stdio/HTTP
    transports and CLI moved to `package:apollovm/apollovm_mcp_io.dart`).
- Verified: `dart analyze` is clean and the web build compiles against 1.4.1.
- apollovm: ^1.4.1

## 1.11.0

- Updated to ApolloVM 1.3.0 (from 0.1.47), the package's first stable 1.x line.
  The versions folded in are additive — the core `package:apollovm/apollovm.dart`
  API this playground uses is unchanged, so no example code changed:
  - 0.1.48: the `apollovm` CLI's `run` now executes `.wasm` binaries through the
    Wasm runtime (`apollovm run foo.wasm`), closing the `compile` → `run` loop;
    `.wasm` maps to the `wasm` language.
  - 1.2.0 / 1.2.1: a Dart-first **Language Server Protocol** server ships as a
    separate library `package:apollovm/apollovm_lsp.dart` (diagnostics, symbols,
    hover, definition, references, rename, completion), runnable over stdio via
    `apollovm lsp` or embedded/web with no `dart:io`.
  - 1.3.0: LSP `documentHighlight` and `prepareRename` server features, plus a
    new `LspClient` (and `LspClient.inProcess()`) that drives the server in a
    single isolate.
- Verified: `dart analyze` is clean and the web build compiles against 1.3.0.
- apollovm: ^1.3.0

## 1.10.0

- Updated to ApolloVM 0.1.47, folding in 0.1.46. Together these bring broad
  Dart → WebAssembly coverage across all languages:
  - 0.1.46: `num` (TypeScript/JavaScript `number`) support; `switch` on a boxed
    scrutinee; scalar `Object`/`dynamic` entry-point parameters are now
    marshalled (fixing the JavaScript/Lua/Python examples that previously saw
    all arguments as `0`); anonymous functions with untyped parameters; and
    generic `Box<T>` (Dart/Java/Kotlin/C#/TypeScript).
  - 0.1.47: `/` on integer operands is truncating integer division in
    Java/Kotlin/C# (Dart keeps `~/`); integer division by zero raises a
    catchable exception matching the interpreter.
  - With this, every "Example" picker entry except `Dart — Async/await (Future)`
    compiles to and runs on Wasm (verified across all eight languages).
- Added "Wasm" examples for the newly-supported features (verified to compile to
  and run on Wasm):
  - "Generics (Box<T>)": a value flows through a generic `T` field and is
    unboxed for arithmetic.
  - "Integer division (by zero)": `~/` by zero raises a catchable exception.
- apollovm: ^0.1.47

## 1.9.0

- Updated to ApolloVM 0.1.45, which closes more Dart → WebAssembly backend gaps:
  - `Map`/`List` → `String` coercion in `print(...)` / interpolation (renders
    Dart's `{k: v, …}` / `[e, …]` form).
  - Arithmetic and comparison on boxed `Object`/`dynamic` operands (e.g.
    `args[1] ~/ 2` from a `List<Object>`), unboxed to a concrete number first.
  - Anonymous functions stored in a `var` and called by name.
- Added "Wasm" examples for the newly-supported features (verified to compile to
  and run on Wasm):
  - "Maps & boxed args": builds a `<String,int>` map from boxed `List<Object>`
    elements and prints it.
  - "Lambdas": a `var`-stored closure invoked by name.
- apollovm: ^0.1.45

## 1.8.0

- Updated to ApolloVM 0.1.44, which fixes rich-enum field/method reads in a
  `print` / string-interpolation context on Wasm (e.g. `print(p.gravity)` /
  `print('${p.mult(2)}')`) — previously these produced garbage values because
  the enum-entry initializer baked its constructor call index before the
  `print`/`double_to_str` host imports shifted the function indices.
- Added a "Wasm — Rich enum (field in print)" example: it prints an entry's
  `gravity`, `name`/`index` and a method result, and returns `mars.index`
  (verified to compile to and run on Wasm).
- apollovm: ^0.1.44

## 1.7.0

- Updated to ApolloVM 0.1.43, which closes several Dart → WebAssembly backend
  gaps: unqualified sibling `static` class-method calls (including with named
  arguments and omitted default parameters), `String + <number>` concatenation,
  `switch` on a `String`/`enum` scrutinee, rich-enum methods taking an
  enum-typed parameter, C#/TypeScript explicit-value enum `.value`, and typed
  catch-all clauses.
- Added two "Wasm" examples exercising the 0.1.43 class-method fix (both
  verified to compile to and run on Wasm):
  - "Named arguments (class method)": a method calls a sibling `static` method
    with named arguments.
  - "Default parameters (class method)": a call omits an optional parameter,
    which falls back to its declared default.
- Expanded the "Dart — Rich enum" example to show entry methods: `mult(double)`
  and `ratio(Planet)` (an enum-typed parameter), alongside `gravity`,
  `index` and `name`.
- apollovm: ^0.1.43

## 1.6.0

- Updated to ApolloVM 0.1.42, folding in 0.1.41:
  - 0.1.41: rich enums — each enum entry is a cached `const` class instance
    (identity `==`) carrying `index` and `name`, with `EnumName.values`; Dart
    enhanced enums (constructor args, fields, methods) and explicit-value
    entries (`.value`) are supported, including in Wasm.
  - 0.1.42: named / keyword arguments for function, method and constructor
    calls (Dart `foo(a: 1)`, Kotlin `foo(a = 1)`, C# `foo(a: 1)`, Python
    `foo(a=1)`); default values for optional and named parameters; and a new
    `apollovm compile` CLI command targeting WebAssembly. Named arguments and
    defaults are also handled by the on-the-fly Wasm compiler.
- Adapted the playground examples to ApolloVM 0.1.42's stricter entry-point
  rule (only a `static` class method or a top-level function can run without a
  class instance):
  - Dart/Java/C# examples now declare the entry method `static`.
  - Kotlin/JavaScript/TypeScript/Lua/Python examples use a top-level `main(...)`
    function as the entry point (instantiating the demo class where needed).
- Updated the enum examples to the 0.1.41 rich-enum model: an enum entry is a
  class instance, so members are read via a variable (e.g. `var e =
  Planet.earth; e.gravity`) rather than assigning the entry to an `int`. The
  Dart/Java/Kotlin enum examples now show an entry field (`gravity`) plus
  `index`/`name`; C# shows the explicit `value`.
- Added "Example" picker entries for the new 0.1.42 features (all verified to
  run via ApolloVM):
  - "Named arguments" for Dart and C# — a call binds arguments by name, so the
    call-site order is free.
  - "Default parameters" for Dart and C# — an omitted argument uses the
    parameter's declared default.
- apollovm: ^0.1.42

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
