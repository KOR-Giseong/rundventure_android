// functions/index.js

const { onCall } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

// 관리자 권한 부여
exports.setAdminClaim = onCall(async (request) => {
  const { email } = request.data;
  const allowedAdminEmails = ["admin@naver.com", "test12@enaver.com"];

  if (!allowedAdminEmails.includes(email)) {
    throw new Error("Permission denied.");
  }

  const user = await admin.auth().getUserByEmail(email);
  await admin.auth().setCustomUserClaims(user.uid, {
    isAdmin: true,
  });

  return { message: "관리자 권한 부여 완료" };
});

// 특정 사용자에게 알림 전송
exports.sendNotificationToUser = onCall(async (request) => {
  const { uid, title, body } = request.data;

  const userDoc = await admin.firestore().collection("users").doc(uid).get();
  const fcmToken = userDoc.data()?.fcmToken;

  if (!fcmToken) {
    throw new Error("FCM 토큰이 없습니다.");
  }

  const message = {
    token: fcmToken,
    notification: { title, body },
    data: { click_action: "FLUTTER_NOTIFICATION_CLICK" },
  };

  await admin.messaging().send(message);
  return { success: true, message: "알림 전송 성공" };
});

// 전체 사용자에게 알림 전송
exports.sendNotificationToAll = onCall(async (request) => {
  const { title, body } = request.data;

  const snapshot = await admin.firestore().collection("users").get();
  const tokens = snapshot.docs.map(doc => doc.data().fcmToken).whereType<String>();

  if (tokens.length === 0) {
    throw new Error("FCM 토큰이 없습니다.");
  }

  const message = {
    notification: { title, body },
    tokens: Array.from(tokens),
  };

  const response = await admin.messaging().sendMulticast(message);
  return { success: true, message: `${response.successCount}명에게 전송됨` };
});