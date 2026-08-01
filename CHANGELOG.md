## 1.35.0

### apollovm 2.25.0 (maintenance): `?.` on a boxed Wasm slot

Updated to `apollovm: ^2.25.0`. **No example changed, and nothing changes in the
playground today** — 2.25.0 is a Wasm-backend fix, and it lands in a corner none
of the shipped examples reach.

It came out of ticking the **Wasm** checkbox on **Dart — Null-aware access (?.
and ?[])**, which is an interpreted-only example (`wasm: false`). That reports:

```
Wasm has no null value for `String`: can't compile `String missing = null`.
... declare the variable as `var` / `Object?` / `dynamic`, or give it a
non-null initial value.
```

That refusal is by design — a concrete Wasm slot has no encoding for `null`, so
it errors rather than emitting a module that fails validation — and it behaves
the same on 2.24.0. What 2.25.0 fixes is that *following the advice* used to hit
a second wall: `var missing = null; missing?.length` was an
`UnimplementedError`. Getters (`.length` / `.isEmpty` / `.isNotEmpty`) on a
boxed slot now compile and short-circuit properly.

**The example still does not compile to Wasm**, and it is worth being precise
about why. With `var`, it now gets one step further and stops on the *method*:

```
UnimplementedError: Wasm method `.toUpperCase` on Null is not supported yet.
```

Methods on a boxed slot are a separate path from getters and are still
unimplemented, and the example's `String? missing = null` is a concrete slot
either way. So this is progress on the underlying gap, not a fix for the
example — which is fine: the example targets the interpreter, and weakening
`missing?.length` on a genuinely-null receiver to suit a backend it does not
target would cost more than it gains.

All **102** examples were re-verified against the published 2.25.0 — each
interpreted, producing **byte-identical** results and output to 1.34.0, and all
**28** Wasm entries compiling to **byte-identical** modules.

## 1.34.0

### apollovm 2.24.0: the null-aware examples now translate to working code

Updated to `apollovm: ^2.24.0`. Upstream, `a?.b` stopped being emitted as a
plain `a.b` on the targets with no null-aware operator — the null check used to
be dropped, so the translated code threw on exactly the input `?.` exists to
handle.

**This one lands squarely in the playground**, because two shipped examples
exist to demonstrate that operator. Loading **Dart — Null-aware access (?. and
?[])** and translating to Java produced code that could not run:

```java
// before
var first = values[0];
var missingLen = missing.length;
```

`missing` is `null` two lines earlier in that example — reading `.length` off it
is a `NullPointerException`, and `values[0]` the same whenever the argument is
null. It now translates to a guard:

```java
// now
var first = (values != null ? values[0] : null);
var missingLen = (missing != null ? missing.length : null);
```

Python guards with `is not None`, and Lua with an immediately-invoked `nil`
test. C# and JavaScript turned out to have had the operator all along (C# 6,
ES2020) and simply never declared it, so they now emit `values?[0]` and
`values?.[0]` natively rather than dropping the check.

Go still reports the construct as unsupported — it represents a nullable `T?` as
`*T`, so a degraded access would skip the nil check *and* yield the wrong type —
but the message now names the fix.

### What else changed, and what didn't

Python's null comparison is now the identity test it should always have been,
which shows up in **Wasm — Null value (ternary and == null)**:

```python
if first == None:   # before
if first is None:   # now
```

`==` dispatches through `__eq__`, which a class can redefine to return `True`
for `None`. The Python grammar learned to read `is None` / `is not None` back,
so a translation the playground produces can be pasted straight into its own
editor as Python and re-run — which was not true of `is None` before.

### New example: Python — Null check (is None)

Reading that form is new *input* capability, and nothing shipped exercised it —
until now every null-safety example was written in Dart, because Dart was the
only grammar that parsed any of it. **Python — Null check (is None)** is the
first null-safety example authored in another language, and it translates out to
Dart, Kotlin, JS, TS, Go and Lua, each in its own spelling:

```python
if value is None:        # Python (source)
if (value == null) {     # Dart, Kotlin
if (value === null) {    # JavaScript, TypeScript
if value == nil {        # Go, Lua
```

Java and C# reject it, for the same reason they reject every other Python
example here: both require functions to live in a class, and Python's are
top-level. That is unchanged by this release.

General `a is b` is still not parsed — it is identity, and reading it as `==`
would silently turn it into equality.

The example count goes from 101 to **102**; the existing 101 are byte-identical
with and without the addition.

