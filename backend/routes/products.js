const express = require("express");
const fs = require("fs");
const path = require("path");

const router = express.Router();
const DATA_FILE = path.join(__dirname, "..", "data", "products.json");

function readProducts() {
  return JSON.parse(fs.readFileSync(DATA_FILE, "utf-8"));
}

// GET /api/products?category=Grocery&search=rice
router.get("/", (req, res) => {
  let products = readProducts();
  const { category, search } = req.query;

  if (category && category !== "All") {
    products = products.filter((p) => p.category === category);
  }
  if (search) {
    const q = search.toLowerCase();
    products = products.filter((p) => p.name.toLowerCase().includes(q));
  }
  res.json(products);
});

// GET /api/products/categories
router.get("/categories", (req, res) => {
  const products = readProducts();
  const categories = ["All", ...new Set(products.map((p) => p.category))];
  res.json(categories);
});

// GET /api/products/:id
router.get("/:id", (req, res) => {
  const products = readProducts();
  const product = products.find((p) => p.id === Number(req.params.id));
  if (!product) return res.status(404).json({ error: "Product not found" });
  res.json(product);
});

module.exports = router;
