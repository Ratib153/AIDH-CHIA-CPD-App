import 'package:flutter/material.dart';

import '../constants/cpd_category_descriptions.dart';
import '../features/activities/add_activity_screen.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extension.dart';

/// Full-screen draggable bottom sheet with official CHIA category guidance.
class CategoryInfoSheet {
  CategoryInfoSheet._();

  static Future<void> show(
    BuildContext context,
    int categoryId, {
    bool showLogActivityButton = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final description = kCategoryDescriptions[categoryId];
            if (description == null) {
              return _MissingCategorySheet(scrollController: scrollController);
            }
            return _CategoryInfoSheetBody(
              categoryId: categoryId,
              description: description,
              scrollController: scrollController,
              showLogActivityButton: showLogActivityButton,
            );
          },
        );
      },
    );
  }
}

class _MissingCategorySheet extends StatelessWidget {
  const _MissingCategorySheet({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final ext = context.appExt;
    return _SheetChrome(
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const SizedBox(height: 8),
          Text(
            'Category information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'No information is available for this category yet.',
            style: TextStyle(color: ext.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryInfoSheetBody extends StatelessWidget {
  const _CategoryInfoSheetBody({
    required this.categoryId,
    required this.description,
    required this.scrollController,
    required this.showLogActivityButton,
  });

  final int categoryId;
  final CategoryDescription description;
  final ScrollController scrollController;
  final bool showLogActivityButton;

  @override
  Widget build(BuildContext context) {
    final ext = context.appExt;

    return _SheetChrome(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              children: [
                _SheetHeader(categoryId: categoryId, description: description),
                const _SectionDivider(),
                _SectionHeading(
                  icon: Icons.info_outline,
                  iconColor: AppColors.primary,
                  title: 'Overview',
                ),
                const SizedBox(height: 8),
                Text(
                  description.overview,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionDivider(),
                _SectionHeading(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                  title: "What's Eligible",
                ),
                const SizedBox(height: 8),
                ...description.eligibleActivities.map(
                  (item) => _BulletRow(
                    text: item,
                    dotColor: AppColors.success,
                    textColor: ext.textPrimary,
                  ),
                ),
                if (description.ineligibleActivities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _SectionDivider(),
                  _SectionHeading(
                    icon: Icons.cancel_outlined,
                    iconColor: AppColors.error,
                    title: "What's NOT Eligible",
                  ),
                  const SizedBox(height: 8),
                  ...description.ineligibleActivities.map(
                    (item) => _BulletRow(
                      text: item,
                      dotColor: AppColors.error,
                      textColor: ext.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const _SectionDivider(),
                _SectionHeading(
                  icon: Icons.table_chart_outlined,
                  iconColor: AppColors.primary,
                  title: 'Points Guide',
                ),
                const SizedBox(height: 10),
                _PointsGuideTable(entries: description.pointsGuide),
                if (description.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _SectionDivider(),
                  _SectionHeading(
                    icon: Icons.note_alt_outlined,
                    iconColor: ext.textSecondary,
                    title: 'Notes & Evidence',
                  ),
                  const SizedBox(height: 8),
                  ...description.notes.map(
                    (item) => _BulletRow(
                      text: item,
                      dotColor: ext.textHint,
                      textColor: ext.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (description.eligibilityReminder != null) ...[
                  const SizedBox(height: 16),
                  _EligibilityReminderCard(
                    text: description.eligibilityReminder!,
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
          _BottomActions(
            categoryId: categoryId,
            showLogActivityButton: showLogActivityButton,
          ),
        ],
      ),
    );
  }
}

class _SheetChrome extends StatelessWidget {
  const _SheetChrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appExt.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.appExt.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.categoryId,
    required this.description,
  });

  final int categoryId;
  final CategoryDescription description;

  @override
  Widget build(BuildContext context) {
    final ext = context.appExt;
    final isUncapped = description.cap == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: description.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(description.icon, color: description.color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category $categoryId',
                    style: TextStyle(
                      color: description.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description.title,
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isUncapped
                    ? ext.successSurface
                    : ext.primaryTint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isUncapped ? 'Uncapped' : 'Cap: ${description.cap}',
                style: TextStyle(
                  color: isUncapped ? AppColors.success : AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ext.primaryTint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                description.rate,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  final IconData icon;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: context.appExt.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: context.appExt.border),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.text,
    required this.dotColor,
    required this.textColor,
    this.fontSize = 14,
  });

  final String text;
  final Color dotColor;
  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsGuideTable extends StatelessWidget {
  const _PointsGuideTable({required this.entries});

  final List<PointsGuideEntry> entries;

  @override
  Widget build(BuildContext context) {
    final ext = context.appExt;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++)
            Container(
              color: i.isEven ? ext.primaryTint.withOpacity(0.35) : ext.card,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entries[i].label,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entries[i].points,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

class _EligibilityReminderCard extends StatelessWidget {
  const _EligibilityReminderCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ext = context.appExt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.warningSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ext.textPrimary,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.categoryId,
    required this.showLogActivityButton,
  });

  final int categoryId;
  final bool showLogActivityButton;

  @override
  Widget build(BuildContext context) {
    final ext = context.appExt;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: context.appExt.card,
        border: Border(top: BorderSide(color: ext.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: ext.textSecondary,
                side: BorderSide(color: ext.border),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
          if (showLogActivityButton) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute<void>(
                      builder: (_) => AddActivityScreen(
                        initialCategoryId: categoryId,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Log Activity →'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
