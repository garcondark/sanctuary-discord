#!/usr/bin/env node

/**
 * Home Sanctuary - Task State API Server
 *
 * A tiny zero-dependency HTTP server (Node built-in `http`) that owns the shared
 * cleaning-task state so every device sees the same checkboxes. State lives in a
 * single JSON file; task completion auto-resets on a schedule (daily/weekly/monthly).
 *
 * Endpoints:
 *   GET  /health       -> "ok"
 *   GET  /api/tasks    -> { tasks }              (applies scheduled resets first)
 *   POST /api/toggle   { frequency, id } -> { tasks }
 *
 * Note: only task state is shared here. The Discord webhook remains per-device
 * (browser localStorage) and the notifier keeps reading it from .env.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '127.0.0.1';
const DATA_FILE = process.env.DATA_FILE || path.join(__dirname, 'data.json');

// Default task list — mirrors the seed data in web/index.html.
function defaultTasks() {
  return {
    daily: [
      { id: 1, name: 'Make beds', completed: false, lastDone: null },
      { id: 2, name: 'Wash dishes', completed: false, lastDone: null },
      { id: 3, name: 'Wipe kitchen counters', completed: false, lastDone: null },
      { id: 4, name: 'Sweep kitchen floor', completed: false, lastDone: null },
      { id: 5, name: 'Take out trash', completed: false, lastDone: null }
    ],
    weekly: [
      { id: 6, name: 'Vacuum all rooms', completed: false, lastDone: null, dayOfWeek: 6 },
      { id: 7, name: 'Mop floors', completed: false, lastDone: null, dayOfWeek: 6 },
      { id: 8, name: 'Clean bathrooms', completed: false, lastDone: null, dayOfWeek: 0 },
      { id: 9, name: 'Change bed linens', completed: false, lastDone: null, dayOfWeek: 0 },
      { id: 10, name: 'Dust surfaces', completed: false, lastDone: null, dayOfWeek: 3 },
      { id: 11, name: 'Clean mirrors & windows', completed: false, lastDone: null, dayOfWeek: 3 }
    ],
    monthly: [
      { id: 12, name: 'Deep clean refrigerator', completed: false, lastDone: null, dayOfMonth: 1 },
      { id: 13, name: 'Clean oven', completed: false, lastDone: null, dayOfMonth: 1 },
      { id: 14, name: 'Wash windows', completed: false, lastDone: null, dayOfMonth: 15 },
      { id: 15, name: 'Organize closets', completed: false, lastDone: null, dayOfMonth: 15 },
      { id: 16, name: 'Vacuum under furniture', completed: false, lastDone: null, dayOfMonth: 1 },
      { id: 17, name: 'Clean baseboards', completed: false, lastDone: null, dayOfMonth: 15 }
    ]
  };
}

// ============================================
// PERSISTENCE
// ============================================

function pad(n) {
  return String(n).padStart(2, '0');
}

// Period keys computed in the server's LOCAL time. A frequency resets whenever its
// current key differs from the stored one:
//   daily   -> new calendar day (00:00 each day)
//   weekly  -> new week starting Sunday (00:00 each Sunday)
//   monthly -> new month (00:00 on the 1st)
function periodKeys(now = new Date()) {
  const daily = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;

  // Date of the most recent Sunday (start of the current week).
  const sunday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay());
  const weekly = `${sunday.getFullYear()}-${pad(sunday.getMonth() + 1)}-${pad(sunday.getDate())}`;

  const monthly = `${now.getFullYear()}-${pad(now.getMonth() + 1)}`;

  return { daily, weekly, monthly };
}

function loadData() {
  let data;
  try {
    data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
  } catch (err) {
    // Missing or unreadable — start from defaults.
    data = { tasks: defaultTasks(), resetKeys: {} };
  }
  if (!data.tasks) data.tasks = defaultTasks();
  if (!data.resetKeys) data.resetKeys = {};
  return data;
}

function saveData(data) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

// Clear `completed` for any frequency whose period has rolled over. Preserves
// `lastDone`. Returns true if anything changed. Seeds keys on first run without
// wiping existing checkmarks.
function applyResets(data, now = new Date()) {
  const keys = periodKeys(now);
  let changed = false;

  for (const freq of ['daily', 'weekly', 'monthly']) {
    const stored = data.resetKeys[freq];
    if (stored === undefined) {
      // First time we've seen this frequency — record the key, don't reset.
      data.resetKeys[freq] = keys[freq];
      changed = true;
      continue;
    }
    if (stored !== keys[freq]) {
      for (const task of data.tasks[freq]) {
        if (task.completed) task.completed = false;
      }
      data.resetKeys[freq] = keys[freq];
      changed = true;
    }
  }

  return changed;
}

// ============================================
// SERVER
// ============================================

function sendJson(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Cache-Control': 'no-store'
  });
  res.end(payload);
}

function handleGetTasks(res) {
  const data = loadData();
  if (applyResets(data)) saveData(data);
  sendJson(res, 200, { tasks: data.tasks });
}

function handleToggle(req, res) {
  let raw = '';
  req.on('data', chunk => {
    raw += chunk;
    if (raw.length > 1e6) req.destroy(); // guard against absurd payloads
  });
  req.on('end', () => {
    let body;
    try {
      body = JSON.parse(raw || '{}');
    } catch (err) {
      return sendJson(res, 400, { error: 'Invalid JSON' });
    }

    const { frequency, id } = body;
    if (!['daily', 'weekly', 'monthly'].includes(frequency)) {
      return sendJson(res, 400, { error: 'Invalid frequency' });
    }

    const data = loadData();
    applyResets(data); // keep state current even on a write
    const task = data.tasks[frequency].find(t => t.id === id);
    if (!task) {
      return sendJson(res, 404, { error: 'Task not found' });
    }

    task.completed = !task.completed;
    if (task.completed) {
      task.lastDone = new Date().toISOString();
    }

    saveData(data);
    sendJson(res, 200, { tasks: data.tasks });
  });
}

const server = http.createServer((req, res) => {
  const url = (req.url || '').split('?')[0];

  if (req.method === 'GET' && url === '/health') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    return res.end('ok');
  }

  if (req.method === 'GET' && url === '/api/tasks') {
    return handleGetTasks(res);
  }

  if (req.method === 'POST' && url === '/api/toggle') {
    return handleToggle(req, res);
  }

  sendJson(res, 404, { error: 'Not found' });
});

// Seed the store and apply any pending reset on startup.
(function init() {
  const data = loadData();
  applyResets(data);
  saveData(data);
})();

// Re-check resets every minute so a browser left open reflects the midnight/Sunday/
// 1st-of-month rollover promptly (clients poll and pick up the cleared state).
setInterval(() => {
  const data = loadData();
  if (applyResets(data)) saveData(data);
}, 60 * 1000);

server.listen(PORT, HOST, () => {
  console.log(`✓ Home Sanctuary API listening on http://${HOST}:${PORT}`);
  console.log(`  Data file: ${DATA_FILE}`);
});
