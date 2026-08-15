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
// Moves products currently sitting under brand-only sections (Amul, Patanjali,
// Tata NutriKorner, Nutraj, More Brands) into our regular category taxonomy
// (Tea & Coffee, Pulses, Personal Care, etc.) so every brand's tea/coffee,
// dal, masala etc. shows up mixed together under ONE category — instead of
// each brand only ever showing its own products.
//
// Classification is done from the PRODUCT NAME (not the imported subCategory
// field), because that field means different things per source: Amul/Tata's
// is a real product-type grouping, but master_catalog's ("More Brands") is
// just the manufacturer's brand name (e.g. "Suhana Masale", "Vatika") — a
// name-based keyword match is the one thing that works the same way across
// every source.
router.post("/reclassify-brands", checkAdmin, async (req, res) => {
  const db = req.app.locals.db;

  // Ordered most-specific-first — e.g. "Breakfast Cereals" (corn flakes) is
  // checked before the broad "Cereals & Millets" (atta/rice) so corn flakes
  // don't get swept into the grain aisle.
  const RULES = [
    [/dish\s?wash/i, { section: "Home Supplies", subCategory: "Dishwashers" }],
    [/detergent|fabric\s?(conditioner|softener|care)|washing\s?powder|surf\s?excel/i, { section: "Home Supplies", subCategory: "Detergent & Fabric Care" }],
    [/floor\s?clean|surface\s?clean|toilet\s?clean|\bphenyl\b|harpic|all\s?purpose\s?clean|air\s?freshener|room\s?spray|room\s?mist|odonil|bathroom\s?clean/i, { section: "Home Supplies", subCategory: "All Purpose Cleaners" }],
    [/shampoo|conditioner|toothpaste|tooth\s?brush|face\s?wash|face\s?cream|body\s?wash|body\s?lotion|hair\s?oil|\bscrub|face\s?pack|deodorant|talcum|sanitizer|\bsoap\b|skin\s?care|personal\s?care|facial\s?kit|sunscreen|\bserum\b|lipstick|nail\s?paint|\bkajal\b|\bbleach\b|hand\s?wash|hair\s?care|body\s?cleanser|shower\s?gel|eye\s?patch|fragrance|\bperfume\b|\bedp\b|moisturi[sz]/i, { section: "Daily Essentials", subCategory: "Personal Care" }],
    [/corn\s?flakes|muesli|granola|\boats\b|breakfast\s?cereal/i, { section: "Snacking & Munching", subCategory: "Breakfast Cereals" }],
    [/biscuit|cookie|\brusk\b|cracker/i, { section: "Snacking & Munching", subCategory: "Biscuits & Cookies" }],
    [/\bchips\b|wafer|namkeen|bhujia|crisps/i, { section: "Snacking & Munching", subCategory: "Chips & Crisps" }],
    [/chocolate|\bcandy\b|\bjelly\b|toffee|eclair|\bmithai\b|sweet|laddoo|jamun|peda|rosogolla|basundi/i, { section: "Snacking & Munching", subCategory: "Chocolates Candies & Jellys" }],
    [/\btea\b|\bcoffee\b|\bchai\b/i, { section: "Grocery & Kitchen", subCategory: "Tea & Coffee" }],
    [/\bsugar\b|jaggery|\bgur\b|\bhoney\b/i, { section: "Grocery & Kitchen", subCategory: "Sugar & Jaggery" }],
    [/almond|cashew|walnut|raisin|kismis|pista|dry\s?fruit|dried\s?fruit|anjeer|\bdates?\b|khajur|\bseeds?\b|makhana|\bpeanuts?\b|quinoa|munakka/i, { section: "Grocery & Kitchen", subCategory: "Dry Fruits & Nuts" }],
    [/\bdal\b|\bdaal\b|chana|moong|\btoor\b|arhar|\burad\b|masoor|rajma|\bbesan\b|pulses/i, { section: "Grocery & Kitchen", subCategory: "Pulses" }],
    [/masala|\bspice|turmeric|haldi|chilli|mirch|dhania|coriander|\bcumin\b|jeera|fennel|mustard.*rai|cardamom|fenugreek|\bhing\b|gond\s?katira|poppy\s?seed|saffron|\bkesar\b|\bsalt\b|methi/i, { section: "Grocery & Kitchen", subCategory: "Masala & Spices" }],
    [/\bghee\b|edible\s?oil|cooking\s?oil|mustard\s?oil|sunflower\s?oil|groundnut\s?oil|olive\s?oil|sesame\s?oil|coconut\s?oil|safflower|til\s?oil|\boil\b/i, { section: "Grocery & Kitchen", subCategory: "Edible Oil & Ghee" }],
    [/\bmilk\b|paneer|\bcurd\b|yogurt|\bcheese\b|\bbutter\b|\bcream\b|\blassi\b|dairy\s?whitener|dairy\s?creamer|malai/i, { section: "Daily Essentials", subCategory: "Dairy" }],
    [/\bbread\b|\bbun\b|\bcake\b|bakery/i, { section: "Daily Essentials", subCategory: "Bakery" }],
    [/\batta\b|\bflour\b|\brice\b|\bpoha\b|millet|jowar|bajra|\bragi\b|\bsuji\b|\brava\b|sooji|vermicelli|\bdalia\b|malted\s?food/i, { section: "Grocery & Kitchen", subCategory: "Cereals & Millets" }],
    [/\bsauce\b|ketchup|\bspread\b|\bjam\b|pickle|chutney|\bpaste\b|murabba|\bthecha\b|\bachar\b/i, { section: "Grocery & Kitchen", subCategory: "Sauces & Spreads" }],
    [/protein|\bwhey\b|health\s?drink|nutrition|multivitamin|collagen/i, { section: "Daily Essentials", subCategory: "Health & Protein" }],
    [/\binfant\b|\bbaby\b/i, { section: "Daily Essentials", subCategory: "Baby Care" }],
    [/instant\s?(food|noodle|soup|mix)|mashed\s?potato|\bnoodles?\b|\bramen\b/i, { section: "Snacking & Munching", subCategory: "Instant Foods" }],
    [/combo|trial\s?pack/i, { section: "Grocery & Kitchen", subCategory: "Combo Bundle" }],
    [/kool\s?drink|thandai|beverage|\bjuice\b|mojito|tonic\s?water|ginger\s?ale/i, { section: "Daily Essentials", subCategory: "Beverages" }],
  ];

  const BRAND_SECTIONS = ["Amul", "Patanjali", "Tata NutriKorner", "Nutraj", "More Brands"];
  const products = await db.collection("products").find({ section: { $in: BRAND_SECTIONS } }).toArray();

  let updated = 0;
  let skipped = 0;
  const touchedSubcats = new Set(); // "subCategory|section"

  for (const p of products) {
    // Match on the ORIGINAL imported subCategory + name together — the
    // subCategory is a real signal for Amul/Patanjali/Tata (e.g. Patanjali's
    // "Spices" subCategory catches "Cumin Whole" even though the word
    // "spice" never appears in the product name itself). For "More Brands"
    // (master_catalog) the subCategory is just the manufacturer's brand
    // name, not descriptive, so only the product name is used there.
    const text = p.section === "More Brands" ? p.name : `${p.subCategory || ""} ${p.name}`;
    const match = RULES.find(([regex]) => regex.test(text));
    if (!match) {
      skipped++;
      continue;
    }
    const target = match[1];
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

  // Remove brand-only subcategory entries that no longer have any products
  // left in them (some products may have been skipped/unmatched and stay
  // put, so only clean up ones that are now truly empty).
  const brandSubcats = await db.collection("subcategories").find({ section: { $in: BRAND_SECTIONS } }).toArray();
  let removedCount = 0;
  for (const s of brandSubcats) {
    const stillHasProducts = await db.collection("products").countDocuments({ subCategory: s.name, section: s.section });
    if (stillHasProducts === 0) {
      await db.collection("subcategories").deleteOne({ id: s.id });
      removedCount++;
    }
  }

  res.json({
    productsUpdated: updated,
    productsSkipped: skipped,
    newSubcategoriesCreated: newSubcats.length,
    oldBrandSubcategoriesRemoved: removedCount,
  });
});

module.exports = router;
