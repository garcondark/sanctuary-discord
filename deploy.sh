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
cp "$SCRIPT_DIR/api-server.js" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/discord-notifier.js" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/package.json" "$INSTALL_DIR/"
cp -r "$SCRIPT_DIR/web" "$INSTALL_DIR/"

# Make scripts executable
chmod +x "$INSTALL_DIR/api-server.js"
chmod +x "$INSTALL_DIR/discord-notifier.js"

echo ""
echo "📦 Installing Node.js dependencies..."
cd "$INSTALL_DIR"
npm install --production

# Set ownership
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$INSTALL_DIR"

echo ""
echo "⚙️  Installing systemd services and timers..."
cp "$SCRIPT_DIR/systemd/home-sanctuary-api.service" /etc/systemd/system/
cp "$SCRIPT_DIR/systemd/home-sanctuary-notify.service" /etc/systemd/system/
cp "$SCRIPT_DIR/systemd/home-sanctuary-weekday-weekly-monthly.timer" /etc/systemd/system/
cp "$SCRIPT_DIR/systemd/home-sanctuary-weekday-daily.timer" /etc/systemd/system/
cp "$SCRIPT_DIR/systemd/home-sanctuary-weekend-weekly-monthly.timer" /etc/systemd/system/
cp "$SCRIPT_DIR/systemd/home-sanctuary-weekend-daily.timer" /etc/systemd/system/

# Update service files with actual username
sed -i "s/User=claude/User=$ACTUAL_USER/" /etc/systemd/system/home-sanctuary-api.service
sed -i "s/User=claude/User=$ACTUAL_USER/" /etc/systemd/system/home-sanctuary-notify.service

systemctl daemon-reload

# Enable and start API service
systemctl enable home-sanctuary-api.service
systemctl start home-sanctuary-api.service

# Enable and start timers
systemctl enable home-sanctuary-weekday-weekly-monthly.timer
systemctl enable home-sanctuary-weekday-daily.timer
systemctl enable home-sanctuary-weekend-weekly-monthly.timer
systemctl enable home-sanctuary-weekend-daily.timer
systemctl start home-sanctuary-weekday-weekly-monthly.timer
systemctl start home-sanctuary-weekday-daily.timer
systemctl start home-sanctuary-weekend-weekly-monthly.timer
systemctl start home-sanctuary-weekend-daily.timer

echo ""
echo "🌐 Configuring nginx..."
cp "$SCRIPT_DIR/nginx/home-sanctuary.conf" /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/home-sanctuary.conf /etc/nginx/sites-enabled/

# Test nginx config
nginx -t

systemctl reload nginx

echo ""
echo "🔧 Setting up sanctuary.local hostname..."
if ! grep -q "sanctuary.local" /etc/hosts; then
  echo "127.0.0.1 sanctuary.local" >> /etc/hosts
  echo "✓ Added sanctuary.local to /etc/hosts"
fi

echo ""
echo "✅ Testing API server..."
sleep 2
curl -s http://localhost:3000/health && echo "✓ API server is running!" || echo "⚠️  API server check failed"

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║   Deployment Complete!                     ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "📊 Service Status:"
systemctl status home-sanctuary-api.service --no-pager -l | head -3
echo ""
echo "⏰ Timer Status:"
systemctl list-timers | grep -E "sanctuary|NEXT|LEFT"
echo ""
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "🌐 Web UI Access:"
echo "   Local:              http://sanctuary.local"
echo "   By IP:              http://$LOCAL_IP"
echo "   From this machine:  http://localhost"
echo ""
echo "⚙️  Next Steps:"
echo "   1. Open http://sanctuary.local in your browser"
echo "   2. Click 'Settings' to add your Discord webhook URL"
echo "   3. Start checking off tasks!"
echo ""
echo "📝 Useful commands:"
echo "   View API logs:      journalctl -u home-sanctuary-api -f"
echo "   View notify logs:   journalctl -u home-sanctuary-notify -f"
echo "   Check timers:       systemctl list-timers | grep sanctuary"
echo "   Test notification:  cd $INSTALL_DIR && node discord-notifier.js"
echo "   Restart API:        sudo systemctl restart home-sanctuary-api"
echo ""
echo "📅 Notification Schedule:"
echo "   Weekdays: Weekly/Monthly at 12PM, Daily at 7PM"
echo "   Weekends: Weekly/Monthly at 7AM, Daily at 12PM"
echo ""