The rest of the release is an AST refactor (`??`, `&&`, `||` and `x == null`
became nodes of their own instead of operators special-cased inside the generic
binary-operation node). That is internal and reaches nothing here.

Measured across the shipped corpus, translating all **101** examples into all
**9** target languages — 909 pairs — **13 changed**, and every one is a
null-safety example:

```
Dart — Null-aware access (?. and ?[])   java11, python, lua, csharp, javascript, go
Dart — Access chains (a.b.c and a.b?.c) java11, python, lua, csharp, javascript
Dart — Null assertion (!)               csharp
Wasm — Null value (ternary and == null) python
```

All **101** examples were also re-run interpreted on 2.23.3 and 2.24.0 and
produce **byte-identical** results and output, and all **28** Wasm examples
compile to **byte-identical** modules. The upstream `run` paths for `??`, `&&`
and `||` moved to new AST nodes in this release, so that was worth confirming
rather than assuming.

## 1.33.0

### apollovm 2.23.3: an unresolved entry point says what the source declares

Updated to `apollovm: ^2.23.3` (2.23.2 was an `apollovm_wasm` release and
changes nothing here). Upstream, `ApolloRuntime.execute` — the CLI and MCP entry
path — stopped reporting `Entry function not found` for a call whose arguments
match no declaration, and lists the declared signatures instead.

**That exact fix doesn't reach the playground**, which resolves its entry point
through `ApolloRunner.executeFunction`/`executeClassMethod`. Those bind
permissively rather than matching a signature — extra arguments are dropped and
missing ones arrive as `null` — so a mismatch here runs, it doesn't fail.

What the playground did share is the unhelpful half of the message. Its three
unresolved-entry errors each repeated the name that was looked for and nothing
else:

```
Bad state: Can't find function to execute> functionName: mian ; language: dart
Bad state: Can't find class to execute: Bar->main
ApolloVMRuntimeError: Can't find entry function: mian
```

**Run** now answers with what the source actually declares:

```
Entry function `mian` not found in the source. Declared: `int main(int a, String b)`,
`int Foo.run(int a)`, `String Foo.greet(String n)`.
Tip: the Function field selects the entry point (blank means `main`), and the
Class field scopes it to a class method.
```

A **Class** field naming a class that isn't there lists the classes that are,
and suggests clearing the field to run a top-level function. Every other error —
including one thrown by the executed program — surfaces unchanged.

### A non-`static` class entry method now runs

The **Class** field used to require a `static` method: a plain `int run(int a)`
failed with `Can't call non-static method 'Foo.run' without a class instance`,
because the playground called `executeClassMethod` without one. It now passes a
fresh, field-less instance the way `ApolloRuntime` (the CLI/MCP path) does, so
both forms run — field initializers included. A `static` entry method is
unaffected by the empty instance.

All **101** shipped examples were re-run through both the old and the new call
path and produce byte-identical results and output, and all 28 Wasm examples
still compile to a module. They keep their `static` entry methods; `static` is
now a convention in the examples rather than a requirement.

## 1.32.0

### apollovm 2.23.1: the entry-point fields are trimmed

Updated to `apollovm: ^2.23.1`. Upstream fixes a caller that fills in every
field rather than omitting the optional ones: `ApolloRuntime.execute` — the CLI
and MCP entry path — now trims `className`/`function` and reads a blank name as
"not specified", falling back to the full discovery order (or to `main`). The
rest of the release is Dart tooling around the LSP fixtures.

**Neither reaches the playground**, which loads and runs source directly. The
101 shipped examples produce byte-identical results on 2.23.0 and 2.23.1 —
interpreted runs, Wasm runs, null-safety loads and every translation.

The playground picks up the same normalization for its own fields, though,
because it calls `ApolloRunner.executeClassMethod`/`executeFunction` rather than
`ApolloRuntime.execute`, and those do no trimming. A **Class** field holding
`" Foo "` — easy to end up with after a paste — failed with:

```
Can't find class to execute:  Foo ->main
```

**Run** now trims both entry-point fields before resolving the entry point, and
an empty **Function** field means `main`, matching the CLI's default. A blank
**Class** field still selects a top-level function, as before, and a class that
genuinely isn't in the source is still reported as not found.

All **101** examples were re-verified — each interpreted, each of the 28 Wasm
entries on the Wasm-compiled backend too, all 101 loading clean with the **Null
safety** checkbox ticked, and all 101 translated to every other language.

## 1.31.0

### A "Null safety" checkbox in the Run Configuration

