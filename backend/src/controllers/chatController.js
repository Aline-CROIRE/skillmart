const Conversation = require('../models/Conversation');
const Message = require('../models/Message');

// Start or Get existing conversation
exports.accessConversation = async (req, res) => {
  const { recipientId, projectId } = req.body;
  
  let conversation = await Conversation.findOne({
    participants: { $all: [req.user._id, recipientId] },
    projectRef: projectId
  });

  if (!conversation) {
    conversation = await Conversation.create({
      participants: [req.user._id, recipientId],
      projectRef: projectId
    });
  }

  res.json(conversation);
};

// Get list of all my chats
exports.getMyConversations = async (req, res) => {
  const chats = await Conversation.find({ participants: req.user._id })
    .populate('participants', 'name role')
    .populate('projectRef', 'title')
    .sort({ updatedAt: -1 });
  res.json(chats);
};

// Get messages for a specific chat
exports.getMessages = async (req, res) => {
  const messages = await Message.find({ conversationId: req.params.chatId });
  res.json(messages);
};