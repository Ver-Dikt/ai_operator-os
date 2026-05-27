import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/fluten_runtime_store.dart';
import 'shell/app_shell.dart';
import 'state/app_settings.dart';
import 'theme/app_theme.dart';

class AiOperatorApp extends StatefulWidget {
  const AiOperatorApp({super.key});

  @override
  State<AiOperatorApp> createState() => _AiOperatorAppState();
}

class _AiOperatorAppState extends State<AiOperatorApp> {
  late final Future<SharedPreferences> _preferencesFuture =
      SharedPreferences.getInstance();
  AppSettings? _settings;
  FlutenRuntimeStore? _runtimeStore;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _preferencesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            home: const _BootScreen(),
          );
        }

        _settings ??= AppSettings(preferences: snapshot.data!);
        _runtimeStore ??= FlutenRuntimeStore(preferences: snapshot.data!);

        return AppSettingsScope(
          notifier: _settings!,
          child: FlutenRuntimeScope(
            notifier: _runtimeStore!,
            child: AnimatedBuilder(
              animation: _settings!,
              builder: (context, _) => MaterialApp(
                title: 'AI Studio',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: _settings!.darkMode
                    ? ThemeMode.dark
                    : ThemeMode.light,
                initialRoute: _settings!.startupDestination.routePath,
                onGenerateRoute: (routeSettings) {
                  final destination = AppDestinationRoute.fromRoute(
                    routeSettings.name,
                  );
                  return PageRouteBuilder<void>(
                    settings: routeSettings,
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        AppShell(destination: destination),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 140),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class FlutenRuntimeScope extends InheritedNotifier<FlutenRuntimeStore> {
  const FlutenRuntimeScope({
    super.key,
    required FlutenRuntimeStore super.notifier,
    required super.child,
  });

  static FlutenRuntimeStore of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FlutenRuntimeScope>();
    assert(scope != null, 'FlutenRuntimeScope not found in context');
    return scope!.notifier!;
  }

  static FlutenRuntimeStore read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<FlutenRuntimeScope>();
    final widget = element?.widget as FlutenRuntimeScope?;
    assert(widget != null, 'FlutenRuntimeScope not found in context');
    return widget!.notifier!;
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings super.notifier,
    required super.child,
  });

  static AppSettings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found in context');
    return scope!.notifier!;
  }
}
