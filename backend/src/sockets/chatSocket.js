const Message = require('../models/Message');
const Conversation = require('../models/Conversation');

const initChat = (io) => {
  io.on('connection', (socket) => {
    
    socket.on('join_room', (chatId) => {
      socket.join(chatId);
    });

    socket.on('send_message', async (data) => {
      const { conversationId, senderId, text } = data;
      
      try {
        // 1. Create message with auto-timestamp
        const message = await Message.create({ conversationId, senderId, text });
        
        // 2. Update the parent conversation's summary
        await Conversation.findByIdAndUpdate(conversationId, { 
          lastMessage: text, 
          updatedAt: Date.now() 
        });

        // 3. Emit the FULL message object (including createdAt) back to the room
        io.to(conversationId).emit('new_message', message);
        
      } catch (error) {
        console.error("Socket Message Error:", error);
      }
    });

  });
};

module.exports = initChat;