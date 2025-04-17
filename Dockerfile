FROM node:23.0.1-alpine3.18

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

CMD ["node", "app.js"]