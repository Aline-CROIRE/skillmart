const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'SkillMart Advanced API',
      version: '2.0.0',
      description: 'Universal Project Marketplace API',
    },
    servers: [{ url: 'http://localhost:5000' }],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
  },
  apis: ['./src/app.js', './src/routes/*.js'],
};

const specs = swaggerJsdoc(options);
module.exports = specs;