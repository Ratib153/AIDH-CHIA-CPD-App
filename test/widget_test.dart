import 'package:flutter_test/flutter_test.dart';

import 'package:aidh_chia_cpd_app/app.dart';

void main() {
  testWidgets('ChiaCpdApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ChiaCpdApp());
    expect(find.byType(ChiaCpdApp), findsOneWidget);
  });
}
