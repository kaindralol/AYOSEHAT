import 'package:flutter_test/flutter_test.dart';

import 'package:ayosehat/app_state.dart';
import 'package:ayosehat/models.dart';
import 'package:ayosehat/scheduler.dart';

/// Tes logika inti tanpa UI: pindah otomatis, kuota gratis, dan trial.
void main() {
  // Rabu, 18 Nov 2026 pukul 07.00; sesi diuji pada Jumat, 20 Nov
  final now = DateTime(2026, 11, 18, 7, 0);
  final friday = DateTime(2026, 11, 20);

  AppState fresh() => AppState(clock: () => now, persist: false);

  Agenda agenda(String title, int start, int end) => Agenda(
        id: title,
        title: title,
        type: AgendaType.organisasi,
        date: friday,
        startMin: start,
        endMin: end,
      );

  test('sesi yang bentrok dipindah ke slot kosong terdekat', () {
    final st = fresh();
    st.addSessions(
        title: 'Badminton',
        date: friday,
        startMin: 16 * 60,
        durationMin: 60);
    final results = st.addAgenda(agenda('Rapat mendadak', 15 * 60 + 30, 17 * 60));

    expect(results.single.outcome, MoveOutcome.moved);
    final s = st.sessions.single;
    expect(Scheduler.conflictingAgenda(s, st.agendas), isNull);
    // Ada jeda minimal 15 menit dari rapat.
    final clearOfMeeting =
        s.endMin <= 15 * 60 + 15 || s.startMin >= 17 * 60 + 15;
    expect(clearOfMeeting, isTrue);
    expect(s.wasMoved, isTrue);
  });

  test('paket gratis hanya 2x pindah otomatis per minggu', () {
    final st = fresh();
    for (final h in [8, 11, 14]) {
      st.addSessions(
          title: 'Sesi $h', date: friday, startMin: h * 60, durationMin: 30);
    }
    final results = st.addAgenda(agenda('Acara seharian', 7 * 60, 15 * 60));

    expect(results.where((r) => r.outcome == MoveOutcome.moved).length, 2);
    expect(results.where((r) => r.outcome == MoveOutcome.locked).length, 1);
    expect(st.freeMovesLeft, 0);
    expect(st.conflicts.length, 1);
  });

  test('trial Pro membuat pindah otomatis tanpa batas', () {
    final st = fresh()..startTrial();
    expect(st.isPro, isTrue);
    expect(st.trialDaysLeft, AppState.trialDays);
    for (final h in [8, 11, 14]) {
      st.addSessions(
          title: 'Sesi $h', date: friday, startMin: h * 60, durationMin: 30);
    }
    final results = st.addAgenda(agenda('Acara seharian', 7 * 60, 15 * 60));
    expect(results.every((r) => r.outcome == MoveOutcome.moved), isTrue);
  });

  test('trial berakhir setelah 14 hari', () {
    var clock = now;
    final st = AppState(clock: () => clock, persist: false)..startTrial();
    clock = now.add(const Duration(days: 15));
    expect(st.isTrialActive, isFalse);
    expect(st.trialExpired, isTrue);
    expect(st.isPro, isFalse);
  });
}
