import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiver_lux/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    expect(find.byType(MyApp), findsOneWidget);
  });
}
