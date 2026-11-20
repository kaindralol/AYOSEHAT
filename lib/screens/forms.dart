import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models.dart';
import '../scheduler.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/session_widgets.dart';

int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;
TimeOfDay _toTime(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);

/// Pilihan "Tambah": agenda kuliah/kegiatan atau sesi olahraga.
Future<void> showAddChooser(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetCtx) {
      Widget option(IconData icon, Color color, String title, String sub,
          Widget page) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            onTap: () {
              Navigator.of(sheetCtx).pop();
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => page));
            },
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy)),
                      const SizedBox(height: 2),
                      Text(sub,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.muted)),
                    ]),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ]),
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            option(
                Icons.directions_run_rounded,
                AppColors.green,
                'Sesi olahraga',
                'Lari, badminton, gym, atau latihan 15 menit di kos',
                const SessionFormPage()),
            option(
                Icons.school_outlined,
                AppColors.navy,
                'Agenda kuliah / kegiatan',
                'Kuliah, rapat, kepanitiaan, tugas. Sesi yang bentrok akan dipindah.',
                const AgendaFormPage()),
          ]),
        ),
      );
    },
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.navy)),
      );
}

class _PickerButton extends StatelessWidget {
  const _PickerButton(
      {required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white, alignment: Alignment.centerLeft),
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.green),
      label: Text(text),
    );
  }
}

// =====================================================================
// Agenda
// =====================================================================
class AgendaFormPage extends StatefulWidget {
  const AgendaFormPage({super.key, this.existing});
  final Agenda? existing;

  @override
  State<AgendaFormPage> createState() => _AgendaFormPageState();
}

