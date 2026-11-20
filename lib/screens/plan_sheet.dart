import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models.dart';
import '../theme.dart';

/// Atur preferensi latihan, lalu susun jadwal latihan di waktu kosong.
Future<void> showPlanSheet(BuildContext context, {String? lead}) {
  final st = AppScope.read(context);
  final cur = st.plan;
  final p = PlanPrefs(
    perWeek: cur?.perWeek ?? 3,
    level: cur?.level ?? 'sedang',
    minutes: cur?.minutes ?? 30,
    time: cur?.time ?? PreferredTime.sore,
  );
  final messenger = ScaffoldMessenger.of(context);

  Widget label(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.navy)),
      );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setS) {
        Widget chips<T>(List<(T, String)> opts, T value, void Function(T) on) =>
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final o in opts)
                ChoiceChip(
                  label: Text(o.$2),
                  selected: o.$1 == value,
                  onSelected: (_) => setS(() => on(o.$1)),
                ),
            ]);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Susun latihan otomatis',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy)),
                  const SizedBox(height: 4),
                  Text(
                    '${lead != null ? '$lead ' : ''}AYOSEHAT mencari waktu kosong di antara kegiatanmu untuk 4 minggu ke depan, dengan jeda 15 menit dari kegiatan lain.',
                    style: const TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  label('Berapa kali seminggu?'),
                  chips<int>([(2, '2x'), (3, '3x'), (4, '4x'), (5, '5x')],
                      p.perWeek, (v) => p.perWeek = v),
                  label('Level latihan'),
                  chips<String>(
                      [('ringan', 'Ringan'), ('sedang', 'Sedang'), ('berat', 'Berat')],
                      p.level,
                      (v) => p.level = v),
                  label('Durasi'),
                  chips<int>([(15, '15 menit'), (30, '30 menit')], p.minutes,
                      (v) => p.minutes = v),
                  label('Waktu favorit'),
                  chips<PreferredTime>(
                      [for (final t in PreferredTime.values) (t, t.label)],
                      p.time,
                      (v) => p.time = v),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final r = st.planWorkouts(p);
                        st.resolveConflicts();
                        Navigator.of(sheetCtx).pop();
                        messenger.showSnackBar(SnackBar(
                            content: Text(
                                '${r.made} sesi latihan disusun di waktu yang kosong.'
                                '${r.short > 0 ? ' ${r.short} sesi tidak muat karena jadwal penuh.' : ''}')));
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Susun jadwal latihan'),
                    ),
                  ),
                ]),
          ),
        );
      },
    ),
  );
}
