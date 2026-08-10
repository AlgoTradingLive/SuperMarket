const express = require("express");
const fs = require("fs");
const path = require("path");
const https = require("https");
const multer = require("multer");

const router = express.Router();
const PRODUCTS_FILE = path.join(__dirname, "..", "data", "products.json");
const SUBCATS_FILE = path.join(__dirname, "..", "data", "subcategories.json");
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

function readJSON(file) {
  return JSON.parse(fs.readFileSync(file, "utf-8"));
}
function writeJSON(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2), "utf-8");
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

// Commit an image file to the GitHub repo (mobile/assets/products/<name>)
// so it's served permanently via jsDelivr CDN, no ephemeral disk involved.
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

// POST /api/admin/upload-image  (multipart/form-data, field name "image")
router.post("/upload-image", checkAdmin, upload.single("image"), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: "No file uploaded" });
  try {
    const ext = path.extname(req.file.originalname) || ".jpg";
    const safeName =
      Date.now() + "-" + Math.random().toString(36).slice(2, 8) + ext.toLowerCase();
    const base64 = req.file.buffer.toString("base64");
    const url = await commitImageToGitHub(safeName, base64);
    res.json({ url });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/admin/off-search?q=Everest  -> search Open Food Facts (real branded product photos)
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

// GET /api/admin/products -> full list (for admin listing/edit)
router.get("/products", checkAdmin, (req, res) => {
  res.json(readJSON(PRODUCTS_FILE));
});

// GET /api/admin/subcategories
router.get("/subcategories", checkAdmin, (req, res) => {
  res.json(readJSON(SUBCATS_FILE));
});

// POST /api/admin/products -> add a new product
router.post("/products", checkAdmin, (req, res) => {
  const { name, subCategory, section, price, mrp, unit, image } = req.body;
  if (!name || !subCategory || !section || !unit || !image) {
    return res.status(400).json({ error: "Missing required fields" });
  }
  const products = readJSON(PRODUCTS_FILE);
  const newId = products.length ? Math.max(...products.map((p) => p.id)) + 1 : 1;
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
  products.push(product);
  writeJSON(PRODUCTS_FILE, products);
  res.status(201).json(product);
});

// PUT /api/admin/products/:id -> edit
router.put("/products/:id", checkAdmin, (req, res) => {
  const products = readJSON(PRODUCTS_FILE);
  const idx = products.findIndex((p) => p.id === Number(req.params.id));
  if (idx === -1) return res.status(404).json({ error: "Not found" });
  products[idx] = { ...products[idx], ...req.body, id: products[idx].id };
  writeJSON(PRODUCTS_FILE, products);
  res.json(products[idx]);
});

// DELETE /api/admin/products/:id
router.delete("/products/:id", checkAdmin, (req, res) => {
  let products = readJSON(PRODUCTS_FILE);
  const before = products.length;
  products = products.filter((p) => p.id !== Number(req.params.id));
  if (products.length === before) return res.status(404).json({ error: "Not found" });
  writeJSON(PRODUCTS_FILE, products);
  res.json({ deleted: true });
});

module.exports = router;
