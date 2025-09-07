# Enhanced Tribute Zones System

## Overview
The enhanced tribute zones system now includes automatic scheduling, loyalty points rewards, comprehensive notifications, Discord webhooks, and admin management tools.

## 🆕 **New Features Added**

### 🎯 **Loyalty Points Integration**
- **Automatic Points**: Gangs now receive loyalty points when capturing tribute zones
- **Point Deduction**: Gangs lose points when losing zones
- **Configurable**: Set custom point values in `cfg.tributeZoneLoyalty`

### 🔔 **Enhanced Notifications System**
- **In-Game Alerts**: All players receive notifications when zones are attacked/captured
- **Discord Integration**: Automatic Discord webhooks with role mentions
- **Visual Effects**: Screen flash effects for major events
- **Gang-Specific Alerts**: Zone owners get pinged when their territory is attacked

### 📅 **Automatic Scheduling**
- **Cron-Based**: Zones automatically activate based on configured schedules
- **Individual Timing**: Each zone can have its own schedule
- **Manual Override**: Admins can still start zones manually
- **Prevention System**: Zones without schedules require manual activation

### 👨‍💼 **Admin Management Tools**
- **Reset Zones**: `/resettributezone <zone>` - Reset any zone to neutral
- **Ban System**: Ban gangs from participating in tribute zones
- **Tech Support**: Special permission level for limited admin access

### 🚫 **Gang Ban System**
- **Temporary Bans**: Ban gangs for specified hours
- **Reason Tracking**: Record why gangs were banned
- **Auto-Expiry**: Bans automatically expire
- **Member Notifications**: All gang members get notified of bans/unbans

## 📊 **Configuration**

### Loyalty Points
```lua
cfg.tributeZoneLoyalty = 100   -- Points gained/lost per tribute zone
```

### Discord Integration
```lua
cfg.discord = {
    enabled = true,
    webhook = 'YOUR_DISCORD_WEBHOOK_URL_HERE',
    botName = 'Gang Wars Bot',
    embedColor = 15105570, -- Orange color
    tributeRoleMentions = {
        ['families'] = '<@&123456789012345678>',
        ['ballas'] = '<@&987654321098765432>',
    },
}
```

### Ban System
```lua
cfg.tributeZoneBans = {
    enabled = true,
    maxBanDuration = 168, -- hours (1 week)
}
```

### Permission Levels
```lua
-- Full admin access
cfg.adminList = {
    ['steam:00000000a000a00'] = true,
}

-- Limited admin access (tech support)
cfg.techSupportList = {
    ['steam:11111111b111b11'] = true,
}
```

## 🎮 **How It Works**

### Automatic Zone Activation
1. **Scheduled Start**: Zones activate automatically based on `resetCronExpression`
2. **Discord Alert**: Webhook sends notification when zone activates
3. **In-Game Notice**: All players receive notification
4. **Role Mention**: Zone owner gang gets Discord mention (if configured)

### Capture Process
1. **Attack Notification**: When zone is attacked, everyone gets notified
2. **Real-time Updates**: Players in zone contribute points over time
3. **Loyalty Reward**: Winner gets loyalty points, loser loses points
4. **Capture Alert**: Success notification sent to all players and Discord

### Admin Controls
1. **Zone Reset**: Admins can reset zones to neutral state instantly
2. **Gang Bans**: Ban problematic gangs from tribute zones
3. **Manual Start**: Override schedules to start zones manually

## 💬 **Admin Commands**

### Zone Management
```bash
/resettributezone <zone_name>
# Resets specified tribute zone to neutral
# Example: /resettributezone suds_law_laundromat

/starttribute
# Opens manual zone start menu (existing command)
```

### Gang Banning
```bash
/bantributegang <gang> <hours> [reason]
# Ban gang from tribute zones
# Example: /bantributegang families 24 "Rule violation"

/unbantributegang <gang>
# Remove gang ban from tribute zones
# Example: /unbantributegang families
```

## 📱 **Discord Setup**

### 1. Create Webhook
1. Go to Discord server settings
2. Select "Integrations" → "Webhooks"
3. Create new webhook for your gang channel
4. Copy webhook URL

