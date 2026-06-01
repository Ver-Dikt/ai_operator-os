import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../screens/agents/agents_screen.dart';
import '../screens/browser/browser_hub_screen.dart';
import '../screens/cinema/director_screen.dart';
import '../screens/command_center_screen.dart';
import '../screens/content_factory/content_factory_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/generation/audio_generation_screen.dart';
import '../screens/generation/image_generation_screen.dart';
import '../screens/generation/video_generation_screen.dart';
import '../screens/history/render_history_screen.dart';
import '../screens/projects/projects_screen.dart';
import '../screens/providers/providers_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/social_intelligence/social_intelligence_screen.dart';
import '../screens/text_workspace/text_workspace_screen.dart';
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
    if (oldWidget.destination != widget.destination) _syncCurrentRoute();
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
    return Scaffold(
      body: Container(
        color: const Color(0xFF050609),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _StudioTopBar(
                destination: destination,
                onSelect: (value) => _goTo(context, value),
              ),
              Expanded(child: _screenFor(context, destination)),
            ],
          ),
        ),
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
      AppDestination.textWorkspace => TextWorkspaceScreen(
        onNavigate: (value) => _goTo(context, value),
      ),
      AppDestination.images => const ImageGenerationScreen(),
      AppDestination.video => const VideoGenerationScreen(),
      AppDestination.audio => const AudioGenerationScreen(),
      AppDestination.director => const DirectorScreen(),
      AppDestination.providers => const ProvidersScreen(),
      AppDestination.renderHistory => const RenderHistoryScreen(),
      AppDestination.socialIntelligence => const SocialIntelligenceScreen(),
      AppDestination.browserHub => const BrowserHubScreen(),
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

class _StudioTopBar extends StatelessWidget {
  const _StudioTopBar({required this.destination, required this.onSelect});

  final AppDestination destination;
  final ValueChanged<AppDestination> onSelect;

  static const _tabs = [
    _StudioTab(AppDestination.textWorkspace, 'AI Чат'),
    _StudioTab(AppDestination.images, 'Image'),
    _StudioTab(AppDestination.video, 'Видео'),
    _StudioTab(AppDestination.audio, 'Audio'),
    _StudioTab(AppDestination.director, 'Cinema'),
    _StudioTab(AppDestination.contentFactory, 'Маркетинг'),
    _StudioTab(AppDestination.workflows, 'Workflows', enabled: false),
    _StudioTab(AppDestination.browserHub, 'Браузер'),
    _StudioTab(AppDestination.renderHistory, 'History'),
    _StudioTab(AppDestination.agents, 'Agents', enabled: false),
    _StudioTab(AppDestination.tools, 'Apps', enabled: false),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 780;
    return Container(
      height: compact ? 94 : 50,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 18),
      decoration: const BoxDecoration(
        color: Color(0xE6050609),
        border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: compact ? _compactLayout(context) : _wideLayout(context),
    );
  }

  Widget _wideLayout(BuildContext context) {
    return Row(
      children: [
        _Logo(onTap: () => onSelect(AppDestination.commandCenter)),
        const SizedBox(width: 18),
        Expanded(
          child: _TabsScroller(
            destination: destination,
            tabs: _tabs,
            onSelect: onSelect,
          ),
        ),
        const SizedBox(width: 12),
        _BalancePill(),
        const SizedBox(width: 10),
        _TopIconButton(
          tooltip: 'Модели и провайдеры',
          icon: Icons.hub_outlined,
          onTap: () => onSelect(AppDestination.providers),
        ),
        _TopIconButton(
          tooltip: 'Настройки',
          icon: Icons.tune_rounded,
          onTap: () => onSelect(AppDestination.settings),
        ),
      ],
    );
  }

  Widget _compactLayout(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 47,
          child: Row(
            children: [
              _Logo(onTap: () => onSelect(AppDestination.commandCenter)),
              const Spacer(),
              _TopIconButton(
                tooltip: 'Модели и провайдеры',
                icon: Icons.hub_outlined,
                onTap: () => onSelect(AppDestination.providers),
              ),
              _TopIconButton(
                tooltip: 'Настройки',
                icon: Icons.tune_rounded,
                onTap: () => onSelect(AppDestination.settings),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 43,
          child: _TabsScroller(
            destination: destination,
            tabs: _tabs,
            onSelect: onSelect,
          ),
        ),
      ],
    );
  }
}

class _StudioTab {
  const _StudioTab(this.destination, this.label, {this.enabled = true});

  final AppDestination destination;
  final String label;
  final bool enabled;
}

class _Logo extends StatelessWidget {
  const _Logo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F7F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.layers_rounded,
              color: Colors.black,
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'OpenGenerativeAI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabsScroller extends StatelessWidget {
  const _TabsScroller({
    required this.destination,
    required this.tabs,
    required this.onSelect,
  });

  final AppDestination destination;
  final List<_StudioTab> tabs;
  final ValueChanged<AppDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: tabs.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final tab = tabs[index];
        final selected = destination == tab.destination;
        final activeDestination = {
          AppDestination.textWorkspace,
          AppDestination.images,
          AppDestination.video,
          AppDestination.audio,
          AppDestination.director,
          AppDestination.browserHub,
          AppDestination.renderHistory,
        }.contains(tab.destination);
        final enabled = tab.enabled && activeDestination;
        return Tooltip(
          message: enabled
              ? tab.label
              : 'Раздел будет подключен следующим этапом.',
          child: InkWell(
            onTap: enabled ? () => onSelect(tab.destination) : null,
            child: SizedBox(
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    enabled ? tab.label : '${tab.label} · Скоро',
                    style: TextStyle(
                      color: !enabled
                          ? const Color(0x55FFFFFF)
                          : selected
                          ? const Color(0xFFC8FFF4)
                          : const Color(0x99FFFFFF),
                      fontSize: enabled ? 12 : 11,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 2,
                    width: selected ? 26 : 0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8FFF4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BalancePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        children: [
          Icon(Icons.circle, color: Color(0xFF22C55E), size: 8),
          SizedBox(width: 8),
          Text(
            'Local prep mode',
            style: TextStyle(
              color: Color(0xDFFFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: const Color(0xBFFFFFFF),
      ),
    );
  }
}
