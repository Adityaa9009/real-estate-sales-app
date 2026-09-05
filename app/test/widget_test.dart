import 'package:real_estate_sales_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the real estate login page', (tester) async {
    await tester.pumpWidget(const RealEstateSalesApp());
    expect(find.text('REAL ESTATE'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
