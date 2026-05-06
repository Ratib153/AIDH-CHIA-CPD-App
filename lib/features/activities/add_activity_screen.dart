import 'package:flutter/material.dart';

import '../../constants/cpd_categories.dart';
import '../../database/database_service.dart';
import '../../models/cpd_activity.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

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
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _recomputeWarnings() async {
    final active = await _databaseService.getActiveCycle();
    if (active?.id == null || _selectedCategoryId == null) return;
    final pointsMap = await _databaseService.getPointsByCategory(active!.id!);
    final currentCategoryPoints = pointsMap[_selectedCategoryId!] ?? 0;
    final category = kCpdCategories.firstWhere((c) => c['id'] == _selectedCategoryId);
    final cap = category['cap'] as double?;
    String? warning;
    if (cap != null && currentCategoryPoints + _pointsClaimed > cap) {
      final countable = (cap - currentCategoryPoints).clamp(0, _pointsClaimed);
      warning =
          'Adding this activity will exceed the cap for ${category['name']} (cap: ${cap.toStringAsFixed(0)} pts). '
          'Only ${countable.toStringAsFixed(1)} pts of your ${_pointsClaimed.toStringAsFixed(1)} pts claimed will count towards your 60-point total.';
    }
    final cycleTotal = await _databaseService.getTotalPointsByCycle(active.id!);
    String? success;
    if (cycleTotal + _pointsClaimed >= 60) {
      success = '🎉 Adding this activity will complete your 60-point recertification requirement!';
    }
    if (mounted) {
      setState(() {
        _warningText = warning;
        _successText = success;
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
    final minutesPerSession = int.tryParse(_fields['minutesPerSession']!.text) ?? 0;
    double points = double.tryParse(_fields['points']!.text) ?? 0;

    switch (_selectedCategoryId) {
      case 1:
        points = duration;
      case 2:
        points = duration * (_cat2Type == 'credit' ? 1.5 : 1.0);
      case 3:
        points = count * 0.25;
      case 4:
        points = _cat4Role == 'speaker' ? (minutes / 15) * 2 : duration * 2;
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
      case 6:
        points = years * 5;
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
        points = per * count;
      case 8:
        points = (sessions * minutesPerSession) / 60;
      case 9:
        points = duration;
      case 10:
        points = double.tryParse(_fields['points']!.text) ?? 0;
      default:
        break;
    }

    setState(() {
      _pointsClaimed = points;
      if ([1, 2, 3, 4, 5, 6, 7, 8, 9].contains(_selectedCategoryId)) {
        _fields['points']!.text = points.toStringAsFixed(2);
      }
    });
    _recomputeWarnings();
  }

  Future<void> _save() async {
    final active = await _databaseService.getActiveCycle();
    if (!_formKey.currentState!.validate() || active?.id == null || _selectedCategoryId == null) {
      return;
    }
    if (!_isDateInCycle(active!.startDate, active.endDate, _dateLogged)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date must be within active cycle range.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now().toIso8601String();
      var evidence = _fields['evidence']!.text.trim();
      if (_crossProgram) {
        evidence = evidence.isEmpty
            ? 'Also claimed in another CPD program.'
            : '$evidence\nAlso claimed in another CPD program.';
      }
      final activity = CpdActivity(
        cycleId: active.id!,
        dateLogged: _dateLogged.toIso8601String().substring(0, 10),
        categoryId: _selectedCategoryId!,
        categoryName: _categoryName(_selectedCategoryId!),
        subcategory: _fields['subcategory']!.text.trim().isEmpty
            ? null
            : _fields['subcategory']!.text.trim(),
        activityDescription: _fields['activityName']!.text.trim(),
        providerName: _fields['provider']!.text.trim().isEmpty ? null : _fields['provider']!.text.trim(),
        durationHours: double.tryParse(_fields['durationHours']!.text),
        pointsClaimed: _pointsClaimed,
        competencyDomain: _selectedDomain,
        evidenceNote: evidence.isEmpty ? null : evidence,
        createdAt: now,
        updatedAt: now,
      );
      await _databaseService.addActivity(activity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activity added — ${_pointsClaimed.toStringAsFixed(1)} pts logged')),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _isDateInCycle(String start, String end, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime.parse(start);
    final e = DateTime.parse(end);
    return !d.isBefore(DateTime(s.year, s.month, s.day)) && !d.isAfter(DateTime(e.year, e.month, e.day));
  }

  String _categoryName(int id) =>
      (kCpdCategories.firstWhere((element) => element['id'] == id)['name'] as String);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Activity')),
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
              padding: const EdgeInsets.all(16),
              children: [
                Text('Step 1 — Activity Date', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(_dateLogged.toIso8601String().substring(0, 10)),
                  subtitle: Text('Cycle: ${cycle.startDate} to ${cycle.endDate}'),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateLogged,
                      firstDate: DateTime.parse(cycle.startDate),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _dateLogged = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text('Step 2 — Category Selection', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...kCpdCategories.map((category) {
                  final selected = _selectedCategoryId == category['id'];
                  final cap = category['cap'];
                  return Card(
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = category['id'] as int;
                          _eligibility = false;
                          _recomputePoints();
                        });
                      },
                      title: Text('${category['id']}. ${category['name']}'),
                      subtitle: Text('Cap: ${cap == null ? 'Uncapped' : '$cap pts'} · ${category['rateDescription']}'),
                      trailing: selected ? const Icon(Icons.check_circle, color: Color(0xFF0082C8)) : null,
                    ),
                  );
                }),
                if (_selectedCategoryId != null) ...[
                  const SizedBox(height: 16),
                  Text('Step 3 — Category Specific Fields', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _categoryForm(),
                ],
                const SizedBox(height: 16),
                Text('Step 4 — Common Fields', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDomain,
                  decoration: const InputDecoration(
                    labelText: 'Competency Domain (required)',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: kCompetencyDomains
                      .map(
                        (domain) => DropdownMenuItem(
                          value: domain['code'],
                          child: Text('${domain['code']} — ${domain['name']}'),
                        ),
                      )
                      .toList(),
                  validator: (value) => value == null ? 'Select a competency domain.' : null,
                  onChanged: (value) => setState(() => _selectedDomain = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fields['evidence'],
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Evidence note (optional)',
                    helperText:
                        'CHIA conducts random audits. Retain evidence such as certificates, attendance records, receipts, or supervisor endorsements.',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                CheckboxListTile(
                  value: _crossProgram,
                  onChanged: (value) => setState(() => _crossProgram = value ?? false),
                  title: const Text('This activity was also claimed in another CPD program'),
                ),
                if (_warningText != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_warningText!),
                  ),
                if (_successText != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_successText!),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                      : const Text('Save Activity'),
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
    final text = Theme.of(context).textTheme.bodySmall;
    final children = <Widget>[
      TextFormField(
        controller: _fields['activityName'],
        decoration: const InputDecoration(
          labelText: 'Activity name / title',
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => value == null || value.trim().isEmpty ? 'Required.' : null,
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _fields['provider'],
        decoration: const InputDecoration(
          labelText: 'Provider / event / organisation',
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _fields['subcategory'],
        decoration: const InputDecoration(
          labelText: 'Subcategory / role / format',
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      const SizedBox(height: 10),
    ];

    if ([1, 2, 9].contains(id)) {
      children.add(
        TextFormField(
          controller: _fields['durationHours'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Duration (hours)',
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter a valid duration.' : null,
          onChanged: (_) => _recomputePoints(),
        ),
      );
      children.add(const SizedBox(height: 10));
    }

    if (id == 2) {
      children.addAll([
        RadioListTile<String>(
          value: 'credit',
          groupValue: _cat2Type,
          onChanged: (value) {
            setState(() => _cat2Type = value!);
            _recomputePoints();
          },
          title: const Text('Credit-bearing (1.5 pts/hr)'),
        ),
        RadioListTile<String>(
          value: 'noncredit',
          groupValue: _cat2Type,
          onChanged: (value) {
            setState(() => _cat2Type = value!);
            _recomputePoints();
          },
          title: const Text('Non-credit (1 pt/hr)'),
        ),
      ]);
    }

    if ([3, 7].contains(id)) {
      children.add(
        TextFormField(
          controller: _fields['count'],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of items',
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter a valid count.' : null,
          onChanged: (_) => _recomputePoints(),
        ),
      );
      children.add(const SizedBox(height: 10));
    }

    if (id == 4) {
      children.addAll([
        DropdownButtonFormField<String>(
          value: _cat4Role,
          decoration: const InputDecoration(
            labelText: 'Role',
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'speaker', child: Text('Speaker / Guest Lecturer')),
            DropdownMenuItem(value: 'panel', child: Text('Panel / Poster')),
          ],
          onChanged: (value) {
            setState(() => _cat4Role = value!);
            _recomputePoints();
          },
        ),
        const SizedBox(height: 10),
        if (_cat4Role == 'speaker')
          TextFormField(
            controller: _fields['minutes'],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutes (2 pts / 15 min)',
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter minutes.' : null,
            onChanged: (_) => _recomputePoints(),
          ),
      ]);
    }

    if (id == 5) {
      children.addAll([
        DropdownButtonFormField<String>(
          value: _fields['publicationType']!.text.isEmpty ? null : _fields['publicationType']!.text,
          decoration: const InputDecoration(
            labelText: 'Publication type',
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'book', child: Text('Book / Text')),
            DropdownMenuItem(value: 'chapter', child: Text('Book / Chapter')),
            DropdownMenuItem(value: 'journal', child: Text('Peer-reviewed journal article')),
            DropdownMenuItem(value: 'whitepaper', child: Text('Newsletter / whitepaper / report')),
            DropdownMenuItem(value: 'blog', child: Text('Blog >600 words')),
            DropdownMenuItem(value: 'exam', child: Text('CHIA examination item')),
            DropdownMenuItem(value: 'education', child: Text('Formal education content')),
          ],
          onChanged: (value) {
            _fields['publicationType']!.text = value ?? '';
            _recomputePoints();
            setState(() {});
          },
          validator: (value) => value == null ? 'Select type.' : null,
        ),
        const SizedBox(height: 10),
      ]);
      if (_fields['publicationType']!.text == 'exam') {
        children.add(
          TextFormField(
            controller: _fields['count'],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of items',
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (_) => _recomputePoints(),
          ),
        );
      }
      if (_fields['publicationType']!.text == 'education') {
        children.add(
          TextFormField(
            controller: _fields['contentHours'],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Hours of content',
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (_) => _recomputePoints(),
          ),
        );
      }
      children.add(const SizedBox(height: 10));
    }

    if (id == 6) {
      children.add(
        TextFormField(
          controller: _fields['years'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Years of service (5 pts/year)',
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (_) => _recomputePoints(),
          validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter years.' : null,
        ),
      );
      children.add(const SizedBox(height: 10));
      children.add(Text('Volunteer service only. Must relate to health informatics.', style: text));
    }

    if (id == 7) {
      children.addAll([
        DropdownButtonFormField<String>(
          value: _fields['publicationType']!.text.isEmpty ? null : _fields['publicationType']!.text,
          decoration: const InputDecoration(
            labelText: 'Review type',
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'abstract', child: Text('Conference abstract (0.5 pt)')),
            DropdownMenuItem(value: 'fullpaper', child: Text('Conference full paper (1 pt)')),
            DropdownMenuItem(value: 'journalreview', child: Text('Journal review (1.5 pts)')),
            DropdownMenuItem(value: 'editorial', child: Text('Editorial review (2 pts)')),
            DropdownMenuItem(value: 'thesis', child: Text('Thesis (3 pts)')),
          ],
          onChanged: (value) {
            _fields['publicationType']!.text = value ?? '';
            _recomputePoints();
            setState(() {});
          },
        ),
        const SizedBox(height: 8),
        Text('Eligible organisations hint: AIDH, HIMAA, HiNZ, IMIA, HIKM, HIMSS, AMIA', style: text),
      ]);
    }

    if (id == 8) {
      children.addAll([
        RadioListTile<String>(
          value: 'Mentor',
          groupValue: _cat8Role,
          onChanged: (value) => setState(() => _cat8Role = value!),
          title: const Text('Mentor'),
        ),
        RadioListTile<String>(
          value: 'Mentee',
          groupValue: _cat8Role,
          onChanged: (value) => setState(() => _cat8Role = value!),
          title: const Text('Mentee'),
        ),
        TextFormField(
          controller: _fields['sessions'],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of sessions',
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (_) => _recomputePoints(),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _fields['minutesPerSession'],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutes per session',
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (_) => _recomputePoints(),
        ),
      ]);
    }

    if (id == 10) {
      children.addAll([
        TextFormField(
          controller: _fields['description'],
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Description of learning / new skill',
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Required.' : null,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _cat10Equivalent,
          decoration: const InputDecoration(
            labelText: 'Equivalent category for point calculation',
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'cat4', child: Text('Similar to Presentation (Cat 4)')),
            DropdownMenuItem(value: 'cat5', child: Text('Similar to Publication (Cat 5)')),
          ],
          onChanged: (value) => setState(() => _cat10Equivalent = value!),
        ),
      ]);
    }

    children.addAll([
      const SizedBox(height: 10),
      TextFormField(
        controller: _fields['points'],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        readOnly: [3, 5].contains(id),
        decoration: const InputDecoration(
          labelText: 'Points claimed',
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (_) {
          _pointsClaimed = double.tryParse(_fields['points']!.text) ?? 0;
          _recomputeWarnings();
        },
        validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Points must be > 0.' : null,
      ),
      const SizedBox(height: 8),
      CheckboxListTile(
        value: _eligibility,
        onChanged: (value) => setState(() => _eligibility = value ?? false),
        title: Text(_eligibilityText(id)),
      ),
      if (_helperText(id) != null) Text(_helperText(id)!, style: text),
    ]);
    return Column(children: children);
  }

  String _eligibilityText(int id) {
    return switch (id) {
      1 => 'I confirm this event was educational, not promotional',
      4 => 'I confirm this is new, original content (not a repeat presentation)',
      8 => 'This mentoring involved structured learning goals and skill development focus',
      9 => 'I actively contributed — this was not passive attendance',
      10 => 'This activity involved new learning or skill development beyond routine duties',
      _ => 'I confirm this activity is eligible under CHIA CPD rules',
    };
  }

  String? _helperText(int id) {
    return switch (id) {
      1 => 'Note: promotional events (e.g. vendor product demos) are not eligible.',
      4 => 'Repeated presentations of the same content are not eligible.',
      8 => 'Must involve structured approach with clear learning goals and skill development focus.',
      9 => 'Must involve active contribution and practical application.',
      10 =>
        'Only qualifies if the activity involved new learning, research, or skill development beyond routine duties.',
      _ => null,
    };
  }
}
