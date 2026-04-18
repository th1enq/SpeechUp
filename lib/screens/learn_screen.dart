import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _selectedCategory = 'Breathing';

  static final _lessons = <_LessonItem>[
    _LessonItem(
      category: 'Breathing',
      title: 'One breath before the first word',
      description: 'A tiny reset before you begin speaking.',
      duration: '2 min read',
      icon: Icons.air_rounded,
      color: AppColors.calmMintSurface,
    ),
    _LessonItem(
      category: 'Pacing',
      title: 'Use pauses with confidence',
      description: 'Let short pauses support your rhythm.',
      duration: '3 min read',
      icon: Icons.waves_rounded,
      color: AppColors.calmBlueSurface,
    ),
    _LessonItem(
      category: 'Confidence',
      title: 'Keep going after a pause',
      description: 'A pause is part of speaking, not a mistake.',
      duration: '2 min read',
      icon: Icons.favorite_border_rounded,
      color: AppColors.calmMintSurface,
    ),
    _LessonItem(
      category: 'Reducing Hesitation',
      title: 'Turn repetition into emphasis',
      description: 'Use repeated words as a gentle bridge.',
      duration: '4 min read',
      icon: Icons.auto_awesome_rounded,
      color: AppColors.calmBlueSurface,
    ),
  ];

  static const _categories = [
    'Breathing',
    'Pacing',
    'Confidence',
    'Reducing Hesitation',
  ];

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final visibleLessons = _lessons
        .where((lesson) => lesson.category == _selectedCategory)
        .toList();
    final featured = visibleLessons.firstOrNull ?? _lessons.first;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.calmText.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.calmMint,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'SpeechUp',
                  style: base.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.calmText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Learn calmly',
              style: base.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.calmText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Small lessons for easier speaking.',
              style: base.copyWith(
                fontSize: 15,
                height: 1.45,
                color: AppColors.calmTextSecondary,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(category),
                    selectedColor: AppColors.calmMintSurface,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected
                          ? AppColors.calmMint
                          : AppColors.calmTextSecondary.withValues(alpha: 0.16),
                    ),
                    labelStyle: base.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.calmText,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            _FeaturedLessonCard(lesson: featured),
            const SizedBox(height: 18),
            ...visibleLessons.map(
              (lesson) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LessonCard(
                  lesson: lesson,
                  onTap: () => _openLesson(lesson),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLesson(_LessonItem lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _LessonDetailScreen(lesson: lesson)),
    );
  }
}

class _LessonItem {
  final String category;
  final String title;
  final String description;
  final String duration;
  final IconData icon;
  final Color color;

  const _LessonItem({
    required this.category,
    required this.title,
    required this.description,
    required this.duration,
    required this.icon,
    required this.color,
  });
}

class _FeaturedLessonCard extends StatelessWidget {
  final _LessonItem lesson;

  const _FeaturedLessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: lesson.color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.calmText.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(lesson.icon, color: AppColors.calmText, size: 42),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.category,
                  style: base.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.calmTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lesson.title,
                  style: base.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.calmText,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final _LessonItem lesson;
  final VoidCallback onTap;

  const _LessonCard({required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: lesson.color,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(lesson.icon, color: AppColors.calmText),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: base.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.calmText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      style: base.copyWith(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.calmTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                lesson.duration,
                style: base.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.calmTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonDetailScreen extends StatelessWidget {
  final _LessonItem lesson;

  const _LessonDetailScreen({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return Scaffold(
      backgroundColor: AppColors.calmBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: 12),
              Text(
                lesson.title,
                style: base.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.calmText,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lesson.duration,
                style: base.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.calmTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _LessonParagraph(
                title: 'Why it helps',
                body:
                    'A small pause gives your first word more space. You do not need to make it perfect.',
              ),
              _LessonParagraph(
                title: 'Try this',
                body:
                    'Relax your shoulders. Breathe in gently. Begin speaking as your exhale starts.',
              ),
              _LessonParagraph(
                title: 'Practice phrase',
                body: '"I would like to start with..."',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Try this in Practice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonParagraph extends StatelessWidget {
  final String title;
  final String body;

  const _LessonParagraph({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: base.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.calmText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: base.copyWith(
              fontSize: 15,
              height: 1.55,
              color: AppColors.calmTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
