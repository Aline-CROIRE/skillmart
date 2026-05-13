const Message = require('../models/Message');
const Conversation = require('../models/Conversation');

const initChat = (io) => {
  io.on('connection', (socket) => {
    console.log('User connected to chat:', socket.id);

    socket.on('join_chat', (conversationId) => {
      socket.join(conversationId);
    });

    socket.on('send_message', async ({ conversationId, senderId, text }) => {
      const message = await Message.create({ conversationId, senderId, text });
      await Conversation.findByIdAndUpdate(conversationId, { lastMessage: text, updatedAt: Date.now() });
      
      io.to(conversationId).emit('receive_message', message);
    });
  });
};

module.exports = initChat;