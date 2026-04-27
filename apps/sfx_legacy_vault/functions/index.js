/**
 * SFX Legacy Vault - Cloud Functions
 *
 * Dead Man's Switch: checks user deadlines and sends encrypted data
 * to target email if user hasn't pinged within their deadline period.
 *
 * Setup:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Login: firebase login
 * 3. Initialize: firebase init functions
 * 4. Set email service credentials:
 *    firebase functions:config:set nodemailer.host="smtp.gmail.com"
 *    firebase functions:config:set nodemailer.port="587"
 *    firebase functions:config:set nodemailer.user="your-email@gmail.com"
 *    firebase functions:config:set nodemailer.pass="your-app-password"
 * 5. Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

const db = admin.firestore();

// Create a reusable nodemailer transporter
function getTransporter() {
  try {
    const config = functions.config().nodemailer;
    if (!config) {
      throw new Error('Nodemailer config not set. Run: firebase functions:config:set nodemailer.*=...');
    }
    return nodemailer.createTransport({
      host: config.host,
      port: parseInt(config.port, 10),
      secure: false, // true for 465, false for other ports
      auth: {
        user: config.user,
        pass: config.pass,
      },
    });
  } catch (error) {
    console.error('Failed to create transporter:', error.message);
    throw error;
  }
}

/**
 * Scheduled function: Runs every hour to check for expired deadlines.
 * Deploy with: firebase deploy --only functions:deadlineChecker
 */
exports.deadlineChecker = functions.pubsub
  .schedule('every 60 minutes')
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('Deadline checker started at:', new Date().toISOString());

    try {
      const snapshot = await db.collection('users').get();
      const now = admin.firestore.Timestamp.now();
      let checkedCount = 0;
      let sentCount = 0;

      for (const doc of snapshot.docs) {
        const data = doc.data();
        checkedCount++;

        // Skip if already sent
        if (data.status === 'sent') {
          continue;
        }

        const lastActiveAt = data.lastActiveAt;
        if (!lastActiveAt || !lastActiveAt.toDate) {
          console.warn(`Document ${doc.id} missing lastActiveAt`);
          continue;
        }

        const deadlineDays = data.deadlineDays || 14;
        const lastActiveDate = lastActiveAt.toDate ? lastActiveAt.toDate() : new Date(lastActiveAt.seconds * 1000);
        const deadlineDate = new Date(lastActiveDate.getTime() + deadlineDays * 24 * 60 * 60 * 1000);

        if (new Date() > deadlineDate) {
          console.log(`User ${doc.id} deadline passed! Sending data to ${data.targetEmail}`);

          try {
            await sendEncryptedData({
              userId: doc.id,
              targetEmail: data.targetEmail,
              encryptedData: data.encryptedData,
              deadlineDays: deadlineDays,
              createdAt: data.createdAt,
            });

            // Update status to sent
            await doc.ref.update({
              status: 'sent',
              sentAt: admin.firestore.Timestamp.now(),
            });

            sentCount++;
            console.log(`Successfully sent data for user ${doc.id}`);
          } catch (error) {
            console.error(`Failed to send data for user ${doc.id}:`, error.message);

            // Update status to alerted but not sent
            await doc.ref.update({
              status: 'alerted',
              lastError: error.message,
            });
          }
        }
      }

      console.log(`Deadline checker finished. Checked: ${checkedCount}, Sent: ${sentCount}`);
    } catch (error) {
      console.error('Deadline checker error:', error);
    }

    return null;
  });

/**
 * Sends encrypted data to the target email.
 */
async function sendEncryptedData(vaultData) {
  const transporter = getTransporter();

  const mailOptions = {
    from: '"SFX Legacy Vault" <noreply@sfxvault.com>',
    to: vaultData.targetEmail,
    subject: '[SFX Legacy Vault] Encrypted Data Delivery - Dead Man\'s Switch Triggered',
    html: `
      <div style="font-family: monospace; background: #0A0A0F; color: #EAEAEA; padding: 24px; border-radius: 12px;">
        <h2 style="color: #00FF88; margin-top: 0;">SFX Legacy Vault</h2>
        <p style="color: #FF00AA;">This is an automated delivery from the SFX Legacy Vault dead man's switch.</p>
        <p>The vault owner (${vaultData.userId}) has not checked in within their ${vaultData.deadlineDays}-day deadline period.</p>
        <hr style="border-color: #1A1A28;">
        <h3 style="color: #00DDFF;">Encrypted Data:</h3>
        <pre style="background: #12121A; padding: 16px; border-radius: 8px; overflow-x: auto; color: #00FF88; font-size: 12px;">${vaultData.encryptedData}</pre>
        <p style="color: #888899; font-size: 12px;">Note: This data is AES-256 encrypted. The decryption passphrase is stored only on the vault owner's device.</p>
        <hr style="border-color: #1A1A28;">
        <p style="color: #888899; font-size: 11px;">Vault created: ${vaultData.createdAt ? new Date(vaultData.createdAt.toDate ? vaultData.createdAt.toDate().getTime() : vaultData.createdAt.seconds * 1000).toISOString() : 'Unknown'}</p>
        <p style="color: #888899; font-size: 11px;">Delivered: ${new Date().toISOString()}</p>
      </div>
    `,
    text: `SFX Legacy Vault - Dead Man's Switch Triggered\n\n` +
      `The vault owner (${vaultData.userId}) has not checked in within their ${vaultData.deadlineDays}-day deadline period.\n\n` +
      `Encrypted Data:\n${vaultData.encryptedData}\n\n` +
      `Note: This data is AES-256 encrypted. The decryption passphrase is stored only on the vault owner's device.`,
  };

  await transporter.sendMail(mailOptions);
}

/**
 * HTTP trigger: Manual ping endpoint (alternative to client-side ping).
 * Can be called from external systems or scheduled tasks.
 */
exports.manualPing = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  if (userId !== data.userId) {
    throw new functions.https.HttpsError('permission-denied', 'Cannot ping another user\'s vault');
  }

  await db.collection('users').doc(userId).update({
    lastActiveAt: admin.firestore.Timestamp.now(),
    status: 'active',
  });

  return { success: true, timestamp: new Date().toISOString() };
});

/**
 * HTTP trigger: Get vault status without authentication (for admin/monitoring).
 */
exports.getVaultStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const doc = await db.collection('users').doc(context.auth.uid).get();
  if (!doc.exists) {
    return { exists: false };
  }

  const vaultData = doc.data();
  const lastActiveAt = vaultData.lastActiveAt?.toDate ? vaultData.lastActiveAt.toDate() : new Date();
  const deadlineDays = vaultData.deadlineDays || 14;
  const deadlineDate = new Date(lastActiveAt.getTime() + deadlineDays * 24 * 60 * 60 * 1000);
  const hoursRemaining = Math.max(0, Math.floor((deadlineDate - new Date()) / (1000 * 60 * 60)));

  return {
    exists: true,
    status: vaultData.status,
    targetEmail: vaultData.targetEmail,
    deadlineDays: deadlineDays,
    hoursRemaining: hoursRemaining,
    lastActiveAt: lastActiveAt.toISOString(),
    deadlineDate: deadlineDate.toISOString(),
    hasEncryptedData: !!vaultData.encryptedData,
  };
});
