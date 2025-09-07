# Gang Territory Ownership System

## Overview
The Territory Ownership System adds a comprehensive territory control mechanism to your gang script. Gangs can now attack, claim, and defend territories to earn points and establish dominance.

## Features

### 🏰 Territory Control
- Gangs can attack and claim territories to gain control
- Owned territories are highlighted with gang colors on the map
- Each controlled territory grants +1 point to the owning gang
- Points are automatically updated when territories are captured or lost

### ⚔️ Conquest System
- **Conquest Periods**: Scheduled times when all territories become attackable
- **Manual Control**: Admins can start/end conquest periods at any time
- **Default Schedule**: Configurable automatic conquest times
- **Territory Attacks**: Players must be in conquest period to attack owned territories

### 👨‍💼 Admin Controls
The system includes comprehensive admin commands:

#### Territory Management
- `/startconquest [duration]` - Start conquest period manually
- `/endconquest` - End current conquest period
- `/resetterritory <territory>` - Reset territory to neutral
- `/lockterritory <territory>` - Lock territory from attacks
- `/unlockterritory <territory>` - Unlock territory for attacks
- `/territoryinfo [territory]` - Get ownership information
- `/forceclaim <territory> <gang>` - Force claim territory for gang

#### Points Management
- `/addterritorypoints <gang> <points>` - Add points to gang
- `/setterritorypoints <gang> <points>` - Set gang territory points

#### Gang Banning System
- `/bangang <gang> <hours> [reason]` - Ban gang from claiming territories
- `/unbangang <gang>` - Remove gang territory ban

### 🔄 Attack System
- **Attack Duration**: Configurable time for territory battles (default: 15 minutes)
- **Player Count**: System counts attacking vs defending players in territory
- **Defense Bonus**: Defending gangs receive a 20% advantage
- **Cooldown**: Territories have cooldown periods between attacks

### 📊 Visual Features
- **Map Blips**: Territories show on map with gang colors when owned
- **Attack Indicators**: Flashing blips when territories are under attack
- **Zone Information**: Shows ownership status when entering territories
- **Real-time Updates**: Live scoreboard during territory battles

## Configuration

### Basic Settings
```lua
cfg.territorySystem = {
    enabled = true,                         -- Enable/disable the system
    pointsPerTerritory = 1,                 -- Points per owned territory
    attackDuration = 15,                    -- Attack duration in minutes
    attackCooldown = 60,                    -- Cooldown between attacks
    minAttackersRequired = 2,               -- Minimum attackers needed
    defenseBonus = 1.2,                     -- Defense advantage multiplier
    conquestDuration = 120,                 -- Conquest period duration
    maxBanDuration = 168,                   -- Max ban duration (hours)
    adminNotifications = true,              -- Admin notifications
    requireGangMembers = true,              -- Only gang members can attack
}
```

### Conquest Schedule
```lua
defaultConquestTimes = {
    { day = 'monday', hour = 20, minute = 0 },
    { day = 'wednesday', hour = 20, minute = 0 },
    { day = 'friday', hour = 20, minute = 0 },
    { day = 'sunday', hour = 20, minute = 0 },
}
```

## Installation

1. **Database Setup**: Run the updated `install.sql` to create new tables:
   - `rm_gangs_territory_ownership`
   - `rm_gangs_conquest_schedule` 
   - `rm_gangs_banned_gangs`

2. **Configuration**: Update your `cfg.lua` with territory system settings

3. **Permissions**: Add admin identifiers to `cfg.adminList` for command access

## Player Commands

### Territory Attacks
- `/attackterritory` - Attack current territory (must be in enemy territory)
- Stand in enemy territory and use command to start attack
- Requires conquest period to be active (unless territory is neutral)

### Information
- Players can see territory ownership when entering zones
- Map blips show territory control status
- Real-time notifications for attacks and captures

## Database Schema

### Territory Ownership
```sql
CREATE TABLE `rm_gangs_territory_ownership` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `territory_name` VARCHAR(50) NOT NULL,
    `gang_name` VARCHAR(50) NULL DEFAULT NULL,
    `capture_date` TIMESTAMP NULL DEFAULT current_timestamp(),
    `last_attack_date` TIMESTAMP NULL DEFAULT NULL,
    `is_locked` TINYINT(1) NULL DEFAULT '0',
    `under_attack` TINYINT(1) NULL DEFAULT '0',
    `attack_end_time` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `territory_name_unique` (`territory_name`)
);
```

### Gang Bans
```sql
CREATE TABLE `rm_gangs_banned_gangs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `gang_name` VARCHAR(50) NOT NULL,
    `banned_until` TIMESTAMP NOT NULL,
    `reason` VARCHAR(255) NULL DEFAULT NULL,
    `banned_by` VARCHAR(100) NULL DEFAULT NULL,
    `banned_date` TIMESTAMP NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`)
);
```

## Events

### Server Events
- `rm_gangs:server:onTerritoryClaimed` - When territory is claimed
- `rm_gangs:server:onTerritoryAttackStarted` - When attack begins
- `rm_gangs:server:onTerritoryAttackFinished` - When attack ends
- `rm_gangs:server:onConquestStarted` - When conquest period starts
- `rm_gangs:server:onConquestEnded` - When conquest period ends
- `rm_gangs:server:onGangBanned` - When gang is banned
- `rm_gangs:server:onTerritoryReset` - When admin resets territory

### Client Events
- `rm_gangs:client:onTerritoryClaimed` - Territory claimed notification
- `rm_gangs:client:onTerritoryAttackStarted` - Attack started notification
- `rm_gangs:client:updateTerritoryAttack` - Attack progress updates
- `rm_gangs:client:onConquestStarted` - Conquest period notification

## Exports

### Server Exports
```lua
-- Claim territory for a gang
exports['rm_gangs']:claimTerritory(territoryName, gangName, playerId)

-- Start territory attack
exports['rm_gangs']:startTerritoryAttack(territoryName, attackingGang, playerId)

-- Get territory ownership data
exports['rm_gangs']:getTerritoryOwnership()

-- Get conquest state
exports['rm_gangs']:getConquestState()

-- Check if gang is banned
exports['rm_gangs']:isGangBanned(gangName)
```

### Client Exports
```lua
-- Get territory ownership data
exports['rm_gangs']:getTerritoryOwnership()

-- Get conquest state
exports['rm_gangs']:getConquestState()

-- Get current attacks
exports['rm_gangs']:getCurrentAttacks()
```

## Tips for Admins

1. **Balance**: Adjust attack duration and cooldowns based on server activity
2. **Scheduling**: Set conquest times when most players are online
3. **Monitoring**: Use `/territoryinfo` to track ownership changes
4. **Intervention**: Lock territories during events or issues
5. **Punishment**: Use gang bans for rule violations

## Compatibility

- ✅ Integrates with existing turf war system
- ✅ Compatible with tribute zones
- ✅ Works with all supported frameworks (ESX/QBCore)
- ✅ Maintains existing gang functionality
- ✅ Database schema extends existing tables

## Troubleshooting

### Common Issues
1. **Commands not working**: Check admin permissions in `cfg.adminList`
2. **Territories not showing**: Verify database tables were created
3. **Attacks failing**: Check conquest period status and gang membership
4. **Points not updating**: Ensure territory_points column exists in database

### Debug Mode
Enable debugging in config:
```lua
cfg.debug = true
```

## Support

For issues or questions:
1. Check server console for error messages
2. Verify database schema matches requirements
3. Ensure all modules are properly loaded in fxmanifest.lua
4. Check configuration settings match your server needs
