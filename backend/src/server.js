const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const app = require('./app');
const connectDB = require('./config/db');

const startServer = async () => {
  try {
    // 1. Connect to MongoDB
    await connectDB();

    // 2. Start Express API
    const PORT = process.env.PORT || 5000;
    app.listen(PORT, () => {
      console.log(`🚀 SkillMart API is LIVE on port ${PORT}`);
      console.log('✅ Mode: Human Analyst Verification (No AI)');
    });
  } catch (error) {
    console.error('CRITICAL STARTUP ERROR:', error);
    process.exit(1);
  }
};

startServer();