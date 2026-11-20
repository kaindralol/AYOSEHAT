import 'utils/format.dart';

/// Jenis agenda non-olahraga yang bisa bentrok dengan sesi olahraga.
enum AgendaType { kuliah, organisasi, tugas, lainnya }

extension AgendaTypeLabel on AgendaType {
  String get label => switch (this) {
        AgendaType.kuliah => 'Kuliah',
        AgendaType.organisasi => 'Organisasi',
        AgendaType.tugas => 'Tugas',
        AgendaType.lainnya => 'Lainnya',
      };
}

/// Agenda kuliah / rapat / tugas. Bisa sekali saja atau berulang tiap minggu.
class Agenda {
  Agenda({
    required this.id,
    required this.title,
    required this.type,
    required DateTime date,
    required this.startMin,
    required this.endMin,
    this.weekly = false,
    DateTime? until,
    this.sourceId,
  })  : date = dateOnly(date),
        until = until == null ? null : dateOnly(until);

  final String id;
  String title;
  AgendaType type;

  /// Tanggal (untuk agenda sekali) atau tanggal mulai (untuk agenda mingguan).
  DateTime date;
  int startMin;
  int endMin;
  bool weekly;

  /// Agenda mingguan berhenti berlaku setelah tanggal ini (null = seterusnya).
  DateTime? until;

  /// ID file jadwal yang diunggah (null = dibuat manual).
  String? sourceId;

  bool occursOn(DateTime day) {
    final d = dateOnly(day);
    if (!weekly) return sameDay(d, date);
    if (until != null && d.isAfter(until!)) return false;
    return d.weekday == date.weekday && !d.isBefore(date);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'date': date.toIso8601String(),
        'start': startMin,
        'end': endMin,
        'weekly': weekly,
        'until': until?.toIso8601String(),
        'sourceId': sourceId,
      };

  factory Agenda.fromJson(Map<String, dynamic> j) => Agenda(
        id: j['id'] as String,
        title: j['title'] as String,
        type: AgendaType.values.byName(j['type'] as String),
        date: DateTime.parse(j['date'] as String),
        startMin: j['start'] as int,
        endMin: j['end'] as int,
        weekly: (j['weekly'] as bool?) ?? false,
        until: j['until'] == null ? null : DateTime.parse(j['until'] as String),
        sourceId: j['sourceId'] as String?,
      );
}

enum SessionStatus { planned, done, skipped }

/// Satu sesi olahraga pada tanggal tertentu.
class Session {
  Session({
    required this.id,
    required this.title,
    required DateTime date,
    required this.startMin,
    required this.durationMin,
    this.status = SessionStatus.planned,
    this.moveCount = 0,
    DateTime? originalDate,
    this.originalStartMin,
    this.needsMove = false,
    this.workoutId,
    this.auto = false,
  })  : date = dateOnly(date),
        originalDate = originalDate == null ? null : dateOnly(originalDate);

  final String id;
  String title;
  DateTime date;
  int startMin;
  int durationMin;
  SessionStatus status;

  /// Berapa kali sesi ini sudah dipindah otomatis.
  int moveCount;

  /// Jadwal awal sebelum dipindah (untuk ditampilkan ke pengguna).
  DateTime? originalDate;
  int? originalStartMin;

  /// True kalau sesi bentrok dengan agenda dan belum dipindah.
  bool needsMove;

  /// Latihan video terpandu (lihat workouts.dart), kalau ada.
  String? workoutId;

  /// True kalau dibuat otomatis oleh penyusun latihan.
  bool auto;

  int get endMin => startMin + durationMin;

  bool get wasMoved =>
      moveCount > 0 && originalDate != null && originalStartMin != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'start': startMin,
        'duration': durationMin,
        'status': status.name,
        'moveCount': moveCount,
        'originalDate': originalDate?.toIso8601String(),
        'originalStart': originalStartMin,
        'needsMove': needsMove,
        'workoutId': workoutId,
        'auto': auto,
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        id: j['id'] as String,
        title: j['title'] as String,
        date: DateTime.parse(j['date'] as String),
        startMin: j['start'] as int,
        durationMin: j['duration'] as int,
        status: SessionStatus.values.byName(j['status'] as String),
        moveCount: (j['moveCount'] as int?) ?? 0,
        originalDate: j['originalDate'] == null
            ? null
            : DateTime.parse(j['originalDate'] as String),
        originalStartMin: j['originalStart'] as int?,
        needsMove: (j['needsMove'] as bool?) ?? false,
        workoutId: j['workoutId'] as String?,
        auto: (j['auto'] as bool?) ?? false,
      );
}

