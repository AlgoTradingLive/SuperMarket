const admin = require("firebase-admin");

let initialized = false;

function initFirebaseAdmin() {
  if (initialized) return admin;
  const b64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
  if (!b64) {
    console.warn("⚠️ FIREBASE_SERVICE_ACCOUNT_BASE64 not set — push notifications disabled");
    return null;
  }
  try {
    const json = JSON.parse(Buffer.from(b64, "base64").toString("utf-8"));
    admin.initializeApp({
      credential: admin.credential.cert(json),
    });
    initialized = true;
    console.log("✅ Firebase Admin (push notifications) ready");
    return admin;
  } catch (e) {
    console.error("❌ Firebase Admin init failed:", e.message);
    return null;
  }
}

module.exports = { initFirebaseAdmin };
