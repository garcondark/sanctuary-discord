#!/usr/bin/env node

/**
 * Home Sanctuary - Discord Daily Notification Script
 * 
 * Sends cleaning task reminders to Discord via webhook.
 * Scheduled to run at 7 PM on weekdays, 7 AM on weekends.
 */

require('dotenv').config();

// ============================================
// CONFIGURATION
// ============================================

const DISCORD_WEBHOOK_URL = process.env.DISCORD_WEBHOOK_URL;

if (!DISCORD_WEBHOOK_URL) {
  console.error('❌ Error: DISCORD_WEBHOOK_URL not set');
  console.error('   Create a .env file with: DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...');
  process.exit(1);
}

// Your cleaning tasks - customize as needed
const TASKS = {
  daily: [
    { name: 'Make beds' },
    { name: 'Wash dishes' },
    { name: 'Wipe kitchen counters' },
    { name: 'Sweep kitchen floor' },
    { name: 'Take out trash' }
  ],
  weekly: [
    // dayOfWeek: 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    { name: 'Vacuum all rooms', dayOfWeek: 6 },
    { name: 'Mop floors', dayOfWeek: 6 },
    { name: 'Clean bathrooms', dayOfWeek: 0 },
    { name: 'Change bed linens', dayOfWeek: 0 },
    { name: 'Dust surfaces', dayOfWeek: 3 },
    { name: 'Clean mirrors & windows', dayOfWeek: 3 }
  ],
  monthly: [
    // dayOfMonth: 1-28 recommended (29-31 won't trigger in shorter months)
    { name: 'Deep clean refrigerator', dayOfMonth: 1 },
    { name: 'Clean oven', dayOfMonth: 1 },
    { name: 'Wash windows', dayOfMonth: 15 },
    { name: 'Organize closets', dayOfMonth: 15 },
    { name: 'Vacuum under furniture', dayOfMonth: 1 },
    { name: 'Clean baseboards', dayOfMonth: 15 }
  ]
};

// ============================================
// SCRIPT LOGIC
// ============================================

async function sendDiscordNotification() {
  const today = new Date();
  const dayOfWeek = today.getDay();
  const dayOfMonth = today.getDate();
  const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;

  // Get tasks due today
  const dueTasks = {
    daily: TASKS.daily,
    weekly: TASKS.weekly.filter(t => t.dayOfWeek === dayOfWeek),
    monthly: TASKS.monthly.filter(t => t.dayOfMonth === dayOfMonth)
  };

  const totalDue = dueTasks.daily.length + dueTasks.weekly.length + dueTasks.monthly.length;

  if (totalDue === 0) {
    console.log('✓ No tasks due today!');
    return;
  }

  // Build Discord embed
  const dateString = today.toLocaleDateString('en-US', { 
    weekday: 'long', 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  });

  const greeting = isWeekend ? 'Good morning! ☀️' : 'Good evening! 🌙';

  const fields = [];

  if (dueTasks.daily.length > 0) {
    fields.push({
      name: '📅 Daily Tasks',
      value: dueTasks.daily.map(t => `• ${t.name}`).join('\n'),
      inline: false
    });
  }

  if (dueTasks.weekly.length > 0) {
    fields.push({
      name: '📆 Weekly Tasks',
      value: dueTasks.weekly.map(t => `• ${t.name}`).join('\n'),
      inline: false
    });
  }

  if (dueTasks.monthly.length > 0) {
    fields.push({
      name: '🗓️ Monthly Tasks',
      value: dueTasks.monthly.map(t => `• ${t.name}`).join('\n'),
      inline: false
    });
  }

  const payload = {
    embeds: [{
      title: '🏠 Home Sanctuary - Today\'s Cleaning Tasks',
      description: `${greeting} Here are your cleaning tasks for **${dateString}**`,
      color: isWeekend ? 0xf59e0b : 0x3b82f6, // Amber for weekends, blue for weekdays
      fields: fields,
      footer: {
        text: `${totalDue} task${totalDue !== 1 ? 's' : ''} to complete today`
      },
      timestamp: today.toISOString()
    }]
  };

  try {
    const response = await fetch(DISCORD_WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload)
    });

    if (response.ok) {
      console.log(`✓ Discord notification sent successfully at ${today.toLocaleTimeString()}`);
      console.log(`  - ${dueTasks.daily.length} daily tasks`);
      console.log(`  - ${dueTasks.weekly.length} weekly tasks`);
      console.log(`  - ${dueTasks.monthly.length} monthly tasks`);
    } else {
      const errorText = await response.text();
      console.error(`❌ Failed to send notification: ${response.status}`);
      console.error(errorText);
      process.exit(1);
    }
  } catch (error) {
    console.error('❌ Error sending notification:', error.message);
    process.exit(1);
  }
}

// Run the script
sendDiscordNotification();
