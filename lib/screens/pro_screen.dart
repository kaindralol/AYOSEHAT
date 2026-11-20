import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Paywall AYOSEHAT Pro: Rp35.000 per semester, trial 14 hari.
class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AYOSEHAT Pro')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _Hero(st: st),
            const SizedBox(height: 16),
            const _Comparison(),
            const SizedBox(height: 16),
            _Actions(st: st),
            const SizedBox(height: 16),
            const Text(
              'Mode demo: pembayaran belum terhubung ke payment gateway. '
              'Tombol bayar hanya mengaktifkan Pro di HP ini untuk keperluan uji coba.',
              style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.st});
  final AppState st;

  @override
  Widget build(BuildContext context) {
    String status;
    if (st.isPaidPro) {
      status = 'Pro aktif sampai ${fmtDay(st.proUntil!)} ${st.proUntil!.year}';
    } else if (st.isTrialActive) {
      status = 'Trial Pro aktif · sisa ${st.trialDaysLeft} hari';
    } else if (st.trialExpired) {
      status = 'Trial berakhir · paket Gratis';
    } else {
      status = 'Paket Gratis';
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF0D5C4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const AppLogo(size: 44),
          const SizedBox(width: 10),
          const Expanded(child: Wordmark(size: 20, light: true)),
        ]),
        const SizedBox(height: 12),
        Pill(status, fg: AppColors.navy, bg: AppColors.mint),
        const SizedBox(height: 14),
        const Text('Olahraga tetap jalan,\nwalau jadwal berubah.',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fmtRupiah(AppState.priceSemester),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          const Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: Text('/ semester',
                style: TextStyle(color: Color(0xFFD5DCE3))),
          ),
        ]),
        const Text('Berlaku 6 bulan · coba gratis 14 hari dulu',
            style: TextStyle(color: Color(0xFFD5DCE3), fontSize: 12.5)),
      ]),
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Jadwal agenda & olahraga', true, true),
      ('Peringatan saat jadwal bentrok', true, true),
      ('Pindah sesi otomatis', false, true),
      ('Pilih slot kosong manual', true, true),
    ];
    Widget mark(bool on) => Icon(on ? Icons.check_circle : Icons.remove,
        size: 20, color: on ? AppColors.green : AppColors.muted);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(children: [
        const Row(children: [
          Expanded(
              child: Text('Fitur',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.navy))),
          SizedBox(
              width: 64,
              child: Text('Gratis',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.muted))),
          SizedBox(
              width: 64,
              child: Text('Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.green))),
        ]),
        const Divider(height: 20),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(
                  child: Text(r.$1,
                      style: const TextStyle(color: AppColors.navy))),
              SizedBox(width: 64, child: Center(child: mark(r.$2))),
              SizedBox(width: 64, child: Center(child: mark(r.$3))),
            ]),
          ),
        const Divider(height: 20),
        const Row(children: [
          Expanded(
              child: Text('Batas pindah otomatis',
                  style: TextStyle(color: AppColors.navy))),
          SizedBox(
              width: 64,
              child: Text('${AppState.freeMovesPerWeek}x/minggu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.muted))),
          SizedBox(
              width: 64,
              child: Text('Tanpa batas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green))),
        ]),
      ]),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.st});
  final AppState st;

  Future<void> _pay(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Bayar via QRIS'),
        content: Text(
            'Total ${fmtRupiah(AppState.priceSemester)} untuk 1 semester (6 bulan).\n\n'
            'Ini masih mode demo: belum ada pembayaran sungguhan. '
            'Tekan "Konfirmasi" untuk mengaktifkan Pro di HP ini.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Konfirmasi')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      AppScope.read(context).activateProDemo();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('AYOSEHAT Pro aktif. Selamat berolahraga!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (st.isPaidPro) {
      return const AppCard(
        color: AppColors.softGreen,
        borderColor: AppColors.softGreen,
        child: Row(children: [
          Icon(Icons.verified, color: AppColors.green),
          SizedBox(width: 10),
          Expanded(
              child: Text('Pro aktif. Semua sesi bentrok akan dipindah otomatis.',
                  style: TextStyle(color: AppColors.navy))),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (!st.trialUsed)
        FilledButton.icon(
          onPressed: () {
            AppScope.read(context).startTrial();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Trial Pro 14 hari dimulai.')));
          },
          icon: const Icon(Icons.rocket_launch_outlined),
          label: const Text('Mulai trial gratis 14 hari'),
        ),
      if (!st.trialUsed) const SizedBox(height: 10),
      st.trialUsed
          ? FilledButton.icon(
              onPressed: () => _pay(context),
              icon: const Icon(Icons.qr_code_2),
              label: Text(
                  'Bayar ${fmtRupiah(AppState.priceSemester)} via QRIS'),
            )
          : OutlinedButton.icon(
              onPressed: () => _pay(context),
              icon: const Icon(Icons.qr_code_2),
              label: Text(
                  'Langsung bayar ${fmtRupiah(AppState.priceSemester)} via QRIS'),
            ),
    ]);
  }
}
