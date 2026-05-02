const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const dotenv = require('dotenv');
const swaggerUi = require('swagger-ui-express');
const specs = require('./config/swagger');
const errorHandler = require('./middlewares/errorHandler');

dotenv.config();

const app = express();

app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(specs));

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    message: 'SkillMart API is running',
    timestamp: new Date().toISOString()
  });
});

app.use(errorHandler);

module.exports = app;