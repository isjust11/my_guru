import 'package:flutter_test/flutter_test.dart';

import 'package:my_guru/main.dart';

void main() {
  testWidgets('MyGuru app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyGuruApp());

    // Verify app loads with MyGuru title
    expect(find.text('MyGuru'), findsWidgets);
  });
}
