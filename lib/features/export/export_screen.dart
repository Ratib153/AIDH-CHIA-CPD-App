import 'package:flutter/material.dart';

import '../../database/database_service.dart';
import '../../models/cpd_activity.dart';
import 'export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ExportService _exportService = const ExportService();
  final DatabaseService _databaseService = DatabaseService.instance;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export CPD Data', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Export all recorded activities as PDF or Excel.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<CpdActivity>>(
              future: _loadActiveCycleActivities(),
              builder: (context, snapshot) {
                final activities = snapshot.data ?? <CpdActivity>[];
                final totalPoints = activities.fold<double>(
                  0,
                  (sum, item) => sum + item.pointsClaimed,
                );
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ready to export', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Text('Activities: ${activities.length}'),
                        Text('Total points: ${totalPoints.toStringAsFixed(1)}'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : () => _runExport(_ExportType.pdf),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Export as PDF'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isExporting ? null : () => _runExport(_ExportType.excel),
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Export as Excel'),
              ),
            ),
            if (_isExporting) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Future<List<CpdActivity>> _loadActiveCycleActivities() async {
    final activeCycle = await _databaseService.getActiveCycle();
    if (activeCycle?.id == null) {
      return [];
    }
    return _databaseService.getActivitiesByCycle(activeCycle!.id!);
  }

  Future<void> _runExport(_ExportType type) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isExporting = true;
    });

    try {
      final activeCycle = await _databaseService.getActiveCycle();
      if (activeCycle?.id == null) {
        throw Exception('No active cycle found for export.');
      }
      final exportData = await _databaseService.getExportData(activeCycle!.id!);
      final activities = (exportData['activities'] as List<dynamic>)
          .map((row) => CpdActivity(
                id: row['id'] as int?,
                cycleId: activeCycle.id!,
                dateLogged: row['dateLogged'] as String,
                categoryId: row['categoryId'] as int,
                categoryName: row['categoryName'] as String,
                subcategory: row['subcategory'] as String?,
                activityDescription: row['activityDescription'] as String,
                providerName: row['providerName'] as String?,
                durationHours: (row['durationHours'] as num?)?.toDouble(),
                pointsClaimed: (row['pointsClaimed'] as num).toDouble(),
                competencyDomain: row['competencyDomain'] as String?,
                evidenceNote: row['evidenceNote'] as String?,
                deletedAt: null,
                createdAt: DateTime.now().toIso8601String(),
                updatedAt: DateTime.now().toIso8601String(),
              ))
          .toList();

      if (type == _ExportType.pdf) {
        await _exportService.exportToPdf(activities);
      } else {
        await _exportService.exportToExcel(activities);
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            type == _ExportType.pdf
                ? 'PDF export saved successfully.'
                : 'Excel export saved successfully.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Export failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}

enum _ExportType { pdf, excel }
