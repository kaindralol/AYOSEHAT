import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/session_widgets.dart';
import 'forms.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenPro});
  final VoidCallback onOpenPro;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final today = dateOnly(st.clock());
    final todayItems = st.itemsOn(today);
    final upcoming = st.upcomingSessions(days: 3);
    final conflicts = st.conflicts;
    final isEmpty = st.agendas.isEmpty && st.sessions.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Row(children: [
              const AppLogo(size: 40),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wordmark(size: 20),
                      Text('Rencana Olahraga Kamu',
                          style:
                              TextStyle(fontSize: 12.5, color: AppColors.muted)),
                    ]),
              ),
              if (st.isPro)
                const Pill('PRO',
                    fg: Colors.white,
                    bg: AppColors.navy,
                    icon: Icons.workspace_premium),
            ]),
            const SizedBox(height: 16),
            _PlanBanner(st: st, onOpenPro: onOpenPro),
            if (conflicts.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final s in conflicts) ConflictCard(session: s),
            ],
            const SizedBox(height: 12),
            _WeekStatsCard(st: st),
            if (isEmpty) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mulai dari jadwalmu',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.navy)),
                      const SizedBox(height: 6),
                      const Text(
                          'Masukkan agenda kuliah & kegiatan, lalu sesi olahragamu. Kalau ada yang bentrok, AYOSEHAT memindahkan sesi ke slot kosong terdekat.',
                          style:
                              TextStyle(height: 1.45, color: AppColors.muted)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => showAddChooser(context),
                            child: const Text('Tambah jadwal'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => AppScope.read(context).seedDemo(),
                            child: const Text('Isi contoh'),
                          ),
                        ),
                      ]),
                    ]),
              ),
            ],
            const SizedBox(height: 20),
            SectionTitle('Hari ini · ${fmtDayLong(today)}'),
            const SizedBox(height: 10),
            if (todayItems.isEmpty)
              const EmptyHint(
                  icon: Icons.wb_sunny_outlined,
                  text: 'Belum ada agenda atau sesi olahraga hari ini.')
            else
              for (final item in todayItems) DayItemTile(item: item),
            const SizedBox(height: 20),
            const SectionTitle('Sesi 3 hari ke depan'),
            const SizedBox(height: 10),
            if (upcoming.isEmpty)
              const EmptyHint(
                  icon: Icons.directions_run_rounded,
                  text: 'Belum ada sesi olahraga terjadwal. Tekan Tambah.')
            else
              for (final s in upcoming) SessionTile(session: s, showDate: true),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddChooser(context),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

/// Banner status langganan: ajakan trial, sisa trial, atau trial berakhir.
class _PlanBanner extends StatelessWidget {
  const _PlanBanner({required this.st, required this.onOpenPro});
  final AppState st;
  final VoidCallback onOpenPro;

  @override
  Widget build(BuildContext context) {
    if (st.isPaidPro) return const SizedBox.shrink();

    final String title;
    final String body;
    final String cta;
    final VoidCallback action;
    if (st.isTrialActive) {
      title = 'Trial Pro · sisa ${st.trialDaysLeft} hari';
      body =
          'Pindah otomatis tanpa batas sedang aktif. Lanjutkan Pro ${fmtRupiah(AppState.priceSemester)}/semester agar jadwalmu tetap aman di minggu padat.';
      cta = 'Lihat Pro';
      action = onOpenPro;
    } else if (st.trialExpired) {
      title = 'Trial Pro sudah berakhir';
      body =
          'Sekarang kamu di paket Gratis: pindah otomatis ${AppState.freeMovesPerWeek}x per minggu (sisa ${st.freeMovesLeft}).';
      cta = 'Aktifkan Pro';
      action = onOpenPro;
    } else {
      title = 'Coba Pro gratis 14 hari';
      body =
          'Sesi olahraga pindah otomatis tanpa batas setiap kali jadwal kuliah atau rapat berubah.';
      cta = 'Mulai trial';
      action = () => AppScope.read(context).startTrial();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF0D5C4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium, color: AppColors.mint, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(body,
            style: const TextStyle(color: Color(0xFFD5DCE3), height: 1.45)),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.mint,
              foregroundColor: AppColors.navy,
              minimumSize: const Size(0, 42)),
          onPressed: action,
          child: Text(cta),
        ),
      ]),
    );
  }
}

class _WeekStatsCard extends StatelessWidget {
  const _WeekStatsCard({required this.st});
  final AppState st;

  @override
  Widget build(BuildContext context) {
    final w = st.weekStats();
    Widget stat(String value, String label, Color color) => Expanded(
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        );
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Minggu ini',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.navy)),
          ),
          if (!st.isPro)
            Pill('Pindah gratis: sisa ${st.freeMovesLeft}x',
                fg: AppColors.orangeDark, bg: AppColors.softOrange),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          stat('${w.planned}', 'sesi\ndirencanakan', AppColors.navy),
          stat('${w.done}', 'sesi\nselesai', AppColors.green),
          stat('${w.moved}', 'dipindah\notomatis', AppColors.orange),
        ]),
      ]),
    );
  }
}
