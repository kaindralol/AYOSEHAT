import 'dart:math';

const List<String> hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const List<String> hariPanjang = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu'
];
const List<String> bulanPendek = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des'
];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Senin pada minggu yang memuat [d].
DateTime startOfWeek(DateTime d) {
  final x = dateOnly(d);
  return addDays(x, -(x.weekday - 1));
}

int minuteOfDay(DateTime d) => d.hour * 60 + d.minute;

/// 960 -> "16.00"
String fmtMin(int m) {
  final h = (m ~/ 60).toString().padLeft(2, '0');
  final mm = (m % 60).toString().padLeft(2, '0');
  return '$h.$mm';
}

String fmtRange(int start, int end) => '${fmtMin(start)}–${fmtMin(end)}';

/// "Kam, 21 Nov"
String fmtDay(DateTime d) =>
    '${hariPendek[d.weekday - 1]}, ${d.day} ${bulanPendek[d.month - 1]}';

/// "Kamis, 21 Nov"
String fmtDayLong(DateTime d) =>
    '${hariPanjang[d.weekday - 1]}, ${d.day} ${bulanPendek[d.month - 1]}';

/// 35000 -> "Rp35.000"
String fmtRupiah(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp$b';
}

String fmtDuration(int minutes) {
  if (minutes < 60) return '$minutes menit';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h jam' : '$h jam $m menit';
}

final Random _rnd = Random();

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}${_rnd.nextInt(99999).toString().padLeft(5, '0')}';
