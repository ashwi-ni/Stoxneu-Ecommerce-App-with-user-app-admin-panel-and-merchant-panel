const db = require("../db");
const eventEmitter = require("../events/eventEmitter");

exports.createOrder = async (req, res) => {
  try {
    console.log("📦 CREATE ORDER CONTROLLER HIT");

    // Safety check: Fallback to an empty object if the body arrives unparsed
    const order = req.body || {};

    // 1️⃣ UNIVERSAL PARSING: Capture the items array from ANY layout format variation
    const rawItems = order.items || order.orderItems || order.order_items;

    // Strict validation verification check
    if (!rawItems || !Array.isArray(rawItems) || rawItems.length === 0) {
      console.log("⚠️ BLOCKED: Incoming request payload has no items array or it is empty.");
      console.log("📄 RECEIVED BODY STRUCTURE FOR AUDIT:", JSON.stringify(order));
      return res.status(400).json({ message: "Invalid order payload - items array missing" });
    }

    // 2️⃣ EXTRACT THE TARGET PRODUCT ID FROM FIRST ARRAY ROW SAFELY
    const firstItem = rawItems[0];
    const targetProductId = firstItem.productId || firstItem.product_id || firstItem.id;

    if (!targetProductId) {
      console.log("⚠️ BLOCKED: First array element is missing a valid product identification property.");
      return res.status(400).json({ message: "Invalid order payload - product identification key missing" });
    }

    console.log(`🔍 Fetching merchant identifier for Product ID: ${targetProductId}`);

    // Get merchant id from first product entry match
    const [productRows] = await db.query(
      `SELECT merchant_id FROM products WHERE id = ?`,
      [targetProductId]
    );

    if (!productRows || productRows.length === 0) {
      console.log(`❌ ERROR: Product with ID ${targetProductId} not found inside catalog.`);
      return res.status(404).json({ message: "Matching product row not found" });
    }

    // Extract the primary row index cleanly
    const merchantId = productRows[0].merchant_id;
    console.log(`🏪 Found Merchant ID: ${merchantId}`);

    // 3️⃣ INSERT SYSTEM ORDER RECORD TO DISK
    await db.query(
      `INSERT INTO orders
      (order_id, user_id, merchant_id, total_amount, status, address, payment_method, payment_status, refund_status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        order.orderId || order.order_id,
        req.userId,
        merchantId,
        order.totalAmount || order.total_amount,
        (order.status || "PLACED").toUpperCase(),
        order.address || null,
        order.paymentMethod || order.payment_method || "ONLINE",
        order.paymentStatus || order.payment_status || "PAID",
        order.refundStatus || order.refund_status || "NONE",
      ]
    );
    console.log("📝 Main order row inserted into orders table.");

    // 4️⃣ LOOP THROUGH SATELLITE ITEMS MATRIX SEQUENTIALLY
    for (let item of rawItems) {
      await db.query(
        `INSERT INTO order_items
        (order_id, product_id, name, image_url, price, quantity)
        VALUES (?, ?, ?, ?, ?, ?)`,
        [
          order.orderId || order.order_id,
          item.productId || item.product_id || item.id,
          item.name,
          item.imageUrl || item.image_url || null,
          item.price,
          item.quantity,
        ]
      );
    }
    console.log("📝 All order items nested rows inserted cleanly.");

    // 5️⃣ TRIGGER EVENT LISTENER ARCHITECTURE SYSTEM HOOK
    console.log("📤 Emitting ORDER_PLACED event tracking payload...");
    eventEmitter.emit("ORDER_PLACED", {
      userId: req.userId,
      orderId: order.orderId || order.order_id
    });

    return res.status(201).json({ message: "Order created successfully" });

  } catch (e) {
    console.error("❌ ORDER CREATION CORE SYSTEM CRASH:", e);
    return res.status(500).json({ message: "Order creation failed", error: e.message });
  }
};
