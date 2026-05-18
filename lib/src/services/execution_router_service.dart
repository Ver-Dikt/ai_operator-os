import '../models/ai_provider.dart';
import '../models/execution_mode.dart';
import '../models/execution_route.dart';
import 'provider_registry.dart';

class ExecutionRouterService {
  const ExecutionRouterService({this.registry = const ProviderRegistry()});

  final ProviderRegistry registry;

  ExecutionRoute resolveRoute({
    required String workspaceType,
    String? toolId,
    Set<String> configuredApiProviderIds = const {},
    Map<String, LocalRuntimeState> localRuntimeStates = const {},
  }) {
    final normalizedWorkspace = workspaceType.trim().toLowerCase();
    final provider = registry.getProviderForToolId(toolId);
    final runtimeState = localRuntimeStates[provider.id];

    if (_canUseLocal(provider, normalizedWorkspace, runtimeState)) {
      return ExecutionRoute(
        routeType: provider.id == 'n8n'
            ? ExecutionRouteType.hybridFallback
            : ExecutionRouteType.local,
        providerId: provider.id,
        statusLabel: '${provider.name} Connected',
        reason: 'Local runtime is available for this workspace.',
        workspaceType: normalizedWorkspace,
        toolId: toolId,
      );
    }

    if (_canUseApi(provider, configuredApiProviderIds)) {
      return ExecutionRoute(
        routeType: ExecutionRouteType.api,
        providerId: provider.id,
        statusLabel: '${provider.name} API Ready',
        reason: 'Mock API key is present for this provider.',
        workspaceType: normalizedWorkspace,
        toolId: toolId,
      );
    }

    if (_canUseBrowser(provider)) {
      return ExecutionRoute(
        routeType: ExecutionRouteType.browserLaunch,
        providerId: provider.id,
        statusLabel: 'Browser Route Ready',
        reason: _fallbackReason(provider, runtimeState),
        workspaceType: normalizedWorkspace,
        toolId: toolId,
      );
    }

    final fallback = registry.getFallbackProvider(normalizedWorkspace);
    return ExecutionRoute(
      routeType: ExecutionRouteType.manual,
      providerId: fallback.id,
      statusLabel: 'Manual Fallback',
      reason:
          'No configured provider is ready; copy prompt and continue manually.',
      workspaceType: normalizedWorkspace,
      toolId: toolId,
    );
  }

  bool _canUseLocal(
    AiProvider provider,
    String workspaceType,
    LocalRuntimeState? runtimeState,
  ) {
    if (provider.type != AiProviderType.local && provider.id != 'n8n') {
      return false;
    }
    if (!provider.supportedWorkspaces.contains(workspaceType)) return false;
    return runtimeState == LocalRuntimeState.connected ||
        provider.status == AiProviderStatus.connectedMock;
  }

  bool _canUseApi(AiProvider provider, Set<String> configuredApiProviderIds) {
    if (provider.type != AiProviderType.api &&
        provider.type != AiProviderType.hybrid) {
      return false;
    }
    return provider.apiKeyRequired &&
        configuredApiProviderIds.contains(provider.id);
  }

  bool _canUseBrowser(AiProvider provider) {
    return provider.type == AiProviderType.browser ||
        provider.status == AiProviderStatus.available ||
        provider.executionModes.contains(ExecutionMode.browserLaunch) ||
        provider.id == 'manual-browser';
  }

  String _fallbackReason(AiProvider provider, LocalRuntimeState? runtimeState) {
    if (provider.apiKeyRequired) {
      return 'API key needed; using browser/manual route.';
    }
    if (runtimeState == LocalRuntimeState.unavailable) {
      return 'Runtime offline; using browser/manual route.';
    }
    return 'Provider execution is not configured; using manual browser route.';
  }
}
