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
  }) : date = dateOnly(date);

  final String id;
  String title;
  AgendaType type;

  /// Tanggal (untuk agenda sekali) atau tanggal mulai (untuk agenda mingguan).
  DateTime date;
  int startMin;
  int endMin;
  bool weekly;

  bool occursOn(DateTime day) {
    final d = dateOnly(day);
    if (!weekly) return sameDay(d, date);
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
      };

  factory Agenda.fromJson(Map<String, dynamic> j) => Agenda(
        id: j['id'] as String,
        title: j['title'] as String,
        type: AgendaType.values.byName(j['type'] as String),
        date: DateTime.parse(j['date'] as String),
        startMin: j['start'] as int,
        endMin: j['end'] as int,
        weekly: (j['weekly'] as bool?) ?? false,
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
