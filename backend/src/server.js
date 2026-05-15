const http = require('http');
const { Server } = require('socket.io');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const app = require('./app');
const connectDB = require('./config/db');
const seedAdmin = require('./config/seed');
const initChat = require('./sockets/chatSocket');

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*", methods: ["GET", "POST"] }
});

const startServer = async () => {
  try {
    await connectDB();
    await seedAdmin();
    
    // Initialize Socket.io Chat
    initChat(io);

    const PORT = process.env.PORT || 5000;
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 SkillMart Hybrid Server running on port ${PORT}`);
      console.log('✅ Real-time Chat Gateway Enabled');
    });
  } catch (error) {
    console.error('SERVER FATAL ERROR:', error);
    process.exit(1);
  }
};

startServer();