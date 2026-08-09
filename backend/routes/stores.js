const express = require("express");
const fs = require("fs");
const path = require("path");

const router = express.Router();
const STORES_FILE = path.join(__dirname, "..", "data", "stores.json");

// GET /api/stores -> list all offline stores
router.get("/", (req, res) => {
  const stores = JSON.parse(fs.readFileSync(STORES_FILE, "utf-8"));
  res.json(stores);
});

module.exports = router;
