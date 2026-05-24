import 'package:flutter/material.dart';

import '../../constants/cpd_categories.dart';
import '../../database/database_service.dart';
import '../../models/cpd_activity.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_extension.dart';
import '../../theme/theme_controller.dart';
import '../activities/activity_list_screen.dart';
import '../activities/add_activity_screen.dart';
import '../../navigation/app_navigator.dart';
import '../scan/qr_scanner_screen.dart';
import '../../utils/format_points.dart';
import '../../widgets/category_info_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  bool _userDataReady = false;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  Future<void> _initUserData() async {
    await DatabaseService.instance.seedDefaultCycleIfNeeded();
    await ThemeController.instance.load();
    if (mounted) {
      setState(() => _userDataReady = true);
    }
  }

  Future<_DashboardData> _loadData() async {
    final cycle = await _databaseService.getActiveCycle();
    if (cycle?.id == null) {
      return const _DashboardData.empty();
    }

    final activities = await _databaseService.getActivitiesByCycle(cycle!.id!);
    final totalPoints = await _databaseService.getTotalPointsByCycle(cycle.id!);
    final pointsByCategory = await _databaseService.getPointsByCategory(cycle.id!);
    final domainTotals = <String, double>{
      for (final d in ['A', 'B', 'C', 'D', 'E', 'F']) d: 0
    };
    for (final activity in activities) {
      final code = activity.competencyDomain;
      if (code != null && domainTotals.containsKey(code)) {
        domainTotals[code] = domainTotals[code]! + activity.pointsClaimed;
      }
    }

    return _DashboardData(
      cycleName: cycle.cycleName,
      endDate: cycle.endDate,
      targetPoints: cycle.targetPoints,
      totalPoints: totalPoints,
      pointsByCategory: pointsByCategory,
      domainTotals: domainTotals,
      recentActivities: activities.take(3).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_userDataReady) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      child: FutureBuilder<_DashboardData>(
        future: _loadData(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _Header(cycleName: data.cycleName),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroProgressCard(data: data),
                      const SizedBox(height: 16),
                      _QuickActionsRow(onChanged: () => setState(() {})),
                      const SizedBox(height: 24),
                      _SectionHeading('Category Breakdown'),
                      const SizedBox(height: 12),
                      _CategoryList(pointsByCategory: data.pointsByCategory),
                      const SizedBox(height: 24),
                      _SectionHeading('Competency Domains'),
                      const SizedBox(height: 12),
                      _DomainGrid(domainTotals: data.domainTotals),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionHeading('Recent Activities'),
                          if (data.recentActivities.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ActivityListScreen(),
                                  ),
                                );
                              },
                              child: const Text('View all  →'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _RecentActivitiesList(activities: data.recentActivities),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cycleName});

  final String cycleName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.appExt.header,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChiaBrandMark(),
          const SizedBox(height: 14),
          Text(
            'CHIA CPD Tracker',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 2),
          Text(
            'Active cycle · $cycleName',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Official CHIA horizontal wordmark (Certified Health Informatician Australasia).
class _ChiaBrandMark extends StatelessWidget {
  const _ChiaBrandMark();

  static const _logoAsset = 'assets/images/chia_logo.png';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        _logoAsset,
        height: 48,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _HeroProgressCard extends StatelessWidget {
  const _HeroProgressCard({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final progress = data.targetPoints == 0
        ? 0.0
        : (data.totalPoints / data.targetPoints).clamp(0.0, 1.0).toDouble();
    final remaining =
        (data.targetPoints - data.totalPoints).clamp(0, data.targetPoints).toDouble();
    final goalReached = data.totalPoints >= data.targetPoints;

    DateTime? expiry;
    bool isExpiryNear = false;
    try {
      expiry = DateTime.parse(data.endDate);
      isExpiryNear = expiry.difference(DateTime.now()).inDays <= 180;
    } catch (_) {
      expiry = null;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.appExt.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 9,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    if (goalReached)
                      const Icon(Icons.check_rounded,
                              color: Colors.white, size: 48)
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatPoints(data.totalPoints),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'pts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroLine(label: 'Active Cycle:', value: data.cycleName),
                    const SizedBox(height: 6),
                    _HeroLine(label: 'Expires:', value: data.endDate),
                    const SizedBox(height: 6),
                    _HeroLine(
                      label: 'Points remaining:',
                      value: formatPoints(remaining),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (goalReached) ...[
            const SizedBox(height: 14),
            _HeroChip(
              icon: Icons.check_circle,
              label: 'Recertification complete!',
              bg: AppColors.success,
            ),
          ] else if (isExpiryNear) ...[
            const SizedBox(height: 14),
            _HeroChip(
              icon: Icons.warning_amber_rounded,
              label: '⚠ Expires soon — ${data.endDate}',
              bg: AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroLine extends StatelessWidget {
  const _HeroLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label, required this.bg});

  final IconData icon;
  final String label;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.add,
            label: 'Add Activity',
            isPrimary: true,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddActivityScreen()),
              );
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.qr_code_scanner,
            label: 'Scan QR',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              );
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.file_download_outlined,
            label: 'Export',
            onTap: () {
              AppNavigator.maybeOf(context)?.selectTab(3);
            },
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final ext = context.appExt;
    final bg = isPrimary ? AppColors.primary : ext.card;
    final fg = isPrimary ? Colors.white : AppColors.primary;
    final borderColor =
        isPrimary ? AppColors.primary : AppColors.primary.withOpacity(0.4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isPrimary ? null : ext.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.pointsByCategory});

  final Map<int, double> pointsByCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final category in kCpdCategories) ...[
          _CategoryRow(
            categoryId: category['id'] as int,
            name: category['name'] as String,
            cap: category['cap'] as double?,
            total: pointsByCategory[category['id'] as int] ?? 0,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categoryId,
    required this.name,
    required this.cap,
    required this.total,
  });

  final int categoryId;
  final String name;
  final double? cap;
  final double total;

  @override
  Widget build(BuildContext context) {
    final reached = cap != null && total >= cap!;
    final exceeded = cap != null && total > cap!;
    final value =
        cap == null ? null : (total / cap!).clamp(0.0, 1.0).toDouble();
    final Color barColor = exceeded
        ? AppColors.warning
        : reached
            ? AppColors.success
            : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => CategoryInfoSheet.show(context, categoryId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
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
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$categoryId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.appExt.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cap == null
                        ? '${formatPoints(total)} pts'
                        : '${formatPoints(total)} / ${cap!.toStringAsFixed(0)} pts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cap == null ? AppColors.primary : barColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 18, color: context.appExt.textHint),
                ],
              ),
          if (cap == null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 38),
              child: Text(
                'Uncapped category',
                style: TextStyle(color: context.appExt.textHint, fontSize: 12),
              ),
            )
          else ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: context.appExt.border,
                color: barColor,
              ),
            ),
            if (reached)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      exceeded
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle,
                      size: 16,
                      color: barColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      exceeded
                          ? 'Cap exceeded — excess does not count'
                          : 'Cap reached',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

