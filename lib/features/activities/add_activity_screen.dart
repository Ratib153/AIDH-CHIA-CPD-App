import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/cpd_categories.dart';
import '../../database/database_service.dart';
import '../../models/cpd_activity.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_extension.dart';
import '../../utils/format_points.dart';
import '../../widgets/category_info_sheet.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({
    super.key,
    this.prefilledDescription,
    this.prefilledProvider,
    this.initialCategoryId,
    this.existingActivity,
  });

  /// When set, the screen edits this activity (same [DatabaseService] row).
  final CpdActivity? existingActivity;

  /// Optional initial value for the activity title (e.g. from a QR scan).
  final String? prefilledDescription;

  /// Optional initial value for the provider/event/organisation.
  final String? prefilledProvider;

  /// Pre-select a category when opening from a category info sheet.
  final int? initialCategoryId;

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService.instance;

  DateTime _dateLogged = DateTime.now();
  int? _selectedCategoryId;
  String? _selectedDomain;
  bool _crossProgram = false;
  bool _eligibility = false;
  String _cat2Type = 'credit';
  String _cat4Role = 'speaker';
  String _cat8Role = 'Mentor';
  String _cat10Equivalent = 'cat4';
  final Map<String, TextEditingController> _fields = {};

  double _pointsClaimed = 0.0;
  bool _saving = false;
  String? _warningText;
  String? _successText;

  // Per-cycle category caps live-snapshot, refreshed when relevant.
  Map<int, Map<String, double>> _pointsByCategory = emptyPointsByCategory();

  @override
  void initState() {
    super.initState();
    for (final key in [
      'title',
      'provider',
      'durationHours',
      'items',
      'minutes',
      'years',
      'subcategory',
      'description',
      'evidence',
      'points',
      'contentHours',
      'sessions',
      'minutesPerSession',
      'learningDescription',
      'roleOrScope',
      'format',
      'publicationType',
      'courseType',
      'count',
      'programName',
      'activityName',
    ]) {
      _fields[key] = TextEditingController();
    }
    if (widget.existingActivity != null) {
      _populateFromExisting(widget.existingActivity!);
    } else {
      if (widget.prefilledDescription != null &&
          widget.prefilledDescription!.trim().isNotEmpty) {
        _fields['activityName']!.text = widget.prefilledDescription!.trim();
      }
      if (widget.prefilledProvider != null &&
          widget.prefilledProvider!.trim().isNotEmpty) {
        _fields['provider']!.text = widget.prefilledProvider!.trim();
      }
      if (widget.initialCategoryId != null) {
        _selectedCategoryId = widget.initialCategoryId;
      }
    }
    _refreshPointsByCategory().then((_) {
      if (!mounted) return;
      if (_selectedCategoryId != null) {
        _recomputePoints();
        _recomputeWarnings();
      }
    });
  }

  Future<void> _refreshPointsByCategory() async {
    final active = await _databaseService.getActiveCycle();
    if (active?.id == null) return;
    final map = await _databaseService.getPointsByCategory(active!.id!);
    if (!mounted) return;
    setState(() => _pointsByCategory = map);
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _populateFromExisting(CpdActivity ex) {
    _dateLogged = DateTime.parse(ex.dateLogged);
    _selectedCategoryId = ex.categoryId;
    _fields['activityName']!.text = ex.activityDescription;
    _fields['provider']!.text = ex.providerName ?? '';
    if (ex.durationHours != null) {
      _fields['durationHours']!.text = ex.durationHours!.toString();
    }
    _fields['subcategory']!.text = ex.subcategory ?? '';
    _fields['evidence']!.text = ex.evidenceNote ?? '';
    _selectedDomain = ex.competencyDomain;
    _pointsClaimed = ex.pointsClaimed;
    _fields['points']!.text = formatPoints(ex.pointsClaimed);
    _eligibility = true;
  }

  Future<void> _recomputeWarnings() async {
    final active = await _databaseService.getActiveCycle();
    if (active?.id == null || _selectedCategoryId == null) return;
    final pointsMap = await _databaseService.getPointsByCategory(active!.id!);
    final categoryEntry = pointsMap[_selectedCategoryId!] ?? const {'claimed': 0.0, 'effective': 0.0};
    final currentCategoryPoints = categoryEntry['claimed'] ?? 0;
    final currentCategoryEffective = categoryEntry['effective'] ?? 0;
    final category =
        kCpdCategories.firstWhere((c) => c['id'] == _selectedCategoryId);
    final cap = category['cap'] as double?;
    String? warning;
    if (cap != null && currentCategoryPoints + _pointsClaimed > cap) {
      final countable =
          (cap - currentCategoryPoints).clamp(0.0, _pointsClaimed).toDouble();
      final effectiveAfter = effectiveCategoryPoints(
        currentCategoryPoints + _pointsClaimed,
        _selectedCategoryId!,
      );
      warning =
          'Adding this activity will exceed the cap for ${category['name']} (cap: ${cap.toStringAsFixed(0)} pts). '
          'Only ${formatPoints(countable)} pts of your ${formatPoints(_pointsClaimed)} pts claimed will count towards your 60-point total. '
          'Your recertification total will count only ${formatPoints(effectiveAfter)} from this category.';
    }
    final cycleTotal = await _databaseService.getTotalPointsByCycle(active.id!);
    final effectiveDelta = effectiveCategoryPoints(
          currentCategoryPoints + _pointsClaimed,
          _selectedCategoryId!,
        ) -
        currentCategoryEffective;
    String? success;
    if (cycleTotal + effectiveDelta >= 60) {
      success =
          '🎉 Adding this activity will complete your 60-point recertification requirement!';
    }
    if (mounted) {
      setState(() {
        _warningText = warning;
        _successText = success;
        _pointsByCategory = pointsMap;
      });
    }
  }

  void _recomputePoints() {
    final duration = double.tryParse(_fields['durationHours']!.text) ?? 0;
    final count = int.tryParse(_fields['count']!.text) ?? 0;
    final minutes = int.tryParse(_fields['minutes']!.text) ?? 0;
    final years = double.tryParse(_fields['years']!.text) ?? 0;
    final contentHours = double.tryParse(_fields['contentHours']!.text) ?? 0;
    final sessions = int.tryParse(_fields['sessions']!.text) ?? 0;
    final minutesPerSession =
        int.tryParse(_fields['minutesPerSession']!.text) ?? 0;
    double points = double.tryParse(_fields['points']!.text) ?? 0;

    switch (_selectedCategoryId) {
      case 1:
        points = duration;
        break;
      case 2:
        points = duration * (_cat2Type == 'credit' ? 1.5 : 1.0);
        break;
      case 3:
        points = count * 0.25;
        break;
      case 4:
        points = _cat4Role == 'speaker' ? (minutes / 15) * 2 : duration * 2;
        break;
      case 5:
        final type = _fields['publicationType']!.text;
        points = switch (type) {
          'book' => 30,
          'chapter' => 10,
          'journal' => 8,
          'whitepaper' => 5,
          'blog' => 1,
          'exam' => count.toDouble(),
          'education' => (contentHours / 100) * 10,
          _ => 0,
        };
        break;
      case 6:
        points = years * 5;
        break;
      case 7:
        final type = _fields['publicationType']!.text;
        final per = switch (type) {
          'abstract' => 0.5,
          'fullpaper' => 1.0,
          'journalreview' => 1.5,
          'editorial' => 2.0,
          'thesis' => 3.0,
          _ => 0,
        };
        points = (per * count).toDouble();
        break;
      case 8:
        points = (sessions * minutesPerSession) / 60;
        break;
      case 9:
        points = duration;
        break;
      case 10:
        points = double.tryParse(_fields['points']!.text) ?? 0;
        break;
      default:
        break;
    }

    setState(() {
      _pointsClaimed = points;
      if ([1, 2, 3, 4, 5, 6, 7, 8, 9].contains(_selectedCategoryId)) {
        _fields['points']!.text = formatPoints(points);
      }
    });
    _recomputeWarnings();
  }

  Future<void> _save() async {
    final active = await _databaseService.getActiveCycle();
    if (!mounted) return;
    if (!_formKey.currentState!.validate() ||
        active?.id == null ||
        _selectedCategoryId == null) {
      return;
    }
    if ([1, 4, 8, 9, 10].contains(_selectedCategoryId) && !_eligibility) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please confirm eligibility for this category.')),
      );
      return;
    }
    if (!_hasRequiredCategoryFields(_selectedCategoryId!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete all required category fields.')),
      );
      return;
    }
    if (!_isDateNotInFuture(_dateLogged)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Activity date cannot be in the future.')),
      );
      return;
    }
    // We intentionally allow backdating: activities that occurred before
    // the current cycle's start are still recorded (helpful when the user
    // started journalling after the cycle began).

    setState(() => _saving = true);
    try {
      final cycleIdValue = active!.id!;
      final now = DateTime.now().toIso8601String();
      var evidence = _fields['evidence']!.text.trim();
      if (_crossProgram) {
        evidence = evidence.isEmpty
            ? 'Also claimed in another CPD program.'
            : '$evidence\nAlso claimed in another CPD program.';
      }
      final existing = widget.existingActivity;
      final isEdit = existing?.id != null;

      final activity = CpdActivity(
        id: existing?.id,
        userId: FirebaseAuth.instance.currentUser!.uid,
        cycleId: cycleIdValue,
        dateLogged: _dateLogged.toIso8601String().substring(0, 10),
        categoryId: _selectedCategoryId!,
        categoryName: _categoryName(_selectedCategoryId!),
        subcategory: _fields['subcategory']!.text.trim().isEmpty
            ? null
            : _fields['subcategory']!.text.trim(),
        activityDescription: _fields['activityName']!.text.trim(),
        providerName: _fields['provider']!.text.trim().isEmpty
            ? null
            : _fields['provider']!.text.trim(),
        durationHours: _durationHoursForSave(),
        pointsClaimed: _pointsClaimed,
        competencyDomain: _selectedDomain,
        evidenceNote: evidence.isEmpty ? null : evidence,
        createdAt: isEdit ? existing!.createdAt : now,
        updatedAt: now,
      );

      final duplicate = await _databaseService.hasPotentialDuplicate(
        cycleId: cycleIdValue,
        dateLogged: activity.dateLogged,
        categoryId: activity.categoryId,
        activityDescription: activity.activityDescription,
        providerName: activity.providerName,
        excludeId: existing?.id,
      );
      if (duplicate) {
        throw StateError('A matching activity already exists in this cycle.');
      }

      if (isEdit) {
        await _databaseService.updateActivity(activity);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Activity updated — ${formatPoints(_pointsClaimed)} pts')),
        );
      } else {
        await _databaseService.addActivity(activity);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Activity added — ${formatPoints(_pointsClaimed)} pts logged')),
        );
      }
      Navigator.of(context).pop(true);
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double? _durationHoursForSave() {
    if (_selectedCategoryId == 4 && _cat4Role == 'speaker') {
      final minutes = int.tryParse(_fields['minutes']!.text);
      if (minutes == null || minutes <= 0) return null;
      return minutes / 60.0;
    }
    final hours = double.tryParse(_fields['durationHours']!.text);
    return hours;
  }

  bool _hasRequiredCategoryFields(int categoryId) {
    bool hasText(String key) => _fields[key]!.text.trim().isNotEmpty;
    bool hasNumber(String key) => (double.tryParse(_fields[key]!.text) ?? 0) > 0;
    bool hasInt(String key) => (int.tryParse(_fields[key]!.text) ?? 0) > 0;

    switch (categoryId) {
      case 1:
      case 2:
      case 9:
        return hasText('activityName') && hasNumber('durationHours');
      case 3:
        return hasText('activityName') && hasInt('count');
      case 4:
        return hasText('activityName') &&
            (_cat4Role == 'speaker'
                ? hasInt('minutes')
                : hasNumber('durationHours'));
      case 5:
        if (!hasText('activityName') || !hasText('publicationType')) {
          return false;
        }
        if (_fields['publicationType']!.text == 'exam') return hasInt('count');
        if (_fields['publicationType']!.text == 'education') {
          return hasNumber('contentHours');
        }
        return true;
      case 6:
        return hasText('activityName') && hasNumber('years');
      case 7:
        return hasText('activityName') &&
            hasText('publicationType') &&
            hasInt('count');
      case 8:
        return hasText('activityName') &&
            hasInt('sessions') &&
            hasInt('minutesPerSession');
      case 10:
        return hasText('activityName') &&
            hasText('description') &&
            hasNumber('points');
      default:
        return hasText('activityName');
    }
  }

  bool _isDateNotInFuture(DateTime date) {
    final today = DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    return !d.isAfter(t);
  }

  String _categoryName(int id) => (kCpdCategories
      .firstWhere((element) => element['id'] == id)['name'] as String);

  int get _currentStep {
    if (_selectedCategoryId == null) return 1; // picking category
    final hasCategoryFields = _hasRequiredCategoryFields(_selectedCategoryId!);
    if (!hasCategoryFields) return 2;
    if (_selectedDomain == null) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.existingActivity != null ? 'Edit Activity' : 'Add Activity'),
      ),
      body: FutureBuilder(
        future: _databaseService.getActiveCycle(),
        builder: (context, snapshot) {
          final cycle = snapshot.data;
          if (cycle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _Stepper(currentStep: _currentStep),
                const SizedBox(height: 18),
                _StepLabel(
                    number: 1, label: 'Activity Date', current: _currentStep),
                const SizedBox(height: 8),
                _DateCard(
                  date: _dateLogged,
                  startDate: cycle.startDate,
                  endDate: cycle.endDate,
                  onTap: () async {
                    final today = DateTime.now();
                    // Allow backdating up to 3 years (a full CHIA cycle),
                    // independent of when this cycle started in the DB.
                    final cycleStart = DateTime.parse(cycle.startDate);
                    final threeYearsAgo =
                        today.subtract(const Duration(days: 1095));
                    final earliest = cycleStart.isBefore(threeYearsAgo)
                        ? cycleStart
                        : threeYearsAgo;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateLogged.isAfter(today)
                          ? today
                          : _dateLogged,
                      firstDate: earliest,
                      lastDate: today,
                      helpText: 'Select activity date (past dates allowed)',
                    );
                    if (picked != null) {
                      setState(() => _dateLogged = picked);
                    }
                  },
                ),
                const SizedBox(height: 18),
                _StepLabel(
                    number: 2,
                    label: 'Category Selection',
                    current: _currentStep),
                const SizedBox(height: 8),
                ...kCpdCategories.map((category) {
                  final id = category['id'] as int;
                  final selected = _selectedCategoryId == id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CategorySelectionCard(
                      id: id,
                      name: category['name'] as String,
                      cap: category['cap'] as double?,
                      rateDescription: category['rateDescription'] as String,
                      currentPoints: _pointsByCategory[id]?['claimed'] ?? 0,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = id;
                          _eligibility = false;
                          _recomputePoints();
                        });
                      },
                    ),
                  );
                }),
                if (_selectedCategoryId != null) ...[
                  const SizedBox(height: 8),
                  _StepLabel(
                      number: 3,
                      label: 'Details',
                      current: _currentStep),
                  const SizedBox(height: 8),
                  _SectionCard(child: _categoryForm()),
                ],
                const SizedBox(height: 18),
                _StepLabel(
                    number: 4,
                    label: 'Common Fields',
                    current: _currentStep),
                const SizedBox(height: 8),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedDomain,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Competency Domain (required)',
                        ),
                        selectedItemBuilder: (context) {
                          return kCompetencyDomains.map((domain) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${domain['code']} — ${domain['name']}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  color: context.appExt.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        items: kCompetencyDomains
                            .map(
                              (domain) => DropdownMenuItem(
                                value: domain['code'],
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: context.appExt.primaryTint,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        domain['code']!,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      domain['name']!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        validator: (value) =>
                            value == null ? 'Select a competency domain.' : null,
                        onChanged: (value) =>
                            setState(() => _selectedDomain = value),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fields['evidence'],
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Evidence note (optional)',
                          helperText:
                              'CHIA conducts random audits. Retain evidence such as certificates, attendance records, receipts, or supervisor endorsements.',
                          helperMaxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _crossProgram,
                        onChanged: (value) =>
                            setState(() => _crossProgram = value ?? false),
                        title: Text(
                          'This activity was also claimed in another CPD program',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appExt.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_warningText != null) ...[
                  const SizedBox(height: 12),
                  _Banner(
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.warning,
                    bg: context.appExt.warningSurface,
                    accent: AppColors.warning,
                    text: _warningText!,
                  ),
                ],
                if (_successText != null) ...[
                  const SizedBox(height: 12),
                  _Banner(
                    icon: Icons.celebration_rounded,
                    iconColor: AppColors.success,
                    bg: context.appExt.successSurface,
                    accent: AppColors.success,
                    text: _successText!,
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save Activity'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _categoryForm() {
    final id = _selectedCategoryId!;
    final children = <Widget>[
      TextFormField(
        controller: _fields['activityName'],
        decoration:
            const InputDecoration(labelText: 'Activity name / title'),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required.' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _fields['provider'],
        decoration: const InputDecoration(
            labelText: 'Provider / event / organisation'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _fields['subcategory'],
        decoration:
            const InputDecoration(labelText: 'Subcategory / role / format'),
      ),
      const SizedBox(height: 12),
    ];

    if ([1, 2, 9].contains(id)) {
      children.add(
        TextFormField(
          controller: _fields['durationHours'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Duration (hours)'),
          validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0
              ? 'Enter a valid duration.'
              : null,
          onChanged: (_) => _recomputePoints(),
        ),
      );
      children.add(const SizedBox(height: 12));
    }

    if (id == 2) {
      children.addAll([
        _RadioCard(
          value: 'credit',
          groupValue: _cat2Type,
          onChanged: (value) {
            setState(() => _cat2Type = value);
            _recomputePoints();
          },
          title: 'Credit-bearing (1.5 pts/hr)',
        ),
        const SizedBox(height: 8),
        _RadioCard(
          value: 'noncredit',
          groupValue: _cat2Type,
          onChanged: (value) {
            setState(() => _cat2Type = value);
            _recomputePoints();
          },
          title: 'Non-credit (1 pt/hr)',
        ),
        const SizedBox(height: 12),
      ]);
    }

    if ([3, 7].contains(id)) {
      children.add(
        TextFormField(
          controller: _fields['count'],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Number of items'),
          validator: (value) =>
              (int.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter a valid count.' : null,
          onChanged: (_) => _recomputePoints(),
        ),
      );
      children.add(const SizedBox(height: 12));
    }

    if (id == 4) {
      children.addAll([
        DropdownButtonFormField<String>(
          value: _cat4Role,
          decoration: const InputDecoration(labelText: 'Role'),
          items: const [
            DropdownMenuItem(
                value: 'speaker', child: Text('Speaker / Guest Lecturer')),
            DropdownMenuItem(value: 'panel', child: Text('Panel / Poster')),
            DropdownMenuItem(value: 'chair', child: Text('Chair')),
          ],
          onChanged: (value) {
            setState(() => _cat4Role = value!);
            _recomputePoints();
          },
        ),
        const SizedBox(height: 12),
        if (_cat4Role == 'speaker')
          TextFormField(
            controller: _fields['minutes'],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Minutes (2 pts / 15 min)'),
            validator: (value) =>
                (int.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter minutes.' : null,
            onChanged: (_) => _recomputePoints(),
          )
        else
          TextFormField(
            controller: _fields['durationHours'],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Duration (hours, 2 pts/hr)',
            ),
            validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0
                ? 'Enter a valid duration.'
                : null,
            onChanged: (_) => _recomputePoints(),
          ),
      ]);
    }

    if (id == 5) {
      children.addAll([
        DropdownButtonFormField<String>(
          value: _fields['publicationType']!.text.isEmpty
              ? null
              : _fields['publicationType']!.text,
          decoration: const InputDecoration(labelText: 'Publication type'),
          items: const [
            DropdownMenuItem(value: 'book', child: Text('Book / Text')),
            DropdownMenuItem(value: 'chapter', child: Text('Book / Chapter')),
            DropdownMenuItem(
                value: 'journal', child: Text('Peer-reviewed journal article')),
            DropdownMenuItem(
                value: 'whitepaper',
                child: Text('Newsletter / whitepaper / report')),
            DropdownMenuItem(value: 'blog', child: Text('Blog >600 words')),
            DropdownMenuItem(value: 'exam', child: Text('CHIA examination item')),
            DropdownMenuItem(
                value: 'education', child: Text('Formal education content')),
          ],
          onChanged: (value) {
            _fields['publicationType']!.text = value ?? '';
            _recomputePoints();
            setState(() {});
          },
          validator: (value) => value == null ? 'Select type.' : null,
        ),
        const SizedBox(height: 12),
      ]);
      if (_fields['publicationType']!.text == 'exam') {
        children.add(
          TextFormField(
            controller: _fields['count'],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Number of items'),
            validator: (value) =>
                (int.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter item count.' : null,
            onChanged: (_) => _recomputePoints(),
          ),
        );
        children.add(const SizedBox(height: 12));
      }
      if (_fields['publicationType']!.text == 'education') {
        children.add(
          TextFormField(
            controller: _fields['contentHours'],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Hours of content'),
            validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0
                ? 'Enter content hours.'
                : null,
            onChanged: (_) => _recomputePoints(),
          ),
        );
        children.add(const SizedBox(height: 12));
      }
    }

    if (id == 6) {
      children.add(
        TextFormField(
          controller: _fields['years'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Years of service (5 pts/year)',
            helperText: 'Volunteer service only. Must relate to health informatics.',
          ),
          onChanged: (_) => _recomputePoints(),
          validator: (value) =>
              (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter years.' : null,
        ),
      );
      children.add(const SizedBox(height: 12));
    }

    if (id == 7) {
      children.addAll([
        DropdownButtonFormField<String>(
          value: _fields['publicationType']!.text.isEmpty
              ? null
              : _fields['publicationType']!.text,
          decoration: const InputDecoration(
            labelText: 'Review type',
            helperText:
                'Eligible orgs: AIDH, HIMAA, HiNZ, IMIA, HIKM, HIMSS, AMIA',
            helperMaxLines: 2,
          ),
          items: const [
            DropdownMenuItem(
                value: 'abstract', child: Text('Conference abstract (0.5 pt)')),
            DropdownMenuItem(
                value: 'fullpaper', child: Text('Conference full paper (1 pt)')),
            DropdownMenuItem(
                value: 'journalreview', child: Text('Journal review (1.5 pts)')),
            DropdownMenuItem(
                value: 'editorial', child: Text('Editorial review (2 pts)')),
            DropdownMenuItem(value: 'thesis', child: Text('Thesis (3 pts)')),
          ],
          onChanged: (value) {
            _fields['publicationType']!.text = value ?? '';
            _recomputePoints();
            setState(() {});
          },
          validator: (value) => value == null ? 'Select review type.' : null,
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (id == 8) {
      children.addAll([
        _RadioCard(
          value: 'Mentor',
          groupValue: _cat8Role,
          onChanged: (value) => setState(() => _cat8Role = value),
          title: 'Mentor',
        ),
        const SizedBox(height: 8),
        _RadioCard(
          value: 'Mentee',
          groupValue: _cat8Role,
          onChanged: (value) => setState(() => _cat8Role = value),
          title: 'Mentee',
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _fields['sessions'],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Number of sessions'),
          validator: (value) =>
              (int.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter session count.' : null,
          onChanged: (_) => _recomputePoints(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _fields['minutesPerSession'],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Minutes per session'),
          validator: (value) =>
              (int.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter minutes per session.' : null,
          onChanged: (_) => _recomputePoints(),
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (id == 10) {
      children.addAll([
        TextFormField(
          controller: _fields['description'],
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(
              labelText: 'Description of learning / new skill'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required.' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _cat10Equivalent,
          decoration: const InputDecoration(
              labelText: 'Equivalent category for point calculation'),
          items: const [
            DropdownMenuItem(
                value: 'cat4',
                child: Text('Similar to Presentation (Cat 4)')),
            DropdownMenuItem(
                value: 'cat5', child: Text('Similar to Publication (Cat 5)')),
          ],
          onChanged: (value) => setState(() => _cat10Equivalent = value!),
        ),
        const SizedBox(height: 12),
      ]);
    }

    children.addAll([
      TextFormField(
        controller: _fields['points'],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        readOnly: [3, 5].contains(id),
        decoration: const InputDecoration(
          labelText: 'Points claimed',
          helperText: 'Auto-calculated for most categories — edit only if needed.',
          helperMaxLines: 2,
        ),
        onChanged: (_) {
          _pointsClaimed = double.tryParse(_fields['points']!.text) ?? 0;
          _recomputeWarnings();
        },
        validator: (value) =>
            (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Points must be > 0.' : null,
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: context.appExt.primaryTint,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _eligibility,
          onChanged: (value) => setState(() => _eligibility = value ?? false),
          title: Text(
            _eligibilityText(id),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: context.appExt.textPrimary,
            ),
          ),
        ),
      ),
      if (_helperText(id) != null) ...[
        const SizedBox(height: 8),
        Text(
          _helperText(id)!,
          style: TextStyle(color: context.appExt.textHint, fontSize: 12),
        ),
      ],
    ]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  String _eligibilityText(int id) {
    return switch (id) {
      1 => 'I confirm this event was educational, not promotional',
      4 => 'I confirm this is new, original content (not a repeat presentation)',
      8 =>
        'This mentoring involved structured learning goals and skill development focus',
      9 => 'I actively contributed — this was not passive attendance',
      10 =>
        'This activity involved new learning or skill development beyond routine duties',
      _ => 'I confirm this activity is eligible under CHIA CPD rules',
    };
  }

  String? _helperText(int id) {
    return switch (id) {
      1 => 'Note: promotional events (e.g. vendor product demos) are not eligible.',
      4 => 'Repeated presentations of the same content are not eligible.',
      8 =>
        'Must involve structured approach with clear learning goals and skill development focus.',
      9 => 'Must involve active contribution and practical application.',
      10 =>
        'Only qualifies if the activity involved new learning, research, or skill development beyond routine duties.',
      _ => null,
    };
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Date', 'Category', 'Details', 'Common'];
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            for (int i = 1; i <= 4; i++) ...[
              Expanded(
                child: _StepNode(
                  number: i,
                  label: labels[i - 1],
                  state: i < currentStep
                      ? _StepState.completed
                      : (i == currentStep
                          ? _StepState.active
                          : _StepState.upcoming),
                ),
              ),
              if (i < 4)
                Container(
                  width: 20,
                  height: 2,
                  color: i < currentStep
                      ? AppColors.success
                      : context.appExt.border,
                ),
            ],
          ],
        );
      },
    );
  }
}

enum _StepState { completed, active, upcoming }

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.number,
    required this.label,
    required this.state,
  });

  final int number;
  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Widget content;
    switch (state) {
      case _StepState.completed:
        bg = AppColors.success;
        content = const Icon(Icons.check, color: Colors.white, size: 16);
        break;
      case _StepState.active:
        bg = AppColors.primary;
        content = Text(
          '$number',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        );
        break;
      case _StepState.upcoming:
        bg = context.appExt.border;
        content = Text(
          '$number',
          style: TextStyle(
            color: context.appExt.textHint,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        );
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: content,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: switch (state) {
              _StepState.upcoming => context.appExt.textHint,
              _StepState.active => AppColors.primary,
              _StepState.completed => AppColors.success,
            },
            fontSize: 11,
            fontWeight: state == _StepState.active
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel(
      {required this.number, required this.label, required this.current});

  final int number;
  final String label;
  final int current;

  @override
  Widget build(BuildContext context) {
    final isActive = number == current;
    return Row(
      children: [
        Text(
          'Step $number',
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textHint,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: context.appExt.border,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.date,
    required this.startDate,
    required this.endDate,
    required this.onTap,
  });

  final DateTime date;
  final String startDate;
  final String endDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateText = date.toIso8601String().substring(0, 10);
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final daysAgo = DateTime(today.year, today.month, today.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    final subtitle = isToday
        ? 'Today · tap to pick a past date'
        : '$daysAgo ${daysAgo == 1 ? 'day' : 'days'} ago · tap to change';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appExt.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: context.appExt.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.appExt.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.appExt.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.appExt.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySelectionCard extends StatelessWidget {
  const _CategorySelectionCard({
    required this.id,
    required this.name,
    required this.cap,
    required this.rateDescription,
    required this.currentPoints,
    required this.selected,
    required this.onTap,
  });

  final int id;
  final String name;
  final double? cap;
  final String rateDescription;
  final double currentPoints;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forCategory(id);
    final reached = cap != null && currentPoints >= cap!;
    final exceeded = cap != null && currentPoints > cap!;
    final Color barColor = exceeded
        ? AppColors.warning
        : reached
            ? AppColors.success
            : AppColors.primary;
    final double? value =
        cap == null ? null : (currentPoints / cap!).clamp(0.0, 1.0).toDouble();

    return AnimatedScale(
      scale: selected ? 1.0 : 0.99,
      duration: const Duration(milliseconds: 140),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: selected ? context.appExt.primaryTint : context.appExt.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: context.appExt.cardShadow,
              border: Border(
                left: BorderSide(
                  color: selected ? AppColors.primary : accent,
                  width: 4,
                ),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 30,
                            child: selected
                                ? const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
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
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.appExt.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 4),
                Text(
                  '${cap == null ? 'Uncapped' : 'Cap: ${cap!.toStringAsFixed(0)} pts'} · $rateDescription',
                  style: TextStyle(
                    color: context.appExt.textHint,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                if (cap != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor: context.appExt.border,
                      color: barColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${formatPoints(currentPoints)} / ${cap!.toStringAsFixed(0)} pts logged',
                        style: TextStyle(
                          color: context.appExt.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (reached)
                        Text(
                          exceeded ? '⚠ Over cap' : '✓ Cap reached',
                          style: TextStyle(
                            color: barColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ] else
                  Text(
                    '${formatPoints(currentPoints)} pts logged so far',
                    style: TextStyle(
                      color: context.appExt.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.info_outline,
                        size: 18, color: context.appExt.textHint),
                    tooltip: 'What counts for this category?',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => CategoryInfoSheet.show(
                      context,
                      id,
                      showLogActivityButton: false,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appExt.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.appExt.cardShadow,
      ),
      child: child,
    );
  }
}

class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
  });

  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? context.appExt.primaryTint : context.appExt.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : context.appExt.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textHint,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.appExt.textPrimary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.accent,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final Color bg;
  final Color accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.appExt.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
