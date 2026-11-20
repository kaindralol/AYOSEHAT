import 'models.dart';
import 'utils/format.dart';

/// Membaca teks jadwal (hasil CSV, Excel, foto, atau .txt) menjadi kegiatan.
///
/// Aturan sederhana yang cocok untuk jadwal kuliah/kegiatan mahasiswa:
/// - Nama hari (Senin…Minggu / Monday…Sunday) menandai hari kegiatan,
///   berlaku untuk baris itu dan baris-baris di bawahnya.
/// - Rentang jam seperti "07.00 - 09.30", "07:00 s.d. 09:30", "07:00 | 09:30".
/// - Tanggal (2026-11-24, 24/11/2026, 24 Nov 2026) = kegiatan sekali saja.
/// - Sisa teks di baris itu dipakai sebagai nama kegiatan.

const Map<String, int> _days = {
  'senin': 1,
  'selasa': 2,
  'rabu': 3,
  'kamis': 4,
  "jum'at": 5,
  'jumat': 5,
  'sabtu': 6,
  'minggu': 7,
  'ahad': 7,
  'monday': 1,
  'tuesday': 2,
  'wednesday': 3,
  'thursday': 4,
  'friday': 5,
  'saturday': 6,
  'sunday': 7,
};

const Map<String, int> _months = {
  'jan': 1, 'januari': 1, 'january': 1,
  'feb': 2, 'februari': 2, 'february': 2,
  'mar': 3, 'maret': 3, 'march': 3,
  'apr': 4, 'april': 4,
  'mei': 5, 'may': 5,
  'jun': 6, 'juni': 6, 'june': 6,
  'jul': 7, 'juli': 7, 'july': 7,
  'agu': 8, 'agt': 8, 'agustus': 8, 'aug': 8, 'august': 8,
  'sep': 9, 'sept': 9, 'september': 9,
  'okt': 10, 'oktober': 10, 'oct': 10, 'october': 10,
  'nov': 11, 'november': 11,
  'des': 12, 'desember': 12, 'dec': 12, 'december': 12,
};

final RegExp _timeRange = RegExp(
  r'(\d{1,2})\s*[.:]\s*(\d{2})(?:[.:]\d{2})?\s*'
  r'(?:-|–|—|\||s\.?\s?d\.?|sampai|hingga|to)\s*'
  r'(\d{1,2})\s*[.:]\s*(\d{2})(?:[.:]\d{2})?',
  caseSensitive: false,
);
final RegExp _isoDate = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
final RegExp _dmyDate = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b');
final RegExp _textDate = RegExp(r'\b(\d{1,2})\s+([a-zA-Z]{3,9})\s+(\d{4})\b');

AgendaType guessType(String title) {
  final t = title.toLowerCase();
  if (RegExp(r'rapat|himpunan|hmsi|bem|ukm|panitia|kaderisasi|organisasi|ormawa|lkmm|staff|divisi')
      .hasMatch(t)) {
    return AgendaType.organisasi;
  }
  if (RegExp(r'tugas|deadline|kerja kelompok|laporan|kuis|quiz|ujian|ets|eas|uts|uas')
      .hasMatch(t)) {
    return AgendaType.tugas;
  }
  if (RegExp(r'kuliah|kelas|praktikum|matkul|tutorial|responsi|asistensi|dasar|kalkulus|fisika|kimia|matematika|pemrograman|sistem|algoritma|statistika|bahasa|agama|pancasila|kewarganegaraan')
      .hasMatch(t)) {
    return AgendaType.kuliah;
  }
  return AgendaType.lainnya;
}

int? _dayIn(String lower) {
  int? best;
  var bestPos = 1 << 30;
  _days.forEach((name, idx) {
    final m = RegExp('\\b${RegExp.escape(name)}\\b').firstMatch(lower);
    if (m != null && m.start < bestPos) {
      bestPos = m.start;
      best = idx;
    }
  });
  return best;
}

