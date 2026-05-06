import 'package:flutter/material.dart';

import '../../database/database_service.dart';
import '../../models/cpd_activity.dart';
import 'activity_detail_screen.dart';
import 'add_activity_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  int _filterCategory = 0;

  Future<_ActivityListViewData> _loadData() async {
    final cycle = await _databaseService.getActiveCycle();
    if (cycle?.id == null) {
      return const _ActivityListViewData(cycleId: null, activities: []);
    }
    final all = await _databaseService.getActivitiesByCycle(cycle!.id!);
    final filtered = _filterCategory == 0
        ? all
        : all.where((a) => a.categoryId == _filterCategory).toList();
    return _ActivityListViewData(cycleId: cycle.id, activities: filtered);
  }

  Future<void> _deleteActivity(CpdActivity activity) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete activity?'),
            content: const Text('This will hide the activity from your journal list.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
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
      appBar: AppBar(title: const Text('Activities')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddActivityScreen()),
          );
          if (mounted) setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(0, 'All'),
                for (int i = 1; i <= 10; i++) _chip(i, 'Cat $i'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<_ActivityListViewData>(
              future: _loadData(),
              builder: (context, snapshot) {
                final activities = snapshot.data?.activities ?? <CpdActivity>[];
                if (activities.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.inbox_outlined, size: 56, color: Color(0xFF0082C8)),
                          SizedBox(height: 12),
                          Text(
                            'No activities logged yet. Tap + to add your first CPD activity.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final grouped = <String, List<CpdActivity>>{};
                for (final activity in activities) {
                  final key = '${activity.categoryId}. ${activity.categoryName}';
                  grouped.putIfAbsent(key, () => []).add(activity);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: const Border(
                              left: BorderSide(color: Color(0xFF0082C8), width: 4),
                            ),
                          ),
                          child: Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        ...entry.value.map(
                          (activity) => Dismissible(
                            key: ValueKey(activity.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 18),
                              color: Colors.red.shade400,
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              await _deleteActivity(activity);
                              return false;
                            },
                            child: Card(
                              child: ListTile(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ActivityDetailScreen(activity: activity),
                                    ),
                                  );
                                },
                                title: Text(activity.activityDescription),
                                subtitle: Text(
                                  '${activity.dateLogged} · ${activity.providerName ?? 'No provider'}',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${activity.pointsClaimed.toStringAsFixed(1)} pts'),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6F3FA),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(activity.competencyDomain ?? '-'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(int value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filterCategory == value,
        onSelected: (_) => setState(() => _filterCategory = value),
      ),
    );
  }
}

class _ActivityListViewData {
  const _ActivityListViewData({required this.cycleId, required this.activities});

  final int? cycleId;
  final List<CpdActivity> activities;
}
