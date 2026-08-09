const express = require("express");
const TELEGRAM_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID;

async function notifyTelegram(order) {
  if (!TELEGRAM_TOKEN || !TELEGRAM_CHAT_ID) return;

  const itemsList = order.items
    .map(i => `${i.qty} × ${i.name} — ₹${i.price * i.qty}`)
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
const fs = require("fs");
const path = require("path");

const router = express.Router();
const ORDERS_FILE = path.join(__dirname, "..", "data", "orders.json");

function readOrders() {
  if (!fs.existsSync(ORDERS_FILE)) return [];
  return JSON.parse(fs.readFileSync(ORDERS_FILE, "utf-8"));
}

function writeOrders(orders) {
  fs.writeFileSync(ORDERS_FILE, JSON.stringify(orders, null, 2));
}

// POST /api/orders  -> place a new order (mock checkout, no real payment)
router.post("/", (req, res) => {
  const { items, customerName, address, phone } = req.body;

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
    total,
    status: "Placed",
    createdAt: new Date().toISOString(),
  };

  const orders = readOrders();
  orders.push(order);
  writeOrders(orders);
  notifyTelegram(order);

  res.status(201).json({ message: "Order placed successfully", order });
});

// GET /api/orders  -> list all orders (for a simple admin view)
router.get("/", (req, res) => {
  res.json(readOrders());
});

module.exports = router;
