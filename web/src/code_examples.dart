part of '../main.dart';

const initialCodeDart = r'''

class Foo {

  void main(List<Object> args) {
    var title = args[0];
    var a = args[1];
    var b = args[2] ~/ 2;
    var c = args[3] * 3;
    
    if (c > 120) {
      c = 120 ;
    }
    
    var str = 'variables> a: $a ; b: $b ; c: $c' ;
    var sumAB = a + b ;
    var sumABC = a + b + c;
    
    print(str);
    print(title);
    print(sumAB);
    print(sumABC);
    
    // Map:
    var map = <String,int>{
    'a': a,
    'b': b,
    'c': c,
    };
    
    print('Map: $map');
    print('Map `b`: ${map['b']}');
  }
  
}
''';

final initialPositionalParameters = ' [ "Sums:" , 10 , 30 , 50 ] ';
final initialNamedParameters = '';

/// A ready-to-run code example for the playground.
///
/// [positionalParameters] is the JSON typed into the field (it's wrapped in
/// `[ ... ]` before decoding), so a single-array entry point like Dart's
/// `main(List<Object> args)` uses `'[ "Sums:", 10, 30, 50 ]'`, while a
/// multi-arg entry point uses `'"Sums:", 10, 20, 30'`.
class CodeExample {
  final String name;
  final String language;
  final String code;
  final String className;
  final String functionName;
  final String positionalParameters;
  final String namedParameters;

  /// When `true`, this example is listed under the "Wasm" category and loading
  /// it enables the "Wasm compiled" run mode (it compiles to and runs on Wasm).
  final bool wasm;

  const CodeExample(
    this.name,
    this.language,
    this.code,
    this.className,
    this.functionName,
    this.positionalParameters, {
    this.namedParameters = '',
    this.wasm = false,
  });
}

