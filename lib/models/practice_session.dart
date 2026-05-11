import 'package:cloud_firestore/cloud_firestore.dart';

class PracticeSession {
  final String? id;
  final String userId;
  final String exerciseType; // 'read', 'shadowing', 'slow'
  final String content;
  final int score;
  final int durationSeconds;
  final int fluency;
  final int pronunciation;
  final int speechSpeed;
  final DateTime createdAt;

  // ── Azure Pronunciation Assessment scores (0–100) ──
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;
  final double prosodyScore;

  const PracticeSession({
    this.id,
    required this.userId,
    required this.exerciseType,
    required this.content,
    this.score = 0,
    this.durationSeconds = 0,
    this.fluency = 0,
    this.pronunciation = 0,
    this.speechSpeed = 0,
    required this.createdAt,
    this.accuracyScore = 0,
    this.fluencyScore = 0,
    this.completenessScore = 0,
    this.prosodyScore = 0,
  });

  factory PracticeSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PracticeSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      exerciseType: data['exerciseType'] ?? 'read',
      content: data['content'] ?? '',
      score: data['score'] ?? 0,
      durationSeconds: data['durationSeconds'] ?? 0,
      fluency: data['fluency'] ?? 0,
      pronunciation: data['pronunciation'] ?? 0,
      speechSpeed: data['speechSpeed'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      accuracyScore: (data['accuracyScore'] ?? 0).toDouble(),
      fluencyScore: (data['fluencyScore'] ?? 0).toDouble(),
      completenessScore: (data['completenessScore'] ?? 0).toDouble(),
      prosodyScore: (data['prosodyScore'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'exerciseType': exerciseType,
      'content': content,
      'score': score,
      'durationSeconds': durationSeconds,
      'fluency': fluency,
      'pronunciation': pronunciation,
      'speechSpeed': speechSpeed,
      'createdAt': Timestamp.fromDate(createdAt),
      'accuracyScore': accuracyScore,
      'fluencyScore': fluencyScore,
      'completenessScore': completenessScore,
      'prosodyScore': prosodyScore,
    };
  }
}
