const express = require("express");
const path = require("path");
const fs = require("fs");
const https = require("https");
const multer = require("multer");
const { sendPushToPhone } = require("../utils/notify");

const router = express.Router();
const ADMIN_KEY = process.env.ADMIN_KEY || "supermarket123";
const GITHUB_TOKEN = process.env.GITHUB_TOKEN || "";
const GITHUB_REPO = "AlgoTradingLive/SuperMarket";
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 8 * 1024 * 1024 } });

function checkAdmin(req, res, next) {
  const key = req.headers["x-admin-key"];
  if (key !== ADMIN_KEY) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  next();
}

function fetchJSON(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, { headers: { "User-Agent": "SuperMarketApp - Android - Version 1.0" } }, (resp) => {
        let data = "";
        resp.on("data", (chunk) => (data += chunk));
        resp.on("end", () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(e);
          }
        });
      })
      .on("error", reject);
  });
}

// Commit an image file to the GitHub repo so it's served permanently via jsDelivr CDN.
function commitImageToGitHub(filename, base64Content) {
  return new Promise((resolve, reject) => {
    if (!GITHUB_TOKEN) return reject(new Error("GITHUB_TOKEN not configured on server"));
    const repoPath = `mobile/assets/products/${filename}`;
    const body = JSON.stringify({
      message: `Add product photo: ${filename}`,
      content: base64Content,
      branch: "main",
    });
    const options = {
      hostname: "api.github.com",
      path: `/repos/${GITHUB_REPO}/contents/${repoPath}`,
      method: "PUT",
      headers: {
        "Authorization": `token ${GITHUB_TOKEN}`,
        "User-Agent": "SuperMarketAdmin",
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body),
      },
    };
    const req = https.request(options, (resp) => {
      let data = "";
      resp.on("data", (c) => (data += c));
      resp.on("end", () => {
        try {
          const json = JSON.parse(data);
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            resolve(`https://cdn.jsdelivr.net/gh/${GITHUB_REPO}@main/${repoPath}`);
          } else {
            reject(new Error(json.message || "GitHub upload failed"));
          }
        } catch (e) {
          reject(e);
        }
      });
    });
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

// POST /api/admin/upload-image
router.post("/upload-image", checkAdmin, upload.single("image"), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: "No file uploaded" });
  try {
    const ext = path.extname(req.file.originalname) || ".jpg";
    const safeName = Date.now() + "-" + Math.random().toString(36).slice(2, 8) + ext.toLowerCase();
    const base64 = req.file.buffer.toString("base64");
    const url = await commitImageToGitHub(safeName, base64);
    res.json({ url });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/admin/off-search?q=Everest
router.get("/off-search", checkAdmin, async (req, res) => {
  const q = req.query.q;
  if (!q) return res.status(400).json({ error: "q required" });
  try {
    const url = `https://world.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(
      q
    )}&json=1&page_size=30&fields=product_name,brands,quantity,image_front_url,code`;
    const data = await fetchJSON(url);
    const results = (data.products || [])
      .filter((p) => p.product_name && p.image_front_url)
      .map((p) => ({
        name: p.product_name,
        brand: p.brands || "",
        quantity: p.quantity || "",
        image: p.image_front_url,
        code: p.code,
      }));
    res.json(results);
  } catch (e) {
    res.status(500).json({ error: "Search failed: " + e.message });
  }
});

// GET /api/admin/products -> full list
router.get("/products", checkAdmin, async (req, res) => {
  const db = req.app.locals.db;
  const products = await db.collection("products").find({}, { projection: { _id: 0 } }).toArray();
  res.json(products);
});

// GET /api/admin/subcategories
router.get("/subcategories", checkAdmin, async (req, res) => {
  const db = req.app.locals.db;
  const subs = await db.collection("subcategories").find({}, { projection: { _id: 0 } }).toArray();
  res.json(subs);
});

// PUT /api/admin/subcategories/:id -> edit icon/name of a category
router.put("/subcategories/:id", checkAdmin, async (req, res) => {
  const db = req.app.locals.db;
  const update = { ...req.body };
  delete update.id;
  delete update._id;
  const result = await db
    .collection("subcategories")
    .findOneAndUpdate(
      { id: Number(req.params.id) },
      { $set: update },
      { returnDocument: "after", projection: { _id: 0 } }
    );
  if (!result || !result.value) return res.status(404).json({ error: "Not found" });
  res.json(result.value);
});

// POST /api/admin/products -> add a new product
router.post("/products", checkAdmin, async (req, res) => {
  const db = req.app.locals.db;
  const { name, subCategory, section, price, mrp, unit, image } = req.body;
  if (!name || !subCategory || !section || !unit || !image) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  const last = await db.collection("products").find().sort({ id: -1 }).limit(1).toArray();
  const newId = last.length ? last[0].id + 1 : 1;

  const product = {
    id: newId,
    name,
    subCategory,
    section,
    price: Number(price) || 0,
    mrp: Number(mrp) || Number(price) || 0,
    unit,
    image,
    inStock: true,
  };
  await db.collection("products").insertOne(product);
  const { _id, ...clean } = product;
  res.status(201).json(clean);
});

// PUT /api/admin/products/:id -> edit
router.put("/products/:id", checkAdmin, async (req, res) => {
  const db = req.app.locals.db;
  const id = Number(req.params.id);
  const update = { ...req.body };
  delete update.id;
  delete update._id;

  const result = await db.collection("products").findOneAndUpdate(
    { id },
    { $set: update },
    { returnDocument: "after", projection: { _id: 0 } }
  );
  if (!result || !result.value) {
    const existing = await db.collection("products").findOne({ id }, { projection: { _id: 0 } });
    if (!existing) return res.status(404).json({ error: "Not found" });
    return res.json(existing);
  }
  res.json(result.value);
});

// DELETE /api/admin/products/:id
router.delete("/products/:id", checkAdmin, async (req, res) => {
  const db = req.app.locals.db;
  const result = await db.collection("products").deleteOne({ id: Number(req.params.id) });
  if (result.deletedCount === 0) return res.status(404).json({ error: "Not found" });
  res.json({ deleted: true });
});

// GET /api/admin/orders -> full order list, newest first
router.get("/orders", checkAdmin, async (req, res) => {
  const db = req.app.locals.db;
  const orders = await db
    .collection("orders")
    .find({}, { projection: { _id: 0 } })
    .sort({ id: -1 })
    .toArray();
  res.json(orders);
});

// PUT /api/admin/orders/:id -> manually override status (e.g. "Cancelled", "Delivered")
router.put("/orders/:id", checkAdmin, async (req, res) => {
  const db = req.app.locals.db;
  const { status } = req.body;
  if (!status) return res.status(400).json({ error: "status required" });
  const result = await db
    .collection("orders")
    .findOneAndUpdate(
      { id: Number(req.params.id) },
      { $set: { status, manualStatus: true } },
      { returnDocument: "after", projection: { _id: 0 } }
    );
  if (!result || !result.value) return res.status(404).json({ error: "Not found" });

  const order = result.value;
  sendPushToPhone(
    db,
    order.phone,
    "Order Update",
    `Your order #${order.id} is now "${status}"`
  );

  res.json(order);
});

// POST /api/admin/import-bundle  { bundle: "amul" | "patanjali" | "tata" | "nutraj" | "morebrands" }
// Bulk-imports a pre-prepared brand product dataset (bundled JSON files
// shipped with the backend) into a dedicated top-level "section" for that brand.
router.post("/import-bundle", checkAdmin, async (req, res) => {
  const db = req.app.locals.db;
  const { bundle } = req.body;
  const DATA_DIR = path.join(__dirname, "..", "data");

  try {
    let rawProducts = [];
    let sectionName = "";

    if (bundle === "amul") {
      sectionName = "Amul";
      const p1 = JSON.parse(fs.readFileSync(path.join(DATA_DIR, "amul_products_part1.json"), "utf-8"));
      const p2 = JSON.parse(fs.readFileSync(path.join(DATA_DIR, "amul_products_part2.json"), "utf-8"));
      rawProducts = [...p1, ...p2].map((p) => ({
        name: p.name,
        subCategory: p.section, // Amul's "section" field is the finer grouping (Milk, Protein, etc.)
        section: sectionName,
        price: p.price,
        mrp: p.mrp,
        unit: p.unit,
        image: p.image,
        inStock: p.inStock !== false,
      }));
    } else if (bundle === "patanjali") {
      sectionName = "Patanjali";
      const products = JSON.parse(fs.readFileSync(path.join(DATA_DIR, "patanjali_all_products.json"), "utf-8"));
      rawProducts = products.map((p) => ({
        name: p.name,
        subCategory: p.subCategory,
        section: sectionName,
        price: p.price,
        mrp: p.mrp,
        unit: p.unit,
        image: p.image,
        inStock: p.inStock !== false,
      }));
    } else if (bundle === "tata") {
      sectionName = "Tata NutriKorner";
      const products = JSON.parse(fs.readFileSync(path.join(DATA_DIR, "tata_nutrikorner_products.json"), "utf-8"));
      rawProducts = products.map((p) => ({
        name: p.name,
        subCategory: p.section, // Tata's "section" field is the broad grouping (Tea, Masala, Ghee, etc.)
        section: sectionName,
        price: p.price,
        mrp: p.mrp,
        unit: p.unit,
        image: p.image,
        inStock: p.inStock !== false,
      }));
    } else if (bundle === "nutraj") {
      sectionName = "Nutraj";
      const products = JSON.parse(fs.readFileSync(path.join(DATA_DIR, "nutraj_products_clean.json"), "utf-8"));
      rawProducts = products.map((p) => ({
        name: p.name,
        subCategory: p.section, // Nutraj's "section" field is the broad grouping (Walnuts, Almonds, Pistachio, etc.)
        section: sectionName,
        price: p.price,
        mrp: p.mrp,
        unit: p.unit,
        image: p.image,
        inStock: p.inStock !== false,
      }));
    } else if (bundle === "morebrands") {
      sectionName = "More Brands";
      const master = JSON.parse(fs.readFileSync(path.join(DATA_DIR, "master_catalog.json"), "utf-8"));
      const excludeSections = ["Natural Food Products", "Natural Personal Care"]; // already imported as Patanjali
      rawProducts = master
        .filter((p) => !excludeSections.includes(p.section) && p.image)
        .map((p) => ({
          name: p.name,
          subCategory: p.section, // brand name (Suhana Masale, Vatika, Saffola, etc.)
          section: sectionName,
          price: p.price,
          mrp: p.mrp,
          unit: p.unit,
          image: p.image,
          inStock: p.inStock !== false,
        }));
    } else {
      return res.status(400).json({ error: "bundle must be 'amul', 'patanjali', 'tata', 'nutraj', or 'morebrands'" });
    }

    // Skip products that already exist in this section (by name, case-insensitive)
    // so re-running the import (e.g. after a bigger file was added) doesn't duplicate.
    const existingProducts = await db
      .collection("products")
      .find({ section: sectionName })
      .toArray();
    const existingProductNames = new Set(existingProducts.map((p) => p.name.trim().toLowerCase()));
    rawProducts = rawProducts.filter((p) => !existingProductNames.has(p.name.trim().toLowerCase()));

    // Assign fresh sequential ids continuing from current max
    const lastProduct = await db.collection("products").find().sort({ id: -1 }).limit(1).toArray();
    let nextId = lastProduct.length ? lastProduct[0].id + 1 : 1;
    const productsToInsert = rawProducts.map((p) => ({ id: nextId++, ...p }));

    // Build subcategory entries (dedup by name+section) with an icon
    // taken from the first product in that group.
    const subcatMap = new Map();
    for (const p of productsToInsert) {
      const key = `${p.subCategory}|${p.section}`;
      if (!subcatMap.has(key)) {
        subcatMap.set(key, { name: p.subCategory, section: p.section, icon: p.image });
      }
    }
    const existingSubcats = await db
      .collection("subcategories")
      .find({ section: sectionName })
      .toArray();
    const existingNames = new Set(existingSubcats.map((s) => s.name));
    const newSubcats = [...subcatMap.values()].filter((s) => !existingNames.has(s.name));

    const lastSubcat = await db.collection("subcategories").find().sort({ id: -1 }).limit(1).toArray();
    let nextSubId = lastSubcat.length ? lastSubcat[0].id + 1 : 1;
    const subcatsToInsert = newSubcats.map((s) => ({ id: nextSubId++, ...s }));

    if (productsToInsert.length) await db.collection("products").insertMany(productsToInsert);
    if (subcatsToInsert.length) await db.collection("subcategories").insertMany(subcatsToInsert);

    res.json({
      section: sectionName,
      productsAdded: productsToInsert.length,
      subcategoriesAdded: subcatsToInsert.length,
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/admin/reclassify-brands
// Moves products currently grouped under brand-only sections (Amul, Patanjali,
// Tata NutriKorner) into our regular category taxonomy (e.g. Personal Care,
// Dairy, Masala & Spices) so all brands mix together under one category,
// instead of each brand having its own separate section.
router.post("/reclassify-brands", checkAdmin, async (req, res) => {
  const db = req.app.locals.db;

  // Map: current subCategory (as imported) -> { section, subCategory } in our app taxonomy.
  // Reuses existing categories wherever a good match exists; a few new ones are
  // introduced only where nothing suitable already existed.
  const MAP = {
    // ---- Patanjali ----
    "Edible Oil": { section: "Grocery & Kitchen", subCategory: "Edible Oil & Ghee" },
    "Flours": { section: "Grocery & Kitchen", subCategory: "Flours & Atta" },
    "Dal Pulses": { section: "Grocery & Kitchen", subCategory: "Pulses" },
    "Candy": { section: "Snacking & Munching", subCategory: "Chocolates Candies & Jellys" },
    "Biscuits and Cookies": { section: "Snacking & Munching", subCategory: "Biscuits & Cookies" },
    "Spices": { section: "Grocery & Kitchen", subCategory: "Masala & Spices" },
    "Herbal Tea": { section: "Grocery & Kitchen", subCategory: "Tea & Coffee" },
    "Tea": { section: "Grocery & Kitchen", subCategory: "Tea & Coffee" },
    "Jam": { section: "Daily Essentials", subCategory: "Jam & Spreads" },
    "Dalia, Poha and Vermicelli": { section: "Grocery & Kitchen", subCategory: "Cereals & Millets" },
    "Dried Fruits & Nuts": { section: "Grocery & Kitchen", subCategory: "Dry Fruits & Nuts" },
    "Tooth Brush": { section: "Daily Essentials", subCategory: "Personal Care" },
    "Toothpaste": { section: "Daily Essentials", subCategory: "Personal Care" },
    "Face Cream": { section: "Daily Essentials", subCategory: "Personal Care" },
    "Body Care": { section: "Daily Essentials", subCategory: "Personal Care" },
    "Face Wash": { section: "Daily Essentials", subCategory: "Personal Care" },
    "Foot Cream": { section: "Daily Essentials", subCategory: "Personal Care" },
    "Hair Oil": { section: "Daily Essentials", subCategory: "Personal Care" },
    "Scrubs": { section: "Daily Essentials", subCategory: "Personal Care" },
    "Face Pack": { section: "Daily Essentials", subCategory: "Personal Care" },
    "Conditioner": { section: "Daily Essentials", subCategory: "Personal Care" },
    "Shampoo": { section: "Daily Essentials", subCategory: "Personal Care" },
    // ---- Amul (their "section" field became our subCategory on import) ----
    "Milk": { section: "Daily Essentials", subCategory: "Dairy" },
    "Fresh Cream": { section: "Daily Essentials", subCategory: "Dairy" },
    "Panchamrit": { section: "Daily Essentials", subCategory: "Dairy" },
    "Milk Powders": { section: "Daily Essentials", subCategory: "Dairy" },
    "Camel Milk": { section: "Daily Essentials", subCategory: "Dairy" },
    "Ghee": { section: "Grocery & Kitchen", subCategory: "Edible Oil & Ghee" },
    "Protein": { section: "Daily Essentials", subCategory: "Health & Protein" },
    "Organic": { section: "Grocery & Kitchen", subCategory: "Organic Products" },
    "Kitchen Essentials": { section: "Grocery & Kitchen", subCategory: "Kitchen Essentials" },
    "Tea & Snacks": { section: "Daily Essentials", subCategory: "Beverages" },
    "Beverages": { section: "Daily Essentials", subCategory: "Beverages" },
    "Chocolates": { section: "Snacking & Munching", subCategory: "Chocolates Candies & Jellys" },
    "Sweets": { section: "Snacking & Munching", subCategory: "Chocolates Candies & Jellys" },
    "Cake": { section: "Daily Essentials", subCategory: "Bakery" },
    "Infant Food": { section: "Daily Essentials", subCategory: "Baby Care" },
    // ---- Tata NutriKorner (their "section" field became our subCategory on import) ----
    "Tea Coffee & Beverages": { section: "Grocery & Kitchen", subCategory: "Tea & Coffee" },
    "Instant Foods": { section: "Snacking & Munching", subCategory: "Instant Foods" },
    "Dry Fruits & Seeds": { section: "Grocery & Kitchen", subCategory: "Dry Fruits & Nuts" },
    "Masala & Spices": { section: "Grocery & Kitchen", subCategory: "Masala & Spices" },
    "Atta Rice & Dal": { section: "Grocery & Kitchen", subCategory: "Cereals & Millets" },
    "Oils & Ghee": { section: "Grocery & Kitchen", subCategory: "Edible Oil & Ghee" },
    "Sauces & Spreads": { section: "Grocery & Kitchen", subCategory: "Sauces & Spreads" },
    "Breakfast Essentials": { section: "Snacking & Munching", subCategory: "Breakfast Cereals" },
  };

  const BRAND_SECTIONS = ["Amul", "Patanjali", "Tata NutriKorner"];
  const products = await db.collection("products").find({ section: { $in: BRAND_SECTIONS } }).toArray();

  let updated = 0;
  let skipped = 0;
  const touchedSubcats = new Set(); // "subCategory|section"

  for (const p of products) {
    const target = MAP[p.subCategory];
    if (!target) {
      skipped++;
      continue;
    }
    await db.collection("products").updateOne(
      { id: p.id },
      { $set: { section: target.section, subCategory: target.subCategory } }
    );
    touchedSubcats.add(`${target.subCategory}|${target.section}`);
    updated++;
  }

  // Make sure every target subcategory actually exists (for the home screen icon grid)
  const existingSubcats = await db.collection("subcategories").find({}).toArray();
  const existingKeys = new Set(existingSubcats.map((s) => `${s.name}|${s.section}`));
  const lastSubcat = await db.collection("subcategories").find().sort({ id: -1 }).limit(1).toArray();
  let nextSubId = lastSubcat.length ? lastSubcat[0].id + 1 : 1;

  const newSubcats = [];
  for (const key of touchedSubcats) {
    if (!existingKeys.has(key)) {
      const [name, section] = key.split("|");
      // use any already-reclassified product's image in this subcategory as the icon
      const sample = await db.collection("products").findOne({ subCategory: name, section });
      newSubcats.push({ id: nextSubId++, name, section, icon: sample ? sample.image : "" });
    }
  }
  if (newSubcats.length) await db.collection("subcategories").insertMany(newSubcats);

  // Remove the now-empty brand-only subcategory entries (Amul/Patanjali/Tata NutriKorner)
  const removed = await db.collection("subcategories").deleteMany({ section: { $in: BRAND_SECTIONS } });

  res.json({
    productsUpdated: updated,
    productsSkipped: skipped,
    newSubcategoriesCreated: newSubcats.length,
    oldBrandSubcategoriesRemoved: removed.deletedCount,
  });
});

module.exports = router;
