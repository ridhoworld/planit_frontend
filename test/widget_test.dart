import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('PlanIt App smoke test', (WidgetTester tester) async {
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authProvider,
        child: const PlanItApp(),
      ),
    );

    expect(find.byType(PlanItApp), findsOneWidget);
  });
}
