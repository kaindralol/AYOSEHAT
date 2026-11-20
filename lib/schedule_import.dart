import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'models.dart';
import 'schedule_parser.dart';

class ImportResult {
  ImportResult(this.fileName, this.entries, [this.error]);
  final String fileName;
  final List<ParsedEntry> entries;
  final String? error;
}

const allowedScheduleExtensions = ['jpg', 'jpeg', 'png', 'csv', 'xlsx', 'txt', 'ics'];

/// Buka pemilih file, lalu baca jadwal di dalamnya.
/// Mengembalikan null kalau pengguna membatalkan.
Future<ImportResult?> pickAndReadSchedule() async {
  final res = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedScheduleExtensions,
    withData: true,
  );
  if (res == null || res.files.isEmpty) return null;
  final f = res.files.single;
  final name = f.name;
  final ext = (f.extension ?? '').toLowerCase();
  try {
    List<ParsedEntry> entries;
    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
      final path = f.path;
      if (path == null) {
        return ImportResult(name, [], 'Foto tidak bisa dibuka dari lokasi ini.');
      }
      entries = parseScheduleText(await _ocr(path));
    } else {
      final bytes = f.bytes ?? await File(f.path!).readAsBytes();
      if (ext == 'xlsx') {
        entries = parseScheduleText(_excelToLines(bytes));
      } else {
        final text = utf8.decode(bytes, allowMalformed: true);
        entries = ext == 'ics'
            ? parseIcs(text)
            : parseScheduleText(ext == 'csv' ? csvToLines(text) : text);
      }
    }
    return ImportResult(
      name,
      entries,
      entries.isEmpty
          ? 'Tidak ada kegiatan berhari & berjam yang terbaca dari file ini.'
          : null,
    );
  } catch (e) {
    return ImportResult(name, [], 'Gagal membaca file: $e');
  }
}

String _excelToLines(List<int> bytes) {
  final x = Excel.decodeBytes(bytes);
  final buf = StringBuffer();
  for (final sheet in x.tables.values) {
    for (final row in sheet.rows) {
      buf.writeln(row.map((c) => c?.value?.toString() ?? '').join(' | '));
    }
  }
  return buf.toString();
}

/// Baca teks dari foto/screenshot jadwal di HP (tanpa internet).
/// Potongan teks yang sejajar disusun kembali menjadi baris tabel.
Future<String> _ocr(String path) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(InputImage.fromFilePath(path));
    final items = <_Piece>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final r = line.boundingBox;
        items.add(_Piece(line.text, r.left, r.top + r.height / 2, r.height));
      }
    }
    items.sort((a, b) => a.cy.compareTo(b.cy));
    final rows = <List<_Piece>>[];
    for (final p in items) {
      if (rows.isNotEmpty) {
        final last = rows.last;
        final cy = last.map((e) => e.cy).reduce((a, b) => a + b) / last.length;
        if ((p.cy - cy).abs() < p.h * 0.6) {
          last.add(p);
          continue;
        }
      }
      rows.add([p]);
    }
    return rows.map((r) {
      r.sort((a, b) => a.left.compareTo(b.left));
      return r.map((e) => e.text).join(' | ');
    }).join('\n');
  } finally {
    await recognizer.close();
  }
}

class _Piece {
  _Piece(this.text, this.left, this.cy, this.h);
  final String text;
  final double left;
  final double cy;
  final double h;
}
