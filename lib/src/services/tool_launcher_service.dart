import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ai_tool.dart';

class ToolLauncherService {
  const ToolLauncherService();

  static const Map<String, String> toolUrls = {
    'chatgpt': 'https://chatgpt.com/',
    'chatgpt-images': 'https://chatgpt.com/',
    'claude': 'https://claude.ai/',
    'gemini': 'https://gemini.google.com/',
    'perplexity': 'https://www.perplexity.ai/',
    'leonardo': 'https://leonardo.ai/',
    'flux-playground': 'https://playground.bfl.ai/',
    'midjourney': 'https://www.midjourney.com/',
    'ideogram': 'https://ideogram.ai/',
    'freepik-ai': 'https://www.freepik.com/ai',
    'kling': 'https://klingai.com/',
    'runway': 'https://app.runwayml.com/',
    'pika': 'https://pika.art/',
    'luma': 'https://lumalabs.ai/dream-machine',
    'veo': 'https://labs.google/fx/tools/flow',
    'google-flow': 'https://labs.google/fx/tools/flow',
    'sora': 'https://sora.chatgpt.com/',
    'suno': 'https://suno.com/',
    'elevenlabs': 'https://elevenlabs.io/',
    'udio': 'https://www.udio.com/',
    'n8n': 'https://n8n.io/',
    'make': 'https://www.make.com/',
    'zapier': 'https://zapier.com/',
    'ollama': 'http://localhost:11434',
    'comfyui': 'http://127.0.0.1:8188',
  };

  String? destinationFor(AiTool tool) {
    final mapped = toolUrls[tool.id];
    if (mapped != null && mapped.isNotEmpty) return mapped;
    return tool.url.trim().isEmpty ? null : tool.url;
  }

  Future<bool> openExternalTool(AiTool tool) async {
    final url = destinationFor(tool);
    if (url == null) return false;
    await _openUrl(url);
    return true;
  }

  Future<bool> openPromptInBrowser(AiTool tool, String prompt) async {
    await Clipboard.setData(ClipboardData(text: prompt));
    return openExternalTool(tool);
  }

  Future<void> launchWorkflow(String url) async {
    await _openUrl(url);
  }

  Future<void> copyPrompt(String prompt) async {
    await Clipboard.setData(ClipboardData(text: prompt));
  }

  Future<bool> continueInTool(AiTool tool, String prompt) async {
    return openPromptInBrowser(tool, prompt);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
