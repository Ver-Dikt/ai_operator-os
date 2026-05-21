import '../models/generation/camera_profile.dart';
import '../models/generation/director_preset.dart';

const seedDirectorPresets = <DirectorPreset>[
  DirectorPreset(
    id: 'neon-noir',
    name: 'Неоновый нуар',
    description: 'Контрастный ночной кадр, мокрые поверхности, глубокие тени.',
    camera: CameraProfile(
      id: 'large-format-prime',
      name: 'Large Format Prime',
      cameraBody: 'large format digital cinema camera',
      lens: 'anamorphic prime lens',
      focalLength: 40,
      aperture: 'f/1.8',
      motion: 'медленный push-in',
      light: 'неоновые боковые источники, мягкий контровой свет',
      color: 'cyan и magenta без пересвета, плотные чёрные',
    ),
    moodTags: ['напряжение', 'дорогой клип', 'городская ночь'],
    negativePrompt: 'дешёвый глянец, случайный zoom, плоский свет',
  ),
  DirectorPreset(
    id: 'documentary-intimate',
    name: 'Документальная близость',
    description: 'Живой наблюдательный кадр с реалистичной фактурой.',
    camera: CameraProfile(
      id: 's35-handheld',
      name: 'S35 Handheld',
      cameraBody: 'Super 35 documentary cinema camera',
      lens: 'warm vintage prime lens',
      focalLength: 32,
      aperture: 'f/2.8',
      motion: 'очень мягкая ручная камера',
      light: 'натуральный оконный свет и практические источники',
      color: 'тёплая плёнка, умеренное зерно, реалистичная кожа',
    ),
    moodTags: ['честно', 'интимно', 'наблюдение'],
    negativePrompt:
        'пластиковая кожа, рекламная постановка, чрезмерная резкость',
  ),
  DirectorPreset(
    id: 'premium-product',
    name: 'Премиальный предмет',
    description:
        'Чистый рекламный кадр для продукта, обложки или launch-видео.',
    camera: CameraProfile(
      id: 'studio-macro',
      name: 'Studio Macro',
      cameraBody: 'studio digital cinema camera',
      lens: 'clinical sharp macro lens',
      focalLength: 85,
      aperture: 'f/4',
      motion: 'контролируемый slider move',
      light: 'большой softbox, тонкий rim light, отражатели',
      color: 'чистый контраст, дорогие материалы, аккуратные блики',
    ),
    moodTags: ['премиально', 'точно', 'launch campaign'],
    negativePrompt: 'грязный фон, дешёвые отражения, лишние элементы',
  ),
];
