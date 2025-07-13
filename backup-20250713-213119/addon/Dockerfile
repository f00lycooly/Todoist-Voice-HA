ARG BUILD_FROM=ghcr.io/hassio-addons/base:15.0.7
FROM $BUILD_FROM

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Update package index and install dependencies
RUN apk update && apk add --no-cache \
    nodejs \
    npm \
    curl

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production || npm install --production

COPY src/ ./src/
RUN mkdir -p /data/logs

HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
CMD ["node", "src/server.js"]
