require('dotenv').config();
const express = require('express');
const cors = require('cors');
const cron = require("node-cron");
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const bodyParser = require('body-parser');
const twilio = require('twilio');
const multer = require("multer");
const path = require("path");
const fs = require("fs");

const db = require('./db');

const app = express();
const eventEmitter = require("./events/eventEmitter");
//const eventEmitter = new EventEmitter();
//////////////////////// FIREBASE ////////////////////////

const admin = require('firebase-admin');
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log("Firebase Admin Version:", admin.SDK_VERSION);

//////////////////////// MIDDLEWARE ////////////////////////

// MUST COME BEFORE ROUTES
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'ngrok-skip-browser-warning'
  ],
  credentials: true
}));

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({
  limit: '50mb',
  extended: true
}));

app.use(bodyParser.json());

//////////////////////// NGROK FIX ////////////////////////

app.use((req, res, next) => {
  res.setHeader("ngrok-skip-browser-warning", "true");

  if (req.method === "OPTIONS") {
    return res.sendStatus(200);
  }

  next();
});

//////////////////////// STATIC FILES ////////////////////////

app.use(
  '/uploads',
  cors(),
  express.static('uploads', {
    setHeaders: (res) => {
      res.set('Access-Control-Allow-Origin', '*');
    }
  })
);

//////////////////////// SERVICES ////////////////////////

require("./services/notificationListener");

//////////////////////// MIDDLEWARE IMPORT ////////////////////////

const authMiddleware = require("./middleware/authMiddleware");

//////////////////////// ROUTES ////////////////////////

const notificationRoutes = require("./routes/notificationRoutes");
//const userNotificationRoutes = require("./routes/userNotificationRoutes");
const orderRoutes = require("./routes/orderRoutes");

app.use("/notifications", notificationRoutes);

//app.use("/user-notifications", userNotificationRoutes);

// ✅ SINGLE CLEAN ORDER ROUTE
app.use("/orders", orderRoutes);

//////////////////////// TEST ROUTE ////////////////////////

app.get('/test', (req, res) => {
  res.send("Server is completely alive and healthy");
});

// ================================
// CRON JOB (PUT HERE 👇)
// ================================
cron.schedule("0 0 * * *", async () => {

  try {

    const [result] = await db.query(
      `
      DELETE FROM user_notifications
      WHERE created_at < NOW() - INTERVAL 30 DAY
      `
    );

    console.log(`🧹 Deleted ${result.affectedRows} old notifications`);

  } catch (err) {
    console.error("CRON ERROR:", err);
  }
});

//////////////////////// TWILIO ////////////////////////
//
//const twilioClient = twilio(
//  process.env.TWILIO_SID,
//  process.env.TWILIO_AUTH_TOKEN
//);

//////////////////////// GOOGLE AUTH ////////////////////////

//const { OAuth2Client } = require('google-auth-library');
//
//console.log("GOOGLE_CLIENT_ID:", process.env.GOOGLE_CLIENT_ID);
//
//const googleClient = new OAuth2Client(
//  process.env.GOOGLE_CLIENT_ID
//);

//////////////////////// RAZORPAY ////////////////////////

//const Razorpay = require('razorpay');
//const crypto = require('crypto');
//
//const razorpay = new Razorpay({
//  key_id: 'rzp_test_SEMaMT8TVnP5xL',
//  key_secret: 'TnoWZHt1sfcOIEHSow53rKMU'
//});

//////////////////////// MULTER ////////////////////////

//const storage = multer.diskStorage({
//  destination: function (req, file, cb) {
//    cb(null, "uploads/");
//  },
//
//  filename: function (req, file, cb) {
//    const uniqueName =
//      Date.now() + path.extname(file.originalname);
//
//    cb(null, uniqueName);
//  },
//});
//
//const upload = multer({ storage });

//////////////////////// SERVER ////////////////////////

//const PORT = process.env.PORT || 5000;
//
//app.listen(PORT, () => {
//  console.log(`🚀 Server running on port ${PORT}`);
//});
//////////////////////// real ////////////////////////

// 3. Static files
// Add these headers specifically for your static folder
app.use('/uploads', cors(), express.static('uploads', {
  setHeaders: (res) => {
    res.set('Access-Control-Allow-Origin', '*');
  }
}));


// 4. Ngrok & Header fix
app.use((req, res, next) => {
  res.setHeader("ngrok-skip-browser-warning", "true");
  // Handle pre-flight (OPTIONS) requests immediately
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

const SECRET_KEY = process.env.JWT_SECRET;

const twilioClient = twilio(
process.env.TWILIO_SID,
 process.env.TWILIO_AUTH_TOKEN
 );
 const { OAuth2Client } = require('google-auth-library');
 console.log("GOOGLE_CLIENT_ID:", process.env.GOOGLE_CLIENT_ID);
 const googleClient = new OAuth2Client(
   process.env.GOOGLE_CLIENT_ID
 );
const Razorpay = require('razorpay');
const crypto = require('crypto');
const razorpay = new Razorpay({
  key_id: 'rzp_test_SEMaMT8TVnP5xL',
  key_secret: 'TnoWZHt1sfcOIEHSow53rKMU'
});


const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "uploads/");
  },
  filename: function (req, file, cb) {
    const uniqueName = Date.now() + path.extname(file.originalname);
    cb(null, uniqueName);
  },
});

const upload = multer({ storage: storage });

/////////////////////////////middleware////////////////////////////////
//function authMiddleware(req, res, next) {
//  const authHeader = req.headers.authorization;
//  console.log("🔐 AUTH HEADER:", authHeader);
//
//  if (!authHeader) {
//    console.log("❌ NO AUTH HEADER");
//    return res.status(401).json({ message: "No token provided" });
//  }
//
//  const token = authHeader.split(" ")[1];
//console.log("EXTRACTED TOKEN:", token);
//  try {
//    const decoded = jwt.verify(token, SECRET_KEY);
//    req.userId = decoded.id;
//    console.log("✅ USER ID:", req.userId);
//     req.user = decoded;
//       console.log(`✅ Auth Success: User ${req.userId} with role ${req.user.role}`);
//    next();
//  } catch (err) {
//    console.log("❌ JWT ERROR:", err.message);
//    return res.status(401).json({ message: "Invalid token" });
//  }
//}
//module.exports = { authMiddleware };
//app.get('/test', (req, res) => res.send("Server is alive"));

// ----------------RAZORPAY ----------------

app.post('/verify', (req, res) => {
  const { razorpay_payment_id, razorpay_order_id, razorpay_signature } = req.body;

  const generated_signature = crypto
    .createHmac('sha256', razorpay.key_secret)
    .update(razorpay_order_id + "|" + razorpay_payment_id)
    .digest('hex');

  if (generated_signature === razorpay_signature) {
    res.send({ success: true });
  } else {
    res.status(400).send({ success: false });
  }
});

// ---------------- GET ADDRESSES ----------------
app.get('/addresses', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;

    const [rows] = await db.query(
      'SELECT * FROM addresses WHERE user_id = ?',
      [userId]
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json([]);
  }
});


