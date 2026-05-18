FROM node:20-slim

WORKDIR /app

# Copy package descriptors first to take advantage of Docker layering cache
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Copy application source code
COPY src ./src

# Expose backend port
EXPOSE 5000

# Run the backend service
CMD ["node", "src/server.js"]
