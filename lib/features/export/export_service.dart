import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/cpd_activity.dart';

/// Result of an export operation.
///
/// `path` is `null` when the user cancelled the system Save As dialog.
/// `cancelled` distinguishes a deliberate cancel from a real failure.
class ExportResult {
  const ExportResult({required this.path, this.cancelled = false});

  final String? path;
  final bool cancelled;

  bool get success => path != null && path!.isNotEmpty;
}

class ExportService {
  const ExportService();

  Future<ExportResult> exportToPdf(List<CpdActivity> activities) async {
    final document = pw.Document();
    final totalPoints = activities.fold<double>(
      0,
      (sum, item) => sum + item.pointsClaimed,
    );

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
            pw.Text('Total points: ${_formatPoints(totalPoints)}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const ['Title', 'Category', 'Date', 'Points', 'Notes'],
              data: activities
                  .map(
                    (activity) => [
                      activity.title,
                      activity.category,
                      _formatDate(activity.date),
                      _formatPoints(activity.pointsClaimed),
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
    return _saveFile(
      bytes: bytes,
      fileName: 'chia_cpd_export_${DateTime.now().millisecondsSinceEpoch}',
      extension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  Future<ExportResult> exportToExcel(List<CpdActivity> activities) async {
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
        DoubleCellValue(activity.pointsClaimed),
        TextCellValue(activity.notes ?? ''),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to generate Excel bytes.');
    }

    return _saveFile(
      bytes: Uint8List.fromList(bytes),
      fileName: 'chia_cpd_export_${DateTime.now().millisecondsSinceEpoch}',
      extension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Future<ExportResult> _saveFile({
    required Uint8List bytes,
    required String fileName,
    required String extension,
    required MimeType mimeType,
  }) async {
    // `saveAs` opens the platform's native save dialog (Android: SAF; iOS:
    // share/save sheet; desktop: native Save As; web: triggers download).
    // This is more reliable than `saveFile` which silently writes to private
    // app storage on Android 10+ (scoped storage) where users cannot find it.
    try {
      final result = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: bytes,
        ext: extension,
        mimeType: mimeType,
      );

      // file_saver returns an empty string when the user cancels the dialog.
      if (result == null || result.isEmpty) {
        return const ExportResult(path: null, cancelled: true);
      }
      return ExportResult(path: result);
    } catch (_) {
      // Some platforms (notably web) don't implement `saveAs` and throw.
      // Fall back to the silent `saveFile` so the export still completes.
      final fallback = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: extension,
        mimeType: mimeType,
      );
      if (fallback.isEmpty) {
        return const ExportResult(path: null, cancelled: false);
      }
      return ExportResult(path: fallback);
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Matches dashboard display: whole numbers without ".0", fractions kept.
  String _formatPoints(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}
