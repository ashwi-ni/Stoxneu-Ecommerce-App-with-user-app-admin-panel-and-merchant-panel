const admin = require("firebase-admin");
const db = require("../db");

async function sendPushToUser(userId, title, body) {
  try {
    const [rows] = await db.query(
      `SELECT fcmToken FROM users WHERE id = ?`,
      [userId]
    );

    if (!rows.length || !rows[0].fcmToken) return;

    const token = rows[0].fcmToken;

    const message = {
      notification: {
        title,
        body,
      },
      token: token,
    };

    const response = await admin.messaging().send(message);

    console.log("FCM sent:", response);
  } catch (err) {
    console.log("FCM ERROR:", err);
  }
}

module.exports = { sendPushToUser };