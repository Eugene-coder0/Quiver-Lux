import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiver_lux/main.dart';
import 'package:quiver_lux/features/customer/models/product_model.dart';
import 'package:quiver_lux/features/vendor/providers/vendor_providers.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerProductsProvider.overrideWith(
            (ref) async => const <ProductModel>[],
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MyApp), findsOneWidget);
  });
}
