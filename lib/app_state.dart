import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'scheduler.dart';
import 'utils/format.dart';

enum MoveOutcome { moved, noSlot, locked }

/// Hasil percobaan memindahkan satu sesi yang bentrok.
class MoveResult {
  MoveResult(this.session, this.outcome,
      {this.fromDate, this.fromMin, this.agendaTitle});
  final Session session;
  final MoveOutcome outcome;
  final DateTime? fromDate;
  final int? fromMin;
  final String? agendaTitle;
}

class WeekStats {
  const WeekStats(
      {required this.planned, required this.done, required this.moved});
  final int planned;
  final int done;
  final int moved;
}

/// Seluruh data & aturan bisnis AYOSEHAT. Disimpan lokal di HP.
class AppState extends ChangeNotifier {
  AppState({DateTime Function()? clock, this.persist = true})
      : clock = clock ?? DateTime.now;

  // ---- Aturan langganan (Startup Sustainability Blueprint v1) ----
  static const int trialDays = 14;
  static const int priceSemester = 35000; // Rp35.000 per semester
  static const int semesterDays = 182; // berlaku ±6 bulan
  static const int freeMovesPerWeek = 2; // pindah otomatis gratis / minggu

  static const String _storageKey = 'ayosehat_state_v1';

  final DateTime Function() clock;
  final bool persist;

  final List<Agenda> agendas = [];
  final List<Session> sessions = [];

  /// Semua pemindahan otomatis (untuk statistik).
  final List<DateTime> moveLog = [];

  /// Pemindahan otomatis yang memakai kuota gratis.
  final List<DateTime> freeMoveLog = [];

  DateTime? trialStart;
  DateTime? proUntil;

  // ---------------- Langganan ----------------
  bool get isTrialActive =>
      trialStart != null &&
      clock().isBefore(trialStart!.add(const Duration(days: trialDays)));

  bool get trialUsed => trialStart != null;

  int get trialDaysLeft {
    if (!isTrialActive) return 0;
    final end = trialStart!.add(const Duration(days: trialDays));
    return (end.difference(clock()).inHours / 24).ceil();
  }

  bool get isPaidPro => proUntil != null && clock().isBefore(proUntil!);

  bool get isPro => isPaidPro || isTrialActive;

  bool get trialExpired => trialUsed && !isTrialActive && !isPaidPro;

  int get freeMovesUsedThisWeek {
    final monday = startOfWeek(clock());
    return freeMoveLog.where((d) => !d.isBefore(monday)).length;
  }

  int get freeMovesLeft => max(0, freeMovesPerWeek - freeMovesUsedThisWeek);

  bool get canAutoMove => isPro || freeMovesLeft > 0;

  void startTrial() {
    if (trialUsed) return;
    trialStart = clock();
    _commit();
  }

  /// Mode demo: belum terhubung ke payment gateway sungguhan.
  void activateProDemo() {
    proUntil = clock().add(const Duration(days: semesterDays));
    _commit();
  }

  void cancelProDemo() {
    proUntil = null;
    _commit();
  }

  // ---------------- Query ----------------
  List<DayItem> itemsOn(DateTime day) {
    final items = <DayItem>[
      for (final a in agendas)
        if (a.occursOn(day)) DayItem.agenda(a),
      for (final s in sessions)
        if (sameDay(s.date, day)) DayItem.session(s),
    ];
    items.sort((a, b) => a.start.compareTo(b.start));
    return items;
  }

  List<Session> get conflicts {
    final today = dateOnly(clock());
    final list = sessions
        .where((s) =>
            s.needsMove &&
            s.status == SessionStatus.planned &&
            !s.date.isBefore(today))
        .toList();
    list.sort(_bySchedule);
    return list;
  }

  List<Session> upcomingSessions({int days = 3}) {
    final today = dateOnly(clock());
    final last = addDays(today, days);
    final list = sessions
        .where((s) =>
            s.status == SessionStatus.planned &&
            s.date.isAfter(today) &&
            !s.date.isAfter(last))
        .toList();
    list.sort(_bySchedule);
    return list;
  }

  WeekStats weekStats() {
    final monday = startOfWeek(clock());
    final nextMonday = addDays(monday, 7);
    bool inWeek(DateTime d) => !d.isBefore(monday) && d.isBefore(nextMonday);
    final week = sessions.where((s) => inWeek(s.date)).toList();
    return WeekStats(
      planned: week.where((s) => s.status != SessionStatus.skipped).length,
      done: week.where((s) => s.status == SessionStatus.done).length,
      moved: moveLog.where(inWeek).length,
    );
  }

