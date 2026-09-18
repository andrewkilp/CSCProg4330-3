import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/route_arguments.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../trips/domain/trip.dart';
import '../../../trips/providers/trip_provider.dart';
import '../../providers/template_provider.dart';
import '../widgets/apply_template_dialog.dart';

/// Choose the trip a template is applied to. The provider performs the copy
/// and coordinates the affected trip's packing data.
class ApplyTemplateScreen extends StatefulWidget {
  const ApplyTemplateScreen({super.key, required this.arguments});
  final TemplateApplicationArguments arguments;
  @override
  State<ApplyTemplateScreen> createState() => _ApplyTemplateScreenState();
}

class _ApplyTemplateScreenState extends State<ApplyTemplateScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<TripProvider>().loadTrips());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Apply ${widget.arguments.templateName}')),
    body: Consumer<TripProvider>(
      builder: (context, provider, _) {
        if (provider.isInitialLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final trips = provider.trips;
        final error = provider.error;
        if (trips.isEmpty && error != null) {
          return ErrorState(
            title: 'Trips could not be loaded',
            message: error.message,
            actionLabel: 'Retry',
            onAction: () => unawaited(provider.loadTrips(force: true)),
          );
        }
        if (trips.isEmpty) {
          return const EmptyState(
            title: 'No trips yet',
            message: 'Create a trip before applying a template.',
          );
        }
        return ListView.builder(
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            return ListTile(
              key: ValueKey('apply-target-${trip.id}'),
              leading: const Icon(Icons.luggage_outlined),
              title: Text(trip.name),
              subtitle: Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(trip.startDate.toLocal()),
              ),
              onTap: () => unawaited(_apply(context, trip)),
            );
          },
        );
      },
    ),
  );

  Future<void> _apply(BuildContext context, Trip trip) async {
    final id = trip.id;
    if (id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<TemplateProvider>();
    final confirmed = await ApplyTemplateDialog.confirm(
      context,
      templateName: widget.arguments.templateName,
      tripName: trip.name,
    );
    if (!confirmed) return;
    try {
      await provider.applyTemplateToTrip(widget.arguments.templateId, id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Applied ${widget.arguments.templateName} to ${trip.name}.',
          ),
        ),
      );
      navigator.pop();
    } on AppException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