apollovm 2.22.0 added an opt-in check that rejects source with null-safety
**errors** while loading it, and 2.23.0 exposed it to the CLI and MCP. The
playground can now switch it on too, next to the existing **Wasm** checkbox.

With it ticked, this fails *before* anything runs:

```dart
class Foo {
  static void main(int a, int? b) {
    print(a);
    print(b);
    var c = a + b;
  }
}
```

```
[Null Safety] Can't load `web` (dart): 1 null-safety error(s).
  - The operand 'b' can be 'null', so it can't be used in an operation
    unconditionally. Use '??', '!' or a null check.
```

Unticked (the default), the behaviour is unchanged: it prints `5` and `null`
first, then fails at the `+` with an `ApolloVMNullPointerException`. That
contrast is the point of the checkbox — the same program, failing at load rather
than mid-run.

The setting applies to every action that loads source — **Run**, **Translate to
all languages** and **Download Wasm** — so a rejected program is rejected
consistently. It does not affect loading an already-compiled Wasm module, which
carries no AST to analyze.

A rejection is shown as its own report rather than being wrapped in the generic
`Can't load source!` message, which would have buried the findings.

All **101** examples were re-verified, and all 101 also load cleanly **with the
checkbox on** — ticking it never breaks a shipped example.

## 1.30.0

### apollovm 2.23.0 (maintenance)

Updated to `apollovm: ^2.23.0`. **No example changed, and nothing changes in the
playground** — 2.23.0 exposes the opt-in null-safety check through the `apollovm`
CLI (`--null-safety`) and the MCP tools (a `nullSafety` argument), neither of
which the browser playground uses.

The playground continues to construct its VM with the default (checks off), so
**Run** executes and shows the runtime error while the **Problems** panel flags
the issue as you type — the behaviour introduced in 1.29.0.

All **101** examples were re-verified against the published 2.23.0 — each
interpreted, each of the 28 Wasm entries on the Wasm-compiled backend too — and
all 101 remain clean under the analyzer.

## 1.29.0

### apollovm 2.22.0: the Problems panel now checks class methods

Updated to `apollovm: ^2.22.0`. No example changed — this release is an upstream
fix that changes what the **Problems** panel can see.

The null-safety analyzer walked only top-level functions: `ASTRoot` keeps its
classes outside `children`, so the traversal never entered a class body (and
`ASTClass` kept constructors and getters out too). **Every method, constructor
and getter of every class went unanalyzed.**

Since almost everything in the playground is written as a class, that was most
of the editor. Typing this into a class method used to produce no diagnostic at
all:

```dart
class Foo {
  static void main(int a, int? b) {
    var c = a + b;   // 'b' can be 'null' — now reported
  }
}
```

All **101** shipped examples remain analyzer-clean, so the newly-reachable class
bodies produce no false positives — the panel only lights up on code you write.

Upstream also added an opt-in `ApolloVM(nullSafetyChecks: true)` that rejects a
null-safety error at *load* time instead of failing partway through a run. The
playground keeps the default (off), so **Run** still executes and shows the
runtime error, with the Problems panel flagging the issue as you type.

All 101 examples were re-verified — each interpreted, each of the 28 Wasm entries
on the Wasm-compiled backend too.

## 1.28.0

### apollovm 2.21.0: two Translate-panel fixes

Updated to `apollovm: ^2.21.0`. No example changed — this release is two upstream
fixes reaching the **Translate to all languages** panel, both found while
documenting the null-safety surface in the ApolloVM README.

- **Kotlin's null-aware index was `xs?[0]`**, which is not valid Kotlin — it has
  no `?[` operator. The Kotlin tab now shows the call form, `xs?.get(0)`.
- **Lua's null literal was `null`**, which is not a Lua value. The generated code
  referenced an undefined global, so `a == null` was *always false* instead of a
  nil test. The Lua tab now shows `nil`.

Both are visible on the Dart null-safety examples: switch to the Kotlin or Lua
tab on **Null-aware access (`?.` and `?[]`)** and the output is now code the
target language actually accepts.

All **101** examples were re-verified — each interpreted, each of the 28 Wasm
entries on the Wasm-compiled backend too — and all 101 remain clean under the
analyzer.

## 1.27.0

### apollovm 2.20.0: Go finally has nullable types

Updated to `apollovm: ^2.20.0`. No example changed — this release is the
upstream Go work reaching the playground.

