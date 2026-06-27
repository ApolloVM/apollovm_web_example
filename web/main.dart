import 'dart:convert';

import 'package:web/web.dart' hide MimeType;

import 'package:apollovm/apollovm.dart';
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

void main() async {
  buildUI();
}
