const jwt = require("jsonwebtoken");

const SECRET_KEY = process.env.JWT_SECRET;

function authMiddleware(req, res, next) {

  const authHeader = req.headers.authorization;

  console.log("🔐 AUTH HEADER:", authHeader);

  if (!authHeader) {
    return res.status(401).json({
      message: "No token provided"
    });
  }

  const token = authHeader.split(" ")[1];

  try {

    const decoded = jwt.verify(token, SECRET_KEY);

    req.userId = decoded.id;
    req.user = decoded;

    next();

  } catch (err) {

    return res.status(401).json({
      message: "Invalid token"
    });
  }
}

module.exports = authMiddleware;