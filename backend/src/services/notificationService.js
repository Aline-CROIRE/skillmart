const admin = require('firebase-admin');

// IMPORTANT: The user must place their serviceAccountKey.json in the src/config directory
// or set the GOOGLE_APPLICATION_CREDENTIALS environment variable.
try {
  let serviceAccount;
  
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    // If running on Render, use the environment variable
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } else {
    // If running locally, use the file
    serviceAccount = require('../config/firebase-service-account.json');
  }

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('Firebase Admin Initialized');
} catch (error) {
  console.warn('Firebase Admin could not be initialized. Ensure FIREBASE_SERVICE_ACCOUNT env var or local json file is present.');
}

exports.sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!fcmToken) return;

  const message = {
    notification: { title, body },
    data: data,
    token: fcmToken
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
  } catch (error) {
    console.error('Error sending message:', error);
  }
};