/// Examples shown in the "Example" selector. Every entry is verified to run.
const codeExamples = <CodeExample>[
  CodeExample('Dart — Class (maps & strings)', 'dart', initialCodeDart, 'Foo',
      'main', '[ "Sums:", 10, 30, 50 ]'),
  CodeExample('Dart — Fibonacci (Interpreted + Wasm)', 'dart', _exDartFib, '',
      'fibonacci', '10'),
  CodeExample('Java11 — Class', 'java11', _exJava, 'Foo', 'main',
      '[ "Sums:", 10, 20, 30 ]'),
  CodeExample('Kotlin — Class', 'kotlin', _exKotlin, 'Foo', 'main',
      '"Sums:", 10, 20, 30'),
  CodeExample('JavaScript — Class', 'javascript', _exJs, 'Foo', 'main',
      '"Sums:", 10, 20, 30'),
  CodeExample('TypeScript — Class', 'typescript', _exTs, 'Foo', 'main',
      '"Sums:", 10, 20, 30'),
  CodeExample(
      'Lua — Class', 'lua', _exLua, 'Foo', 'main', '"Sums:", 10, 20, 30'),
  // Python language support (apollovm 0.1.35).
  CodeExample('Python — Class', 'python', _exPython, 'Foo', 'main',
      '"Sums:", 10, 20, 30'),
  // C# language support (apollovm 0.1.37).
  CodeExample(
      'C# — Class', 'csharp', _exCs, 'Foo', 'main', '"Sums:", 10, 20, 30'),
  // Exception handling (apollovm 0.1.33): try/catch/finally and throw.
  // Run with b = 0 to take the throwing path, or b = 2 for the normal path.
  CodeExample('Dart — Exceptions (try/catch/finally)', 'dart', _exDartTryCatch,
      'Foo', 'main', '10, 0'),
  CodeExample('Java11 — Exceptions (try/catch/finally)', 'java11',
      _exJavaTryCatch, 'Foo', 'main', '10, 0'),
  CodeExample('Kotlin — Exceptions (try/catch/finally)', 'kotlin',
      _exKotlinTryCatch, 'Foo', 'main', '10, 0'),
  CodeExample('JavaScript — Exceptions (try/catch/finally)', 'javascript',
      _exJsTryCatch, 'Foo', 'main', '10, 0'),
  CodeExample('TypeScript — Exceptions (try/catch/finally)', 'typescript',
      _exTsTryCatch, 'Foo', 'main', '10, 0'),
  CodeExample('C# — Exceptions (try/catch/finally)', 'csharp', _exCsTryCatch,
      'Foo', 'main', '10, 0'),
  // Conditional / ternary expressions (apollovm 0.1.36). Each language uses its
  // own idiom (`?:`, Kotlin/`if`/`else`, Python `a if c else b`).
  CodeExample('Dart — Conditional (a > b ? a : b)', 'dart', _exDartTernary,
      'Foo', 'main', '40, 130'),
  CodeExample('Java11 — Conditional (a > b ? a : b)', 'java11', _exJavaTernary,
      'Foo', 'main', '40, 130'),
  CodeExample('Kotlin — Conditional (if/else expression)', 'kotlin',
      _exKotlinTernary, 'Foo', 'main', '40, 130'),
  CodeExample('JavaScript — Conditional (a > b ? a : b)', 'javascript',
      _exJsTernary, 'Foo', 'main', '40, 130'),
  CodeExample('TypeScript — Conditional (a > b ? a : b)', 'typescript',
      _exTsTernary, 'Foo', 'main', '40, 130'),
  CodeExample('Python — Conditional (a if c else b)', 'python',
      _exPythonTernary, 'Foo', 'main', '40, 130'),
  CodeExample('C# — Conditional (a > b ? a : b)', 'csharp', _exCsTernary, 'Foo',
      'main', '40, 130'),
  // Anonymous functions / lambdas / closures (apollovm 0.1.36, plus Java/Kotlin/
  // Lua lambda parsing in 0.1.37).
  CodeExample(
      'Dart — Lambdas (closures)', 'dart', _exDartLambda, 'Foo', 'main', '5'),
  CodeExample('JavaScript — Lambdas (closures)', 'javascript', _exJsLambda,
      'Foo', 'main', '5'),
  CodeExample('TypeScript — Lambdas (closures)', 'typescript', _exTsLambda,
      'Foo', 'main', '5'),
  CodeExample('Python — Lambdas (closures)', 'python', _exPythonLambda, 'Foo',
      'main', '5'),
  CodeExample('Java11 — Lambdas', 'java11', _exJavaLambda, 'Foo', 'main', '5'),
  CodeExample(
      'Kotlin — Lambdas', 'kotlin', _exKotlinLambda, 'Foo', 'main', '5'),
  CodeExample('Lua — Lambdas', 'lua', _exLuaLambda, 'Foo', 'main', '5'),
  // C# lambda parsing (apollovm 0.1.38): `n => n * 2` bound to a `Func`
  // delegate.
  CodeExample('C# — Lambdas', 'csharp', _exCsLambda, 'Foo', 'main', '5'),
  // switch / case (apollovm 0.1.38). C-style fall-through for Dart/Java/C#/JS/TS;
  // mapped to Kotlin `when` and Python `match`. Run with n = 2.
  CodeExample('Dart — Switch/case', 'dart', _exDartSwitch, 'Foo', 'main', '2'),
  CodeExample(
      'Java11 — Switch/case', 'java11', _exJavaSwitch, 'Foo', 'main', '2'),
  CodeExample(
      'Kotlin — When (switch)', 'kotlin', _exKotlinWhen, 'Foo', 'main', '2'),
  CodeExample('JavaScript — Switch/case', 'javascript', _exJsSwitch, 'Foo',
      'main', '2'),
  CodeExample('TypeScript — Switch/case', 'typescript', _exTsSwitch, 'Foo',
      'main', '2'),
  CodeExample(
      'Python — Match/case', 'python', _exPythonMatch, 'Foo', 'main', '2'),
  CodeExample('C# — Switch/case', 'csharp', _exCsSwitch, 'Foo', 'main', '2'),
  // do/while and Lua's `repeat ... until` (apollovm 0.1.38). Run with n = 3.
  CodeExample(
      'Dart — Do/while loop', 'dart', _exDartDoWhile, 'Foo', 'main', '3'),
  CodeExample(
      'Kotlin — Do/while loop', 'kotlin', _exKotlinDoWhile, 'Foo', 'main', '3'),
  CodeExample(
      'Lua — Repeat/until loop', 'lua', _exLuaRepeat, 'Foo', 'main', '3'),
  // Bitwise operators (apollovm 0.1.38; Kotlin/Lua added 0.1.40). Run with
  // a = 12, b = 10 (Lua uses literals, no parameters).
  CodeExample('Dart — Bitwise (& | ^ << >> ~)', 'dart', _exDartBitwise, 'Foo',
      'main', '12, 10'),
  CodeExample('Java11 — Bitwise (& | ^ << >> ~)', 'java11', _exJavaBitwise,
      'Foo', 'main', '12, 10'),
  CodeExample('Kotlin — Bitwise (and/or/xor/shl/shr)', 'kotlin',
      _exKotlinBitwise, 'Foo', 'main', '12, 10'),
  CodeExample(
      'Lua — Bitwise (& | ~ << >>)', 'lua', _exLuaBitwise, 'Foo', 'main', ''),
  CodeExample('C# — Bitwise (& | ^ << >> ~)', 'csharp', _exCsBitwise, 'Foo',
      'main', '12, 10'),
  // enum with runtime value access (apollovm 0.1.38 declarations, 0.1.39 value
  // access): an entry resolves to its explicit value (C#) or ordinal index.
  CodeExample(
      'Dart — Enum (ordinal value)', 'dart', _exDartEnum, 'Foo', 'main', ''),
  CodeExample('Java11 — Enum (ordinal value)', 'java11', _exJavaEnum, 'Foo',
      'main', ''),
  CodeExample('Kotlin — Enum (ordinal value)', 'kotlin', _exKotlinEnum, 'Foo',
      'main', ''),
  CodeExample('Python — Enum (ordinal value)', 'python', _exPythonEnum, 'Foo',
      'main', ''),
  CodeExample(
      'C# — Enum (explicit values)', 'csharp', _exCsEnum, 'Foo', 'main', ''),
  // Generic classes (apollovm 0.1.39): `Box<T>` declared, instantiated and
  // used. Run with x = 10.
  CodeExample(
      'Dart — Generics (Box<T>)', 'dart', _exDartGenerics, 'Foo', 'main', '10'),
  CodeExample('Java11 — Generics (Box<T>)', 'java11', _exJavaGenerics, 'Foo',
      'main', '10'),
  CodeExample('Kotlin — Generics (Box<T>)', 'kotlin', _exKotlinGenerics, 'Foo',
      'main', '10'),
  CodeExample('TypeScript — Generics (Box<T>)', 'typescript', _exTsGenerics,
      'Foo', 'main', '10'),
  CodeExample(
      'C# — Generics (Box<T>)', 'csharp', _exCsGenerics, 'Foo', 'main', '10'),
  // async/await (interpreted). Only Dart's async/await currently parses in
  // ApolloVM.
  CodeExample(
      'Dart — Async/await (Future)', 'dart', _exDartAsync, 'Foo', 'main', '5'),
  CodeExample('Dart — Async function (returns Future)', 'dart', _exDartAsyncFn,
      '', 'sumAsync', '10, 20'),
  // Wasm-compatible examples (apollovm Wasm backend, alpha). Each is a Dart
  // top-level function (or a single class instantiated from one) that compiles
  // to and runs on Wasm; loading one enables the "Wasm compiled" run mode.
  // All are verified end-to-end in the browser via the Wasm-compiled path.
  CodeExample('Wasm — Fibonacci', 'dart', _exDartFib, '', 'fibonacci', '10',
      wasm: true),
  CodeExample(
      'Wasm — Factorial', 'dart', _exWasmFactorial, '', 'factorial', '5',
      wasm: true),
  CodeExample('Wasm — GCD (Euclid)', 'dart', _exWasmGcd, '', 'gcd', '48, 36',
      wasm: true),
  CodeExample('Wasm — Power', 'dart', _exWasmPower, '', 'power', '2, 10',
      wasm: true),
  CodeExample('Wasm — Sum 1..N', 'dart', _exWasmSumTo, '', 'sumTo', '100',
      wasm: true),
  CodeExample(
      'Wasm — Collatz steps', 'dart', _exWasmCollatz, '', 'collatzSteps', '27',
      wasm: true),
  CodeExample(
      'Wasm — Prime check (print)', 'dart', _exWasmPrime, '', 'isPrime', '13',
      wasm: true),
  CodeExample(
      'Wasm — Class instance method', 'dart', _exWasmClass, '', 'run', '5',
      wasm: true),
  // Wasm control flow + bitwise (apollovm 0.1.40): `switch`/`case`, `do`/`while`
  // and the bitwise operators now compile to and run on Wasm.
  CodeExample(
      'Wasm — Switch/case (n % 3)', 'dart', _exWasmSwitch, '', 'classify', '7',
      wasm: true),
  CodeExample(
      'Wasm — Bit count (& >>)', 'dart', _exWasmBitCount, '', 'bitCount', '13',
      wasm: true),
  CodeExample(
      'Wasm — Do/while sum 1..N', 'dart', _exWasmDoWhile, '', 'sumTo', '5',
      wasm: true),
];

