# Firebase data schema

Firestore is schemaless, so this file documents the schema the app currently
expects and writes.

## `users/{uid}`

Used by Home, Progress, Profile, onboarding/login setup, and streak.

Fields:
- `displayName: string`
- `email: string`
- `createdAt: timestamp`
- `totalSessions: number`
- `totalSpeakingMinutes: number`
- `averageScore: number`
- `streakDays: number`
- `lastQualifiedPracticeDate: timestamp | null`
- `lastPracticeAt: timestamp | null`
- `language: string`
- `difficulty: string`
- `notificationsEnabled: boolean` (controls app-side local notifications and
  FCM push delivery)
- `notificationAlertMode: "sound" | "vibrate" | "silent"`
- `practiceGoals: string[]`
- `practiceReminderEnabled: boolean`
- `practiceReminderHour: number`
- `practiceReminderMinute: number`
- `practiceReminderTimezoneOffsetMinutes: number`
- `nextPracticeReminderAt: timestamp`

Current gap:
- `avatarIndex`, `aiVoiceTone`, and `aiVoiceSpeed` are still stored locally in
  `SharedPreferences`, not Firestore.

## `practice_sessions/{autoId}`

Used by Practice, Home, and Progress.

Fields:
- `userId: string`
- `exerciseType: string`
- `content: string`
- `score: number`
- `durationSeconds: number`
- `fluency: number`
- `pronunciation: number`
- `speechSpeed: number`
- `createdAt: timestamp`
- `accuracyScore: number`
- `fluencyScore: number`
- `completenessScore: number`
- `prosodyScore: number`

## `conversations/{sessionId}`

Used by Conversation. For older records this may be an auto id; new records use
the generated session id as the document id.

Fields:
- `sessionId: string`
- `userId: string`
- `scenarioId: string`
- `scenarioTitle: string`
- `customPrompt: string | null`
- `provider: "gemini" | "scripted"`
- `messages: map[]`
- `messageCount: number`
- `startedAt: timestamp`
- `endedAt: timestamp`
- `createdAt: timestamp`
- `updatedAt: timestamp`

Message fields:
- `text: string`
- `isUser: boolean`
- `role: "user" | "assistant"`

## `notifications/{notificationId}`

Used by the notification bell and Social friend requests.

Fields:
- `userId: string`
- `title: string`
- `body: string`
- `type: "general" | "friend_request"`
- `read: boolean`
- `data: map`
- `createdAt: timestamp`
- `updatedAt: timestamp`

Friend request notification data:
- `connectionId: string`
- `requesterId: string`
- `requesterName: string`

## `users/{uid}/fcm_tokens/{tokenId}`

Used by Firebase Cloud Messaging.

Fields:
- `token: string`
- `platform: "android" | "unknown"`
- `createdAt: timestamp`
- `updatedAt: timestamp`

Cloud Functions:
- `sendNotificationPush` triggers when a `notifications/{notificationId}`
  document is created and sends FCM to the recipient's saved tokens using
  `users/{uid}.notificationAlertMode` to select the Android notification
  channel.
- `enqueuePracticeReminderNotifications` runs every minute, finds due
  `users/{uid}.nextPracticeReminderAt`, creates a `notifications/{autoId}`
  reminder document, and advances the next reminder by one day.

## Not persisted yet

- Scheduled reminder time is stored locally by `NotificationService`.
- Profile avatar and AI voice settings are stored locally.
- Progress milestones are computed/displayed in UI, not stored as separate
  Firestore achievement records.
