#!/bin/bash
# Deploy Apache configuration to server
# Run from project root: ./deploy/deploy-apache-config.sh

set -e  # Exit on any error

echo "=== Deploying Apache config to monkeys ==="

# Step 1: Copy config to server temp location
echo "1. Copying config to server..."
scp apache-config/ordiwedding.conf monkeys:/tmp/ordiwedding.conf.tmp

# Step 2: Install and enable on server
ssh monkeys "
    echo '2. Installing config...'
    
    # Copy to Apache's sites-available directory
    # sites-available = storage for all possible site configs
    sudo cp /tmp/ordiwedding.conf.tmp /etc/apache2/sites-available/ordiwedding.conf
    rm /tmp/ordiwedding.conf.tmp
    
    echo '3. Enabling site if needed...'
    
    # a2ensite = Apache2 Enable Site
    # Creates symlink from sites-available to sites-enabled
    # Apache only loads configs from sites-enabled/
    if [ ! -L /etc/apache2/sites-enabled/ordiwedding.conf ]; then
        sudo a2ensite ordiwedding
        echo '   Site enabled (symlink created)'
    else
        echo '   Site already enabled'
    fi
    
    echo '4. Testing configuration...'
    
    # apache2ctl configtest = Validates Apache config syntax
    # Checks for errors WITHOUT affecting running server
    # Returns 'Syntax OK' or specific error messages
    sudo apache2ctl configtest
"

echo ""
echo "=== Deployment complete! ==="
echo ""
echo "To activate the new configuration:"
echo "  ssh monkeys 'sudo apache2ctl graceful'"
echo ""
echo "Notes on apache2ctl graceful:"
echo "  - Reloads config without dropping active connections"
echo "  - Current requests complete with old config"
echo "  - New requests use new config"
echo "  - Safer than 'restart' which drops all connections"