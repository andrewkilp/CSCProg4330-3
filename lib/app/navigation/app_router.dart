import 'package:flutter/material.dart';

import '../../features/packing/presentation/screens/packing_item_form_screen.dart';
import '../../features/packing/presentation/screens/packing_list_screen.dart';
import '../../features/templates/presentation/screens/apply_template_screen.dart';
import '../../features/templates/presentation/screens/template_preview_screen.dart';
import '../../features/trips/presentation/screens/trip_form_screen.dart';
import '../theme/theme_controller.dart';
import 'app_routes.dart';
import 'home_shell.dart';
import 'route_arguments.dart';
import 'route_error_page.dart';

/// Central named-route generation and argument validation. Screens receive
/// plain identifiers and immutable values, never providers or repositories.
class AppRouter {
  const AppRouter({required this.themeController});
  final ThemeController themeController;

  Route<Object?> onGenerateRoute(RouteSettings settings) =>
      MaterialPageRoute<Object?>(
        settings: settings,
        builder: (context) => _destination(settings),
      );

  Widget _destination(RouteSettings settings) {
    final arguments = settings.arguments;
    switch (settings.name) {
      case AppRoutes.home:
        return HomeShell(themeController: themeController);
      case AppRoutes.tripForm:
        if (arguments == null) {
          return const TripFormScreen(arguments: TripFormArguments());
        }
        return arguments is TripFormArguments
            ? TripFormScreen(arguments: arguments)
            : const RouteErrorPage(
                message: 'That trip could not be opened for editing.',
              );
      case AppRoutes.tripDetails:
        return arguments is TripDetailsArguments
            ? PackingListScreen(tripId: arguments.tripId)
            : const RouteErrorPage(
                message: 'Open a packing list from your trips.',
              );
      case AppRoutes.itemForm:
        return arguments is PackingItemFormArguments
            ? PackingItemFormScreen(arguments: arguments)
            : const RouteErrorPage(
                message: 'Open an item from a trip packing list.',
              );
      case AppRoutes.templatePreview:
        return arguments is TemplatePreviewArguments
            ? TemplatePreviewScreen(arguments: arguments)
            : const RouteErrorPage(
                message: 'Open a template from your template list.',
              );
      case AppRoutes.templateApplication:
        return arguments is TemplateApplicationArguments
            ? ApplyTemplateScreen(arguments: arguments)
            : const RouteErrorPage(
                message: 'Choose a template before applying it.',
              );
      default:
        return const RouteErrorPage();
    }
  }
}
