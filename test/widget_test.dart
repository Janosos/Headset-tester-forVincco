import 'package:flutter_test/flutter_test.dart';
import 'package:headset_tester_vincco/main.dart';

void main() {
  testWidgets('HeadsetTesterApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HeadsetTesterApp(startMinimized: false));
    expect(find.text('Vincco Headset Tester'), findsWidgets);
  });
}