Until now, **Translate to all languages** could not produce usable Go for
anything nullable. A `String? s = null` came out as `var s string = nil`, which
is not valid Go, and `??` was reported as unsupported outright — Go simply had
no representation for nullability.

A nullable `T?` is now generated as a Go pointer `*T`, the one form that can
hold `nil`. In the Go tab you will now see:

- `int? a` as `a *int`, and a `String? name` field as `name *string`;
- reads deref — `(*a)` — while `x == null` compares the pointer as `x == nil`;
- `int? x = 5` as `goPtr(5)`, using a small generated helper, since Go cannot
  write `&5`;
- `a ?? b` as `func() int { if a != nil { return *a }; return b }()`, because Go
  has no conditional expression;
- `List<int>?` left as `[]int`, since a Go slice is already nilable.

Upstream verifies each of those by compiling the generated source with a real
Go toolchain rather than matching strings — which is what had let
`var s string = nil` through.

The **Dart — Null assertion (!)** example is the one that shows this off: its Go
tab is now a real, compilable program. Two constructs still report UNSUPPORTED
in the Go tab — `?.` and `??=` — because degrading them would emit code that
skips a nil check or does not type-check. Plain `??` is unaffected.

All **101** examples were re-verified — each interpreted, each of the 28 Wasm
entries on the Wasm-compiled backend too — and all 101 remain clean under the
analyzer.

## 1.26.0

### apollovm 2.19.0: `x == null` works, and a new Wasm null example

Updated to `apollovm: ^2.19.0`.

The headline upstream fix is that **`x == null` no longer throws**. It failed for
any typed operand — `int? a = 1; if (a == null)` raised
``type 'Null' is not a subtype of type 'FutureOr<int>'`` — so the most common
null check in Dart was unusable in the playground unless written backwards as
`null == x`. Equality now compares uncast, so a mismatched type is `false`
rather than an error.

That unblocked a new example, under **Wasm**:

- **Null value (ternary and `== null`)** — walks a `List<Object>`, takes a
  `null` ternary arm when the list is empty, prints it through an
  interpolation, and branches on `== null`. Run it as-is, then clear the
  arguments to `[ ]` to take the null path. Verified on both backends with
  identical output.

Also in this release, from upstream: on Wasm, `== null` against a boxed value
now compares against the null box instead of taking the String content-equality
route (which reported a non-null `List<Object>` element as null), and
`String s; s == null` compiles to a valid module instead of one the browser
refuses. In *Translate to all languages*, Go no longer emits
`var s string = nil` — source that does not compile — reporting UNSUPPORTED
instead. And `(expr).m().field` now parses.

All **101** examples verified — each interpreted, each of the 28 Wasm entries on
the Wasm-compiled backend too — and all 101 remain clean under the analyzer.

## 1.25.0

### apollovm 2.18.0: `null` compiles to Wasm

Updated to `apollovm: ^2.18.0`. No example changed — this release is the
upstream fixes reaching the playground.

Compiling a `null` literal through **Compile to Wasm** used to throw
`UnimplementedError: generateASTExpressionNullValue`, so an ordinary Dart idiom
could not be compiled at all:

```dart
var a = args.length > 0 ? args[0] : null;
```

`null` is now a real value in the Wasm backend's *boxed* domain (the
boxed-`Object` pointer 0), so it works in a `var` / `Object?` slot, as a ternary
arm, as a `List<Object>` element, through `??`, and inside a string
interpolation — printing `null` rather than a raw pointer. Where it genuinely
has no representation, such as `int x = null` (an `int` is an i64 in Wasm), the
compiler now reports a clear unsupported-construct error naming the type
instead of producing a module the browser refuses to instantiate.

The **Problems** panel also gained two checks, both of which previously passed
silently:

- a nullable operand used in an operation — `x + (y ?? 0)` where `x` is `int?`
  (`??`, `==` and `!=` stay exempt, and `!` or a null check still suppress it);
- a nullable *value* assigned to a non-nullable slot — `int x = a;` where `a`
  is `int?`, which is the existing "can't assign `null`" error one step removed.

All **100** examples were re-verified against 2.18.0 — each on the interpreted
backend, each of the 27 Wasm entries on the Wasm-compiled backend too — and all
100 remain clean under the analyzer, so the new checks produce no false
positives on any shipped example.

## 1.24.0

### apollovm 2.17.0: Dart null safety in the playground

