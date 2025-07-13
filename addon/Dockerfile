# Dockerfile.addon - Enhanced for Home Assistant Add-on
ARG BUILD_FROM=ghcr.io/hassio-addons/base:15.0.7
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies
RUN apk add --no-cache \
    nodejs=20.10.0-r0 \
    npm=10.2.3-r0 \
    curl=8.5.0-r0 \
    tzdata=2023d-r0

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install Node.js dependencies
RUN npm ci --only=production \
    && npm cache clean --force

# Copy application source
COPY src/ ./src/
COPY config/ ./config/

# Create necessary directories
RUN mkdir -p /data/logs /data/cache

# Set permissions
RUN chmod +x src/server.js

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Labels for Home Assistant add-on
LABEL \
    io.hass.name="Todoist Voice HA" \
    io.hass.description="Intelligent conversational task creation for Todoist" \
    io.hass.arch="armhf|armv7|aarch64|amd64|i386" \
    io.hass.type="addon" \
    io.hass.version="2.0.0" \
    io.hass.stage="stable" \
    maintainer="Todoist Voice HA Team" \
    org.opencontainers.image.title="Todoist Voice HA" \
    org.opencontainers.image.description="Conversational AI assistant for Todoist task management" \
    org.opencontainers.image.source="https://github.com/your-username/todoist-voice-ha" \
    org.opencontainers.image.licenses="MIT"

# Expose port
EXPOSE 8080

# Start the application
CMD ["node", "src/server.js"]