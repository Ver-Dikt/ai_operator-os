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
    notes:
        'OpenAI-compatible text execution is available when API key, base URL, and model are configured.',
  ),
  AiProvider(
    id: 'omniroute',
    name: 'OmniRoute',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['text', 'agents'],
    description:
        'Experimental OpenAI-compatible text router. Endpoint and free tier must be verified by the user.',
    baseUrl: 'http://localhost:3000/v1',
    apiKeyRequired: true,
    notes:
        'API-кандидат. FLUTEN calls only the configured OpenAI-compatible endpoint; no OmniRoute repo is installed or run.',
  ),
  AiProvider(
    id: 'openai',
    name: 'OpenAI / ChatGPT API',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['text', 'image', 'agents'],
    description: 'API provider for future text, image, and prompt execution.',
    baseUrl: 'https://api.openai.com/v1',
    apiKeyRequired: true,
    notes: 'Settings only. Real OpenAI API calls are not connected yet.',
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
    id: 'replicate',
    name: 'Replicate',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['image', 'video', 'audio'],
    description: 'Hosted model API for future multimodal execution routes.',
    baseUrl: 'https://api.replicate.com/v1',
    apiKeyRequired: true,
    notes: 'Settings only. Real Replicate calls are not connected yet.',
  ),
  AiProvider(
    id: 'runway',
    name: 'Runway',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['video'],
    description: 'Video generation provider settings for future API routing.',
    baseUrl: 'https://api.runwayml.com',
    apiKeyRequired: true,
    notes: 'Settings only. Real Runway calls are not connected yet.',
  ),
  AiProvider(
    id: 'kling',
    name: 'Kling',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['video'],
    description: 'Video generation provider settings for future API routing.',
    baseUrl: 'https://klingai.com',
    apiKeyRequired: true,
    notes: 'Settings only. Real Kling calls are not connected yet.',
  ),
  AiProvider(
    id: 'stability',
    name: 'Stability / Stable Diffusion',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['image'],
    description: 'Image generation provider settings for future API routing.',
    baseUrl: 'https://api.stability.ai',
    apiKeyRequired: true,
    notes: 'Settings only. Real Stability calls are not connected yet.',
  ),
  AiProvider(
    id: 'elevenlabs',
    name: 'ElevenLabs',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.notConfigured,
    supportedWorkspaces: ['audio'],
    description: 'Voice generation provider settings for future API routing.',
    baseUrl: 'https://api.elevenlabs.io',
    apiKeyRequired: true,
    notes: 'Settings only. Real ElevenLabs calls are not connected yet.',
  ),
  AiProvider(
    id: 'suno-udio',
    name: 'Suno / Udio',
    type: AiProviderType.api,
    executionModes: [ExecutionMode.api, ExecutionMode.browserLaunch],
    status: AiProviderStatus.comingSoon,
    supportedWorkspaces: ['audio'],
    description: 'Music provider placeholder for future execution settings.',
    baseUrl: 'https://suno.com',
    apiKeyRequired: true,
    notes: 'Placeholder settings only. No music API calls are connected.',
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
    id: 'ace-step',
    name: 'ACE-Step',
    type: AiProviderType.local,
    executionModes: [ExecutionMode.local],
    status: AiProviderStatus.localUnavailable,
    supportedWorkspaces: ['audio'],
    description: 'Local audio/music generation runtime planned for later.',
    apiKeyRequired: false,
    localEndpoint: 'http://localhost:8001',
    notes: 'Endpoint settings only. Local execution is not connected yet.',
  ),
  AiProvider(
    id: 'local-browser',
    name: 'Local browser / WebView',
    type: AiProviderType.local,
    executionModes: [ExecutionMode.local, ExecutionMode.browserLaunch],
    status: AiProviderStatus.comingSoon,
    supportedWorkspaces: ['text', 'image', 'video', 'audio'],
    description: 'Embedded browser runtime placeholder for later WebView work.',
    apiKeyRequired: false,
    localEndpoint: 'http://localhost',
    notes: 'WebView is not connected in this phase.',
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
      'openai' || 'dall-e' || 'chatgpt-image' => 'openai',
      'claude' => 'claude',
      'openrouter' => 'openrouter',
      'omniroute' => 'omniroute',
      'gemini' || 'gemini-image-tools' => 'gemini',
      'replicate' => 'replicate',
      'runway' => 'runway',
      'kling' => 'kling',
      'stable-diffusion' || 'stability' || 'sdxl' => 'stability',
      'elevenlabs' => 'elevenlabs',
      'suno' || 'udio' => 'suno-udio',
      'mistral' || 'mistral-chat' => 'mistral',
      'deepseek' => 'deepseek',
      'qwen' => 'qwen',
      'huggingface' => 'huggingface',
      'ollama' => 'ollama',
      'comfyui' || 'comfyui-local' => 'comfyui',
      'ace-step' => 'ace-step',
      'local-browser' => 'local-browser',
      'n8n' => 'n8n',
      _ => 'manual-browser',
    };
    return getProviderById(providerId)!;
  }
}
