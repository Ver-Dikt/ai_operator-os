import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ai_tool.dart';

class ToolLauncherService {
  const ToolLauncherService();

  Future<void> openExternalTool(AiTool tool) async {
    await _openUrl(tool.url);
  }

  Future<void> openPromptInBrowser(AiTool tool, String prompt) async {
    await Clipboard.setData(ClipboardData(text: prompt));
    await openExternalTool(tool);
  }

  Future<void> launchWorkflow(String url) async {
    await _openUrl(url);
  }

  Future<void> copyPrompt(String prompt) async {
    await Clipboard.setData(ClipboardData(text: prompt));
  }

  Future<void> continueInTool(AiTool tool, String prompt) async {
    await openPromptInBrowser(tool, prompt);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
