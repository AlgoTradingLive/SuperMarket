const express = require("express");
const fs = require("fs");
const path = require("path");

const router = express.Router();
const DATA_FILE = path.join(__dirname, "..", "data", "products.json");

function readProducts() {
  return JSON.parse(fs.readFileSync(DATA_FILE, "utf-8"));
}

// GET /api/products?section=Grocery & Kitchen&subCategory=Pulses&search=dal
router.get("/", (req, res) => {
  let products = readProducts();
  const { section, subCategory, category, search } = req.query;

  // 'category' जुनं नाव - backward compatibility साठी 'section' सारखंच वापरतो
  const sectionFilter = section || category;

  if (sectionFilter && sectionFilter !== "All") {
    products = products.filter((p) => p.section === sectionFilter);
  }
  if (subCategory) {
    products = products.filter((p) => p.subCategory === subCategory);
  }
  if (search) {
    const q = search.toLowerCase();
    products = products.filter((p) => p.name.toLowerCase().includes(q));
  }
  res.json(products);
});

// GET /api/products/categories -> सगळे sections ("All" सकट)
router.get("/categories", (req, res) => {
  const products = readProducts();
  const sections = ["All", ...new Set(products.map((p) => p.section))];
  res.json(sections);
});

// GET /api/products/:id
router.get("/:id", (req, res) => {
  const products = readProducts();
  const product = products.find((p) => p.id === Number(req.params.id));
  if (!product) return res.status(404).json({ error: "Product not found" });
  res.json(product);
});

module.exports = router;
