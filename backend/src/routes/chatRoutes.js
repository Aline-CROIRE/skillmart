const express = require('express');
const router = express.Router();
const { accessConversation, getMyConversations, getMessages } = require('../controllers/chatController');
const { protect } = require('../middlewares/authMiddleware');

// Base path is /api/chat
router.post('/', protect, accessConversation); // Starts a chat
router.get('/', protect, getMyConversations);  // Lists my chats
router.get('/:chatId', protect, getMessages);   // Gets message history

module.exports = router;