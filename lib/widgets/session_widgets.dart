import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_state.dart';
import '../models.dart';
import '../scheduler.dart';
import '../screens/forms.dart';
import '../screens/pro_screen.dart';
import '../screens/workout_player_screen.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../workouts.dart';
import 'common.dart';

void openPro(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ProScreen()));
}

/// Ringkasan hasil pindah otomatis dalam SnackBar.
void showMoveResults(BuildContext context, List<MoveResult> results) {
  if (results.isEmpty) return;
  final moved = results.where((r) => r.outcome == MoveOutcome.moved).toList();
  final locked = results.where((r) => r.outcome == MoveOutcome.locked).length;
  final noSlot = results.where((r) => r.outcome == MoveOutcome.noSlot).length;

  final lines = <String>[
    for (final r in moved)
      '${r.session.title} dipindah ke ${fmtDay(r.session.date)} '
          '${fmtMin(r.session.startMin)} (bentrok dengan ${r.agendaTitle}).',
    if (locked > 0)
      '$locked sesi bentrok. Kuota pindah otomatis gratis minggu ini habis.',
    if (noSlot > 0)
      '$noSlot sesi bentrok dan tidak ada slot kosong dalam 3 hari. Atur manual.',
  ];
  final messenger = ScaffoldMessenger.of(context);
  final nav = Navigator.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    duration: const Duration(seconds: 6),
    content: Text(lines.join('\n')),
    action: locked > 0
        ? SnackBarAction(
            label: 'Pro',
            textColor: AppColors.mint,
            onPressed: () => nav.push(
                MaterialPageRoute(builder: (_) => const ProScreen())))
        : null,
  ));
}

/// Kartu satu item di timeline (agenda abu-abu, sesi olahraga hijau).
class DayItemTile extends StatelessWidget {
  const DayItemTile({super.key, required this.item, this.showDate = false});
  final DayItem item;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final a = item.agenda;
    if (a != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          color: AppColors.softGrey,
          borderColor: AppColors.softGrey,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AgendaFormPage(existing: a))),
          child: Row(children: [
            _TimeCol(start: item.start, end: item.end, color: AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                    const SizedBox(height: 2),
                    Text(
                        '${a.type.label}${a.weekly ? ' · tiap ${hariPanjang[a.date.weekday - 1]}' : ''}',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.muted)),
                  ]),
            ),
            const Icon(Icons.edit_outlined, size: 18, color: AppColors.muted),
          ]),
        ),
      );
    }
    return SessionTile(session: item.session!, showDate: showDate);
  }
}

class SessionTile extends StatelessWidget {
  const SessionTile({super.key, required this.session, this.showDate = false});
  final Session session;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final done = s.status == SessionStatus.done;
    final skipped = s.status == SessionStatus.skipped;
    final conflict = s.needsMove && s.status == SessionStatus.planned;
    final Color border = conflict
        ? AppColors.orange
        : done
            ? AppColors.green
            : AppColors.line;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        borderColor: border,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => showSessionActions(context, s),
        child: Row(children: [
          _TimeCol(
              start: s.startMin,
              end: s.endMin,
              color: conflict ? AppColors.orangeDark : AppColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          decoration:
                              skipped ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 2),
                  Text(
                      '${showDate ? '${fmtDay(s.date)} · ' : ''}${fmtDuration(s.durationMin)}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.muted)),
                  if (s.auto || s.wasMoved || conflict || done || skipped) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if (conflict)
                        const Pill('Bentrok',
                            fg: AppColors.orangeDark,
                            bg: AppColors.softOrange,
                            icon: Icons.warning_amber_rounded),
                      if (s.auto)
                        const Pill('Disusun otomatis',
                            fg: AppColors.muted,
                            bg: AppColors.softGrey,
                            icon: Icons.auto_awesome),
                      if (s.wasMoved)
                        Pill(
                            'Dipindah dari ${fmtDay(s.originalDate!)} ${fmtMin(s.originalStartMin!)}',
                            icon: Icons.swap_horiz),
                      if (done)
                        const Pill('Selesai', icon: Icons.check_circle),
                      if (skipped)
                        const Pill('Dilewati',
                            fg: AppColors.muted, bg: AppColors.softGrey),
                    ]),
                  ],
                ]),
          ),
          Icon(
              done
                  ? Icons.check_circle
                  : s.workoutId != null
                      ? Icons.play_circle_fill
                      : Icons.directions_run_rounded,
              color: done ? AppColors.green : AppColors.navy),
        ]),
      ),
    );
  }
}

class _TimeCol extends StatelessWidget {
  const _TimeCol(
      {required this.start, required this.end, required this.color});
  final int start;
  final int end;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(fmtMin(start),
            style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        Text(fmtMin(end),
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]),
    );
  }
}

