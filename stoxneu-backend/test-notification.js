// test-notification.js
const db = require("./db"); // Adjust path to match your db file
const eventEmitter = require("./events/eventEmitter");

// 1. Force the listener file to load and register the event
console.log("🛠️ Loading notification listener...");
require("./services/notificationListener"); // Adjust path to match your listener file

async function runTest() {
  console.log("\n🚀 STARTING NOTIFICATION TEST...");

 const mockData = {
   userId: 1,
   orderId: "pay_SpZscQ5UQWj4Kl" // Simulates a real Razorpay ID
 };


  console.log("📤 Emitting ORDER_PLACED event manually...");

  // 2. Trigger the event manually
  eventEmitter.emit("ORDER_PLACED", mockData);

  // 3. Wait 2 seconds for the async database database insert to complete
  setTimeout(async () => {
    try {
      console.log("\n🔍 Checking database for saved notification...");
      const [rows] = await db.query(
        "SELECT * FROM user_notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 1",
        [mockData.userId]
      );

      if (rows && rows.length > 0) {
        console.log("🎉 SUCCESS! Notification found in database:");
        console.log(rows[0]);
      } else {
        console.log("❌ FAILURE: Event fired, but no database row was created.");
      }
    } catch (err) {
      console.log("❌ SQL ERROR DURING CHECK:", err.message);
    } finally {
      process.exit(0);
    }
  }, 2000);
}

runTest();
