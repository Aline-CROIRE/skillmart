const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const errorHandler = require('./middlewares/errorHandler');

const authRoutes = require('./routes/authRoutes');
const projectRoutes = require('./routes/projectRoutes');
const analystRoutes = require('./routes/analystRoutes');
const marketRoutes = require('./routes/marketRoutes');

const app = express();

app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(cors());
app.use(express.json());

app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/analyst', analystRoutes);
app.use('/api/market', marketRoutes);

app.get('/health', (req, res) => res.status(200).json({ status: 'UP' }));

app.use(errorHandler);

module.exports = app;