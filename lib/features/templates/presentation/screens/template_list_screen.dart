import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/navigation/route_arguments.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/packing_template.dart';
import '../../providers/template_provider.dart';
import '../widgets/delete_template_dialog.dart';

/// Starter and user-created templates in one list. Only template names load
/// here; a template's items load when its preview opens.
class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({super.key});
  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<TemplateProvider>().loadTemplates());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Consumer<TemplateProvider>(
      builder: (context, provider, _) => _body(context, provider),
    ),
  );

  Widget _body(BuildContext context, TemplateProvider provider) {
    final templates = provider.templates;
    if (provider.isInitialLoading) {
      return const Center(
        key: ValueKey('template-list-loading'),
        child: CircularProgressIndicator(),
      );
    }
    final error = provider.error;
    if (templates.isEmpty && error != null) {
      return ErrorState(
        title: 'Templates could not be loaded',
        message: error.message,
        actionLabel: 'Retry',
        onAction: () => unawaited(provider.loadTemplates(force: true)),
      );
    }
    if (templates.isEmpty) {
      return const EmptyState(
        title: 'Your templates',
        message: 'Save a packing list as a template to reuse it on any trip.',
      );
    }
    return Column(
      children: [
        if (error != null)
          MaterialBanner(
            key: const ValueKey('template-list-error-banner'),
            content: Text(error.message),
            actions: [
              TextButton(
                onPressed: () => unawaited(provider.loadTemplates(force: true)),
                child: const Text('Retry'),
              ),
            ],
          ),
        Expanded(
          child: ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                key: ValueKey('template-tile-${template.id}'),
                leading: const Icon(Icons.checklist_outlined),
                title: Text(template.name),
                trailing: IconButton(
                  tooltip: 'Delete template',
                  onPressed: () => unawaited(_delete(context, template)),
                  icon: const Icon(Icons.delete_outline),
                ),
                onTap: () => _openPreview(context, template),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openPreview(BuildContext context, PackingTemplate template) {
    final id = template.id;
    if (id == null) return;
    unawaited(
      Navigator.of(context).pushNamed(
        AppRoutes.templatePreview,
        arguments: TemplatePreviewArguments(
          templateId: id,
          templateName: template.name,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, PackingTemplate template) async {
    final id = template.id;
    if (id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<TemplateProvider>();
    if (!await DeleteTemplateDialog.confirm(context, template.name)) return;
    try {
      await provider.deleteTemplate(id);
      messenger.showSnackBar(
        SnackBar(content: Text('Deleted ${template.name}.')),
      );
    } on AppException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
