import 'dart:convert';

// `Range` (DOM) and `SymbolKind` (ApolloVM core) are hidden so the LSP
// protocol's `Range`/`SymbolKind` (from `apollovm_lsp.dart`) win.
import 'package:web/web.dart' hide MimeType, Range;

import 'package:apollovm/apollovm.dart' hide SymbolKind;
import 'package:apollovm/apollovm_lsp.dart';
import 'package:apollovm/apollovm_repository.dart';
import 'package:collection/collection.dart';
import 'package:dom_tools/dom_tools.dart';
import 'package:swiss_knife/swiss_knife.dart';
import 'package:data_serializer/data_serializer.dart';

// The playground is organized as a single library split across `web/src/`:
part 'src/code_examples.dart'; // CodeExample data + category helpers.
part 'src/ui_builder.dart'; // buildUI(): HTML template + event wiring.
part 'src/dom.dart'; // _listen() + DOM `selectX()` helpers.
part 'src/code_editor.dart'; // Line-numbered code editor.
part 'src/vm.dart'; // ApolloVM execute / compile / convert.
part 'src/actions.dart'; // UI action handlers + output panel.
part 'src/lsp.dart'; // In-process LSP: diagnostics, outline, hover.
part 'src/highlight.dart'; // Per-language syntax highlighting.
part 'src/completion.dart'; // LSP-driven code completion popup.
part 'src/repository.dart'; // Remote repository: file tree, edit/save, git.

void main() async {
  buildUI();
}
