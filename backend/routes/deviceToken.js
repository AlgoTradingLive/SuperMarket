const express = require("express");
const router = express.Router();

// POST /api/device-token  { phone, token } -> save/refresh a push token for a phone number
router.post("/", async (req, res) => {
  const db = req.app.locals.db;
  const { phone, token } = req.body;
  if (!phone || !token) {
    return res.status(400).json({ error: "phone and token required" });
  }
  await db.collection("deviceTokens").updateOne(
    { token },
    { $set: { phone, token, updatedAt: new Date().toISOString() } },
    { upsert: true }
  );
  res.json({ ok: true });
});

module.exports = router;
