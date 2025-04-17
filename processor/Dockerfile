FROM node:23-alpine-slim

WORKDIR /app

# Install dependencies first (for better caching)
COPY package.json package-lock.json* ./
RUN npm install

# Copy application code
COPY . .

# Start the application
CMD ["node", "index.js"]
