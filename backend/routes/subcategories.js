const express = require("express");
const router = express.Router();

// GET /api/subcategories -> सगळ्या subcategories, section नुसार गटबद्ध
router.get("/", async (req, res) => {
  const db = req.app.locals.db;
  const subs = await db.collection("subcategories").find({}, { projection: { _id: 0 } }).toArray();
  const grouped = {};
  subs.forEach((s) => {
    if (!grouped[s.section]) grouped[s.section] = [];
    grouped[s.section].push(s);
  });
  res.json(grouped);
});

module.exports = router;
