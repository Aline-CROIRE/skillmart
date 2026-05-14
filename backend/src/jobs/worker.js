const { Worker } = require('bullmq');
const Project = require('../models/Project');
const Analysis = require('../models/Analysis');
const { analyzeWithClaude } = require('../services/aiService'); // This is your Gemini service

const startWorker = (connection) => {
  const worker = new Worker(
    'project-analysis',
    async (job) => {
      console.log(`🚀 AI processing started for: ${job.data.title}`);
      const { projectId, title, description } = job.data;

      try {
        // 1. Get AI Report from Gemini
        const aiResult = await analyzeWithClaude({ title, description });

        // 2. Save Analysis Report to MongoDB
        await Analysis.create({
          projectId,
          score: aiResult.score,
          summary: aiResult.summary,
          securityFindings: aiResult.securityFindings,
          qualityMetrics: aiResult.qualityMetrics,
          rawAiResponse: aiResult,
        });

        // 3. Set project to 'pending' (Ready for Admin Approval)
        // If you want it to go live immediately, change this to 'approved'
        await Project.findByIdAndUpdate(projectId, { status: 'pending' });

        console.log(`✅ AI processing complete for: ${title}. Project is now PENDING.`);
      } catch (error) {
        console.error(`❌ Worker Error on project ${projectId}:`, error);
        await Project.findByIdAndUpdate(projectId, { status: 'rejected' });
      }
    },
    { 
      connection,
      removeOnComplete: { count: 100 },
      removeOnFail: { count: 500 }
    }
  );

  worker.on('ready', () => console.log('🤖 AI Background Worker is ACTIVE and waiting for jobs...'));
  worker.on('error', (err) => console.error('❌ Worker Connection Error:', err));
};

module.exports = startWorker;