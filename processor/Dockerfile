FROM node:20-alpine

WORKDIR /app

# Install dependencies first (for better caching)
COPY package.json package-lock.json* ./
RUN npm install

# Copy application code
COPY . .

# Start the application
CMD ["node", "index.js"]
