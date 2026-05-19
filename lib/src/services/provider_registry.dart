import '../models/ai_provider.dart';
import '../models/execution_mode.dart';

const seedProviders = <AiProvider>[
  AiProvider(
    id: 'chatgpt',
    name: 'ChatGPT',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['text', 'agents'],
    description: 'OpenAI ChatGPT provider for text, coding, and operator chat.',
    baseUrl: 'https://chatgpt.com',
    apiKeyRequired: true,
    notes:
        'Text runtime metadata only. Direct API calls are not connected yet.',
  ),
  AiProvider(
    id: 'claude',
    name: 'Claude',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['text', 'agents'],
    description: 'Anthropic Claude provider for writing and analysis.',
    baseUrl: 'https://claude.ai',
    apiKeyRequired: true,
    notes:
        'Text runtime metadata only. Direct API calls are not connected yet.',
  ),
  AiProvider(
    id: 'openrouter',
    name: 'OpenRouter',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['text', 'agents'],
    description: 'API gateway for text models and agent routing.',
    baseUrl: 'https://openrouter.ai',
    apiKeyRequired: true,
    notes: 'Foundation only. API key storage and real calls are not connected.',
  ),
  AiProvider(
    id: 'gemini',
    name: 'Gemini',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['text', 'image', 'audio'],
    description: 'Google multimodal provider for text, image, and audio flows.',
    baseUrl: 'https://gemini.google.com',
    apiKeyRequired: true,
    notes: 'Registered as metadata only.',
  ),
  AiProvider(
    id: 'mistral',
    name: 'Mistral',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['text', 'agents'],
    description: 'Mistral Le Chat and API provider for text workflows.',
    baseUrl: 'https://chat.mistral.ai',
    apiKeyRequired: true,
    notes:
        'Text runtime metadata only. Direct API calls are not connected yet.',
  ),
  AiProvider(
    id: 'deepseek',
    name: 'DeepSeek',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['text', 'agents'],
    description: 'DeepSeek provider for coding, reasoning, and text chat.',
    baseUrl: 'https://www.deepseek.com/chat',
    apiKeyRequired: true,
    notes:
        'Text runtime metadata only. Direct API calls are not connected yet.',
  ),
  AiProvider(
    id: 'qwen',
    name: 'Qwen',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['text', 'agents'],
    description: 'Qwen chat provider for text and multimodal planning.',
    baseUrl: 'https://chat.qwen.ai',
    apiKeyRequired: true,
    notes:
        'Text runtime metadata only. Direct API calls are not connected yet.',
  ),
  AiProvider(
    id: 'huggingface',
    name: 'Hugging Face',
    type: AiProviderType.hybrid,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['text', 'image', 'video', 'audio'],
    description:
        'Hybrid model hub for hosted APIs, spaces, and model research.',
    baseUrl: 'https://huggingface.co',
    apiKeyRequired: true,
    notes: 'No hosted inference calls are connected yet.',
  ),
  AiProvider(
    id: 'ollama',
    name: 'Ollama',
    type: AiProviderType.local,
    executionModes: [ExecutionMode.local],
    status: AiProviderStatus.connectedMock,
    supportedWorkspaces: ['text', 'agents'],
    description: 'Local LLM runtime for text and agent planning workflows.',
    apiKeyRequired: false,
    localEndpoint: 'http://localhost:11434',
    notes: 'Mock connection state only. Endpoint probing is not enabled.',
  ),
  AiProvider(
    id: 'comfyui',
    name: 'ComfyUI',
    type: AiProviderType.local,
    executionModes: [ExecutionMode.local],
    status: AiProviderStatus.localUnavailable,
    supportedWorkspaces: ['image', 'video'],
    description: 'Local node runtime for image and video generation workflows.',
    apiKeyRequired: false,
    localEndpoint: 'http://127.0.0.1:8188',
    notes: 'Endpoint metadata only. Runtime launch is not connected.',
  ),
  AiProvider(
    id: 'manual-browser',
    name: 'Manual Browser Launch',
    type: AiProviderType.browser,
    executionModes: [ExecutionMode.manual, ExecutionMode.browserLaunch],
    status: AiProviderStatus.available,
    supportedWorkspaces: [
      'agents',
      'text',
      'image',
      'video',
      'audio',
      'automation',
    ],
    description: 'Safe default route: copy prompt and open the selected tool.',
    apiKeyRequired: false,
    notes: 'Default provider until real API and local execution are connected.',
  ),
  AiProvider(
    id: 'n8n',
    name: 'n8n',
    type: AiProviderType.hybrid,
    executionModes: [ExecutionMode.local, ExecutionMode.api],
    status: AiProviderStatus.comingSoon,
    supportedWorkspaces: ['automation'],
    description: 'Workflow automation provider for operator pipelines.',
    baseUrl: 'https://n8n.io',
    apiKeyRequired: false,
    localEndpoint: 'http://localhost:5678',
    notes:
        'Automation execution is planned for a later Integration Layer step.',
  ),
];

class ProviderRegistry {
  const ProviderRegistry();

  List<AiProvider> getAllProviders() => seedProviders;

  List<AiProvider> getProvidersForWorkspace(String workspaceType) {
    final normalized = workspaceType.trim().toLowerCase();
    return seedProviders
        .where((provider) => provider.supportedWorkspaces.contains(normalized))
        .toList(growable: false);
  }

  AiProvider? getProviderById(String id) {
    final normalized = id.trim().toLowerCase();
    for (final provider in seedProviders) {
      if (provider.id == normalized) return provider;
    }
    return null;
  }

  List<AiProvider> getAvailableProviders() {
    return seedProviders
        .where(
          (provider) =>
              provider.status == AiProviderStatus.available ||
              provider.status == AiProviderStatus.connectedMock,
        )
        .toList(growable: false);
  }

  AiProvider getFallbackProvider(String workspaceType) {
    return getProviderById('manual-browser')!;
  }

  AiProvider getProviderForToolId(String? toolId) {
    final normalized = (toolId ?? '').trim().toLowerCase();
    final providerId = switch (normalized) {
      'chatgpt' => 'chatgpt',
      'claude' => 'claude',
      'openrouter' => 'openrouter',
      'gemini' || 'gemini-image-tools' => 'gemini',
      'mistral' || 'mistral-chat' => 'mistral',
      'deepseek' => 'deepseek',
      'qwen' => 'qwen',
      'huggingface' => 'huggingface',
      'ollama' => 'ollama',
      'comfyui' => 'comfyui',
      'n8n' => 'n8n',
      _ => 'manual-browser',
    };
    return getProviderById(providerId)!;
  }
}
