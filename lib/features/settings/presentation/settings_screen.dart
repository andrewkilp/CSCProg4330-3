import 'package:flutter/material.dart';

import '../../../app/theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final ThemeController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Theme', style: Theme.of(context).textTheme.headlineSmall),
        for (final mode in ThemeMode.values)
          Semantics(
            selected: controller.mode == mode,
            child: ListTile(
              title: Text(switch (mode) {
                ThemeMode.system => 'System',
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
              }),
              leading: Icon(
                controller.mode == mode
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              selected: controller.mode == mode,
              onTap: () => controller.setMode(mode),
            ),
          ),
        if (controller.error != null) Text(controller.error!),
      ],
    ),
  );
}
