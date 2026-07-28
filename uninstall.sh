#!/bin/bash

# Home Sanctuary - Uninstall Script
# Run with: sudo bash uninstall.sh

set -e

echo "╔════════════════════════════════════════════╗"
echo "║   Home Sanctuary - Uninstall Script        ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root: sudo bash uninstall.sh"
  exit 1
fi

echo "🛑 Stopping and disabling services..."
systemctl stop home-sanctuary-weekday.timer 2>/dev/null || true
systemctl stop home-sanctuary-weekend.timer 2>/dev/null || true
systemctl disable home-sanctuary-weekday.timer 2>/dev/null || true
systemctl disable home-sanctuary-weekend.timer 2>/dev/null || true
systemctl stop home-sanctuary.service 2>/dev/null || true
systemctl disable home-sanctuary.service 2>/dev/null || true
systemctl stop home-sanctuary-api.service 2>/dev/null || true
systemctl disable home-sanctuary-api.service 2>/dev/null || true

echo "🗑️  Removing systemd files..."
rm -f /etc/systemd/system/home-sanctuary.service
rm -f /etc/systemd/system/home-sanctuary-api.service
rm -f /etc/systemd/system/home-sanctuary-weekday.timer
rm -f /etc/systemd/system/home-sanctuary-weekend.timer
systemctl daemon-reload

echo "🌐 Removing nginx configuration..."
rm -f /etc/nginx/sites-enabled/home-sanctuary.conf
rm -f /etc/nginx/sites-available/home-sanctuary.conf
nginx -t && systemctl reload nginx

echo "📁 Removing installation directory..."
read -p "Remove /opt/home-sanctuary and all data? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  rm -rf /opt/home-sanctuary
  echo "✓ Installation directory removed"
else
  echo "⚠️  Kept /opt/home-sanctuary (you can manually add webhook URL and redeploy)"
fi

echo ""
echo "✅ Home Sanctuary has been uninstalled!"
echo ""
echo "The web interface is no longer accessible."
echo "No scheduled notifications will be sent."
echo ""