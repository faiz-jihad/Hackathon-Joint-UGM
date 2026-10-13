FROM node:20-alpine

WORKDIR /app

# Install system dependencies required for Prisma native engines and entrypoint checks
RUN apk add --no-cache \
    libc6-compat \
    openssl \
    netcat-openbsd \
    curl

# Install node dependencies
COPY package*.json ./
RUN npm install

# Copy Prisma schema and generate client
COPY prisma ./prisma/
RUN npx prisma generate || true

# Copy project files
COPY . .

# Configure entrypoint script for automatic database schema sync and seeding
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 3000

ENV NODE_ENV=development
ENV PORT=3000

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["npm", "run", "dev"]
