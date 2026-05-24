import 'package:flutter/material.dart';

import '../../constants/cpd_categories.dart';
import '../../database/database_service.dart';
import '../../models/cpd_activity.dart';
import '../../utils/format_points.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_extension.dart';
import '../../theme/ui_polish.dart';
import 'activity_detail_screen.dart';
import 'add_activity_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;

  // 0 = all, 1..10 = category id, "A".."F" = domain code
  Object _activeFilter = 0;

  Future<_ActivityListViewData> _loadData() async {
    final cycle = await _databaseService.getActiveCycle();
    if (cycle?.id == null) {
      return const _ActivityListViewData(
        cycleId: null,
        activities: [],
        allActivities: [],
        totalLogged: 0,
        totalEffective: 0,
      );
    }
    final all = await _databaseService.getActivitiesByCycle(cycle!.id!);
    final filtered = _applyFilter(all);
    final totalLogged =
        all.fold<double>(0, (sum, a) => sum + a.pointsClaimed);
    final totalEffective =
        await _databaseService.getTotalPointsByCycle(cycle.id!);
    return _ActivityListViewData(
      cycleId: cycle.id,
      activities: filtered,
      allActivities: all,
      totalLogged: totalLogged,
      totalEffective: totalEffective,
    );
  }

  List<CpdActivity> _applyFilter(List<CpdActivity> all) {
    final filter = _activeFilter;
    if (filter is int) {
      if (filter == 0) return all;
      return all.where((a) => a.categoryId == filter).toList();
    }
    if (filter is String) {
      return all.where((a) => a.competencyDomain == filter).toList();
    }
    return all;
  }

  Future<void> _deleteActivity(CpdActivity activity) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete activity?'),
            content: const Text(
                'This will hide the activity from your journal list.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    minimumSize: const Size(0, 44)),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    await _databaseService.softDeleteActivity(activity.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity removed from active list.')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 0),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddActivityScreen()),
            );
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Activity',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<_ActivityListViewData>(
          future: _loadData(),
          builder: (context, snapshot) {
            final view = snapshot.data;
            if (view == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final activities = view.activities;

            return Column(
              children: [
                _Header(
                  count: activities.length,
                  totalLogged: view.totalLogged,
                  totalEffective: view.totalEffective,
                  showBack: Navigator.of(context).canPop(),
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                _FilterChips(
                  active: _activeFilter,
                  allActivities: view.allActivities,
                  onChanged: (value) => setState(() => _activeFilter = value),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: activities.isEmpty
                      ? const _EmptyState()
                      : _GroupedList(
                          activities: activities,
                          onDelete: _deleteActivity,
                          onRefresh: () {
                            if (mounted) setState(() {});
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.totalLogged,
    required this.totalEffective,
    required this.showBack,
    required this.onBack,
  });

  final int count;
  final double totalLogged;
  final double totalEffective;
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.appExt.header,
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                tooltip: 'Back',
              ),
            )
          else
            const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activities',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  totalLogged != totalEffective
                      ? '$count ${count == 1 ? 'activity' : 'activities'} · '
                          '${formatPoints(totalLogged)} logged · '
                          '${formatPoints(totalEffective)} count toward 60'
                      : '$count ${count == 1 ? 'activity' : 'activities'} · '
                          '${formatPoints(totalEffective)} pts this cycle',
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

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.active,
    required this.allActivities,
    required this.onChanged,
  });

  final Object active;
  final List<CpdActivity> allActivities;
  final ValueChanged<Object> onChanged;

  int _countFor(Object value) {
    if (value is int) {
      if (value == 0) return allActivities.length;
      return allActivities.where((a) => a.categoryId == value).length;
    }
    if (value is String) {
      return allActivities.where((a) => a.competencyDomain == value).length;
    }
    return 0;
  }

  String _chipLabel(String base, Object value) {
    final count = _countFor(value);
    if (value is int && value >= 1 && value <= 10 && count > 0) {
      return '$base ($count)';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appExt.header,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip(context, label: _chipLabel('All', 0), value: 0),
            for (int i = 1; i <= 10; i++)
              _chip(
                context,
                label: _chipLabel('Cat $i', i),
                value: i,
              ),
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: context.appExt.border,
            ),
            for (final d in kCompetencyDomains)
              _chip(
                context,
                label: 'Domain ${d['code']}',
                value: d['code']!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, {required String label, required Object value}) {
    final isSelected = active == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : context.appExt.chipUnselectedBackground,
            border: Border.all(
              color: isSelected ? AppColors.primary : context.appExt.border,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : context.appExt.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({
    required this.activities,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<CpdActivity> activities;
  final Future<void> Function(CpdActivity) onDelete;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<CpdActivity>>{};
    for (final activity in activities) {
      grouped.putIfAbsent(activity.categoryId, () => []).add(activity);
    }
    final orderedKeys = grouped.keys.toList()..sort();

    var itemIndex = 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: orderedKeys.expand((categoryId) {
        final rows = grouped[categoryId]!;
        final name = rows.first.categoryName;
        final categoryTotal =
            rows.fold<double>(0, (sum, a) => sum + a.pointsClaimed);
        final widgets = <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: PolishedListFadeIn(
              index: itemIndex++,
              child: _CategoryGroupHeader(
                categoryId: categoryId,
                name: name,
                total: categoryTotal,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ];
        for (final activity in rows) {
          widgets.add(
            PolishedListFadeIn(
              index: itemIndex++,
              child: _ActivityCard(
                activity: activity,
                onDelete: () => onDelete(activity),
                onRefresh: onRefresh,
              ),
            ),
          );
          widgets.add(const SizedBox(height: 10));
        }
        return widgets;
      }).toList(),
    );
  }
}

class _CategoryGroupHeader extends StatelessWidget {
  const _CategoryGroupHeader({
    required this.categoryId,
    required this.name,
    required this.total,
  });

  final int categoryId;
  final String name;
  final double total;

  @override
  Widget build(BuildContext context) {
    final accent = categoryAccentForId(categoryId);
    final cap = cpdCategoryCap(categoryId);
    final effective = effectiveCategoryPoints(total, categoryId);
    final isOverCap = cap != null && total > cap;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: context.appExt.primaryTint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Cat $categoryId',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.appExt.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isOverCap
                ? const Color(0xFFFEF3C7)
                : const Color(0xFFE6F3FB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isOverCap
                ? '${formatPoints(effective)} / ${cap.toStringAsFixed(0)} pts ⚠'
                : '${formatPoints(total)} pts',
            style: TextStyle(
              color: isOverCap
                  ? const Color(0xFF92400E)
                  : const Color(0xFF0082C8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.onDelete,
    required this.onRefresh,
  });

  final CpdActivity activity;
  final Future<void> Function() onDelete;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final accent = categoryAccentForId(activity.categoryId);
    return Dismissible(
      key: ValueKey(activity.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await onDelete();
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ActivityDetailScreen(activity: activity),
              ),
            );
            if (changed == true) onRefresh();
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
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${activity.dateLogged}'
                                  '${activity.providerName != null && activity.providerName!.isNotEmpty ? ' · ${activity.providerName}' : ''}',
                                  style: TextStyle(
                                    color: context.appExt.textHint,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: context.appExt.primaryTint,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Domain ${activity.competencyDomain ?? '-'}',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
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
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F3FB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 48,
                color: Color(0xFF0082C8),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No activities yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1321),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + Add Activity to log your first CPD activity.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF4A5570),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityListViewData {
  const _ActivityListViewData({
    required this.cycleId,
    required this.activities,
    required this.allActivities,
    required this.totalLogged,
    required this.totalEffective,
  });

  final int? cycleId;
  final List<CpdActivity> activities;
  final List<CpdActivity> allActivities;
  final double totalLogged;
  final double totalEffective;
}
