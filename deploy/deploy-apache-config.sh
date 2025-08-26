#!/bin/bash
# Deploy Apache configuration to server
# Run from project root: ./deploy/deploy-apache-config.sh

set -e  # Exit on any error

echo "=== Deploying Apache config to monkeys ==="

# Step 1: Copy config to server temp location
echo "1. Copying config to server..."
scp apache-config/ordiwedding monkeys:/tmp/ordiwedding.tmp

# Step 2: Install and enable on server
echo "2. Installing config..."

# Copy to Apache's sites-available directory
# Note: Old Apache 2.2 doesn't use .conf extension
sumo "cp /tmp/ordiwedding.tmp /etc/apache2/sites-available/ordiwedding"
ssh monkeys "rm /tmp/ordiwedding.tmp"

echo "3. Enabling site if needed..."

# a2ensite = Apache2 Enable Site
# Creates symlink from sites-available to sites-enabled
if ! ssh monkeys "test -L /etc/apache2/sites-enabled/ordiwedding"; then
    sumo "/usr/sbin/a2ensite ordiwedding"
    echo "   Site enabled (symlink created)"
else
    echo "   Site already enabled"
fi

echo "4. Testing configuration..."

# apache2ctl configtest = Validates Apache config syntax
# Checks for errors WITHOUT affecting running server
sumo "/usr/sbin/apache2ctl configtest"

echo ""
echo "=== Deployment complete! ==="
echo ""
echo "To activate the new configuration:"
echo "  sumo '/usr/sbin/apache2ctl graceful'"
echo ""
echo "Notes on apache2ctl graceful:"
echo "  - Reloads config without dropping active connections"
echo "  - Current requests complete with old config"
echo "  - New requests use new config"
echo "  - Safer than 'restart' which drops all connections"