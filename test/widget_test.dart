import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:geonexus/main.dart';
import 'package:geonexus/presentation/providers/auth_providers.dart';

void main() {
  testWidgets('renderiza a aplicação sem sessão', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Stream.value(
              const AuthState(AuthChangeEvent.signedOut, null),
            ),
          ),
        ],
        child: const GeonexusApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(GeonexusApp), findsOneWidget);
  });
}
