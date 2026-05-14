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

// FIX: Configure Helmet to allow cross-origin resource sharing (for file downloads)
app.use(helmet({
  crossOriginResourcePolicy: false,
  crossOriginEmbedderPolicy: false,
}));

app.use(cors());
app.use(express.json());

// STANDARDIZED PATH: Create 'uploads' folder inside 'backend' root
const uploadsDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// SERVE STATIC FILES
app.use('/uploads', express.static(uploadsDir));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/analyst', analystRoutes);
app.use('/api/market', marketRoutes);

app.get('/health', (req, res) => res.status(200).json({ status: 'UP' }));

app.use(errorHandler);

module.exports = app;