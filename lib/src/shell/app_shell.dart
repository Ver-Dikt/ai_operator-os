import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../screens/agents/agents_screen.dart';
import '../screens/command_center_screen.dart';
import '../screens/content_factory/content_factory_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/projects/projects_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tools/tools_screen.dart';
import '../screens/use_cases/use_cases_screen.dart';
import '../screens/workflows/workflows_screen.dart';
import '../state/app_settings.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.destination});

  final AppDestination destination;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncCurrentRoute();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destination != widget.destination) {
      _syncCurrentRoute();
    }
  }

  void _syncCurrentRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final settings = AppSettingsScope.of(context);
      if (settings.currentDestination != widget.destination) {
        settings.setDestination(widget.destination);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    final commandWorkspace = destination == AppDestination.commandCenter;
    final mobileDestinations = const [
      AppDestination.commandCenter,
      AppDestination.tools,
      AppDestination.agents,
      AppDestination.workflows,
      AppDestination.settings,
    ];
    final mobileIndex = mobileDestinations.contains(destination)
        ? mobileDestinations.indexOf(destination)
        : 0;

    return Scaffold(
      body: Row(
        children: [
          if (isWide && !commandWorkspace)
            _DesktopSidebar(
              destination: destination,
              onSelect: (value) => _goTo(context, value),
            ),
          Expanded(child: _screenFor(context, destination)),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              height: 72,
              selectedIndex: mobileIndex,
              onDestinationSelected: (index) =>
                  _goTo(context, mobileDestinations[index]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_customize_outlined),
                  label: 'Главная',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Инструменты',
                ),
                NavigationDestination(
                  icon: Icon(Icons.smart_toy_outlined),
                  label: 'Агенты',
                ),
                NavigationDestination(
                  icon: Icon(Icons.schema_outlined),
                  label: 'Сценарии',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_rounded),
                  label: 'Настройки',
                ),
              ],
            ),
    );
  }

  void _goTo(BuildContext context, AppDestination value) {
    if (value == widget.destination) return;
    AppSettingsScope.of(context).setDestination(value);
    Navigator.of(context).pushNamed(value.routePath);
  }

  Widget _screenFor(BuildContext context, AppDestination destination) {
    return switch (destination) {
      AppDestination.commandCenter => CommandCenterScreen(
        onNavigate: (value) => _goTo(context, value),
      ),
      AppDestination.tools => const ToolsScreen(),
      AppDestination.agents => const AgentsScreen(),
      AppDestination.workflows => const WorkflowsScreen(),
      AppDestination.contentFactory => const ContentFactoryScreen(),
      AppDestination.useCases => const UseCasesScreen(),
      AppDestination.projects => const ProjectsScreen(),
      AppDestination.favorites => const FavoritesScreen(),
      AppDestination.settings => const SettingsScreen(),
    };
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.destination, required this.onSelect});

  final AppDestination destination;
  final ValueChanged<AppDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = const [
      (
        AppDestination.commandCenter,
        Icons.dashboard_customize_outlined,
        Icons.dashboard_customize_rounded,
      ),
      (AppDestination.tools, Icons.grid_view_outlined, Icons.grid_view_rounded),
      (
        AppDestination.agents,
        Icons.smart_toy_outlined,
        Icons.smart_toy_rounded,
      ),
      (AppDestination.workflows, Icons.schema_outlined, Icons.schema_rounded),
      (
        AppDestination.contentFactory,
        Icons.factory_outlined,
        Icons.factory_rounded,
      ),
      (AppDestination.useCases, Icons.map_outlined, Icons.map_rounded),
      (
        AppDestination.projects,
        Icons.folder_open_outlined,
        Icons.folder_rounded,
      ),
      (
        AppDestination.favorites,
        Icons.star_outline_rounded,
        Icons.star_rounded,
      ),
      (AppDestination.settings, Icons.tune_rounded, Icons.tune_rounded),
    ];

    return Container(
      width: 252,
      decoration: const BoxDecoration(
        color: Color(0xFF070A0F),
        border: Border(right: BorderSide(color: Color(0xFF243244))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandBlock(),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  children: [
                    for (final item in items)
                      _NavItem(
                        key: ValueKey('nav-${item.$1.name}'),
                        icon: item.$2,
                        selectedIcon: item.$3,
                        label: item.$1.label,
                        selected: destination == item.$1,
                        onTap: () => onSelect(item.$1),
                      ),
                  ],
                ),
              ),
              const _StatusCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6BE4C9), Color(0xFFFFB86B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.blur_on_rounded, color: Color(0xFF07100F)),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Operator OS',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              Text(
                'центр управления',
                style: TextStyle(color: Color(0xFF8B97A8), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFF102A2A) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 42,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(
                  selected ? selectedIcon : icon,
                  size: 20,
                  color: selected
                      ? const Color(0xFF6BE4C9)
                      : const Color(0xFF8B97A8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFFE8EEF8)
                          : const Color(0xFFA7B1C1),
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D111A),
        border: Border.all(color: const Color(0xFF243244)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.circle, color: Color(0xFF6BE4C9), size: 10),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Локальный демо-режим',
              style: TextStyle(
                color: Color(0xFFC8D2E1),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