const _exDartFib =
    r'''// Top-level function: runs both Interpreted and Wasm-compiled.
// The returned value is shown in the OUTPUT "result" panel.
int fibonacci(int n) {
  if (n <= 1) {
    return n;
  }
  var a = 0;
  var b = 1;
  var i = 2;
  while (i <= n) {
    var c = a + b;
    a = b;
    b = c;
    i = i + 1;
  }
  return b;
}
''';

const _exJava = r'''class Foo {
   static public void main(Object[] args) {
     var title = args[0];
     var a = args[1];
     var b = args[2];
     var c = args[3];
     var sumAB = a + b ;
     var sumABC = a + b + c;
     print(title);
     print(sumAB);
     print(sumABC);
   }
}
''';

const _exKotlin = r'''class Foo {
    fun main(title: String, a: Int, b: Int, c: Int) {
      val sumAB = a + b
      val sumABC = a + b + c
      println(title)
      println(sumAB)
      println(sumABC)
    }
}
''';

const _exJs = r'''class Foo {
  main(title, a, b, c) {
    let sumAB = a + b;
    let sumABC = a + b + c;
    print(title);
    print(sumAB);
    print(sumABC);
  }
}
''';

const _exTs = r'''class Foo {
  main(title: string, a: number, b: number, c: number): void {
    let sumAB: number = a + b;
    let sumABC: number = a + b + c;
    print(title);
    print(sumAB);
    print(sumABC);
  }
}
''';

