import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/navigation/route_arguments.dart';
import '../../../../shared/widgets/category_heading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/template_item.dart';
import '../../providers/template_provider.dart';
import '../models/template_group.dart';

/// Read-only preview of one template. Its items are read the first time this
/// screen opens and then served from the provider's cache.
class TemplatePreviewScreen extends StatefulWidget {
  const TemplatePreviewScreen({super.key, required this.arguments});
  final TemplatePreviewArguments arguments;
  @override
  State<TemplatePreviewScreen> createState() => _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends State<TemplatePreviewScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      context.read<TemplateProvider>().loadTemplateItems(
        widget.arguments.templateId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.arguments.templateName)),
    body: Consumer<TemplateProvider>(
      builder: (context, provider, _) => _body(context, provider),
    ),
    floatingActionButton: FloatingActionButton.extended(
      key: const ValueKey('apply-template-button'),
      tooltip: 'Apply this template to a trip',
      onPressed: () => unawaited(
        Navigator.of(context).pushNamed(
          AppRoutes.templateApplication,
          arguments: TemplateApplicationArguments(
            templateId: widget.arguments.templateId,
            templateName: widget.arguments.templateName,
          ),
        ),
      ),
      icon: const Icon(Icons.playlist_add),
      label: const Text('Apply to a trip'),
    ),
  );

  Widget _body(BuildContext context, TemplateProvider provider) {
    final id = widget.arguments.templateId;
    final items = provider.templateItems[id];
    if (items == null) {
      final error = provider.error;
      if (error != null && !provider.loadingItemIds.contains(id)) {
        return ErrorState(
          title: 'Template could not be loaded',
          message: error.message,
          actionLabel: 'Retry',
          onAction: () =>
              unawaited(provider.loadTemplateItems(id, force: true)),
        );
      }
      return const Center(
        key: ValueKey('template-preview-loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (items.isEmpty) {
      return const EmptyState(
        title: 'No saved items',
        message: 'This template has no items yet.',
      );
    }
    final groups = groupTemplateItems(items);
    final rows = <Object>[
      for (final group in groups) ...[group.label, ...group.items],
    ];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row is String) {
          final group = groups.firstWhere((group) => group.label == row);
          return Semantics(
            header: true,
            child: CategoryHeading(
              category: row,
              itemCount: group.items.length,
            ),
          );
        }
        final item = row as TemplateItem;
        return ListTile(
          key: ValueKey('template-item-${item.id}'),
          dense: true,
          title: Text(item.name),
          subtitle: item.quantity > 1
              ? Text('Quantity: ${item.quantity}')
              : null,
        );
      },
    );
  }
}
