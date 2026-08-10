const { MongoClient } = require("mongodb");
const fs = require("fs");
const path = require("path");

const uri = process.env.MONGODB_URI;
let dbInstance = null;

async function connectDB() {
  if (dbInstance) return dbInstance;
  if (!uri) throw new Error("MONGODB_URI not set");

  const client = new MongoClient(uri);
  await client.connect();
  dbInstance = client.db("supermarket");
  console.log("✅ MongoDB connected");

  await seedIfEmpty(dbInstance);
  return dbInstance;
}

// One-time seed: if a collection is empty, load it from the bundled JSON file
// so nothing from the old file-based data gets lost during migration.
async function seedIfEmpty(db) {
  const seeds = [
    { collection: "products", file: "products.json" },
    { collection: "subcategories", file: "subcategories.json" },
    { collection: "stores", file: "stores.json" },
  ];

  for (const s of seeds) {
    const count = await db.collection(s.collection).countDocuments();
    if (count === 0) {
      const filePath = path.join(__dirname, "data", s.file);
      if (fs.existsSync(filePath)) {
        const data = JSON.parse(fs.readFileSync(filePath, "utf-8"));
        if (Array.isArray(data) && data.length) {
          await db.collection(s.collection).insertMany(data);
          console.log(`🌱 Seeded ${data.length} docs into "${s.collection}"`);
        }
      }
    }
  }

  // Orders may or may not have an existing file (created at runtime before)
  const ordersCount = await db.collection("orders").countDocuments();
  if (ordersCount === 0) {
    const ordersFile = path.join(__dirname, "data", "orders.json");
    if (fs.existsSync(ordersFile)) {
      const data = JSON.parse(fs.readFileSync(ordersFile, "utf-8"));
      if (Array.isArray(data) && data.length) {
        await db.collection("orders").insertMany(data);
        console.log(`🌱 Seeded ${data.length} docs into "orders"`);
      }
    }
  }
}

module.exports = { connectDB };
