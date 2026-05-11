/// Structured curriculum model for tracking user progress through
/// a series of lessons and exercises.
///
/// Each [CourseCurriculum] contains ordered [CurriculumModule]s,
/// each module contains [CurriculumLesson]s.

class CourseCurriculum {
  final String id;
  final String title;
  final String description;
  final List<CurriculumModule> modules;

  const CourseCurriculum({
    required this.id,
    required this.title,
    required this.description,
    required this.modules,
  });

  int get totalLessons =>
      modules.fold<int>(0, (sum, m) => sum + m.lessons.length);

  int completedLessons(Set<String> completedIds) =>
      modules.fold<int>(
        0,
        (sum, m) => sum + m.lessons.where((l) => completedIds.contains(l.id)).length,
      );

  double progressPercent(Set<String> completedIds) {
    final total = totalLessons;
    if (total == 0) return 0;
    return completedLessons(completedIds) / total;
  }

  /// The default Vietnamese speaking curriculum.
  static final CourseCurriculum defaultCurriculum = CourseCurriculum(
    id: 'vi_speaking_v1',
    title: 'Luyện nói tiếng Việt',
    description: 'Chương trình 4 tuần cải thiện kỹ năng nói',
    modules: [
      CurriculumModule(
        id: 'mod_basics',
        title: 'Tuần 1: Nền tảng',
        description: 'Phát âm cơ bản và kiểm soát hơi thở',
        lessons: [
          CurriculumLesson(
            id: 'l_breathing',
            title: 'Bài tập thở',
            description: 'Kiểm soát hơi thở khi nói',
            exerciseType: 'read',
            difficulty: 'easy',
          ),
          CurriculumLesson(
            id: 'l_vowels',
            title: 'Nguyên âm cơ bản',
            description: 'Phát âm các nguyên âm a, e, i, o, u',
            exerciseType: 'read',
            difficulty: 'easy',
          ),
          CurriculumLesson(
            id: 'l_tones',
            title: 'Thanh điệu',
            description: 'Luyện 6 thanh điệu tiếng Việt',
            exerciseType: 'read',
            difficulty: 'easy',
          ),
          CurriculumLesson(
            id: 'l_greeting',
            title: 'Câu chào hỏi',
            description: 'Chào hỏi và giới thiệu bản thân',
            exerciseType: 'read',
            difficulty: 'easy',
          ),
        ],
      ),
      CurriculumModule(
        id: 'mod_fluency',
        title: 'Tuần 2: Trôi chảy',
        description: 'Nói liền mạch và giảm từ đệm',
        lessons: [
          CurriculumLesson(
            id: 'l_short_phrases',
            title: 'Cụm từ ngắn',
            description: 'Nói các cụm từ 3-5 từ liền mạch',
            exerciseType: 'read',
            difficulty: 'medium',
          ),
          CurriculumLesson(
            id: 'l_fillers',
            title: 'Giảm từ đệm',
            description: 'Tập nói mà không dùng "ờ", "à"',
            exerciseType: 'read',
            difficulty: 'medium',
          ),
          CurriculumLesson(
            id: 'l_shadowing',
            title: 'Shadowing',
            description: 'Nghe và lặp lại theo giọng mẫu',
            exerciseType: 'shadowing',
            difficulty: 'medium',
          ),
          CurriculumLesson(
            id: 'l_pacing',
            title: 'Nhịp nói',
            description: 'Kiểm soát tốc độ nói tự nhiên',
            exerciseType: 'slow',
            difficulty: 'medium',
          ),
        ],
      ),
      CurriculumModule(
        id: 'mod_expression',
        title: 'Tuần 3: Diễn đạt',
        description: 'Nói có cảm xúc và ngữ điệu',
        lessons: [
          CurriculumLesson(
            id: 'l_emotion',
            title: 'Ngữ điệu cảm xúc',
            description: 'Thể hiện vui, buồn, hào hứng qua giọng nói',
            exerciseType: 'read',
            difficulty: 'medium',
          ),
          CurriculumLesson(
            id: 'l_emphasis',
            title: 'Nhấn mạnh',
            description: 'Nhấn mạnh từ quan trọng trong câu',
            exerciseType: 'read',
            difficulty: 'medium',
          ),
          CurriculumLesson(
            id: 'l_story',
            title: 'Kể chuyện',
            description: 'Kể một câu chuyện ngắn có cốt truyện',
            exerciseType: 'read',
            difficulty: 'hard',
          ),
        ],
      ),
      CurriculumModule(
        id: 'mod_advanced',
        title: 'Tuần 4: Nâng cao',
        description: 'Giao tiếp thực tế và thuyết trình',
        lessons: [
          CurriculumLesson(
            id: 'l_debate',
            title: 'Tranh luận',
            description: 'Trình bày quan điểm và phản biện',
            exerciseType: 'read',
            difficulty: 'hard',
          ),
          CurriculumLesson(
            id: 'l_present',
            title: 'Thuyết trình',
            description: 'Chuẩn bị và trình bày bài thuyết trình 2 phút',
            exerciseType: 'read',
            difficulty: 'hard',
          ),
          CurriculumLesson(
            id: 'l_improv',
            title: 'Ứng biến',
            description: 'Nói tự do về chủ đề bất kỳ trong 1 phút',
            exerciseType: 'read',
            difficulty: 'hard',
          ),
        ],
      ),
    ],
  );
}

class CurriculumModule {
  final String id;
  final String title;
  final String description;
  final List<CurriculumLesson> lessons;

  const CurriculumModule({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
  });
}

class CurriculumLesson {
  final String id;
  final String title;
  final String description;
  final String exerciseType; // 'read', 'shadowing', 'slow'
  final String difficulty; // 'easy', 'medium', 'hard'

  const CurriculumLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.exerciseType,
    this.difficulty = 'easy',
  });
}
