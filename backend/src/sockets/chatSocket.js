const Message = require('../models/Message');
const Conversation = require('../models/Conversation');

const initChat = (io) => {
  io.on('connection', (socket) => {
    console.log('User joined real-time gateway:', socket.id);

    socket.on('join_room', (chatId) => {
      socket.join(chatId);
      console.log(`User entered room: ${chatId}`);
    });

    socket.on('send_message', async (data) => {
      const { conversationId, senderId, text } = data;
      
      // 1. Save message to DB
      const message = await Message.create({ conversationId, senderId, text });
      
      // 2. Update conversation timestamp
      await Conversation.findByIdAndUpdate(conversationId, { 
        lastMessage: text, 
        updatedAt: Date.now() 
      });

      // 3. Broadcast to everyone in that specific room
      io.to(conversationId).emit('new_message', message);
    });

    socket.on('disconnect', () => {
      console.log('User left gateway');
    });
  });
};

module.exports = initChat;