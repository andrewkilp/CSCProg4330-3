import '../../../core/errors/app_exception.dart';
import '../domain/packing_template.dart';
import '../domain/template_item.dart';
import '../domain/packing_template_repository.dart';
import '../../shared_data/providers/async_provider.dart';

class TemplateProvider extends AsyncProvider {
  /// The composition owner must reload active packing providers for this ID.
  /// Without an active detail provider, a no-op is safe: future details load fresh.
  TemplateProvider(this._repository, {required this.onTripItemsChanged});
  final PackingTemplateRepository _repository;
  final Future<void> Function(int tripId) onTripItemsChanged;
  List<PackingTemplate> _templates = const [];
  List<PackingTemplate> get templates => _templates;
  final Map<int, List<TemplateItem>> _items = {};
  Map<int, List<TemplateItem>> get templateItems => Map.unmodifiable(_items);
  final Map<int, Future<void>> _itemLoads = {};
  final Set<int> _loadingItemIds = {};
  Set<int> get loadingItemIds => Set.unmodifiable(_loadingItemIds);
  Future<void>? _loading;

  Future<void> _refresh() async {
    final templates = await _repository.getAllTemplates();
    if (isDisposed) return;
    _templates = List.unmodifiable(templates);
    final ids = templates.map((template) => template.id).toSet();
    _items.removeWhere((id, _) => !ids.contains(id));
    hasLoaded = true;
  }

  Future<void> loadTemplates({bool force = false}) {
    if (_loading != null) return _loading!;
    if (hasLoaded && !force) return Future.value();
    return _loading = operate(
      _refresh,
      loading: true,
    ).onError<AppException>((_, _) {}).whenComplete(() => _loading = null);
  }

  Future<void> loadTemplateItems(int templateId, {bool force = false}) {
    if (_itemLoads.containsKey(templateId)) return _itemLoads[templateId]!;
    if (_items.containsKey(templateId) && !force) return Future.value();
    return _itemLoads[templateId] =
        operate(() async {
          _loadingItemIds.add(templateId);
          changed();
          try {
            final items = await _repository.getTemplateItems(templateId);
            if (!isDisposed) _items[templateId] = List.unmodifiable(items);
          } finally {
            _loadingItemIds.remove(templateId);
          }
        }).onError<AppException>((_, _) {}).whenComplete(() {
          _itemLoads.remove(templateId);
        });
  }

  Future<int> saveTripAsTemplate(int tripId, String name) => operate(() async {
    final id = await _repository.saveTripAsTemplate(tripId, name);
    await refreshAfterWrite(_refresh);
    return id;
  }, mutation: true);

  Future<void> applyTemplateToTrip(int templateId, int tripId) =>
      operate(() async {
        await _repository.applyTemplateToTrip(templateId, tripId);
        await refreshAfterWrite(() => onTripItemsChanged(tripId));
      }, mutation: true);

  Future<void> deleteTemplate(int templateId) => operate(() async {
    await _repository.deleteTemplate(templateId);
    if (!isDisposed) _items.remove(templateId);
    await refreshAfterWrite(_refresh);
  }, mutation: true);
}
