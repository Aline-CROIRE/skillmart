const mongoose = require('mongoose');

const analysisSchema = new mongoose.Schema(
  {
    projectId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Project',
      required: true,
    },
    score: {
      type: Number,
      required: true,
    },
    summary: {
      type: String,
      required: true,
    },
    securityFindings: [String],
    qualityMetrics: {
      codeQuality: Number,
      documentation: Number,
    },
    rawAiResponse: {
      type: Object,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Analysis', analysisSchema);