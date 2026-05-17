const express = require('express');
const router = express.Router();
const { sendVerificationEmail } = require('../services/emailService');

router.get('/send-test', async (req, res) => {
  const { email } = req.query;
  if (!email) {
    return res.status(400).json({ error: 'Email query parameter is required' });
  }

  try {
    const result = await sendVerificationEmail(email, 'Test User', '123456');
    if (result.ok) {
      res.json({ message: `Test email sent successfully to ${email}` });
    } else {
      res.status(500).json({ error: 'Failed to send email', detail: result.error });
    }
  } catch (error) {
    res.status(500).json({ error: 'System error', detail: error.message });
  }
});

router.get('/debug-env', (req, res) => {
  res.json({
    hasGmailUser: !!process.env.GMAIL_USER,
    hasGmailPass: !!process.env.GMAIL_APP_PASSWORD,
    hasResendKey: !!process.env.RESEND_API_KEY,
    nodeEnv: process.env.NODE_ENV || 'not set'
  });
});

/**
 * @swagger
 * tags:
 *   name: Test
 *   description: Utility endpoints for testing system features
 */

const { protect: auth } = require('../middlewares/authMiddleware');
const notificationService = require('../services/notificationService');

/**
 * @swagger
 * /api/test/trigger-push:
 *   post:
 *     summary: Trigger a test push notification for yourself
 *     tags: [Test]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               message:
 *                 type: string
 *               type:
 *                 type: string
 *                 enum: [project_update, security, wallet, admin_broadcast]
 *     responses:
 *       200:
 *         description: Notification triggered successfully
 */
router.post('/trigger-push', auth, async (req, res) => {
  const { title, message, type } = req.body;
  
  try {
    const notification = await notificationService.createNotification(
      req.user.id,
      title || 'Test Notification',
      message || 'This is a test notification from the SkillMart system.',
      type || 'project_update'
    );
    
    res.json({ 
      message: 'Push notification triggered', 
      notification 
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