/// Kartu peringatan bentrok di Beranda.
class ConflictCard extends StatelessWidget {
  const ConflictCard({super.key, required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final agenda = Scheduler.conflictingAgenda(session, st.agendas);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        color: const Color(0xFFFFF6EE),
        borderColor: AppColors.orange,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.orangeDark),
            SizedBox(width: 8),
            Text('Jadwal bentrok',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.orangeDark)),
          ]),
          const SizedBox(height: 6),
          Text(
            '${session.title} (${fmtDay(session.date)}, ${fmtRange(session.startMin, session.endMin)}) '
            'bertabrakan dengan ${agenda?.title ?? 'agenda lain'}.',
            style: const TextStyle(height: 1.4, color: AppColors.navy),
          ),
          if (!st.canAutoMove) ...[
            const SizedBox(height: 6),
            const Text(
                'Kuota pindah otomatis gratis minggu ini sudah habis. Pindahkan manual atau aktifkan Pro.',
                style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: st.canAutoMove
                  ? FilledButton.icon(
                      onPressed: () {
                        final r = AppScope.read(context).autoMoveOne(session);
                        if (r != null) showMoveResults(context, [r]);
                      },
                      icon: const Icon(Icons.auto_fix_high, size: 18),
                      label: const Text('Pindah otomatis'),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy),
                      onPressed: () => openPro(context),
                      icon: const Icon(Icons.workspace_premium, size: 18),
                      label: const Text('Buka Pro'),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => showManualMove(context, session),
                child: const Text('Pilih manual'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Bottom sheet aksi untuk satu sesi olahraga.
Future<void> showSessionActions(BuildContext context, Session s) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetCtx) {
      final st = AppScope.read(context);
      final conflict = s.needsMove && s.status == SessionStatus.planned;
      void close() => Navigator.of(sheetCtx).pop();
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy)),
                const SizedBox(height: 4),
                Text(
                    '${fmtDayLong(s.date)} · ${fmtRange(s.startMin, s.endMin)}',
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                if (s.workoutId != null && workoutById(s.workoutId) != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_fill,
                        color: AppColors.green),
                    title: const Text('Putar video latihan'),
                    subtitle: Text(
                        '${workoutById(s.workoutId)!.minutes} menit · ${workoutById(s.workoutId)!.level.label}'),
                    onTap: () {
                      close();
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => WorkoutPlayerScreen(
                              workout: workoutById(s.workoutId)!)));
                    },
                  ),
                if (s.status == SessionStatus.planned) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline,
                        color: AppColors.green),
                    title: const Text('Tandai selesai'),
                    onTap: () {
                      st.setStatus(s, SessionStatus.done);
                      close();
                    },
                  ),
                  if (conflict)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.auto_fix_high,
                          color: AppColors.green),
                      title: const Text('Pindah otomatis ke slot kosong'),
                      subtitle: Text(st.isPro
                          ? 'Pro: tanpa batas'
                          : 'Gratis: sisa ${st.freeMovesLeft}x minggu ini'),
                      trailing: st.canAutoMove
                          ? null
                          : const Pill('Pro',
                              fg: Colors.white, bg: AppColors.navy),
                      onTap: () {
                        close();
                        if (!st.canAutoMove) {
                          openPro(context);
                          return;
                        }
                        final r = st.autoMoveOne(s);
                        if (r != null) showMoveResults(context, [r]);
                      },
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_repeat,
                        color: AppColors.navy),
                    title: const Text('Pilih jadwal lain (manual)'),
                    onTap: () {
                      close();
                      showManualMove(context, s);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.not_interested, color: AppColors.muted),
                    title: const Text('Lewati sesi ini'),
                    onTap: () {
                      st.setStatus(s, SessionStatus.skipped);
                      close();
                    },
                  ),
                ] else
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.undo, color: AppColors.navy),
                    title: const Text('Kembalikan ke rencana'),
                    onTap: () {
                      st.setStatus(s, SessionStatus.planned);
                      close();
                    },
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: AppColors.red),
                  title: const Text('Hapus sesi',
                      style: TextStyle(color: AppColors.red)),
                  onTap: () {
                    st.deleteSession(s);
                    close();
                  },
                ),
              ]),
        ),
      );
    },
  );
}

/// Pilih slot saran atau tanggal & jam sendiri (tidak memakai kuota).
Future<void> showManualMove(BuildContext context, Session s) {
  final st = AppScope.read(context);
  final slots =
      Scheduler.suggestSlots(s, st.agendas, st.sessions, now: st.clock())
          .where((x) => !(sameDay(x.date, s.date) && x.startMin == s.startMin))
          .toList();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pindahkan ke slot kosong',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy)),
              const SizedBox(height: 4),
              Text(
                  '${s.title} · ${fmtDuration(s.durationMin)} · jeda 15 menit dari agenda lain',
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
              if (slots.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Belum ada slot kosong dalam 4 hari ke depan.',
                      style: TextStyle(color: AppColors.muted)),
                ),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final slot in slots)
                  ActionChip(
                    avatar: const Icon(Icons.schedule,
                        size: 16, color: AppColors.green),
                    label: Text(
                        '${fmtDay(slot.date)} · ${fmtRange(slot.startMin, slot.startMin + s.durationMin)}'),
                    onPressed: () {
                      st.moveManual(s, slot.date, slot.startMin);
                      Navigator.of(sheetCtx).pop();
                    },
                  ),
              ]),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(sheetCtx).pop();
                  await _pickCustom(context, s);
                },
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Pilih tanggal & jam sendiri'),
              ),
            ]),
      ),
    ),
  );
}

Future<void> _pickCustom(BuildContext context, Session s) async {
  final st = AppScope.read(context);
  final today = dateOnly(st.clock());
  final date = await showDatePicker(
    context: context,
    initialDate: s.date.isBefore(today) ? today : s.date,
    firstDate: today,
    lastDate: addDays(today, 180),
  );
  if (date == null || !context.mounted) return;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: s.startMin ~/ 60, minute: s.startMin % 60),
  );
  if (time == null || !context.mounted) return;
  final start = time.hour * 60 + time.minute;
  final clash =
      Scheduler.conflictingAgendaAt(date, start, s.durationMin, st.agendas);
  if (clash != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Jam itu bentrok dengan ${clash.title} (${fmtRange(clash.startMin, clash.endMin)}). Pilih jam lain.')));
    return;
  }
  st.moveManual(s, date, start);
}
