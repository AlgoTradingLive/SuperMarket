const express = require("express");
const fs = require("fs");
const path = require("path");

const router = express.Router();
const DATA_FILE = path.join(__dirname, "..", "data", "subcategories.json");

function readSubcategories() {
  return JSON.parse(fs.readFileSync(DATA_FILE, "utf-8"));
}

// GET /api/subcategories -> सगळ्या subcategories, section नुसार गटबद्ध
router.get("/", (req, res) => {
  const subs = readSubcategories();
  const grouped = {};
  subs.forEach((s) => {
    if (!grouped[s.section]) grouped[s.section] = [];
    grouped[s.section].push(s);
  });
  res.json(grouped);
});

module.exports = router;
