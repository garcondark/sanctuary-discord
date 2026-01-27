# Home Sanctuary - Deployment Package

## What's Included

This package contains everything you need to deploy the Home Sanctuary cleaning tracker as a traditional web application with backend services.

### Complete File Structure

```
home-sanctuary/
├── deploy.sh                    # Deployment script (run with: sudo bash deploy.sh)
├── uninstall.sh                 # Uninstall script
├── README.md                    # Full documentation
├── package.json                 # Node.js dependencies
├── api-server.js                # Express API backend (port 3000)
├── discord-notifier.js          # Discord notification script
├── web/
│   └── index.html               # React frontend application
├── systemd/
│   ├── home-sanctuary-api.service                      # API server service
│   ├── home-sanctuary-notify.service                   # Notification service
│   ├── home-sanctuary-weekday-weekly-monthly.timer     # Mon-Fri 12PM
│   ├── home-sanctuary-weekday-daily.timer              # Mon-Fri 7PM
│   ├── home-sanctuary-weekend-weekly-monthly.timer     # Sat-Sun 7AM
│   └── home-sanctuary-weekend-daily.timer              # Sat-Sun 12PM
└── nginx/
    └── home-sanctuary.conf      # Nginx configuration
```

## Quick Start

1. **Download the entire `home-sanctuary` folder** to your Linux server

2. **Run the deployment script:**
   ```bash
   cd home-sanctuary
   sudo bash deploy.sh
   ```

3. **Access the web interface:**
   - Open http://sanctuary.local in your browser
   - Or use http://YOUR_SERVER_IP

4. **Configure Discord notifications:**
   - Click "Settings" button in the web UI
   - Enter your Discord webhook URL
   - Click "Save Settings"

5. **Start using it:**
   - Click tasks to mark them complete
   - Progress bars update automatically
   - Tasks sync across all devices
   - Automated notifications send at scheduled times

## Key Features Implemented

✅ **Multi-Device Sync**: Backend API with JSON storage - all devices see the same data
✅ **Discord Notifications**: Automated and manual notifications
✅ **Smart Scheduling**: Different times for weekdays/weekends
✅ **Persistent Storage**: Tasks and settings saved on server
✅ **Beautiful UI**: Kept 100% of the original design and functionality
✅ **System Integration**: Runs as systemd services with auto-start

## Notification Schedule

**Weekdays (Mon-Fri):**
- Weekly/Monthly tasks → 12:00 PM
- Daily tasks → 7:00 PM

**Weekends (Sat-Sun):**
- Weekly/Monthly tasks → 7:00 AM
- Daily tasks → 12:00 PM

## Technical Architecture

### Frontend (index.html)
- React application with original UI completely intact
- Polls backend API every 2 seconds for updates
- No localStorage - uses backend API instead
- Works on any device with a browser

### Backend (api-server.js)
- Express.js server on port 3000
- REST API endpoints for tasks and webhook
- Stores data in `/opt/home-sanctuary/data.json`
- Runs continuously via systemd

### Notification System (discord-notifier.js)
- Standalone script triggered by systemd timers
- Reads tasks and webhook from shared JSON file
- Determines which tasks are due based on date/time
- Sends formatted messages to Discord

### Web Server (nginx)
- Serves static files from /opt/home-sanctuary/web
- Proxies /api/* requests to Express backend
- Configured for sanctuary.local domain

## What Changed from the Artifact

**Removed:**
- Claude's `window.storage` API calls
- Artifact-specific dependencies

**Added:**
- Express.js backend API server
- REST API endpoints (/api/data, /api/tasks, /api/webhook, /api/notify)
- JSON file storage (data.json)
- Systemd service for API server
- Systemd service for notifications
- Four systemd timers for scheduling
- Nginx configuration
- Multi-device polling system

**Preserved:**
- 100% of original UI design
- All visual styles and animations
- All interactive features
- Progress tracking
- Task completion states
- Settings modal
- Notification toasts
- Responsive design

## Usage Commands

```bash
# View what's running
systemctl list-timers | grep sanctuary
systemctl status home-sanctuary-api

# View logs
journalctl -u home-sanctuary-api -f
journalctl -u home-sanctuary-notify -f

# Manual notification test
cd /opt/home-sanctuary
node discord-notifier.js

# Restart API server
sudo systemctl restart home-sanctuary-api

# Complete uninstall
sudo bash uninstall.sh
```

## Domain Name (sanctuary.local)

The deploy script automatically adds `sanctuary.local` to `/etc/hosts`, so you can access the application at:
- http://sanctuary.local (from any device on the network that can resolve the hostname)
- http://YOUR_SERVER_IP (always works from network devices)
- http://localhost (from the server itself)

If you want other devices to use sanctuary.local, either:
1. Set up local DNS, or
2. Add `SERVER_IP sanctuary.local` to each device's hosts file

## Troubleshooting

**Web interface won't load:**
```bash
sudo systemctl status home-sanctuary-api
curl http://localhost:3000/health
```

**Notifications not working:**
```bash
# Check webhook is configured
cat /opt/home-sanctuary/data.json | grep webhookUrl

# Test manually
cd /opt/home-sanctuary
node discord-notifier.js
```

**Tasks not syncing:**
```bash
# API logs will show any errors
journalctl -u home-sanctuary-api -n 100
```

## Next Steps

1. Deploy using `sudo bash deploy.sh`
2. Access http://sanctuary.local
3. Add your Discord webhook URL in Settings
4. Customize the default tasks if needed
5. Start tracking your cleaning routine!

See README.md for full documentation.
