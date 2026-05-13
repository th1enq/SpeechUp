/// Structured result from Azure Pronunciation Assessment API.
///
/// Maps the JSON response from the Azure Speech SDK REST endpoint into typed
/// Dart fields.  All scores are 0–100 floats.  Word-level detail is optional
/// and only populated when the API response includes it.
class PronunciationResult {
  /// Overall pronunciation accuracy (0–100).
  final double accuracyScore;

  /// Speech fluency rating (0–100).
  final double fluencyScore;

  /// How much of the reference text was spoken (0–100).
  final double completenessScore;

  /// Prosody (intonation/rhythm) score (0–100).  May be 0 if the API doesn't
  /// return it for the selected language.
  final double prosodyScore;

  /// Per-word assessment detail (optional).
  final List<WordResult> words;

  /// The reference text that was assessed against.
  final String referenceText;

  /// Text recognized by Azure from the submitted audio, when available.
  final String recognizedText;

  /// Raw JSON from Azure for debugging / future use.
  final Map<String, dynamic>? rawJson;

  const PronunciationResult({
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    this.prosodyScore = 0,
    this.words = const [],
    this.referenceText = '',
    this.recognizedText = '',
    this.rawJson,
  });

  /// Composite score: weighted average of the four dimensions.
  double get overallScore =>
      (accuracyScore * 0.3 +
              fluencyScore * 0.3 +
              completenessScore * 0.2 +
              prosodyScore * 0.2)
          .clamp(0, 100);

  /// Build from the Azure REST JSON response (NBest[0].PronunciationAssessment).
  factory PronunciationResult.fromAzureJson(
    Map<String, dynamic> json, {
    String referenceText = '',
  }) {
    // The top-level NBest array contains assessment results.
    final nBest = json['NBest'] as List<dynamic>?;
    final best = (nBest != null && nBest.isNotEmpty)
        ? nBest[0] as Map<String, dynamic>
        : json;

    final pa = best['PronunciationAssessment'] as Map<String, dynamic>? ?? best;

    final wordsList = <WordResult>[];
    final wordsJson = best['Words'] as List<dynamic>?;
    if (wordsJson != null) {
      for (final w in wordsJson) {
        if (w is Map<String, dynamic>) {
          wordsList.add(WordResult.fromJson(w));
        }
      }
    }

    return PronunciationResult(
      accuracyScore: _toDouble(pa['AccuracyScore']),
      fluencyScore: _toDouble(pa['FluencyScore']),
      completenessScore: _toDouble(pa['CompletenessScore']),
      prosodyScore: _toDouble(pa['ProsodyScore'] ?? best['PronScore']),
      words: wordsList,
      referenceText: referenceText,
      recognizedText: _recognizedTextFromAzure(json, best),
      rawJson: json,
    );
  }

  /// Build a placeholder result for when Azure is unavailable.
  factory PronunciationResult.placeholder({
    double accuracy = 0,
    double fluency = 0,
    double completeness = 0,
    double prosody = 0,
  }) {
    return PronunciationResult(
      accuracyScore: accuracy,
      fluencyScore: fluency,
      completenessScore: completeness,
      prosodyScore: prosody,
    );
  }

  Map<String, dynamic> toMap() => {
    'accuracyScore': accuracyScore,
    'fluencyScore': fluencyScore,
    'completenessScore': completenessScore,
    'prosodyScore': prosodyScore,
    'overallScore': overallScore,
    'referenceText': referenceText,
    'recognizedText': recognizedText,
  };

  factory PronunciationResult.fromMap(Map<String, dynamic> map) {
    return PronunciationResult(
      accuracyScore: _toDouble(map['accuracyScore']),
      fluencyScore: _toDouble(map['fluencyScore']),
      completenessScore: _toDouble(map['completenessScore']),
      prosodyScore: _toDouble(map['prosodyScore']),
      referenceText: map['referenceText'] as String? ?? '',
      recognizedText: map['recognizedText'] as String? ?? '',
    );
  }

  static String _recognizedTextFromAzure(
    Map<String, dynamic> root,
    Map<String, dynamic> best,
  ) {
    final candidates = [
      best['Display'],
      best['DisplayText'],
      root['DisplayText'],
      best['Lexical'],
      root['Text'],
    ];
    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  String toString() =>
      'PronunciationResult(accuracy=$accuracyScore, fluency=$fluencyScore, '
      'completeness=$completenessScore, prosody=$prosodyScore, '
      'overall=${overallScore.toStringAsFixed(1)})';
}

/// Per-word pronunciation assessment.
class WordResult {
  final String word;
  final double accuracyScore;

  /// "None", "Omission", "Insertion", "Mispronunciation", etc.
  final String errorType;

  const WordResult({
    required this.word,
    required this.accuracyScore,
    this.errorType = 'None',
  });

  bool get hasError => errorType != 'None';

  factory WordResult.fromJson(Map<String, dynamic> json) {
    final pa = json['PronunciationAssessment'] as Map<String, dynamic>? ?? json;
    return WordResult(
      word: json['Word'] as String? ?? '',
      accuracyScore: PronunciationResult._toDouble(pa['AccuracyScore']),
      errorType: pa['ErrorType'] as String? ?? 'None',
    );
  }
}
