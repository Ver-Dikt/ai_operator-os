import '../models/routing_recommendation.dart';

class RouterService {
  const RouterService();

  RoutingRecommendation recommend(String task) {
    final q = task.toLowerCase();
    if (q.contains('video') || q.contains('cinematic') || q.contains('short')) {
      return const RoutingRecommendation(
        task: 'Cinematic / short video',
        bestPaidTools: ['Veo', 'Runway', 'Sora'],
        bestFreeTools: ['Kling', 'Pika', 'Kensa'],
        localOptions: ['ComfyUI', 'Stable Diffusion video workflows'],
        recommendedWorkflow: 'AI Short Video Factory',
        estimatedCost: 'Free test path, paid quality path from credits',
        notes: [
          'Start with Director Agent before generating.',
          'Use stable shots and final gesture to control attention.',
        ],
      );
    }
    if (q.contains('music') || q.contains('song') || q.contains('track')) {
      return const RoutingRecommendation(
        task: 'Music / release promo',
        bestPaidTools: ['Suno Pro', 'Udio paid', 'ElevenLabs'],
        bestFreeTools: ['BandLab', 'Suno free tests', 'Udio free tests'],
        localOptions: ['Local DAW + open audio tools'],
        recommendedWorkflow: 'Music Release Promo Pack',
        estimatedCost: 'Free planning, paid generation when quality matters',
        notes: ['Convert mood into visual identity before clips.'],
      );
    }
    if (q.contains('code') || q.contains('flutter') || q.contains('app')) {
      return const RoutingRecommendation(
        task: 'Coding / app feature',
        bestPaidTools: ['Cursor', 'GitHub Copilot'],
        bestFreeTools: ['ChatGPT free', 'Replit free tier'],
        localOptions: ['Ollama + local coding model'],
        recommendedWorkflow: 'Flutter Feature Builder',
        estimatedCost: 'Free planning, paid IDE assistance optional',
        notes: ['Use Code Builder Agent and add tests before UI polish.'],
      );
    }
    return const RoutingRecommendation(
      task: 'General AI task',
      bestPaidTools: ['ChatGPT', 'Claude', 'Perplexity Pro'],
      bestFreeTools: ['ChatGPT Free', 'Gemini', 'NotebookLM'],
      localOptions: ['Ollama', 'LM Studio', 'Open WebUI'],
      recommendedWorkflow: 'AI Tool Finder',
      estimatedCost: 'Start free, upgrade only when bottleneck is clear',
      notes: ['Route by output type, budget and privacy constraints.'],
    );
  }
}
