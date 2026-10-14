#!/bin/sh
set -e

echo "🚀 [RETIVA Web Production]: Starting production container initialization..."

# Wait for PostgreSQL to be ready
echo "⏳ [RETIVA Web Production]: Verifying PostgreSQL database readiness..."
until nc -z -v -w30 postgres 5432 2>/dev/null
do
  echo "⏳ [RETIVA Web Production]: Database is unavailable - waiting 2s..."
  sleep 2
done

echo "✅ [RETIVA Web Production]: Database connection established!"

# Ensure Prisma Client is generated
echo "📦 [RETIVA Web Production]: Generating Prisma Client..."
npx prisma generate || true

# Push Prisma schema to database (auto-sync schema)
echo "📦 [RETIVA Web Production]: Syncing Prisma schema with PostgreSQL..."
npx prisma db push --skip-generate || true

# Seed database with initial facilities, users, and clinical reference data
echo "🌱 [RETIVA Web Production]: Seeding clinical reference data..."
npx prisma db seed || echo "ℹ️ [RETIVA Web Production]: Seed already applied or completed."

echo "🚀 [RETIVA Web Production]: Initialization complete. Starting Next.js production server..."
exec "$@"
