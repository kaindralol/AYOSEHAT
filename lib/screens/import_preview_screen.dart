import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models.dart';
import '../schedule_import.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'plan_sheet.dart';

/// Periksa hasil baca file jadwal sebelum disimpan.
class ImportPreviewScreen extends StatefulWidget {
  const ImportPreviewScreen({super.key, required this.result});
  final ImportResult result;

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  late final List<bool> _checked =
      List<bool>.filled(widget.result.entries.length, true);
  UploadMode _mode = UploadMode.seterusnya;

  String _when(ParsedEntry e) => e.date != null
      ? fmtDayLong(e.date!)
      : 'Tiap ${hariPanjang[(e.weekday ?? 1) - 1]}';

  void _save() {
    final st = AppScope.read(context);
    final picked = [
      for (var i = 0; i < widget.result.entries.length; i++)
        if (_checked[i]) widget.result.entries[i],
    ];
    final hadPlan = st.plan != null;
    st.importSchedule(widget.result.fileName, picked, _mode);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    nav.pop();
    if (hadPlan) {
      final n = st.sessions.where((s) => s.auto).length;
      messenger.showSnackBar(SnackBar(
          content: Text(
              '${picked.length} kegiatan disimpan. Latihan disusun ulang: $n sesi di waktu yang kosong.')));
    } else {
      showPlanSheet(nav.context,
          lead: '${picked.length} kegiatan disimpan. Sekarang atur latihannya.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.result.entries;
    final count = _checked.where((c) => c).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Periksa jadwal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text('${entries.length} kegiatan terbaca dari ${widget.result.fileName}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 4),
            const Text(
                'Hapus centang kegiatan yang terbaca salah. Kamu tetap bisa mengubah jamnya nanti di tab Jadwal.',
                style: TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: [
                for (var i = 0; i < entries.length; i++)
                  CheckboxListTile(
                    value: _checked[i],
                    onChanged: (v) => setState(() => _checked[i] = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(entries[i].title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${_when(entries[i])} · ${fmtRange(entries[i].startMin, entries[i].endMin)} · ${entries[i].type.label}'),
                  ),
              ]),
            ),
            const SizedBox(height: 18),
            const Text('Jadwal ini dipakai untuk…',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 8),
            SegmentedButton<UploadMode>(
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
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 6),
            Text(
              _mode == UploadMode.seterusnya
                  ? 'Cocok untuk jadwal kuliah: kegiatan berulang setiap minggu.'
                  : 'Cocok untuk jadwal kepanitiaan atau minggu ujian: hanya berlaku minggu ini.',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: count == 0 ? null : _save,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text('Simpan $count kegiatan & susun latihan'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alur lengkap: pilih file → baca → periksa → simpan.
Future<void> uploadScheduleFlow(BuildContext context) async {
  final res = await pickAndReadSchedule();
  if (res == null || !context.mounted) return;
  if (res.error != null) {
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Jadwal belum terbaca'),
        content: Text(
            '${res.error}\n\nTips: pastikan setiap kegiatan punya hari dan jam, misalnya "Senin 07.00-09.30 Kalkulus". '
            'Format yang didukung: PDF, foto/screenshot (JPG, PNG), Excel (.xlsx), CSV, TXT, dan kalender (.ics).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup')),
        ],
      ),
    );
    return;
  }
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ImportPreviewScreen(result: res)));
}
