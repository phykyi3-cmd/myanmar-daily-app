/// Converts Myanmar numerals (`၀–၉`), commas, and whitespace into plain ASCII digits
/// so numeric inputs work identically on Burmese and English keyboards.
String normalizeAsciiDigits(String input) {
  const mmZero = 0x1040;
  final buf = StringBuffer();
  for (final code in input.trim().codeUnits) {
    if (code >= mmZero && code <= mmZero + 9) {
      buf.writeCharCode(0x30 + (code - mmZero));
    } else if (code == 0x2C /* , */ || code == 0x20 /* space */) {
      continue;
    } else {
      buf.writeCharCode(code);
    }
  }
  return buf.toString();
}

/// Lightweight formatting helpers without external locale dependencies.
String formatMmk(int amount) {
  final isNegative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    if (i > 0 && reverseIndex % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return '${isNegative ? '-' : ''}${buffer.toString()} ကျပ်';
}

/// Formats a [DateTime] as `YYYY-MM-DD`.
String formatDateShort(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

/// Returns Burmese weekday name (`တနင်္လာနေ့` .. `တနင်္ဂနွေနေ့`).
String formatBurmeseWeekday(DateTime date) {
  switch (date.weekday) {
    case DateTime.monday:
      return 'တနင်္လာနေ့';
    case DateTime.tuesday:
      return 'အင်္ဂါနေ့';
    case DateTime.wednesday:
      return 'ဗုဒ္ဓဟူးနေ့';
    case DateTime.thursday:
      return 'ကြာသပတေးနေ့';
    case DateTime.friday:
      return 'သောကြာနေ့';
    case DateTime.saturday:
      return 'စနေနေ့';
    default:
      return 'တနင်္ဂနွေနေ့';
  }
}

/// Formats a date in readable Burmese with weekday and relative today/yesterday badge.
String formatBurmeseFullDate(DateTime date, {DateTime? now}) {
  const months = <String>[
    'ဇန်နဝါရီ',
    'ဖေဖော်ဝါရီ',
    'မတ်',
    'ဧပြီ',
    'မေ',
    'ဇွန်',
    'ဇူလိုင်',
    'ဩဂုတ်',
    'စက်တင်ဘာ',
    'အောက်တိုဘာ',
    'နိုဝင်ဘာ',
    'ဒီဇင်ဘာ',
  ];
  final ref = now ?? DateTime.now();
  final todayKey = formatDateShort(ref);
  final yesterdayKey = formatDateShort(ref.subtract(const Duration(days: 1)));
  final targetKey = formatDateShort(date);

  final suffix = targetKey == todayKey
      ? ' (ယနေ့)'
      : targetKey == yesterdayKey
          ? ' (မနေ့က)'
          : '';
  final monthLabel = months[(date.month - 1).clamp(0, 11)];
  return '${formatBurmeseWeekday(date)} • ${date.day} $monthLabel ${date.year}$suffix';
}

/// Formats local time as `HH:mm`.
String formatTimeShort(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Formats days remaining in clear Burmese.
String formatDaysRemainingMm(int days) {
  if (days < 0) return '${days.abs()} ရက် ကျော်လွန်နေပါသည်';
  if (days == 0) return 'ယနေ့ နောက်ဆုံးရက်';
  if (days == 1) return 'မနက်ဖြန်';
  return '$days ရက် အလို';
}
