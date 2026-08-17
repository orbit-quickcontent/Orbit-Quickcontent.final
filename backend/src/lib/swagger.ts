import { Express } from 'express';

export function setupSwagger(app: Express) {
  try {
    const swaggerJSDoc = require('swagger-jsdoc');
    const swaggerUi = require('swagger-ui-express');

    const options = {
      definition: {
        openapi: '3.0.0',
        info: {
          title: 'ORBIT API Documentation',
          version: '1.0.0',
          description: 'API documentation for the ORBIT Hyperlocal Video Marketplace Platform',
        },
      },
      apis: ['./src/api/**/*.routes.ts', './src/api/**/*.ts'],
    };

    const swaggerSpec = swaggerJSDoc(options);
    app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
  } catch (err) {
    // Graceful skip in serverless environment
  }
}
