import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/user_profile.dart';
import '../models/practice_session.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _logFirestoreError(String operation, Object error, [StackTrace? st]) {
    if (error is FirebaseException) {
      debugPrint(
        '[FirestoreService] $operation failed: ${error.code}: ${error.message}',
      );
    } else {
      debugPrint('[FirestoreService] $operation failed: $error');
    }
    if (st != null) debugPrint('$st');
  }

  // ─── User Profile ───────────────────────────────────────────

  /// Create user profile after registration
  Future<void> createUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.uid).set(profile.toFirestore());
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } on FirebaseException catch (e, st) {
      _logFirestoreError('getUserProfile($uid)', e, st);
      return null;
    } catch (e, st) {
      _logFirestoreError('getUserProfile($uid)', e, st);
      return null;
    }
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

  /// Check whether a profile already exists with this email.
  Future<bool> isEmailRegistered(String email) async {
    final normalized = email.trim().toLowerCase();
    try {
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: normalized)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } on FirebaseException catch (e, st) {
      _logFirestoreError('isEmailRegistered($email)', e, st);
      return false;
    } catch (e, st) {
      _logFirestoreError('isEmailRegistered($email)', e, st);
      return false;
    }
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
    try {
      final query = await _db
          .collection('practice_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return query.docs
          .map((doc) => PracticeSession.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e, st) {
      _logFirestoreError('getRecentSessions($userId)', e, st);
      return const [];
    } catch (e, st) {
      _logFirestoreError('getRecentSessions($userId)', e, st);
      return const [];
    }
  }

  /// Get today's sessions for daily score calculation
  Future<List<PracticeSession>> getTodaySessions(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
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
    } on FirebaseException catch (e, st) {
      _logFirestoreError('getTodaySessions($userId)', e, st);
      return const [];
    } catch (e, st) {
      _logFirestoreError('getTodaySessions($userId)', e, st);
      return const [];
    }
  }

  /// Get sessions for a specific date (local calendar day)
  Future<List<PracticeSession>> getSessionsForDate(
    String userId,
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    try {
      final query = await _db
          .collection('practice_sessions')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .get();
      return query.docs
          .map((doc) => PracticeSession.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e, st) {
      _logFirestoreError('getSessionsForDate($userId, $date)', e, st);
      return const [];
    } catch (e, st) {
      _logFirestoreError('getSessionsForDate($userId, $date)', e, st);
      return const [];
    }
  }

  /// Calculate daily score from today's sessions
  Future<int> getDailyScore(String userId) async {
    try {
      final sessions = await getTodaySessions(userId);
      if (sessions.isEmpty) return 0;
      final total = sessions.fold<int>(0, (acc, s) => acc + s.score);
      return (total / sessions.length).round();
    } on FirebaseException catch (e, st) {
      _logFirestoreError('getDailyScore($userId)', e, st);
      return 0;
    } catch (e, st) {
      _logFirestoreError('getDailyScore($userId)', e, st);
      return 0;
    }
  }

  /// Get session count for a specific date range
  Future<int> getSessionCount(
      String userId, DateTime start, DateTime end) async {
    try {
      final query = await _db
          .collection('practice_sessions')
          .where('userId', isEqualTo: userId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .get();
      return query.size;
    } on FirebaseException catch (e, st) {
      _logFirestoreError('getSessionCount($userId)', e, st);
      return 0;
    } catch (e, st) {
      _logFirestoreError('getSessionCount($userId)', e, st);
      return 0;
    }
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
    try {
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
    } on FirebaseException catch (e, st) {
      _logFirestoreError('getConversationHistory($userId)', e, st);
      return const [];
    } catch (e, st) {
      _logFirestoreError('getConversationHistory($userId)', e, st);
      return const [];
    }
  }

  // ─── Progress & Stats ──────────────────────────────────────

  /// Get weekly scores (last 7 days)
  Future<List<int>> getWeeklyScores(String userId, {DateTime? endDate}) async {
    final now = endDate ?? DateTime.now();
    final scores = <int>[];

    try {
      final normalizedNow = DateTime(now.year, now.month, now.day);
      for (int i = 6; i >= 0; i--) {
        final day = normalizedNow.subtract(Duration(days: i));
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
    } on FirebaseException catch (e, st) {
      _logFirestoreError('getWeeklyScores($userId)', e, st);
      return const [0, 0, 0, 0, 0, 0, 0];
    } catch (e, st) {
      _logFirestoreError('getWeeklyScores($userId)', e, st);
      return const [0, 0, 0, 0, 0, 0, 0];
    }
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
