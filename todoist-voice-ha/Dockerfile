# Dockerfile for Todoist Voice HA Add-on
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.19
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Node.js and dependencies
# Check if we're on Alpine or Debian and install accordingly
RUN \
    if command -v apk >/dev/null; then \
        # Alpine-based
        apk add --no-cache nodejs npm curl; \
    else \
        # Debian-based
        apt-get update && \
        apt-get install -y --no-install-recommends nodejs npm curl && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Create app directory
WORKDIR /app

# Copy package files first (for better Docker layer caching)
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy app source
COPY src/ ./src/
COPY *.js ./

# Create non-root user (compatible with both Alpine and Debian)
RUN \
    if command -v adduser >/dev/null && adduser --help 2>&1 | grep -q BusyBox; then \
        # Alpine
        addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001 -G nodejs; \
    else \
        # Debian
        useradd -r -u 1001 -g root nodejs; \
    fi

# Change ownership
RUN chown -R nodejs:$(id -gn nodejs) /app
USER nodejs

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start the application
CMD ["node", "src/server.js"]