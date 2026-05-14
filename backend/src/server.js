const path = require('path');
// Load environment variables using absolute path for stability
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const app = require('./app');
const connectDB = require('./config/db');
const redisConnection = require('./config/redis');
const startWorker = require('./jobs/worker');

const startServer = async () => {
  try {
    // 1. Connect to MongoDB Atlas
    await connectDB();

    // 2. Connect to Upstash Redis and Start AI Worker
    // The worker shares the same Redis connection as the API
    startWorker(redisConnection);

    // 3. Start the Express API
    const PORT = process.env.PORT || 5000;
    const server = app.listen(PORT, () => {
      console.log(`🚀 SkillMart API is LIVE on port ${PORT}`);
      console.log(`Environment: ${process.env.NODE_ENV}`);
    });

    // Handle unexpected port errors
    server.on('error', (e) => {
      if (e.code === 'EADDRINUSE') {
        console.error(`❌ Port ${PORT} is busy. Please clear it and restart.`);
        process.exit(1);
      }
    });

  } catch (error) {
    console.error('CRITICAL STARTUP ERROR:', error);
    process.exit(1);
  }
};

startServer();