// services/notificationListener.js
console.log("🔥 notificationListener LOADED");
const admin = require("firebase-admin");
const db = require("../db");
const eventEmitter = require("../events/eventEmitter");
const notificationService = require("./notificationService");

console.log("🔥 notificationListener INITIALIZED");

eventEmitter.on("ORDER_PLACED", async (data) => {
  console.log("🔥 EVENT RECEIVED BY LISTENER:", data);

  try {
    const activeUserId = data.userId || data.user_id;
    const activeOrderId = data.orderId || data.order_id;

    if (!activeUserId) {
      console.log("⚠️ No user found");
      return;
    }

    // 1. Save notification in DB
    await notificationService.createUserNotification({
      userId: activeUserId,
      orderId: activeOrderId,
      title: "Order Placed ",
      body: `Your order #${activeOrderId || ''} is confirmed`,
      type: "order",
    });

    // 2. FETCH FCM TOKEN FROM DB (important)
    const [rows] = await db.query(
      "SELECT fcmToken FROM users WHERE id = ?",
      [activeUserId]
    );

    const fcmToken = rows[0]?.fcmToken;

    // 3. SEND PUSH NOTIFICATION
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: "Order Placed ",
          body: `Your order #${activeOrderId} is confirmed`,
        },
        data: {
          orderId: String(activeOrderId),
          type: "order",
        },
      });

      console.log("📲 Push notification sent");
    } else {
      console.log("⚠️ No FCM token found for user");
    }

  } catch (err) {
    console.log("NOTIFICATION LISTENER ERROR:", err.message);
  }
});
eventEmitter.on("ORDER_SHIPPED", async ({ userId, orderId }) => {
  try {

    console.log("📦 ORDER_SHIPPED EVENT RECEIVED");

    // Insert DB notification
    await db.query(
      `INSERT INTO user_notifications
      (user_id, type, title, body, order_id, is_read)
      VALUES (?, ?, ?, ?)`,
      [
        userId,
        "Order Shipped",
        `Your order ${orderId} has been shipped.`,
        "ORDER_SHIPPED"
      ]
    );

    // Get user FCM token
    const [users] = await db.query(
      "SELECT fcmToken FROM users WHERE id = ?",
      [userId]
    );

    if (users.length === 0 || !users[0].fcmToken) {
      console.log(" No FCM token found");
      return;
    }

    const token = users[0].fcmToken;

    // Send push notification
    await admin.messaging().send({
      token,
      notification: {
        title: "Order Shipped 🚚",
        body: `Your order ${orderId} has been shipped.`,
      },
      data: {
        type: "ORDER_SHIPPED",
        orderId: orderId.toString(),
      }
    });

    console.log("Shipped notification sent");

  } catch (err) {
    console.error("ORDER_SHIPPED ERROR:", err);
  }
});
eventEmitter.on("ORDER_DELIVERED", async ({ userId, orderId }) => {
  try {

    console.log("ORDER_DELIVERED EVENT");

    await db.query(
      `INSERT INTO user_notifications (user_id, type, title, body, order_id, is_read)
       VALUES (?, ?, ?, ?)`,
      [
        userId,
        "Order Delivered",
        `Your order ${orderId} has been delivered successfully.`,
        "ORDER_DELIVERED"
      ]
    );

    const [rows] = await db.query(
      "SELECT fcmToken FROM users WHERE id = ?",
      [userId]
    );

    const token = rows[0]?.fcmToken;

    if (token) {
      await admin.messaging().send({
        token,
        notification: {
          title: "Delivered",
          body: `Order ${orderId} has been delivered.`,
        },
        data: {
          type: "ORDER_DELIVERED",
          orderId: orderId.toString(),
        },
      });
    }

  } catch (err) {
    console.error("DELIVERED NOTIFY ERROR:", err);
  }
});

