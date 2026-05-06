import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/cpd_activity.dart';

class ExportService {
  const ExportService();

  Future<void> exportToPdf(List<CpdActivity> activities) async {
    final document = pw.Document();
    final totalPoints = activities.fold<int>(0, (sum, item) => sum + item.points);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return [
            pw.Text(
              'CHIA CPD Activities Export',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Total activities: ${activities.length}'),
            pw.Text('Total points: $totalPoints'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const ['Title', 'Category', 'Date', 'Points', 'Notes'],
              data: activities
                  .map(
                    (activity) => [
                      activity.title,
                      activity.category,
                      _formatDate(activity.date),
                      activity.points.toString(),
                      activity.notes ?? '',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            ),
          ];
        },
      ),
    );

    final bytes = await document.save();
    await _saveFile(
      bytes: bytes,
      fileName: 'chia_cpd_export_${DateTime.now().millisecondsSinceEpoch}',
      extension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  Future<void> exportToExcel(List<CpdActivity> activities) async {
    final excel = Excel.createExcel();
    final sheet = excel['CPD Export'];
    sheet.appendRow([
      TextCellValue('Title'),
      TextCellValue('Category'),
      TextCellValue('Date'),
      TextCellValue('Points'),
      TextCellValue('Notes'),
    ]);

    for (final activity in activities) {
      sheet.appendRow([
        TextCellValue(activity.title),
        TextCellValue(activity.category),
        TextCellValue(_formatDate(activity.date)),
        IntCellValue(activity.points),
        TextCellValue(activity.notes ?? ''),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to generate Excel bytes.');
    }

    await _saveFile(
      bytes: Uint8List.fromList(bytes),
      fileName: 'chia_cpd_export_${DateTime.now().millisecondsSinceEpoch}',
      extension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Future<void> _saveFile({
    required Uint8List bytes,
    required String fileName,
    required String extension,
    required MimeType mimeType,
  }) async {
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: extension,
      mimeType: mimeType,
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
