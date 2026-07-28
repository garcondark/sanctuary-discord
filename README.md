# Home Sanctuary

Cleaning task tracker with scheduled Discord notifications, designed to run 24/7 on a NanoPC-T6 (or any Ubuntu server).

## Features

- **Web UI** — Track daily, weekly, and monthly cleaning tasks from any device on your network
- **Discord Notifications** — Automated reminders at 5:45 AM on weekdays and 7 AM on weekends
- **Persistent Storage** — Tasks saved in browser localStorage
- **Reliable Scheduling** — Systemd timers with automatic start on boot

## Quick Start (On Your NanoPC-T6)

These instructions assume you're working directly on your NanoPC-T6 (e.g., using Claude in the browser on the SBC itself).

### 1. Download the Project

Download the `cleaning-bot` folder from Claude to your Downloads folder, then open a terminal:

```bash
# Move to your home directory
cd ~

# Extract or move the downloaded folder
mv ~/Downloads/cleaning-bot ~/cleaning-bot

# Or if downloaded as a zip:
# unzip ~/Downloads/cleaning-bot.zip -d ~/
```

### 2. Run the Deployment Script

```bash
cd ~/cleaning-bot
sudo bash deploy.sh
```

The script will:
- Install Node.js, npm, and nginx
- Prompt you for your Discord webhook URL
- Set up the notification script
- Configure systemd timers for the notification schedule
- Deploy the web UI via nginx
- Send a test notification to verify everything works

### 3. Access the Web UI

Once deployed, open a browser and go to:
- `http://localhost` (on the NanoPC-T6 itself)
- `http://YOUR_LOCAL_IP` (from other devices on your network)

To find your local IP:
```bash
hostname -I | awk '{print $1}'
```

## Manual Installation

If you prefer to set things up step-by-step:

### 1. Install Dependencies

```bash
sudo apt update
sudo apt install -y nginx nodejs npm
```

### 2. Set Up the Notification Script

```bash
sudo mkdir -p /opt/home-sanctuary
sudo cp discord-notifier.js package.json /opt/home-sanctuary/
sudo cp -r web /opt/home-sanctuary/
cd /opt/home-sanctuary
sudo npm install
```

### 3. Create Environment File

```bash
sudo nano /opt/home-sanctuary/.env
```

Add your webhook URL:
```
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN
```

Then secure the file:
```bash
sudo chmod 600 /opt/home-sanctuary/.env
```

### 4. Install Systemd Service and Timers

```bash
sudo cp systemd/*.service systemd/*.timer /etc/systemd/system/

# Update the service file with your username
sudo sed -i "s/User=claude/User=$USER/" /etc/systemd/system/home-sanctuary.service

sudo systemctl daemon-reload
sudo systemctl enable --now home-sanctuary-weekday.timer
sudo systemctl enable --now home-sanctuary-weekend.timer
```

### 5. Configure Nginx

```bash
sudo cp nginx/home-sanctuary.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/home-sanctuary.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## Remote Access (Optional)

If you want to manage your NanoPC-T6 from another computer later:

```bash
# From another machine on your network:
ssh your-username@YOUR_NANOPC_IP

