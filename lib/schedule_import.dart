import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import 'models.dart';
import 'schedule_parser.dart';

class ImportResult {
  ImportResult(this.fileName, this.entries, [this.error]);
  final String fileName;
  final List<ParsedEntry> entries;
  final String? error;
}

const allowedScheduleExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'csv', 'xlsx', 'txt', 'ics'];

/// Buka pemilih file, lalu baca jadwal di dalamnya.
/// Mengembalikan null kalau pengguna membatalkan.
Future<ImportResult?> pickAndReadSchedule() async {
  // FileType.any: filter ekstensi di Android bisa gagal untuk tipe file
  // yang tidak dikenali HP (penyebab error "getClass on a null object").
  final res = await FilePicker.platform.pickFiles(type: FileType.any);
  if (res == null || res.files.isEmpty) return null;
  final f = res.files.single;
  final name = f.name;
  final ext = (f.extension ?? name.split('.').last).toLowerCase();
  if (!allowedScheduleExtensions.contains(ext)) {
    return ImportResult(name, [],
        'Format .$ext belum didukung. Gunakan PDF, foto (JPG/PNG), Excel (.xlsx), CSV, TXT, atau .ics.');
  }
  try {
    List<ParsedEntry> entries;
    final path = f.path;
    Future<List<int>> readBytes() async =>
        f.bytes ?? (path != null ? await File(path).readAsBytes() : <int>[]);
    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
      if (path == null) {
        return ImportResult(name, [], 'Foto tidak bisa dibuka dari lokasi ini.');
      }
      entries = parseScheduleText(await _ocr(path));
    } else if (ext == 'pdf') {
      entries = parseScheduleText(await _pdfText(await readBytes()));
    } else {
      final bytes = await readBytes();
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

/// PDF: setiap halaman (maks. 3) diubah jadi gambar, lalu dibaca seperti foto.
Future<String> _pdfText(List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  final parts = <String>[];
  var i = 0;
  await for (final page in Printing.raster(Uint8List.fromList(bytes), dpi: 200)) {
    if (i >= 3) break;
    final png = await page.toPng();
    final file = File('${dir.path}/ayosehat_pdf_${i++}.png');
    await file.writeAsBytes(png, flush: true);
    parts.add(await _ocr(file.path));
  }
  return parts.join('\n');
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
