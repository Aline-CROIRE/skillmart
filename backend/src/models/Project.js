const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, default: 0 },
  category: { type: String, required: true },
  fileUrl: { type: String, required: true },
  sellerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  
  // Review Pipeline
  status: { 
    type: String, 
    enum: ['pending', 'under_review', 'approved', 'rejected', 'needs_changes'], 
    default: 'pending' 
  },
  analystId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  reviewNote: { type: String, default: "" },

  stats: {
    views: { type: Number, default: 0 },
    sales: { type: Number, default: 0 }
  }
}, { timestamps: true });

module.exports = mongoose.model('Project', projectSchema);