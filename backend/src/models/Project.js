const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, default: 0 },
  category: { 
    type: String, 
    required: true,
    enum: ['Academic', 'Business', 'Creative', 'Technology', 'Professional', 'Other']
  },
  fileUrl: { type: String, required: true },
  sellerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  status: { 
    type: String, 
    enum: ['pending', 'analyzing', 'approved', 'rejected'], 
    default: 'pending' 
  },
  stats: {
    views: { type: Number, default: 0 },
    downloads: { type: Number, default: 0 },
    sales: { type: Number, default: 0 }
  }
}, { timestamps: true });

module.exports = mongoose.model('Project', projectSchema);