eventEmitter.on("ORDER_CANCELED", async ({ userId, orderId }) => {
  try {
    console.log("📦 ORDER_CANCELED EVENT");

    await db.query(
      `INSERT INTO user_notifications (user_id, type, title, body, order_id, is_read)
       VALUES (?, ?, ?, ?)`,
      [
        userId,
        "Order Canceled ",
        `Your order ${orderId} has been canceled.`,
        "ORDER_CANCELED"
      ]
    );

    const [rows] = await db.query(
      "SELECT fcmToken FROM users WHERE id = ?",
      [userId]
    );

    const token = rows[0]?.fcmToken;

    if (!token) {
      console.log("⚠️ No FCM token");
      return;
    }

    await admin.messaging().send({
      token,
      notification: {
        title: "Order Canceled ❌",
        body: `Order ${orderId} was canceled`,
      },
      data: {
        type: "ORDER_CANCELED",
        orderId: String(orderId),
      }
    });

    console.log("✅ Cancel notification sent");

  } catch (err) {
    console.error(" CANCEL NOTIF ERROR:", err);
  }
});

eventEmitter.on("ORDER_RETURNED", async ({ userId, orderId }) => {
  try {

    console.log("🔄 ORDER_RETURNED EVENT");

    // 1️⃣ Save DB notification
    await db.query(
      `INSERT INTO user_notifications
       (user_id, type, title, body, order_id, is_read)
       VALUES (?, ?, ?, ?)`,
      [
        userId,
        "Return Requested 🔄",
        `Your return request for order ${orderId} has been received.`,
        "ORDER_RETURNED"
      ]
    );

    // 2️⃣ Fetch FCM token
    const [rows] = await db.query(
      "SELECT fcmToken FROM users WHERE id = ?",
      [userId]
    );

    const token = rows[0]?.fcmToken;

    if (!token) {
      console.log("❌ No FCM token found");
      return;
    }

    // 3️⃣ Send push notification
    await admin.messaging().send({
      token,
      notification: {
        title: "Return Requested 🔄",
        body: `Return request for order ${orderId} received.`,
      },
      data: {
        type: "ORDER_RETURNED",
        orderId: String(orderId),
      }
    });

    console.log("✅ Return notification sent");

  } catch (err) {
    console.error("❌ RETURN NOTIFICATION ERROR:", err);
  }
});

///////Refund request/////////////////////////////

eventEmitter.on("REFUND_REJECTED", async ({ userId, orderId }) => {
  console.log("🔥 REJECT LISTENER TRIGGERED:", { userId, orderId });

  try {
    // 1️⃣ Save notification to database logs with matching 6 parameters
    await db.query(
      `INSERT INTO user_notifications (user_id, type, title, body, order_id, is_read) VALUES (?, ?, ?, ?, ?, '0')`,
      [
        userId,
        "REFUND_REJECTED",
        "Refund Request Rejected ❌",
        `Your refund request for order #${orderId} has been rejected.`,
        String(orderId) // Populates the order_id column cleanly instead of leaving it NULL
      ]
    );
    console.log("✅ Rejection row saved to user_notifications");

    // 2️⃣ Fetch user FCM Token
    const [users] = await db.query("SELECT fcmToken FROM users WHERE id=?", [userId]);
    const token = users[0]?.fcmToken;

    if (!token) {
      console.log("❌ No FCM token found for user profile.");
      return;
    }

    // 3️⃣ Send FCM Push Notification safely
    try {
      await admin.messaging().send({
        token,
        notification: {
          title: "Refund Request Rejected ❌",
          body: `Refund request for order #${orderId} has been rejected.`,
        },
        data: {
          type: "REFUND_REJECTED",
          orderId: String(orderId),
        }
      });
      console.log("✅ Rejection push notification dispatched!");
    } catch (err) {
      console.log("❌ FCM TRANSMISSION ERROR:", err.message);
    }

  } catch (err) {
    console.error("❌ REFUND REJECTION PIPELINE ERROR:", err);
  }
});

/////////Merchant Panel notification listener/////////////////

