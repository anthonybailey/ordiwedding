#!/bin/bash
# Set up Postfix to relay outbound mail through Gmail SMTP.
# Run on monkeys under sudo: sudo ./setup-mail-relay.sh <app-password>
#
# Requires a Google App Password (not regular password).
# Generate at: https://myaccount.google.com/apppasswords

set -e

GMAIL_USER="anthony.bailey@gmail.com"

if [ -z "$1" ]; then
    echo "Usage: sudo $0 <google-app-password>"
    exit 1
fi

APP_PASSWORD="$1"

echo "=== Setting up Gmail SMTP relay ==="

echo "1. Creating SASL password file..."
echo "[smtp.gmail.com]:587 ${GMAIL_USER}:${APP_PASSWORD}" > /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd

echo "2. Configuring Postfix relay..."
postconf -e 'relayhost = [smtp.gmail.com]:587'
postconf -e 'smtp_sasl_auth_enable = yes'
postconf -e 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd'
postconf -e 'smtp_sasl_security_options = noanonymous'
postconf -e 'smtp_use_tls = yes'
postconf -e 'smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt'

echo "3. Reloading Postfix..."
/usr/sbin/postfix reload

echo ""
echo "=== Done! Test with: echo test | mail -s 'relay test' your@email.com ==="
