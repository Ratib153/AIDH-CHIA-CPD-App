import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../utils/format_points.dart';

/// PDF/Excel export result; [path] is null if the user cancelled Save As.
class ExportResult {
  const ExportResult({required this.path, this.cancelled = false});

  final String? path;
  final bool cancelled;

  bool get success => path != null && path!.isNotEmpty;
}

class ExportService {
  const ExportService();

  static const _sheetName = 'CPD Export';

  Future<ExportResult> exportToPdf({
    required Map<String, dynamic> exportData,
    required Map<int, Map<String, double>> categoryTotals,
    String? fileName,
  }) async {
    final cycle = exportData['cycle'] as Map<String, dynamic>;
    final activityRows =
        List<Map<String, dynamic>>.from(exportData['activities'] as List);
    final grouped = _groupActivitiesByCategory(activityRows);

    final totalClaimed = activityRows.fold<double>(
      0,
      (sum, row) => sum + ((row['pointsClaimed'] as num?)?.toDouble() ?? 0),
    );
    final totalEffective = (cycle['totalPoints'] as num?)?.toDouble() ?? 0;
    final targetPoints = (cycle['targetPoints'] as num?)?.toDouble() ?? 60;

    final tableRows = <List<String>>[];
    for (final categoryId in grouped.keys) {
      final rows = grouped[categoryId]!;
      for (final activity in rows) {
        tableRows.add([
          activity['activityDescription'] as String? ?? '',
          activity['categoryName'] as String? ?? '',
          _formatDomainShort(activity['competencyDomain'] as String?),
          activity['dateLogged'] as String? ?? '',
          formatPoints((activity['pointsClaimed'] as num?)?.toDouble() ?? 0),
          formatPoints(_effectivePointsForActivity(activity, categoryTotals)),
          activity['evidenceNote'] as String? ?? '',
        ]);
      }
      final claimed = categoryTotals[categoryId]?['claimed'] ?? 0;
      final effective = categoryTotals[categoryId]?['effective'] ?? 0;
      if (claimed > effective) {
        tableRows.add([
          '',
          '',
          '',
          '',
          '',
          '',
          '⚠ Cap exceeded: only ${formatPoints(effective)} of ${formatPoints(claimed)} pts count',
        ]);
      }
    }

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) {
          return [
            pw.Text(
              'CHIA CPD Activities Export',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Cycle: ${cycle['name']}'),
            pw.Text(
              'Period: ${cycle['startDate']} → ${cycle['endDate']}',
            ),
            pw.Text('Total activities: ${activityRows.length}'),
            pw.Text(
              'Total points claimed: ${formatPoints(totalClaimed)} · '
              'Counted toward recertification: ${formatPoints(totalEffective)} / ${formatPoints(targetPoints)}',
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Title',
                'Category',
                'Domain',
                'Date',
                'Pts Claimed',
                'Pts Counted',
                'Notes',
              ],
              data: tableRows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue700),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.centerLeft,
              },
            ),
            pw.SizedBox(height: 16),
            _buildPdfSummaryBox(
              cycle: cycle,
              totalClaimed: totalClaimed,
              totalEffective: totalEffective,
              targetPoints: targetPoints,
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Domain legend: A = Health Sciences · B = Information Science · '
              'C = Information Technology · D = Leadership and Management · '
              'E = Social and Behavioural Sciences · F = Core Health Informatics',
              style: pw.TextStyle(
                fontSize: 7,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await document.save();
    return _saveFile(
      bytes: bytes,
      fileName: fileName ??
          'chia_cpd_export_${DateTime.now().millisecondsSinceEpoch}',
      extension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  pw.Widget _buildPdfSummaryBox({
    required Map<String, dynamic> cycle,
    required double totalClaimed,
    required double totalEffective,
    required double targetPoints,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue800),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CPD SUMMARY',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Cycle: ${cycle['name']}'),
          pw.Text(
            'Period: ${cycle['startDate']} to ${cycle['endDate']}',
          ),
          pw.SizedBox(height: 6),
          pw.Text('Total points claimed: ${formatPoints(totalClaimed)}'),
          pw.Text(
            'Total points counted toward recertification: '
            '${formatPoints(totalEffective)} / ${formatPoints(targetPoints)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (totalEffective >= targetPoints)
            pw.Text(
              '✓ Recertification requirement met.',
              style: pw.TextStyle(
                color: PdfColors.green800,
                fontWeight: pw.FontWeight.bold,
              ),
            )
          else
            pw.Text(
              '✗ Recertification requirement not yet met '
              '(${formatPoints(targetPoints - totalEffective)} pts remaining).',
              style: const pw.TextStyle(color: PdfColors.red800),
            ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Note: Points exceeding category caps do not count toward the '
            '60-point recertification total. Excess points are shown for '
            'record-keeping purposes only.',
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Future<ExportResult> exportToExcel({
    required Map<String, dynamic> exportData,
    required Map<int, Map<String, double>> categoryTotals,
    String? fileName,
  }) async {
    final cycle = exportData['cycle'] as Map<String, dynamic>;
    final activityRows =
        List<Map<String, dynamic>>.from(exportData['activities'] as List);
    final grouped = _groupActivitiesByCategory(activityRows);

    final excel = Excel.createExcel();
    if (excel.sheets.containsKey('Sheet1')) {
      excel.rename('Sheet1', _sheetName);
    }
    final sheet = excel[_sheetName];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#0082C8'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    final summaryStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#F3F4F6'),
    );

    const headers = [
      'Title',
      'Category',
      'Domain',
      'Date',
      'Points Claimed',
      'Points Counted',
      'Notes',
    ];
    for (var col = 0; col < headers.length; col++) {
      _setCell(
        sheet,
        col,
        0,
        TextCellValue(headers[col]),
        style: headerStyle,
      );
    }

    var rowIndex = 1;
    for (final categoryId in grouped.keys) {
      final rows = grouped[categoryId]!;
      for (final activity in rows) {
        _writeActivityRow(sheet, rowIndex, activity, categoryTotals);
        rowIndex++;
      }

      final claimed = categoryTotals[categoryId]?['claimed'] ?? 0;
      final effective = categoryTotals[categoryId]?['effective'] ?? 0;
      final isCapped = claimed > effective;
      final summaryLabel = isCapped
          ? 'Category $categoryId total (cap: ${formatPoints(effective)} of ${formatPoints(claimed)} count):'
          : 'Category $categoryId total:';

      _setCell(sheet, 3, rowIndex, TextCellValue(summaryLabel), style: summaryStyle);
      _setCell(sheet, 4, rowIndex, DoubleCellValue(claimed), style: summaryStyle);
      _setCell(sheet, 5, rowIndex, DoubleCellValue(effective), style: summaryStyle);
      rowIndex++;
    }

    final totalClaimed = activityRows.fold<double>(
      0,
      (sum, row) => sum + ((row['pointsClaimed'] as num?)?.toDouble() ?? 0),
    );
    final totalEffective = (cycle['totalPoints'] as num?)?.toDouble() ?? 0;
    final targetPoints = (cycle['targetPoints'] as num?)?.toDouble() ?? 60;

    rowIndex++;
    _setCell(sheet, 3, rowIndex, TextCellValue('TOTAL POINTS CLAIMED:'),
        style: summaryStyle);
    _setCell(sheet, 4, rowIndex, DoubleCellValue(totalClaimed), style: summaryStyle);
    rowIndex++;
    _setCell(
      sheet,
      3,
      rowIndex,
      TextCellValue('TOTAL POINTS COUNTED TOWARD RECERTIFICATION:'),
      style: summaryStyle,
    );
    _setCell(sheet, 5, rowIndex, DoubleCellValue(totalEffective), style: summaryStyle);
    rowIndex++;
    _setCell(sheet, 3, rowIndex, TextCellValue('TARGET:'), style: summaryStyle);
    _setCell(sheet, 5, rowIndex, DoubleCellValue(targetPoints), style: summaryStyle);

    for (var col = 0; col < headers.length; col++) {
      sheet.setColumnWidth(col, col == 0 ? 28.0 : 16.0);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to generate Excel bytes.');
    }

    return _saveFile(
      bytes: Uint8List.fromList(bytes),
      fileName: fileName ??
          'chia_cpd_export_${DateTime.now().millisecondsSinceEpoch}',
      extension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  void _writeActivityRow(
    Sheet sheet,
    int rowIndex,
    Map<String, dynamic> activity,
    Map<int, Map<String, double>> categoryTotals,
  ) {
    _setCell(
      sheet,
      0,
      rowIndex,
      TextCellValue(activity['activityDescription'] as String? ?? ''),
    );
    _setCell(
      sheet,
      1,
      rowIndex,
      TextCellValue(activity['categoryName'] as String? ?? ''),
    );
    _setCell(
      sheet,
      2,
      rowIndex,
      TextCellValue(_formatDomainForExport(activity['competencyDomain'] as String?)),
    );
    _setCell(
      sheet,
      3,
      rowIndex,
      TextCellValue(activity['dateLogged'] as String? ?? ''),
    );
    _setCell(
      sheet,
      4,
      rowIndex,
      DoubleCellValue((activity['pointsClaimed'] as num?)?.toDouble() ?? 0),
    );
    _setCell(
      sheet,
      5,
      rowIndex,
      DoubleCellValue(_effectivePointsForActivity(activity, categoryTotals)),
    );
    _setCell(
      sheet,
      6,
      rowIndex,
      TextCellValue(activity['evidenceNote'] as String? ?? ''),
    );
  }

  void _setCell(
    Sheet sheet,
    int columnIndex,
    int rowIndex,
    CellValue value, {
    CellStyle? style,
  }) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: rowIndex));
    cell.value = value;
    if (style != null) {
      cell.cellStyle = style;
    }
  }

  Map<int, List<Map<String, dynamic>>> _groupActivitiesByCategory(
    List<Map<String, dynamic>> activities,
  ) {
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final activity in activities) {
      final categoryId = activity['categoryId'] as int? ?? 0;
      grouped.putIfAbsent(categoryId, () => []).add(activity);
    }
    final keys = grouped.keys.toList()..sort();
    return {for (final key in keys) key: grouped[key]!};
  }

  double _effectivePointsForActivity(
    Map<String, dynamic> activity,
    Map<int, Map<String, double>> categoryTotals,
  ) {
    final categoryId = activity['categoryId'] as int? ?? 0;
    final pointsClaimed = (activity['pointsClaimed'] as num?)?.toDouble() ?? 0.0;

    final totals = categoryTotals[categoryId];
    if (totals == null) return pointsClaimed;

    final categoryClaimed = totals['claimed'] ?? 0.0;
    final categoryEffective = totals['effective'] ?? 0.0;

    if (categoryClaimed <= categoryEffective) return pointsClaimed;
    if (categoryClaimed == 0) return 0.0;

    return truncatePoints(
      pointsClaimed * (categoryEffective / categoryClaimed),
      2,
    );
  }

  String _formatDomainForExport(String? domainCode) {
    if (domainCode == null || domainCode.isEmpty) return '—';
    const domainNames = {
      'A': 'A — Health Sciences',
      'B': 'B — Information Science',
      'C': 'C — Information Technology',
      'D': 'D — Leadership and Management',
      'E': 'E — Social and Behavioural Sciences',
      'F': 'F — Core Health Informatics',
    };
    return domainNames[domainCode.toUpperCase()] ?? domainCode;
  }

  String _formatDomainShort(String? domainCode) {
    if (domainCode == null || domainCode.isEmpty) return '—';
    return domainCode.toUpperCase();
  }

  Future<ExportResult> _saveFile({
    required Uint8List bytes,
    required String fileName,
    required String extension,
    required MimeType mimeType,
  }) async {
    try {
      final result = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: bytes,
        ext: extension,
        mimeType: mimeType,
      );

      if (result == null || result.isEmpty) {
        return const ExportResult(path: null, cancelled: true);
      }
      return ExportResult(path: result);
    } catch (_) {
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
}
