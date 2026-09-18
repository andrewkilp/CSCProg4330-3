import 'package:flutter/material.dart';

/// Tappable date field shared by the trip form and the duplicate dialog.
/// It only reports the chosen local date; callers own validation and state.
class TripDateField extends StatelessWidget {
  const TripDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.onClear,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final selected = value;
    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
          suffixIcon: selected != null && onClear != null
              ? IconButton(
                  tooltip: 'Clear $label',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                )
              : const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          selected == null
              ? 'Not set'
              : localizations.formatMediumDate(selected.toLocal()),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final today = DateTime.now();
    final initial =
        value?.toLocal() ?? DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 10),
      helpText: label,
    );
    if (picked != null) onChanged(picked);
  }
}
