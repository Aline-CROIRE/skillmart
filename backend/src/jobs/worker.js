const { Worker } = require('bullmq');
const Project = require('../models/Project');
const Analysis = require('../models/Analysis');
const { analyzeWithClaude } = require('../services/aiService');

const startWorker = (connection) => {
  const worker = new Worker(
    'project-analysis',
    async (job) => {
      console.log(`AI Analyzing: ${job.data.title}`);
      try {
        const aiResult = await analyzeWithClaude(job.data);
        await Analysis.create({
          projectId: job.data.projectId,
          score: aiResult.score,
          summary: aiResult.summary,
          securityFindings: aiResult.securityFindings,
          qualityMetrics: aiResult.qualityMetrics,
          rawAiResponse: aiResult,
        });
        await Project.findByIdAndUpdate(job.data.projectId, { status: 'approved' });
        console.log(`Analysis Complete: ${job.data.title}`);
      } catch (error) {
        console.error(` Worker Error:`, error);
      }
    },
    { connection }
  );

  worker.on('ready', () => console.log('Background Worker Started'));
  worker.on('error', (err) => console.error(' Worker Redis Error:', err));
};

module.exports = startWorker;