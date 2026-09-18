import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/navigation/route_arguments.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/trip_card.dart';
import '../../domain/trip.dart';
import '../../providers/trip_provider.dart';
import '../trip_schedule_text.dart';
import '../trip_sections.dart';
import '../widgets/duplicate_trip_dialog.dart';
import '../widgets/trip_delete_dialog.dart';
import '../widgets/trip_section.dart';

class _SectionHeaderRow {
  const _SectionHeaderRow(this.title, this.tripCount);
  final String title;
  final int tripCount;
}

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});
  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  @override
  void initState() {
    super.initState();
    // Triggered exactly once here; never from build. A cached load is a no-op.
    unawaited(context.read<TripProvider>().loadTrips());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Consumer<TripProvider>(
      builder: (context, provider, _) => _body(context, provider),
    ),
    floatingActionButton: FloatingActionButton.extended(
      key: const ValueKey('create-trip-button'),
      tooltip: 'Create trip',
      onPressed: () => _openForm(context),
      icon: const Icon(Icons.add),
      label: const Text('Create trip'),
    ),
  );

  Widget _body(BuildContext context, TripProvider provider) {
    final trips = provider.trips;
    if (provider.isInitialLoading) {
      return const Center(
        key: ValueKey('trip-list-loading'),
        child: CircularProgressIndicator(),
      );
    }
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
      return EmptyState(
        title: 'Your trips',
        message: 'Create your first trip to start a packing list.',
        actionLabel: 'Create trip',
        onAction: () => _openForm(context),
      );
    }
    // `now` is captured once per build, outside the item builders.
    final now = DateTime.now();
    final sections = splitTrips(trips, now);
    final rows = <Object>[
      if (sections.upcoming.isNotEmpty) ...[
        _SectionHeaderRow('Upcoming', sections.upcoming.length),
        ...sections.upcoming,
      ],
      if (sections.past.isNotEmpty) ...[
        _SectionHeaderRow('Past', sections.past.length),
        ...sections.past,
      ],
    ];
    return Column(
      children: [
        if (error != null)
          MaterialBanner(
            key: const ValueKey('trip-list-error-banner'),
            content: Text(error.message),
            actions: [
              TextButton(
                onPressed: () => unawaited(provider.loadTrips(force: true)),
                child: const Text('Retry'),
              ),
            ],
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              if (row is _SectionHeaderRow) {
                return TripSectionHeader(
                  title: row.title,
                  tripCount: row.tripCount,
                );
              }
              final trip = row as Trip;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TripCard(
                  key: ValueKey('trip-card-${trip.id}'),
                  trip: trip,
                  scheduleLabel: tripScheduleLabel(trip, now),
                  onTap: () => _openTrip(context, trip),
                  onEdit: () => _openForm(context, trip: trip),
                  onDuplicate: () => unawaited(_duplicate(context, trip)),
                  onDelete: () => unawaited(_delete(context, trip)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openForm(BuildContext context, {Trip? trip}) => unawaited(
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.tripForm, arguments: TripFormArguments(trip: trip)),
  );

  void _openTrip(BuildContext context, Trip trip) {
    final id = trip.id;
    if (id == null) return;
    unawaited(
      Navigator.of(context).pushNamed(
        AppRoutes.tripDetails,
        arguments: TripDetailsArguments(tripId: id),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Trip trip) async {
    final id = trip.id;
    if (id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<TripProvider>();
    if (!await TripDeleteDialog.confirm(context, trip.name)) return;
    try {
      await provider.deleteTrip(id);
      messenger.showSnackBar(SnackBar(content: Text('Deleted ${trip.name}.')));
    } on AppException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _duplicate(BuildContext context, Trip trip) async {
    final id = trip.id;
    if (id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<TripProvider>();
    final request = await DuplicateTripDialog.request(context, trip);
    if (request == null) return;
    try {
      await provider.duplicateTrip(
        id,
        newName: request.name,
        newStartDate: request.startDate,
        newEndDate: request.endDate,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Duplicated as ${request.name}.')),
      );
    } on AppException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
