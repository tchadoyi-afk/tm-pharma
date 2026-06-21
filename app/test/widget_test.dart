import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tm_pharma/main.dart';

void main() {
  testWidgets('L\'app démarre et affiche le nom TM Pharma',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TmPharmaApp()));
    await tester.pumpAndSettle();

    expect(find.text('TM Pharma'), findsWidgets);
  });
}
