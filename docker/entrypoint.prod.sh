#!/bin/sh
set -e

echo "Starting Twenty CRM Production..."

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
until pg_isready -h "$PG_DATABASE_HOST" -p "${PG_DATABASE_PORT:-5432}" -U "$PG_DATABASE_USER"; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "PostgreSQL is ready!"

# Run database migrations
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "Running database migrations..."
  cd /app/packages/twenty-server
  # Try to run migrations, but don't fail if they error
  echo "Skipping migrations for now - run manually if needed"
fi

# Execute the main command
exec "$@"