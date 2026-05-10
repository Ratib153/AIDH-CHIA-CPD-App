import 'package:flutter/material.dart';

import 'data/activity_repository.dart';
import 'models/activity.dart';
import 'widgets/activity_form.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final _repo = ActivityRepository.instance;

  Future<void> _openAddForm() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ActivityForm()),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _openEditForm(Activity activity) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ActivityForm(existing: activity)),
    );
    if (result == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity updated')),
      );
    }
  }

  Future<void> _confirmDelete(Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this activity?'),
        content: Text(
          '"${activity.title}" will be removed from your journal.',
        ),
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
    );

    if (confirmed != true || !mounted) return;
    _repo.softDelete(activity.id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activities = _repo.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Activities')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddForm,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: activities.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _ActivityCard(
                  activity: activity,
                  onEdit: () => _openEditForm(activity),
                  onDelete: () => _confirmDelete(activity),
                );
              },
            ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.onEdit,
    required this.onDelete,
  });

  final Activity activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${activity.date.year}-${activity.date.month.toString().padLeft(2, '0')}-${activity.date.day.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        title: Text(activity.title),
        subtitle: Text(
          '${activity.category} · $dateLabel · ${activity.points.toStringAsFixed(1)} pts',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 56, color: Color(0xFF0F6FFF)),
            const SizedBox(height: 12),
            Text(
              'No activities yet. Tap + to add one.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