const _exLua = r'''Foo = {}
Foo.__index = Foo

function Foo:main(title, a, b, c)
  local sumAB = a + b
  local sumABC = a + b + c
  print(title)
  print(sumAB)
  print(sumABC)
end
''';

const _exDartTryCatch = r'''class Foo {
  void main(int a, int b) {
    // Catch a built-in VM runtime error (division by zero):
    try {
      print('a ~/ b = ${a ~/ b}');
    } catch (e) {
      print('caught runtime error: $e');
    } finally {
      print('division done');
    }

    // Catch a user-thrown value (typed `on String`); finally always runs:
    try {
      if (b == 0) {
        throw 'b must not be zero';
      }
      print('b is fine: $b');
    } on String catch (msg) {
      print('caught: $msg');
    } finally {
      print('check done');
    }
  }
}
''';

const _exJavaTryCatch = r'''class Foo {
   static public void main(int a, int b) {
     // Catch a built-in VM runtime error (integer division by zero):
     try {
       print("a / b = " + (a / b));
     } catch (Exception e) {
       print("caught runtime error: " + e);
     } finally {
       print("division done");
     }

     // Catch a user-thrown value (typed); finally always runs:
     try {
       if (b == 0) {
         throw "b must not be zero";
       }
       print("b is fine: " + b);
     } catch (String msg) {
       print("caught: " + msg);
     } finally {
       print("check done");
     }
   }
}
''';

const _exKotlinTryCatch = r'''class Foo {
    fun main(a: Int, b: Int) {
      // Catch a built-in VM runtime error (integer division by zero):
      try {
        println("a / b = " + (a / b))
      } catch (e: Exception) {
        println("caught runtime error: " + e)
      } finally {
        println("division done")
      }

      // Catch a user-thrown value (typed); finally always runs:
      try {
        if (b == 0) {
          throw "b must not be zero"
        }
        println("b is fine: " + b)
      } catch (e: String) {
        println("caught: " + e)
      } finally {
        println("check done")
      }
    }
}
''';

// JavaScript division by zero is `Infinity` (not an error), so this example
// focuses on catching a user `throw`; `finally` always runs.
const _exJsTryCatch = r'''class Foo {
  main(a, b) {
    try {
      if (b == 0) {
        throw "b must not be zero";
      }
      print("b is fine: " + b);
    } catch (e) {
      print("caught: " + e);
    } finally {
      print("check done");
    }
  }
}
''';

const _exTsTryCatch = r'''class Foo {
  main(a: number, b: number): void {
    try {
      if (b == 0) {
        throw "b must not be zero";
      }
      print("b is fine: " + b);
    } catch (e) {
      print("caught: " + e);
    } finally {
      print("check done");
    }
  }
}
''';