### 2. Configure Script
```lua
cfg.discord = {
    enabled = true,
    webhook = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_URL',
    botName = 'Gang Wars Bot',
    embedColor = 15105570,
    tributeRoleMentions = {
        ['families'] = '<@&YOUR_FAMILIES_ROLE_ID>',
        ['ballas'] = '<@&YOUR_BALLAS_ROLE_ID>',
        -- Add all your gangs
    },
}
```

### 3. Get Role IDs
1. Enable Developer Mode in Discord
2. Right-click gang roles → "Copy ID"
3. Use format: `<@&ROLE_ID>`

## 🔧 **Database Changes**

### New Table Added
```sql
CREATE TABLE IF NOT EXISTS `rm_gangs_tribute_zone_bans` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `gang_name` VARCHAR(50) NOT NULL,
    `banned_until` TIMESTAMP NOT NULL,
    `reason` VARCHAR(255) NULL DEFAULT NULL,
    `banned_by` VARCHAR(100) NULL DEFAULT NULL,
    `banned_date` TIMESTAMP NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`)
);
```

## 📋 **Installation Steps**

1. **Database Update**: Run the updated `install.sql`
2. **Configure Discord**: Set webhook URL in `cfg.lua`
3. **Set Permissions**: Add admins to `cfg.adminList` and `cfg.techSupportList`
4. **Configure Roles**: Add Discord role IDs to `cfg.discord.tributeRoleMentions`
5. **Restart Resource**: Restart the gang script

## 🚨 **Notification Types**

### In-Game Notifications
- **Zone Attack Started**: 🚨 Red notification + screen flash
- **Zone Captured**: 🏰 Green notification + screen flash
- **Zone Reset**: 🔄 Blue notification
- **Gang Banned**: ⚠️ Yellow notification to gang members

### Discord Notifications
- **Attack Started**: Red embed with role mention for zone owner
- **Zone Captured**: Green embed with role mentions for involved gangs
- **Manual Start**: Orange embed showing admin who started
- **Scheduled Start**: Blue embed for automatic activations

## ⚙️ **Advanced Configuration**

### Zone-Specific Settings
Each tribute zone can have individual settings:
```lua
{
    name = 'suds_law_laundromat',
    label = 'Suds Law Laundromat',
    paymentAmount = 1500,
    resetCronExpression = '00 20 * * mon', -- Monday 8 PM
    captureDuration = 10, -- minutes
    -- ... other settings
}
```

### Cron Expression Examples
```lua
'0 20 * * mon'     -- Monday 8:00 PM
'0 18 * * fri'     -- Friday 6:00 PM  
'30 19 * * sat'    -- Saturday 7:30 PM
'0 21 * * sun'     -- Sunday 9:00 PM
```

## 🎯 **Permission Levels**

### Full Admin (`cfg.adminList`)
- Reset tribute zones
- Ban/unban gangs
- Start manual tribute events
- All territory commands

### Tech Support (`cfg.techSupportList`)
- Reset tribute zones
- Ban/unban gangs (with restrictions)
- Start manual tribute events
- Limited territory commands

### Players
- Participate in tribute zones (if not banned)
- Receive notifications
- View zone status

## 🔍 **Troubleshooting**

### Common Issues
1. **Discord not working**: Check webhook URL format
2. **No notifications**: Verify Discord webhook permissions
3. **Bans not working**: Ensure database table was created
4. **Points not awarded**: Check `cfg.tributeZoneLoyalty` setting

### Debug Tips
1. Check server console for error messages
2. Verify Discord webhook in browser
3. Test role mentions manually in Discord
4. Check gang member online status

## 🏆 **Best Practices**

### For Admins
1. **Schedule Balance**: Spread zone times across different days
2. **Fair Punishment**: Use reasonable ban durations
3. **Clear Communication**: Always provide ban reasons
4. **Monitor Activity**: Watch for zone camping or exploitation

### For Server Owners
1. **Regular Backups**: Backup database before major changes
2. **Performance**: Monitor Discord webhook rate limits
3. **Community**: Announce new features to players
4. **Feedback**: Gather player input on zone timings

## 📈 **Future Enhancements**

Planned features for future updates:
- Gang statistics dashboard
- Zone capture history
- Advanced scheduling options
- Mobile notifications
- Integration with other gang systems

---

This enhanced system provides a complete tribute zone experience with automatic management, comprehensive notifications, and powerful admin tools. The system is designed to be both user-friendly for players and manageable for administrators.
