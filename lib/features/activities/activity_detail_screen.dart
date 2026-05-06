import 'package:flutter/material.dart';

import '../../models/cpd_activity.dart';

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key, required this.activity});

  final CpdActivity activity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoTile(label: 'Date Logged', value: activity.dateLogged),
          _InfoTile(label: 'Category', value: '${activity.categoryId}. ${activity.categoryName}'),
          _InfoTile(label: 'Subcategory', value: activity.subcategory ?? '-'),
          _InfoTile(label: 'Description', value: activity.activityDescription),
          _InfoTile(label: 'Provider', value: activity.providerName ?? '-'),
          _InfoTile(
            label: 'Duration (hours)',
            value: activity.durationHours?.toStringAsFixed(2) ?? '-',
          ),
          _InfoTile(
            label: 'Points Claimed',
            value: activity.pointsClaimed.toStringAsFixed(2),
          ),
          _InfoTile(label: 'Competency Domain', value: activity.competencyDomain ?? '-'),
          _InfoTile(label: 'Evidence Note', value: activity.evidenceNote ?? '-'),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
