const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, default: 0 },
  category: { type: String, required: true },
  fileUrl: { type: String },
  thumbnailUrl: { type: String },
  sellerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  
  // Ownership details
  ownerType: { type: String, enum: ['Individual', 'Company'], default: 'Individual' },
  ownerName: { type: String },
  ceoName: { type: String },
  linkedinUrl: { type: String },

  // Project Type details
  projectType: { type: String, enum: ['Business Idea', 'Shareholder Seeking', 'Operational'], default: 'Business Idea' },
  externalLink: { type: String },
  proposalUrl: { type: String },
  rdbProofUrl: { type: String },
  incomeStatementUrl: { type: String },
  rraTaxHistoryUrl: { type: String },
  rraClearanceUrl: { type: String },
  pitchVideoUrl: { type: String },

  // Shareholder seeking details
  isShareholderSeeking: { type: Boolean, default: false },
  maxShareholders: { type: Number },
  totalSharesAvailable: { type: Number },
  minShare: { type: Number },
  shareValue: { type: Number },

  // Review Pipeline
  status: { 
    type: String, 
    enum: ['pending', 'under_review', 'pending_approval', 'approved', 'rejected', 'needs_changes'], 
    default: 'pending' 
  },
  analystId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  reviewNote: { type: String, default: "" },
  watchers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

  stats: {
    views: { type: Number, default: 0 },
    sales: { type: Number, default: 0 }
  },
  
  // Premium Analytics
  analyticsFileUrl: { type: String },
  analyticsAccessRequests: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    status: { type: String, enum: ['pending', 'granted', 'denied'], default: 'pending' },
    requestedAt: { type: Date, default: Date.now }
  }]
}, { timestamps: true });

module.exports = mongoose.model('Project', projectSchema);