Updated to `apollovm: ^2.17.0`, picking up **Dart null safety** (2.16.0) —
nullable types (`T?`), the null-coalescing operators `??` / `??=`, null-aware
access `?.` / `?[`, the null assertion `!`, and a flow-aware static analyzer —
plus the 2.17.0 fixes described below. None of it was reachable from the
**Example** selector, so five examples now cover it.

Under **Dart** (interpreted):

- **Null safety (`??` and `??=`)** — `String?` / `int?` parameters, `??`
  supplying a fallback for a null, `??=` assigning only into a null target, and
  a non-null value passing straight through.
- **Null-aware access (`?.` and `?[]`)** — `?[` on a null and a non-null list,
  `?.` on both a getter and a method invocation, each short-circuiting to null
  rather than throwing, then totalled with `??`.
- **Null assertion (`!`)** — the value on a non-null target, and the
  `ApolloVMNullPointerException` on a null one, caught so one run shows both.
- **Access chains (`a.b.c` and `a.b?.c`)** — walking a linked `Node` list
  through chains of any depth, mixing `.`, `?.` and `!`, including a write
  through a chain (`head.next.value = 20`).

Under **Wasm**:

- **Null safety (`!` and `??`)** — the same syntax lowered into the Wasm
  backend's non-null numeric domain, where `x!` is a no-op and `a ?? b` takes
  its left operand. Runs on both backends with identical output.

Every one of the **100** examples was re-verified — each on the interpreted
backend, and each of the 27 Wasm entries on the Wasm-compiled backend too, with
matching results and identical `print` output. All 100 are also clean under the
null-safety analyzer, so the Problems panel stays empty on a freshly loaded
example.

Writing these surfaced four upstream gaps, all **fixed in apollovm 2.17.0**, so
the examples use the natural form of each construct rather than a workaround:

- A **`String?` parameter rejected a non-null `String` argument**
  (`parameters signature not compatible`), though `null` worked. Argument
  passing is an assignment, so the parameter check now uses `acceptsAssignment`.
- **Storing a null-short-circuited `?.` / `?[` result in a local failed** —
  `var v = s?.length` on a null receiver threw ``Class not set for type: Null``.
  A null-aware access now reports a nullable static type.
- **`?.` didn't parse when chained onto a field access.** `a.next?.value` was a
  `SyntaxError: digit expected`, and even plain `a.next.value` failed — the
  grammar accepted only a single-identifier receiver. Member-access chains of
  any depth now parse, which is what the new *Access chains* example shows.
- **`??` and `??=` leaked verbatim into targets that have no equivalent.**
  Java, Python and Lua now desugar into a conditional and Kotlin emits `?:` /
  `t = t ?: v`; Dart, C#, JavaScript and TypeScript keep the native operators.
  Go now reports UNSUPPORTED in *Translate to all languages* — it has no
  null-coalescing operator and no conditional expression, and its generator maps
  `T?` onto a non-nullable Go `T`, so any rendering would be code that does not
  compile.

The postfix `!` is fine everywhere: Kotlin `!!`, TypeScript `!`, dropped in the
rest.

## 1.23.0

### Eight new Wasm examples for the 2.15.0 feature surface

1.22.0 pulled in `apollovm 2.15.0`, but the *Compile to Wasm* action still
demoed roughly the surface it did at 2.1.0 — none of the newly-supported syntax
was reachable from the **Example** selector. Eight examples now cover it, under
the **Wasm** category:

- **Static class fields** — a `static int total` persisting across calls.
- **Inheritance (extends/super)** — an override that calls `super`, reading both
  an inherited and an own field.
- **Custom getters** — `int get area` / `int get perimeter`, accessed via a
  receiver.
- **Nested collections (`m[0][1]`)** — read, write and `+=` through a nested
  `List` and `Map`.
- **String methods** — `length`, case, `substring`, `indexOf`, `startsWith`,
  `contains`, `replaceAll`, index `s[i]`.
- **String trim & pad** — `trim`, `padLeft`, `padRight`.
- **String split** — `split(',')` returning a `List<String>` that crosses the
  module boundary.
- **String equality & compareTo** — `==` as content equality, plus `compareTo`.

Every one was verified end-to-end on **both** backends — interpreted and
Wasm-compiled — with matching results and identical `print` output, keeping the
promise in the examples file that each Wasm entry is a verified runner.

Two upstream gaps were found while verifying, and the examples are written to
avoid them (each is noted in a comment next to the example):

