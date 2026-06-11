//const db = require("../db");
//
//
//// ========================================
//// GET USER NOTIFICATIONS
//// ========================================
//exports.getUserNotifications = async (req, res) => {
//  try {
//
//    const userId = req.user.id;
//
//    const [notifications] = await db.query(
//      `
//      SELECT *
//      FROM user_notifications
//      WHERE user_id = ?
//      ORDER BY created_at DESC
//      `,
//      [userId]
//    );
//
//    res.status(200).json({
//      success: true,
//      data: notifications,
//    });
//
//  } catch (error) {
//    console.log("GET USER NOTIFICATIONS ERROR:", error);
//
//    res.status(500).json({
//      success: false,
//      message: error.message,
//    });
//  }
notification_servicen