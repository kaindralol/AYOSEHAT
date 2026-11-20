import 'models.dart';
import 'utils/format.dart';

/// Rentang waktu sibuk dalam satu hari (menit sejak 00.00).
class Block {
  const Block(this.start, this.end, this.label);
  final int start;
  final int end;
  final String label;
}

/// Kandidat jadwal baru untuk sebuah sesi.
class Slot {
  const Slot(this.date, this.startMin);
  final DateTime date;
  final int startMin;
}

/// Logika inti AYOSEHAT: mencari slot kosong terdekat saat sesi olahraga
/// bentrok dengan agenda kuliah, organisasi, atau tugas.
class Scheduler {
  /// Jam paling pagi & paling malam sesi olahraga boleh dijadwalkan.
  static const int dayStart = 5 * 60 + 30; // 05.30
  static const int dayEnd = 21 * 60 + 30; // 21.30

  /// Kelipatan waktu yang dicoba (15 menit).
  static const int step = 15;

  /// Jeda minimal antara sesi olahraga dan agenda lain.
  static const int buffer = 15;

  /// Berapa hari ke depan (selain hari sesi itu sendiri) boleh dipakai.
  static const int maxDaysAhead = 2;

  static bool overlaps(int aStart, int aEnd, int bStart, int bEnd) =>
      aStart < bEnd && bStart < aEnd;

  static List<Block> busyBlocks(
    DateTime day,
    List<Agenda> agendas,
    List<Session> sessions, {
    String? excludeSessionId,
  }) {
    return [
      for (final a in agendas)
        if (a.occursOn(day)) Block(a.startMin, a.endMin, a.title),
      for (final s in sessions)
        if (s.id != excludeSessionId &&
            s.status != SessionStatus.skipped &&
            sameDay(s.date, day))
          Block(s.startMin, s.endMin, s.title),
    ];
  }

  /// Agenda yang bertabrakan langsung dengan sesi (tanpa jeda), atau null.
  static Agenda? conflictingAgenda(Session s, List<Agenda> agendas) {
    return conflictingAgendaAt(s.date, s.startMin, s.durationMin, agendas);
  }

  static Agenda? conflictingAgendaAt(
      DateTime day, int start, int duration, List<Agenda> agendas) {
    for (final a in agendas) {
      if (a.occursOn(day) &&
          overlaps(start, start + duration, a.startMin, a.endMin)) {
        return a;
      }
    }
    return null;
  }

  static bool isFree(int start, int duration, List<Block> blocks) {
    if (start < dayStart || start + duration > dayEnd) return false;
    for (final b in blocks) {
      if (overlaps(start - buffer, start + duration + buffer, b.start, b.end)) {
        return false;
      }
    }
    return true;
  }

  static List<Slot> freeSlotsOnDay(
    DateTime day,
    int duration,
    List<Block> blocks, {
    required int minStart,
  }) {
    var t = minStart < dayStart ? dayStart : minStart;
    if (t % step != 0) t += step - t % step;
    final result = <Slot>[];
    for (; t + duration <= dayEnd; t += step) {
      if (isFree(t, duration, blocks)) result.add(Slot(dateOnly(day), t));
    }
    return result;
  }

  static List<Slot> _rankedSlotsForDay(
    Session s,
    DateTime day,
    List<Agenda> agendas,
    List<Session> sessions,
    DateTime now,
  ) {
    if (dateOnly(day).isBefore(dateOnly(now))) return [];
    final blocks =
        busyBlocks(day, agendas, sessions, excludeSessionId: s.id);
    final minStart = sameDay(day, now) ? minuteOfDay(now) + step : dayStart;
    final free =
        freeSlotsOnDay(day, s.durationMin, blocks, minStart: minStart);
    final preferred = s.startMin;
    free.sort((a, b) {
      final da = (a.startMin - preferred).abs();
      final db = (b.startMin - preferred).abs();
      if (da != db) return da.compareTo(db);
      // Jarak sama: utamakan yang lebih sore (setelah agenda selesai).
      return b.startMin.compareTo(a.startMin);
    });
    return free;
  }

  /// Slot terbaik: hari yang sama dulu, sedekat mungkin dengan jam semula.
  /// Kalau penuh, coba hari berikutnya (maksimal [maxDaysAhead] hari).
  static Slot? findSlot(
    Session s,
    List<Agenda> agendas,
    List<Session> sessions, {
    required DateTime now,
  }) {
    for (var d = 0; d <= maxDaysAhead; d++) {
      final day = addDays(s.date, d);
      final ranked = _rankedSlotsForDay(s, day, agendas, sessions, now);
      if (ranked.isNotEmpty) return ranked.first;
    }
    return null;
  }

  /// Beberapa pilihan slot untuk dipilih manual (maks. 2 per hari).
  static List<Slot> suggestSlots(
    Session s,
    List<Agenda> agendas,
    List<Session> sessions, {
    required DateTime now,
    int count = 6,
  }) {
    final result = <Slot>[];
    for (var d = 0; d <= maxDaysAhead + 1 && result.length < count; d++) {
      final day = addDays(s.date, d);
      final ranked = _rankedSlotsForDay(s, day, agendas, sessions, now);
      result.addAll(ranked.take(2));
    }
    return result.take(count).toList();
  }
}
