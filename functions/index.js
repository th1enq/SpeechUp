const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");

admin.initializeApp();

exports.sendNotificationPush = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const notification = snapshot.data();
    const userId = notification.userId;
    if (!userId) return;

    const userRef = admin.firestore().collection("users").doc(userId);
    const [userSnapshot, tokensSnapshot] = await Promise.all([
      userRef.get(),
      userRef.collection("fcm_tokens").get(),
    ]);

    const rawNotificationMode =
      (userSnapshot.exists && userSnapshot.data().notificationAlertMode) ||
      "sound";
    if (userSnapshot.exists && userSnapshot.data().notificationsEnabled === false) {
      return;
    }
    const notificationMode = ["sound", "vibrate", "silent"].includes(
      rawNotificationMode,
    )
      ? rawNotificationMode
      : "sound";
    const channelId = `speechup_notification_${notificationMode}_channel`;

    const tokens = tokensSnapshot.docs
      .map((doc) => doc.data().token)
      .filter((token) => typeof token === "string" && token.length > 0);

    if (tokens.length === 0) return;

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: notification.title || "SpeechUp",
        body: notification.body || "Bạn có thông báo mới.",
      },
      data: {
        notificationId: snapshot.id,
        type: notification.type || "general",
      },
      android: {
        priority: "high",
        notification: {
          channelId,
        },
      },
    });

    const invalidTokenCodes = new Set([
      "messaging/invalid-registration-token",
      "messaging/registration-token-not-registered",
    ]);

    const deletes = [];
    response.responses.forEach((sendResponse, index) => {
      const errorCode = sendResponse.error && sendResponse.error.code;
      if (errorCode && invalidTokenCodes.has(errorCode)) {
        deletes.push(tokensSnapshot.docs[index].ref.delete());
      }
    });

    await Promise.all(deletes);
  },
);

exports.enqueuePracticeReminderNotifications = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "UTC",
  },
  async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const usersSnapshot = await db
      .collection("users")
      .where("nextPracticeReminderAt", "<=", now)
      .orderBy("nextPracticeReminderAt")
      .limit(100)
      .get();

    const batch = db.batch();

    usersSnapshot.docs.forEach((userDoc) => {
      const user = userDoc.data();
      if (user.practiceReminderEnabled !== true) return;
      const dueAt = user.nextPracticeReminderAt;

      let nextReminderAt = dueAt && dueAt.toDate
        ? dueAt.toDate()
        : new Date();
      do {
        nextReminderAt = new Date(nextReminderAt.getTime() + 24 * 60 * 60 * 1000);
      } while (nextReminderAt <= new Date());

      batch.update(userDoc.ref, {
        nextPracticeReminderAt: admin.firestore.Timestamp.fromDate(
          nextReminderAt,
        ),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (user.notificationsEnabled === false) return;

      const notificationRef = db.collection("notifications").doc();
      batch.set(notificationRef, {
        userId: userDoc.id,
        title: "Nhắc lịch tập luyện",
        body: "Đến giờ tập luyện của bạn rồi.",
        type: "general",
        read: false,
        data: {
          source: "practice_reminder",
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
  },
);