DateTime? _dateIn(String line) {
  var m = _isoDate.firstMatch(line);
  if (m != null) {
    return _safeDate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }
  m = _dmyDate.firstMatch(line);
  if (m != null) {
    return _safeDate(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
  }
  m = _textDate.firstMatch(line);
  if (m != null) {
    final mon = _months[m[2]!.toLowerCase()];
    if (mon != null) return _safeDate(int.parse(m[3]!), mon, int.parse(m[1]!));
  }
  return null;
}

DateTime? _safeDate(int y, int mo, int d) {
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  return DateTime(y, mo, d);
}

String _cleanTitle(String s) {
  var t = s;
  t = t.replaceAll(_timeRange, ' ');
  t = t.replaceAll(_isoDate, ' ').replaceAll(_dmyDate, ' ');
  t = t.replaceAll(_textDate, ' ');
  for (final name in _days.keys) {
    t = t.replaceAll(RegExp('\\b${RegExp.escape(name)}\\b', caseSensitive: false), ' ');
  }
  t = t.replaceAll(RegExp(r'\b(jam|pukul|wib|ruang|room|kelas)\b\s*:?', caseSensitive: false), ' ');
  t = t.replaceAll(RegExp(r'[|;,\t"]+'), ' ');
  t = t.replaceAll(RegExp(r'^\s*[\d.)\-–—:]+\s*'), '');
  t = t.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  t = t.replaceAll(RegExp(r'^[\-–—:]+|[\-–—:]+$'), '').trim();
  if (t.length > 60) t = t.substring(0, 60).trim();
  return t;
}

/// Ubah CSV/TSV menjadi baris yang kolomnya dipisah " | ".
String csvToLines(String text) => text
    .split(RegExp(r'\r?\n'))
    .map((l) => l.split(RegExp(r'[,;\t]')).map((c) => c.trim()).join(' | '))
    .join('\n');

List<ParsedEntry> parseScheduleText(String text) {
  final out = <ParsedEntry>[];
  final seen = <String>{};
  int? currentDay;
  DateTime? currentDate;
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final lower = line.toLowerCase();
    final day = _dayIn(lower);
    final date = _dateIn(line);
    if (date != null) {
      currentDate = date;
      currentDay = null;
    } else if (day != null) {
      currentDay = day;
      currentDate = null;
    }
    final matches = _timeRange.allMatches(line).toList();
    if (matches.isEmpty) continue;
    var title = _cleanTitle(line);
    if (title.isEmpty) title = 'Kegiatan';
    for (final m in matches) {
      final s = int.parse(m[1]!) * 60 + int.parse(m[2]!);
      final e = int.parse(m[3]!) * 60 + int.parse(m[4]!);
      if (s < 0 || e > 24 * 60 || e <= s || int.parse(m[2]!) > 59) continue;
      if (currentDate == null && currentDay == null) continue;
      final k = '$title|$currentDay|${currentDate?.toIso8601String()}|$s';
      if (!seen.add(k)) continue;
      out.add(ParsedEntry(
        title: title,
        type: guessType(title),
        startMin: s,
        endMin: e,
        weekday: currentDate == null ? currentDay : null,
        date: currentDate,
      ));
    }
  }
  return out;
}

/// Membaca file kalender .ics (ekspor Google Calendar, dll).
List<ParsedEntry> parseIcs(String text, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final lines = <String>[];
  for (final l in text.split(RegExp(r'\r?\n'))) {
    if ((l.startsWith(' ') || l.startsWith('\t')) && lines.isNotEmpty) {
      lines[lines.length - 1] += l.substring(1);
    } else {
      lines.add(l);
    }
  }
  final out = <ParsedEntry>[];
  Map<String, String>? ev;
  for (final l in lines) {
    if (l == 'BEGIN:VEVENT') {
      ev = {};
    } else if (l == 'END:VEVENT' && ev != null) {
      final e = _icsEvent(ev, today);
      if (e != null) out.add(e);
      ev = null;
    } else if (ev != null) {
      final i = l.indexOf(':');
      if (i > 0) {
        final key = l.substring(0, i).split(';').first.toUpperCase();
        ev[key] = l.substring(i + 1);
      }
    }
  }
  return out;
}

DateTime? _icsTime(String? v) {
  if (v == null) return null;
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z?)$').firstMatch(v.trim());
  if (m == null) return null;
  final parts = [for (var i = 1; i <= 6; i++) int.parse(m[i]!)];
  if (m[7] == 'Z') {
    return DateTime.utc(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5])
        .toLocal();
  }
  return DateTime(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]);
}

ParsedEntry? _icsEvent(Map<String, String> ev, DateTime today) {
  final start = _icsTime(ev['DTSTART']);
  final end = _icsTime(ev['DTEND']);
  if (start == null || end == null) return null;
  final s = minuteOfDay(start);
  final e = sameDay(start, end) ? minuteOfDay(end) : 24 * 60 - 1;
  if (e <= s) return null;
  final title = _cleanTitle((ev['SUMMARY'] ?? 'Kegiatan').replaceAll(r'\,', ','));
  final name = title.isEmpty ? 'Kegiatan' : title;
  final rrule = ev['RRULE'] ?? '';
  if (rrule.contains('FREQ=WEEKLY')) {
    final until = _icsTime(RegExp(r'UNTIL=([0-9TZ]+)').firstMatch(rrule)?[1]);
    if (until != null && until.isBefore(today)) return null;
    return ParsedEntry(
        title: name, type: guessType(name), startMin: s, endMin: e, weekday: start.weekday);
  }
  final d = dateOnly(start);
  if (d.isBefore(today) || d.isAfter(addDays(today, 56))) return null;
  return ParsedEntry(title: name, type: guessType(name), startMin: s, endMin: e, date: d);
}