- A **`static` field inside a string interpolation** isn't compiled to Wasm yet
  (`print('$total')` throws ``Can't find local variable `total` ``), though
  reading it in an expression or a `return` works. The example prints the call
  results instead.
- **Interpolating a whole nested collection** (`print('$grid')`) raises
  `UnimplementedError` on Wasm. The example prints the elements individually.

## 1.22.0

### apollovm 2.15.0: Wasm grows up, and the Outline gets another fix

Updated to `apollovm: ^2.15.0`, fourteen releases on from `2.1.0`. The bulk of
the work landed in the on-the-fly **Wasm** backend behind the *Compile to Wasm*
action, which went from "simple functions" to running most of what the
interpreter runs.

- **The Outline sidebar selects a whole field declaration.** A field/variable's
  `documentSymbol` range used to stop at the name, so clicking `count` in the
  Outline of `int count = 0;` selected just `count`. It now runs to the
  terminating `;`, including an initializer with `(`/`[`/`{ }` in it — matching
  how methods and enum members already behaved (see 1.20.2).
- **Classes now compile to Wasm.** `static` fields (as module globals),
  single inheritance with `extends`/`super` (a subclass lays its superclass's
  fields out first, so an inherited method reads the right slot), custom
  instance getters (`int get x => ...`), and a generic field (`class Box<T>`,
  stored boxed and unboxed at the instantiation type).
- **Strings are broadly complete in Wasm.** On top of the case/length methods
  from 2.1.0: `substring`, `codeUnitAt`, `startsWith`/`endsWith`, `indexOf`,
  `contains`, `trim`/`trimLeft`/`trimRight`, `padLeft`/`padRight`,
  `replaceAll`/`replaceFirst`, `split`, `compareTo`, index `s[i]`, and `==`/`!=`
  as *content* equality rather than pointer identity. Byte-indexed, so exact for
  ASCII text.
- **Nested collections and chained indexing work on both backends.**
  `[[1, 2], [3, 4]]`, `{'a': {'b': 5}}`, and reads/writes through every level
  (`m[0][1]`, `m['a']['b']`, `m[0][1] += 5`) — in the interpreter (2.2.0) and in
  Wasm (2.6.0). Returning a `List`/`Map` across the module boundary is covered
  too.
- **Inheritance and `static` fields work in the interpreter**, across the Dart,
  Java, C#, JavaScript, TypeScript and Python grammars — the Java/C#/JS grammars
  had been silently dropping the superclass and the `static` modifier.
- **Transpile-target fixes.** Go `&^` (bit clear) now emits `a & (~b)` instead of
  a plain `&`; Lua gets `..` for string-variable concatenation, 1-based list
  indexing, and parenthesized interpolation subexpressions.
- **Parser fixes.** `~/=` (Dart) and `//=` (Python) no longer crash the parser,
  and an unsupported compound operator surfaces as a clean `SyntaxError`.
  `Enum.values` can be assigned to a typed or inferred list.
- **No change to this playground's own code** — everything above is inside
  `apollovm`.

## 1.21.0

### apollovm 2.1.0: Wasm loop fix and initial String methods

- Updated to `apollovm: ^2.1.0`, which improves the on-the-fly **Wasm** backend
  that the *Compile to Wasm* action uses:
  - **A `++`/`--` inside a `while`/`do-while` loop no longer breaks Wasm
    compilation.** A bare increment/decrement statement in a loop body used to
    emit an invalid module (it failed WebAssembly validation), so an example
    like `while (i < n) { i++; }` compiled but wouldn't run. It now works.
  - **String `.length`, `.isEmpty`, `.isNotEmpty` compile to Wasm**, and
    **`.toUpperCase()` / `.toLowerCase()`** compile for ASCII text — so examples
    that manipulate strings can now be run through the Wasm path, not just the
    interpreter.
- **No change to this playground's own code** — the improvements are entirely
  inside `apollovm`'s Wasm code generator.

## 1.20.2

### apollovm 2.0.1: the Outline no longer mangles a Dart enum

- Updated to `apollovm: ^2.0.1`, which fixes how the in-process LSP records the
  source range of a Dart enum constant. Both symptoms were visible right here in
  the **Outline** sidebar:
  - **A constant with arguments now selects its whole entry.** An enum constant
    is a constructor invocation, but its range was recorded as the name alone —
    clicking `earth` in the Outline of `enum Planet { earth(5.97, 6371) }`
    selected just `earth`, not its arguments. It now covers the entry,
    including a `.named` constructor, `<T>` type arguments and an `= value`.
  - **Named arguments no longer appear as phantom constants.** The scan past a
    constant stopped at the first `,` even inside the argument list, so an
    argument label was read as another constant: `earth(mass: 5.97, radius:
    6371)` listed a bogus `radius` member in the Outline. It's gone.
- **No change to this playground's own code** — the fix is entirely inside
  `apollovm`'s LSP.

## 1.20.1

### The deployed site can run Wasm again

- **▶ Run · Wasm** was broken on the deployed GitHub Pages site in Chrome/Edge,
  while working fine under `webdev serve`. The cause was our own
  Content-Security-Policy, not GitHub Pages: the deploy workflow injects a CSP
  `<meta>` tag into the *built* `index.html`, and its `script-src 'self'` had no
  `'wasm-unsafe-eval'`. Once `script-src` is set, Chromium gates the Wasm
  compilation APIs under it too — so `WebAssembly.instantiate()` on the module
  bytes we generate at runtime was refused with a `CompileError`, and the run
  died before executing a single instruction.
- Added `'wasm-unsafe-eval'` to `script-src`. It is the *minimum* grant that
  unblocks this: it permits WebAssembly compilation only, and still refuses
  `eval()` and `new Function()` on JavaScript strings — unlike the much broader
  `'unsafe-eval'`, which we deliberately do not use. Compiling user-authored
  Wasm is this playground's whole purpose, and the module runs inside the Wasm
  sandbox with only the imports ApolloVM gives it (the `print` bridge), with no
  DOM access. Every other directive stays as strict as before.
- It was invisible in development by design: the CSP is injected at deploy time
  only, never into `web/index.html`, so `webdev serve` (DDC, which needs
  `'unsafe-eval'`) keeps working. That split is still right — it had just
  overshot for Wasm.
- **This was never a CORS or GitHub Pages configuration issue.** Pages already
  serves the site with `access-control-allow-origin: *` and sends no CSP header
  of its own — and it cannot be made to send custom headers at all. The Wasm
  module never crosses the network: it is generated in memory and handed
  straight to the browser engine as a buffer, so no CORS is involved.
- *Compile & download `.wasm`* was never affected — a `blob:` in an
  `<a download>` is not gated by `script-src`.

### A CSP refusal now explains itself

- A blocked Wasm run used to surface as a raw
  `WasmModuleLoadError: Can't load wasm module: test.wasm / Cause: CompileError:
  …`, which named the symptom but not the cause. The Wasm run path now detects a
  CSP-refused compile and reports what is actually wrong — the page's
  `script-src` needs `'wasm-unsafe-eval'` — plus the workaround (run
  interpreted), alongside the original engine message. This mirrors the existing
  missing-entry-point hint.

## 1.20.0

### apollovm 2.0.0: the native Wasm engine moves out of core

- Updated to `apollovm: ^2.0.0`. Executing a compiled Wasm module *on the Dart
  VM* used to require `package:wasm_run`, which dragged an FFI/Rust toolchain and
  a long-abandoned `flutter_rust_bridge` 1.x into every consumer — even the ones
  that only parse, translate or generate code. That engine now lives in a
  separate package, `apollovm_wasm`, and `apollovm` no longer pins the old
  `shelf`/`web_socket_channel` stack that came with it.
- **This playground is unaffected, and neither of its Wasm features changed.**
  Wasm *compilation* never left core, so *Compile & download `.wasm`* is
  untouched; and the browser already ships a Wasm engine, so apollovm keeps its
  browser runtime in core — `WasmRuntime`'s conditional import still resolves to
  the `js_interop` web implementation under dart2js, which is exactly how this
  app is built. The **▶ Run · Wasm** path and the Wasm examples run as before.
- The breaking change only bites a Dart VM (non-browser) consumer that *executes*
  Wasm: it now has to add `apollovm_wasm` and call
  `registerApolloVMWasmRuntime()` once, otherwise `WasmRuntime()` reports
  `isSupported == false`.

### Dependency refresh

- `collection` `^1.19.1`, `web` `^1.1.1`, `dom_tools` `^3.0.1`,
  `swiss_knife` `^3.3.14`, `data_serializer` `^1.2.2`.
- Dev: `build_runner` `^2.15.1`, `build_web_compilers` `^4.8.0`.

## 1.19.0

### Parse errors point at the real mistake (apollovm 1.10.0)

- Updated to `apollovm: ^1.10.0`, whose parsers now record the farthest point the
  grammar actually reached and report a failure there, instead of collapsing
  every deep syntax error to a generic *`end of input expected`* at line 1. The
  fast happy path is untouched — the tracking re-parse only runs on failure.
- **The editor's squiggles, gutter markers and Problems panel land on the actual
  error.** The language server's `analyze` drives all three from apollovm's
  `locateParseError`, so a bad token mid-file now underlines that token on its
  own line rather than the top of the buffer. This holds for Dart, Java, Kotlin,
  Go, C#, JavaScript, TypeScript and Lua.
- **Python diagnostics are unchanged**: its source is rewritten by the
  indentation preprocessor before the grammar sees it, so apollovm intentionally
  leaves Python out of the farthest-failure tracking for now.

## 1.18.0

### Go is a first-class language (apollovm 1.9.2)

- Updated to `apollovm: ^1.9.2`, which fixes three Go generator defects found
  while adding the Go transpile tab in 1.17.0: a field-initializing constructor
  (`Point(this.x, this.y)`) whose arguments were silently dropped, identifiers
  colliding with Go's reserved words (`map`, `type`) emitting source that does
  not parse, and structs emitted after the functions that call their factories.
- **Go joins the language selector**, with syntax highlighting and a `.go`
  buffer for the language server. It parses, runs and transpiles like any other
  source language.
- **Three new Go examples**, each verified to run and to transpile to Dart,
  Kotlin, JavaScript, TypeScript, Lua and Python (Java and C# need a class to
  hold a top-level function, as with the Kotlin and Lua examples):
  - *Go — Function (sums)*: a top-level `main`, `:=` inference and `fmt.Println`.
  - *Go — Struct & receiver method*: `type Point struct` plus `func (o *Point)`
    and a `NewPoint(...)` factory — exactly what the generator emits for a Dart
    class. Transpile it back to Dart and the class reappears.
  - *Go — For loop*: the three-clause `for i := 1; i <= n; i++`.
- The Outline panel stays empty for a `.go` buffer: the language server reports
  no document symbols for Go yet.

## 1.17.0

### Go as a transpile target (apollovm 1.9.1)

- Updated to `apollovm: ^1.9.1`, a bug-fix release whose coverage pass fixed the
  Go generator and grammar: **Dart → Go → parse → run** now works end to end.
- **`Go` is now a tab in the Transpile panel.** Of the 84 bundled examples, 80
  generate Go; the 4 extension examples report `UNSUPPORTED`, since Go has no
  extension construct. Go is a transpile target only — the LSP reports no
  symbols for a `.go` buffer, so it is not offered as an editor language.
- Also fixed upstream, and exercised by the existing examples: a Dart map
  literal transpiled to Java 11 emits `new HashMap<>(){{ ... }}`, which the Java
  grammar used to crash on — so a Dart map example now survives a round trip
  through Java. And `String.length` / `isEmpty` / `isNotEmpty` and the `sign` of
  `int`/`double` work as getters, not only as method calls.

## 1.16.0

### Extensions — add methods and getters to an existing type (apollovm 1.9.0)

- Updated to `apollovm: ^1.9.0`, which adds a shared extension construct to the
  three languages that have one natively: an extension parsed as Dart, Kotlin or
  C# runs and translates to the other two.
- **Five new examples**, each verified to run and to transpile:
  - *Dart — Extension methods (on int)*: `extension NumExt on int { ... }`,
    transpiles to Kotlin and C#.
  - *Dart — Extension getter (on a class)*: an extension on a user class with a
    getter; transpiles to Kotlin only, since C# has no extension property.
  - *Dart — Class getters (area / perimeter)*: instance getters in a class body,
    block-bodied and `=> ...`, which Dart only started parsing in apollovm 1.9.0.
  - *Kotlin — Extension function & property*: top-level `fun Int.doubled()` and
    `val Int.twice`, grouped by receiver into one extension.
  - *C# — Extension methods (this self)*: a `static class` whose methods take a
    `this` self-parameter.
- **Unsupported transpile targets now read as such.** Generating an extension
  into a language that has no equivalent (Java, JavaScript, TypeScript, Python,
  Go, Lua — and C# for an extension *getter*) throws `UnsupportedSyntaxError`
  rather than emitting a misleading shim. The Transpile panel now labels those
  targets `UNSUPPORTED: ...` instead of showing a raw error, and switching the
  editor's language to an unsupported target reports the reason and keeps the
  language selector on the source language.
- Raised the SDK constraint to `>=3.10.0`, as required by apollovm 1.9.0.

## 1.15.1

- Make the Outline panel the default active panel during initialization.

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
