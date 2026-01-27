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
systemctl stop home-sanctuary-api.service 2>/dev/null || true
systemctl stop home-sanctuary-notify.service 2>/dev/null || true
systemctl stop home-sanctuary-weekday-weekly-monthly.timer 2>/dev/null || true
systemctl stop home-sanctuary-weekday-daily.timer 2>/dev/null || true
systemctl stop home-sanctuary-weekend-weekly-monthly.timer 2>/dev/null || true
systemctl stop home-sanctuary-weekend-daily.timer 2>/dev/null || true

systemctl disable home-sanctuary-api.service 2>/dev/null || true
systemctl disable home-sanctuary-notify.service 2>/dev/null || true
systemctl disable home-sanctuary-weekday-weekly-monthly.timer 2>/dev/null || true
systemctl disable home-sanctuary-weekday-daily.timer 2>/dev/null || true
systemctl disable home-sanctuary-weekend-weekly-monthly.timer 2>/dev/null || true
systemctl disable home-sanctuary-weekend-daily.timer 2>/dev/null || true

echo "🗑️  Removing systemd files..."
rm -f /etc/systemd/system/home-sanctuary-api.service
rm -f /etc/systemd/system/home-sanctuary-notify.service
rm -f /etc/systemd/system/home-sanctuary-weekday-weekly-monthly.timer
rm -f /etc/systemd/system/home-sanctuary-weekday-daily.timer
rm -f /etc/systemd/system/home-sanctuary-weekend-weekly-monthly.timer
rm -f /etc/systemd/system/home-sanctuary-weekend-daily.timer
systemctl daemon-reload

echo "🌐 Removing nginx configuration..."
rm -f /etc/nginx/sites-enabled/home-sanctuary.conf
rm -f /etc/nginx/sites-available/home-sanctuary.conf
nginx -t && systemctl reload nginx

echo "🗑️  Removing sanctuary.local from /etc/hosts..."
sed -i '/sanctuary.local/d' /etc/hosts 2>/dev/null || true

echo "📁 Removing installation directory..."
read -p "Remove /opt/home-sanctuary and all data? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  rm -rf /opt/home-sanctuary
  echo "✓ Installation directory removed"
else
  echo "⚠️  Kept /opt/home-sanctuary"
  echo "   You can add a webhook URL to data.json and redeploy"
fi

echo ""
echo "✅ Home Sanctuary has been uninstalled!"
echo ""
echo "The web interface is no longer accessible."
echo "No scheduled notifications will be sent."
echo ""