// Python support (apollovm 0.1.35): a class with a method, PEP-484 type hints
// optional. Uses `self` and idiomatic snake_case.
const _exPython = r'''class Foo:
    def main(self, title, a, b, c):
        sum_ab = a + b
        sum_abc = a + b + c
        print(title)
        print(sum_ab)
        print(sum_abc)
''';

// Conditional / ternary expressions (apollovm 0.1.36). Only the selected branch
// is evaluated.
const _exDartTernary = r'''class Foo {
  void main(int a, int b) {
    var max = a > b ? a : b;
    var label = max > 100 ? 'big' : 'small';
    print('max: $max ($label)');
  }
}
''';

const _exJavaTernary = r'''class Foo {
   static public void main(int a, int b) {
     int max = a > b ? a : b;
     String label = max > 100 ? "big" : "small";
     print("max: " + max + " (" + label + ")");
   }
}
''';

const _exKotlinTernary = r'''class Foo {
    fun main(a: Int, b: Int) {
      val max = if (a > b) a else b
      val label = if (max > 100) "big" else "small"
      println("max: " + max + " (" + label + ")")
    }
}
''';

const _exJsTernary = r'''class Foo {
  main(a, b) {
    let max = a > b ? a : b;
    let label = max > 100 ? "big" : "small";
    print("max: " + max + " (" + label + ")");
  }
}
''';

const _exTsTernary = r'''class Foo {
  main(a: number, b: number): void {
    let max: number = a > b ? a : b;
    let label: string = max > 100 ? "big" : "small";
    print("max: " + max + " (" + label + ")");
  }
}
''';

const _exPythonTernary = r'''class Foo:
    def main(self, a, b):
        max = a if a > b else b
        label = "big" if max > 100 else "small"
        print(f"max: {max} ({label})")
''';

// Anonymous functions / lambdas / closures (apollovm 0.1.36): function values
// stored in variables and invoked dynamically.
const _exDartLambda = r'''class Foo {
  void main(int x) {
    var twice = (int n) => n * 2;
    var inc = (int n) => n + 1;
    print('twice: ${twice(x)} ; inc: ${inc(x)}');
  }
}
''';

const _exJsLambda = r'''class Foo {
  main(x) {
    let twice = (n) => n * 2;
    let inc = (n) => n + 1;
    print("twice: " + twice(x) + " ; inc: " + inc(x));
  }
}
''';

const _exTsLambda = r'''class Foo {
  main(x: number): void {
    let twice = (n: number) => n * 2;
    let inc = (n: number) => n + 1;
    print("twice: " + twice(x) + " ; inc: " + inc(x));
  }
}
''';

const _exPythonLambda = r'''class Foo:
    def main(self, x):
        twice = lambda n: n * 2
        inc = lambda n: n + 1
        print(twice(x))
        print(inc(x))
''';

// async/await (interpreted): `await` on calls to other `async` methods that
// return a `Future`.
const _exDartAsync = r'''class Foo {
  Future<int> doubleIt(int n) async {
    return n * 2;
  }

  Future<int> increment(int n) async {
    return n + 1;
  }

  Future<void> main(int x) async {
    var doubled = await doubleIt(x);
    var result = await increment(doubled);
    print('doubled: $doubled');
    print('incremented: $result');
  }
}
''';

// Top-level `async` function returning a `Future<int>`; the awaited return
// value is shown in the OUTPUT "result" panel.
const _exDartAsyncFn = r'''Future<int> sumAsync(int a, int b) async {
  // The awaited return value is shown in the OUTPUT "result" panel.
  var sum = a + b;
  return sum;
}
''';

// Wasm-compatible examples: Dart top-level functions (integer math, loops,
// branches) that the Wasm backend compiles and runs. The returned value is
// shown in the OUTPUT "result" panel.
const _exWasmFactorial = r'''int factorial(int n) {
  var r = 1;
  var i = 2;
  while (i <= n) {
    r = r * i;
    i = i + 1;
  }
  return r;
}
''';

const _exWasmGcd = r'''int gcd(int a, int b) {
  while (b != 0) {
    var t = b;
    b = a % b;
    a = t;
  }
  return a;
}
''';

const _exWasmPower = r'''int power(int base, int exp) {
  var r = 1;
  var i = 0;
  while (i < exp) {
    r = r * base;
    i = i + 1;
  }
  return r;
}
''';

const _exWasmSumTo = r'''int sumTo(int n) {
  var sum = 0;
  var i = 1;
  while (i <= n) {
    sum = sum + i;
    i = i + 1;
  }
  return sum;
}
''';