// ---------------- POST ADD ADDRESS ----------------
app.post('/addresses', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId; // 🔥 from JWT

    const {
      name,
      phone,
      house,
      road,
      city,
      state,
      country,
      pincode,
      landmark,
      isDefault
    } = req.body;

    // If default → unset previous defaults of this user
       if (isDefault === 1) {
         await db.query(
           'UPDATE addresses SET isDefault = 0 WHERE user_id = ?',
           [userId]
         );
       }

    const [result] = await db.query(
      `INSERT INTO addresses
       (user_id, name, phone, house, road, city, state, country, pincode, landmark, isDefault)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        name,
        phone,
        house,
        road,
        city,
        state,
        country,
        pincode,
        landmark,
        isDefault ? 1 : 0
      ]
    );

    const [rows] = await db.query(
      'SELECT * FROM addresses WHERE id = ?',
      [result.insertId]
    );

    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to add address' });
  }
});

// ---------------- PUT UPDATE ADDRESS1 ----------------
app.put('/addresses/:id', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const addressId = req.params.id;

    const {
      name,
      phone,
      house,
      road,
      city,
      state,
      country,
      pincode,
      landmark,
      isDefault
    } = req.body;

       if (isDefault === 1) {
         await db.query(
           'UPDATE addresses SET isDefault = 0 WHERE user_id = ?',
           [userId]
         );
       }

    await db.query(
      `UPDATE addresses
       SET name=?, phone=?, house=?, road=?, city=?, state=?,
           country=?, pincode=?, landmark=?, isDefault=?
       WHERE id=? AND user_id=?`,
      [
        name,
        phone,
        house,
        road,
        city,
        state,
        country,
        pincode,
        landmark,
        isDefault ? 1 : 0,
        addressId,
        userId
      ]
    );

    const [rows] = await db.query(
      'SELECT * FROM addresses WHERE id = ? AND user_id = ?',
      [addressId, userId]
    );

    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to update address' });
  }
});

// ---------------- DELETE ADDRESSES ----------------

app.delete('/addresses/:id', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const addressId = req.params.id;

    const [result] = await db.query(
      'DELETE FROM addresses WHERE id = ? AND user_id = ?',
      [addressId, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Address not found or not yours' });
    }

    res.status(200).json({ message: 'Address deleted successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});



/* =======================
   EMAIL + PASSWORD
======================= */

// Register

// FIXED REGISTRATION ENDPOINT
app.post('/auth/register', async (req, res) => {
  try {
    const { email, password, role } = req.body;  // receive role from request

    const [existing] = await db.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (existing.length > 0) {
      return res.status(400).json({ message: "User already exists" });
    }

    const hashed = await bcrypt.hash(password, 10);

    // Insert email, password, and role
    const [result] = await db.query(
      'INSERT INTO users (email, password, role) VALUES (?, ?, ?)',
      [email, hashed, role || 'user'] // default to 'user' if role not provided
    );

    const userId = result.insertId;

    // create JWT including role
    const token = jwt.sign(
      { id: userId, email: email, role: role || 'user' },
      SECRET_KEY,
      { expiresIn: "7d" }
    );

    res.json({ token });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Server error" });
  }
});

app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    console.log("📩 Login attempt for:", email);

    // 1. Fetch user from database
    const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);

    if (rows.length === 0) {
      console.log("❌ User not found in DB:", email);
      return res.status(400).json({ message: "User not found" });
    }

    // 🔥 FIX: rows is an array, get the first object
    const user = rows[0];

    // 2. Verify Password
    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      console.log("❌ Password mismatch for:", email);
      return res.status(400).json({ message: "Invalid password" });
    }

    // 3. Generate JWT Token
    const token = jwt.sign(
      { id: user.id, role: user.role, email: user.email },
      SECRET_KEY,
      { expiresIn: '30d' }
    );

    console.log("✅ Login successful:", email, "Role:", user.role);

    // 4. Return unified response for both apps
    res.json({
      token,
      user: {
        id: user.id,
        name: user.name || "User",
        email: user.email,
        role: user.role,
        avatar: user.avatar || "",
        hasShop: user.has_shop === 1 || user.has_shop === true,
        kycStatus: user.kyc_status || 'not_submitted'
      }
    });

  } catch (e) {
    console.error("🔥 Server Error:", e);
    res.status(500).json({ message: "Server error" });
  }
});




/* =======================
   PHONE OTP
======================= */

// SEND OTP
app.post('/auth/otp-send', async (req, res) => {
  try {
    let { phone } = req.body;
    if (!phone) return res.status(400).json({ message: "Phone required" });

    if (!phone.startsWith('+')) phone = '+91' + phone;

    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    const now = new Date(); // current UTC time
    const otpExpire = new Date(now.getTime() + 5 * 60 * 1000); // 5 minutes later

    // Convert to MySQL DATETIME format (YYYY-MM-DD HH:MM:SS)
    const nowMySQL = now.toISOString().slice(0, 19).replace('T', ' ');
    const expireMySQL = otpExpire.toISOString().slice(0, 19).replace('T', ' ');

    await db.query(
      `INSERT INTO phone_otps (phone, otp, created_at, expires_at)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
       otp = VALUES(otp),
       expires_at = VALUES(expires_at),
       created_at = VALUES(created_at)`,
      [phone, otp, nowMySQL, expireMySQL]
    );
    await twilioClient.messages.create({
      body: `Your OTP is ${otp}. It will expire in 5 minutes.`,
      from: process.env.TWILIO_PHONE,
      to: phone,
    });

    console.log('OTP SENT:', phone, otp);
    res.json({ message: "OTP sent successfully" });
  } catch (err) {
    console.error("OTP SEND ERROR:", err);
    res.status(500).json({ message: "OTP send failed" });
  }
});

// VERIFY OTP
app.post('/auth/otp-verify', async (req, res) => {
  try {
    let { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ message: "Phone and OTP required" });
    }

    if (!phone.startsWith('+')) phone = '+91' + phone;

    const nowMySQL = new Date().toISOString().slice(0, 19).replace('T', ' ');

    // 1️⃣ Validate OTP
    const [rows] = await db.query(
      `SELECT * FROM phone_otps
       WHERE phone = ? AND otp = ? AND expires_at > ?`,
      [phone, otp, nowMySQL]
    );

    if (rows.length === 0) {
      return res.status(400).json({ message: "Invalid or expired OTP" });
    }

    // 2️⃣ Delete OTP
    await db.query('DELETE FROM phone_otps WHERE phone = ?', [phone]);

    // 3️⃣ Find or create user
    const [users] = await db.query(
      'SELECT id FROM users WHERE phone = ?',
      [phone]
    );

    let userId;

    if (users.length === 0) {
      const hashed = await bcrypt.hash(
        Math.random().toString(36),
        10
      );

      const result = await db.query(
        'INSERT INTO users (phone, password) VALUES (?, ?)',
        [phone, hashed]
      );

      userId = result[0].insertId;
    } else {
      userId = users[0].id;
    }

    // 4️⃣ Create JWT
    const token = jwt.sign(
      { id: userId },
      SECRET_KEY,
      { expiresIn: '1h' }
    );

    // 5️⃣ Send response
    res.json({
      message: "OTP verified successfully",
      token
    });

  } catch (err) {
    console.error("OTP VERIFY ERROR:", err);
    res.status(500).json({ message: "OTP verify failed" });
  }
});


//JUST TRY//
app.post('/auth/google-login', async (req, res) => {
  try {
    const { idToken } = req.body;
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { email, name, picture, sub: googleId } = payload;

    // 1. Find or create user
    let [users] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    let user;

    if (users.length === 0) {
      const [result] = await db.query(
        'INSERT INTO users (email, name, avatar, google_id, role) VALUES (?, ?, ?, ?, ?)',
        [email, name, picture, googleId, 'user']
      );
      const [newUser] = await db.query('SELECT * FROM users WHERE id = ?', [result.insertId]);
      user = newUser[0];
    } else {
      user = users[0];
    }

    // 2. Generate Token with Role (Crucial for Flutter)
    const token = jwt.sign(
      { id: user.id, role: user.role || 'user', email: user.email },
      SECRET_KEY,
      { expiresIn: '30d' }
    );

    // 3. Return combined response
    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        hasShop: user.has_shop === 1,
        kycStatus: user.kyc_status
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Google login failed" });
  }
});



/* CATEGORY APIs */

// 🔹 GET all categories
app.get("/categories", async (req, res) => {
  try {

    const [rows] = await db.query(
      `
      SELECT
        id,
        name,
        icon_url,
        priority,
        home_status
      FROM categories
      WHERE home_status = 1
      ORDER BY priority ASC
      `
    );

    res.json(rows);

  } catch (error) {

    console.error(error);

    res.status(500).json({
      message: "Server error",
    });
  }
});
// 🔹 GET sub-categories by category
app.get("/categories/:id/subcategories", async (req, res) => {
  try {
    const categoryId = req.params.id;

    const [rows] = await db.query(
      "SELECT id, category_id, name, icon_url FROM sub_categories WHERE category_id = ?",
      [categoryId]
    );

    res.json(rows); // ✅ MUST be inside try
  } catch (error) {
    console.error("Subcategory error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

app.get('/products', async (req, res) => {
  try {

    let query = `
      SELECT * FROM products
      WHERE request_status = 'approved'
      AND is_active = 1
    `;

    const params = [];

    // Optional subcategory filter
    if (req.query.subCategoryId) {

      query += ' AND sub_category_id = ?';

      params.push(req.query.subCategoryId);
    }

    const [products] = await db.query(query, params);

    res.json(products);

  } catch (err) {

    console.error(err);

    res.status(500).json({
      message: 'Server error',
    });
  }
});


// 🔹 GET categories with subcategories and products
app.get("/categories-with-products", async (req, res) => {
  try {
    // 1. Fetch all categories
    const [categories] = await db.query("SELECT * FROM categories");

    // 2. Fetch subcategories and products for each category
    const result = await Promise.all(
      categories.map(async (category) => {
        // Subcategories for this category
        const [subcategories] = await db.query(
          "SELECT * FROM sub_categories WHERE category_id = ?",
          [category.id]
        );

        // Products for each subcategory
        const subWithProducts = await Promise.all(
          subcategories.map(async (sub) => {
          const [products] = await db.query(
            `
            SELECT
              id,
              name,
              description,
              CAST(price AS UNSIGNED) AS price,
              CAST(mrp AS UNSIGNED) AS mrp,
              image_url
            FROM products
            WHERE sub_category_id = ?
            AND request_status = 'approved'
            AND is_active = 1
            `,
            [sub.id]
          );

            return { ...sub, products };
          })
        );

        return { ...category, subcategories: subWithProducts };
      })
    );

    res.json(result);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});

app.get('/flash_deals/:type', async (req, res) => {
  const saleType = req.params.type;

  try {
    const [rows] = await db.query(
      `
      SELECT
        p.id,
        p.name,
        p.price AS original_price,
        p.mrp,
        p.image_url,

        f.flash_price,
        f.flash_percentage,
        f.start_time,
        f.end_time,
        f.sale_type,
        f.status

      FROM flash_deals f

      JOIN products p
        ON f.product_id = p.id

      WHERE f.status = 'active'
        AND f.sale_type = ?
        AND f.start_time <= NOW()
        AND f.end_time >= NOW()

        -- ONLY APPROVED + ACTIVE PRODUCTS
        AND p.request_status = 'approved'
        AND p.is_active = 1
      `,
      [saleType]
    );

    res.json(rows);

  } catch (error) {
    console.error(error);
    res.status(500).json({
      error: 'Server error',
    });
  }
});



// POST: /api/merchant/store-flash-deals
app.post('/merchant/flash-deals', authMiddleware, async (req, res) => {
  const { sale_type, start_time, end_time, products } = req.body;

  const merchantId = req.userId;

  if (!products || products.length === 0) {
    return res.status(400).json({ message: "No products selected" });
  }

  try {
    const productIds = products.map(p => p.product_id);

    // 1. Fetch products from DB
    const [dbProducts] = await db.query(
      `
      SELECT id, merchant_id, request_status, is_active
      FROM products
      WHERE id IN (?)
      `,
      [productIds]
    );

    // 2. Check ownership
    const notOwned = dbProducts.filter(p => p.merchant_id !== merchantId);

    if (notOwned.length > 0) {
      return res.status(403).json({
        message: "You can only use your own products",
        invalid_products: notOwned.map(p => p.id)
      });
    }

    // 3. Check approval + active status
    const invalid = dbProducts.filter(p =>
      p.request_status !== 'approved' || p.is_active !== 1
    );

    if (invalid.length > 0) {
      return res.status(400).json({
        message: "Some products are not approved or inactive",
        invalid_products: invalid.map(p => p.id)
      });
    }

    // 4. Prepare insert values
    const values = products.map(p => [
      p.product_id,
      p.flash_price,
      p.flash_percentage,
      start_time,
      end_time,
      p.status || 'active',
      sale_type
    ]);

    // 5. Insert / Upsert
    const sql = `
      INSERT INTO flash_deals
      (product_id, flash_price, flash_percentage, start_time, end_time, status, sale_type)
      VALUES ?
      ON DUPLICATE KEY UPDATE
        flash_price = VALUES(flash_price),
        flash_percentage = VALUES(flash_percentage),
        status = VALUES(status),
        start_time = VALUES(start_time),
        end_time = VALUES(end_time)
    `;

    await db.query(sql, [values]);

    res.status(200).json({
      message: "Flash deals saved successfully"
    });

  } catch (error) {
    console.error("Flash Deal Error:", error);
    res.status(500).json({
      message: "Internal server error"
    });
  }
});


app.get("/banners", async (req, res) => {
  try {
    const [rows] = await db.query("SELECT * FROM banners ORDER BY created_at DESC");
    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Failed to fetch banners" });
  }
});

app.get('/products/search', async (req, res) => {
  try {
    const q = req.query.q;

    if (!q || q.trim() === '') {
      return res.json([]);
    }

    const [products] = await db.query(
      `
      SELECT *
      FROM products
      WHERE name LIKE ?
         OR description LIKE ?
      `,
      [`%${q}%`, `%${q}%`]
    );

    res.json(products);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Search failed' });
  }
});

//Profile user//
app.get('/me', authMiddleware, async (req, res) => {
  try {
    const [rows] = await db.query(
      `
      SELECT
        id,
        COALESCE(name, email, phone, 'User') AS name,
        phone,
        email,
        avatar,
        role
      FROM users
      WHERE id = ?
      `,
      [req.userId]
    );

    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ message: "Failed to fetch user" });
  }
});

// UPDATE user profile
app.put('/me', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { name, email, phone } = req.body;

    await db.query(
      `UPDATE users SET name = ?, email = ?, phone = ? WHERE id = ?`,
      [name, email, phone, userId]
    );

    const [rows] = await db.query(
      `SELECT id, name, email, phone, avatar, role FROM users WHERE id = ?`,
      [userId]
    );

    res.json(rows[0]);
  } catch (err) {
    console.error("UPDATE USER ERROR:", err);
    res.status(500).json({ message: 'Failed to update profile' });
  }
});

// ---------------- CREATE ORDER ----------------
// CREATE ORDER
//app.post('/orders', authMiddleware, async (req, res) => {
//  try {
//    const order = req.body;
//
//    // Get merchant id from first product
//    const [product] = await db.query(
//      `SELECT merchant_id FROM products WHERE id = ?`,
//      [order.items[0].productId]
//    );
//
//    const merchantId = product[0].merchant_id;
//
//    await db.query(
//      `INSERT INTO orders
//      (order_id, user_id, merchant_id, total_amount, status, address, payment_method, payment_status, refund_status)
//      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
//      [
//        order.orderId,
//        req.userId,
//        merchantId,
//        order.totalAmount,
//        order.status.toUpperCase(),
//        order.address,
//        order.paymentMethod,
//        order.paymentStatus,
//        order.refundStatus || "NONE",
//      ]
//    );
//
//    for (let item of order.items) {
//      await db.query(
//        `INSERT INTO order_items
//        (order_id, product_id, name, image_url, price, quantity)
//        VALUES (?, ?, ?, ?, ?, ?)`,
//        [
//          order.orderId,
//          item.productId,
//          item.name,
//          item.imageUrl,
//          item.price,
//          item.quantity,
//        ]
//      );
//    }
//
//    res.status(201).json({ message: "Order created" });
//
//  } catch (e) {
//    console.error(e);
//    res.status(500).json({ message: "Order creation failed" });
//  }
//});


// GET ORDERS
app.get('/orders', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;

    console.log("📦 Fetching orders for user:", userId);

    const [orders] = await db.query(
      `SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC`,
      [userId]
    );

    for (let order of orders) {
      const [items] = await db.query(
        `SELECT product_id, name, image_url, price, quantity
         FROM order_items
         WHERE order_id = ?`,
        [order.order_id]
      );

      order.items = items || [];

      order.orderId = order.order_id;
      order.totalAmount = Number(order.total_amount);
      order.paymentMethod = order.payment_method;
      order.paymentStatus = order.payment_status;
      order.refundStatus = order.refund_status;
      order.date = order.created_at;
    }

    res.json(orders);
  } catch (error) {
    console.error("❌ FETCH ORDERS ERROR:", error);
    res.status(500).json({ message: "Failed to fetch orders" });
  }
});


// REQUEST REFUND
//app.post('/orders/:id/refund', authMiddleware, async (req, res) => {
//  try {
//    const orderIdString = req.params.id;
//    const { reason, productId } = req.body;
//
//    console.log("--- REFUND REQUEST START ---");
//    console.log("Order ID String:", orderIdString);
//    console.log("Product ID:", productId); // If this is undefined, Flutter isn't sending it
//
//    // 1. Fetch Order
//    const [orders] = await db.query("SELECT id, merchant_id FROM orders WHERE order_id = ?", [orderIdString]);
//    if (orders.length === 0) {
//        console.log("❌ Order not found in DB");
//        return res.status(404).json({ message: "Order not found" });
//    }
//    const order = orders[0];
//    console.log("✅ Found Numeric Order ID:", order.id);
//
//    // 2. Fetch Item Price
//    // Note: Cast productId to ensure it's a number
//    const [items] = await db.query(
//      "SELECT price FROM order_items WHERE order_id = ? AND product_id = ?",
//      [orderIdString, productId]
//    );
//
//    if (items.length === 0) {
//        console.log("❌ Item not found in order_items table for this order");
//        return res.status(404).json({ message: "Item not found" });
//    }
//    const itemPrice = items[0].price;
//    console.log("✅ Found Item Price:", itemPrice);
//
//    // 3. Insert Refund Request
//    const insertSql = `
//      INSERT INTO refund_requests
//      (order_id, product_id, merchant_id, amount, reason, status, created_at, updated_at)
//      VALUES (?, ?, ?, ?, ?, 'pending', NOW(), NOW())`;
//
//    await db.query(insertSql, [order.id, productId, order.merchant_id, itemPrice, reason || ""]);
//    console.log("✅ Refund Request Row Inserted");
//
//    // 4. Update Order Table
//    const updateResult = await db.query(
//      "UPDATE orders SET refund_status = 'REQUESTED' WHERE id = ?",
//      [order.id]
//    );
//    console.log("✅ Order Status Updated to REQUESTED");
//
//    res.json({ success: true, message: "Refund updated" });
//
//  } catch (err) {
//    console.error("🔥 CRITICAL SERVER ERROR:", err);
//    res.status(500).json({ message: "Refund failed", error: err.message });
//  }
//});


app.post('/orders/:id/refund', authMiddleware, async (req, res) => {

  try {

    const orderIdString = req.params.id;
    const { reason, productId } = req.body;

    console.log("--- REFUND REQUEST START ---");

    // 1️⃣ Fetch Order
    const [orders] = await db.query(
      "SELECT id, merchant_id FROM orders WHERE order_id = ?",
      [orderIdString]
    );

    if (orders.length === 0) {

      return res.status(404).json({
        message: "Order not found"
      });
    }

    const order = orders[0];

    // 2️⃣ Fetch Item Price
    const [items] = await db.query(
      `
      SELECT price
      FROM order_items
      WHERE order_id = ?
      AND product_id = ?
      `,
      [orderIdString, productId]
    );

    if (items.length === 0) {

      return res.status(404).json({
        message: "Item not found"
      });
    }

    const itemPrice = items[0].price;

    // 3️⃣ Insert Refund Request
    const insertSql = `
      INSERT INTO refund_requests
      (
        order_id,
        product_id,
        merchant_id,
        amount,
        reason,
        status,
        created_at,
        updated_at
      )
      VALUES
      (?, ?, ?, ?, ?, 'pending', NOW(), NOW())
    `;

    await db.query(
      insertSql,
      [
        order.id,
        productId,
        order.merchant_id,
        itemPrice,
        reason || ""
      ]
    );

    console.log("✅ Refund Request Row Inserted");

    // 4️⃣ Update Order Status
    await db.query(
      `
      UPDATE orders
      SET refund_status = 'REQUESTED'
      WHERE id = ?
      `,
      [order.id]
    );

    console.log("✅ Order Status Updated");

    // 5️⃣ EMIT MERCHANT NOTIFICATION EVENT
    eventEmitter.emit("REFUND_REQUESTED", {

      orderId: orderIdString

    });

    console.log("📢 REFUND_REQUESTED EVENT EMITTED");

    // 6️⃣ RESPONSE
    res.json({
      success: true,
      message: "Refund updated"
    });

  } catch (err) {

    console.error("🔥 CRITICAL SERVER ERROR:", err);

    res.status(500).json({
      message: "Refund failed",
      error: err.message
    });
  }
});


// ---------------- WISHLIST ----------------
app.get('/wishlist', authMiddleware, async (req, res) => {
  try {
    console.log("📥 WISHLIST USER:", req.userId);

    const [rows] = await db.query(
      `SELECT
  p.id AS id,
        p.name,
        p.description,
        p.price,
        p.mrp,
        p.image_url
       FROM wishlist w
       JOIN products p ON w.product_id = p.id
       WHERE w.user_id = ?
       ORDER BY w.created_at DESC`,
      [req.userId]
    );
    console.log("📦 WISHLIST ROWS:", rows.length);
    res.json(rows);
  } catch (err) {
    console.error("❌ FETCH WISHLIST ERROR:", err);
    res.status(500).json({ message: err.message });
  }
});
app.post('/wishlist', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { productId } = req.body;

    if (!productId) return res.status(400).json({ message: "Product ID required" });

    // Insert or ignore if already exists
    await db.query(
      `INSERT IGNORE INTO wishlist (user_id, product_id)
       VALUES (?, ?)`,
      [userId, productId]
    );

    res.status(201).json({ message: "Added to wishlist" });
  } catch (err) {
    console.error("❌ ADD WISHLIST ERROR:", err);
    res.status(500).json({ message: "Failed to add to wishlist" });
  }
});

app.delete('/wishlist/:productId', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
        const productId = req.params.productId;

    const [result] = await db.query(
      `DELETE FROM wishlist WHERE user_id = ? AND product_id = ?`,
      [userId, productId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Product not found in wishlist" });
    }

    res.json({ message: "Removed from wishlist" });
  } catch (err) {
    console.error("❌ REMOVE WISHLIST ERROR:", err);
    res.status(500).json({ message: "Failed to remove from wishlist" });
  }
});

// ----------------- CART ROUTES -----------------

