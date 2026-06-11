// routes/orderRoutes.js
const express = require("express");

// ✅ FIX: Use native Express Router instead of the standalone 'router' library instance
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const orderController = require("../controllers/orderController");

// Ensure native middleware parsing is attached directly to this route context container
router.use(express.json());
router.use(express.urlencoded({ extended: true }));

// Clean, native route definition mapping
router.post("/", authMiddleware, orderController.createOrder);

module.exports = router;