class _DomainGrid extends StatelessWidget {
  const _DomainGrid({required this.domainTotals});

  final Map<String, double> domainTotals;

  @override
  Widget build(BuildContext context) {
    final entries = domainTotals.entries.toList();
    final nameByCode = {
      for (final d in kCompetencyDomains) d['code']!: d['name']!,
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Fixed height instead of aspect ratio so two-line domain names
        // (e.g. "Social and Behavioural Sciences") always fit.
        mainAxisExtent: 76,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.appExt.primaryTint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        nameByCode[entry.key] ?? 'Domain ${entry.key}',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appExt.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatPoints(entry.value)} pts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: context.appExt.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentActivitiesList extends StatelessWidget {
  const _RecentActivitiesList({required this.activities});

  final List<CpdActivity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appExt.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.appExt.cardShadow,
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined,
                color: AppColors.primary, size: 36),
            const SizedBox(height: 8),
            Text(
              'No activities yet for this cycle.',
              style: TextStyle(color: context.appExt.textSecondary),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final activity in activities) ...[
          _RecentActivityCard(activity: activity),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.activity});

  final CpdActivity activity;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forCategory(activity.categoryId);
    return Container(
      decoration: BoxDecoration(
        color: context.appExt.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.appExt.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.activityDescription,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: context.appExt.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${activity.dateLogged} · ${activity.categoryName}',
                            style: TextStyle(
                              color: context.appExt.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${formatPoints(activity.pointsClaimed)} pts',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.cycleName,
    required this.endDate,
    required this.targetPoints,
    required this.totalPoints,
    required this.pointsByCategory,
    required this.domainTotals,
    required this.recentActivities,
  });

  const _DashboardData.empty()
      : cycleName = 'No Active Cycle',
        endDate = 'N/A',
        targetPoints = 60,
        totalPoints = 0,
        pointsByCategory = const {},
        domainTotals = const {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0, 'F': 0},
        recentActivities = const [];

  final String cycleName;
  final String endDate;
  final double targetPoints;
  final double totalPoints;
  final Map<int, double> pointsByCategory;
  final Map<String, double> domainTotals;
  final List<CpdActivity> recentActivities;
}
