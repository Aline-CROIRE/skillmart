const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const dotenv = require('dotenv');
const path = require('path');
const swaggerUi = require('swagger-ui-express');
const specs = require('./config/swagger');
const errorHandler = require('./middlewares/errorHandler');
const projectRoutes = require('./routes/projectRoutes');

dotenv.config();

const app = express();

app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(specs));

app.use('/api/projects', projectRoutes);

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    message: 'SkillMart API is running',
    timestamp: new Date().toISOString()
  });
});

app.use(errorHandler);

module.exports = app;