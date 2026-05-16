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

module.exports = router;
