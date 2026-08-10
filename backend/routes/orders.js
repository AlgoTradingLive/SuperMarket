const express = require("express");
const TELEGRAM_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID;

const router = express.Router();

// Auto status progression thresholds (minutes since order placed)
const STATUS_STEPS = [
  { minutes: 0, status: "Placed" },
  { minutes: 2, status: "Packed" },
  { minutes: 8, status: "Out for Delivery" },
  { minutes: 20, status: "Delivered" },
];

function computeLiveStatus(order) {
  const elapsedMin = (Date.now() - new Date(order.createdAt).getTime()) / 60000;
  let status = STATUS_STEPS[0].status;
  for (const step of STATUS_STEPS) {
    if (elapsedMin >= step.minutes) status = step.status;
  }
  return { ...order, status };
}

async function notifyTelegram(order) {
  if (!TELEGRAM_TOKEN || !TELEGRAM_CHAT_ID) return;

  const itemsList = order.items
    .map((i) => `${i.qty} × ${i.name} — ₹${i.price * i.qty}`)
    .join("\n");

  const orderTime = new Date(order.createdAt).toLocaleString("en-IN", {
    timeZone: "Asia/Kolkata",
    day: "2-digit", month: "short", year: "numeric",
    hour: "2-digit", minute: "2-digit",
  });

  const text =
`🛍️ <b>New Order Received</b>
━━━━━━━━━━━━━━━━
🆔 Order #${order.id}
🕒 ${orderTime}
🏬 <b>Store:</b> ${order.storeName || "Not selected"}

👤 <b>Customer</b>
${order.customerName}
📞 ${order.phone}
📍 ${order.address}

🧺 <b>Items</b>
${itemsList}

━━━━━━━━━━━━━━━━
💰 <b>Total: ₹${order.total}</b>
💳 Payment: Cash on Delivery`;

  try {
    await fetch(`https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chat_id: TELEGRAM_CHAT_ID,
        text,
        parse_mode: "HTML",
      }),
    });
  } catch (e) {
    console.error("Telegram notify failed:", e.message);
  }
}

// POST /api/orders  -> place a new order
router.post("/", async (req, res) => {
  const db = req.app.locals.db;
  const { items, customerName, address, phone, storeId, storeName } = req.body;

  if (!items || items.length === 0) {
    return res.status(400).json({ error: "Cart is empty" });
  }
  if (!customerName || !address || !phone) {
    return res.status(400).json({ error: "Customer details required" });
  }

  const total = items.reduce((sum, item) => sum + item.price * item.qty, 0);

  const order = {
    id: Date.now(),
    items,
    customerName,
    address,
    phone,
    storeId: storeId || null,
    storeName: storeName || null,
    total,
    status: "Placed",
    createdAt: new Date().toISOString(),
  };

  await db.collection("orders").insertOne(order);
  notifyTelegram(order);

  const { _id, ...clean } = order;
  res.status(201).json({ message: "Order placed successfully", order: computeLiveStatus(clean) });
});

// GET /api/orders?phone=xxxxxxxxxx
router.get("/", async (req, res) => {
  const db = req.app.locals.db;
  const { phone } = req.query;
  const query = phone ? { phone } : {};
  const orders = await db
    .collection("orders")
    .find(query, { projection: { _id: 0 } })
    .sort({ id: -1 })
    .toArray();
  res.json(orders.map(computeLiveStatus));
});

// GET /api/orders/:id
router.get("/:id", async (req, res) => {
  const db = req.app.locals.db;
  const order = await db
    .collection("orders")
    .findOne({ id: Number(req.params.id) }, { projection: { _id: 0 } });
  if (!order) return res.status(404).json({ error: "Order not found" });
  res.json(computeLiveStatus(order));
});

module.exports = router;
