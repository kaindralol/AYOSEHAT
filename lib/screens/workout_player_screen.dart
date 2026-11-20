import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../workouts.dart';
import 'workouts_screen.dart';

/// Memutar video latihan YouTube langsung di dalam aplikasi.
class WorkoutPlayerScreen extends StatefulWidget {
  const WorkoutPlayerScreen({super.key, required this.workout});
  final Workout workout;

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.workout.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        // Wajib sejak 2025: YouTube perlu tahu aplikasi mana yang memutar
        // video (tanpa ini muncul "Error code 152/153").
        origin: 'https://id.ayosehat.ayosehat',
        showFullscreenButton: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Future<void> _openYoutube() async {
    final ok = await launchUrl(Uri.parse(widget.workout.watchUrl),
        mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tidak bisa membuka aplikasi YouTube.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;
    return Scaffold(
      appBar: AppBar(title: Text(w.title)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            YoutubePlayer(controller: _controller, aspectRatio: 16 / 9),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Pill(w.level.label,
                          fg: levelColor(w.level), bg: levelBg(w.level)),
                      const SizedBox(width: 6),
                      Pill('${w.minutes} menit',
                          fg: AppColors.muted, bg: AppColors.softGrey),
                    ]),
                    const SizedBox(height: 10),
                    Text(w.title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy)),
                    const SizedBox(height: 4),
                    Text(w.description,
                        style: const TextStyle(
                            color: AppColors.muted, height: 1.45)),
                    const SizedBox(height: 14),
                    AppCard(
                      color: AppColors.softGrey,
                      borderColor: AppColors.softGrey,
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        const Icon(Icons.smart_display_outlined,
                            color: AppColors.muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Video YouTube: ${w.videoTitle}',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.muted)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Pemanasan dulu, minum air, dan berhenti kalau pusing atau nyeri.',
                      style: TextStyle(color: AppColors.navy, height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _openYoutube,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Buka di aplikasi YouTube'),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Kalau video tidak bisa diputar di sini (pemilik video menonaktifkan pemutaran di aplikasi lain), buka lewat tombol di atas.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
