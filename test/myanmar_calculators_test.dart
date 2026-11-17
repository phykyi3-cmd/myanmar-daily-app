import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_daily_app/domain/use_cases/myanmar_calculators.dart';

void main() {
  group('MyanmarCalculators', () {
    test('converts kyat, pae, yway accurately', () {
      final weight = MyanmarCalculators.toKyatWeight(
        kyat: 1,
        pae: 8,
        yway: 4,
      );
      expect(weight, closeTo(1.53125, 0.0001));
    });

    test('calculates gold price with wastage and making fee', () {
      final result = MyanmarCalculators.calculateGoldPrice(
        kyat: 0,
        pae: 8,
        yway: 0,
        pricePerKyat: 6000000,
        wastagePae: 1,
        makingFeeMmk: 50000,
      );

      expect(result.goldValueMmk, 3000000);
      expect(result.wastageValueMmk, 375000);
      expect(result.makingFeeMmk, 50000);
      expect(result.totalMmk, 3425000);
    });

    test('calculates flat installment monthly payment and total payable', () {
      final result = MyanmarCalculators.calculateInstallment(
        principal: 1000000,
        downPayment: 200000,
        monthlyFlatInterestPercent: 2,
        months: 5,
      );

      expect(result.financedAmount, 800000);
      expect(result.totalInterest, 80000);
      expect(result.totalPayable, 880000);
      expect(result.monthlyPayment, 176000);
    });

    test('converts currency both ways safely', () {
      expect(
        MyanmarCalculators.convertCurrency(
          amount: 100,
          rateMmkPerUnit: 4500,
          toMmk: true,
        ),
        450000,
      );
      expect(
        MyanmarCalculators.convertCurrency(
          amount: 450000,
          rateMmkPerUnit: 4500,
          toMmk: false,
        ),
        100,
      );
    });
  });
}
