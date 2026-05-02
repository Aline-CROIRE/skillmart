const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const dotenv = require('dotenv');

dotenv.config();

const app = express();

// Global Middlewares
app.use(helmet()); // Security headers
app.use(cors());   // Enable CORS
app.use(morgan('dev')); // Logging
app.use(express.json()); // Body parser
app.use(express.urlencoded({ extended: true }));

/**
 * @openapi
 * /health:
 *   get:
 *     description: Check if the API is running
 *     responses:
 *       200:
 *         description: Returns a success message and timestamp.
 */
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'UP',
        message: 'SkillMart API is running',
        timestamp: new Date().toISOString()
    });
});

module.exports = app;