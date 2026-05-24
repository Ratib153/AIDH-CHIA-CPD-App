import 'package:flutter/material.dart';

import '../constants/cpd_categories.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extension.dart';
import '../utils/format_points.dart';

/// Shows category points with cap context: logged total, cap, and effective count.
class CategoryCapLabel extends StatelessWidget {
  const CategoryCapLabel({
    super.key,
    required this.categoryId,
    required this.claimed,
    this.compact = false,
  });

  final int categoryId;
  final double claimed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cap = cpdCategoryCap(categoryId);
    final effective = effectiveCategoryPoints(claimed, categoryId);
    final exceeded = cap != null && claimed > cap;

    if (cap == null) {
      return Text(
        '${formatPoints(claimed)} pts',
        style: _primaryStyle(context),
        textAlign: TextAlign.end,
      );
    }

    if (exceeded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${formatPoints(claimed)} logged',
            style: TextStyle(
              color: context.appExt.textSecondary,
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.end,
          ),
          const SizedBox(height: 2),
          Text(
            'Cap: ${formatPoints(cap)} pts',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
          Text(
            'Only ${formatPoints(effective)} count',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      );
    }

    return Text(
      '${formatPoints(claimed)} / ${formatPoints(cap)} pts',
      style: _primaryStyle(context),
      textAlign: TextAlign.end,
    );
  }

  TextStyle _primaryStyle(BuildContext context) {
    return TextStyle(
      color: context.appExt.textSecondary,
      fontSize: compact ? 12 : 13,
      fontWeight: FontWeight.w700,
    );
  }
}

/// Cycle-level summary when raw logged points differ from capped effective total.
class CyclePointsCapSummary extends StatelessWidget {
  const CyclePointsCapSummary({
    super.key,
    required this.totalLogged,
    required this.totalEffective,
  });

  final double totalLogged;
  final double totalEffective;

  @override
  Widget build(BuildContext context) {
    final capsApplied = totalLogged != totalEffective;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatRow(
          label: 'Total logged',
          value: '${formatPoints(totalLogged)} pts',
        ),
        const SizedBox(height: 8),
        _StatRow(
          label: 'Counts toward 60 pts',
          value: '${formatPoints(totalEffective)} pts',
          valueColor: AppColors.primary,
        ),
        if (capsApplied) ...[
          const SizedBox(height: 8),
          Text(
            'Category caps applied — only capped amounts count toward your '
            'recertification total.',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: context.appExt.textHint,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? context.appExt.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
