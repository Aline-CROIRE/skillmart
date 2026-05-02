const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'SkillMart API',
      version: '1.0.0',
      description: 'AI-Powered Project Analysis & Approval System API',
    },
    servers: [
      {
        url: 'http://localhost:5000',
        description: 'Development server',
      },
    ],
  },
  apis: ['./src/app.js', './src/routes/*.js'],
};

const specs = swaggerJsdoc(options);
module.exports = specs;