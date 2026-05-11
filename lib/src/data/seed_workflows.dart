import '../models/workflow_template.dart';

WorkflowStep _step(
  String id,
  String title,
  String instruction, {
  String? agentId,
  List<String> tools = const [],
  String prompt = '',
  bool manual = true,
  bool auto = false,
}) {
  return WorkflowStep(
    id: id,
    title: title,
    instruction: instruction,
    agentId: agentId,
    toolIds: tools,
    promptTemplate: prompt.isEmpty
        ? 'Task: {{task}}\nConstraints: {{constraints}}\nOutput: $title'
        : prompt,
    expectedOutput: '$title completed artifact',
    isManual: manual,
    isAutomatable: auto,
  );
}

final seedWorkflows = <WorkflowTemplate>[
  WorkflowTemplate(
    id: 'ai-short-video-factory',
    title: 'AI Short Video Factory',
    description:
        'Idea to hook, script, scenes, video prompts, tool selection, edit plan and captions.',
    category: 'Video',
    difficulty: WorkflowDifficulty.medium,
    estimatedTime: '45-90 min',
    costLevel: CostLevel.mixed,
    requiredTools: ['chatgpt', 'kling', 'canva'],
    optionalTools: ['veo', 'runway', 'elevenlabs', 'suno'],
    outputExamples: ['9 scene prompts', 'caption pack', 'publishing checklist'],
    steps: [
      _step(
        'idea',
        'Idea',
        'Condense the idea into one emotional promise.',
        agentId: 'content-factory-agent',
      ),
      _step(
        'hook',
        'Hook',
        'Write three first-second hooks and pick the strongest constraint.',
      ),
      _step('script', 'Script', 'Write a compact script with a clear turn.'),
      _step(
        'scenes',
        'Scenes',
        'Split the script into visual beats.',
        agentId: 'director-agent',
      ),
      _step(
        'video-prompts',
        'Video Prompts',
        'Write prompt-ready shots with blocking and camera reason.',
        tools: ['kling', 'veo'],
      ),
      _step(
        'tool-selection',
        'Tool Selection',
        'Choose free, fast and quality tool paths.',
        agentId: 'tool-router-agent',
      ),
      _step(
        'generation',
        'Generation Checklist',
        'Track generated shots and variations.',
      ),
      _step('edit', 'Edit Plan', 'Define rhythm, captions and final gesture.'),
      _step(
        'publish',
        'Publish Captions',
        'Write captions and hashtags for release.',
      ),
    ],
  ),
  WorkflowTemplate(
    id: 'music-release-promo-pack',
    title: 'Music Release Promo Pack',
    description:
        'Turns a track mood into teaser ideas, cover prompts, lyric clips and posting calendar.',
    category: 'Music',
    difficulty: WorkflowDifficulty.easy,
    estimatedTime: '60 min',
    costLevel: CostLevel.low,
    requiredTools: ['chatgpt', 'canva', 'kling'],
    optionalTools: ['suno', 'udio', 'bandlab'],
    outputExamples: ['7 teaser ideas', 'cover art prompts', '14-day calendar'],
    steps: [
      _step(
        'song-mood',
        'Song Mood',
        'Describe the emotional world of the track.',
        agentId: 'music-promo-agent',
      ),
      _step(
        'identity',
        'Visual Identity',
        'Define colors, objects, pacing and texture.',
      ),
      _step('teasers', 'Teaser Ideas', 'Generate short-form concepts.'),
      _step('lyrics', 'Lyric Clips', 'Pick lines and visual treatment.'),
      _step('cover', 'Cover Art Prompts', 'Create cover art prompt variants.'),
      _step(
        'video',
        'Short Video Prompts',
        'Create video prompts for promo clips.',
      ),
      _step('calendar', 'Posting Calendar', 'Build release cadence.'),
    ],
  ),
  WorkflowTemplate(
    id: 'ai-tool-finder',
    title: 'AI Tool Finder',
    description:
        'Convert a task and constraints into a free/paid/local tool stack.',
    category: 'Research',
    difficulty: WorkflowDifficulty.easy,
    estimatedTime: '15 min',
    costLevel: CostLevel.free,
    requiredTools: ['perplexity', 'chatgpt'],
    optionalTools: ['ollama', 'notebooklm'],
    outputExamples: ['best paid option', 'free path', 'local fallback'],
    steps: [
      _step('task', 'User Task', 'Write the concrete job to be done.'),
      _step(
        'constraints',
        'Constraints',
        'Add budget, platform and time limits.',
      ),
      _step(
        'split',
        'Free/Paid Split',
        'Separate zero-cost, paid and local options.',
        agentId: 'free-stack-agent',
      ),
      _step(
        'best-tools',
        'Best Tools',
        'Pick tools by fit and reliability.',
        agentId: 'tool-router-agent',
      ),
      _step(
        'workflow',
        'Workflow Recommendation',
        'Turn the result into a sequence.',
      ),
    ],
  ),
  WorkflowTemplate(
    id: 'cinematic-scene-builder',
    title: 'Cinematic Scene Builder',
    description:
        'Builds a scene with dramatic beat, blocking, camera reason and final gesture.',
    category: 'Video',
    difficulty: WorkflowDifficulty.advanced,
    estimatedTime: '30-60 min',
    costLevel: CostLevel.mixed,
    requiredTools: ['chatgpt', 'veo'],
    optionalTools: ['midjourney', 'runway', 'comfyui'],
    outputExamples: ['director notes', 'video prompt pack', 'negative prompts'],
    steps: [
      _step('beat', 'Dramatic Beat', 'Name the emotional turn.'),
      _step('location', 'Location', 'Choose a space that creates pressure.'),
      _step(
        'blocking',
        'Blocking',
        'Place bodies before camera motion.',
        agentId: 'director-agent',
      ),
      _step(
        'camera',
        'Camera Reason',
        'Move the camera only for a dramatic reason.',
      ),
      _step('stable', 'Stable Shot', 'Use stability as an expressive choice.'),
      _step(
        'gesture',
        'Final Gesture',
        'Define the gesture that reframes the scene.',
      ),
      _step('prompt-pack', 'Prompt Pack', 'Write final prompts and negatives.'),
    ],
  ),
  WorkflowTemplate(
    id: 'local-ai-setup',
    title: 'Local AI Setup',
    description:
        'Prepare a local stack around Ollama, model selection and local knowledge.',
    category: 'Local',
    difficulty: WorkflowDifficulty.medium,
    estimatedTime: '45 min',
    costLevel: CostLevel.free,
    requiredTools: ['ollama', 'lm-studio'],
    optionalTools: ['open-webui', 'anythingllm', 'n8n'],
    outputExamples: ['model list', 'local chat setup', 'automation notes'],
    steps: [
      _step('ollama', 'Ollama', 'Install and verify local endpoint.'),
      _step('models', 'Model Selection', 'Pick models by RAM and task.'),
      _step('chat', 'Local Chat', 'Open local chat UI.'),
      _step('knowledge', 'Local Knowledge Base', 'Plan document ingestion.'),
      _step('automation', 'Local Automation', 'Connect local services later.'),
    ],
  ),
];
