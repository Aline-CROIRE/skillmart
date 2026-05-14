const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema({
  participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  projectRef: { type: mongoose.Schema.Types.ObjectId, ref: 'Project' }, // Context of chat
  lastMessage: { type: String, default: "" },
  updatedAt: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('Conversation', conversationSchema);