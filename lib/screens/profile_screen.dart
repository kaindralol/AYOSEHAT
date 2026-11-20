import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/session_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<bool> _confirm(BuildContext context, String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Lanjut')),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final done =
        st.sessions.where((s) => s.status == SessionStatus.done).length;
    final moved = st.moveLog.length;

    String plan;
    if (st.isPaidPro) {
      plan = 'Pro · aktif sampai ${fmtDay(st.proUntil!)} ${st.proUntil!.year}';
    } else if (st.isTrialActive) {
      plan = 'Trial Pro · sisa ${st.trialDaysLeft} hari';
    } else {
      plan = 'Gratis · pindah otomatis ${st.freeMovesLeft}x lagi minggu ini';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            AppCard(
              child: Row(children: [
                const AppLogo(size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Wordmark(size: 18),
                        const SizedBox(height: 4),
                        Text(plan,
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.muted)),
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Stat(value: '$done', label: 'sesi selesai')),
              const SizedBox(width: 10),
              Expanded(
                  child: _Stat(value: '$moved', label: 'sesi diselamatkan')),
              const SizedBox(width: 10),
              Expanded(
                  child: _Stat(
                      value: '${st.agendas.length}', label: 'agenda')),
            ]),
            const SizedBox(height: 20),
            const SectionTitle('Mode demo (untuk presentasi)'),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome, color: AppColors.green),
                  title: const Text('Isi contoh jadwal maba'),
                  subtitle: const Text('Kuliah, rapat himpunan, dan 8 sesi olahraga'),
                  onTap: () async {
                    if (await _confirm(context, 'Isi contoh jadwal?',
                            'Agenda & sesi yang ada sekarang akan diganti.') &&
                        context.mounted) {
                      AppScope.read(context).seedDemo();
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bolt, color: AppColors.orange),
                  title: const Text('Simulasikan agenda mendadak'),
                  subtitle: const Text(
                      'Tambah "Rapat panitia mendadak" yang menabrak sesi berikutnya'),
                  onTap: () {
                    final r = AppScope.read(context).simulateSuddenAgenda();
                    if (r.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Belum ada sesi olahraga yang akan datang.')));
                    } else {
                      showMoveResults(context, r);
                    }
                  },
                ),
                if (st.isPaidPro) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cancel_outlined,
                        color: AppColors.muted),
                    title: const Text('Batalkan Pro (demo)'),
                    onTap: () => AppScope.read(context).cancelProDemo(),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.delete_forever, color: AppColors.red),
                  title: const Text('Hapus semua data',
                      style: TextStyle(color: AppColors.red)),
                  subtitle: const Text('Termasuk status trial & Pro'),
                  onTap: () async {
                    if (await _confirm(context, 'Hapus semua data?',
                            'Semua agenda, sesi, dan status langganan akan dihapus dari HP ini.') &&
                        context.mounted) {
                      AppScope.read(context).resetAll();
                    }
                  },
                ),
              ]),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('AYOSEHAT v0.1 · Rencana Olahraga Kamu',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.green)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]),
    );
  }
}
