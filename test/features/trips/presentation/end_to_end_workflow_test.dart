import 'package:flutter_test/flutter_test.dart';

import '../../../../integration_test/packmate_workflow.dart';

/// Host entry point for the same end-to-end workflow, so `flutter test` covers
/// it without an emulator. The device run lives in integration_test/.
/// A live binding is required because the workflow performs real SQLite I/O.
void main() {
  LiveTestWidgetsFlutterBinding();
  packMateWorkflowTests();
}
