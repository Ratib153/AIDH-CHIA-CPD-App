import 'package:flutter/material.dart';

import '../../constants/cpd_categories.dart';
import '../../database/database_service.dart';
import '../../models/cpd_activity.dart';
import '../activities/add_activity_screen.dart';
import '../export/export_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;

  Future<_DashboardData> _loadData() async {
    final cycle = await _databaseService.getActiveCycle();
    if (cycle?.id == null) {
      return const _DashboardData.empty();
    }

    final activities = await _databaseService.getActivitiesByCycle(cycle!.id!);
    final totalPoints = await _databaseService.getTotalPointsByCycle(cycle.id!);
    final pointsByCategory = await _databaseService.getPointsByCategory(cycle.id!);
    final domainTotals = <String, double>{for (final d in ['A', 'B', 'C', 'D', 'E', 'F']) d: 0};
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
      recentActivities: activities.take(5).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_DashboardData>(
        future: _loadData(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final progress = data.targetPoints == 0
              ? 0.0
              : (data.totalPoints / data.targetPoints).clamp(0.0, 1.0).toDouble();
          final remaining = (data.targetPoints - data.totalPoints).clamp(0, data.targetPoints);
          final expiry = DateTime.parse(data.endDate);
          final isExpiryNear = expiry.difference(DateTime.now()).inDays <= 180;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                Text('CHIA CPD Dashboard', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Active cycle: ${data.cycleName}'),
                        Text('Expiry: ${data.endDate}'),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFE0E0E0),
                          color: const Color(0xFF0082C8),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Points claimed: ${data.totalPoints.toStringAsFixed(1)} / ${data.targetPoints.toStringAsFixed(0)}',
                        ),
                        Text('Points remaining: ${remaining.toStringAsFixed(1)}'),
                      ],
                    ),
                  ),
                ),
                if (isExpiryNear)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Your CHIA credential expires on ${data.endDate}. Ensure you submit before this date.',
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AddActivityScreen()),
                          );
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('+ Add Activity'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ExportScreen()),
                          );
                        },
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Export Journal'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Category Breakdown', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...kCpdCategories.map((category) {
                  final id = category['id'] as int;
                  final cap = category['cap'] as double?;
                  final total = data.pointsByCategory[id] ?? 0;
                  final reached = cap != null && total >= cap;
                  final exceeded = cap != null && total > cap;
                  final value =
                      cap == null ? null : (total / cap).clamp(0.0, 1.0).toDouble();
                  final color = exceeded
                      ? Colors.amber
                      : reached
                          ? Colors.green
                          : const Color(0xFF0082C8);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${category['id']}. ${category['name']}'),
                          const SizedBox(height: 4),
                          Text(
                            cap == null
                                ? '${total.toStringAsFixed(1)} pts'
                                : '${total.toStringAsFixed(1)} / ${cap.toStringAsFixed(1)} pts',
                          ),
                          if (value != null) ...[
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: value,
                              minHeight: 8,
                              color: color,
                              backgroundColor: const Color(0xFFE0E0E0),
                            ),
                          ],
                          if (reached)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                exceeded
                                    ? '⚠ Cap exceeded — excess pts do not count'
                                    : '✓ Cap reached',
                                style: TextStyle(color: color),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),
                Text('Competency Domains', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...data.domainTotals.entries.map(
                  (entry) => Card(
                    child: ListTile(
                      title: Text('Domain ${entry.key}'),
                      trailing: Text('${entry.value.toStringAsFixed(1)} pts'),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Recent Activities', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...data.recentActivities.map(
                  (activity) => Card(
                    child: ListTile(
                      title: Text(activity.activityDescription),
                      subtitle: Text('${activity.dateLogged} · ${activity.categoryName}'),
                      trailing: Text('${activity.pointsClaimed.toStringAsFixed(1)} pts'),
                    ),
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
