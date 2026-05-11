const path = require('path');
const dotenv = require('dotenv');

// Absolute path to find the .env in the backend folder
dotenv.config({ path: path.resolve(__dirname, '../backend/.env') });

const { Worker } = require('bullmq');
const mongoose = require('mongoose');
const Project = require('../backend/src/models/Project');
const Analysis = require('../backend/src/models/Analysis');
const { analyzeWithClaude } = require('../backend/src/services/aiService');

const mongoUri = process.env.MONGO_URI;
if (!mongoUri) {
    console.error('ERROR: Worker cannot find MONGO_URI. Check .env path.');
    process.exit(1);
}

mongoose.connect(mongoUri)
  .then(() => console.log('Worker connected to MongoDB'))
  .catch(err => console.error('Worker MongoDB Error:', err));

const connection = {
  host: process.env.REDIS_HOST,
  port: parseInt(process.env.REDIS_PORT),
  password: process.env.REDIS_PASSWORD,
  tls: {}, 
  maxRetriesPerRequest: null
};

const worker = new Worker(
  'project-analysis',
  async (job) => {
    console.log(`Processing: ${job.data.title}`);
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
      console.log(`Finished: ${job.data.title}`);
    } catch (error) {
      console.error(`Worker Job Error:`, error);
    }
  },
  { connection }
);

worker.on('ready', () => console.log('Worker connected to Upstash Redis'));
worker.on('error', (err) => console.error('Worker Redis Error:', err));