const _exWasmCollatz = r'''int collatzSteps(int n) {
  var steps = 0;
  while (n != 1) {
    if (n % 2 == 0) {
      n = n ~/ 2;
    } else {
      n = 3 * n + 1;
    }
    steps = steps + 1;
  }
  return steps;
}
''';

// Demonstrates `print` marshalling from a Wasm module (host import): prints
// `prime`/`not prime` and returns 1/0.
const _exWasmPrime = r'''int isPrime(int n) {
  if (n < 2) {
    print('not prime');
    return 0;
  }
  var i = 2;
  while (i * i <= n) {
    if (n % i == 0) {
      print('not prime');
      return 0;
    }
    i = i + 1;
  }
  print('prime');
  return 1;
}
''';

// Single class compiled to Wasm with an instance method, instantiated and
// called from a top-level entry-point function.
const _exWasmClass = r'''class Counter {
  int base;
  int addTo(int n) {
    return base + n;
  }
}

int run(int x) {
  var c = Counter();
  c.base = 10;
  return c.addTo(x);
}
''';

// C# language support (apollovm 0.1.37): a class with a method, idiomatic
// modifiers and `print` (the VM's print function).
const _exCs = r'''class Foo {
  public void main(string title, int a, int b, int c) {
    int sumAB = a + b;
    int sumABC = a + b + c;
    print(title);
    print(sumAB);
    print(sumABC);
  }
}
''';

const _exCsTernary = r'''class Foo {
  public void main(int a, int b) {
    int max = a > b ? a : b;
    string label = max > 100 ? "big" : "small";
    print("max: " + max + " (" + label + ")");
  }
}
''';

const _exCsTryCatch = r'''class Foo {
  public void main(int a, int b) {
    try {
      if (b == 0) {
        throw "b must not be zero";
      }
      print("b is fine: " + b);
    } catch (Exception e) {
      print("caught: " + e);
    } finally {
      print("check done");
    }
  }
}
''';

// Lambda parsing for Java, Kotlin and Lua (apollovm 0.1.37): anonymous
// functions stored in variables and invoked.
const _exJavaLambda = r'''class Foo {
   static public void main(int x) {
     var twice = (int n) -> n * 2;
     var inc = (int n) -> n + 1;
     print("twice: " + twice(x) + " ; inc: " + inc(x));
   }
}
''';

const _exKotlinLambda = r'''class Foo {
    fun main(x: Int) {
      val twice = { n: Int -> n * 2 }
      val inc = { n: Int -> n + 1 }
      println("twice: " + twice(x) + " ; inc: " + inc(x))
    }
}
''';

const _exLuaLambda = r'''Foo = {}
Foo.__index = Foo

function Foo:main(x)
  local twice = function(n) return n * 2 end
  local inc = function(n) return n + 1 end
  print("twice: " .. twice(x) .. " ; inc: " .. inc(x))
end
''';

// C# lambda parsing (apollovm 0.1.38): anonymous functions bound to `Func`
// delegates and invoked.
const _exCsLambda = r'''class Foo {
  public void main(int x) {
    Func twice = n => n * 2;
    Func inc = n => n + 1;
    print("twice: " + twice(x) + " ; inc: " + inc(x));
  }
}
''';

// switch / case (apollovm 0.1.38): C-style fall-through (`break` ends a case,
// `default` runs when nothing matches).
const _exDartSwitch = r'''class Foo {
  void main(int n) {
    switch (n) {
      case 1:
        print('one');
        break;
      case 2:
        print('two');
        break;
      default:
        print('many');
    }
  }
}
''';

const _exJavaSwitch = r'''class Foo {
   static public void main(int n) {
     switch (n) {
       case 1:
         print("one");
         break;
       case 2:
         print("two");
         break;
       default:
         print("many");
     }
   }
}
''';

// Kotlin maps `switch` to `when (e) { v -> … ; else -> … }` (no fall-through).
const _exKotlinWhen = r'''class Foo {
    fun main(n: Int) {
      when (n) {
        1 -> println("one")
        2 -> println("two")
        else -> println("many")
      }
    }
}
''';

const _exJsSwitch = r'''class Foo {
  main(n) {
    switch (n) {
      case 1:
        print("one");
        break;
      case 2:
        print("two");
        break;
      default:
        print("many");
    }
  }
}
''';

