import 'package:flutter/material.dart';

import '../../database/database_service.dart';
import '../../models/cpd_activity.dart';
import '../../models/recertification_cycle.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_extension.dart';
import '../../utils/format_points.dart';
import '../../widgets/category_cap_label.dart';
import '../activities/activity_detail_screen.dart';

/// Read-only journal of activities logged in a specific recertification cycle.
class PastCycleActivitiesScreen extends StatelessWidget {
  const PastCycleActivitiesScreen({super.key, required this.cycle});

  final RecertificationCycle cycle;

  Future<_CycleActivitiesData> _load() async {
    final db = DatabaseService.instance;
    if (cycle.id == null) {
      return const _CycleActivitiesData(
        activities: [],
        totalLogged: 0,
        totalEffective: 0,
      );
    }
    final activities = await db.getActivitiesByCycle(cycle.id!);
    final totalLogged = activities.fold<double>(
      0,
      (sum, activity) => sum + activity.pointsClaimed,
    );
    final totalEffective = await db.getTotalPointsByCycle(cycle.id!);
    return _CycleActivitiesData(
      activities: activities,
      totalLogged: totalLogged,
      totalEffective: totalEffective,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cycle.cycleName),
      ),
      body: FutureBuilder<_CycleActivitiesData>(
        future: _load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.activities.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No activities were logged in this cycle.',
                  style: TextStyle(color: context.appExt.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final grouped = <int, List<CpdActivity>>{};
          for (final activity in data.activities) {
            grouped.putIfAbsent(activity.categoryId, () => []).add(activity);
          }
          final orderedKeys = grouped.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _CycleSummaryCard(
                cycle: cycle,
                activityCount: data.activities.length,
                totalLogged: data.totalLogged,
                totalEffective: data.totalEffective,
              ),
              const SizedBox(height: 16),
              Text(
                'Activities',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              for (final categoryId in orderedKeys) ...[
                _PastCategoryHeader(
                  categoryId: categoryId,
                  name: grouped[categoryId]!.first.categoryName,
                  claimed: grouped[categoryId]!.fold<double>(
                    0,
                    (sum, activity) => sum + activity.pointsClaimed,
                  ),
                ),
                const SizedBox(height: 8),
                for (final activity in grouped[categoryId]!) ...[
                  _PastActivityTile(activity: activity),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CycleActivitiesData {
  const _CycleActivitiesData({
    required this.activities,
    required this.totalLogged,
    required this.totalEffective,
  });

  final List<CpdActivity> activities;
  final double totalLogged;
  final double totalEffective;
}

class _CycleSummaryCard extends StatelessWidget {
  const _CycleSummaryCard({
    required this.cycle,
    required this.activityCount,
    required this.totalLogged,
    required this.totalEffective,
  });

  final RecertificationCycle cycle;
  final int activityCount;
  final double totalLogged;
  final double totalEffective;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appExt.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.appExt.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_formatDate(cycle.startDate)} → ${_formatDate(cycle.endDate)}',
            style: TextStyle(color: context.appExt.textHint, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            'Activities: $activityCount',
            style: TextStyle(
              color: context.appExt.textHint,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          CyclePointsCapSummary(
            totalLogged: totalLogged,
            totalEffective: totalEffective,
          ),
        ],
      ),
    );
  }
}

class _PastCategoryHeader extends StatelessWidget {
  const _PastCategoryHeader({
    required this.categoryId,
    required this.name,
    required this.claimed,
  });

  final int categoryId;
  final String name;
  final double claimed;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forCategory(categoryId);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 24,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Cat $categoryId · $name',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.appExt.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        CategoryCapLabel(categoryId: categoryId, claimed: claimed, compact: true),
      ],
    );
  }
}

class _PastActivityTile extends StatelessWidget {
  const _PastActivityTile({required this.activity});

  final CpdActivity activity;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forCategory(activity.categoryId);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ActivityDetailScreen(activity: activity),
            ),
          );
        },
        child: Container(
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: context.appExt.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activity.dateLogged,
                                style: TextStyle(
                                  color: context.appExt.textHint,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${formatPoints(activity.pointsClaimed)} pts',
                          style: const TextStyle(
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
        ),
      ),
    );
  }
}

String _formatDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return iso;
  }
}
