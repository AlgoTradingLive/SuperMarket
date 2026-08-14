const express = require("express");
const router = express.Router();

// GET /api/products?section=...&subCategory=...&search=...&deals=true
router.get("/", async (req, res) => {
  const db = req.app.locals.db;
  const { section, subCategory, category, search, deals } = req.query;
  const sectionFilter = section || category;

  const query = {};
  if (sectionFilter && sectionFilter !== "All") query.section = sectionFilter;
  if (subCategory) query.subCategory = subCategory;
  if (search) query.name = { $regex: search, $options: "i" };
  // deals=true: only products with a real discount (mrp > price > 0) — used
  // by the home screen so it doesn't have to download the whole (now much
  // larger, after the brand-bundle imports) catalog just to find a handful
  // of discounted items.
  if (deals === "true") {
    query.$expr = { $and: [{ $gt: ["$mrp", "$price"] }, { $gt: ["$mrp", 0] }, { $gt: ["$price", 0] }] };
  }

  const products = await db.collection("products").find(query, { projection: { _id: 0 } }).toArray();
  res.json(products);
});

// GET /api/products/categories -> सगळे sections ("All" सकट)
router.get("/categories", async (req, res) => {
  const db = req.app.locals.db;
  const sections = await db.collection("products").distinct("section");
  res.json(["All", ...sections]);
});

// GET /api/products/:id
router.get("/:id", async (req, res) => {
  const db = req.app.locals.db;
  const product = await db
    .collection("products")
    .findOne({ id: Number(req.params.id) }, { projection: { _id: 0 } });
  if (!product) return res.status(404).json({ error: "Product not found" });
  res.json(product);
});

module.exports = router;
