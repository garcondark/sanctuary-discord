# Home Sanctuary - Cleaning Task Tracker

A beautiful, functional web-based cleaning task tracker with Discord notifications and multi-device sync.

## Features

- ✨ **Beautiful UI** - Elegant, responsive interface with smooth animations
- 🔄 **Multi-Device Sync** - Tasks sync automatically across all devices
- 📱 **Discord Notifications** - Automated reminders sent to Discord
- ⏰ **Smart Scheduling** - Different notification times for weekdays and weekends
- 📊 **Progress Tracking** - Visual progress bars for each task category
- 🎯 **Task Categories** - Daily, Weekly, and Monthly tasks

## Installation

### Prerequisites

- Ubuntu/Debian-based Linux system
- Root/sudo access
- Node.js and npm (installed automatically)
- nginx (installed automatically)

### Quick Install

1. Download all files to a directory
2. Run the deployment script:

```bash
sudo bash deploy.sh
```

3. Open http://sanctuary.local in your browser
4. Click "Settings" to add your Discord webhook URL
5. Start tracking your cleaning tasks!

## Notification Schedule

The system sends notifications at different times based on the day and task type:

**Weekdays (Monday-Friday):**
- Weekly/Monthly tasks: 12:00 PM
- Daily tasks: 7:00 PM

**Weekends (Saturday-Sunday):**
- Weekly/Monthly tasks: 7:00 AM
- Daily tasks: 12:00 PM

## Architecture

### Frontend
- Single-page React application
- Polls backend API every 2 seconds for updates
- Responsive design for mobile and desktop
- Located in `/opt/home-sanctuary/web/`

### Backend
- Express.js API server running on port 3000
- JSON file storage for tasks and settings
- Endpoints:
  - `GET /api/data` - Fetch all tasks and webhook
  - `POST /api/tasks` - Save tasks
  - `POST /api/webhook` - Save webhook URL
  - `POST /api/notify` - Trigger manual notification
  - `GET /health` - Health check

### Services
- **home-sanctuary-api.service** - Runs the API server continuously
- **home-sanctuary-notify.service** - Runs notification script (triggered by timers)

### Timers
- **home-sanctuary-weekday-weekly-monthly.timer** - Mon-Fri 12:00 PM
- **home-sanctuary-weekday-daily.timer** - Mon-Fri 7:00 PM
- **home-sanctuary-weekend-weekly-monthly.timer** - Sat-Sun 7:00 AM
- **home-sanctuary-weekend-daily.timer** - Sat-Sun 12:00 PM

## File Structure

```
/opt/home-sanctuary/
├── api-server.js           # Express API server
├── discord-notifier.js     # Discord notification script
├── package.json            # Node.js dependencies
├── data.json               # Task and webhook storage
└── web/
    └── index.html          # Frontend application

/etc/systemd/system/
├── home-sanctuary-api.service
├── home-sanctuary-notify.service
├── home-sanctuary-weekday-weekly-monthly.timer
├── home-sanctuary-weekday-daily.timer
├── home-sanctuary-weekend-weekly-monthly.timer
└── home-sanctuary-weekend-daily.timer

/etc/nginx/sites-available/
└── home-sanctuary.conf
```

## Usage

### Web Interface

Access the web interface at:
- http://sanctuary.local
- http://localhost (from the server)
- http://YOUR_SERVER_IP (from other devices on network)

### Manual Notification

Test notifications manually:
```bash
cd /opt/home-sanctuary
node discord-notifier.js
```

### View Logs

API server logs:
```bash
journalctl -u home-sanctuary-api -f
```

Notification logs:
```bash
journalctl -u home-sanctuary-notify -f
```

### Check Timer Status

```bash
systemctl list-timers | grep sanctuary
```

### Restart API Server

```bash
sudo systemctl restart home-sanctuary-api
```

## Discord Webhook Setup

1. Open Discord and go to your server
2. Click Server Settings → Integrations → Webhooks
3. Click "New Webhook"
4. Choose a channel for notifications
5. Copy the webhook URL
6. In Home Sanctuary, click "Settings" and paste the URL

## Customization

### Modify Tasks

Edit `/opt/home-sanctuary/data.json` to change default tasks, then restart the API:
```bash
sudo systemctl restart home-sanctuary-api
```

### Change Notification Times

Edit the timer files in `/etc/systemd/system/` and reload:
```bash
sudo systemctl daemon-reload
sudo systemctl restart home-sanctuary-*.timer
```

### Change Port

Edit `/opt/home-sanctuary/api-server.js` and change the PORT variable, then update nginx config.

## Troubleshooting

### Web interface won't load
```bash
# Check API service
sudo systemctl status home-sanctuary-api

# Check nginx
sudo systemctl status nginx

# Test API directly
curl http://localhost:3000/health
```

### Notifications not sending
```bash
# Check webhook URL is set
cat /opt/home-sanctuary/data.json | grep webhookUrl

# Test manually
cd /opt/home-sanctuary && node discord-notifier.js

# Check timer status
systemctl list-timers | grep sanctuary
```

### Tasks not syncing between devices
```bash
# Check API is running
sudo systemctl status home-sanctuary-api

# Check data file permissions
ls -la /opt/home-sanctuary/data.json

# View API logs
journalctl -u home-sanctuary-api -n 50
```

## Uninstallation

To completely remove Home Sanctuary:

```bash
sudo bash uninstall.sh
```

This will:
- Stop and disable all services and timers
- Remove systemd files
- Remove nginx configuration
- Optionally remove the installation directory

## Security Notes

- The web interface is accessible to anyone on your local network
- Data is stored in plain text JSON
- No authentication is implemented
- Suitable for home use on a trusted network
- For internet exposure, add authentication and use HTTPS

## License

MIT

## Support

For issues or questions, check the logs and refer to the troubleshooting section above.
