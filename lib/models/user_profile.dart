import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final DateTime createdAt;
  final int totalSessions;
  final double totalSpeakingMinutes;
  final int averageScore;
  final int streakDays;
  final String language;
  final String difficulty;
  final bool notificationsEnabled;
  final bool privateMode;
  final bool saveTranscripts;
  final String microphoneLocaleId;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.createdAt,
    this.totalSessions = 0,
    this.totalSpeakingMinutes = 0,
    this.averageScore = 0,
    this.streakDays = 0,
    this.language = 'English (US)',
    this.difficulty = 'Intermediate',
    this.notificationsEnabled = true,
    this.privateMode = true,
    this.saveTranscripts = true,
    this.microphoneLocaleId = 'en_US',
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalSessions: data['totalSessions'] ?? 0,
      totalSpeakingMinutes: (data['totalSpeakingMinutes'] ?? 0).toDouble(),
      averageScore: data['averageScore'] ?? 0,
      streakDays: data['streakDays'] ?? 0,
      language: data['language'] ?? 'English (US)',
      difficulty: data['difficulty'] ?? 'Intermediate',
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      privateMode: data['privateMode'] ?? true,
      saveTranscripts: data['saveTranscripts'] ?? true,
      microphoneLocaleId: data['microphoneLocaleId'] ?? 'en_US',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalSessions': totalSessions,
      'totalSpeakingMinutes': totalSpeakingMinutes,
      'averageScore': averageScore,
      'streakDays': streakDays,
      'language': language,
      'difficulty': difficulty,
      'notificationsEnabled': notificationsEnabled,
      'privateMode': privateMode,
      'saveTranscripts': saveTranscripts,
      'microphoneLocaleId': microphoneLocaleId,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    int? totalSessions,
    double? totalSpeakingMinutes,
    int? averageScore,
    int? streakDays,
    String? language,
    String? difficulty,
    bool? notificationsEnabled,
    bool? privateMode,
    bool? saveTranscripts,
    String? microphoneLocaleId,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt,
      totalSessions: totalSessions ?? this.totalSessions,
      totalSpeakingMinutes: totalSpeakingMinutes ?? this.totalSpeakingMinutes,
      averageScore: averageScore ?? this.averageScore,
      streakDays: streakDays ?? this.streakDays,
      language: language ?? this.language,
      difficulty: difficulty ?? this.difficulty,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      privateMode: privateMode ?? this.privateMode,
      saveTranscripts: saveTranscripts ?? this.saveTranscripts,
      microphoneLocaleId: microphoneLocaleId ?? this.microphoneLocaleId,
    );
  }
}