# Or set up SSH keys for passwordless login:
ssh-copy-id your-username@YOUR_NANOPC_IP
```

To find your NanoPC-T6's IP address (run this on the SBC):
```bash
hostname -I | awk '{print $1}'
```

---

## Schedule

| Day | Time | Description |
|-----|------|-------------|
| Mon–Fri | 5:45 AM | Morning reminder for weekday tasks |
| Sat–Sun | 7:00 AM | Morning reminder for weekend tasks |

To modify the schedule, edit the timer files. These live in two places: the repo's
`systemd/*.timer` files are the source of truth used by `deploy.sh`, while the copies
under `/etc/systemd/system/` are what actually runs. To change the live schedule directly:

```bash
sudo nano /etc/systemd/system/home-sanctuary-weekday.timer
sudo nano /etc/systemd/system/home-sanctuary-weekend.timer
sudo systemctl daemon-reload
# daemon-reload alone does NOT re-arm a running timer — restart it too:
sudo systemctl restart home-sanctuary-weekday.timer home-sanctuary-weekend.timer
```

Prefer editing the repo's `systemd/*.timer` files and re-running `sudo bash deploy.sh`
(see [Updating / Refreshing an install](#updating--refreshing-an-install)) so your source
and the live install stay in sync.

## Updating / Refreshing an install

Your local checkout is only the **source**. The running instance is a separate deployed
copy:

| What | Where |
|------|-------|
| Source (this repo) | `~/sanctuary-discord` (wherever you cloned it) |
| Live app files | `/opt/home-sanctuary/` |
| Live systemd units | `/etc/systemd/system/home-sanctuary*.{service,timer}` |
| Live config | `/opt/home-sanctuary/.env` |

Because of this, editing your local files changes nothing until you redeploy.

**Refresh in place** (keeps your `.env` / webhook) — after editing repo files:

```bash
cd ~/sanctuary-discord
sudo bash deploy.sh
```

`deploy.sh` re-copies the app + timer files, reloads systemd, and **restarts** the timers
so schedule changes take effect immediately. It only prompts for a webhook URL if
`/opt/home-sanctuary/.env` doesn't already exist — an existing `.env` is left untouched.

**Clean re-stand-up** (start fresh):

```bash
cd ~/sanctuary-discord
sudo bash uninstall.sh   # answer N to keep /opt/home-sanctuary + .env, or Y to wipe it
sudo bash deploy.sh
```

**Verify what's actually running:**

```bash
systemctl list-timers | grep sanctuary
```

You should see the weekday timer's next trigger at **05:45** and the weekend timer at
**07:00**.

## Customizing Tasks

Edit the `TASKS` object in `/opt/home-sanctuary/discord-notifier.js`:

```javascript
const TASKS = {
  daily: [
    { name: 'Make beds' },
    // Add more daily tasks...
  ],
  weekly: [
    { name: 'Vacuum all rooms', dayOfWeek: 6 },  // 0=Sun, 6=Sat
    // Add more weekly tasks...
  ],
  monthly: [
    { name: 'Deep clean refrigerator', dayOfMonth: 1 },
    // Add more monthly tasks...
  ]
};
```

---

## Domain Setup (Optional)

You have several options for accessing your Home Sanctuary from a custom domain:

### Option A: Local DNS / Hosts File (LAN Only)

Simplest option for home network access only.

**On each device that needs access**, edit the hosts file:

```bash
# Linux/Mac: /etc/hosts
# Windows: C:\Windows\System32\drivers\etc\hosts

192.168.1.100  sanctuary.home
```

Replace `192.168.1.100` with your NanoPC-T6's local IP.

Then update nginx:
```bash
sudo nano /etc/nginx/sites-available/home-sanctuary.conf
# Change: server_name sanctuary.local _;
# To:     server_name sanctuary.home _;
sudo systemctl reload nginx
```

### Option B: Router DNS (LAN Only)

If your router supports custom DNS entries (common in OpenWrt, pfSense, Unifi):

1. Add a DNS record: `sanctuary.home` → `192.168.1.100`
2. All devices on your network can now access `http://sanctuary.home`

### Option C: DuckDNS (Free, Internet Access)

For access from anywhere via the internet.

1. **Create account** at [duckdns.org](https://www.duckdns.org/)
2. **Create a subdomain** (e.g., `mysanctuary.duckdns.org`)
3. **Install the update script**:

```bash
mkdir -p ~/duckdns
cat > ~/duckdns/duck.sh << 'EOF'
#!/bin/bash
DOMAIN="mysanctuary"
TOKEN="your-duckdns-token"
curl -s "https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=" > ~/duckdns/duck.log
EOF
chmod +x ~/duckdns/duck.sh
```

4. **Add cron job** to keep IP updated:
```bash
crontab -e
# Add:
*/5 * * * * ~/duckdns/duck.sh
```

5. **Update nginx** with your domain:
```bash
sudo nano /etc/nginx/sites-available/home-sanctuary.conf
# Change server_name to: mysanctuary.duckdns.org
sudo systemctl reload nginx
```

6. **Port forward** port 80 on your router to your NanoPC-T6's IP

### Option D: Cloudflare Tunnel (Recommended for Internet Access)

More secure than port forwarding — no open ports required.

1. **Create Cloudflare account** and add your domain
2. **Install cloudflared**:
```bash
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update
sudo apt install cloudflared
```

3. **Authenticate and create tunnel**:
```bash
cloudflared tunnel login
cloudflared tunnel create home-sanctuary
cloudflared tunnel route dns home-sanctuary sanctuary.yourdomain.com
```

4. **Configure the tunnel** (`~/.cloudflared/config.yml`):
```yaml
tunnel: YOUR_TUNNEL_ID
credentials-file: /home/YOUR_USER/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  - hostname: sanctuary.yourdomain.com
    service: http://localhost:80
  - service: http_status:404
```

5. **Run as service**:
```bash
sudo cloudflared service install
sudo systemctl enable --now cloudflared
```

### Option E: Tailscale (Private Network)

Access from anywhere without exposing to the public internet.

1. **Install Tailscale** on your NanoPC-T6:
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

2. **Install Tailscale** on your phone/laptop
3. Access via Tailscale IP: `http://100.x.x.x` or enable MagicDNS for `http://nanopc-t6`

---

## Maintenance Commands

```bash
# View notification logs
journalctl -u home-sanctuary -f

# Check timer status
systemctl list-timers | grep sanctuary

# Manually trigger a notification
cd /opt/home-sanctuary && node discord-notifier.js

# Edit webhook URL
sudo nano /opt/home-sanctuary/.env

# Restart nginx after config changes
sudo nginx -t && sudo systemctl reload nginx
```

## Hardware Watchdog (Optional)

For maximum reliability, enable the hardware watchdog to auto-reboot on system hangs:

```bash
# Install watchdog daemon
sudo apt install watchdog

# Configure
sudo nano /etc/watchdog.conf
# Uncomment: watchdog-device = /dev/watchdog
# Uncomment: max-load-1 = 24

# Enable
sudo systemctl enable --now watchdog
```

## Troubleshooting

**Notification not sending?**
```bash
# Check webhook URL
cat /opt/home-sanctuary/.env

# Test manually
cd /opt/home-sanctuary && node discord-notifier.js
```

**Web UI not loading?**
```bash
# Check nginx status
sudo systemctl status nginx

# Check nginx config
sudo nginx -t

# Check if port 80 is in use
sudo lsof -i :80
```

**Timer not firing?**
```bash
# Check timer status
systemctl status home-sanctuary-weekday.timer
systemctl status home-sanctuary-weekend.timer

# Check system time
timedatectl
```
