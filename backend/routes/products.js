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

// GET /api/products/related?name=...&subCategory=...&excludeId=...
// "You might like" — matches by the PRODUCT TYPE (keywords from its name +
// subCategory), across ALL brands/sections. A plain exact-subCategory match
// only ever finds the same brand, because every imported brand names its
// subCategory differently for the same kind of product (e.g. Tata calls it
// "Dal", Patanjali calls it "Dal Pulses", Amul calls it "Organic Dal") — so
// "Tata Toor Dal" would only ever show more Tata products. This instead
// pulls out meaningful words ("toor", "dal") and searches every brand's
// name/subCategory for them, so Patanjali/other brands' dal shows up too.
const RELATED_STOP_WORDS = new Set([
  "organic", "unpolished", "polished", "whole", "natural", "premium", "pure",
  "fresh", "pack", "combo", "trial", "of", "the", "and", "kg", "g", "gm",
  "ml", "l", "pc", "pcs", "piece", "pieces", "set",
]);
router.get("/related", async (req, res) => {
  const db = req.app.locals.db;
  const { name, subCategory, excludeId } = req.query;
  const text = `${subCategory || ""} ${name || ""}`.toLowerCase();
  const words = text
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter((w) => w.length > 2 && !RELATED_STOP_WORDS.has(w) && Number.isNaN(Number(w)));
  const keywords = [...new Set(words)];
  if (keywords.length === 0) return res.json([]);

  const regexes = keywords.map((w) => new RegExp(w, "i"));
  const query = {
    $or: [{ name: { $in: regexes } }, { subCategory: { $in: regexes } }],
  };
  if (excludeId) query.id = { $ne: Number(excludeId) };

  const products = await db
    .collection("products")
    .find(query, { projection: { _id: 0 } })
    .limit(30)
    .toArray();
  res.json(products);
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
