import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/auth_service.dart';
import '../../constants/cpd_categories.dart';
import '../../constants/settings_keys.dart';
import '../../database/database_service.dart';
import '../../firebase_options.dart';
import '../../models/recertification_cycle.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_extension.dart';
import '../../utils/format_points.dart';
import '../../theme/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;

  bool _isEditing = false;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _credentialController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _credentialController.dispose();
    super.dispose();
  }

  String _effectiveDisplayName(String? localName) {
    if (DefaultFirebaseOptions.isConfigured) {
      final username = AuthService.instance.username;
      if (username != null && username.isNotEmpty) {
        return username;
      }
    }
    return localName ?? 'CHIA Professional';
  }

  Future<_ProfileData> _load() async {
    final name =
        await _databaseService.getSetting(kProfileDisplayName);
    final displayName = _effectiveDisplayName(name);
    final credential =
        await _databaseService.getSetting(kProfileCredentialNumber);
    final cycle = await _databaseService.getActiveCycle();

    double totalPoints = 0;
    int activitiesCount = 0;
    Map<int, double> pointsByCategory = const {};
    if (cycle?.id != null) {
      totalPoints =
          await _databaseService.getTotalPointsByCycle(cycle!.id!);
      final activities =
          await _databaseService.getActivitiesByCycle(cycle.id!);
      activitiesCount = activities.length;
      pointsByCategory =
          await _databaseService.getPointsByCategory(cycle.id!);
    }

    if (!_isEditing) {
      _nameController.text = displayName;
      _credentialController.text = credential ?? '';
    }

    return _ProfileData(
      displayName: displayName,
      usesFirebaseUsername: AuthService.instance.username != null,
      credentialNumber: credential ?? '',
      cycle: cycle,
      totalPoints: totalPoints,
      activitiesCount: activitiesCount,
      pointsByCategory: pointsByCategory,
    );
  }

  bool _isValidUsername(String value) {
    return value.length >= 3 &&
        value.length <= 30 &&
        RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final trimmedName = _nameController.text.trim();
      final hasFirebaseAccount = DefaultFirebaseOptions.isConfigured &&
          AuthService.instance.isSignedIn;

      String displayName;
      if (hasFirebaseAccount) {
        if (!_isValidUsername(trimmedName)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Username must be 3–30 characters (letters, numbers, underscores).',
              ),
            ),
          );
          return;
        }
        displayName = trimmedName;
        await AuthService.instance.updateUsername(displayName);
      } else {
        displayName =
            trimmedName.isEmpty ? 'CHIA Professional' : trimmedName;
      }

      await _databaseService.setSetting(
        kProfileDisplayName,
        displayName,
      );
      await _databaseService.setSetting(
        kProfileCredentialNumber,
        _credentialController.text.trim().isEmpty
            ? null
            : _credentialController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
      setState(() => _isEditing = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save profile.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _startNewCycle() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Start a new cycle?'),
            content: const Text(
              'This will archive your current cycle and start a new 3-year cycle. '
              'Your existing activities will be preserved and available in past cycles.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  minimumSize: const Size(0, 44),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Start new cycle'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final all = await _databaseService.getAllCycles();
    final nextNumber = all.length + 1;
    final now = DateTime.now();
    final newCycle = RecertificationCycle(
      userId: AuthService.instance.currentUser!.uid,
      cycleName: 'Cycle $nextNumber',
      startDate: now.toIso8601String().substring(0, 10),
      endDate: now
          .add(const Duration(days: 1095))
          .toIso8601String()
          .substring(0, 10),
      targetPoints: 60,
      isActive: true,
      createdAt: now.toIso8601String(),
    );
    await _databaseService.archiveAndCreateNewCycle(newCycle);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('New cycle started. Good luck with your recertification!')),
    );
    setState(() {});
  }

  Future<void> _showManageCycles() async {
    final all = await _databaseService.getAllCycles();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appExt.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Recertification Cycles',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Past cycles are kept for audit and evidence.',
                  style: TextStyle(color: context.appExt.textHint, fontSize: 13),
                ),
                const SizedBox(height: 14),
                for (final cycle in all) ...[
                  _CycleListTile(cycle: cycle),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCategoriesSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appExt.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'CPD Categories & Caps',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Reference for the 10 CHIA CPD categories.',
                  style: TextStyle(color: context.appExt.textHint, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in kCpdCategories)
                        _CategoryReferenceRow(
                          id: c['id'] as int,
                          name: c['name'] as String,
                          cap: c['cap'] as double?,
                          rate: c['rateDescription'] as String,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showContact() async {
    const email = 'certification@digitalhealth.org.au';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Contact AIDH'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Email AIDH for certification queries:'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: context.appExt.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: SelectableText(
                        email,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      color: AppColors.primary,
                      onPressed: () {
                        Clipboard.setData(
                            const ClipboardData(text: email));
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Email copied to clipboard.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openExternalUrl('mailto:$email');
              },
              icon: const Icon(Icons.mail_outline, size: 18),
              label: const Text('Send email'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openExternalUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  Future<void> _showRecertGuide() async {
    const url = 'https://www.digitalhealth.org.au';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('CHIA Recertification Guide'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Open the AIDH website for full guidance:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.appExt.primaryTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _openExternalUrl(url);
                },
                child: const Row(
                  children: [
                    Icon(Icons.open_in_new, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        url,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openExternalUrl(url);
            },
            icon: const Icon(Icons.open_in_browser, size: 18),
            label: const Text('Open in browser'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: AuthService.instance,
        builder: (context, _) {
          return FutureBuilder<_ProfileData>(
        future: _load(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _ProfileHeader(
                displayName: data.displayName,
                usesFirebaseUsername: data.usesFirebaseUsername,
                credentialNumber: data.credentialNumber,
                isEditing: _isEditing,
                isSaving: _isSaving,
                nameController: _nameController,
                credentialController: _credentialController,
                onToggle: () {
                  if (_isEditing) {
                    _saveProfile();
                  } else {
                    _nameController.text = data.displayName;
                    _credentialController.text = data.credentialNumber;
                    setState(() => _isEditing = true);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.cycle != null)
                      _ActiveCycleCard(
                        cycle: data.cycle!,
                        totalPoints: data.totalPoints,
                        onManage: _showManageCycles,
                      ),
                    const SizedBox(height: 14),
                    if (data.cycle != null)
                      _ExpiryCard(endDate: data.cycle!.endDate),
                    const SizedBox(height: 14),
                    _SummaryCard(
                      totalPoints: data.totalPoints,
                      activitiesCount: data.activitiesCount,
                      categoriesUsed: data.pointsByCategory.values
                          .where((v) => v > 0)
                          .length,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    const _AppearanceSettings(),
                    if (DefaultFirebaseOptions.isConfigured) ...[
                      const SizedBox(height: 22),
                      Text(
                        'Account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      const _AccountSettings(),
                    ],
                    const SizedBox(height: 22),
                    Text(
                      'About & Help',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    _AboutList(
                      onGuide: _showRecertGuide,
                      onCategories: _showCategoriesSheet,
                      onContact: _showContact,
                    ),
                    const SizedBox(height: 22),
                    _DangerZone(onResetCycle: _startNewCycle),
                  ],
                ),
              ),
            ],
          );
        },
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.usesFirebaseUsername,
    required this.credentialNumber,
    required this.isEditing,
    required this.isSaving,
    required this.nameController,
    required this.credentialController,
    required this.onToggle,
  });

  final String displayName;
  final bool usesFirebaseUsername;
  final String credentialNumber;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController nameController;
  final TextEditingController credentialController;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.appExt.header,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Column(
        children: [
          const _ChiaCircularBadge(),
          const SizedBox(height: 14),
          if (!isEditing) ...[
            Text(
              usesFirebaseUsername ? '@$displayName' : displayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.appExt.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              credentialNumber.isEmpty
                  ? 'Add your CHIA credential number'
                  : credentialNumber,
              style: TextStyle(
                fontSize: 13,
                color: credentialNumber.isEmpty
                    ? context.appExt.textHint
                    : context.appExt.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onToggle,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] else ...[
            TextField(
              controller: nameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText:
                    usesFirebaseUsername ? 'Username' : 'Display name',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: credentialController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'CHIA credential number (e.g. CHIA-1234)',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: isSaving ? null : onToggle,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check, size: 18),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular brand badge used in lieu of an image asset.
class _ChiaCircularBadge extends StatelessWidget {
  const _ChiaCircularBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'CHIA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _ActiveCycleCard extends StatelessWidget {
  const _ActiveCycleCard({
    required this.cycle,
    required this.totalPoints,
    required this.onManage,
  });

  final RecertificationCycle cycle;
  final double totalPoints;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final progress = cycle.targetPoints == 0
        ? 0.0
        : (totalPoints / cycle.targetPoints).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(18),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.appExt.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.autorenew,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cycle.cycleName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.appExt.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDate(cycle.startDate)} → ${_formatDate(cycle.endDate)}',
                      style: TextStyle(
                        color: context.appExt.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${formatPoints(totalPoints)} / ${cycle.targetPoints.toStringAsFixed(0)} pts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.appExt.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onManage,
                child: const Text('Manage Cycles'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: AppColors.primary,
              backgroundColor: context.appExt.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryCard extends StatelessWidget {
  const _ExpiryCard({required this.endDate});

  final String endDate;

  @override
  Widget build(BuildContext context) {
    DateTime? expiry;
    try {
      expiry = DateTime.parse(endDate);
    } catch (_) {
      expiry = null;
    }
    final daysAway = expiry == null
        ? null
        : expiry.difference(DateTime.now()).inDays;

    Color accent;
    IconData icon;
    String heading;
    String body;
    if (daysAway == null) {
      accent = AppColors.textHint;
      icon = Icons.info_outline;
      heading = 'Credential status unknown';
      body = 'Expiry date is not set.';
    } else if (daysAway < 0) {
      accent = AppColors.error;
      icon = Icons.cancel_outlined;
      heading = '✗ Credential lapsed';
      body =
          'Your CHIA credential has lapsed. Recertify by re-sitting the examination.';
    } else if (daysAway <= 180) {
      accent = AppColors.warning;
      icon = Icons.warning_amber_rounded;
      heading = '⚠ Expiring soon';
      body =
          'Ensure you submit your 60 CPD points before ${_formatDate(endDate)}.';
    } else {
      accent = AppColors.success;
      icon = Icons.verified_outlined;
      heading = '✓ Credential active';
      body = 'Expires on ${_formatDate(endDate)} ($daysAway days from now).';
    }

    return Container(
      decoration: BoxDecoration(
        color: context.appExt.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.appExt.cardShadow,
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: context.appExt.textSecondary,
                    fontSize: 13,
                    height: 1.4,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalPoints,
    required this.activitiesCount,
    required this.categoriesUsed,
  });

  final double totalPoints;
  final int activitiesCount;
  final int categoriesUsed;

  @override
  Widget build(BuildContext context) {
    final remaining = (60 - totalPoints).clamp(0, 60).toDouble();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appExt.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.appExt.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Cycle at a Glance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Total pts',
                  value: formatPoints(totalPoints),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Pts remaining',
                  value: formatPoints(remaining),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Activities',
                  value: '$activitiesCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Categories used',
                  value: '$categoriesUsed / 10',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.appExt.primaryTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: context.appExt.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSettings extends StatelessWidget {
  const _AccountSettings();

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appExt;
    final email = AuthService.instance.currentUser?.email;
    final username = AuthService.instance.username;

    return Container(
      decoration: BoxDecoration(
        color: ext.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ext.cardShadow,
      ),
      child: Column(
        children: [
          if (username != null)
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppColors.primary),
              title: const Text('Username'),
              subtitle: Text(
                '@$username',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ext.textPrimary,
                ),
              ),
            ),
          if (email != null)
            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              title: const Text('Email'),
              subtitle: Text(
                email,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ext.textPrimary,
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Sign out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}

class _AppearanceSettings extends StatelessWidget {
  const _AppearanceSettings();

  @override
  Widget build(BuildContext context) {
    final ext = context.appExt;
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDark;
        return Container(
          decoration: BoxDecoration(
            color: ext.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ext.cardShadow,
          ),
          child: SwitchListTile(
            secondary: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.primary,
            ),
            title: Text(
              'Dark mode',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ext.textPrimary,
              ),
            ),
            subtitle: Text(
              'Use a dark appearance across the app',
              style: TextStyle(
                fontSize: 13,
                color: ext.textSecondary,
              ),
            ),
            value: isDark,
            onChanged: ThemeController.instance.setDark,
          ),
        );
      },
    );
  }
}

class _AboutList extends StatelessWidget {
  const _AboutList({
    required this.onGuide,
    required this.onCategories,
    required this.onContact,
  });

  final VoidCallback onGuide;
  final VoidCallback onCategories;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appExt.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.appExt.cardShadow,
      ),
      child: Column(
        children: [
          _AboutTile(
            icon: Icons.menu_book_outlined,
            title: 'CHIA Recertification Guide',
            onTap: onGuide,
          ),
          const Divider(height: 1),
          _AboutTile(
            icon: Icons.category_outlined,
            title: 'CPD Categories & Caps',
            onTap: onCategories,
          ),
          const Divider(height: 1),
          _AboutTile(
            icon: Icons.email_outlined,
            title: 'Contact AIDH',
            onTap: onContact,
          ),
          const Divider(height: 1),
          const _AboutTile(
            icon: Icons.info_outline,
            title: 'App Version',
            trailingText: 'v1.0.0 (CHIA CPD)',
          ),
        ],
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.appExt.primaryTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: context.appExt.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: TextStyle(
                  color: context.appExt.textHint,
                  fontSize: 12,
                ),
              )
            else if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.onResetCycle});

  final VoidCallback onResetCycle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appExt.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.appExt.cardShadow,
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Danger zone',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Starting a new cycle archives your current cycle. Existing activities will remain available in past cycles for audit.',
            style: TextStyle(
              color: context.appExt.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onResetCycle,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Start New Recertification Cycle'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.5),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleListTile extends StatelessWidget {
  const _CycleListTile({required this.cycle});

  final RecertificationCycle cycle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cycle.isActive ? context.appExt.primaryTint : context.appExt.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cycle.isActive ? AppColors.primary : context.appExt.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            cycle.isActive
                ? Icons.radio_button_checked
                : Icons.history_toggle_off,
            color: cycle.isActive ? AppColors.primary : context.appExt.textHint,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cycle.cycleName,
                  style: TextStyle(
                    color: cycle.isActive
                        ? AppColors.primary
                        : context.appExt.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(cycle.startDate)} → ${_formatDate(cycle.endDate)}',
                  style: TextStyle(
                    color: context.appExt.textHint,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (cycle.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryReferenceRow extends StatelessWidget {
  const _CategoryReferenceRow({
    required this.id,
    required this.name,
    required this.cap,
    required this.rate,
  });

  final int id;
  final String name;
  final double? cap;
  final String rate;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forCategory(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: context.appExt.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: context.appExt.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Cat $id',
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: context.appExt.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cap == null ? 'Uncapped' : 'Cap: ${cap!.toStringAsFixed(0)} pts'} · $rate',
                  style: TextStyle(
                    color: context.appExt.textHint,
                    fontSize: 11,
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

class _ProfileData {
  const _ProfileData({
    required this.displayName,
    required this.usesFirebaseUsername,
    required this.credentialNumber,
    required this.cycle,
    required this.totalPoints,
    required this.activitiesCount,
    required this.pointsByCategory,
  });

  final String displayName;
  final bool usesFirebaseUsername;
  final String credentialNumber;
  final RecertificationCycle? cycle;
  final double totalPoints;
  final int activitiesCount;
  final Map<int, double> pointsByCategory;
}

String _formatDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return iso;
  }
}
