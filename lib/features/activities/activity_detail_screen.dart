import 'package:flutter/material.dart';

import '../../models/cpd_activity.dart';
import '../../theme/app_theme.dart';

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key, required this.activity});

  final CpdActivity activity;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forCategory(activity.categoryId);
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Cat ${activity.categoryId}',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${activity.pointsClaimed.toStringAsFixed(1)} pts',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  activity.activityDescription,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.categoryName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailGroup(
            children: [
              _DetailRow(label: 'Date Logged', value: activity.dateLogged),
              _DetailRow(
                  label: 'Subcategory', value: activity.subcategory ?? '—'),
              _DetailRow(
                  label: 'Provider', value: activity.providerName ?? '—'),
              _DetailRow(
                label: 'Duration (hours)',
                value: activity.durationHours?.toStringAsFixed(2) ?? '—',
              ),
              _DetailRow(
                label: 'Competency Domain',
                value: activity.competencyDomain != null
                    ? 'Domain ${activity.competencyDomain}'
                    : '—',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailGroup(
            children: [
              _DetailRow(
                label: 'Evidence Note',
                value: activity.evidenceNote ?? '—',
                multiline: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailGroup extends StatelessWidget {
  const _DetailGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: multiline ? null : 3,
              overflow: multiline ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
