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
        workflowId: 'ai-short-video-factory',
        agentIds: [
          'director-agent',
          'content-factory-agent',
          'tool-router-agent',
        ],
        toolIds: ['kling', 'pika', 'veo', 'runway', 'canva'],
        useCaseIds: ['make-10-reels-for-track', 'build-ai-influencer'],
        freePath: [
          'Kling/Pika test credits',
          'Canva free layout',
          'manual edit',
        ],
        proPath: [
          'Veo or Runway quality pass',
          'ElevenLabs voice',
          'paid captions/editing',
        ],
        manualSteps: ['approve scenes', 'pick best takes', 'final human QA'],
        automationPotential:
            'Semi-automated: prompts and checklist now, generation later',
        monetizationIdea:
            'Potential content or client-service opportunity. Validate audience/client demand first.',
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
        workflowId: 'music-release-promo-pack',
        agentIds: [
          'music-promo-agent',
          'content-factory-agent',
          'director-agent',
        ],
        toolIds: ['suno', 'udio', 'bandlab', 'kling', 'canva'],
        useCaseIds: ['make-10-reels-for-track'],
        freePath: ['BandLab', 'Canva free', 'Kling/Pika free tests'],
        proPath: ['Suno/Udio paid generations', 'Runway quality pass'],
        manualSteps: ['select hooks', 'approve visuals', 'schedule posts'],
        automationPotential: 'Assisted batch planning',
        monetizationIdea:
            'Potential artist promo package. Requires real track quality and audience validation.',
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
        workflowId: 'ai-tool-finder',
        agentIds: [
          'code-builder-agent',
          'qa-critic-agent',
          'tool-router-agent',
        ],
        toolIds: ['cursor', 'copilot', 'windsurf', 'ollama'],
        useCaseIds: ['build-n8n-workflow'],
        freePath: ['Ollama planning', 'manual Flutter implementation'],
        proPath: ['Cursor/Copilot acceleration'],
        manualSteps: ['review code', 'run tests', 'verify UX'],
        automationPotential: 'Assisted coding, human review required',
        monetizationIdea:
            'Potential SaaS/client build opportunity only after user validation.',
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
      workflowId: 'ai-tool-finder',
      agentIds: ['tool-router-agent', 'research-agent', 'free-stack-agent'],
      toolIds: ['chatgpt', 'perplexity', 'notebooklm', 'ollama'],
      useCaseIds: ['ai-tool-comparison', 'competitor-analysis'],
      freePath: ['ChatGPT/Gemini free', 'NotebookLM', 'Ollama local'],
      proPath: ['ChatGPT Plus/Pro', 'Claude', 'Perplexity Pro'],
      manualSteps: [
        'clarify constraints',
        'compare alternatives',
        'human decision',
      ],
      automationPotential: 'Assisted planning',
      monetizationIdea:
          'Potential opportunity only. Validate problem, buyer and delivery path.',
      notes: ['Route by output type, budget and privacy constraints.'],
    );
  }
}