  static int _bySchedule(Session a, Session b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : a.startMin.compareTo(b.startMin);
  }

  bool _isPast(Session s) {
    final now = clock();
    final today = dateOnly(now);
    if (s.date.isBefore(today)) return true;
    return sameDay(s.date, today) && s.endMin <= minuteOfDay(now);
  }

  // ---------------- Inti: pindah otomatis ----------------
  MoveResult? _tryResolve(Session s) {
    if (s.status != SessionStatus.planned || _isPast(s)) {
      s.needsMove = false;
      return null;
    }
    final agenda = Scheduler.conflictingAgenda(s, agendas);
    if (agenda == null) {
      s.needsMove = false;
      return null;
    }
    if (!canAutoMove) {
      s.needsMove = true;
      return MoveResult(s, MoveOutcome.locked, agendaTitle: agenda.title);
    }
    final slot = Scheduler.findSlot(s, agendas, sessions, now: clock());
    if (slot == null) {
      s.needsMove = true;
      return MoveResult(s, MoveOutcome.noSlot, agendaTitle: agenda.title);
    }
    final fromDate = s.date;
    final fromMin = s.startMin;
    s.originalDate ??= s.date;
    s.originalStartMin ??= s.startMin;
    s.date = slot.date;
    s.startMin = slot.startMin;
    s.moveCount++;
    s.needsMove = false;
    final now = clock();
    moveLog.add(now);
    if (!isPro) freeMoveLog.add(now);
    return MoveResult(s, MoveOutcome.moved,
        fromDate: fromDate, fromMin: fromMin, agendaTitle: agenda.title);
  }

  /// Dipanggil setiap agenda berubah: semua sesi yang bentrok dicoba
  /// dipindah ke slot kosong terdekat.
  List<MoveResult> resolveConflicts() {
    final list = sessions.toList()..sort(_bySchedule);
    final results = <MoveResult>[];
    for (final s in list) {
      final r = _tryResolve(s);
      if (r != null) results.add(r);
    }
    _commit();
    return results;
  }

  MoveResult? autoMoveOne(Session s) {
    final r = _tryResolve(s);
    _commit();
    return r;
  }

  /// Tandai bentrok tanpa memindahkan (dipakai saat sesi baru dibuat).
  void _flagConflicts() {
    for (final s in sessions) {
      s.needsMove = s.status == SessionStatus.planned &&
          !_isPast(s) &&
          Scheduler.conflictingAgenda(s, agendas) != null;
    }
  }

  // ---------------- Agenda ----------------
  List<MoveResult> addAgenda(Agenda a) {
    agendas.add(a);
    return resolveConflicts();
  }

  List<MoveResult> updateAgenda(
    Agenda a, {
    required String title,
    required AgendaType type,
    required DateTime date,
    required int startMin,
    required int endMin,
    required bool weekly,
  }) {
    a
      ..title = title
      ..type = type
      ..date = dateOnly(date)
      ..startMin = startMin
      ..endMin = endMin
      ..weekly = weekly;
    return resolveConflicts();
  }

  void deleteAgenda(Agenda a) {
    agendas.removeWhere((x) => x.id == a.id);
    _flagConflicts();
    _commit();
  }

  // ---------------- Sesi ----------------
  void addSessions({
    required String title,
    required DateTime date,
    required int startMin,
    required int durationMin,
    int repeatWeeks = 1,
  }) {
    for (var i = 0; i < repeatWeeks; i++) {
      sessions.add(Session(
        id: newId(),
        title: title,
        date: addDays(date, 7 * i),
        startMin: startMin,
        durationMin: durationMin,
      ));
    }
    _flagConflicts();
    _commit();
  }

  /// Pindah manual tidak memakai kuota.
  void moveManual(Session s, DateTime date, int startMin) {
    s.date = dateOnly(date);
    s.startMin = startMin;
    s.needsMove = Scheduler.conflictingAgenda(s, agendas) != null;
    _commit();
  }

  void setStatus(Session s, SessionStatus status) {
    s.status = status;
    if (status != SessionStatus.planned) s.needsMove = false;
    _commit();
  }

  void deleteSession(Session s) {
    sessions.removeWhere((x) => x.id == s.id);
    _commit();
  }

