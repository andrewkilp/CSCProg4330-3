import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/route_arguments.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/trip.dart';
import '../../providers/trip_provider.dart';
import '../validation/trip_form_validator.dart';
import '../widgets/trip_date_field.dart';

/// One screen for creating and editing a trip. It owns only transient form
/// state; persistence and the trip list snapshot stay in TripProvider.
class TripFormScreen extends StatefulWidget {
  const TripFormScreen({super.key, required this.arguments});
  final TripFormArguments arguments;
  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Trip? _existing = widget.arguments.trip;
  late final TextEditingController _name = TextEditingController(
    text: _existing?.name ?? '',
  );
  late final TextEditingController _destination = TextEditingController(
    text: _existing?.destination ?? '',
  );
  late DateTime? _startDate = _existing?.startDate.toLocal();
  late DateTime? _endDate = _existing?.endDate?.toLocal();
  String? _startError;
  String? _endError;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _destination.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _name.text != (_existing?.name ?? '') ||
      _destination.text != (_existing?.destination ?? '') ||
      _startDate != _existing?.startDate.toLocal() ||
      _endDate != _existing?.endDate?.toLocal();

  Future<bool> _confirmDiscard() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your unsaved trip details will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              key: const ValueKey('trip-form-discard'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _save() async {
    if (_submitting) return;
    final fieldsValid = _formKey.currentState?.validate() ?? false;
    final startError = TripFormValidator.startDate(_startDate);
    final endError = TripFormValidator.endDate(_startDate, _endDate);
    setState(() {
      _startError = startError;
      _endError = endError;
    });
    if (!fieldsValid || startError != null || endError != null) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<TripProvider>();
    final destination = _destination.text.trim();
    try {
      final existing = _existing;
      if (existing == null) {
        await provider.createTrip(
          Trip(
            name: _name.text.trim(),
            destination: destination.isEmpty ? null : destination,
            startDate: _startDate!,
            endDate: _endDate,
            createdAt: DateTime.now(),
          ),
        );
      } else {
        await provider.updateTrip(
          existing.copyWith(
            name: _name.text.trim(),
            destination: destination.isEmpty ? null : destination,
            startDate: _startDate!,
            endDate: _endDate,
          ),
        );
      }
      navigator.pop(true);
    } on AppException catch (error) {
      // The entered values stay on screen so the user can retry.
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isDirty || _submitting,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      final navigator = Navigator.of(context);
      if (await _confirmDiscard()) navigator.pop();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.arguments.isEditing ? 'Edit trip' : 'New trip'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const ValueKey('trip-name-field'),
              controller: _name,
              autofocus: !widget.arguments.isEditing,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              validator: TripFormValidator.name,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Trip name',
                helperText: 'Required',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('trip-destination-field'),
              controller: _destination,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Destination',
                helperText: 'Optional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TripDateField(
              label: 'Start date',
              value: _startDate,
              errorText: _startError,
              onChanged: (value) => setState(() {
                _startDate = value;
                _startError = null;
                _endError = TripFormValidator.endDate(value, _endDate);
              }),
            ),
            const SizedBox(height: 16),
            TripDateField(
              label: 'End date',
              value: _endDate,
              errorText: _endError,
              onClear: () => setState(() {
                _endDate = null;
                _endError = null;
              }),
              onChanged: (value) => setState(() {
                _endDate = value;
                _endError = TripFormValidator.endDate(_startDate, value);
              }),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('trip-form-save'),
              onPressed: _submitting ? null : _save,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.arguments.isEditing ? 'Save trip' : 'Add trip'),
            ),
          ],
        ),
      ),
    ),
  );
}
