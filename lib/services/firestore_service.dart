import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/practice_session.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User Profile ───────────────────────────────────────────

  /// Create user profile after registration
  Future<void> createUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.uid).set(profile.toFirestore());
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  /// Update user profile fields
  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    await _db.collection('users').doc(uid).update(updates);
  }

  /// Stream user profile for real-time updates
  Stream<UserProfile?> streamUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  // ─── Practice Sessions ──────────────────────────────────────

  /// Save a practice session
  Future<DocumentReference> savePracticeSession(
      PracticeSession session) async {
    return await _db.collection('practice_sessions').add(session.toFirestore());
  }

  /// Get recent practice sessions for a user
  Future<List<PracticeSession>> getRecentSessions(String userId,
      {int limit = 10}) async {
    final query = await _db
        .collection('practice_sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return query.docs
        .map((doc) => PracticeSession.fromFirestore(doc))
        .toList();
  }

  /// Get today's sessions for daily score calculation
  Future<List<PracticeSession>> getTodaySessions(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final query = await _db
        .collection('practice_sessions')
        .where('userId', isEqualTo: userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs
        .map((doc) => PracticeSession.fromFirestore(doc))
        .toList();
  }

  /// Calculate daily score from today's sessions
  Future<int> getDailyScore(String userId) async {
    final sessions = await getTodaySessions(userId);
    if (sessions.isEmpty) return 0;
    final total = sessions.fold<int>(0, (acc, s) => acc + s.score);
    return (total / sessions.length).round();
  }

  /// Get session count for a specific date range
  Future<int> getSessionCount(
      String userId, DateTime start, DateTime end) async {
    final query = await _db
        .collection('practice_sessions')
        .where('userId', isEqualTo: userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();
    return query.size;
  }

  // ─── Conversation History ───────────────────────────────────

  /// Save conversation
  Future<void> saveConversation({
    required String userId,
    required String scenarioId,
    required List<Map<String, dynamic>> messages,
  }) async {
    await _db.collection('conversations').add({
      'userId': userId,
      'scenarioId': scenarioId,
      'messages': messages,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get conversation history
  Future<List<Map<String, dynamic>>> getConversationHistory(String userId,
      {int limit = 20}) async {
    final query = await _db
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ─── Progress & Stats ──────────────────────────────────────

  /// Get weekly scores (last 7 days)
  Future<List<int>> getWeeklyScores(String userId) async {
    final now = DateTime.now();
    final scores = <int>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));

      final query = await _db
          .collection('practice_sessions')
          .where('userId', isEqualTo: userId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .get();

      if (query.docs.isEmpty) {
        scores.add(0);
      } else {
        final total = query.docs.fold<int>(
            0, (acc, doc) => acc + ((doc.data()['score'] ?? 0) as int));
        scores.add((total / query.docs.length).round());
      }
    }
    return scores;
  }

  /// Update the streak count for a user
  Future<void> updateStreak(String userId) async {
    final profile = await getUserProfile(userId);
    if (profile == null) return;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final startOfYesterday =
        DateTime(yesterday.year, yesterday.month, yesterday.day);
    final endOfYesterday = startOfYesterday.add(const Duration(days: 1));

    // Check if user practiced yesterday
    final yesterdayCount =
        await getSessionCount(userId, startOfYesterday, endOfYesterday);

    int newStreak;
    if (yesterdayCount > 0) {
      newStreak = profile.streakDays + 1;
    } else {
      // Check if user already practiced today (don't reset)
      final startOfToday = DateTime(now.year, now.month, now.day);
      final todayCount =
          await getSessionCount(userId, startOfToday, now);
      newStreak = todayCount > 0 ? 1 : 0;
    }

    await updateUserProfile(userId, {'streakDays': newStreak});
  }
}
