const express = require("express");
const router = express.Router();

// GET /api/stores -> list all offline stores
router.get("/", async (req, res) => {
  const db = req.app.locals.db;
  const stores = await db.collection("stores").find({}, { projection: { _id: 0 } }).toArray();
  res.json(stores);
});

module.exports = router;
