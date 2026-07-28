#!/bin/bash

# Home Sanctuary - Deployment Script
# Run with: sudo bash deploy.sh

set -e

echo "╔════════════════════════════════════════════╗"
echo "║   Home Sanctuary - Deployment Script       ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root: sudo bash deploy.sh"
  exit 1
fi

# Get the actual user (not root)
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ "$ACTUAL_USER" = "root" ]; then
  echo "❌ Please run with sudo from a non-root user"
  exit 1
fi

INSTALL_DIR="/opt/home-sanctuary"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📦 Installing system dependencies..."
apt-get update -qq
apt-get install -y nginx nodejs npm

echo ""
echo "📁 Creating installation directory..."
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/discord-notifier.js" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/package.json" "$INSTALL_DIR/"
cp -r "$SCRIPT_DIR/web" "$INSTALL_DIR/"

# Create .env file if it doesn't exist
if [ ! -f "$INSTALL_DIR/.env" ]; then
  echo ""
  echo "🔑 Setting up environment..."
  read -p "Enter your Discord Webhook URL: " WEBHOOK_URL
  echo "DISCORD_WEBHOOK_URL=$WEBHOOK_URL" > "$INSTALL_DIR/.env"
  chmod 600 "$INSTALL_DIR/.env"
fi

echo ""
echo "📦 Installing Node.js dependencies..."
cd "$INSTALL_DIR"
npm install --production

# Set ownership
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$INSTALL_DIR"

echo ""
echo "⚙️  Installing systemd service and timers..."
cp "$SCRIPT_DIR/systemd/home-sanctuary.service" /etc/systemd/system/
cp "$SCRIPT_DIR/systemd/home-sanctuary-weekday.timer" /etc/systemd/system/
cp "$SCRIPT_DIR/systemd/home-sanctuary-weekend.timer" /etc/systemd/system/

# Update service file with actual username
sed -i "s/User=claude/User=$ACTUAL_USER/" /etc/systemd/system/home-sanctuary.service

systemctl daemon-reload
systemctl enable home-sanctuary-weekday.timer
systemctl enable home-sanctuary-weekend.timer
systemctl restart home-sanctuary-weekday.timer
systemctl restart home-sanctuary-weekend.timer

echo ""
echo "🌐 Configuring nginx..."
cp "$SCRIPT_DIR/nginx/home-sanctuary.conf" /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/home-sanctuary.conf /etc/nginx/sites-enabled/

# Test nginx config
nginx -t

systemctl reload nginx

echo ""
echo "✅ Testing notification script..."
cd "$INSTALL_DIR"
sudo -u "$ACTUAL_USER" node discord-notifier.js && echo "✓ Test notification sent!" || echo "⚠️  Test failed - check your webhook URL"

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║   Deployment Complete!                     ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "📊 Timer Status:"
systemctl list-timers | grep -E "home-sanctuary|NEXT"
echo ""
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "🌐 Web UI Access:"
echo "   On this machine:    http://localhost"
echo "   From other devices: http://$LOCAL_IP"
echo ""
echo "📝 Useful commands:"
echo "   View logs:          journalctl -u home-sanctuary -f"
echo "   Test notification:  cd $INSTALL_DIR && node discord-notifier.js"
echo "   Check timers:       systemctl list-timers | grep sanctuary"
echo "   Edit webhook:       sudo nano $INSTALL_DIR/.env"
echo "   Edit tasks:         sudo nano $INSTALL_DIR/discord-notifier.js"
echo ""
