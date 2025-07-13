FROM node:20-alpine

# Install system dependencies
RUN apk add --no-cache curl bash

WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install Node.js dependencies
RUN npm install --only=production

# Copy application source
COPY src/ ./src/

# Create required directories
RUN mkdir -p /data/logs /data/cache

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Expose port
EXPOSE 8080

# Start the application
CMD ["node", "src/server.js"]
