const express = require("express");
const crypto = require("crypto");
const Razorpay = require("razorpay");

const router = express.Router();

const KEY_ID = process.env.RAZORPAY_KEY_ID;
const KEY_SECRET = process.env.RAZORPAY_KEY_SECRET;

function getClient() {
  if (!KEY_ID || !KEY_SECRET) {
    throw new Error("Razorpay keys not configured on server");
  }
  return new Razorpay({ key_id: KEY_ID, key_secret: KEY_SECRET });
}

// POST /api/payment/create-order  { amount: <rupees> }
// Creates a Razorpay order and returns the public key id + order id for the app.
router.post("/create-order", async (req, res) => {
  try {
    const { amount } = req.body;
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: "Valid amount required" });
    }
    const client = getClient();
    const order = await client.orders.create({
      amount: Math.round(amount * 100), // paise
      currency: "INR",
      receipt: "order_rcpt_" + Date.now(),
    });
    res.json({
      keyId: KEY_ID,
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/payment/verify
// { razorpay_order_id, razorpay_payment_id, razorpay_signature }
// Confirms the payment signature is genuine before we trust it.
router.post("/verify", (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({ error: "Missing payment details" });
    }
    const expected = crypto
      .createHmac("sha256", KEY_SECRET)
      .update(`${razorpay_order_id}|${razorpay_payment_id}`)
      .digest("hex");

    const valid = expected === razorpay_signature;
    res.json({ verified: valid });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
