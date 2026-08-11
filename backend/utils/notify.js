const { initFirebaseAdmin } = require("../firebase-admin");

// Sends a push notification to every device registered under a phone number.
// Silently no-ops if Firebase Admin isn't configured or the phone has no tokens.
async function sendPushToPhone(db, phone, title, body) {
  const admin = initFirebaseAdmin();
  if (!admin || !phone) return;

  const tokens = await db.collection("deviceTokens").find({ phone }).toArray();
  if (!tokens.length) return;

  await Promise.all(
    tokens.map(async (t) => {
      try {
        await admin.messaging().send({
          token: t.token,
          notification: { title, body },
        });
      } catch (e) {
        // Token likely stale/expired — clean it up so we don't keep retrying it.
        if (
          e.code === "messaging/registration-token-not-registered" ||
          e.code === "messaging/invalid-registration-token"
        ) {
          await db.collection("deviceTokens").deleteOne({ token: t.token });
        } else {
          console.error("Push send failed:", e.message);
        }
      }
    })
  );
}

module.exports = { sendPushToPhone };
