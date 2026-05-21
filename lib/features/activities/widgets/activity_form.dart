import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../data/activity_repository.dart';
import '../models/activity.dart';

class ActivityForm extends StatefulWidget {
  const ActivityForm({super.key, this.existing});

  final Activity? existing;

  bool get isEdit => existing != null;

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _pointsController;
  late final TextEditingController _notesController;
  late String _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _pointsController = TextEditingController(
      text: existing != null ? existing.points.toString() : '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _category = existing?.category ?? kActivityCategories.first;
    _date = existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pointsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final points = double.parse(_pointsController.text.trim());
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    if (widget.isEdit) {
      final updated = widget.existing!.copyWith(
        title: title,
        category: _category,
        date: _date,
        points: points,
        notes: notes,
      );
      context.read<ActivityRepository>().update(updated);
    } else {
      context.read<ActivityRepository>().add(
        title: title,
        category: _category,
        date: _date,
        points: points,
        notes: notes,
      );
    }

    Navigator.of(context).pop(true);
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _validatePoints(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Must be a number';
    if (parsed <= 0) return 'Must be greater than 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Activity' : 'Add Activity'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: _validateRequired,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: kActivityCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
              validator: _validateRequired,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Date'),
              child: Row(
                children: [
                  Expanded(child: Text(dateLabel)),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Pick date'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pointsController,
              decoration: const InputDecoration(labelText: 'Points'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _validatePoints,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(widget.isEdit ? 'Save changes' : 'Add activity'),
            ),
          ],
        ),
      ),
    );
  }
}
