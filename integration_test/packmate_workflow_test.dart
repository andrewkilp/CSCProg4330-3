import 'package:integration_test/integration_test.dart';

import 'packmate_workflow.dart';

/// Device entry point: `flutter test integration_test -d <android-device-id>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  packMateWorkflowTests();
}
