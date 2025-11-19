#!/bin/bash
# Setup PostgreSQL database and user for Cinematico

set -e

echo "Setting up PostgreSQL database..."

# Check if PostgreSQL is running
if ! pg_isready -q; then
  echo "PostgreSQL is not running. Please start PostgreSQL first."
  echo "On macOS with Homebrew: brew services start postgresql@15"
  exit 1
fi

# Get current user
CURRENT_USER=$(whoami)

# Create user if it doesn't exist
echo "Creating user 'cinematico'..."
psql -d postgres -c "CREATE USER cinematico WITH PASSWORD 'cinematico';" 2>/dev/null || echo "User 'cinematico' may already exist"

# Create databases
echo "Creating databases..."
psql -d postgres -c "CREATE DATABASE cinematico_development OWNER cinematico;" 2>/dev/null || echo "Database 'cinematico_development' may already exist"
psql -d postgres -c "CREATE DATABASE cinematico_test OWNER cinematico;" 2>/dev/null || echo "Database 'cinematico_test' may already exist"

echo "Database setup complete!"
echo "You can now run: bin/rails db:migrate"

