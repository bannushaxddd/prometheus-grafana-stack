FROM node:20-alpine

WORKDIR /usr/src/app

COPY package.json ./
RUN npm install --omit=dev

COPY server.js ./
COPY public/index.html ./public/index.html

EXPOSE 3000

# Lightweight healthcheck without curl
RUN apk add --no-cache wget

USER node
CMD ["node", "server.js"]
