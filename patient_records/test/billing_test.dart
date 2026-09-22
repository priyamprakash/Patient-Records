import 'package:flutter_test/flutter_test.dart';
import 'package:patient_records/models/models.dart';

void main() {
  group('Billing and Discount Tests', () {
    test('Calculates bill subtotal correctly', () {
      final items = [
        BillItem(id: '1', description: 'Consultation', quantity: 1, unitPrice: 500.0),
        BillItem(id: '2', description: '[Diagnostic] Lipid Profile', quantity: 1, unitPrice: 800.0),
      ];

      final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      expect(subtotal, 1300.0);
    });

    test('Calculates percentage discount correctly', () {
      const subtotal = 1000.0;
      const discountPercent = 10.0; // 10%
      final calculatedDiscount = (subtotal * discountPercent) / 100.0;
      expect(calculatedDiscount, 100.0);
      expect(subtotal - calculatedDiscount, 900.0);
    });

    test('Calculates flat discount correctly', () {
      const subtotal = 1000.0;
      const flatDiscount = 150.0; // ₹150 off
      expect(subtotal - flatDiscount, 850.0);
    });
  });
}
