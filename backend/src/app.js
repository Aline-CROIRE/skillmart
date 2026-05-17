const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const errorHandler = require('./middlewares/errorHandler');

const authRoutes = require('./routes/authRoutes');
const projectRoutes = require('./routes/projectRoutes');
const analystRoutes = require('./routes/analystRoutes');
const marketRoutes = require('./routes/marketRoutes');
const chatRoutes = require('./routes/chatRoutes'); // NEW
const adminRoutes = require('./routes/adminRoutes'); // NEW
const notificationRoutes = require('./routes/notificationRoutes'); // NEW
const testRoutes = require('./routes/testRoutes'); // TEMPORARY TEST
const swaggerUi = require('swagger-ui-express');
const swaggerSpecs = require('./config/swaggerConfig');

const app = express();

app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(cors());
app.use(express.json());

app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// REGISTER ALL ROUTES
app.use('/api/auth', authRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/analyst', analystRoutes);
app.use('/api/market', marketRoutes);
app.use('/api/chat', chatRoutes); // <--- FIXED: This solves the 404
app.use('/api/admin', adminRoutes); // NEW
app.use('/api/notifications', notificationRoutes); // NEW
app.use('/api/test', testRoutes); // TEMPORARY TEST
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpecs));

app.get('/health', (req, res) => res.status(200).json({ status: 'UP' }));
app.use(errorHandler);

module.exports = app;