  // ---------------- Demo & reset ----------------
  /// Isi contoh jadwal maba yang aktif berkegiatan.
  void seedDemo() {
    agendas.clear();
    sessions.clear();
    moveLog.clear();
    freeMoveLog.clear();
    final monday = startOfWeek(clock());
    Agenda weekly(String t, AgendaType type, int dayIdx, int s, int e) =>
        Agenda(
          id: newId(),
          title: t,
          type: type,
          date: addDays(monday, dayIdx),
          startMin: s,
          endMin: e,
          weekly: true,
        );
    agendas.addAll([
      weekly('Kalkulus', AgendaType.kuliah, 0, 7 * 60, 9 * 60 + 30),
      weekly('Pemrograman Dasar', AgendaType.kuliah, 1, 10 * 60, 12 * 60 + 30),
      weekly('Fisika Dasar', AgendaType.kuliah, 2, 13 * 60, 15 * 60 + 30),
      weekly('Rapat himpunan', AgendaType.organisasi, 2, 18 * 60 + 30,
          20 * 60 + 30),
      weekly('Kimia Dasar', AgendaType.kuliah, 3, 7 * 60, 9 * 60 + 30),
      weekly('Praktikum', AgendaType.kuliah, 4, 13 * 60, 16 * 60),
    ]);
    for (var w = 0; w < 2; w++) {
      final base = addDays(monday, 7 * w);
      sessions.addAll([
        Session(
            id: newId(),
            title: 'Lari pagi',
            date: addDays(base, 1),
            startMin: 6 * 60,
            durationMin: 30),
        Session(
            id: newId(),
            title: 'Badminton',
            date: addDays(base, 2),
            startMin: 16 * 60,
            durationMin: 60),
        Session(
            id: newId(),
            title: 'Latihan 15 menit di kos',
            date: addDays(base, 3),
            startMin: 20 * 60,
            durationMin: 15),
        Session(
            id: newId(),
            title: 'Jogging sore',
            date: addDays(base, 4),
            startMin: 16 * 60 + 30,
            durationMin: 45),
      ]);
    }
    _flagConflicts();
    _commit();
  }

  /// Demo presentasi: muncul agenda mendadak yang menabrak sesi berikutnya.
  List<MoveResult> simulateSuddenAgenda() {
    final now = clock();
    final next = sessions
        .where((s) => s.status == SessionStatus.planned && !_isPast(s))
        .toList()
      ..sort(_bySchedule);
    if (next.isEmpty) return [];
    final target = next.first;
    final start = max(Scheduler.dayStart, target.startMin - 30);
    final end = min(23 * 60 + 45, target.endMin + 15);
    final date = sameDay(target.date, now) ? now : target.date;
    return addAgenda(Agenda(
      id: newId(),
      title: 'Rapat panitia mendadak',
      type: AgendaType.organisasi,
      date: date,
      startMin: start,
      endMin: end,
    ));
  }

  void resetAll() {
    agendas.clear();
    sessions.clear();
    moveLog.clear();
    freeMoveLog.clear();
    trialStart = null;
    proUntil = null;
    _commit();
  }

  // ---------------- Penyimpanan ----------------
  void _commit() {
    notifyListeners();
    if (persist) save();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'agendas': agendas.map((a) => a.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'moveLog': moveLog.map((d) => d.toIso8601String()).toList(),
      'freeMoveLog': freeMoveLog.map((d) => d.toIso8601String()).toList(),
      'trialStart': trialStart?.toIso8601String(),
      'proUntil': proUntil?.toIso8601String(),
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      agendas
        ..clear()
        ..addAll((data['agendas'] as List)
            .map((e) => Agenda.fromJson(e as Map<String, dynamic>)));
      sessions
        ..clear()
        ..addAll((data['sessions'] as List)
            .map((e) => Session.fromJson(e as Map<String, dynamic>)));
      moveLog
        ..clear()
        ..addAll((data['moveLog'] as List? ?? [])
            .map((e) => DateTime.parse(e as String)));
      freeMoveLog
        ..clear()
        ..addAll((data['freeMoveLog'] as List? ?? [])
            .map((e) => DateTime.parse(e as String)));
      trialStart = data['trialStart'] == null
          ? null
          : DateTime.parse(data['trialStart'] as String);
      proUntil = data['proUntil'] == null
          ? null
          : DateTime.parse(data['proUntil'] as String);
      _flagConflicts();
    } catch (e) {
      debugPrint('Gagal membaca data AYOSEHAT: $e');
    }
    notifyListeners();
  }
}