// GET cart items
app.get('/cart', authMiddleware, async (req, res) => {
  try {
    const [cartItems] = await db.query(
      `SELECT c.quantity, p.id AS product_id, p.name,
       p.price, p.mrp, p.image_url
       FROM cart c JOIN products p ON c.product_id = p.id
       WHERE c.user_id = ?`,
      [req.userId]
    );

    // Convert strings to numbers in JS before sending to Flutter
    const formattedItems = cartItems.map(item => ({
      ...item,
      price: parseFloat(item.price),
      mrp: parseFloat(item.mrp)
    }));

    res.json(formattedItems);
  } catch (err) {
    res.status(500).json({ error: "Database error" });
  }
});


// ADD to cart
app.post('/cart', authMiddleware, async (req, res) => {
  try {
    const { product_id, quantity } = req.body;

    // 1. Check if item exists
    const [existing] = await db.query(
      `SELECT id FROM cart WHERE user_id=? AND product_id=?`,
      [req.userId, product_id]
    );

    if (existing.length > 0) {
      // ✅ FIX: Access the ID from the first object in the array: existing[0].id
      await db.query(
        `UPDATE cart SET quantity = quantity + ? WHERE id = ?`,
        [quantity, existing[0].id]
      );
    } else {
      // 2. Insert new row
      await db.query(
        `INSERT INTO cart (user_id, product_id, quantity) VALUES (?, ?, ?)`,
        [req.userId, product_id, quantity]
      );
    }
    res.json({ message: 'Added to cart' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal Server Error" });
  }
});


// ---------------- UPDATE Cart Quantity (Increase/Decrease) ----------------
app.put('/cart/update', authMiddleware, async (req, res) => {
  try {
    const { product_id, change } = req.body; // change will be 1 or -1

    // Update quantity but don't let it go below 1
    const [result] = await db.query(
      `UPDATE cart SET quantity = GREATEST(1, quantity + ?)
       WHERE user_id = ? AND product_id = ?`,
      [change, req.userId, product_id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Item not found in cart" });
    }

    res.json({ message: "Quantity updated" });
  } catch (err) {
    console.error("UPDATE ERROR:", err);
    res.status(500).json({ error: "Server error" });
  }
});

// ---------------- DELETE Item from Cart ----------------
app.delete('/cart/:product_id', authMiddleware, async (req, res) => {
  try {
    await db.query(
      "DELETE FROM cart WHERE user_id = ? AND product_id = ?",
      [req.userId, req.params.product_id]
    );
    res.json({ message: "Item removed" });
  } catch (err) {
    res.status(500).json({ error: "Server error" });
  }
});

// ==========================================
// GET USER NOTIFICATIONS
// ==========================================
app.get("/user/notifications", authMiddleware, async (req, res) => {
  try {

    const userId = req.user.id;

    const [rows] = await db.query(
      `
      SELECT
        id,
        title,
        body,
        type,
        image_url,
        is_read,
        created_at
      FROM user_notifications
      WHERE user_id = ?
      ORDER BY created_at DESC
      `,
      [userId]
    );

    res.json({
      success: true,
      data: rows,
    });

  } catch (err) {

    console.error("FETCH USER NOTIFICATIONS ERROR:", err);

    res.status(500).json({
      success: false,
      message: "Failed to fetch notifications",
    });
  }
});

// ==========================================
// MARK NOTIFICATIONS AS READ
// ==========================================
app.put("/user/notifications/read", authMiddleware, async (req, res) => {
  try {

    const userId = req.user.id;

    await db.query(
      `
      UPDATE user_notifications
      SET is_read = 1
      WHERE user_id = ?
      `,
      [userId]
    );

    res.json({
      success: true,
      message: "Notifications marked as read",
    });

  } catch (err) {

    console.error("MARK READ ERROR:", err);

    res.status(500).json({
      success: false,
      message: "Failed to mark notifications",
    });
  }
});

// ==========================================
// DELETE SINGLE NOTIFICATION
// ==========================================
app.delete(
  "/user/notifications/:id",
  authMiddleware,
  async (req, res) => {

    try {

      const userId = req.user.id;
      const notificationId = req.params.id;

      await db.query(
        `
        DELETE FROM user_notifications
        WHERE id = ?
        AND user_id = ?
        `,
        [notificationId, userId]
      );

      res.json({
        success: true,
        message: "Notification deleted",
      });

    } catch (err) {

      console.error("DELETE NOTIFICATION ERROR:", err);

      res.status(500).json({
        success: false,
        message: "Failed to delete notification",
      });
    }
  }
);
// ==========================================
// AUTO DELETE OLD NOTIFICATIONS
// ==========================================
setInterval(async () => {

  try {

    const [result] = await db.query(
      `
      DELETE FROM user_notifications
      WHERE created_at < NOW() - INTERVAL 30 DAY
      `
    );

    console.log(
      `🧹 Old notifications deleted: ${result.affectedRows}`
    );

  } catch (err) {

    console.error("AUTO DELETE ERROR:", err);
  }

}, 1000 * 60 * 60 * 24);
// ---------------- Dashboard ----------------

app.get("/dashboard", authMiddleware, async (req, res) => {
  try {

    const merchantId = req.userId;

    /// TOTAL ORDERS
    const [orders] = await db.query(
"SELECT COUNT(*) as totalOrders FROM orders WHERE merchant_id = ?",
      [merchantId]
    );

    /// TOTAL PRODUCTS
    const [products] = await db.query(
      "SELECT COUNT(*) as totalProducts FROM products WHERE merchant_id = ?",
      [merchantId]
    );

    /// PENDING ORDERS
 const [pending] = await db.query(
   "SELECT COUNT(*) as pendingOrders FROM orders WHERE merchant_id = ? AND status = 'Placed'",
   [merchantId]
 );

    /// REVENUE
    const [revenue] = await db.query(`
      SELECT SUM(oi.price * oi.quantity) as revenue
      FROM order_items oi
      JOIN products p ON p.id = oi.product_id
      WHERE p.merchant_id = ?
    `,[merchantId]);

    res.json({
      totalOrders: orders[0].totalOrders || 0,
      totalProducts: products[0].totalProducts || 0,
      pendingOrders: pending[0].pendingOrders || 0,
      revenue: revenue[0].revenue || 0,
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});
///////////////////Notification Count///////////////////////////////////////////////

app.get("/user/notifications/unread-count", authMiddleware, async (req, res) => {

  try {

    const userId = req.user.id;

    const [rows] = await db.query(
      `
      SELECT COUNT(*) as count
      FROM user_notifications
      WHERE user_id = ?
      AND is_read = 0
      `,
      [userId]
    );

    res.json({
      count: rows[0].count,
    });

  } catch (err) {

    console.log(err);

    res.status(500).json({
      error: "Server error",
    });
  }
});

app.put(
  "/user/notifications/:id/read",
  authMiddleware,
  async (req, res) => {

    try {

      const notificationId = req.params.id;
      const userId = req.user.id;

      await db.query(
        `
        UPDATE user_notifications
        SET is_read = 1
        WHERE id = ?
        AND user_id = ?
        `,
        [notificationId, userId]
      );

      res.json({
        success: true,
      });

    } catch (err) {

      console.log(err);

      res.status(500).json({
        success: false,
      });
    }
  }
);

//  ----------------GET help and support static page content ----------------

app.get("/static-pages/:slug", async (req, res) => {
  try {
    const { slug } = req.params;

    const [rows] = await db.query(
      "SELECT * FROM static_pages WHERE slug = ? LIMIT 1",
      [slug]
    );

    if (!rows.length) {
      return res.status(404).json({
        message: "Page not found",
      });
    }

    res.json(rows[0]);

  } catch (e) {
    console.log(e);

    res.status(500).json({
      message: "Server error",
    });
  }
});

//  ----------------GET PRODUCTS OF LOGGED-IN MERCHANT ----------------
 const checkSubscription = async (req, res, next) => {
      const merchantId = req.userId;

      const [rows] = await db.query(
        `SELECT * FROM merchant_subscriptions
         WHERE merchant_id = ?
         ORDER BY id DESC LIMIT 1`,
        [merchantId]
      );

      if (rows.length === 0) {
        return res.status(403).json({ message: "No subscription found" });
      }

      const sub = rows[0];

      if (sub.status !== 'active' || new Date(sub.end_date) < new Date()) {
        return res.status(403).json({ message: "Subscription expired" });
      }

      next();
    };
    app.get('/merchant/products', authMiddleware,checkSubscription, async (req, res) => {



      try {
        const merchantId = req.userId; // ✅ use the field set in middleware
        if (!merchantId) {
          return res.status(400).json({ message: "Merchant ID missing" });
        }

        const [products] = await db.query(
          "SELECT * FROM products WHERE merchant_id = ?",
          [merchantId]
        );

        res.json(products); // will be [] if no products
      } catch (err) {
        console.error("DB error:", err);
        res.status(500).json({ message: "Server error" });
      }
    });

//  ----------------POST PRODUCTS OF LOGGED-IN MERCHANT ----------------

app.post("/merchant/products", upload.single("image_url"), authMiddleware, async (req, res) => {
  try {
    const { name, sku, stock_quantity, low_stock_threshold,description = "", price, mrp, category_id, sub_category_id } = req.body;

    // merchant_id is attached to req by authMiddleware
    const merchant_id = req.userId;

    if (!merchant_id) {
      return res.status(401).json({ message: "Unauthorized: Merchant ID missing" });
    }

  //  const image = req.file ? `/uploads/${req.file.filename}` : null;
   const image = req.file ? `/uploads/${req.file.filename}` : null;

    const sql = `
      INSERT INTO products
      (name, sku, stock_quantity, low_stock_threshold,description, price, mrp, image_url, category_id, sub_category_id, merchant_id)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?,?,?,?)
    `;

    const [result] = await db.query(sql, [
      name,
      sku,
       stock_quantity,
        low_stock_threshold,
      description,
      price,
      mrp,
      image,
      category_id,
      sub_category_id,
      merchant_id
    ]);

    res.status(201).json({
      message: "Product added successfully",
      product_id: result.insertId,
      image_url: image
    });
  } catch (err) {
    console.error("SQL ERROR:", err);
    res.status(500).json({ error: err.message });
  }
});
//  ----------------DELETE PRODUCTS OF LOGGED-IN MERCHANT ----------------

app.delete('/merchant/products/:id', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const merchant_id= req.params.id;

    const [result] = await db.query(
      'DELETE FROM products WHERE id = ? AND merchant_id = ?',
      [merchant_id, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'products not found ' });
    }

    res.status(200).json({ message:'Product deleted successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

//  ----------------UPDATE PRODUCTS OF LOGGED-IN MERCHANT ----------------


app.put(
  "/merchant/products/:id",
  authMiddleware,
  upload.single("image_url"),
  async (req, res) => {
    try {

      const productId = req.params.id;
      const merchantId = req.userId;

      const {
        name,
        description,
        price,
        mrp,
         stock_quantity,
        low_stock_threshold,
         sku,
        category_id,
        sub_category_id
      } = req.body;

      /// Get existing product
      const [rows] = await db.query(
        "SELECT * FROM products WHERE id=? AND merchant_id=?",
        [productId, merchantId]
      );

      if (rows.length === 0) {
        return res.status(404).json({ message: "Product not found" });
      }

      const oldProduct = rows[0];
      let imageUrl = oldProduct.image_url;

      /// If new image uploaded
      if (req.file) {

imageUrl = `/uploads/${req.file.filename}`;

        /// delete old image
if (oldProduct.image_url) {
  const fileName = oldProduct.image_url.split('/uploads/').pop();

  const oldPath = path.join(__dirname, 'uploads', fileName);

  fs.unlink(oldPath, (err) => {
    if (err) console.log("Old image delete failed:", err);
  });
}
      }

      /// Update product
      await db.query(
        `UPDATE products SET
          name=?,
          description=?,
          price=?,
          mrp=?,
           stock_quantity=?,
           low_stock_threshold=?,
           sku=?,
          category_id=?,
          sub_category_id=?,
          image_url=?
         WHERE id=? AND merchant_id=?`,
        [
          name,
          description,
          price,
          mrp,
           stock_quantity,
            low_stock_threshold,
           sku,
          category_id,
          sub_category_id,
          imageUrl,
          productId,
          merchantId
        ]
      );

      res.json({ message: "Product updated successfully" });

    } catch (error) {

      console.error(error);

      res.status(500).json({
        message: "Update failed",
        error: error.message
      });
    }
  }
);

// Toggle Product Active Status (Vendor only)
app.patch("/merchant/products/:id/toggle-status", authMiddleware, async (req, res) => {
  const productId = req.params.id;
  const { is_active } = req.body; // Expects 1 or 0

  try {
    await db.query(
      "UPDATE products SET is_active = ? WHERE id = ? AND merchant_id = ?",
      [is_active, productId, req.userId]
    );
    res.json({ success: true, message: "Status updated" });
  } catch (err) {
    res.status(500).json({ error: "Failed to toggle status" });
  }
});


app.patch("/merchant/products/:id/stock", authMiddleware, async (req, res) => {
  const { stock_quantity } = req.body;
  const productId = req.params.id;

  try {
    await db.query(
      "UPDATE products SET stock_quantity = ? WHERE id = ? AND merchant_id = ?",
      [stock_quantity, productId, req.userId]
    );
    res.json({ success: true, message: "Stock updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------- GET MERCHANT ORDER ----------------

app.get('/merchant/orders', authMiddleware, async (req, res) => {
  try {
    const merchantId = req.userId; // from token
    console.log("MERCHANT ID FROM TOKEN:", merchantId);

    const [orders] = await db.query(
      `SELECT * FROM orders WHERE merchant_id = ? ORDER BY created_at DESC`,
      [merchantId]
    );

    console.log("ORDERS FOUND:", orders.length); // Should print >0
    res.json(orders);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Failed to fetch merchant orders" });
  }
});

// ---------------- CONFIRM MERCHANT ORDER ----------------

app.post("/merchant/orders/:orderId/confirm", async (req, res) => {
  const { orderId } = req.params;

  await db.query(
    "UPDATE orders SET status='Confirmed' WHERE order_id=?",
    [orderId]
  );

  res.json({ message: "Order confirmed" });
});


// ---------------- SHIP MERCHANT ORDER ----------------
app.post("/merchant/orders/:orderId/shipped", authMiddleware, async (req, res) => {
  const { orderId } = req.params;

  try {

    const [orders] = await db.query(
      "SELECT * FROM orders WHERE order_id = ?",
      [orderId]
    );

    if (orders.length === 0) {
      return res.status(404).json({ message: "Order not found" });
    }

    const order = orders[0];

    // Prevent wrong state change
    if (order.status === "Delivered") {
      return res.status(400).json({ message: "Already delivered" });
    }

    // Update status
    await db.query(
      "UPDATE orders SET status='Shipped' WHERE order_id=?",
      [orderId]
    );

    console.log("🚚 Order marked as SHIPPED");

    // EMIT EVENT
    eventEmitter.emit("ORDER_SHIPPED", {
      userId: order.user_id,
      orderId: order.order_id,
    });

    res.json({
      success: true,
      message: "Order marked as shipped"
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// ---------------- DELIVER MERCHANT ORDER ----------------

app.post("/merchant/orders/:orderId/delivered", authMiddleware, async (req, res) => {
  const connection = await db.getConnection();

  try {
    const { orderId } = req.params;

    await connection.beginTransaction();

    // 1️⃣ Fetch order
const [orders] = await connection.query(
  `SELECT id, user_id, total_amount, merchant_id, is_paid
   FROM orders
   WHERE order_id = ? FOR UPDATE`,
  [orderId]
);
    if (orders.length === 0) {
      await connection.rollback();
      return res.status(404).json({ message: "Order not found" });
    }

    const order = orders[0];

    if (order.is_paid === 1) {
      await connection.rollback();
      return res.status(400).json({ message: "Already processed" });
    }

    // 2️⃣ Get commission rate
    const [shop] = await connection.query(
      "SELECT commission_rate FROM merchant_shops WHERE merchant_id = ?",
      [order.merchant_id]
    );

    const commissionRate = Number(shop[0]?.commission_rate || 0);

    const commissionAmount =
      (order.total_amount * commissionRate) / 100;

    const merchantEarning =
      order.total_amount - commissionAmount;

    // 3️⃣ Update order
    await connection.query(
      "UPDATE orders SET status='Delivered', is_paid=1 WHERE order_id=?",
      [orderId]
    );

    // 4️⃣ Ensure wallet exists
    await connection.query(
      "INSERT IGNORE INTO merchant_wallet (merchant_id, balance) VALUES (?, 0)",
      [order.merchant_id]
    );

    // 5️⃣ CREDIT ONLY NET AMOUNT (IMPORTANT FIX)
    await connection.query(
      `UPDATE merchant_wallet
       SET balance = balance + ?
       WHERE merchant_id = ?`,
      [merchantEarning, order.merchant_id]
    );

    // 6️⃣ Wallet transaction log
    await connection.query(
      `INSERT INTO merchant_wallet_transactions
      (merchant_id, order_id, amount, type, description)
      VALUES (?, ?, ?, 'credit', ?)`,
      [
        order.merchant_id,
        order.id,
        merchantEarning,
        `Order #${orderId} | Earned ₹${merchantEarning} (Commission ₹${commissionAmount})`
      ]
    );

    await connection.commit();

eventEmitter.emit("PAYMENT_RECEIVED", {
  orderId: orderId
});

    eventEmitter.emit("ORDER_DELIVERED", {
      userId: order.user_id,
      orderId: order.order_id,
    });

    res.json({
      success: true,
      message: "Order delivered and commission applied",
      merchantEarning,
      commissionAmount
    });


  } catch (err) {
    await connection.rollback();
    console.error(err);
    res.status(500).json({ message: "System error" });

  } finally {
    connection.release();
  }
});
// ---------------- CANCEL MERCHANT ORDER ----------------

app.post("/merchant/orders/:orderId/cancel", async (req, res) => {
  const { orderId } = req.params;

  try {
    // 1️⃣ Fetch order first
    const [orders] = await db.query(
      `SELECT id, user_id, order_id, status
       FROM orders
       WHERE order_id = ?`,
      [orderId]
    );

    if (orders.length === 0) {
      return res.status(404).json({ message: "Order not found" });
    }

    const order = orders[0];

    // 2️⃣ Optional: prevent double cancel
    if (order.status === "Canceled") {
      return res.status(400).json({ message: "Already canceled" });
    }

    // 3️⃣ Update status
    await db.query(
      "UPDATE orders SET status='Canceled' WHERE order_id=?",
      [orderId]
    );

    // 4️⃣ Emit event (NOW correct)
    eventEmitter.emit("ORDER_CANCELED", {
      userId: order.user_id,
      orderId: order.order_id,
    });

    return res.json({ message: "Order canceled" });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
});
// ---------------- RETURN MERCHANT ORDER ----------------

app.post("/merchant/orders/:orderId/return", authMiddleware, async (req, res) => {
  const { orderId } = req.params;
  const { reason, amount } = req.body;

  try {
    const [orders] = await db.query("SELECT * FROM orders WHERE order_id=?", [orderId]);
    if (orders.length === 0) return res.status(404).json({ message: "Order not found" });

    const order = orders[0];

    // 1. Update order status to 'returned'
    await db.query("UPDATE orders SET status='returned' WHERE order_id=?", [orderId]);

    // 2. Insert refund request with status 'approved' (so it skips 'pending' tab)
    const [result] = await db.query(
      `INSERT INTO refund_requests (order_id, product_id, merchant_id, amount, reason, status)
       VALUES (?, NULL, ?, ?, ?, 'approved')`, // 🔥 Changed 'pending' to 'approved'
      [order.id, order.merchant_id, amount || order.total_amount, reason || ""]
    );
eventEmitter.emit("ORDER_RETURNED", {
  userId: order.user_id,
  orderId: order.order_id,
});

    res.json({ message: "Refund request created directly in Approved tab", refundId: result.insertId });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
});

// ---------------- MERCHANT ORDER ITEMS ----------------

app.get("/merchant/orders/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;

    const [orders] = await db.query(
      "SELECT * FROM orders WHERE order_id = ?",
      [orderId]
    );

    if (orders.length === 0) {
      return res.status(404).json({ message: "Order not found" });
    }

    const order = orders[0];

    const [items] = await db.query(
      `SELECT product_id, name, image_url, price, quantity
       FROM order_items
       WHERE order_id = ?`,
      [orderId]
    );

    order.items = items || [];

    res.json(order);

  } catch (error) {
    console.error("MERCHANT ORDER ERROR:", error);
    res.status(500).json({ message: "Failed to fetch order" });
  }
});
// ================== REFUND REQUEST ==================
app.get("/merchant/refunds/:status", authMiddleware, async (req, res) => {
  const status = req.params.status.toLowerCase();
  const merchantId = req.userId;

  try {
    const [rows] = await db.query(`
      SELECT
        r.id AS refund_id,
        r.order_id AS numeric_order_id,
        r.amount,
        r.reason,
        r.status,
        ANY_VALUE(COALESCE(oi.name, 'Unknown Product')) AS product_name,
        ANY_VALUE(COALESCE(oi.image_url, '')) AS image_url,
        ANY_VALUE(COALESCE(oi.quantity, 1)) AS quantity
      FROM refund_requests r
      LEFT JOIN orders o ON r.order_id = o.id
      LEFT JOIN order_items oi ON o.order_id = oi.order_id AND r.product_id = oi.product_id
      WHERE r.merchant_id = ? AND LOWER(r.status) = ?
      GROUP BY r.id
      ORDER BY r.created_at DESC
    `, [merchantId, status]);

    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
});


app.post("/merchant/refunds/:refundId/refunded", authMiddleware, async (req, res) => {
  const { refundId } = req.params;

  try {
    // Update refund request to refunded
    await db.query(
      "UPDATE refund_requests SET status='refunded' WHERE id=?",
      [refundId]
    );

    res.json({ message: "Refund marked as refunded" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// ================== Wallet APIs ==================

app.get("/merchant/wallet/stats", authMiddleware, async (req, res) => {
  const merchantId = req.userId;

  try {
    const query = `
      SELECT
        (SELECT balance FROM merchant_wallet WHERE merchant_id = ?) as balance,
        (SELECT IFNULL(SUM(amount), 0) FROM payout_requests WHERE merchant_id = ? AND status = 'pending') as pending,
        (SELECT IFNULL(SUM(amount), 0) FROM payout_requests WHERE merchant_id = ? AND status = 'approved') as withdrawn,
        (
          SELECT IFNULL(SUM((o.total_amount * ms.commission_rate) / 100), 0)
          FROM orders o
          JOIN merchant_shops ms ON o.merchant_id = ms.merchant_id
          WHERE o.merchant_id = ? AND o.status = 'delivered'
        ) as total_commission
    `;

    const [rows] = await db.query(query, [merchantId, merchantId, merchantId, merchantId]);
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});




// ✅ Get wallet
app.get("/merchant/wallet", authMiddleware, async (req, res) => {
  const merchantId = req.userId;

  const [rows] = await db.query(
    "SELECT balance FROM merchant_wallet WHERE merchant_id = ?",
    [merchantId]
  );

  if (rows.length === 0) {
    await db.query(
      "INSERT INTO merchant_wallet (merchant_id, balance) VALUES (?, 0)",
      [merchantId]
    );
    return res.json({ balance: 0 });
  }

  res.json(rows[0]);
});
// 2️⃣ Request payout

app.post("/merchant/payouts", authMiddleware, async (req, res) => {
  const connection = await db.getConnection();
  const merchantId = req.userId;
  const amount = Number(req.body.amount);

  try {
    if (!amount || amount <= 0) {
      return res.status(400).json({ message: "Invalid amount" });
    }

    await connection.beginTransaction();

    // 1️⃣ Lock wallet
    const [walletRows] = await connection.query(
      "SELECT balance FROM merchant_wallet WHERE merchant_id = ? FOR UPDATE",
      [merchantId]
    );

    if (!walletRows.length) {
      await connection.rollback();
      return res.status(404).json({ message: "Wallet not found" });
    }

    const walletBalance = Number(walletRows[0].balance);

    // 2️⃣ Pending total
    const [pendingRows] = await connection.query(
      `SELECT IFNULL(SUM(amount),0) as pending_total
       FROM payout_requests
       WHERE merchant_id = ? AND status = 'pending'`,
      [merchantId]
    );

    const pendingAmount = Number(pendingRows[0].pending_total);

    // 3️⃣ Available balance
    const availableBalance = walletBalance - pendingAmount;

    if (amount > availableBalance) {
      await connection.rollback();
      return res.status(400).json({
        message: "Insufficient available balance",
        walletBalance,
        pendingAmount,
        availableBalance
      });
    }

    // 4️⃣ CREATE payout request ONLY (NO ledger yet)
    const [result] = await connection.query(
      `INSERT INTO payout_requests
       (merchant_id, amount, status,order_id,    requested_at)
       VALUES (?, ?, 'pending',?, NOW())`,
      [merchantId, amount,order_id]
    );

    await connection.commit();

    res.json({
      success: true,
      message: "Payout request created",
      payout_id: result.insertId,
      availableBalance: availableBalance - amount
    });

  } catch (err) {
    await connection.rollback();
    console.error(err);
    res.status(500).json({ message: "Payout failed" });

  } finally {
    connection.release();
  }
});
// 3️⃣ Get payout history
app.get("/merchant/payouts", authMiddleware, async (req, res) => {
  const merchantId = req.userId;

  try {
    const [rows] = await db.query(
      `SELECT
        id,
        amount,
        status,
        requested_at,
        completed_at
       FROM payout_requests
       WHERE merchant_id = ?
       ORDER BY requested_at DESC`,
      [merchantId]
    );
console.log("📥 PAYOUT HISTORY API HIT");
console.log("USER:", req.userId);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.delete("/merchant/payout/:id", authMiddleware, async (req, res) => {
  const merchantId = req.userId;
  const payoutId = req.params.id;

  try {
    // 1️⃣ Fetch the payout first
    const [rows] = await db.query(
      "SELECT * FROM payout_requests WHERE id = ? AND merchant_id = ?",
      [payoutId, merchantId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "Payout not found" });
    }

    const payout = rows[0];

    // 2️⃣ Only allow pending payouts
    if (payout.status !== "pending") {
      return res.status(400).json({ message: "Only pending payouts can be deleted" });
    }

    console.log("Deleting payout:", payoutId, "for merchant:", merchantId);

    // 3️⃣ Delete
    const [result] = await db.query(
      "DELETE FROM payout_requests WHERE id = ? AND merchant_id = ?",
      [payoutId, merchantId]
    );

    console.log("Rows affected:", result.affectedRows);

    if (result.affectedRows === 0) {
      return res.status(500).json({ message: "Failed to delete payout" });
    }

    res.json({ message: "Deleted successfully" });

  } catch (err) {
    console.error("❌ PAYOUT DELETE ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// Save or update payment method
app.post("/merchant/payment-method", authMiddleware, async (req, res) => {
  const merchantId = req.userId;
  const { type, details } = req.body;

  if (!type || !details) return res.status(400).json({ message: "Missing type or details" });

  try {
    // Insert or update (UPSERT)
    await db.query(
      `INSERT INTO merchant_payment_methods (merchant_id, type, details)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE details = ?`,
      [merchantId, type, JSON.stringify(details), JSON.stringify(details)]
    );

    res.json({ message: "Payment method saved successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Failed to save method" });
  }
});

// Get all saved methods for merchant
app.get("/merchant/payment-methods", authMiddleware, async (req, res) => {
  const merchantId = req.userId;
  try {
    const [rows] = await db.query(
      "SELECT type, details FROM merchant_payment_methods WHERE merchant_id = ?",
      [merchantId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

//  Merchant Coupon //

app.post("/merchant/coupons", authMiddleware, async (req, res) => {
    const {
        title, code, coupon_type, customer, limit_per_user,
        discount_type, discount_amount, min_purchase, start_date, expire_date
    } = req.body;

    const merchant_id = req.userId; // From authMiddleware

    try {
        // Format dates for MySQL (YYYY-MM-DD)
        const formattedStart = start_date.split('-').reverse().join('-');
        const formattedExpire = expire_date.split('-').reverse().join('-');

        const sql = `
            INSERT INTO coupons
            (merchant_id, title, code, coupon_type, customer, limit_per_user,
             discount_type, discount_amount, min_purchase, start_date, expire_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        await db.query(sql, [
            merchant_id, title, code, coupon_type, customer, limit_per_user,
            discount_type, discount_amount, min_purchase, formattedStart, formattedExpire
        ]);

        res.status(201).json({ message: "Coupon created successfully" });
    } catch (err) {
        console.error(err);
        if (err.code === 'ER_DUP_ENTRY') {
            return res.status(400).json({ message: "Coupon code already exists" });
        }
        res.status(500).json({ message: "Internal server error" });
    }
});

// 📋 Fetch all coupons for the logged-in merchant
app.get("/merchant/coupons", authMiddleware, async (req, res) => {
    try {
        const [rows] = await db.query(
            "SELECT * FROM coupons WHERE merchant_id = ? ORDER BY created_at DESC",
            [req.userId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: "Failed to fetch coupons" });
    }
});

// 🔄 Toggle Coupon Status
app.patch("/merchant/coupons/:id/status", authMiddleware, async (req, res) => {
    const { status } = req.body; // Expects 1 or 0
    try {
        await db.query("UPDATE coupons SET status = ? WHERE id = ? AND merchant_id = ?", [status, req.params.id, req.userId]);
        res.json({ message: "Status updated" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 📝 Update Coupon Details
app.put("/merchant/coupons/:id", authMiddleware, async (req, res) => {
    const { title, code, discount_amount, min_purchase, expire_date } = req.body;
    try {
        await db.query(
            "UPDATE coupons SET title=?, code=?, discount_amount=?, min_purchase=?, expire_date=? WHERE id=? AND merchant_id=?",
            [title, code, discount_amount, min_purchase, expire_date, req.params.id, req.userId]
        );
        res.json({ message: "Coupon updated" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 🗑️ Delete Coupon
app.delete("/merchant/coupons/:id", authMiddleware, async (req, res) => {
    try {
        await db.query("DELETE FROM coupons WHERE id = ? AND merchant_id = ?", [req.params.id, req.userId]);
        res.json({ message: "Coupon deleted" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});
// GET merchant profile

app.get('/merchant/me', authMiddleware, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, name, phone, email, avatar, role FROM users WHERE id = ?`,
      [req.userId]
    );

    if (rows.length === 0) return res.status(404).json({ message: "Merchant not found" });

    // Flutter expects an OBJECT, but db.query returns an ARRAY.
    // Send rows[0] to match your Merchant.fromJson() logic.
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ message: "Failed to fetch merchant" });
  }
});


// UPDATE merchant profile
app.put('/merchant/me', authMiddleware, upload.single('avatar'), async (req, res) => {
  try {
    const { name, email, phone } = req.body;
    const userId = req.userId;

    let sql = "UPDATE users SET name = ?, email = ?, phone = ?";
    let params = [name, email, phone];

    if (req.file) {
      // req.file.filename will be the 'uniqueName' from your storage config
    const avatarUrl = "${ApiConfig.baseUrl}/uploads/" + req.file.filename;

      sql += ", avatar = ?";
      params.push(avatarUrl);
    }

    sql += " WHERE id = ?";
    params.push(userId);

    await db.query(sql, params);

    // Fetch fresh data to return to Flutter
    const [rows] = await db.query(
      "SELECT id, name, email, phone, avatar, role FROM users WHERE id = ?",
      [userId]
    );

  res.json(rows[0]);
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Update failed" });
  }
});
// kyc onboarding

app.get('/merchant/status', authMiddleware, async (req, res) => {
  try {
    const merchantId = req.userId;

    const [userDataArray] = await db.query(
      'SELECT name, email, has_shop, kyc_status FROM users WHERE id = ? LIMIT 1',
      [merchantId]
    );

    if (userDataArray.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    const userData = userDataArray[0];

    res.json({
      name: userData.name || "User",
      email: userData.email,
      hasShop: userData.has_shop === 1 || userData.has_shop === true,
      kycStatus: userData.kyc_status,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

 app.post('/merchant/shop', authMiddleware, async (req, res) => {
   try {
     const merchantId = req.userId; // comes from token
     const { name, contact, address } = req.body;

     await db.query(
       `INSERT INTO merchant_shops (merchant_id, name, contact, address)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        name=?, contact=?, address=?`,
       [merchantId, name, contact, address, name, contact, address]
     );

     await db.query(
       "UPDATE users SET has_shop = true WHERE id = ?",
       [merchantId]
     );

     res.json({ message: "Shop saved" });
   } catch (err) {
     console.error(err);
     res.status(500).json({ message: "Server error" });
   }
 });

// ✅ GET Shop Details
app.get('/merchant/shop', authMiddleware, async (req, res) => {
  try {
    const merchantId = req.userId; // Extracted from token by your middleware

    // Query the merchant_shops table
    const [shopData] = await db.query(
      'SELECT name, contact, address FROM merchant_shops WHERE merchant_id = ? LIMIT 1',
      [merchantId]
    );

    if (shopData.length === 0) {
      return res.status(404).json({ message: 'Shop details not found' });
    }

    // Return the first (and only) result
    res.json(shopData[0]);
  } catch (err) {
    console.error("Error fetching shop info:", err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Toggle Shop Live/Offline status
app.patch('/merchant/shop/status', authMiddleware, async (req, res) => {
  try {
    const merchantId = req.userId;
    const { is_active } = req.body; // Expecting true or false

    await db.query(
      'UPDATE merchant_shops SET is_active = ? WHERE merchant_id = ?',
      [is_active ? 1 : 0, merchantId]
    );

    res.json({
      success: true,
      isLive: is_active,
      message: is_active ? "Shop is now visible to customers" : "Shop is now hidden"
    });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
});


// kyc
  // ✅ Corrected the upload.fields line
  app.post(
    '/merchant/kyc',
    authMiddleware,
    upload.fields([
      { name: 'pan_image', maxCount: 1 },
      { name: 'aadhaar_image', maxCount: 1 }
    ]),
    async (req, res) => {
      try {
        const merchantId = req.userId;
        const { pan, aadhaar, account_holder, account_number, ifsc } = req.body;

        // ✅ Using optional chaining to safely get filenames
        const panImage = req.files?.pan_image?.[0]?.filename || null;
        const aadhaarImage = req.files?.aadhaar_image?.[0]?.filename || null;

        // 1. Check current status first
        const [current] = await db.query(
          "SELECT status FROM merchant_kyc WHERE merchant_id = ?",
          [merchantId]
        );

        const newStatus = 'pending';

        if (current.length > 0) {
          // UPDATE EXISTING
          await db.query(`
            UPDATE merchant_kyc SET
              pan_number = ?,
              aadhaar_number = ?,
              account_holder = ?,
              account_number = ?,
              ifsc_code = ?,
              pan_image = COALESCE(?, pan_image),
              aadhaar_image = COALESCE(?, aadhaar_image),
              status = ?,
              updated_at = NOW()
            WHERE merchant_id = ?
          `, [pan, aadhaar, account_holder, account_number, ifsc, panImage, aadhaarImage, newStatus, merchantId]);
        } else {
          // INSERT NEW
          await db.query(`
            INSERT INTO merchant_kyc
            (merchant_id, pan_number, aadhaar_number, account_holder, account_number, ifsc_code, pan_image, aadhaar_image, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          `, [merchantId, pan, aadhaar, account_holder, account_number, ifsc, panImage, aadhaarImage, newStatus]);
        }

        // 2. Sync the users table
        await db.query(
          "UPDATE users SET kyc_status = ?, updated_at = NOW() WHERE id = ?",
          [newStatus, merchantId]
        );

        res.json({
          message: current.length > 0 ? "KYC updated and resubmitted" : "KYC submitted successfully",
          status: newStatus
        });

      } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Server error" });
      }
    }
  );
/////////////////merchant notification//////////////

app.get("/merchant/notifications", authMiddleware, async (req, res) => {
  try {

    const merchantId = req.userId;

    console.log("🔔 FETCHING NOTIFICATIONS FOR MERCHANT:", merchantId);

    const [rows] = await db.query(
      `SELECT * FROM merchant_notifications
       WHERE merchant_id = ?
       ORDER BY created_at DESC`,
      [merchantId]
    );

    console.log("📦 NOTIFICATIONS FOUND:", rows);

    res.json(rows);

  } catch (err) {

    console.log("❌ MERCHANT NOTIFICATION FETCH ERROR:", err);

    res.status(500).json({
      message: "Failed to fetch notifications"
    });
  }
});

app.put("/merchant/notifications/:id/read", authMiddleware, async (req, res) => {
  try {
    const notificationId = req.params.id;
    const merchantId = req.user.id;

    const [result] = await db.query(
      `UPDATE merchant_notifications
       SET is_read = 1
       WHERE id = ? AND merchant_id = ?`,
      [notificationId, merchantId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Notification not found" });
    }

    res.json({ message: "Marked as read" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.delete("/merchant/notifications/:id", authMiddleware, async (req, res) => {
  try {
    const notificationId = req.params.id;
    const merchantId = req.user.id;

    const [result] = await db.query(
      `DELETE FROM merchant_notifications
       WHERE id = ? AND merchant_id = ?`,
      [notificationId, merchantId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Notification not found" });
    }

    res.json({ message: "Deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.get(
  "/merchant/notifications/unread-count",
  authMiddleware,
  async (req, res) => {
    try {
      const merchantId = req.user.id;

      const [rows] = await db.query(
        `SELECT COUNT(*) as count
         FROM merchant_notifications
         WHERE merchant_id = ?
         AND is_read = 0`,
        [merchantId]
      );

      res.json({
        count: rows[0].count,
      });

    } catch (err) {
      res.status(500).json({
        message: err.message,
      });
    }
  }
);

//-----------------------------------------------------MERCHANT SUBSCRIPTION.......................................................................................//

//GET subscription-status//
app.get('/merchant/subscription-status', authMiddleware, async (req, res) => {
  try {
    const merchantId = req.userId;

    const [rows] = await db.query(
      `SELECT * FROM merchant_subscriptions
       WHERE merchant_id = ?
       ORDER BY id DESC
       LIMIT 1`,
      [merchantId]
    );

    const now = new Date();

    // ---------------- NO RECORD ----------------
    if (rows.length === 0) {
      return res.json({
        status: "none",
        showTrial: true,
        plan: null,
        expiry: null,
        trialEndsAt: null
      });
    }

    const sub = rows[0];

    const trialActive =
      sub.trial_ends_at && new Date(sub.trial_ends_at) > now;

    const subscriptionActive =
      sub.end_date && new Date(sub.end_date) > now;

    const hasUsedTrial =
      !!sub.trial_started_at;

    res.json({
      status: subscriptionActive
        ? "active"
        : trialActive
        ? "trial"
        : "expired",

      plan: sub.plan,
      expiry: sub.end_date,
      trialEndsAt: sub.trial_ends_at,

      // 🔥 IMPORTANT FIX
      showTrial: !hasUsedTrial && !subscriptionActive
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

//. Create subscription//

app.post('/merchant/subscription/create', authMiddleware, async (req, res) => {
  try {
    const merchantId = req.userId;
    const { plan, durationDays, paymentId } = req.body;

    const start = new Date();
    const end = new Date();
    end.setDate(start.getDate() + durationDays);

    await db.query(
      `INSERT INTO merchant_subscriptions
      (merchant_id, plan, status, start_date, end_date, payment_id)
      VALUES (?, ?, 'active', ?, ?, ?)`,
      [merchantId, plan, start, end, paymentId]
    );

    res.json({
      message: "Subscription activated",
      plan,
      start,
      end
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

app.post('/merchant/start-trial', authMiddleware, async (req, res) => {
  try {
    const merchantId = req.userId;

    // 1. Check if trial already used
    const [rows] = await db.query(
      `SELECT trial_started_at
       FROM merchant_subscriptions
       WHERE merchant_id = ?
       ORDER BY id DESC
       LIMIT 1`,
      [merchantId]
    );

    if (rows.length > 0 && rows[0].trial_started_at) {
      return res.status(400).json({
        message: "Free trial already used"
      });
    }

    // 2. Create 30-day trial
    const start = new Date();
    const end = new Date(start);
    end.setDate(start.getDate() + 30);

    await db.query(
      `INSERT INTO merchant_subscriptions
      (merchant_id, plan, status, start_date, end_date, trial_started_at, trial_ends_at)
      VALUES (?, 'FREE_TRIAL', 'active', ?, ?, ?, ?)`,
      [merchantId, start, end, start, end]
    );

    res.json({
      message: "Trial started successfully",
      start,
      end
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

/////////////////////////////////////////////////ADMIN PANEL///////////////////////////////////////////////////////////////////////////
// 7.1 Dashboard Stats & Trends
app.get('/admin/dashboard', authMiddleware, async (req, res) => {
  try {
    const [userRows] = await db.query('SELECT COUNT(*) as total FROM users');
    const [orderRows] = await db.query('SELECT COUNT(*) as total FROM orders');
    const [merchantRows] = await db.query("SELECT COUNT(*) as total FROM users WHERE role = 'merchant' AND kyc_status = 'approved'");
    const [revenueRows] = await db.query('SELECT SUM(total_amount) as total FROM orders');

    const [salesTrend] = await db.query(`
      SELECT DATE(created_at) as date, SUM(total_amount) as value
      FROM orders WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
      GROUP BY DATE(created_at) ORDER BY date ASC
    `);

    const [ordersTrend] = await db.query(`
      SELECT DATE(created_at) as date, COUNT(*) as value
      FROM orders WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
      GROUP BY DATE(created_at) ORDER BY date ASC
    `);

    // 🚀 Fetch Recent Orders
    const [recentOrders] = await db.query(`
      SELECT o.id as order_id, u.name as customer_name, o.total_amount, o.status
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      ORDER BY o.created_at DESC LIMIT 5
    `);

    // 🚀 Fetch KYC Alerts
    const [kycRows] = await db.query("SELECT COUNT(*) as count FROM users WHERE role = 'merchant' AND kyc_status = 'pending'");

    // 🔥 ONLY ONE res.json() AT THE END
    res.json({
      totalUsers: userRows[0].total || 0,
      totalOrders: orderRows[0].total || 0,
      activeMerchants: merchantRows[0].total || 0,
      totalRevenue: revenueRows[0].total || 0,
      salesTrend: salesTrend,
      ordersTrend: ordersTrend,
      recentOrders: recentOrders,
      alerts: {
        pendingKyc: kycRows[0].count || 0
      }
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// 7.2.1 Get All Users with Order Counts
app.get('/admin/users', authMiddleware, async (req, res) => {
  try {
    const [users] = await db.query(`
      SELECT id, name, email, phone, role, kyc_status, is_blocked, created_at,
      (SELECT COUNT(*) FROM orders WHERE user_id = users.id) as total_orders
      FROM users
      WHERE role = 'user' -- 🔥 This line filters for regular users only
      ORDER BY created_at DESC
    `);
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// 7.2.2 Block/Unblock User
app.post('/admin/users/:id/toggle-block', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    // Get the current user data
    const [userRows] = await db.query('SELECT is_blocked FROM users WHERE id = ?', [id]);

    if (userRows.length === 0) return res.status(404).json({ message: "User not found" });

    // Toggle the status
    const newStatus = userRows[0].is_blocked === 1 ? 0 : 1;

    await db.query('UPDATE users SET is_blocked = ? WHERE id = ?', [newStatus, id]);
    res.json({ success: true, is_blocked: newStatus });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/admin/users/:id/details', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;

    // 1. Get Profile
    const [user] = await db.query('SELECT name, email, avatar, created_at, phone FROM users WHERE id = ?', [id]);

    // 2. Get Order Status Counts
    const [stats] = await db.query(`
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN status IN ('Placed', 'Processing') THEN 1 ELSE 0 END) as ongoing,
        SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END) as completed,
        SUM(CASE WHEN status = 'Canceled' THEN 1 ELSE 0 END) as canceled,
        SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) as returned
      FROM orders WHERE user_id = ?`, [id]);

    // 3. Get Order List
// 3. Get Order List - Updated to select the actual varchar column
const [orders] = await db.query(`
  SELECT
    order_id,
    total_amount,
    status,
    payment_status,
    created_at
  FROM orders WHERE user_id = ? ORDER BY created_at DESC`, [id]);


res.json({
  profile: user[0],
  stats: stats[0],
  orders: orders
});

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/admin/users/:id', authMiddleware, async (req, res) => {
  try {
    const userId = req.params.id;

    // Example query (adjust to your DB)
    await db.query('DELETE FROM users WHERE id = ?', [userId]);

    res.status(200).json({ message: 'User deleted successfully' });
  } catch (err) {
    console.error('Delete Error:', err);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// GET Comprehensive Customer Details for Admin
app.get('/admin/users/:userId/details', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.params;

    // 1. Fetch User Profile
    const [profile] = await db.query(
      'SELECT name, email, avatar, created_at FROM users WHERE id = ?',
      [userId]
    );

    if (profile.length === 0) return res.status(404).json({ message: "User not found" });

    // 2. Fetch Order Statistics (Counts by Status)
    const [stats] = await db.query(
      `SELECT
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'PENDING' OR status = 'PROCESSING' THEN 1 END) as ongoing,
        COUNT(CASE WHEN status = 'DELIVERED' THEN 1 END) as completed,
        COUNT(CASE WHEN status = 'CANCELED' THEN 1 END) as canceled,
        COUNT(CASE WHEN status = 'RETURNED' THEN 1 END) as returned
       FROM orders WHERE user_id = ?`,
      [userId]
    );

    // 3. Fetch Recent Order List
    const [orders] = await db.query(
      `SELECT order_id, total_amount, status, payment_status, created_at
       FROM orders WHERE user_id = ? ORDER BY created_at DESC`,
      [userId]
    );

    res.json({
      profile: profile[0],
      stats: stats[0] || { total: 0, ongoing: 0, completed: 0, canceled: 0, returned: 0 },
      orders: orders
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

app.get('/admin/orders/:id', authMiddleware, async (req, res) => {
  try {
    const orderId = req.params.id;

    // 1. Fetch Basic Order Info
    const [orderRows] = await db.query('SELECT * FROM orders WHERE order_id = ?', [orderId]);

    if (orderRows.length === 0) {
      return res.status(404).json({ message: "Order not found" });
    }

    const order = orderRows[0];

    // 2. Fetch Items from order_items table
    const [itemRows] = await db.query(
      'SELECT name, image_url, price, quantity FROM order_items WHERE order_id = ?',
      [orderId]
    );

    // 3. Format response for the Flutter UI
    res.json({
      order_id: order.order_id,
      total_amount: order.total_amount,
      status: order.status,
      address: order.address,
      payment_method: order.payment_method,
      payment_status: order.payment_status,
      refund_status: order.refund_status,
      created_at: order.created_at,
      is_paid: order.is_paid,
      sub_total: order.total_amount, // Using total_amount as fallback
      tax: 0,
      shipping: 0,
      items: itemRows // Now contains the list of products with images
    });
  } catch (err) {
    console.error("Fetch Order Error:", err);
    res.status(500).json({ error: err.message });
  }
});

// --- ADMIN: Fetch All Pending KYC Applications ---
app.get('/admin/kyc/pending', authMiddleware, async (req, res) => {
  try {
    // This query gets merchant data and joins with users table for the name/email
    const [rows] = await db.query(`
      SELECT
        mk.*,
        u.name as merchant_name,
        u.email
      FROM merchant_kyc mk
      JOIN users u ON mk.merchant_id = u.id
      WHERE mk.status = 'pending'
      ORDER BY mk.created_at DESC
    `);

    res.json(rows);
  } catch (err) {
    console.error("Admin KYC Fetch Error:", err);
    res.status(500).json({ message: "Server error" });
  }
});


// --- ADMIN: Update Merchant KYC Status ---
app.post('/admin/kyc/update-status', authMiddleware, async (req, res) => {
  try {
    const { merchant_id, status, reason } = req.body;

    // 1. Update the KYC table (Removed updated_at)
    const [kycResult] = await db.query(
      "UPDATE merchant_kyc SET status = ? WHERE merchant_id = ?",
      [status, merchant_id]
    );

    // 2. Update the users table (Removed updated_at)
    // Assuming 'users' table also might not have 'updated_at' based on the error
    const [userResult] = await db.query(
      "UPDATE users SET kyc_status = ? WHERE id = ?",
      [status, merchant_id]
    );

    if (kycResult.affectedRows === 0) {
      return res.status(404).json({ message: "Merchant KYC record not found" });
    }

    res.json({
      success: true,
      message: `KYC has been successfully ${status}`
    });

  } catch (err) {
    console.error("KYC Update Error:", err);
    res.status(500).json({ message: "Server error during KYC update" });
  }
});


app.get('/admin/kyc/all', authMiddleware, async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT
        mk.*,
        u.name as merchant_name,
        u.email,
        u.phone,                 -- 🔥 Added Vendor Phone
        ms.name as shop_name,
        ms.contact,              -- 🔥 Added Shop Contact/Phone
        ms.address,              -- 🔥 Added Shop Address
        (SELECT COUNT(*) FROM products WHERE merchant_id = mk.merchant_id) as total_products,
        (SELECT COUNT(DISTINCT id) FROM orders WHERE merchant_id = mk.merchant_id) as total_orders
      FROM merchant_kyc mk
      JOIN users u ON mk.merchant_id = u.id
      LEFT JOIN merchant_shops ms ON mk.merchant_id = ms.merchant_id
      ORDER BY mk.created_at DESC
    `);
    res.json(rows);
  } catch (err) {
    console.error("SQL Error:", err);
    res.status(500).json({ message: "Server error" });
  }
});


// 1. Fetch current settings and vendor list
app.get('/admin/commission/settings', authMiddleware, async (req, res) => {
  try {
    // 1. Get global commission
    const [globalRows] = await db.query(
      "SELECT value FROM business_settings WHERE type = 'global_commission'"
    );

    // 2. Get all vendors
    const [vendorRows] = await db.query(
      "SELECT merchant_id, name, commission_rate FROM merchant_shops"
    );

    // 🔥 FIX: Check if globalRows has data before accessing [0]
   const globalValue =
     globalRows.length > 0 ? Number(globalRows[0].value) : 0;

    console.log("Sending Settings:", { global_commission: globalValue, vendors: vendorRows });

    res.json({
      global_commission: globalValue,
      vendors: vendorRows // This must be an array []
    });
  } catch (err) {
    console.error("Commission Fetch Error:", err);
    res.status(500).json({ message: "Server Error", error: err.message });
  }
});



// 2. Update the Global percentage
app.post('/admin/commission/global', authMiddleware, async (req, res) => {
  const { rate } = req.body;
  await db.query("INSERT INTO business_settings (type, value) VALUES ('global_commission', ?) ON DUPLICATE KEY UPDATE value = ?", [rate, rate]);
  res.json({ success: true });
});

// 3. Update a specific vendor
app.post('/admin/commission/vendor', authMiddleware, async (req, res) => {
  const { merchant_id, rate } = req.body;
  await db.query("UPDATE merchant_shops SET commission_rate = ? WHERE merchant_id = ?", [rate, merchant_id]);
  res.json({ success: true });
});

// 1. Fetch All Pending Withdrawal Requests for Table List
app.get('/admin/payouts/pending', authMiddleware, async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT
        pr.id, pr.merchant_id, pr.amount, pr.status, pr.requested_at,
        ms.name as shop_name
      FROM payout_requests pr
      JOIN merchant_shops ms ON pr.merchant_id = ms.merchant_id
      WHERE pr.status = 'pending'
      ORDER BY pr.requested_at DESC
    `);
    res.json(rows);
  } catch (err) {
    console.error("Fetch Pending Payouts Error:", err);
    res.status(500).json({ message: "Internal Server Error" });
  }
});

///PAYOUT//
app.post('/admin/payouts/update-status', authMiddleware, async (req, res) => {
  // We use order_id to identify the transaction since you're clicking from the order/report list
  const { order_id, merchant_id, amount, status } = req.body;

  const connection = await db.getConnection();

  try {
    await connection.beginTransaction();

    // 1️⃣ Check if a payout record already exists for this order
    const [rows] = await connection.query(
      "SELECT id, status FROM payout_requests WHERE order_id = ? FOR UPDATE",
      [order_id]
    );

    let payout_id;

    if (rows.length > 0) {
      // If it exists but is already done, stop to prevent double deduction
      if (rows[0].status === 'completed' || rows[0].status === 'failed') {
        await connection.rollback();
        return res.status(400).json({ message: `Order ${order_id} already processed.` });
      }
      payout_id = rows[0].id;
    }

    if (status === 'approved') {
      if (rows.length === 0) {
        // 2️⃣ Create a new record on the fly if it doesn't exist
        const [insert] = await connection.query(
          `INSERT INTO payout_requests (merchant_id, order_id, amount, status, requested_at, completed_at)
           VALUES (?, ?, ?, 'completed', NOW(), NOW())`,
          [merchant_id, order_id, amount]
        );
        payout_id = insert.insertId;
      } else {
        // 3️⃣ Update the existing pending record
        await connection.query(
          "UPDATE payout_requests SET status='completed', completed_at=NOW() WHERE id=?",
          [payout_id]
        );
      }

      // 4️⃣ Deduct wallet balance
      await connection.query(
        "UPDATE merchant_wallet SET balance = balance - ? WHERE merchant_id=?",
        [amount, merchant_id]
      );

      // 5️⃣ Insert ledger record for history
      await connection.query(
        `INSERT INTO merchant_wallet_transactions
         (merchant_id, order_id, amount, type, description)
         VALUES (?, ?, ?, 'debit', ?)`,
        [merchant_id, order_id, amount, `Payout processed for Order #${order_id}`]
      );
    }

    if (status === 'rejected') {
      if (rows.length === 0) {
        // Create a failed record for tracking even if rejected immediately
        await connection.query(
          `INSERT INTO payout_requests (merchant_id, order_id, amount, status, requested_at, completed_at)
           VALUES (?, ?, ?, 'failed', NOW(), NOW())`,
          [merchant_id, order_id, amount]
        );
      } else {
        await connection.query(
          "UPDATE payout_requests SET status='failed', completed_at=NOW() WHERE id=?",
          [payout_id]
        );
      }
    }

    await connection.commit();
    res.json({ success: true, message: "Payout updated successfully" });

  } catch (err) {
    await connection.rollback();
    console.error("Payout Error:", err);
    res.status(500).json({ message: "Server error during payout" });
  } finally {
    connection.release();
  }
});

// ---------------- ADMIN: FETCH ALL PRODUCTS FOR APPROVAL ----------------
app.get('/admin/products', authMiddleware, async (req, res) => {
  try {
    // We JOIN with the 'users' (or merchants) table to get the shop/vendor name
    // Replace 'users' with your actual merchant table name if it's different
    const sql = `
      SELECT p.*, u.name as vendor_name
      FROM products p
      LEFT JOIN users u ON p.merchant_id = u.id
      ORDER BY p.created_at DESC
    `;

    const [products] = await db.query(sql);

    // To match your Flutter code, we wrap it in a data object
    res.json({ success: true, data: products });
  } catch (err) {
    console.error("Admin DB error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// ---------------- ADMIN: APPROVE/REJECT PRODUCT ----------------
app.post("/admin/products/update-status", authMiddleware, async (req, res) => {
  try {
    const { product_id, status } = req.body; // status: 'approved' or 'denied'

    if (!['approved', 'denied'].includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    const sql = "UPDATE products SET request_status = ? WHERE id = ?";

    await db.query(sql, [status, product_id]);

    res.json({ success: true, message: `Product ${status} successfully` });
  } catch (err) {
    console.error("Status Update error:", err);
    res.status(500).json({ error: err.message });
  }
});

// 3. Delete Category (Deletes child sub-categories automatically)
app.delete('/admin/products/:id', authMiddleware, async (req, res) => {
  try {
    // Optional: Check if req.userRole === 'admin'
    await db.query("DELETE FROM products WHERE id = ?", [req.params.id]);
    res.json({ success: true, message: "Product deleted by Admin" });
  } catch (err) {
    res.status(500).json({ message: "Failed to delete" });
  }
});

// ---------------- ADMIN: EDIT PRODUCT ----------------
// 🚩 Ensure this is .put and NOT .post
// ---------------- ADMIN: DEDICATED EDIT ROUTE ----------------
app.put("/admin/products/:id", authMiddleware, upload.single("image_url"), async (req, res) => {
  try {
    const productId = req.params.id;
    // Note: Admin doesn't care about merchantId ownership

    const {
      name, description, price, mrp, stock_quantity,
      low_stock_threshold, sku, category_id, sub_category_id
    } = req.body;

    // 1. Get existing product only by ID
    const [rows] = await db.query("SELECT * FROM products WHERE id=?", [productId]);
    if (rows.length === 0) {
      return res.status(404).json({ message: "Product not found" });
    }

    const oldProduct = rows[0];
    let imageUrl = oldProduct.image_url;

    if (req.file) {
      imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
    }

    // 2. Update logic without merchant_id check
    await db.query(
      `UPDATE products SET
        name=?, description=?, price=?, mrp=?, stock_quantity=?,
        low_stock_threshold=?, sku=?, category_id=?, sub_category_id=?, image_url=?
      WHERE id=?`,
      [name, description, price, mrp, stock_quantity, low_stock_threshold, sku, category_id, sub_category_id, imageUrl, productId]
    );

    res.json({ success: true, message: "Product updated successfully by Admin" });
  } catch (error) {
    res.status(500).json({ message: "Admin update failed", error: error.message });
  }
});



// ---------------- ADMIN: CATEGORY & SUB-CATEGORY CRUD ----------------

app.get('/admin/categories', async (req, res) => {
  try {
    const sql = `
      SELECT c.*,
      (SELECT COUNT(*) FROM sub_categories WHERE category_id = c.id) as sub_count
      FROM categories c
      ORDER BY c.priority ASC, c.id DESC`; // 👈 Change to ASC
    const [rows] = await db.query(sql);
    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});




// 2. Add Category or Sub-Category (Handles Both)
app.post("/admin/category/store", upload.single("icon_url"), async (req, res) => {
  const { name, category_id } = req.body;
  const icon = req.file ? `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}` : null;

  try {
    if (category_id && category_id !== '0') {
      // Logic: Save to sub_categories table
      await db.query("INSERT INTO sub_categories (name, category_id, icon_url) VALUES (?, ?, ?)",
        [name, category_id, icon]);
    } else {
      // Logic: Save to main categories table
      await db.query("INSERT INTO categories (name, icon_url) VALUES (?, ?)", [name, icon]);
    }
    res.json({ success: true, message: "Created successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// ✅ ADD THIS ROUTE TO YOUR SERVER
app.post("/admin/category/add", authMiddleware, upload.single("icon_url"), async (req, res) => {
  try {
    const { name, priority } = req.body;
    const icon_url = req.file ? `/uploads/${req.file.filename}` : null;

    if (!name) return res.status(400).json({ message: "Name is required" });

    const [result] = await db.query(
      "INSERT INTO categories (name, icon_url, priority) VALUES (?, ?, ?)",
      [name, icon_url, priority || 1]
    );

    res.status(201).json({ success: true, message: "Category created" });
  } catch (err) {
    console.error("Route Error:", err);
    res.status(500).json({ message: "Server error" });
  }
});



// ✏️ UPDATE CATEGORY
app.put("/admin/category/:id", authMiddleware, upload.single("icon_url"), async (req, res) => {
  try {
    const { id } = req.params;

    // 🔍 DEBUG LOGS
    console.log("Files:", req.file);
    console.log("Body:", req.body);

    // Extract fields from req.body
    const name = req.body.name;
    const priority = req.body.priority;

    if (!name) {
      return res.status(400).json({ success: false, message: "Name is missing in request body" });
    }

    const [existing] = await db.query("SELECT icon_url FROM categories WHERE id = ?", [id]);
    if (!existing || existing.length === 0) {
      return res.status(404).json({ success: false, message: "Category not found" });
    }

    let icon_url = existing[0].icon_url;
    if (req.file) {
      icon_url = `/uploads/${req.file.filename}`;
    }

    // Convert priority to Number
    const finalPriority = parseInt(priority) || 1;

    await db.query(
      "UPDATE categories SET name = ?, icon_url = ?, priority = ? WHERE id = ?",
      [name, icon_url, finalPriority, id]
    );

    res.json({ success: true, message: "Category updated successfully" });
  } catch (err) {
    console.error("Update Category Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});




// 🗑️ DELETE CATEGORY
app.delete("/admin/category/:id", authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;

    // 1. Optional but recommended: Check if sub_categories exist first
    const [subs] = await db.query("SELECT id FROM sub_categories WHERE category_id = ?", [id]);
    if (subs.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Cannot delete category that has sub-categories. Delete them first."
      });
    }

    // 2. Delete the category
    const [result] = await db.query("DELETE FROM categories WHERE id = ?", [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: "Category not found" });
    }

    res.json({ success: true, message: "Category deleted successfully" });
  } catch (err) {
    console.error("Delete Category Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// 🏠 TOGGLE HOME CATEGORY STATUS
app.patch("/admin/category/:id/home-status", authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { home_status } = req.body; // Expects true or false (or 1/0)

    const statusValue = home_status ? 1 : 0;

    const [result] = await db.query(
      "UPDATE categories SET home_status = ? WHERE id = ?",
      [statusValue, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: "Category not found" });
    }

    res.json({ success: true, message: "Home status updated" });
  } catch (err) {
    console.error("Home Status Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});


app.get('/admin/sub-categories', authMiddleware, async (req, res) => {
  try {
    const sql = `
      SELECT
        s.id,
        s.name,
        s.category_id,
        s.priority,
        s.icon_url,            -- 👈 ADD THIS LINE
        c.name as main_category_name
      FROM sub_categories s
      LEFT JOIN categories c ON s.category_id = c.id
      ORDER BY s.priority ASC, s.name ASC`;

    const [rows] = await db.query(sql);
    res.json({ success: true, data: rows }); // Ensure your model parses 'icon_url'
  } catch (err) {
    console.error("SQL ERROR in Sub-Categories:", err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});


// ✏️ UPDATE SUB-CATEGORY
// Add multer middleware to the route
app.put("/admin/sub-category/:id", authMiddleware, upload.single('icon_url'), async (req, res) => {
  try {
    const { id } = req.params;
    const { name, category_id, priority } = req.body;

    // Check if a new file was uploaded
    const icon_url = req.file ? `/uploads/${req.file.filename}` : null;

    if (icon_url) {
      // Update everything including image
      await db.query(
        "UPDATE sub_categories SET name = ?, category_id = ?, priority = ?, icon_url = ? WHERE id = ?",
        [name, category_id, priority || 1, icon_url, id]
      );
    } else {
      // Update only text fields
      await db.query(
        "UPDATE sub_categories SET name = ?, category_id = ?, priority = ? WHERE id = ?",
        [name, category_id, priority || 1, id]
      );
    }

    res.json({ success: true, message: "Sub-category updated successfully" });
  } catch (err) {
    console.error(err); // This helps you see the actual error in terminal
    res.status(500).json({ success: false, message: "Server error" });
  }
});


// 🗑️ DELETE SUB-CATEGORY
app.delete("/admin/sub-category/:id", authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    // Check if products are linked to this sub-category before deleting
    const [products] = await db.query("SELECT id FROM products WHERE sub_category_id = ?", [id]);
    if (products.length > 0) {
      return res.status(400).json({ success: false, message: "Cannot delete: Products are linked to this sub-category" });
    }

    await db.query("DELETE FROM sub_categories WHERE id = ?", [id]);
    res.json({ success: true, message: "Sub-category deleted" });
  } catch (err) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ➕ ADD SUB-CATEGORY
//app.post("/admin/sub-category/add", authMiddleware, async (req, res) => {
//  try {
//    const { name, category_id, priority } = req.body;
//    const sql = "INSERT INTO sub_categories (name, category_id, priority) VALUES (?, ?, ?)";
//    await db.query(sql, [name, category_id, priority || 1]);
//    res.status(201).json({ success: true, message: "Sub-category added" });
//  } catch (err) {
//    res.status(500).json({ error: err.message });
//  }
//});

app.post('/admin/sub-category/add', authMiddleware, upload.single('icon_url'), async (req, res) => {
  try {
    const { name, category_id, priority } = req.body;
    const icon_url = req.file ? `/uploads/${req.file.filename}` : null; // 👈 Get path from multer

    const sql = `INSERT INTO sub_categories (name, category_id, priority, icon_url) VALUES (?, ?, ?, ?)`;
    await db.query(sql, [name, category_id, priority, icon_url]);

    res.status(201).json({ success: true, message: "Sub-category added!" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: err.message });
  }
});


// ---------------- ADMIN: FETCH ALL ORDERS WITH ITEMS ----------------
app.get('/admin/orders', authMiddleware, async (req, res) => {
  try {
    // 1. Fetch all orders
    const [orders] = await db.query(`SELECT * FROM orders ORDER BY created_at DESC`);

    // 2. Fetch all items (to match your Flutter model's nested list)
    const [items] = await db.query(`SELECT * FROM order_items`);

    // 3. Combine them
    const ordersWithItems = orders.map(order => {
      return {
        ...order,
        items: items.filter(item => item.order_id === order.id)
      };
    });

    res.json({ success: true, data: ordersWithItems });
  } catch (err) {
    console.error("Fetch Orders Error:", err);
    res.status(500).json({ success: false, message: "Server Error" });
  }
});

// ---------------- ADMIN: UPDATE ORDER STATUS ----------------
app.patch('/admin/orders/:id/status', authMiddleware, async (req, res) => {
  const { id } = req.params;
  const { status } = req.body; // e.g., 'Confirmed', 'Delivered', 'Canceled'

  try {
    await db.query("UPDATE orders SET status = ? WHERE id = ?", [status, id]);
    res.json({ success: true, message: "Order status updated" });
  } catch (err) {
    res.status(500).json({ message: "Update failed" });
  }
});

// ---------------- ADMIN: REFUND PROCESSING ----------------
// POST: Update status and insert log into refund_status_logs
app.post("/merchant/refunds/:id/:action", authMiddleware, async (req, res) => {
    const refundId = req.params.id; // Correctly catches '13'
    let action = req.params.action.toLowerCase().trim(); // Catches 'approve', 'reject', or 'refund'
    const { note } = req.body;
    const changedBy = (req.user && req.user.role) ? req.user.role : 'Admin';

    let status = 'pending';
    if (action.includes('approve')) status = 'approved';
    if (action.includes('reject')) status = 'rejected';
    if (action.includes('refund')) status = 'refunded';

    try {
        // 1️⃣ Step A: Fetch order metadata out of your refund_requests table
        const [refunds] = await db.query(
            "SELECT order_id, amount FROM refund_requests WHERE id = ?",
            [refundId]
        );

        if (!refunds || refunds.length === 0) {
            return res.status(404).json({ success: false, error: "Refund request tracking record not found" });
        }

        const realOrderId = refunds[0].order_id;
        const refundAmount = refunds[0].amount;

        // 2️⃣ Step B: Update tracking tables
        await db.query("UPDATE refund_requests SET status = ? WHERE id = ?", [status, refundId]);

        await db.query(
            "INSERT INTO refund_status_logs (refund_id, changed_by, status, note) VALUES (?, ?, ?, ?)",
            [refundId, changedBy, status, note || ""]
        );

        // Sync statuses over to the master orders table based on action types
        if (status === 'refunded' || status === 'approved') {
            await db.query("UPDATE orders SET refund_status = 'COMPLETED', status = 'Refunded' WHERE id = ?", [realOrderId]);
        } else if (status === 'rejected') {
            await db.query("UPDATE orders SET refund_status = 'REJECTED' WHERE id = ?", [realOrderId]);
        }

        // 3️⃣ Step C: Look up buyer ID inside orders table
        const [orders] = await db.query("SELECT user_id FROM orders WHERE id = ?", [realOrderId]);

        if (orders && orders.length > 0) {
            const buyerUserId = orders[0].user_id;

            // Trigger notifications right inside the active pipeline!
            if (status === 'refunded' || status === 'approved') {
                console.log("🚨 DISPATCHING NOTIFICATION: ORDER_REFUNDED");
                eventEmitter.emit("ORDER_REFUNDED", {
                    userId: buyerUserId,
                    orderId: realOrderId,
                    refundAmount: refundAmount
                });
            } else if (status === 'rejected') {
                console.log("🚨 DISPATCHING NOTIFICATION: REFUND_REJECTED");
                eventEmitter.emit("REFUND_REJECTED", {
                    userId: buyerUserId,
                    orderId: realOrderId
                });
            }
        }

        // Return exact response string expected by your Flutter app
        return res.status(200).json({ success: true, message: "REFUND_LOGGED_SUCCESSFULLY" });

    } catch (err) {
        console.error("❌ BACKEND PIPELINE SQL ERROR:", err.message);
        return res.status(500).json({ success: false, error: err.message });
    }
});




app.get('/admin/refunds', authMiddleware, async (req, res) => {
  const { status } = req.query;

  try {
    let sql = `
      SELECT
        r.id AS refund_id,
        r.order_id AS numeric_order_id,
        r.merchant_id,
        r.amount,
        r.reason,
        r.status,
        r.created_at,
        -- Force selection of product details
        COALESCE(oi.name, 'Unknown Product') AS product_name,
        COALESCE(oi.image_url, '') AS image_url,
        COALESCE(oi.quantity, 1) AS quantity,
        -- Force selection of shop details
        COALESCE(ms.name, 'Unknown Shop') AS shop_name,
        COALESCE(ms.contact, 'N/A') AS vendor_phone
      FROM refund_requests r
      LEFT JOIN orders o ON CAST(r.order_id AS CHAR) = CAST(o.id AS CHAR)
      LEFT JOIN order_items oi ON TRIM(o.order_id) = TRIM(oi.order_id)
                               AND CAST(r.product_id AS CHAR) = CAST(oi.product_id AS CHAR)
      LEFT JOIN merchant_shops ms ON CAST(r.merchant_id AS CHAR) = CAST(ms.merchant_id AS CHAR)
    `;

    // 🔥 Added TRIM and LOWER to the filter for a perfect match
    if (status && status !== 'all') {
      sql += ` WHERE LOWER(TRIM(r.status)) = ${db.escape(status.toLowerCase().trim())}`;
    }

    sql += ` ORDER BY r.created_at DESC`;

    const [rows] = await db.query(sql);

    // 🕵️ DEBUG LOG: Check this in your server terminal!
    console.log(`-----------------------------------`);
    console.log(`STATUS REQUESTED: ${status}`);
    console.log(`ROWS FOUND: ${rows.length}`);
    if(rows.length > 0) console.log(`FIRST PRODUCT: ${rows[0].product_name}`);
    console.log(`-----------------------------------`);

    res.json({ success: true, data: rows });
  } catch (err) {
    console.error("❌ ADMIN FETCH ERROR:", err.message);
    res.status(500).json({ success: false, message: "Server error" });
  }
});




// --- NEW REFUND ROUTES ---

// POST: Update status and insert log into refund_status_logs
app.post("/merchant/refunds/:id/:action", authMiddleware, async (req, res) => {
    const refundId = req.params.id;
    let action = req.params.action.toLowerCase().trim();
    const { note } = req.body;
    const changedBy = (req.user && req.user.role) ? req.user.role : 'Admin';

    // Force standard strings to avoid "Data truncated" errors
    let status = 'pending';
    if (action.includes('approve')) status = 'approved';
    if (action.includes('reject')) status = 'rejected';
    if (action.includes('refund')) status = 'refunded';

    try {
        await db.query("UPDATE refund_requests SET status = ? WHERE id = ?", [status, refundId]);

        await db.query(
            "INSERT INTO refund_status_logs (refund_id, changed_by, status, note) VALUES (?, ?, ?, ?)",
            [refundId, changedBy, status, note || ""]
        );

        res.status(200).json({ success: true, message: "REFUND_LOGGED_SUCCESSFULLY" });
    } catch (err) {
        console.error("❌ SQL ERROR:", err.message);
        res.status(500).json({ success: false, error: err.message });
    }
});

// GET: Fetch logs for the Flutter screen
app.get("/merchant/refunds/:id/logs", authMiddleware, async (req, res) => {
    const refundId = req.params.id;
    try {
        const [rows] = await db.query(
            "SELECT * FROM refund_status_logs WHERE refund_id = ? ORDER BY created_at DESC",
            [refundId]
        );
        res.status(200).json({ success: true, data: rows });
    } catch (err) {
        console.error("❌ FETCH LOGS ERROR:", err.message);
        res.status(500).json({ success: false, error: err.message });
    }
});


// --- . POST: ADD NEW BANNER (ADMIN) ---
app.post("/admin/banners", upload.single("image"), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No image uploaded" });

    const { type, link } = req.body;
    // Constructs full URL: http://your-ip:3000/uploads/filename.jpg
    //const imageUrl = `${req.protocol}://${req.get("host")}/uploads/${req.file.filename}`;
   const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;
    const query = "INSERT INTO banners (image_url, type, link, is_published) VALUES (?, ?, ?, 1)";
    await db.query(query, [imageUrl, type || 'Main Section Banner', link || '']);

    res.status(201).json({ message: "Banner created successfully!" });
  } catch (error) {
    console.error("❌ DB ERROR:", error);
    res.status(500).json({ error: "Failed to create banner" });
  }
});

// --- 1. GET ALL BANNERS ---
app.get("/admin/banners", async (req, res) => {
  try {
    const [rows] = await db.query("SELECT * FROM banners ORDER BY created_at DESC");
    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Failed to fetch banners" });
  }
});

// --- 2. PATCH: TOGGLE STATUS (Published/Draft) ---
app.patch("/admin/banners/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { is_published, link, type } = req.body;

    let updates = [];
    let values = [];

    if (is_published !== undefined) {
      updates.push("is_published = ?");
      values.push(is_published ? 1 : 0);
    }
    if (link !== undefined) {
      updates.push("link = ?");
      values.push(link);
    }
    if (type !== undefined) {
      updates.push("type = ?");
      values.push(type);
    }

    if (updates.length === 0) return res.status(400).json({ message: "Nothing to update" });

    values.push(id);
    const sql = `UPDATE banners SET ${updates.join(", ")} WHERE id = ?`;

    const [result] = await db.query(sql, values);
    res.json({ success: true, message: "Banner updated successfully" });
  } catch (error) {
    console.error("❌ UPDATE ERROR:", error);
    res.status(500).json({ error: "Update failed" });
  }
});


// --- 3. DELETE: REMOVE BANNER ---
app.delete("/admin/banners/:id", async (req, res) => {
  try {
    await db.query("DELETE FROM banners WHERE id = ?", [req.params.id]);
    res.json({ message: "Deleted" });
  } catch (err) {
    res.status(500).send(err);
  }
});

// ✅ SAVE OR UPDATE STATIC PAGE
app.post('/admin/static-pages/save', authMiddleware, async (req, res) => {
  try {
    const { slug, title, content } = req.body;

    // This SQL will update the row if the slug already exists, otherwise it inserts a new one
    const sql = `
      INSERT INTO static_pages (slug, title, content)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE title = VALUES(title), content = VALUES(content)
    `;

    await db.query(sql, [slug, title, content]);
    res.json({ success: true, message: "Page saved successfully" });
  } catch (err) {
    console.error("Error saving static page:", err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ✅ GET SINGLE PAGE BY SLUG
app.get('/admin/static-pages/:slug', authMiddleware, async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM static_pages WHERE slug = ?', [req.params.slug]);

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "Page not found" });
    }

    res.json({ success: true, data: rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});


app.get('/admin/reports/sales', authMiddleware, async (req, res) => {
  const { filter } = req.query;
  let dateCondition = "1=1";

  if (filter === "This Month") {
    dateCondition = "MONTH(o.created_at) = MONTH(CURRENT_DATE()) AND YEAR(o.created_at) = YEAR(CURRENT_DATE())";
  } else if (filter === "This Year") {
    dateCondition = "YEAR(o.created_at) = YEAR(CURRENT_DATE())";
  }

  try {
    // 1. Summary Metrics - JOINING ON ms.merchant_id
    const [summaryRows] = await db.query(`
      SELECT
        COALESCE(SUM(o.total_amount), 0) as totalSales,
        -- Force the commission calculation. If the JOIN fails, we fallback to 10% as a safety.
        COALESCE(SUM(o.total_amount * (COALESCE(ms.commission_rate, 10.00) / 100)), 0) as totalCommission,
        COALESCE(SUM(o.total_amount - (o.total_amount * (COALESCE(ms.commission_rate, 10.00) / 100))), 0) as vendorShare,
        (SELECT COALESCE(SUM(quantity), 0) FROM order_items) as totalProductsSold,
        (SELECT COUNT(*) FROM merchant_shops WHERE is_active = 1) as activeVendors
      FROM orders o
      -- 🔥 Force both IDs to be treated as CHAR for the JOIN to prevent type mismatch
      LEFT JOIN merchant_shops ms ON CAST(o.merchant_id AS CHAR) = CAST(ms.merchant_id AS CHAR)
      WHERE (LOWER(o.status) IN ('delivered', 'success', 'completed', 'paid') OR o.status IS NULL)
      AND ${dateCondition}
    `);

   const [chartData] = await db.query(`
      SELECT MONTH(o.created_at) as month, SUM(o.total_amount) as amount
      FROM orders o
      WHERE ${dateCondition}
      GROUP BY month ORDER BY month
    `);

        const [payments] = await db.query(`
          SELECT o.payment_method, SUM(o.total_amount) as amount
          FROM orders o
          WHERE ${dateCondition}
          GROUP BY o.payment_method
        `);

    // 4. Transactions - JOINING ON ms.merchant_id
    const [transactions] = await db.query(`
      SELECT
        o.order_id,
        ms.name as vendor_name,
        o.total_amount as subtotal,
        (o.total_amount * (ms.commission_rate / 100)) as commission,
        o.status
      FROM orders o
      INNER JOIN merchant_shops ms ON o.merchant_id = ms.merchant_id
      WHERE ${dateCondition}
      ORDER BY o.created_at DESC LIMIT 10
    `);

    const summary = summaryRows[0] || {
      totalSales: 0, totalCommission: 0, vendorShare: 0, totalProductsSold: 0, activeVendors: 0
    };

    // This log should now show a real number for totalCommission
    console.log("Summary Data Sent:", summary);

    res.json({
      success: true,
      summary: summary,
      chart: chartData, // ✅ Fixed: Use the fetched chartData variable
      payments: payments, // ✅ Fixed: Use the fetched payments variable
      transactions: transactions
    });


  } catch (err) {
    console.error("SQL Error:", err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});


app.get('/admin/reports/commissions', authMiddleware, async (req, res) => {
  const { filter } = req.query;

  try {
    // 1. Date Condition
    let dateCondition = "1=1";
    if (filter === "This Month") {
      dateCondition = "MONTH(o.created_at) = MONTH(CURRENT_DATE()) AND YEAR(o.created_at) = YEAR(CURRENT_DATE())";
    } else if (filter === "This Year") {
      dateCondition = "YEAR(o.created_at) = YEAR(CURRENT_DATE())";
    }

    // 2. Order Status Condition (Clean version for summaries)
    const baseStatusCondition = "LOWER(o.status) IN ('delivered', 'success', 'completed', 'paid')";

    // 3. MAIN QUERY (Hides paid orders using pr.status)
    // 3. MAIN QUERY (Includes Product Names and Hides paid orders)
         // 3. MAIN QUERY (Sends ALL data to Flutter for a complete report)
         const mainQuery = `
           SELECT
             o.id AS order_id,
             o.merchant_id,
             ms.name AS vendor_name,
             o.total_amount AS order_amount,
             COALESCE(ms.commission_rate, 0) AS commission_rate,
             (o.total_amount * (COALESCE(ms.commission_rate, 0) / 100)) AS commission_amount,
             (o.total_amount - (o.total_amount * (COALESCE(ms.commission_rate, 0) / 100))) AS payout_amount,
             o.status,
             o.created_at,
             pr.status AS payout_status,

             (SELECT GROUP_CONCAT(name SEPARATOR ', ')
              FROM order_items
              WHERE order_id = o.order_id) AS product_names

           FROM orders o
           LEFT JOIN merchant_shops ms ON o.merchant_id = ms.merchant_id
           LEFT JOIN payout_requests pr ON pr.order_id = o.id
           WHERE ${dateCondition}
           AND ${baseStatusCondition}
           -- ✅ Removed the 'completed' filter to show full history
           ORDER BY o.created_at DESC
         `;

    const [rows] = await db.query(mainQuery);

    // 4. SUMMARY CALCULATIONS (Using baseStatusCondition to avoid Join errors)

    // Total Sales (from visible rows)
    const totalSales = rows.reduce((sum, item) => sum + (Number(item.order_amount) || 0), 0);

    // Admin Profit
    const [commRows] = await db.query(`
      SELECT COALESCE(SUM(o.total_amount * (COALESCE(ms.commission_rate,0)/100)),0) AS totalCommission
      FROM orders o
      LEFT JOIN merchant_shops ms ON ms.merchant_id = o.merchant_id
      WHERE ${dateCondition} AND ${baseStatusCondition}
    `);
    const totalCommission = Number(commRows[0].totalCommission || 0);

    // Paid Out
    const [paidRows] = await db.query("SELECT COALESCE(SUM(amount), 0) AS paidPayout FROM payout_requests WHERE status = 'completed'");
    const paidPayout = Number(paidRows[0].paidPayout || 0);

    // Wallet Balance (Pending)
    const [walletRes] = await db.query("SELECT COALESCE(SUM(balance), 0) AS currentWallets FROM merchant_wallet");
    const pendingPayout = Number(walletRes[0].currentWallets);

    res.json({
      success: true,
      summary: {
        totalSales: Number(totalSales.toFixed(2)),
        totalCommission: Number(totalCommission.toFixed(2)),
        paidPayout: Number(paidPayout.toFixed(2)),
        pendingPayout: Number(pendingPayout.toFixed(2)),
        orderCount: rows.length
      },
      data: rows
    });

  } catch (err) {
    console.error("❌ Commission Report API Error:", err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

//////////////TAX REPORT///////////////////////////////////////////////////////

app.get('/admin/reports/tax-income', authMiddleware, async (req, res) => {
  const { filter } = req.query;

  try {
    // 1. Determine Date Filter
    let dateCondition = "1=1";
    if (filter === "This Month") {
      dateCondition = "MONTH(o.created_at) = MONTH(CURRENT_DATE()) AND YEAR(o.created_at) = YEAR(CURRENT_DATE())";
    } else if (filter === "This Year") {
      dateCondition = "YEAR(o.created_at) = YEAR(CURRENT_DATE())";
    }

    // 2. Fetch Data (Handling NULLs with COALESCE)
    const query = `
      SELECT
        'Admin Commission' AS income_source,
        ROUND(COALESCE(SUM(o.total_amount * (COALESCE(ms.commission_rate, 0) / 100)), 0), 2) AS total_income,
        ROUND(COALESCE(SUM((o.total_amount * (COALESCE(ms.commission_rate, 0) / 100)) * 0.06), 0), 2) AS tax_amount
      FROM orders o
      LEFT JOIN merchant_shops ms ON o.merchant_id = ms.merchant_id
      WHERE LOWER(o.status) IN ('delivered', 'success', 'completed', 'paid')
      AND ${dateCondition}
    `;

    const [rows] = await db.query(query);
    const result = rows[0];

    // 3. Prepare Response
    res.json({
      success: true,
      summary: {
        totalIncome: (Number(result.total_income) || 0).toFixed(2),
        totalTax: (Number(result.tax_amount) || 0).toFixed(2),
      },
      data: [{
        income_source: result.income_source,
        total_income: (Number(result.total_income) || 0).toFixed(2),
        tax_amount: (Number(result.tax_amount) || 0).toFixed(2),
      }]
    });

  } catch (err) {
    console.error("❌ SQL Error:", err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// FETCH Admin Profile
app.get('/admin/me', authMiddleware, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, name, phone, email, avatar, role FROM users WHERE id = ?`,
      [req.userId]
    );

    if (rows.length === 0) return res.status(404).json({ message: "Admin not found" });

    // Ensure we send back an object, just like your merchant logic
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ message: "Server error fetching profile" });
  }
});

// UPDATE Admin Profile
app.put('/admin/me', authMiddleware, upload.single('avatar'), async (req, res) => {
  try {
    const { name, email, phone } = req.body;
    const userId = req.userId;

    // 1. Log incoming data to your terminal to see if it's arriving
    console.log("Update requested for user:", userId, "Data:", req.body);

    let sql = "UPDATE users SET name = ?, email = ?, phone = ?";
    let params = [name, email, phone];

    if (req.file) {
      console.log("File detected:", req.file.filename);
   const avatarUrl = `https://${req.get('host')}/uploads/${req.file.filename}`;


      sql += ", avatar = ?";
      params.push(avatarUrl);
    }

    sql += " WHERE id = ?";
    params.push(userId);

    // 2. Execute Update
    await db.query(sql, params);

    // 3. Fetch fresh data using [rows] destructuring correctly
    const [freshRows] = await db.query(
      "SELECT id, name, email, phone, avatar, role FROM users WHERE id = ?",
      [userId]
    );

    if (freshRows.length > 0) {
      // freshRows[0] is the user object
      res.json(freshRows[0]);
    } else {
      res.status(404).json({ message: "User not found after update" });
    }

  } catch (err) {
    // 🔥 This prevents the HTML error. It sends JSON instead.
    console.error("DATABASE ERROR:", err.message);
    res.status(500).json({
      message: "Database error",
      error: err.message
    });
  }
});



app.put('/auth/change-password', authMiddleware, async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  const userId = req.userId;

  // 1. Fetch the hashed password from DB
  const [user] = await db.query("SELECT password FROM users WHERE id = ?", [userId]);

  // 2. Compare old password
  const match = await bcrypt.compare(oldPassword, user[0].password);
  if (!match) return res.status(401).json({ message: "Current password is incorrect" });

  // 3. Hash new password and update
  const hashed = await bcrypt.hash(newPassword, 10);
  await db.query("UPDATE users SET password = ? WHERE id = ?", [hashed, userId]);

  res.json({ message: "Password updated successfully" });
});


// 1. ENDPOINT TO SAVE THE FCM TOKEN INTO MYSQL
app.post("/api/save-token", authMiddleware, async (req, res) => {
  try {
    const { fcmToken } = req.body;

    // AuthMiddleware provides this identity object dynamically
    const userId = req.user.id;

    if (!fcmToken) return res.status(400).json({ error: "Token payload missing" });

    // This updates the user's record regardless of whether their role is 'user' or 'merchant'
    const sql = "UPDATE users SET fcmToken = ? WHERE id = ?";

    await db.query(sql, [fcmToken, userId]);

    console.log(`[SQL Sync] Token assigned to profile row ID ${userId}`);
    return res.status(200).json({ success: true, message: "Device registered." });

  } catch (e) {
    console.error("Token registration failed:", e.message);
    return res.status(500).json({ error: e.message });
  }
});

app.get("/api/save-token/:userId", async (req, res) => {
  try {
    const userId = req.params.userId;

    // 1. Fetch token from DB
    const [rows] = await db.query(
      "SELECT fcmToken FROM users WHERE id = ?",
      [userId]
    );

    const fcmToken = rows[0]?.fcmToken;

    if (!fcmToken) {
      return res.status(404).json({
        message: "No FCM token found for this user",
      });
    }

    // 2. Send push notification
    const response = await admin.messaging().send({
      token: fcmToken,

      notification: {
        title: "🔥 Backend FCM Test",
        body: "Notification sent using stored DB token!",
      },

      data: {
        type: "test",
        userId: String(userId),
      },
    });

    console.log("✅ FCM SENT:", response);

    return res.json({
      success: true,
      message: "Notification sent",
      response,
    });

  } catch (err) {
    console.log("❌ FCM ERROR:", err.message);

    return res.status(500).json({
      error: err.message,
    });
  }
});
// 2. ENDPOINT FOR ADMIN TO BROADCAST NOTIFICATIONS
app.post(
  "/admin/send-notification",

  authMiddleware,
  upload.single("image"),
  async (req, res) => {
  try {
  const { title, body, target, userId } = req.body;
   let imageUrl = null;

   if (req.file) {
     imageUrl =
       `https://${req.get("host")}/uploads/${req.file.filename}`;

     console.log("IMAGE URL:", imageUrl);
   }
await db.query(
  `
  INSERT INTO notifications
  (title, body, target, imageUrl)
  VALUES (?, ?, ?, ?)
  `,
  [title, body, target, imageUrl]
);
    let targetTokens = [];

    // ✅ CASE 1: Specific User
    if (target === "Specific User") {
      if (!userId) {
        return res.status(400).json({ error: "userId required for Specific User" });
      }

      const [rows] = await db.query(
        "SELECT fcmToken FROM users WHERE id = ? AND fcmToken IS NOT NULL AND fcmToken != ''",
        [userId]
      );

      targetTokens = rows.map(r => r.fcmToken);
    }

    // ✅ CASE 2: All Users
    else if (target === "All Users") {
      const [rows] = await db.query(
        "SELECT fcmToken FROM users WHERE role = 'user' AND fcmToken IS NOT NULL AND fcmToken != ''"
      );
      targetTokens = rows.map(r => r.fcmToken);
    }

    // ✅ CASE 3: All Merchants
    else if (target === "All Merchants") {
      const [rows] = await db.query(
        "SELECT fcmToken FROM users WHERE role = 'merchant' AND fcmToken IS NOT NULL AND fcmToken != ''"
      );
      targetTokens = rows.map(r => r.fcmToken);
    }

    else {
      return res.status(400).json({ error: "Invalid target group" });
    }

    if (!targetTokens.length) {
      return res.status(200).json({
        success: false,
        message: "No FCM tokens found"
      });
    }

    // 🔥 Build message
    const baseMessage = {
      notification: {
        title,
        body,
        image: imageUrl || undefined,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          image: imageUrl || undefined,
        },
      },
      apns: {
        payload: {
          aps: {
            "mutable-content": 1,
          },
        },
        fcmOptions: {
          imageUrl: imageUrl,
        },
      },
      webpush: {
        notification: {
          title,
          body,
          image: imageUrl,   // ✅ correct for web
        },
      },
    };

    // 🔥 Send individually (best practice)
    const sendPromises = targetTokens.map(token =>
      admin.messaging().send({
        ...baseMessage,
        token
      }).then(() => true).catch(() => false)
    );

    const results = await Promise.all(sendPromises);

    const successCount = results.filter(r => r).length;

    return res.status(200).json({
      success: true,
      sentCount: successCount,
      total: targetTokens.length
    });

  } catch (error) {
    console.error("Notification Error:", error);
    return res.status(500).json({ error: error.message });
  }
});

app.get("/admin/notifications", authMiddleware, async (req, res) => {
  try {

    const [rows] = await db.query(
      "SELECT * FROM notifications ORDER BY id DESC"
    );

    res.status(200).json(rows);

  } catch (e) {
    res.status(500).json({
      error: e.message,
    });
  }
});


app.delete("/admin/notifications/:id", authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;

    await db.query(
      "DELETE FROM notifications WHERE id = ?",
      [id]
    );

    return res.status(200).json({
      success: true,
      message: "Notification deleted"
    });

  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});


module.exports = app;

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`🚀 Server actually started on port ${PORT}`);
});

