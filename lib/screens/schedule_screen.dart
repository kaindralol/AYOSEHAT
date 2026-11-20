import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/session_widgets.dart';
import 'forms.dart';

/// Jadwal mingguan: agenda + sesi olahraga per hari.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final now = st.clock();
    final monday = addDays(startOfWeek(now), 7 * _weekOffset);
    final sunday = addDays(monday, 6);
    final label = _weekOffset == 0
        ? 'Minggu ini'
        : _weekOffset == 1
            ? 'Minggu depan'
            : _weekOffset == -1
                ? 'Minggu lalu'
                : '${monday.day} ${bulanPendek[monday.month - 1]} – ${sunday.day} ${bulanPendek[sunday.month - 1]}';

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal')),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(children: [
              IconButton(
                tooltip: 'Minggu sebelumnya',
                onPressed: () => setState(() => _weekOffset--),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Column(children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy)),
                  Text(
                      '${fmtDay(monday)} – ${fmtDay(sunday)}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.muted)),
                ]),
              ),
              IconButton(
                tooltip: 'Minggu berikutnya',
                onPressed: () => setState(() => _weekOffset++),
                icon: const Icon(Icons.chevron_right),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              children: [
                for (var i = 0; i < 7; i++) ...[
                  _DayHeader(
                      date: addDays(monday, i),
                      isToday: sameDay(addDays(monday, i), now)),
                  ...() {
                    final items = st.itemsOn(addDays(monday, i));
                    if (items.isEmpty) {
                      return [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('Kosong',
                              style: TextStyle(color: AppColors.muted)),
                        )
                      ];
                    }
                    return [for (final it in items) DayItemTile(item: it)];
                  }(),
                ],
              ],
            ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah',
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        onPressed: () => showAddChooser(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.isToday});
  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(children: [
        Text(fmtDayLong(date),
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.navy)),
        if (isToday) ...[
          const SizedBox(width: 8),
          const Pill('Hari ini'),
        ],
      ]),
    );
  }
}
