import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_state.dart';
import '../models.dart';
import '../schedule_import.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/session_widgets.dart';
import 'forms.dart';
import 'import_preview_screen.dart';
import 'plan_sheet.dart';

/// Jadwal: unggah file jadwal kegiatan, latihan otomatis, dan tampilan mingguan.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _weekOffset = 0;
  bool _reading = false;

  Future<void> _upload() async {
    setState(() => _reading = true);
    ImportResult? res;
    try {
      res = await pickAndReadSchedule();
    } finally {
      if (mounted) setState(() => _reading = false);
    }
    if (res == null || !mounted) return;
    if (res.error != null) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Jadwal belum terbaca'),
          content: Text(
              '${res!.error}\n\nTips: pastikan setiap kegiatan punya hari dan jam, misalnya "Senin 07.00-09.30 Kalkulus". '
              'Format yang didukung: PDF, foto/screenshot (JPG, PNG), Excel (.xlsx), CSV, TXT, dan kalender (.ics).'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c), child: const Text('Tutup')),
          ],
        ),
      );
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ImportPreviewScreen(result: res!)));
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus semua jadwal?'),
        content: const Text(
            'Semua file jadwal, agenda kegiatan, dan sesi latihan akan dihapus. Status trial/Pro tetap ada.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Hapus semua',
                  style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok == true && mounted) {
      AppScope.read(context).clearAllSchedules();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua jadwal sudah dihapus.')));
    }
  }

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
                : '${fmtDay(monday)} – ${fmtDay(sunday)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          children: [
            _UploadSlot(reading: _reading, onTap: _reading ? null : _upload),
            if (st.uploads.isNotEmpty) ...[
              const SizedBox(height: 16),
              const SectionTitle('Jadwal yang diunggah'),
              const SizedBox(height: 8),
              for (final u in st.uploads) _UploadTile(upload: u),
            ],
            const SizedBox(height: 12),
            _PlanCard(st: st),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
              onPressed: (st.agendas.isEmpty && st.sessions.isEmpty)
                  ? null
                  : _confirmClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Hapus semua jadwal'),
            ),
            const SizedBox(height: 18),
            Row(children: [
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
                  Text('${fmtDay(monday)} – ${fmtDay(sunday)}',
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
            for (var i = 0; i < 7; i++) ...[
              _DayHeader(
                  date: addDays(monday, i),
                  isToday: sameDay(addDays(monday, i), now)),
              ..._dayItems(st, addDays(monday, i)),
            ],
          ],
        ),
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

  List<Widget> _dayItems(AppState st, DateTime day) {
    final items = st.itemsOn(day);
    if (items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Kosong', style: TextStyle(color: AppColors.muted)),
        ),
      ];
    }
    return [for (final it in items) DayItemTile(item: it)];
  }
}

/// Slot untuk mengunggah file jadwal kegiatan.
class _UploadSlot extends StatelessWidget {
  const _UploadSlot({required this.reading, required this.onTap});
  final bool reading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.green, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Column(children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                  color: AppColors.softGreen, shape: BoxShape.circle),
              child: reading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.upload_file,
                      color: AppColors.green, size: 28),
            ),
            const SizedBox(height: 10),
            Text(reading ? 'Membaca jadwal…' : 'Unggah file jadwal kegiatan',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy)),
            const SizedBox(height: 4),
            const Text(
              'PDF, foto/screenshot jadwal, Excel, CSV, TXT, atau kalender (.ics). '
              'AYOSEHAT membaca hari & jamnya, lalu menyusun latihan di waktu yang kosong.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Satu file jadwal yang sudah diunggah + pilihan seterusnya / seminggu saja.
class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.upload});
  final UploadedSchedule upload;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final u = upload;
    final weekly = u.mode == UploadMode.seterusnya;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.description_outlined, color: AppColors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy)),
                    Text(
                        '${u.count} kegiatan · diunggah ${fmtDay(u.uploadedAt)}',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.muted)),
                  ]),
            ),
            IconButton(
              tooltip: 'Hapus file jadwal ini',
              icon: const Icon(Icons.close, color: AppColors.muted),
              onPressed: () => st.deleteUpload(u),
            ),
          ]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<UploadMode>(
              segments: const [
                ButtonSegment(
                    value: UploadMode.seterusnya,
                    icon: Icon(Icons.all_inclusive, size: 18),
                    label: Text('Gunakan seterusnya')),
                ButtonSegment(
                    value: UploadMode.semingguSaja,
                    icon: Icon(Icons.date_range, size: 18),
                    label: Text('Seminggu saja')),
              ],
              selected: {u.mode},
              showSelectedIcon: false,
              onSelectionChanged: (sel) => st.setUploadMode(u, sel.first),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            weekly
                ? 'Kegiatan rutin berulang setiap minggu.'
                : 'Hanya berlaku sampai ${fmtDayLong(u.weekEnd)}.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ]),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.st});
  final AppState st;

  @override
  Widget build(BuildContext context) {
    final p = st.plan;
    return AppCard(
      color: AppColors.softGreen,
      borderColor: AppColors.softGreen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.auto_awesome, color: AppColors.green),
          SizedBox(width: 8),
          Expanded(
            child: Text('Latihan otomatis',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.navy)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          p == null
              ? 'Belum disusun. Unggah jadwal kegiatan, lalu AYOSEHAT memilih waktu olahraga yang pas.'
              : '${p.perWeek}x seminggu · ${p.level[0].toUpperCase()}${p.level.substring(1)} · ${p.minutes} menit · waktu ${p.time.label.toLowerCase()}. '
                  'Disusun ulang otomatis setiap jadwal kegiatan berubah.',
          style: const TextStyle(color: AppColors.navy, height: 1.4),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => showPlanSheet(context),
          icon: const Icon(Icons.tune, size: 18),
          label: Text(p == null ? 'Susun latihan otomatis' : 'Ubah & susun ulang'),
        ),
      ]),
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
