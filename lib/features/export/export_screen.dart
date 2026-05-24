import 'package:flutter/material.dart';

import '../../database/database_service.dart';
import '../../models/cpd_activity.dart';
import '../../models/recertification_cycle.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_extension.dart';
import '../../theme/ui_polish.dart';
import '../../utils/format_points.dart';
import 'export_service.dart';

enum _ExportType { pdf, excel }

enum _CycleStatus { active, completed, archived }

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ExportService _exportService = const ExportService();
  final DatabaseService _databaseService = DatabaseService.instance;

  List<RecertificationCycle> _allCycles = [];
  RecertificationCycle? _selectedCycle;
  Map<int, double> _cyclePoints = {};
  _ExportViewData? _exportView;
  bool _isLoadingCycles = true;
  bool _isLoadingSummary = false;
  bool _isExporting = false;
  bool _exportSuccess = false;
  _ExportType _selectedFormat = _ExportType.pdf;

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    try {
      final cycles = await _databaseService.getAllCycles();
      final activeCycle = await _databaseService.getActiveCycle();
      final pointsByCycle = <int, double>{};
      for (final cycle in cycles) {
        if (cycle.id != null) {
          pointsByCycle[cycle.id!] =
              await _databaseService.getTotalPointsByCycle(cycle.id!);
        }
      }

      final selected = activeCycle ?? (cycles.isNotEmpty ? cycles.first : null);

      if (!mounted) return;
      setState(() {
        _allCycles = cycles;
        _selectedCycle = selected;
        _cyclePoints = pointsByCycle;
        _isLoadingCycles = false;
      });
      await _loadExportSummary();
    } catch (_) {
      if (mounted) setState(() => _isLoadingCycles = false);
    }
  }

  Future<void> _loadExportSummary() async {
    final selected = _selectedCycle;
    if (selected?.id == null) {
      if (mounted) {
        setState(() {
          _exportView = const _ExportViewData(
            cycle: null,
            activities: [],
            totalPoints: 0,
          );
        });
      }
      return;
    }

    setState(() => _isLoadingSummary = true);
    try {
      final activities =
          await _databaseService.getActivitiesByCycle(selected!.id!);
      final totalPoints =
          await _databaseService.getTotalPointsByCycle(selected.id!);
      if (!mounted) return;
      setState(() {
        _exportView = _ExportViewData(
          cycle: selected,
          activities: activities,
          totalPoints: totalPoints,
        );
        _isLoadingSummary = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  Future<void> _selectCycle(RecertificationCycle cycle) async {
    setState(() => _selectedCycle = cycle);
    await _loadExportSummary();
  }

  _CycleStatus _cycleStatus(RecertificationCycle cycle) {
    if (cycle.isActive) return _CycleStatus.active;
    final today = DateTime.now();
    final end = DateTime.tryParse(cycle.endDate);
    if (end == null) return _CycleStatus.archived;
    final endDay = DateTime(end.year, end.month, end.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    if (endDay.isBefore(todayDay)) return _CycleStatus.completed;
    return _CycleStatus.archived;
  }

  String _exportHeading(_CycleStatus status, bool hasActivities) {
    if (!hasActivities) return 'Nothing to export yet';
    return switch (status) {
      _CycleStatus.active => 'Ready to export — Active Cycle',
      _CycleStatus.completed => 'Ready to export — Completed Cycle',
      _CycleStatus.archived => 'Ready to export — Archived Cycle',
    };
  }

  String _exportFileName() {
    final cycleSlug = (_selectedCycle?.cycleName ?? 'cycle')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    return 'chia_cpd_${cycleSlug.isEmpty ? 'cycle' : cycleSlug}_$dateStr';
  }

  Future<void> _runExport(_ExportType type) async {
    final messenger = ScaffoldMessenger.of(context);

    if (_selectedCycle?.id == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a cycle to export.')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final selectedCycle = _selectedCycle!;
      final exportData =
          await _databaseService.getExportData(selectedCycle.id!);
      final categoryTotals =
          await _databaseService.getPointsByCategory(selectedCycle.id!);

      final fileName = _exportFileName();
      final result = type == _ExportType.pdf
          ? await _exportService.exportToPdf(
              exportData: exportData,
              categoryTotals: categoryTotals,
              fileName: fileName,
            )
          : await _exportService.exportToExcel(
              exportData: exportData,
              categoryTotals: categoryTotals,
              fileName: fileName,
            );

      if (!mounted) return;
      if (result.cancelled) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Export cancelled.')),
        );
      } else if (result.success) {
        final label = type == _ExportType.pdf ? 'PDF' : 'Excel';
        if (kUsePolishedUI) {
          setState(() => _exportSuccess = true);
          Future<void>.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _exportSuccess = false);
          });
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Saved as $label.\n${result.path}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Export did not complete. Please try a different location.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Export failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    if (_isLoadingCycles) {
      return ColoredBox(
        color: bg,
        child: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_allCycles.isEmpty) {
      return ColoredBox(
        color: bg,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const _Header(),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.hourglass_empty,
                        size: 48, color: context.appExt.textHint),
                    const SizedBox(height: 12),
                    Text(
                      'No cycles found. Add activities to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.appExt.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final view = _exportView;
    final hasActivities = view?.activities.isNotEmpty ?? false;
    final selectedStatus = _selectedCycle == null
        ? _CycleStatus.active
        : _cycleStatus(_selectedCycle!);
    final showPastCycleBanner =
        _selectedCycle != null && !_selectedCycle!.isActive;

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _Header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Select Cycle to Export',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.appExt.textPrimary,
                ),
              ),
            ),
            if (_allCycles.length == 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Only one cycle found. Start a new cycle from your Profile screen.',
                  style: TextStyle(
                    color: context.appExt.textHint,
                    fontSize: 12,
                  ),
                ),
              ),
            for (final cycle in _allCycles)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _CycleSelectCard(
                  cycle: cycle,
                  selected: _selectedCycle?.id == cycle.id,
                  totalPoints: cycle.id == null ? 0 : (_cyclePoints[cycle.id!] ?? 0),
                  status: _cycleStatus(cycle),
                  onTap: () => _selectCycle(cycle),
                ),
              ),
            if (showPastCycleBanner) const _AuditReminderBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingSummary || view == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _SummaryCard(
                      view: view,
                      heading: _exportHeading(selectedStatus, hasActivities),
                    ),
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
                              () => _selectedFormat = _ExportType.pdf,
                            ),
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
                              () => _selectedFormat = _ExportType.excel,
                            ),
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
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                            : (kUsePolishedUI && _exportSuccess)
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : Icon(
                                    _selectedFormat == _ExportType.pdf
                                        ? Icons.picture_as_pdf
                                        : Icons.table_chart,
                                    size: 20,
                                  ),
                        label: (kUsePolishedUI && _exportSuccess)
                            ? const Text('Exported!')
                            : Text(
                                _selectedFormat == _ExportType.pdf
                                    ? 'Export as PDF'
                                    : 'Export as Excel',
                              ),
                      ),
                    ),
                    if (!hasActivities) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Add at least one activity in this cycle before exporting.',
                        style: TextStyle(
                          color: context.appExt.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 22),
                  const _SubmissionReminder(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  } catch (_) {
    return isoDate;
  }
}

