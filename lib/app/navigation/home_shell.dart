import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';
import '../../features/trips/presentation/screens/trip_list_screen.dart';
import '../../features/templates/presentation/template_list_placeholder.dart';
import '../../features/settings/presentation/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.themeController});
  final ThemeController themeController;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final _pages = <Widget>[
    const TripListScreen(),
    const TemplateListPlaceholder(),
    SettingsScreen(controller: widget.themeController),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PackMate')),
    body: IndexedStack(index: _index, children: _pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (index) => setState(() => _index = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.luggage_outlined),
          label: 'Trips',
        ),
        NavigationDestination(icon: Icon(Icons.checklist), label: 'Templates'),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    ),
  );
}
