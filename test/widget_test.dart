import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drimain_mobile/main.dart';

void main() {
  testWidgets('App boots and shows Login or Dashboard', (tester) async {
    await tester.pumpWidget(const TPMApp());

    // Brak stanu zalogowania – spodziewamy się ekranu logowania.
    expect(find.textContaining('Zaloguj'), findsOneWidget);

    // Snapshot UI
    await expectLater(
      find.byType(TPMApp),
      matchesGoldenFile('goldens/app_start.png'),
      skip: true, // Usuń jeśli używasz goldenów
    );
  });
}
