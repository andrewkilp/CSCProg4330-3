import '../../features/packing/domain/packing_item.dart';
import '../../features/trips/domain/trip.dart';

/// Typed route payloads. The router validates these instead of casting, so a
/// missing or wrong argument reaches a recoverable page, never a crash.
class TripFormArguments {
  const TripFormArguments({this.trip});

  /// Null opens create mode; a value opens edit mode with existing values.
  final Trip? trip;
  bool get isEditing => trip != null;
}

class TripDetailsArguments {
  const TripDetailsArguments({required this.tripId});
  final int tripId;
}

class PackingItemFormArguments {
  const PackingItemFormArguments({
    required this.tripId,
    this.item,
    this.knownCategories = const <String>[],
  });
  final int tripId;
  final PackingItem? item;

  /// Categories already used in this trip, offered beside the defaults.
  final List<String> knownCategories;
  bool get isEditing => item != null;
}

class TemplatePreviewArguments {
  const TemplatePreviewArguments({
    required this.templateId,
    required this.templateName,
  });
  final int templateId;
  final String templateName;
}

class TemplateApplicationArguments {
  const TemplateApplicationArguments({
    required this.templateId,
    required this.templateName,
  });
  final int templateId;
  final String templateName;
}
