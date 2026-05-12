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
    text: 'Одинокий робот слышит музыку из заброшенной станции метро',
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
          'От идеи к production-плану. Phase 1 использует демо-планирование сцен и копируемые промпты.',
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
                      ('tiktok', 'TikTok'),
                      ('reels', 'Reels'),
                      ('shorts', 'Shorts'),
                      ('youtube', 'YouTube'),
                      ('music promo', 'Музыкальное промо'),
                      ('cinematic scene', 'Кинематографичная сцена'),
                    ])
                      ChoiceChip(
                        label: Text(value.$2),
                        selected: _format == value.$1,
                        onSelected: (_) => setState(() => _format = value.$1),
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
        ? 'Идея контента без названия'
        : idea.trim();
    return ContentProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: safeIdea,
      format: ContentFormat.shorts,
      idea: safeIdea,
      targetAudience: 'аудитория, которой интересен AI-контент',
      mood: 'кинематографично, сфокусированно, эмоционально ясно',
      duration: format == 'youtube' ? '3-6 min' : '30-45 sec',
      scenes: [
        ScenePlan(
          sceneNumber: 1,
          dramaticPurpose: 'Показать желание и ограничение.',
          cameraLogic:
              'Статичный кадр; движение задерживается, чтобы собрать внимание.',
          blocking:
              'Герой расположен в глубине кадра, вокруг остается негативное пространство.',
          visualPrompt:
              'Wide cinematic shot of $safeIdea, strong depth, restrained motion, textured light.',
          negativePrompt:
              'random camera motion, glossy stock footage, incoherent hands, overcutting',
          voiceover: 'Маленькое изменение меняет все направление.',
          musicDirection: 'Редкий пульс, затем теплый подъем.',
          toolRecommendation:
              'Kling для черновика, Veo/Runway для качественного прохода.',
        ),
        ScenePlan(
          sceneNumber: 2,
          dramaticPurpose: 'Показать препятствие через блокинг.',
          cameraLogic: 'Медленный push-in только после решения персонажа.',
          blocking:
              'Объект на переднем плане частично закрывает героя до поворота.',
          visualPrompt:
              'Medium shot, foreground occlusion, subject crosses from shadow into a narrow light path.',
          negativePrompt: 'busy background, fast zoom, random lens changes',
          voiceover: 'Путь становится видимым только после выбора.',
          musicDirection: 'Низкая перкуссия с воздухом.',
          toolRecommendation: 'Сгенерируй варианты в Runway или Pika.',
        ),
        ScenePlan(
          sceneNumber: 3,
          dramaticPurpose: 'Финальный жест переосмысляет весь ролик.',
          cameraLogic: 'Удержи камеру и дай жесту нести эмоцию.',
          blocking: 'Герой останавливается и поворачивает объект к камере.',
          visualPrompt:
              'Close final gesture, stable camera, emotional restraint, cinematic contrast.',
          negativePrompt: 'melodrama, shaking camera, extra limbs',
          voiceover: 'Сигнал никогда не был снаружи. Он ждал ответа.',
          musicDirection: 'Разрешение одной мелодической фразой.',
          toolRecommendation: 'Увеличь лучший дубль и добавь подписи в Canva.',
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
