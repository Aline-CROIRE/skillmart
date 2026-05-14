const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const fs = require('fs');
const errorHandler = require('./middlewares/errorHandler');

const authRoutes = require('./routes/authRoutes');
const projectRoutes = require('./routes/projectRoutes');
const analystRoutes = require('./routes/analystRoutes');
const marketRoutes = require('./routes/marketRoutes');

const app = express();

app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(cors());
app.use(express.json());

// FOOLPROOF STATIC PATH: Uses the root of the project
const rootDir = process.cwd();
const uploadsDir = path.join(rootDir, 'uploads');

// Ensure the folder exists so the server doesn't throw a hidden error
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

app.use('/uploads', express.static(uploadsDir));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/analyst', analystRoutes);
app.use('/api/market', marketRoutes);

app.get('/health', (req, res) => res.status(200).json({ status: 'UP' }));

app.use(errorHandler);

module.exports = app;