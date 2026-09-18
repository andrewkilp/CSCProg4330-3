import 'package:flutter/material.dart';

import '../../domain/trip.dart';
import '../validation/trip_form_validator.dart';
import 'trip_date_field.dart';

/// Values the user chose for a copy. The provider performs the duplication;
/// this dialog never builds or saves copied packing items.
class DuplicateTripRequest {
  const DuplicateTripRequest({
    required this.name,
    required this.startDate,
    this.endDate,
  });
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
}

class DuplicateTripDialog extends StatefulWidget {
  const DuplicateTripDialog({super.key, required this.trip});
  final Trip trip;

  static Future<DuplicateTripRequest?> request(
    BuildContext context,
    Trip trip,
  ) => showDialog<DuplicateTripRequest>(
    context: context,
    builder: (context) => DuplicateTripDialog(trip: trip),
  );

  @override
  State<DuplicateTripDialog> createState() => _DuplicateTripDialogState();
}

class _DuplicateTripDialogState extends State<DuplicateTripDialog> {
  late final TextEditingController _name = TextEditingController(
    text: '${widget.trip.name} copy',
  );
  late DateTime? _startDate = widget.trip.startDate.toLocal();
  late DateTime? _endDate = widget.trip.endDate?.toLocal();
  String? _nameError;
  String? _startError;
  String? _endError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final nameError = TripFormValidator.name(_name.text);
    final startError = TripFormValidator.startDate(_startDate);
    final endError = TripFormValidator.endDate(_startDate, _endDate);
    if (nameError != null || startError != null || endError != null) {
      setState(() {
        _nameError = nameError;
        _startError = startError;
        _endError = endError;
      });
      return;
    }
    Navigator.of(context).pop(
      DuplicateTripRequest(
        name: _name.text.trim(),
        startDate: _startDate!,
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Duplicate trip'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Packing items from "${widget.trip.name}" are copied and start '
            'unpacked.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('duplicate-trip-name'),
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'New trip name',
              errorText: _nameError,
              border: const OutlineInputBorder(),
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
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('duplicate-trip-confirm'),
        onPressed: _submit,
        child: const Text('Duplicate'),
      ),
    ],
  );
}
