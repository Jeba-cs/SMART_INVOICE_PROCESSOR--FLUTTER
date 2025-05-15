import 'package:flutter_test/flutter_test.dart';
import 'package:smart_invoice_app/main.dart';

void main() {
  testWidgets('SmartInvoiceApp has a title', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartInvoiceApp());

    // Looks for the AppBar title
    expect(find.text('Smart Invoice Processor'), findsOneWidget);
  });
}