const _exTsSwitch = r'''class Foo {
  main(n: number): void {
    switch (n) {
      case 1:
        print("one");
        break;
      case 2:
        print("two");
        break;
      default:
        print("many");
    }
  }
}
''';

// Python maps `switch` to `match`/`case` (`case _:` is the default).
const _exPythonMatch = r'''class Foo:
    def main(self, n):
        match n:
            case 1:
                print("one")
            case 2:
                print("two")
            case _:
                print("many")
''';

const _exCsSwitch = r'''class Foo {
  public void main(int n) {
    switch (n) {
      case 1:
        print("one");
        break;
      case 2:
        print("two");
        break;
      default:
        print("many");
    }
  }
}
''';

// do/while loop (apollovm 0.1.38): the body always runs at least once.
const _exDartDoWhile = r'''class Foo {
  void main(int n) {
    var i = 0;
    do {
      print('i: $i');
      i = i + 1;
    } while (i < n);
  }
}
''';

const _exKotlinDoWhile = r'''class Foo {
    fun main(n: Int) {
      var i = 0
      do {
        println("i: " + i)
        i = i + 1
      } while (i < n)
    }
}
''';

// Lua has no `do`/`while`; ApolloVM maps it to `repeat … until <cond>` (the
// condition is the negation of a do-while's continue condition).
const _exLuaRepeat = r'''Foo = {}
Foo.__index = Foo

function Foo:main(n)
  local i = 0
  repeat
    print("i: " .. i)
    i = i + 1
  until i >= n
end
''';

// Bitwise operators (apollovm 0.1.38; Kotlin/Lua added 0.1.40).
const _exDartBitwise = r'''class Foo {
  void main(int a, int b) {
    print('and: ${a & b}');
    print('or: ${a | b}');
    print('xor: ${a ^ b}');
    print('shl: ${a << 1}');
    print('shr: ${a >> 1}');
    print('not: ${~a}');
  }
}
''';

const _exJavaBitwise = r'''class Foo {
   static public void main(int a, int b) {
     print("and: " + (a & b));
     print("or: " + (a | b));
     print("xor: " + (a ^ b));
     print("shl: " + (a << 1));
     print("shr: " + (a >> 1));
     print("not: " + (~a));
   }
}
''';

// Kotlin's bitwise are infix functions: `and`/`or`/`xor`/`shl`/`shr`.
const _exKotlinBitwise = r'''class Foo {
    fun main(a: Int, b: Int) {
      println("and: " + (a and b))
      println("or: " + (a or b))
      println("xor: " + (a xor b))
      println("shl: " + (a shl 1))
      println("shr: " + (a shr 1))
    }
}
''';

// Lua bitwise: `&` `|` `~` (xor) `<<` `>>` and unary `~` (complement), using
// local literals (the operands must be integers).
const _exLuaBitwise = r'''Foo = {}
Foo.__index = Foo

function Foo:main()
  local a = 12
  local b = 10
  print("and: " .. (a & b))
  print("or: " .. (a | b))
  print("xor: " .. (a ~ b))
  print("shl: " .. (a << 1))
  print("shr: " .. (a >> 1))
  print("not: " .. (~a))
end
''';

const _exCsBitwise = r'''class Foo {
  public void main(int a, int b) {
    print("and: " + (a & b));
    print("or: " + (a | b));
    print("xor: " + (a ^ b));
    print("shl: " + (a << 1));
    print("shr: " + (a >> 1));
    print("not: " + (~a));
  }
}
''';

// enum with runtime value access (apollovm 0.1.39): an enum entry used where a
// value is expected resolves to its ordinal index (Dart/Java/Kotlin/Python) or
// its explicit value (C#).
const _exDartEnum = r'''enum Color { red, green, blue }

class Foo {
  void main() {
    int green = Color.green;
    int blue = Color.blue;
    print('green: $green ; blue: $blue');
  }
}
''';

const _exJavaEnum = r'''enum Color { red, green, blue }

class Foo {
  static public void main() {
    int green = Color.green;
    int blue = Color.blue;
    print("green: " + green + " ; blue: " + blue);
  }
}
''';

const _exKotlinEnum = r'''enum class Color { red, green, blue }

class Foo {
    fun main() {
      val green: Int = Color.green
      val blue: Int = Color.blue
      println("green: " + green + " ; blue: " + blue)
    }
}
''';

const _exPythonEnum = r'''from enum import Enum

class Color(Enum):
    red = 0
    green = 1
    blue = 2

class Foo:
    def main(self):
        green = Color.green
        blue = Color.blue
        print(f"green: {green} ; blue: {blue}")
''';

