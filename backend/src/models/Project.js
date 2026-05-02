const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
    },
    category: {
      type: String,
      required: true,
      enum: ['Web', 'Mobile', 'AI', 'Design', 'Other'],
    },
    fileUrl: {
      type: String,
      required: false,
    },
    status: {
      type: String,
      required: true,
      enum: ['pending', 'analyzing', 'approved', 'rejected'],
      default: 'pending',
    },
    sellerId: {
      type: String,
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Project', projectSchema);