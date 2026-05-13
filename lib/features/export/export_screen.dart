import 'package:flutter/material.dart';

import '../../database/database_service.dart';
import '../../models/cpd_activity.dart';
import '../../models/recertification_cycle.dart';
import '../../theme/app_theme.dart';
import 'export_service.dart';

enum _ExportType { pdf, excel }

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ExportService _exportService = const ExportService();
  final DatabaseService _databaseService = DatabaseService.instance;
  bool _isExporting = false;
  _ExportType _selectedFormat = _ExportType.pdf;

  Future<_ExportViewData> _loadView() async {
    final cycle = await _databaseService.getActiveCycle();
    if (cycle?.id == null) {
      return const _ExportViewData(
          cycle: null, activities: [], totalPoints: 0);
    }
    final activities =
        await _databaseService.getActivitiesByCycle(cycle!.id!);
    final totalPoints =
        await _databaseService.getTotalPointsByCycle(cycle.id!);
    return _ExportViewData(
      cycle: cycle,
      activities: activities,
      totalPoints: totalPoints,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_ExportViewData>(
        future: _loadView(),
        builder: (context, snapshot) {
          final view = snapshot.data;
          if (view == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final hasActivities = view.activities.isNotEmpty;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(
                showBack: Navigator.of(context).canPop(),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCard(view: view),
                    const SizedBox(height: 18),
                    Text(
                      'Choose format',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _FormatCard(
                            icon: Icons.picture_as_pdf,
                            iconColor: AppColors.error,
                            title: 'PDF Format',
                            subtitle: 'Best for submitting to AIDH',
                            selected: _selectedFormat == _ExportType.pdf,
                            onTap: () => setState(
                                () => _selectedFormat = _ExportType.pdf),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FormatCard(
                            icon: Icons.table_chart,
                            iconColor: AppColors.success,
                            title: 'Excel Format',
                            subtitle: 'Best for your own records',
                            selected: _selectedFormat == _ExportType.excel,
                            onTap: () => setState(
                                () => _selectedFormat = _ExportType.excel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: (_isExporting || !hasActivities)
                            ? null
                            : () => _runExport(_selectedFormat),
                        icon: _isExporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _selectedFormat == _ExportType.pdf
                                    ? Icons.picture_as_pdf
                                    : Icons.table_chart,
                                size: 20,
                              ),
                        label: Text(
                          _selectedFormat == _ExportType.pdf
                              ? 'Export as PDF'
                              : 'Export as Excel',
                        ),
                      ),
                    ),
                    if (!hasActivities) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Add at least one activity before exporting.',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _SubmissionReminder(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
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
      final exportData =
          await _databaseService.getExportData(activeCycle!.id!);
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

class _Header extends StatelessWidget {
  const _Header({required this.showBack, required this.onBack});

  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(showBack ? 8 : 20, showBack ? 8 : 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                tooltip: 'Back',
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: showBack ? 12 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.file_download_outlined,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export CPD Journal',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Download your CPD record as PDF or Excel to submit for recertification.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.view});

  final _ExportViewData view;

  @override
  Widget build(BuildContext context) {
    final hasActivities = view.activities.isNotEmpty;
    final progress = view.cycle == null || view.cycle!.targetPoints == 0
        ? 0.0
        : (view.totalPoints / view.cycle!.targetPoints)
            .clamp(0.0, 1.0)
            .toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: hasActivities ? AppColors.success : AppColors.textHint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasActivities ? 'Ready to export' : 'Nothing to export yet',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.assignment_outlined,
                  size: 18, color: AppColors.textHint),
              const SizedBox(width: 8),
              Text(
                '${view.activities.length} ${view.activities.length == 1 ? 'activity' : 'activities'} recorded',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.show_chart,
                  size: 18, color: AppColors.textHint),
              const SizedBox(width: 8),
              Text(
                '${view.totalPoints.toStringAsFixed(1)} / 60 pts total',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: AppColors.primary,
              backgroundColor: AppColors.border,
            ),
          ),
          if (view.cycle != null) ...[
            const SizedBox(height: 10),
            Text(
              '${view.cycle!.cycleName} · ${view.cycle!.startDate} → ${view.cycle!.endDate}',
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'Selected',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmissionReminder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to submit',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'After exporting, email your journal to certification@digitalhealth.org.au '
                  'along with payment of the recertification fee.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportViewData {
  const _ExportViewData({
    required this.cycle,
    required this.activities,
    required this.totalPoints,
  });

  final RecertificationCycle? cycle;
  final List<CpdActivity> activities;
  final double totalPoints;
}
