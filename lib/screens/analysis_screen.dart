import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/shared_widgets.dart';

class AnalysisScreen extends StatefulWidget {
  final String transcript;
  final int durationSeconds;

  const AnalysisScreen({
    super.key,
    required this.transcript,
    required this.durationSeconds,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Show loading then animate in
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showContent = true);
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.transcript.split(' ');
    final fillerWords =
        words.where((w) => w.contains('ờ') || w.contains('à')).length;
    final totalWords = words.length;
    final wordsPerMinute =
        widget.durationSeconds > 0
            ? (totalWords / widget.durationSeconds * 60).round()
            : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Kết quả phân tích',
          style: GoogleFonts.varelaRound(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: !_showContent
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Đang phân tích...',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          : AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overall feedback
                      _buildOverallCard(),
                      const SizedBox(height: 20),

                      // Metrics
                      Text(
                        'Chi tiết',
                        style: GoogleFonts.varelaRound(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Speed metric
                      _MetricBar(
                        label: 'Tốc độ nói',
                        value: '$wordsPerMinute từ/phút',
                        progress: _progressAnimation.value *
                            (wordsPerMinute.clamp(0, 180) / 180),
                        color: wordsPerMinute > 160
                            ? AppColors.feedbackAttention
                            : wordsPerMinute > 120
                                ? AppColors.feedbackWarning
                                : AppColors.feedbackGood,
                        hint: wordsPerMinute > 160
                            ? 'Hơi nhanh, thử chậm lại nhé'
                            : wordsPerMinute > 120
                                ? 'Khá tốt rồi!'
                                : 'Tốc độ rất tốt!',
                      ),
                      const SizedBox(height: 14),

                      // Filler words
                      _MetricBar(
                        label: 'Từ đệm (ờ, à)',
                        value: '$fillerWords từ',
                        progress: _progressAnimation.value *
                            (fillerWords.clamp(0, 10) / 10),
                        color: fillerWords > 5
                            ? AppColors.feedbackAttention
                            : fillerWords > 2
                                ? AppColors.feedbackWarning
                                : AppColors.feedbackGood,
                        hint: fillerWords > 5
                            ? 'Thử giảm từ đệm nhé'
                            : fillerWords > 2
                                ? 'Không nhiều, tiếp tục cải thiện'
                                : 'Rất ít từ đệm, tuyệt vời!',
                      ),
                      const SizedBox(height: 14),

                      // Fluency
                      _MetricBar(
                        label: 'Độ trôi chảy',
                        value: 'Khá tốt',
                        progress: _progressAnimation.value * 0.72,
                        color: AppColors.feedbackGood,
                        hint: 'Bạn nói trôi chảy phần lớn thời gian',
                      ),
                      const SizedBox(height: 24),

                      // Transcript with highlights
                      Text(
                        'Bản ghi lời nói',
                        style: GoogleFonts.varelaRound(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTranscript(words),
                      const SizedBox(height: 24),

                      // AI feedback
                      Text(
                        'Lời khuyên',
                        style: GoogleFonts.varelaRound(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const FeedbackCard(
                        message:
                            'Bạn đã truyền đạt nội dung rất rõ ràng! Hãy thử hít một hơi sâu và nói chậm lại một nhịp ở đoạn giữa nhé. Việc giảm bớt từ đệm sẽ giúp bài nói thêm tự tin.',
                        feedbackColor: AppColors.feedbackGood,
                        icon: Icons.auto_awesome_rounded,
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Thử lại'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Lưu'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOverallCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF34D399)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cta.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.thumb_up_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn đã làm rất tốt!',
                  style: GoogleFonts.varelaRound(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tiếp tục phát huy nhé 💪',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscript(List<String> words) {
    return ClayContainer(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: words.map((word) {
          final isFiller = word.contains('ờ') || word.contains('à');

          Color bgColor = Colors.transparent;
          Color textColor = AppColors.textPrimary;

          if (isFiller) {
            bgColor = AppColors.feedbackWarning.withValues(alpha: 0.15);
            textColor = AppColors.feedbackWarning;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              word,
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: textColor,
                fontWeight: isFiller ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;
  final String hint;

  const _MetricBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
