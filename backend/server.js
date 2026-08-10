const express = require("express");
const cors = require("cors");
const path = require("path");
const { connectDB } = require("./db");

const productsRouter = require("./routes/products");
const ordersRouter = require("./routes/orders");
const subcategoriesRouter = require("./routes/subcategories");
const storesRouter = require("./routes/stores");
const adminRouter = require("./routes/admin");
const paymentRouter = require("./routes/payment");

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// API routes
app.use("/api/products", productsRouter);
app.use("/api/orders", ordersRouter);
app.use("/api/subcategories", subcategoriesRouter);
app.use("/api/stores", storesRouter);
app.use("/api/admin", adminRouter);
app.use("/api/payment", paymentRouter);

// Admin panel page
app.get("/admin", (req, res) => {
  res.sendFile(path.join(__dirname, "admin.html"));
});

// Legal documents
app.get("/privacy-policy", (req, res) => {
  res.sendFile(path.join(__dirname, "legal", "privacy.html"));
});
app.get("/terms", (req, res) => {
  res.sendFile(path.join(__dirname, "legal", "terms.html"));
});
app.get("/refund-policy", (req, res) => {
  res.sendFile(path.join(__dirname, "legal", "refund.html"));
});

// Serve frontend (so the whole app can run from one free server)
app.use(express.static(path.join(__dirname, "..", "frontend")));

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "..", "frontend", "index.html"));
});

async function start() {
  const db = await connectDB();
  app.locals.db = db;
  app.listen(PORT, () => {
    console.log(`🛒 SuperMarket server running on port ${PORT}`);
  });
}

start().catch((err) => {
  console.error("❌ Failed to start server:", err);
  process.exit(1);
});