eventEmitter.on("ORDER_PLACED", async (data) => {
  try {
    const { orderId } = data;

    console.log("📢 ORDER_PLACED → MERCHANT FLOW START");

    // 1. Get all merchants from order items
    const [rows] = await db.query(
      `
      SELECT DISTINCT p.merchant_id
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      WHERE oi.order_id = ?
      `,
      [orderId]
    );

    if (!rows.length) return;

    for (const row of rows) {
      const merchantId = row.merchant_id;

      // 2. Save DB notification
      await db.query(
        `INSERT INTO merchant_notifications
        (merchant_id, title, body, type, order_id, is_read)
        VALUES (?, ?, ?, ?, ?, 0)`,
        [
          merchantId,
          "New Order Received",
          `A new order #${orderId} has been placed`,
          "ORDER_PLACED",
          orderId,
        ]
      );

      console.log("✅ DB notification saved for merchant:", merchantId);

      // 3. Get FCM token
      const [m] = await db.query(
        "SELECT fcmToken FROM users WHERE id = ?",
        [merchantId]
      );

      const token = m[0]?.fcmToken;

      // 4. Send push notification (THIS IS POPUP PART)
      if (token) {
        await admin.messaging().send({
          token,
          notification: {
            title: "New Order Received",
            body: `Order #${orderId}`,
          },
          data: {
            type: "ORDER_PLACED",
            orderId: String(orderId),
          },
        });

        console.log("📲 PUSH SENT to merchant:", merchantId);
      }
    }
  } catch (err) {
    console.error("❌ MERCHANT ORDER NOTIFY ERROR:", err);
  }
});

eventEmitter.on("REFUND_REQUESTED", async ({ orderId }) => {
  try {
    console.log("🔄 REFUND REQUEST → MERCHANT");

    const [rows] = await db.query(
      `SELECT merchant_id FROM orders WHERE order_id = ?`,
      [orderId]
    );

    if (!rows.length) return;

    const merchantId = rows[0].merchant_id;

    await db.query(
      `INSERT INTO merchant_notifications
      (merchant_id, title, body, type, order_id, is_read)
      VALUES (?, ?, ?, ?, ?, 0)`,
      [
        merchantId,
        "Refund Requested 🔄",
        `Refund requested for order #${orderId}`,
        "REFUND_REQUESTED",
        orderId,
      ]
    );

    const [m] = await db.query(
      "SELECT fcmToken FROM users WHERE id = ?",
      [merchantId]
    );

    const token = m[0]?.fcmToken;

    if (token) {
      await admin.messaging().send({
        token,
        notification: {
          title: "Refund Requested 🔄",
          body: `Order #${orderId} refund requested`,
        },
        data: {
          type: "REFUND_REQUESTED",
          orderId: String(orderId),
        },
      });
    }
  } catch (err) {
    console.error(err);
  }
});

eventEmitter.on("PAYMENT_RECEIVED", async ({ orderId }) => {
  try {
    console.log("💰 PAYMENT RECEIVED → MERCHANT");

    const [rows] = await db.query(
      `SELECT merchant_id FROM orders WHERE order_id = ?`,
      [orderId]
    );

    if (!rows.length) return;

    const merchantId = rows[0].merchant_id;

    await db.query(
      `INSERT INTO merchant_notifications
      (merchant_id, title, body, type, order_id, is_read)
      VALUES (?, ?, ?, ?, ?, 0)`,
      [
        merchantId,
        "Payment Received 💰",
        `Payment received for order #${orderId}`,
        "PAYMENT_RECEIVED",
        orderId,
      ]
    );

    const [m] = await db.query(
      "SELECT fcmToken FROM users WHERE id = ?",
      [merchantId]
    );

    const token = m[0]?.fcmToken;

    if (token) {
      await admin.messaging().send({
        token,
        notification: {
          title: "Payment Received 💰",
          body: `Order #${orderId} paid successfully`,
        },
        data: {
          type: "PAYMENT_RECEIVED",
          orderId: String(orderId),
        },
      });
    }
  } catch (err) {
    console.error(err);
  }
});