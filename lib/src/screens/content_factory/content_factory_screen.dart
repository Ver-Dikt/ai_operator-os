import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/content_project.dart';
import '../../widgets/cards/os_card.dart';
import '../../widgets/responsive_page.dart';

class ContentFactoryScreen extends StatefulWidget {
  const ContentFactoryScreen({super.key});

  @override
  State<ContentFactoryScreen> createState() => _ContentFactoryScreenState();
}

class _ContentFactoryScreenState extends State<ContentFactoryScreen> {
  final TextEditingController _idea = TextEditingController(
    text: 'A lonely robot hears music from an abandoned metro station',
  );
  String _format = 'shorts';
  ContentProject? _project;

  @override
  void dispose() {
    _idea.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      title: 'Контент-фабрика',
      subtitle:
          'От идеи к production-плану. Phase 1 использует mock-планирование сцен и копируемые промпты.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _idea,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Опиши идею контента...',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in [
                      'tiktok',
                      'reels',
                      'shorts',
                      'youtube',
                      'music promo',
                      'cinematic scene',
                    ])
                      ChoiceChip(
                        label: Text(value),
                        selected: _format == value,
                        onSelected: (_) => setState(() => _format = value),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => setState(() {
                    _project = _buildProject(_idea.text, _format);
                  }),
                  icon: const Icon(Icons.factory_rounded),
                  label: const Text('Собрать production-план'),
                ),
              ],
            ),
          ),
          if (_project != null) ...[
            const SizedBox(height: 18),
            _ProjectPlan(project: _project!),
          ],
        ],
      ),
    );
  }

  ContentProject _buildProject(String idea, String format) {
    final safeIdea = idea.trim().isEmpty
        ? 'Untitled content idea'
        : idea.trim();
    return ContentProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: safeIdea,
      format: ContentFormat.shorts,
      idea: safeIdea,
      targetAudience: 'AI-curious audience',
      mood: 'cinematic, focused, emotionally clear',
      duration: format == 'youtube' ? '3-6 min' : '30-45 sec',
      scenes: [
        ScenePlan(
          sceneNumber: 1,
          dramaticPurpose: 'Establish desire and constraint.',
          cameraLogic:
              'Static frame; movement is withheld to create attention.',
          blocking: 'Subject placed deep in frame with negative space.',
          visualPrompt:
              'Wide cinematic shot of $safeIdea, strong depth, restrained motion, textured light.',
          negativePrompt:
              'random camera motion, glossy stock footage, incoherent hands, overcutting',
          voiceover: 'Something small changes the whole direction.',
          musicDirection: 'Sparse pulse, then warm lift.',
          toolRecommendation: 'Kling for draft, Veo/Runway for quality pass.',
        ),
        ScenePlan(
          sceneNumber: 2,
          dramaticPurpose: 'Reveal the obstacle through blocking.',
          cameraLogic: 'Slow push only after the character commits.',
          blocking:
              'Foreground object blocks part of the subject until the turn.',
          visualPrompt:
              'Medium shot, foreground occlusion, subject crosses from shadow into a narrow light path.',
          negativePrompt: 'busy background, fast zoom, random lens changes',
          voiceover: 'The path is visible only after the choice.',
          musicDirection: 'Low percussion with air.',
          toolRecommendation: 'Generate variations in Runway or Pika.',
        ),
        ScenePlan(
          sceneNumber: 3,
          dramaticPurpose: 'Final gesture reframes the whole piece.',
          cameraLogic: 'Hold still and let the gesture carry emotion.',
          blocking: 'Subject stops, turns one object toward camera.',
          visualPrompt:
              'Close final gesture, stable camera, emotional restraint, cinematic contrast.',
          negativePrompt: 'melodrama, shaking camera, extra limbs',
          voiceover:
              'The signal was never outside. It was waiting to be answered.',
          musicDirection: 'Resolve with a single melodic phrase.',
          toolRecommendation: 'Upscale best take, add captions in Canva.',
        ),
      ],
      prompts: const [],
      tools: const ['ChatGPT', 'Kling', 'Runway', 'Canva', 'ElevenLabs'],
      status: ContentStatus.planned,
      createdAt: DateTime.now(),
    );
  }
}

class _ProjectPlan extends StatelessWidget {
  const _ProjectPlan({required this.project});

  final ContentProject project;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Длительность: ${project.duration} • настроение: ${project.mood}',
          ),
          const SizedBox(height: 12),
          for (final scene in project.scenes) ...[
            Text(
              'Сцена ${scene.sceneNumber}: ${scene.dramaticPurpose}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            SelectableText(scene.visualPrompt),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: scene.visualPrompt));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Сцена ${scene.sceneNumber} скопирована'),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Скопировать промпт сцены'),
            ),
            const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}