const _exCsEnum = r'''enum Level { Low = 1, Medium = 5, High = 10 }

class Foo {
  public void main() {
    int x = Level.Medium;
    int y = Level.High;
    print("Medium: " + x + " ; High: " + y);
  }
}
''';

// Generic classes (apollovm 0.1.39): a `Box<T>` declared, instantiated with a
// type argument and read back.
const _exDartGenerics = r'''class Box<T> {
  T value;
  Box(this.value);
}

class Foo {
  void main(int x) {
    var b = Box<int>(x);
    print('box: ${b.value}');
  }
}
''';

const _exJavaGenerics = r'''class Box<T> {
  T value;
  Box(T value) {
    this.value = value;
  }
}

class Foo {
  static public void main(int x) {
    Box<Integer> b = new Box<Integer>(x);
    print("box: " + b.value);
  }
}
''';

const _exKotlinGenerics = r'''class Box<T> {
  var value: T
  constructor(value: T) {
    this.value = value
  }
}

class Foo {
    fun main(x: Int) {
      val b = Box<Int>(x)
      println("box: " + b.value)
    }
}
''';

const _exTsGenerics = r'''class Box<T> {
  value: T;
  constructor(value: T) {
    this.value = value;
  }
}

class Foo {
  main(x: number): void {
    let b: Box<number> = new Box<number>(x);
    print("box: " + b.value);
  }
}
''';

const _exCsGenerics = r'''class Box<T> {
  T value;
  Box(T value) {
    this.value = value;
  }
}

class Foo {
  public void main(int x) {
    Box<int> b = new Box<int>(x);
    print("box: " + b.value);
  }
}
''';

// Wasm control flow + bitwise (apollovm 0.1.40): `switch`/`case`, `do`/`while`
// and the bitwise operators compile to and run on Wasm. Each returns an int
// shown in the OUTPUT "result" panel.
const _exWasmSwitch = r'''int classify(int n) {
  switch (n % 3) {
    case 0:
      return 100;
    case 1:
      return 200;
    default:
      return 300;
  }
}
''';

const _exWasmBitCount = r'''int bitCount(int n) {
  var count = 0;
  while (n != 0) {
    count = count + (n & 1);
    n = n >> 1;
  }
  return count;
}
''';

const _exWasmDoWhile = r'''int sumTo(int n) {
  var sum = 0;
  var i = 1;
  do {
    sum = sum + i;
    i = i + 1;
  } while (i <= n);
  return sum;
}
''';

/// Display labels for the example categories, keyed by category code. A
/// category is the example's source language, except Wasm examples, which are
/// grouped under their own `wasm` category.
const _exampleLanguageLabels = <String, String>{
  'dart': 'Dart',
  'java11': 'Java11',
  'kotlin': 'Kotlin',
  'javascript': 'JavaScript',
  'typescript': 'TypeScript',
  'lua': 'Lua',
  'python': 'Python',
  'csharp': 'C#',
  'wasm': 'Wasm',
};

/// The selector category of [e]: `wasm` for Wasm examples, otherwise its
/// source language.
String exampleCategory(CodeExample e) => e.wasm ? 'wasm' : e.language;

/// The distinct example categories, in first-seen order.
List<String> exampleCategories() {
  var categories = <String>[];
  for (var e in codeExamples) {
    var category = exampleCategory(e);
    if (!categories.contains(category)) categories.add(category);
  }
  return categories;
}

/// Index in [codeExamples] of the first example in [category], or `-1`.
int firstExampleIndexForCategory(String category) =>
    codeExamples.indexWhere((e) => exampleCategory(e) == category);

/// The example name without its leading `<Category> — ` prefix (the category
/// is now chosen in its own selector, so the prefix would be redundant).
String exampleOptionLabel(CodeExample e) {
  var i = e.name.indexOf(' — ');
  return i >= 0 ? e.name.substring(i + 3) : e.name;
}

/// Fills the example selector with the [codeExamples] in [category]; each
/// option's value is the example's index in [codeExamples].
void populateExampleSelect(String category) {
  var options = codeExamples
      .mapIndexed((i, e) => exampleCategory(e) == category
          ? '<option value="$i">${exampleOptionLabel(e)}</option>'
          : null)
      .nonNulls
      .join('\n    ');
  selectExampleSelect().innerHTML = options.toJS;
}
