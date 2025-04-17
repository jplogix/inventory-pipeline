FROM node:23-alpine3.18-slim

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

CMD ["node", "index.js"]