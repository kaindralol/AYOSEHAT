/// Latihan terpandu 15–30 menit tanpa alat, dari video YouTube publik.
enum WorkoutLevel { ringan, sedang, berat }

extension WorkoutLevelLabel on WorkoutLevel {
  String get label => switch (this) {
        WorkoutLevel.ringan => 'Ringan',
        WorkoutLevel.sedang => 'Sedang',
        WorkoutLevel.berat => 'Berat',
      };
}

class Workout {
  const Workout({
    required this.id,
    required this.level,
    required this.minutes,
    required this.title,
    required this.description,
    required this.videoId,
    required this.videoTitle,
  });

  final String id;
  final WorkoutLevel level;
  final int minutes;
  final String title;
  final String description;

  /// ID video YouTube (bagian setelah watch?v=).
  final String videoId;

  /// Judul asli video di YouTube.
  final String videoTitle;

  String get thumbnailUrl => 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  String get watchUrl => 'https://www.youtube.com/watch?v=$videoId';
}

const List<Workout> workouts = [
  Workout(
    id: 'r15',
    level: WorkoutLevel.ringan,
    minutes: 15,
    title: 'Kardio Pemula Tanpa Lompat',
    description: 'Gerakan dasar tanpa lompat, cukup ruang kecil di kamar kos.',
    videoId: '3oitzTfujXs',
    videoTitle:
        '15 MIN BEGINNER CARDIO WORKOUT (No Jumping, Small Space Friendly, No Equipment)',
  ),
  Workout(
    id: 'r30',
    level: WorkoutLevel.ringan,
    minutes: 30,
    title: 'Jalan Kaki di Tempat',
    description: 'Kardio jalan di tempat yang santai, tanpa squat dan lompat.',
    videoId: 'eYUx64kGXHc',
    videoTitle: '30 minute Low Impact Cardio Walking Workout at Home',
  ),
  Workout(
    id: 's15',
    level: WorkoutLevel.sedang,
    minutes: 15,
    title: 'Full Body Tanpa Alat',
    description: 'Latihan seluruh tubuh tanpa gerakan berulang.',
    videoId: 'h5tFiJVTQBw',
    videoTitle: '15 Minute Full Body Workout (No Equipment)',
  ),
  Workout(
    id: 's30',
    level: WorkoutLevel.sedang,
    minutes: 30,
    title: 'Full Body Low Impact',
    description: 'Berkeringat tanpa lompat, aman untuk tetangga kos.',
    videoId: 'yeLfaC9XIzQ',
    videoTitle: '30 min Low Impact FULL BODY Workout (No Equipment + No Jumping)',
  ),
  Workout(
    id: 'b15',
    level: WorkoutLevel.berat,
    minutes: 15,
    title: 'HIIT Full Body',
    description: 'Interval intens dan singkat. Untuk yang sudah terbiasa olahraga.',
    videoId: 'L0Ji6oTAovo',
    videoTitle: '15 MIN KILLER HIIT Full Body Workout (No Equipment, At Home)',
  ),
  Workout(
    id: 'b30',
    level: WorkoutLevel.berat,
    minutes: 30,
    title: 'HIIT + Perut',
    description: 'HIIT seluruh tubuh ditutup latihan perut.',
    videoId: 'gTM8YUBFZHE',
    videoTitle:
        '30 MIN CALORIE KILLER HIIT & ABS Workout - No Equipment - Full Body Home Workout',
  ),
];

/// Latihan yang cocok untuk level ('ringan'|'sedang'|'berat') & durasi.
Workout workoutFor(String level, int minutes) {
  final lv = WorkoutLevel.values.firstWhere((l) => l.name == level,
      orElse: () => WorkoutLevel.sedang);
  return workouts.firstWhere((w) => w.level == lv && w.minutes == minutes,
      orElse: () => workouts.firstWhere((w) => w.level == lv));
}

Workout? workoutById(String? id) {
  for (final w in workouts) {
    if (w.id == id) return w;
  }
  return null;
}
