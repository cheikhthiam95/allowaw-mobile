// Test de fumée minimal : un écran autonome (pas d'appel réseau réel au
// bootstrap, contrairement à AllowawApp qui déclenche AuthProvider.bootstrap()
// + les chargements initiaux dès le premier frame) s'affiche sans exception.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allowaw_mobile/core/theme.dart';
import 'package:allowaw_mobile/screens/auth/login_screen.dart';

void main() {
  testWidgets("L'écran de connexion s'affiche sans exception", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const LoginScreen()));
    await tester.pump();

    expect(find.text('allôwaw'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
