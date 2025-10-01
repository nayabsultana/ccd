const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// HTTPS endpoint for bank webhook
exports.webhookTransactions = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');
  const apiKey = req.headers['x-api-key'];
  if (apiKey !== functions.config().webhook.key) return res.status(401).send('Unauthorized');
  const txn = req.body;
  if (!txn || !txn.txnId || !txn.userId) return res.status(400).send('Invalid payload');
  await admin.firestore().collection('transactions').doc(txn.txnId).set(txn, {merge: true});
  res.status(200).send('Transaction received');
});

// Firestore trigger for fraud detection and FCM
exports.detectFraudAndAlert = functions.firestore
  .document('transactions/{txnId}')
  .onWrite(async (change, context) => {
    const txn = change.after.exists ? change.after.data() : null;
    if (!txn) return;
    const { amount, timestamp, userId, txnId } = txn;
    let suspicious = false, reasons = [];
    if (amount > 5000) { suspicious = true; reasons.push('Large amount'); }
    const hour = new Date(timestamp).getHours();
    if (hour < 6 || hour > 22) { suspicious = true; reasons.push('Odd hour'); }
    // Velocity check: last 5 min
    const recentTxns = await admin.firestore().collection('transactions')
      .where('userId', '==', userId)
      .where('timestamp', '>=', Date.now() - 5 * 60 * 1000)
      .get();
    if (recentTxns.size > 3) { suspicious = true; reasons.push('High velocity'); }
    if (!suspicious) return;

    // De-duplicate flag/alert
    const flagRef = admin.firestore().collection('flags').doc(txnId);
    const alertRef = admin.firestore().collection('alerts').doc(txnId);
    await flagRef.set({
      userId, txnId, reasons, status: 'pending', createdAt: admin.firestore.FieldValue.serverTimestamp()
    }, {merge: true});
    await alertRef.set({
      userId, txnId, reasons, status: 'unread', createdAt: admin.firestore.FieldValue.serverTimestamp()
    }, {merge: true});

    // FCM tokens
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    let tokens = userDoc.get('fcmTokens');
    if (!tokens) return;
    if (typeof tokens === 'string') tokens = [tokens];
    for (const token of tokens) {
      try {
        await admin.messaging().send({
          token,
          notification: { title: 'Fraud Alert', body: `Suspicious transaction: ${txnId}` },
          data: { alertId: txnId, txnId: txnId },
          android: { priority: 'high' },
          apns: { headers: { 'apns-priority': '10' } }
        });
      } catch (err) {
        if (err.code === 'messaging/registration-token-not-registered') {
          await admin.firestore().collection('users').doc(userId)
            .update({ fcmTokens: admin.firestore.FieldValue.arrayRemove(token) });
        }
      }
    }
  });
