/// Result of a Myanmar Kyat-Pae-Yway gold price calculation.
class GoldCalculationResult {
  const GoldCalculationResult({
    required this.totalKyatWeight,
    required this.wastageKyatWeight,
    required this.goldValueMmk,
    required this.wastageValueMmk,
    required this.makingFeeMmk,
    required this.totalMmk,
  });

  final double totalKyatWeight;
  final double wastageKyatWeight;
  final int goldValueMmk;
  final int wastageValueMmk;
  final int makingFeeMmk;
  final int totalMmk;
}

/// Result of a flat-rate installment loan calculation.
class InstallmentResult {
  const InstallmentResult({
    required this.financedAmount,
    required this.monthlyPayment,
    required this.totalInterest,
    required this.totalPayable,
  });

  final int financedAmount;
  final int monthlyPayment;
  final int totalInterest;
  final int totalPayable;
}

/// Pure offline domain calculators for everyday Myanmar financial math.
class MyanmarCalculators {
  const MyanmarCalculators._();

  static const int paePerKyat = 16;
  static const int ywayPerPae = 8;
  static const int ywayPerKyat = paePerKyat * ywayPerPae; // 128

  /// Converts Myanmar gold weight ([kyat], [pae], [yway]) into total Kyattha.
  static double toKyatWeight({
    required int kyat,
    required int pae,
    required double yway,
  }) {
    final safeKyat = kyat < 0 ? 0 : kyat;
    final safePae = pae < 0 ? 0 : pae;
    final safeYway = yway < 0 ? 0.0 : yway;
    return safeKyat + (safePae / paePerKyat) + (safeYway / ywayPerKyat);
  }

  /// Calculates Myanmar gold price including wastage (အလျော့တွက်) and making fee (လက်ခ).
  static GoldCalculationResult calculateGoldPrice({
    required int kyat,
    required int pae,
    required double yway,
    required double pricePerKyat,
    double wastagePae = 0,
    double wastageYway = 0,
    double makingFeeMmk = 0,
  }) {
    final safePrice = pricePerKyat < 0 ? 0.0 : pricePerKyat;
    final baseWeight = toKyatWeight(kyat: kyat, pae: pae, yway: yway);
    final wastageWeight = toKyatWeight(
      kyat: 0,
      pae: wastagePae < 0 ? 0 : wastagePae.floor(),
      yway: ((wastagePae < 0 ? 0 : (wastagePae - wastagePae.floor()) * ywayPerPae)) +
          (wastageYway < 0 ? 0 : wastageYway),
    );

    final goldValue = (baseWeight * safePrice).round();
    final wastageValue = (wastageWeight * safePrice).round();
    final safeMakingFee = makingFeeMmk < 0 ? 0 : makingFeeMmk.round();

    return GoldCalculationResult(
      totalKyatWeight: baseWeight,
      wastageKyatWeight: wastageWeight,
      goldValueMmk: goldValue,
      wastageValueMmk: wastageValue,
      makingFeeMmk: safeMakingFee,
      totalMmk: goldValue + wastageValue + safeMakingFee,
    );
  }

  /// Calculates flat monthly interest installments commonly used in retail financing.
  static InstallmentResult calculateInstallment({
    required double principal,
    required double downPayment,
    required double monthlyFlatInterestPercent,
    required int months,
  }) {
    final safePrincipal = principal < 0 ? 0.0 : principal;
    final safeDown = downPayment < 0
        ? 0.0
        : (downPayment > safePrincipal ? safePrincipal : downPayment);
    final financed = safePrincipal - safeDown;
    final safeMonths = months <= 0 ? 1 : months;
    final safeRate =
        monthlyFlatInterestPercent < 0 ? 0.0 : monthlyFlatInterestPercent;

    final totalInterest = financed * (safeRate / 100.0) * safeMonths;
    final totalPayable = financed + totalInterest;
    final monthly = totalPayable / safeMonths;

    return InstallmentResult(
      financedAmount: financed.round(),
      monthlyPayment: monthly.round(),
      totalInterest: totalInterest.round(),
      totalPayable: totalPayable.round(),
    );
  }

  /// Converts between MMK and a foreign currency using [rateMmkPerUnit].
  static double convertCurrency({
    required double amount,
    required double rateMmkPerUnit,
    required bool toMmk,
  }) {
    if (amount <= 0 || rateMmkPerUnit <= 0) return 0;
    return toMmk ? amount * rateMmkPerUnit : amount / rateMmkPerUnit;
  }
}
