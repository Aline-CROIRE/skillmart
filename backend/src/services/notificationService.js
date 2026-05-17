const admin = require('firebase-admin');

// IMPORTANT: The user must place their serviceAccountKey.json in the src/config directory
// or set the GOOGLE_APPLICATION_CREDENTIALS environment variable.
try {
  const serviceAccount = require('../config/firebase-service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('Firebase Admin Initialized');
} catch (error) {
  console.warn('Firebase Admin could not be initialized. Service account key might be missing.');
}

const Notification = require('../models/Notification');

exports.sendPushNotification = async (fcmToken, title, body, data = {}, androidChannelId = 'default') => {
  if (!fcmToken) return;

  const message = {
    notification: { title, body },
    android: {
      notification: {
        channelId: androidChannelId
      }
    },
    data: data,
    token: fcmToken
  };

  try {
    await admin.messaging().send(message);
  } catch (error) {
    console.error('Error sending message:', error);
  }
};

const { sendSecurityAlertEmail } = require('./emailService');

exports.createNotification = async (user, title, message, type, relatedId = null) => {
  try {
    // 1. Save to DB for the Tray
    await Notification.create({
      userId: user._id,
      title,
      message,
      type,
      relatedId
    });

    // 2. Send Push Notification if user has a token
    if (user.fcmToken) {
      let channelId = 'default';
      if (type === 'project_update') channelId = 'projects';
      if (type === 'security') channelId = 'security';
      if (type === 'wallet') channelId = 'wallet';
      if (type === 'admin_broadcast') channelId = 'broadcast';
      await exports.sendPushNotification(user.fcmToken, title, message, { relatedId: relatedId ? String(relatedId) : '' }, channelId);
    }

    // 3. Send Email for Security Alerts
    if (type === 'security' && user.email) {
      await sendSecurityAlertEmail(user.email, title, message);
    }
  } catch (error) {
    console.error('Error in createNotification:', error);
  }
};
