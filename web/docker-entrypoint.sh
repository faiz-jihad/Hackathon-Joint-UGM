#!/bin/sh
set -e

echo "🚀 [RETIVA Web]: Starting container initialization..."

# Wait for PostgreSQL to be ready
echo "⏳ [RETIVA Web]: Verifying PostgreSQL database readiness..."
until nc -z -v -w30 postgres 5432 2>/dev/null || npx prisma db execute --stdin <<EOF
SELECT 1;
EOF
do
  echo "⏳ [RETIVA Web]: Database is unavailable - waiting 2s..."
  sleep 2
done

echo "✅ [RETIVA Web]: Database connection established!"

# Ensure Prisma Client is generated
echo "📦 [RETIVA Web]: Generating Prisma Client..."
npx prisma generate || true

# Push Prisma schema to database (zero downtime sync)
echo "📦 [RETIVA Web]: Syncing Prisma schema with PostgreSQL..."
npx prisma db push --skip-generate || true

# Seed database with initial facilities, users, and clinical data
echo "🌱 [RETIVA Web]: Seeding clinical reference data..."
npx prisma db seed || echo "⚠️ Seed already applied or completed."

echo "🚀 [RETIVA Web]: Initialization complete. Starting Next.js application..."
exec "$@"