class _AgendaFormPageState extends State<AgendaFormPage> {
  late final TextEditingController _title;
  late AgendaType _type;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late bool _weekly;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _title = TextEditingController(text: a?.title ?? '');
    _type = a?.type ?? AgendaType.kuliah;
    _date = a?.date ?? dateOnly(DateTime.now());
    _start = _toTime(a?.startMin ?? 8 * 60);
    _end = _toTime(a?.endMin ?? 10 * 60);
    _weekly = a?.weekly ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _valid =>
      _title.text.trim().isNotEmpty && _toMin(_end) > _toMin(_start);

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: addDays(dateOnly(DateTime.now()), -365),
      lastDate: addDays(dateOnly(DateTime.now()), 365),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool start) async {
    final t = await showTimePicker(
        context: context, initialTime: start ? _start : _end);
    if (t == null) return;
    setState(() {
      if (start) {
        final dur = _toMin(_end) - _toMin(_start);
        _start = t;
        final newEnd = _toMin(t) + (dur > 0 ? dur : 60);
        _end = _toTime(newEnd > 23 * 60 + 59 ? 23 * 60 + 59 : newEnd);
      } else {
        _end = t;
      }
    });
  }

  void _save() {
    final st = AppScope.read(context);
    final a = widget.existing;
    final results = a == null
        ? st.addAgenda(Agenda(
            id: newId(),
            title: _title.text.trim(),
            type: _type,
            date: _date,
            startMin: _toMin(_start),
            endMin: _toMin(_end),
            weekly: _weekly,
          ))
        : st.updateAgenda(a,
            title: _title.text.trim(),
            type: _type,
            date: _date,
            startMin: _toMin(_start),
            endMin: _toMin(_end),
            weekly: _weekly);
    showMoveResults(context, results);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus agenda?'),
        content: Text(widget.existing!.weekly
            ? 'Agenda mingguan ini akan dihapus dari semua minggu.'
            : 'Agenda ini akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Hapus',
                  style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    AppScope.read(context).deleteAgenda(widget.existing!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Ubah agenda' : 'Agenda baru'),
        actions: [
          if (editing)
            IconButton(
                tooltip: 'Hapus',
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (editing)
              const AppCard(
                color: AppColors.softGreen,
                borderColor: AppColors.softGreen,
                child: Row(children: [
                  Icon(Icons.auto_fix_high, color: AppColors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Agenda berubah mendadak? Ubah jamnya di sini. Sesi olahraga yang bentrok akan dipindah ke slot kosong terdekat.',
                        style: TextStyle(height: 1.4, color: AppColors.navy)),
                  ),
                ]),
              ),
            const _FieldLabel('Nama agenda'),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(hintText: 'Misal: Kalkulus, Rapat BEM'),
              onChanged: (_) => setState(() {}),
            ),
            const _FieldLabel('Jenis'),
            Wrap(spacing: 8, children: [
              for (final t in AgendaType.values)
                ChoiceChip(
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ]),
            const _FieldLabel('Tanggal'),
            _PickerButton(
                icon: Icons.event,
                text: fmtDayLong(_date),
                onTap: _pickDate),
            const _FieldLabel('Jam'),
            Row(children: [
              Expanded(
                  child: _PickerButton(
                      icon: Icons.schedule,
                      text: 'Mulai ${fmtMin(_toMin(_start))}',
                      onTap: () => _pickTime(true))),
              const SizedBox(width: 10),
              Expanded(
                  child: _PickerButton(
                      icon: Icons.schedule,
                      text: 'Selesai ${fmtMin(_toMin(_end))}',
                      onTap: () => _pickTime(false))),
            ]),
            if (_toMin(_end) <= _toMin(_start))
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Jam selesai harus setelah jam mulai.',
                    style: TextStyle(color: AppColors.red, fontSize: 12.5)),
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _weekly,
              onChanged: (v) => setState(() => _weekly = v),
              title: const Text('Ulangi setiap minggu'),
              subtitle: Text('Setiap ${hariPanjang[_date.weekday - 1]}'),
            ),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: _valid ? _save : null,
                child: Text(editing ? 'Simpan perubahan' : 'Simpan agenda')),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Sesi olahraga
// =====================================================================
class SessionFormPage extends StatefulWidget {
  const SessionFormPage({super.key});

  @override
  State<SessionFormPage> createState() => _SessionFormPageState();
}

class _SessionFormPageState extends State<SessionFormPage> {
  static const _presets = [
    'Lari pagi',
    'Jogging sore',
    'Badminton',
    'Futsal',
    'Gym',
    'Latihan 15 menit di kos',
  ];
  static const _durations = [15, 30, 45, 60, 90];

  final TextEditingController _title = TextEditingController();
  late DateTime _date;
  TimeOfDay _start = const TimeOfDay(hour: 16, minute: 0);
  int _duration = 30;
  bool _repeat = true;

  @override
  void initState() {
    super.initState();
    _date = dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: addDays(today, 180),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _start);
    if (t != null) setState(() => _start = t);
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final start = _toMin(_start);
    final clash =
        Scheduler.conflictingAgendaAt(_date, start, _duration, st.agendas);
    final Slot? suggestion = clash == null
        ? null
        : Scheduler.findSlot(
            Session(
                id: '_probe',
                title: 'probe',
                date: _date,
                startMin: start,
                durationMin: _duration),
            st.agendas,
            st.sessions,
            now: st.clock());
    final valid = _title.text.trim().isNotEmpty && clash == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Sesi olahraga baru')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const _FieldLabel('Olahraga apa?'),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(hintText: 'Misal: Lari pagi'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final p in _presets)
                ActionChip(
                  label: Text(p),
                  onPressed: () => setState(() {
                    _title.text = p;
                    if (p.contains('15 menit')) _duration = 15;
                  }),
                ),
            ]),
            const _FieldLabel('Kapan?'),
            Row(children: [
              Expanded(
                  child: _PickerButton(
                      icon: Icons.event,
                      text: fmtDay(_date),
                      onTap: _pickDate)),
              const SizedBox(width: 10),
              Expanded(
                  child: _PickerButton(
                      icon: Icons.schedule,
                      text: fmtMin(start),
                      onTap: _pickTime)),
            ]),
            const _FieldLabel('Durasi'),
            Wrap(spacing: 8, children: [
              for (final d in _durations)
                ChoiceChip(
                  label: Text('$d mnt'),
                  selected: _duration == d,
                  onSelected: (_) => setState(() => _duration = d),
                ),
            ]),
            if (clash != null) ...[
              const SizedBox(height: 16),
              AppCard(
                color: const Color(0xFFFFF6EE),
                borderColor: AppColors.orange,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bentrok dengan ${clash.title} (${fmtRange(clash.startMin, clash.endMin)}).',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.orangeDark),
                      ),
                      const SizedBox(height: 8),
                      if (suggestion != null)
                        FilledButton.icon(
                          onPressed: () => setState(() {
                            _date = suggestion.date;
                            _start = _toTime(suggestion.startMin);
                          }),
                          icon: const Icon(Icons.auto_fix_high, size: 18),
                          label: Text(
                              'Pakai slot kosong: ${fmtDay(suggestion.date)} ${fmtMin(suggestion.startMin)}'),
                        )
                      else
                        const Text('Tidak ada slot kosong dalam 3 hari. Pilih jam lain.',
                            style: TextStyle(color: AppColors.muted)),
                    ]),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _repeat,
              onChanged: (v) => setState(() => _repeat = v),
              title: const Text('Ulangi 4 minggu'),
              subtitle: Text('Setiap ${hariPanjang[_date.weekday - 1]}, ${fmtMin(start)}'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: valid
                  ? () {
                      AppScope.read(context).addSessions(
                        title: _title.text.trim(),
                        date: _date,
                        startMin: start,
                        durationMin: _duration,
                        repeatWeeks: _repeat ? 4 : 1,
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
              child: const Text('Simpan sesi'),
            ),
          ],
        ),
      ),
    );
  }
}
