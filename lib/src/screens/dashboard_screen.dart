import 'package:flutter/material.dart';

import '../state/app_settings.dart';
import 'command_center_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenCatalog});

  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    return CommandCenterScreen(
      onNavigate: (destination) {
        if (destination == AppDestination.tools) {
          onOpenCatalog();
        }
      },
    );
  }
}
