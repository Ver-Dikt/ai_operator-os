import 'package:flutter/services.dart';

import '../models/ai_tool.dart';
import '../models/execution_route.dart';
import 'provider_registry.dart';
import 'tool_launcher_service.dart';

class ExecutionAdapterRequest {
  const ExecutionAdapterRequest({
    required this.route,
    required this.prompt,
    this.tool,
  });

  final ExecutionRoute route;
  final String prompt;
  final AiTool? tool;
}

class ExecutionAdapterResult {
  const ExecutionAdapterResult({
    required this.eventLabel,
    required this.stateLabel,
    this.openedToolId,
    this.copiedPrompt,
    this.generatedPrompt,
    this.userMessage,
    this.success = true,
  });

  final String eventLabel;
  final String stateLabel;
  final String? openedToolId;
  final String? copiedPrompt;
  final String? generatedPrompt;
  final String? userMessage;
  final bool success;
}

abstract class ExecutionAdapter {
  const ExecutionAdapter();

  Future<ExecutionAdapterResult> launch(ExecutionAdapterRequest request);

  Future<ExecutionAdapterResult> copyPrompt(
    ExecutionAdapterRequest request,
  ) async {
    await Clipboard.setData(ClipboardData(text: request.prompt));
    return ExecutionAdapterResult(
      eventLabel: 'Prompt copied',
      stateLabel: 'Prompt Copied',
      copiedPrompt: request.prompt,
      userMessage: 'Промпт скопирован',
    );
  }
}

class ManualExecutionAdapter extends ExecutionAdapter {
  const ManualExecutionAdapter();

  @override
  Future<ExecutionAdapterResult> launch(ExecutionAdapterRequest request) async {
    await Clipboard.setData(ClipboardData(text: request.prompt));
    return ExecutionAdapterResult(
      eventLabel: 'Manual workflow ready',
      stateLabel: 'Manual workflow ready',
      copiedPrompt: request.prompt,
      userMessage: 'Manual workflow ready',
    );
  }
}

class BrowserLaunchAdapter extends ExecutionAdapter {
  const BrowserLaunchAdapter({this.launcher = const ToolLauncherService()});

  final ToolLauncherService launcher;

  @override
  Future<ExecutionAdapterResult> launch(ExecutionAdapterRequest request) async {
    final tool = request.tool;
    if (tool == null) {
      return const ExecutionAdapterResult(
        eventLabel: 'Browser route unavailable',
        stateLabel: 'Manual Fallback',
        userMessage: 'URL инструмента не задан',
        success: false,
      );
    }

    final opened = await launcher.continueInTool(tool, request.prompt);
    if (!opened) {
      return const ExecutionAdapterResult(
        eventLabel: 'Browser route unavailable',
        stateLabel: 'Manual Fallback',
        userMessage: 'URL инструмента не задан',
        success: false,
      );
    }

    return ExecutionAdapterResult(
      eventLabel: 'Opened ${tool.name}',
      stateLabel: 'Opened ${tool.name}',
      openedToolId: tool.id,
      generatedPrompt: request.prompt,
      userMessage: 'Открыт ${tool.name}. Prompt уже в буфере',
    );
  }
}

class LocalExecutionAdapter extends ExecutionAdapter {
  const LocalExecutionAdapter({this.registry = const ProviderRegistry()});

  final ProviderRegistry registry;

  @override
  Future<ExecutionAdapterResult> launch(ExecutionAdapterRequest request) async {
    final provider = registry.getProviderById(request.route.providerId);
    final name = provider?.name ?? request.route.providerId;
    final ready =
        request.route.routeType == ExecutionRouteType.local ||
        request.route.routeType == ExecutionRouteType.hybridFallback;
    return ExecutionAdapterResult(
      eventLabel: ready ? '$name runtime ready' : 'Local runtime unavailable',
      stateLabel: ready ? '$name runtime ready' : 'Local runtime unavailable',
      generatedPrompt: request.prompt,
      userMessage: ready
          ? 'Preparing local runtime: $name'
          : 'Local runtime unavailable',
      success: ready,
    );
  }
}

class ApiExecutionAdapter extends ExecutionAdapter {
  const ApiExecutionAdapter({this.registry = const ProviderRegistry()});

  final ProviderRegistry registry;

  @override
  Future<ExecutionAdapterResult> launch(ExecutionAdapterRequest request) async {
    final provider = registry.getProviderById(request.route.providerId);
    final name = provider?.name ?? request.route.providerId;
    final ready = request.route.routeType == ExecutionRouteType.api;
    return ExecutionAdapterResult(
      eventLabel: ready ? '$name provider ready' : 'API key required',
      stateLabel: ready ? '$name provider ready' : 'API key required',
      generatedPrompt: request.prompt,
      userMessage: ready ? 'Preparing $name provider...' : 'API key required',
      success: ready,
    );
  }
}

class ExecutionAdapterFactory {
  const ExecutionAdapterFactory();

  ExecutionAdapter adapterFor(ExecutionRoute route) {
    return switch (route.routeType) {
      ExecutionRouteType.local ||
      ExecutionRouteType.hybridFallback => const LocalExecutionAdapter(),
      ExecutionRouteType.api => const ApiExecutionAdapter(),
      ExecutionRouteType.browserLaunch => const BrowserLaunchAdapter(),
      ExecutionRouteType.manual => const ManualExecutionAdapter(),
    };
  }
}
