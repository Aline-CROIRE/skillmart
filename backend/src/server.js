const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const app = require('./app');
const connectDB = require('./config/db');
const redisConnection = require('./config/redis');
const startWorker = require('./jobs/worker');

const startServer = async () => {
  try {
    // 1. Connect Database
    await connectDB();

    // 2. Start AI Worker
    startWorker(redisConnection);

    // 3. Dynamic Port (Render uses process.env.PORT)
    const PORT = process.env.PORT || 5000;
    
    const server = app.listen(PORT, () => {
      console.log(` Server running on port ${PORT}`);
    });

    // Handle port errors gracefully
    server.on('error', (e) => {
      if (e.code === 'EADDRINUSE') {
        console.error(` Port ${PORT} is busy. Please kill the process or use a different port.`);
        process.exit(1);
      }
    });

  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();