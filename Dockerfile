FROM node:23-alpine

RUN npm install -g pnpm

WORKDIR /app

COPY . .

RUN pnpm install

CMD ["pnpm", "run", "dev"]
