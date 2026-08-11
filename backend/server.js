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
const deviceTokenRouter = require("./routes/deviceToken");
const { computeLiveStatus } = require("./routes/orders");
const { sendPushToPhone } = require("./utils/notify");
const { initFirebaseAdmin } = require("./firebase-admin");

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
app.use("/api/device-token", deviceTokenRouter);

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

  initFirebaseAdmin(); // no-op if FIREBASE_SERVICE_ACCOUNT_BASE64 isn't set

  app.listen(PORT, () => {
    console.log(`🛒 SuperMarket server running on port ${PORT}`);
  });

  // Every minute: auto-progress order status over time and push-notify the
  // customer when it changes (skips orders an admin has manually set).
  setInterval(async () => {
    try {
      const activeOrders = await db
        .collection("orders")
        .find({
          status: { $nin: ["Delivered", "Cancelled"] },
          manualStatus: { $ne: true },
        })
        .toArray();

      for (const order of activeOrders) {
        const newStatus = computeLiveStatus(order).status;
        if (newStatus !== order.status) {
          await db.collection("orders").updateOne(
            { id: order.id },
            { $set: { status: newStatus } }
          );
          sendPushToPhone(
            db,
            order.phone,
            "Order Update",
            `Your order #${order.id} is now "${newStatus}"`
          );
        }
      }
    } catch (e) {
      console.error("Status progression cron failed:", e.message);
    }
  }, 60 * 1000);
}

start().catch((err) => {
  console.error("❌ Failed to start server:", err);
  process.exit(1);
});
