import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../workouts.dart';
import 'workout_player_screen.dart';

Color levelColor(WorkoutLevel l) => switch (l) {
      WorkoutLevel.ringan => AppColors.green,
      WorkoutLevel.sedang => const Color(0xFF9A6B00),
      WorkoutLevel.berat => AppColors.orangeDark,
    };

Color levelBg(WorkoutLevel l) => switch (l) {
      WorkoutLevel.ringan => AppColors.softGreen,
      WorkoutLevel.sedang => const Color(0xFFFFF1D2),
      WorkoutLevel.berat => AppColors.softOrange,
    };

/// Daftar latihan terpandu dengan thumbnail video YouTube.
class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Latihan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const Text(
              '15–30 menit, tanpa alat, bisa di kamar kos. Pilih level sesuai kondisimu dan berhenti kalau pusing atau nyeri.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            for (final level in WorkoutLevel.values) ...[
              const SizedBox(height: 20),
              Row(children: [
                Pill(level.label, fg: levelColor(level), bg: levelBg(level)),
              ]),
              const SizedBox(height: 10),
              for (final w in workouts.where((w) => w.level == level))
                WorkoutCard(workout: w),
            ],
          ],
        ),
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  const WorkoutCard({super.key, required this.workout});
  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final w = workout;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WorkoutPlayerScreen(workout: w))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          VideoThumbnail(workout: w),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
                  const SizedBox(height: 8),
                  Text(w.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy)),
                  const SizedBox(height: 2),
                  Text(w.description,
                      style: const TextStyle(
                          color: AppColors.muted, height: 1.4)),
                ]),
          ),
        ]),
      ),
    );
  }
}

/// Thumbnail asli YouTube dengan tombol play & durasi.
class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({super.key, required this.workout});
  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(fit: StackFit.expand, children: [
        Image.network(
          workout.thumbnailUrl,
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : Container(
                  color: AppColors.softGrey,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2.5),
                ),
          errorBuilder: (context, error, stack) => Container(
            color: AppColors.navy,
            alignment: Alignment.center,
            child: const Icon(Icons.ondemand_video,
                color: Colors.white54, size: 48),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0x66000000)],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
                color: Color(0xE6FFFFFF), shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded,
                size: 40, color: AppColors.green),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: const Color(0xCC000000),
                borderRadius: BorderRadius.circular(6)),
            child: Text('${workout.minutes}:00',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
