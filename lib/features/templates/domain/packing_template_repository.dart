import 'packing_template.dart';
import 'template_item.dart';

/// Failures must throw typed AppException subclasses, never be swallowed.
/// Multi-row writes are atomic; template names must be nonblank.
abstract interface class PackingTemplateRepository {
  Future<List<PackingTemplate>> getAllTemplates();
  Future<List<TemplateItem>> getTemplateItems(int templateId);
  Future<int> saveTripAsTemplate(int tripId, String templateName);

  /// Skips duplicates when trimmed, case-insensitive name AND category match
  /// within the target trip, including items added during this operation.
  /// New rows are independent and start with isPacked false.
  Future<void> applyTemplateToTrip(int templateId, int tripId);

  /// Deletes the template and its owned items atomically.
  Future<void> deleteTemplate(int templateId);
}
