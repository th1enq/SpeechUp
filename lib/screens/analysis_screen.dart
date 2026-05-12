import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/pronunciation_result.dart';
import '../widgets/shared_widgets.dart';

class AnalysisScreen extends StatefulWidget {
  final String transcript;
  final int durationSeconds;

  /// Azure Pronunciation Assessment result (null when Azure is unavailable).
  final PronunciationResult? pronunciationResult;

  const AnalysisScreen({
    super.key,
    required this.transcript,
    required this.durationSeconds,
    this.pronunciationResult,
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
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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

  TextStyle get _base => GoogleFonts.plusJakartaSans();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final words = widget.transcript.split(' ');
    final fillerWords = words
        .where((w) => w.contains('ờ') || w.contains('à'))
        .length;
    final totalWords = words.length;
    final wordsPerMinute = widget.durationSeconds > 0
        ? (totalWords / widget.durationSeconds * 60).round()
        : 0;

    final pr = widget.pronunciationResult;
    final hasAzure = pr != null && pr.accuracyScore > 0;
    final clarityScore = hasAzure
        ? pr.accuracyScore.round()
        : _localClarityScore(wordsPerMinute, fillerWords);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Kết quả phân tích',
          style: _base.copyWith(
            fontWeight: FontWeight.w800,
            color: c.textHeading,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: c.textHeading),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: !_showContent
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: c.accentBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Đang phân tích...',
                    style: _base.copyWith(fontSize: 16, color: c.textMuted),
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
                      // ── Overall score hero card ──
                      _buildOverallCard(c, hasAzure, pr),
                      const SizedBox(height: 24),

                      // ── Azure Pronunciation Scores ──
                      if (hasAzure) ...[
                        Text(
                          'Đánh giá phát âm',
                          style: _base.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: c.textHeading,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _AzureScoreGrid(
                          animation: _progressAnimation,
                          accuracy: pr.accuracyScore,
                          fluency: pr.fluencyScore,
                          completeness: pr.completenessScore,
                          prosody: pr.prosodyScore,
                          c: c,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Basic metrics ──
                      Text(
                        'Chi tiết',
                        style: _base.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: c.textHeading,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Speed metric
                      _MetricBar(
                        label: 'Tốc độ nói',
                        value: '$wordsPerMinute từ/phút',
                        progress:
                            _progressAnimation.value *
                            (wordsPerMinute.clamp(0, 180) / 180),
                        color: wordsPerMinute > 160
                            ? c.feedbackAttention
                            : wordsPerMinute > 120
                            ? c.feedbackWarning
                            : c.feedbackGood,
                        hint: wordsPerMinute > 160
                            ? 'Hơi nhanh, thử chậm lại nhé'
                            : wordsPerMinute > 120
                            ? 'Khá tốt rồi!'
                            : 'Tốc độ rất tốt!',
                        c: c,
                      ),
                      const SizedBox(height: 14),

                      // Filler words
                      _MetricBar(
                        label: 'Từ đệm (ờ, à)',
                        value: '$fillerWords từ',
                        progress:
                            _progressAnimation.value *
                            (fillerWords.clamp(0, 10) / 10),
                        color: fillerWords > 5
                            ? c.feedbackAttention
                            : fillerWords > 2
                            ? c.feedbackWarning
                            : c.feedbackGood,
                        hint: fillerWords > 5
                            ? 'Thử giảm từ đệm nhé'
                            : fillerWords > 2
                            ? 'Không nhiều, tiếp tục cải thiện'
                            : 'Rất ít từ đệm, tuyệt vời!',
                        c: c,
                      ),
                      const SizedBox(height: 14),

                      // Fluency (from Azure or local estimate)
                      _MetricBar(
                        label: 'Độ trôi chảy',
                        value: hasAzure
                            ? '${pr.fluencyScore.round()}%'
                            : 'Khá tốt',
                        progress:
                            _progressAnimation.value *
                            (hasAzure ? pr.fluencyScore / 100 : 0.72),
                        color: c.feedbackGood,
                        hint: hasAzure
                            ? _fluencyHint(pr.fluencyScore)
                            : 'Bạn nói trôi chảy phần lớn thời gian',
                        c: c,
                      ),
                      const SizedBox(height: 14),

                      _MetricBar(
                        label: 'Độ rõ',
                        value: '$clarityScore%',
                        progress:
                            _progressAnimation.value * (clarityScore / 100),
                        color: clarityScore >= 80
                            ? c.feedbackGood
                            : clarityScore >= 65
                            ? c.feedbackWarning
                            : c.feedbackAttention,
                        hint: hasAzure
                            ? _clarityHint(clarityScore)
                            : _localClarityHint(clarityScore),
                        c: c,
                      ),
                      const SizedBox(height: 24),

                      // ── Word-level highlights (if Azure available) ──
                      if (hasAzure && pr.words.isNotEmpty) ...[
                        Text(
                          'Phát âm từng từ',
                          style: _base.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: c.textHeading,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAzureWordHighlights(pr.words, c),
                        const SizedBox(height: 24),
                      ] else ...[
                        // Fallback transcript with filler highlights
                        Text(
                          'Bản ghi lời nói',
                          style: _base.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: c.textHeading,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTranscript(words, c),
                        const SizedBox(height: 24),
                      ],

                      // ── AI feedback ──
                      Text(
                        'Lời khuyên',
                        style: _base.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: c.textHeading,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FeedbackCard(
                        message: hasAzure
                            ? _buildAzureAdvice(pr)
                            : 'Bạn đã truyền đạt nội dung rất rõ ràng! Hãy thử hít '
                                  'một hơi sâu và nói chậm lại một nhịp ở đoạn giữa nhé. '
                                  'Việc giảm bớt từ đệm sẽ giúp bài nói thêm tự tin.',
                        feedbackColor: c.feedbackGood,
                        icon: Icons.auto_awesome_rounded,
                      ),
                      const SizedBox(height: 24),

                      // ── Action buttons ──
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              onTap: () => Navigator.of(context).pop(),
                              icon: Icons.refresh_rounded,
                              label: 'Thử lại',
                              filled: false,
                              c: c,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              onTap: () => Navigator.of(context).pop(),
                              icon: Icons.check_circle_rounded,
                              label: 'Hoàn tất',
                              filled: true,
                              c: c,
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

  // ── Overall Hero Card ──
  Widget _buildOverallCard(
    AppColorsExtension c,
    bool hasAzure,
    PronunciationResult? pr,
  ) {
    final overallScore = hasAzure ? pr!.overallScore : null;
    final emoji = overallScore != null
        ? (overallScore >= 80
              ? '🌟'
              : overallScore >= 60
              ? '👍'
              : '💪')
        : '👍';
    final title = overallScore != null
        ? (overallScore >= 80
              ? 'Xuất sắc!'
              : overallScore >= 60
              ? 'Khá tốt!'
              : 'Tiếp tục luyện tập!')
        : 'Bạn đã làm rất tốt!';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: c.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.accentBlueDeep.withValues(alpha: 0.35),
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
            child: overallScore != null
                ? Center(
                    child: Text(
                      '${overallScore.round()}',
                      style: _base.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const Icon(
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
                  '$emoji $title',
                  style: _base.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  overallScore != null
                      ? 'Điểm tổng: ${overallScore.round()}/100'
                      : 'Tiếp tục phát huy nhé 💪',
                  style: _base.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

  // ── Azure word highlights (color-coded by accuracy) ──
  Widget _buildAzureWordHighlights(
    List<WordResult> words,
    AppColorsExtension c,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 5,
        runSpacing: 6,
        children: words.map((w) {
          Color bgColor;
          Color textColor;

          if (w.hasError) {
            bgColor = c.error.withValues(alpha: 0.12);
            textColor = c.error;
          } else if (w.accuracyScore >= 80) {
            bgColor = c.feedbackGood.withValues(alpha: 0.1);
            textColor = c.feedbackGood;
          } else if (w.accuracyScore >= 50) {
            bgColor = c.feedbackWarning.withValues(alpha: 0.12);
            textColor = c.feedbackWarning;
          } else {
            bgColor = c.error.withValues(alpha: 0.1);
            textColor = c.error;
          }

          return Tooltip(
            message: w.hasError
                ? '${w.errorType} — ${w.accuracyScore.round()}%'
                : '${w.accuracyScore.round()}%',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                w.word,
                style: _base.copyWith(
                  fontSize: 15,
                  color: textColor,
                  fontWeight: w.hasError ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Fallback transcript with filler word highlights ──
  Widget _buildTranscript(List<String> words, AppColorsExtension c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: words.map((word) {
          final isFiller = word.contains('ờ') || word.contains('à');

          Color bgColor = Colors.transparent;
          Color textColor = c.textBody;

          if (isFiller) {
            bgColor = c.feedbackWarning.withValues(alpha: 0.15);
            textColor = c.feedbackWarning;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              word,
              style: _base.copyWith(
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

  String _fluencyHint(double score) {
    if (score >= 85) return 'Bạn nói rất trôi chảy, tuyệt vời!';
    if (score >= 65) return 'Tốt lắm! Thử giảm khoảng dừng để tốt hơn.';
    return 'Hãy luyện thêm nhé, nói chậm rãi và tự tin hơn.';
  }

  int _localClarityScore(int wordsPerMinute, int fillerWords) {
    final speedPenalty = (wordsPerMinute - 145).abs().clamp(0, 35);
    final fillerPenalty = (fillerWords * 6).clamp(0, 24);
    return (88 - speedPenalty - fillerPenalty).clamp(55, 95);
  }

  String _clarityHint(int score) {
    if (score >= 85) return 'Bạn phát âm khá rõ, người nghe sẽ dễ theo dõi.';
    if (score >= 65) {
      return 'Khá ổn. Hãy nhấn âm cuối và nói chậm hơn một chút.';
    }
    return 'Cần nói rõ âm hơn và chia cụm câu ngắn hơn để dễ nghe.';
  }

  String _localClarityHint(int score) {
    if (score >= 85) return 'Nhịp nói và cách diễn đạt của bạn khá rõ ràng.';
    if (score >= 65) return 'Ổn rồi. Thử giảm từ đệm và giữ tốc độ đều hơn.';
    return 'Hãy nói chậm hơn và ngắt cụm rõ hơn để người nghe dễ hiểu.';
  }

  String _buildAzureAdvice(PronunciationResult pr) {
    final parts = <String>[];

    if (pr.accuracyScore >= 85) {
      parts.add('Phát âm của bạn rất chính xác!');
    } else if (pr.accuracyScore >= 60) {
      parts.add(
        'Phát âm khá tốt. Hãy chú ý các từ được đánh dấu để cải thiện.',
      );
    } else {
      parts.add('Hãy luyện phát âm thêm nhé. Thử nghe mẫu và lặp lại từng từ.');
    }

    if (pr.fluencyScore < 70) {
      parts.add('Thử nói trôi chảy hơn bằng cách giảm bớt khoảng dừng.');
    }

    if (pr.completenessScore < 80) {
      parts.add('Bạn đã bỏ sót một số từ. Hãy đọc hết câu nhé.');
    }

    if (pr.prosodyScore > 0 && pr.prosodyScore < 60) {
      parts.add('Hãy thử thay đổi ngữ điệu để bài nói tự nhiên hơn.');
    }

    return parts.join(' ');
  }
}

// ── Azure score grid: 2x2 circular score cards ──
class _AzureScoreGrid extends StatelessWidget {
  final Animation<double> animation;
  final double accuracy;
  final double fluency;
  final double completeness;
  final double prosody;
  final AppColorsExtension c;

  const _AzureScoreGrid({
    required this.animation,
    required this.accuracy,
    required this.fluency,
    required this.completeness,
    required this.prosody,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _ScoreCircleCard(
                label: 'Chính xác',
                score: accuracy,
                icon: Icons.gps_fixed_rounded,
                color: c.accentBlue,
                animation: animation,
                c: c,
              ),
              const SizedBox(height: 12),
              _ScoreCircleCard(
                label: 'Đầy đủ',
                score: completeness,
                icon: Icons.checklist_rounded,
                color: c.accentPurple,
                animation: animation,
                c: c,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _ScoreCircleCard(
                label: 'Trôi chảy',
                score: fluency,
                icon: Icons.waves_rounded,
                color: c.feedbackGood,
                animation: animation,
                c: c,
              ),
              const SizedBox(height: 12),
              _ScoreCircleCard(
                label: 'Ngữ điệu',
                score: prosody,
                icon: Icons.music_note_rounded,
                color: c.feedbackWarning,
                animation: animation,
                c: c,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreCircleCard extends StatelessWidget {
  final String label;
  final double score;
  final IconData icon;
  final Color color;
  final Animation<double> animation;
  final AppColorsExtension c;

  const _ScoreCircleCard({
    required this.label,
    required this.score,
    required this.icon,
    required this.color,
    required this.animation,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final animatedScore = (score * animation.value).round();
    final animatedProgress = (score / 100 * animation.value).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: animatedProgress,
                    strokeWidth: 5,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '$animatedScore',
                  style: base.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: c.textHeading,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: base.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Metric bar (existing design, updated for theme) ──
class _MetricBar extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;
  final String hint;
  final AppColorsExtension c;

  const _MetricBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.hint,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: base.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textHeading,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value,
                  style: base.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
            style: base.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ──
class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool filled;
  final AppColorsExtension c;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.filled,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return SizedBox(
      height: 52,
      child: Material(
        color: filled ? null : c.cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: filled ? c.heroGradient : null,
              color: filled ? null : c.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: filled ? null : Border.all(color: c.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: filled ? Colors.white : c.textHeading,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: base.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: filled ? Colors.white : c.textHeading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