/// Item gabungan (agenda atau sesi) untuk ditampilkan di timeline satu hari.
class DayItem {
  DayItem.agenda(Agenda a)
      : agenda = a,
        session = null,
        start = a.startMin,
        end = a.endMin;

  DayItem.session(Session s)
      : agenda = null,
        session = s,
        start = s.startMin,
        end = s.endMin;

  final Agenda? agenda;
  final Session? session;
  final int start;
  final int end;

  bool get isSession => session != null;
}

/// Cara jadwal hasil unggahan dipakai.
enum UploadMode { seterusnya, semingguSaja }

/// Satu file jadwal kegiatan yang pernah diunggah.
class UploadedSchedule {
  UploadedSchedule({
    required this.id,
    required this.fileName,
    required this.uploadedAt,
    required this.mode,
    required this.count,
  });

  final String id;
  final String fileName;
  final DateTime uploadedAt;
  UploadMode mode;
  int count;

  /// Hari terakhir berlaku untuk mode "seminggu saja" (Minggu di minggu unggah).
  DateTime get weekEnd => addDays(startOfWeek(uploadedAt), 6);

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'uploadedAt': uploadedAt.toIso8601String(),
        'mode': mode.name,
        'count': count,
      };

  factory UploadedSchedule.fromJson(Map<String, dynamic> j) => UploadedSchedule(
        id: j['id'] as String,
        fileName: j['fileName'] as String,
        uploadedAt: DateTime.parse(j['uploadedAt'] as String),
        mode: UploadMode.values.byName(j['mode'] as String),
        count: (j['count'] as int?) ?? 0,
      );
}

/// Waktu favorit untuk berolahraga.
enum PreferredTime { pagi, siang, sore, malam, bebas }

extension PreferredTimeInfo on PreferredTime {
  String get label => switch (this) {
        PreferredTime.pagi => 'Pagi',
        PreferredTime.siang => 'Siang',
        PreferredTime.sore => 'Sore',
        PreferredTime.malam => 'Malam',
        PreferredTime.bebas => 'Bebas',
      };

  /// [mulai, selesai, jam ideal] dalam menit sejak 00.00.
  List<int> get window => switch (this) {
        PreferredTime.pagi => [330, 600, 390],
        PreferredTime.siang => [600, 900, 750],
        PreferredTime.sore => [900, 1110, 990],
        PreferredTime.malam => [1110, 1290, 1170],
        PreferredTime.bebas => [330, 1290, 990],
      };
}

/// Preferensi penyusun latihan otomatis.
class PlanPrefs {
  PlanPrefs({
    this.perWeek = 3,
    this.level = 'sedang',
    this.minutes = 30,
    this.time = PreferredTime.sore,
  });

  int perWeek;

  /// 'ringan' | 'sedang' | 'berat'
  String level;
  int minutes;
  PreferredTime time;

  Map<String, dynamic> toJson() => {
        'perWeek': perWeek,
        'level': level,
        'minutes': minutes,
        'time': time.name,
      };

  factory PlanPrefs.fromJson(Map<String, dynamic> j) => PlanPrefs(
        perWeek: (j['perWeek'] as int?) ?? 3,
        level: (j['level'] as String?) ?? 'sedang',
        minutes: (j['minutes'] as int?) ?? 30,
        time: PreferredTime.values.byName((j['time'] as String?) ?? 'sore'),
      );
}

/// Satu kegiatan hasil membaca file jadwal (sebelum disimpan).
class ParsedEntry {
  ParsedEntry({
    required this.title,
    required this.type,
    required this.startMin,
    required this.endMin,
    this.weekday,
    this.date,
  });

  String title;
  AgendaType type;
  int startMin;
  int endMin;

  /// 1 = Senin ... 7 = Minggu (untuk kegiatan rutin mingguan).
  int? weekday;

  /// Tanggal tertentu (untuk kegiatan sekali).
  DateTime? date;
}