class _CycleSelectCard extends StatelessWidget {
  const _CycleSelectCard({
    required this.cycle,
    required this.selected,
    required this.totalPoints,
    required this.status,
    required this.onTap,
  });

  final RecertificationCycle cycle;
  final bool selected;
  final double totalPoints;
  final _CycleStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = cycle.targetPoints == 0
        ? 0.0
        : (totalPoints / cycle.targetPoints).clamp(0.0, 1.0).toDouble();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? context.appExt.primaryTint : context.appExt.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : context.appExt.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? null : context.appExt.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.primary : context.appExt.textHint,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cycle.cycleName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.appExt.textPrimary,
                            ),
                          ),
                        ),
                        _CycleStatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(cycle.startDate)} → ${_formatDate(cycle.endDate)}',
                      style: TextStyle(
                        color: context.appExt.textHint,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatPoints(totalPoints)} / ${formatPoints(cycle.targetPoints)} pts',
                      style: TextStyle(
                        color: context.appExt.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        color: AppColors.primary,
                        backgroundColor: context.appExt.border,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CycleStatusBadge extends StatelessWidget {
  const _CycleStatusBadge({required this.status});

  final _CycleStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      _CycleStatus.active => (
          const Color(0xFFD1FAE5),
          const Color(0xFF059669),
          '● Active',
        ),
      _CycleStatus.completed => (
          const Color(0xFFE6F3FB),
          AppColors.primary,
          '✓ Completed',
        ),
      _CycleStatus.archived => (
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280),
          'Archived',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AuditReminderBanner extends StatelessWidget {
  const _AuditReminderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exporting a past cycle',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'CHIA conducts random audits. If selected, you have 28 days '
                  'to provide evidence of activities in this cycle. '
                  'Submit completed cycle journals to certification@digitalhealth.org.au.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.appExt.header,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.appExt.primaryTint,
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
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.view, required this.heading});

  final _ExportViewData view;
  final String heading;

  @override
  Widget build(BuildContext context) {
    final ext = context.appExt;
    final hasActivities = view.activities.isNotEmpty;
    final target = view.cycle?.targetPoints ?? 60;
    final progress = target == 0
        ? 0.0
        : (view.totalPoints / target).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appExt.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.appExt.cardShadow,
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
                  color: hasActivities ? AppColors.success : ext.textHint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  heading,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (view.cycle != null) ...[
            const SizedBox(height: 6),
            Text(
              view.cycle!.cycleName,
              style: TextStyle(
                fontSize: 13,
                color: ext.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 18, color: ext.textHint),
              const SizedBox(width: 8),
              Text(
                '${view.activities.length} ${view.activities.length == 1 ? 'activity' : 'activities'} recorded',
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.show_chart, size: 18, color: ext.textHint),
              const SizedBox(width: 8),
              Text(
                '${formatPoints(view.totalPoints)} / ${formatPoints(target)} pts total',
                style: TextStyle(
                  color: ext.textSecondary,
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
              backgroundColor: ext.border,
            ),
          ),
          if (view.cycle != null) ...[
            const SizedBox(height: 10),
            Text(
              '${_formatDate(view.cycle!.startDate)} → ${_formatDate(view.cycle!.endDate)}',
              style: TextStyle(
                color: ext.textHint,
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
    final ext = context.appExt;
    final radius = kUsePolishedUI ? 12.0 : 16.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? ext.primaryTint : ext.card,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: selected ? AppColors.primary : ext.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: ext.cardShadow,
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
                style: TextStyle(
                  color: ext.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: ext.textHint,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
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
  const _SubmissionReminder();

  @override
  Widget build(BuildContext context) {
    final ext = context.appExt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.primaryTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ext.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 22),
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
                Text(
                  'After exporting, email your journal to certification@digitalhealth.org.au '
                  'along with payment of the recertification fee.',
                  style: TextStyle(
                    color: ext.textSecondary,
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
