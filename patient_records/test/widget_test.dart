import 'package:flutter_test/flutter_test.dart';
import 'package:patient_records/main.dart';

void main() {
  testWidgets('Clinic app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ClinicApp());
    expect(find.byType(ClinicApp), findsOneWidget);
  });
}
