#!/bin/bash
# Deploy content pages to server
# Run from project root: ./deploy/deploy-pages.sh
#
# Prerequisites (run once, needs sumo):
#   sumo "mkdir -p /var/www/ordiwedding/-"
#   sumo "chown anthony:anthony /var/www/ordiwedding/-"

set -e  # Exit on any error

echo "=== Deploying pages to monkeys ==="

# Copy page files directly (anthony owns the target directory)
echo "1. Syncing page files..."
rsync -av --delete pages/ monkeys:/var/www/ordiwedding/-/

echo ""
echo "=== Pages deployment complete! ==="
echo "Test at: https://ordi.wedding/-/"
