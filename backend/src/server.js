const http = require('http');
const { Server } = require('socket.io');
require('dotenv').config();

const app = require('./app');
const connectDB = require('./config/db');
const initChat = require('./sockets/chatSocket');

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

connectDB();
initChat(io);

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => console.log(` Server & Socket running on port ${PORT}`));