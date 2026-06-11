const express = require("express");
const router = express.Router();
const db = require("../db");

// ===============================
// GET USER NOTIFICATIONS
// ===============================
router.get("/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const [rows] = await db.query(
      `SELECT
        id,
        user_id,
        title,
        body,
        type,
        image_url,
        is_read,
        created_at
       FROM user_notifications
       WHERE user_id = ?
       ORDER BY created_at DESC`,
      [userId]
    );

    res.status(200).json(rows);
  } catch (err) {
    console.log("FETCH USER NOTIFICATIONS ERROR:", err);
    res.status(500).json({
      message: "Failed to load notifications"
    });
  }
});

// ===============================
// MARK AS READ
// ===============================
router.patch("/read/:id", async (req, res) => {
  try {
    const { id } = req.params;

    await db.query(
      `UPDATE user_notifications SET is_read = 1 WHERE id = ?`,
      [id]
    );

    res.status(200).json({
      message: "Notification marked as read"
    });
  } catch (err) {
    console.log("MARK READ ERROR:", err);
    res.status(500).json({
      message: "Failed to update notification"
    });
  }
});

// ===============================
// DELETE NOTIFICATION
// ===============================
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    await db.query(
      `DELETE FROM user_notifications WHERE id = ?`,
      [id]
    );

    res.status(200).json({
      message: "Notification deleted"
    });
  } catch (err) {
    console.log("DELETE NOTIFICATION ERROR:", err);
    res.status(500).json({
      message: "Failed to delete notification"
    });
  }
});

module.exports = router;