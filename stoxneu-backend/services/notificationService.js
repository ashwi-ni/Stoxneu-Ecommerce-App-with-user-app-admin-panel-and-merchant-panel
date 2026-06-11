// services/notificationService.js
const db = require("../db");

const createUserNotification = async ({
  userId,
  title,
  body,
  type = "general",
  imageUrl = null,
  orderId = null
}) => {
  try {
    console.log(`💾 Inserting notification row for User ID: ${userId}, Order: ${orderId}`);

    await db.query(
      `INSERT INTO user_notifications
       (user_id, title, body, type, image_url, order_id)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [userId, title, body, type, imageUrl, orderId]
    );

    console.log("✅ SQL Insert successfully completed.");
  } catch (err) {
    console.log("❌ DATABASE NOTIFICATION SQL INSERT ERROR:", err.message);
    throw err;
  }
};

module.exports = {
  createUserNotification
};
