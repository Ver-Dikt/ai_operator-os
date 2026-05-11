import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../screens/catalog_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/settings_screen.dart';
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
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final settings = AppSettingsScope.of(context);
      if (settings.currentDestination != widget.destination) {
        settings.setDestination(widget.destination);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final destination = widget.destination;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            _DesktopSidebar(
              destination: destination,
              onSelect: (value) => _goTo(context, value),
              favoritesCount: settings.favoriteIds.length,
            ),
          Expanded(child: _screenFor(context, destination, settings)),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              height: 72,
              selectedIndex: destination.index,
              onDestinationSelected: (index) =>
                  _goTo(context, AppDestination.values[index]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_customize_outlined),
                  label: 'Главная',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Каталог',
                ),
                NavigationDestination(
                  icon: Icon(Icons.star_outline_rounded),
                  label: 'Избранное',
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
    final settings = AppSettingsScope.of(context);
    if (value == widget.destination) {
      return;
    }
    settings.setDestination(value);
    Navigator.of(context).pushNamed(value.routePath);
  }

  Widget _screenFor(
    BuildContext context,
    AppDestination destination,
    AppSettings settings,
  ) {
    return switch (destination) {
      AppDestination.dashboard => DashboardScreen(
        onOpenCatalog: () => _goTo(context, AppDestination.catalog),
      ),
      AppDestination.catalog => const CatalogScreen(),
      AppDestination.favorites => const FavoritesScreen(),
      AppDestination.settings => const SettingsScreen(),
    };
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destination,
    required this.onSelect,
    required this.favoritesCount,
  });

  final AppDestination destination;
  final ValueChanged<AppDestination> onSelect;
  final int favoritesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F16),
        border: Border(right: BorderSide(color: Color(0xFF202A3A))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandBlock(),
              const SizedBox(height: 18),
              _NavItem(
                icon: Icons.dashboard_customize_outlined,
                selectedIcon: Icons.dashboard_customize_rounded,
                label: 'Главная',
                selected: destination == AppDestination.dashboard,
                onTap: () => onSelect(AppDestination.dashboard),
              ),
              _NavItem(
                icon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view_rounded,
                label: 'Каталог',
                selected: destination == AppDestination.catalog,
                onTap: () => onSelect(AppDestination.catalog),
              ),
              _NavItem(
                icon: Icons.star_outline_rounded,
                selectedIcon: Icons.star_rounded,
                label: 'Избранное',
                trailing: favoritesCount == 0 ? null : '$favoritesCount',
                selected: destination == AppDestination.favorites,
                onTap: () => onSelect(AppDestination.favorites),
              ),
              _NavItem(
                icon: Icons.tune_rounded,
                selectedIcon: Icons.tune_rounded,
                label: 'Настройки',
                selected: destination == AppDestination.settings,
                onTap: () => onSelect(AppDestination.settings),
              ),
              const Spacer(),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6BE4C9), Color(0xFFFFB86B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF07100F),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Operator',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              Text(
                'tool stack',
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
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFF132A2A) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 21,
                  color: selected
                      ? const Color(0xFF6BE4C9)
                      : const Color(0xFF8B97A8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFFE8EEF8)
                          : const Color(0xFFA7B1C1),
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D2532),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      trailing!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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
        color: const Color(0xFF111722),
        border: Border.all(color: const Color(0xFF263244)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.circle, color: Color(0xFF6BE4C9), size: 10),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Preview live',
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
