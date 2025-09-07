-- Admin Commands for Territory System
-- This file contains all admin commands for managing the territory ownership system

-- Helper function to check if player is admin
local function isAllowedForTerritoryCommands(identifiers)
    for i = 1, #identifiers do
        if cfg.adminList[identifiers[i]] then
            return true
        end
    end
    return false
end

-- Helper function to get territory list as string
local function getTerritoryList()
    local territoryNames = {}
    for name, _ in pairs(cfg.gangs) do
        table.insert(territoryNames, name)
    end
    return table.concat(territoryNames, ', ')
end

-- Helper function to get gang list as string
local function getGangList()
    local gangNames = {}
    for name, _ in pairs(gangs) do
        table.insert(gangNames, name)
    end
    return table.concat(gangNames, ', ')
end

-- /startconquest - Start conquest period manually
if cfg.commands.startconquest then
    lib.addCommand(cfg.commands.startconquest, {
        help = 'Start a conquest period manually',
        params = {
            { name = 'duration', help = 'Duration in minutes (optional)', type = 'number', optional = true },
        },
    }, function(source, args, raw)
        local identifiers = GetPlayerIdentifiers(source)
        if IsPlayerAceAllowed(source, 'command') or isAllowedForTerritoryCommands(identifiers) then
            local duration = args['duration'] or cfg.territorySystem.conquestDuration
            local success, message = startConquestPeriod(duration, {}, GetPlayerName(source))
            
            if success then
                notify(source, message, 'success')
                local adminMessage = ('Admin %s started conquest period for %d minutes'):format(GetPlayerName(source), duration)
                notifyAdmins(adminMessage, 'info')
            else
                notify(source, message, 'error')
            end
        else
            notify(source, 'You do not have permission to use this command', 'error')
        end
    end)
end

-- /endconquest - End conquest period manually
if cfg.commands.endconquest then
    lib.addCommand(cfg.commands.endconquest, {
        help = 'End the current conquest period manually',
    }, function(source, args, raw)
        local identifiers = GetPlayerIdentifiers(source)
        if IsPlayerAceAllowed(source, 'command') or isAllowedForTerritoryCommands(identifiers) then
            local success, message = endConquestPeriod()
            
            if success then
                notify(source, message, 'success')
                local adminMessage = ('Admin %s ended conquest period'):format(GetPlayerName(source))
                notifyAdmins(adminMessage, 'info')
            else
                notify(source, message, 'error')
            end
        else
            notify(source, 'You do not have permission to use this command', 'error')
        end
    end)
end

-- /resetterritory - Reset territory to neutral
if cfg.commands.resetterritory then
    lib.addCommand(cfg.commands.resetterritory, {
        help = 'Reset a territory to neutral state',
        params = {
            { name = 'territory', help = 'Territory name (' .. getTerritoryList() .. ')', type = 'string' },
        },
    }, function(source, args, raw)
        local identifiers = GetPlayerIdentifiers(source)
        if IsPlayerAceAllowed(source, 'command') or isAllowedForTerritoryCommands(identifiers) then
            local territoryName = args['territory']
            
            if not territories[territoryName] then
                return notify(source, 'Territory not found. Available: ' .. getTerritoryList(), 'error')
            end
            
            local oldOwner = territoryOwnership[territoryName].gangName
            
            -- Reset territory
            territoryOwnership[territoryName].gangName = nil
            territoryOwnership[territoryName].captureDate = nil
            territoryOwnership[territoryName].underAttack = false
            territoryOwnership[territoryName].attackEndTime = nil
            
            -- Update database
            MySQL.update('UPDATE rm_gangs_territory_ownership SET gang_name = NULL, capture_date = NULL, under_attack = 0, attack_end_time = NULL WHERE territory_name = ?', {
                territoryName
            })
            
            -- Update territory points
            updateAllTerritoryPoints()
            
            -- Notify
            notify(source, ('Territory %s has been reset to neutral'):format(territories[territoryName].label), 'success')
            
            local eventData = {
                territoryName = territoryName,
                territoryLabel = territories[territoryName].label,
                oldOwner = oldOwner,
                resetBy = GetPlayerName(source)
            }
            
            TriggerEvent('rm_gangs:server:onTerritoryReset', eventData)
            TriggerClientEvent('rm_gangs:client:onTerritoryReset', -1, eventData)
            
            local adminMessage = ('Admin %s reset territory %s to neutral'):format(GetPlayerName(source), territories[territoryName].label)
            notifyAdmins(adminMessage, 'info')
        else
            notify(source, 'You do not have permission to use this command', 'error')
        end
    end)
end

-- /lockterritory - Lock territory from being attacked
if cfg.commands.lockterritory then
    lib.addCommand(cfg.commands.lockterritory, {
        help = 'Lock a territory to prevent attacks',
        params = {
            { name = 'territory', help = 'Territory name (' .. getTerritoryList() .. ')', type = 'string' },
        },
    }, function(source, args, raw)
        local identifiers = GetPlayerIdentifiers(source)
        if IsPlayerAceAllowed(source, 'command') or isAllowedForTerritoryCommands(identifiers) then
            local territoryName = args['territory']
            
            if not territories[territoryName] then
                return notify(source, 'Territory not found. Available: ' .. getTerritoryList(), 'error')
            end
            
            if territoryOwnership[territoryName].isLocked then
                return notify(source, 'Territory is already locked', 'error')
            end
            
            -- Lock territory
            territoryOwnership[territoryName].isLocked = true
            
            -- Update database
            MySQL.update('UPDATE rm_gangs_territory_ownership SET is_locked = 1 WHERE territory_name = ?', {
                territoryName
            })
            
            notify(source, ('Territory %s has been locked'):format(territories[territoryName].label), 'success')
            
            local eventData = {
                territoryName = territoryName,
                territoryLabel = territories[territoryName].label,
                locked = true,
                lockedBy = GetPlayerName(source)
            }\n            \n            TriggerEvent('rm_gangs:server:onTerritoryLocked', eventData)\n            TriggerClientEvent('rm_gangs:client:onTerritoryLocked', -1, eventData)\n            \n            local adminMessage = ('Admin %s locked territory %s'):format(GetPlayerName(source), territories[territoryName].label)\n            notifyAdmins(adminMessage, 'info')\n        else\n            notify(source, 'You do not have permission to use this command', 'error')\n        end\n    end)\nend\n\n-- /unlockterritory - Unlock territory for attacks\nif cfg.commands.unlockterritory then\n    lib.addCommand(cfg.commands.unlockterritory, {\n        help = 'Unlock a territory to allow attacks',\n        params = {\n            { name = 'territory', help = 'Territory name (' .. getTerritoryList() .. ')', type = 'string' },\n        },\n    }, function(source, args, raw)\n        local identifiers = GetPlayerIdentifiers(source)\n        if IsPlayerAceAllowed(source, 'command') or isAllowedForTerritoryCommands(identifiers) then\n            local territoryName = args['territory']\n            \n            if not territories[territoryName] then\n                return notify(source, 'Territory not found. Available: ' .. getTerritoryList(), 'error')\n            end\n            \n            if not territoryOwnership[territoryName].isLocked then\n                return notify(source, 'Territory is not locked', 'error')\n            end\n            \n            -- Unlock territory\n            territoryOwnership[territoryName].isLocked = false\n            \n            -- Update database\n            MySQL.update('UPDATE rm_gangs_territory_ownership SET is_locked = 0 WHERE territory_name = ?', {\n                territoryName\n            })\n            \n            notify(source, ('Territory %s has been unlocked'):format(territories[territoryName].label), 'success')\n            \n            local eventData = {\n                territoryName = territoryName,\n                territoryLabel = territories[territoryName].label,\n                locked = false,\n                unlockedBy = GetPlayerName(source)\n            }\n            \n            TriggerEvent('rm_gangs:server:onTerritoryLocked', eventData)\n            TriggerClientEvent('rm_gangs:client:onTerritoryLocked', -1, eventData)\n            \n            local adminMessage = ('Admin %s unlocked territory %s'):format(GetPlayerName(source), territories[territoryName].label)\n            notifyAdmins(adminMessage, 'info')\n        else\n            notify(source, 'You do not have permission to use this command', 'error')\n        end\n    end)\nend\n\n-- /addterritorypoints - Add territory points to gang\nif cfg.commands.addterritorypoints then\n    lib.addCommand(cfg.commands.addterritorypoints, {\n        help = 'Add territory points to a gang',\n        params = {\n            { name = 'gang', help = 'Gang name (' .. getGangList() .. ')', type = 'string' },\n            { name = 'points', help = 'Points to add', type = 'number' },\n        },\n    }, function(source, args, raw)\n        local identifiers = GetPlayerIdentifiers(source)\n        if IsPlayerAceAllowed(source, 'command') or isAllowedForTerritoryCommands(identifiers) then\n            local gangName = args['gang']\n            local points = args['points']\n            \n            if not gangs[gangName] then\n                return notify(source, 'Gang not found. Available: ' .. getGangList(), 'error')\n            end\n            \n            local oldPoints = gangs[gangName].territory_points or 0\n            gangs[gangName].territory_points = oldPoints + points\n            \n            -- Update database\n            MySQL.update('UPDATE rm_gangs_main SET territory_points = ? WHERE name = ?', {\n                gangs[gangName].territory_points,\n                gangName\n            })\n            \n            -- Notify clients\n            TriggerClientEvent('rm_gangs:client:updateTerritoryPoints', -1, gangs)\n            \n            notify(source, ('Added %d territory points to %s (Total: %d)'):format(points, gangs[gangName].label, gangs[gangName].territory_points), 'success')\n            \n            local adminMessage = ('Admin %s added %d territory points to %s'):format(GetPlayerName(source), points, gangs[gangName].label)\n            notifyAdmins(adminMessage, 'info')\n        else\n            notify(source, 'You do not have permission to use this command', 'error')\n        end\n    end)\nend\n\n-- /setterritorypoints - Set gang territory points\nif cfg.commands.setterritorypoints then\n    lib.addCommand(cfg.commands.setterritorypoints, {\n        help = 'Set territory points for a gang',\n        params = {\n            { name = 'gang', help = 'Gang name (' .. getGangList() .. ')', type = 'string' },\n            { name = 'points', help = 'Points to set', type = 'number' },\n        },\n    }, function(source, args, raw)\n        local identifiers = GetPlayerIdentifiers(source)\n        if IsPlayerAceAllowed(source, 'command') or isAllowedForTerritoryCommands(identifiers) then\n            local gangName = args['gang']\n            local points = args['points']\n            \n            if not gangs[gangName] then\n                return notify(source, 'Gang not found. Available: ' .. getGangList(), 'error')\n            end\n            \n            local oldPoints = gangs[gangName].territory_points or 0\n            gangs[gangName].territory_points = points\n            \n            -- Update database\n            MySQL.update('UPDATE rm_gangs_main SET territory_points = ? WHERE name = ?', {\n                gangs[gangName].territory_points,\n                gangName\n            })\n            \n            -- Notify clients\n            TriggerClientEvent('rm_gangs:client:updateTerritoryPoints', -1, gangs)\n            \n            notify(source, ('Set territory points for %s to %d (Previous: %d)'):format(gangs[gangName].label, points, oldPoints), 'success')\n            \n            local adminMessage = ('Admin %s set territory points for %s to %d'):format(GetPlayerName(source), gangs[gangName].label, points)\n            notifyAdmins(adminMessage, 'info')\n        else\n            notify(source, 'You do not have permission to use this command', 'error')\n        end\n    end)\nend\n\n-- /bangang - Ban gang from claiming territories\nif cfg.commands.bangang then\n    lib.addCommand(cfg.commands.bangang, {\n        help = 'Ban a gang from claiming territories',\n        params = {\n            { name = 'gang', help = 'Gang name (' .. getGangList() .. ')', type = 'string' },\n            { name = 'hours', help = 'Ban duration in hours (max: ' .. cfg.territorySystem.maxBanDuration .. ')', type = 'number' },\n            { name = 'reason', help = 'Ban reason (optional)', type = 'string', optional = true },\n        },\n    }, function(source, args, raw)\n        local identifiers = GetPlayerIdentifiers(source)\n        if IsPlayerAceAllowed(source, 'command') or isAllowedForTerritoryCommands(identifiers) then\n            local gangName = args['gang']\n            local hours = args['hours']\n            local reason = args['reason'] or 'Admin ban'\n            \n            if not gangs[gangName] then\n                return notify(source, 'Gang not found. Available: ' .. getGangList(), 'error')\n            end\n            \n            if hours > cfg.territorySystem.maxBanDuration then\n                return notify(source, ('Ban duration cannot exceed %d hours'):format(cfg.territorySystem.maxBanDuration), 'error')\n            end\n            \n            if isGangBanned(gangName) then\n                return notify(source, 'Gang is already banned', 'error')\n            end\n            \n            local bannedUntil = os.date('%Y-%m-%d %H:%M:%S', os.time() + (hours * 3600))\n            \n            -- Insert ban\n            MySQL.insert.await('INSERT INTO rm_gangs_banned_gangs (gang_name, banned_until, reason, banned_by) VALUES (?, ?, ?, ?)', {\n                gangName,\n                bannedUntil,\n                reason,\n                GetPlayerName(source)\n            })\n            \n            -- Update local ban cache\n            gangBans[gangName] = {\n                bannedUntil = bannedUntil,\n                reason = reason,\n                bannedBy = GetPlayerName(source),\n                bannedDate = os.date('%Y-%m-%d %H:%M:%S')\n            }\n            \n            notify(source, ('Gang %s has been banned from claiming territories for %d hours'):format(gangs[gangName].label, hours), 'success')\n            \n            local eventData = {\n                gangName = gangName,\n                gangLabel = gangs[gangName].label,\n                bannedUntil = bannedUntil,\n                reason = reason,\n                bannedBy = GetPlayerName(source),\n                hours = hours\n            }\n            \n            TriggerEvent('rm_gangs:server:onGangBanned', eventData)\n            TriggerClientEvent('rm_gangs:client:onGangBanned', -1, eventData)\n            \n            local adminMessage = ('Admin %s banned gang %s from claiming territories for %d hours'):format(GetPlayerName(source), gangs[gangName].label, hours)\n            notifyAdmins(adminMessage, 'warning')\n        else\n            notify(source, 'You do not have permission to use this command', 'error')\n        end\n    end)\nend\n\n-- /unbangang - Unban gang from claiming territories\nif cfg.commands.unbangang then\n    lib.addCommand(cfg.commands.unbangang, {\n        help = 'Unban a gang from claiming territories',\n        params = {\n            { name = 'gang', help = 'Gang name (' .. getGangList() .. ')', type = 'string' },\n        },\n    }, function(source, args, raw)\n        local identifiers = GetPlayerIdentifiers(source)\n        if IsPlayerAceAllowed(source, 'command') or isAllowedForTerritoryCommands(identifiers) then\n            local gangName = args['gang']\n            \n            if not gangs[gangName] then\n                return notify(source, 'Gang not found. Available: ' .. getGangList(), 'error')\n            end\n            \n            if not isGangBanned(gangName) then\n                return notify(source, 'Gang is not banned', 'error')\n            end\n            \n            -- Remove ban\n            MySQL.query.await('DELETE FROM rm_gangs_banned_gangs WHERE gang_name = ?', {gangName})\n            \n            -- Update local ban cache\n            gangBans[gangName] = nil\n            \n            notify(source, ('Gang %s has been unbanned'):format(gangs[gangName].label), 'success')\n            \n            local eventData = {\n                gangName = gangName,\n                gangLabel = gangs[gangName].label,\n                unbannedBy = GetPlayerName(source)\n            }\n            \n            TriggerEvent('rm_gangs:server:onGangUnbanned', eventData)\n            TriggerClientEvent('rm_gangs:client:onGangUnbanned', -1, eventData)\n            \n            local adminMessage = ('Admin %s unbanned gang %s'):format(GetPlayerName(source), gangs[gangName].label)\n            notifyAdmins(adminMessage, 'info')\n        else\n            notify(source, 'You do not have permission to use this command', 'error')\n        end\n    end)\nend\n\n-- /territoryinfo - Get territory ownership information\nif cfg.commands.territoryinfo then\n    lib.addCommand(cfg.commands.territoryinfo, {\n        help = 'Get territory ownership information',\n        params = {\n            { name = 'territory', help = 'Territory name (optional - leave blank for all)', type = 'string', optional = true },\n        },\n    }, function(source, args, raw)\n        local identifiers = GetPlayerIdentifiers(source)\n        if IsPlayerAceAllowed(source, 'command') or isAllowedForTerritoryCommands(identifiers) then\n            local territoryName = args['territory']\n            \n            if territoryName then\n                if not territories[territoryName] then\n                    return notify(source, 'Territory not found. Available: ' .. getTerritoryList(), 'error')\n                end\n                \n                local ownership = territoryOwnership[territoryName]\n                local info = {}\n                table.insert(info, ('Territory: %s'):format(territories[territoryName].label))\n                table.insert(info, ('Owner: %s'):format(ownership.gangName and gangs[ownership.gangName].label or 'Neutral'))\n                table.insert(info, ('Locked: %s'):format(ownership.isLocked and 'Yes' or 'No'))\n                table.insert(info, ('Under Attack: %s'):format(ownership.underAttack and 'Yes' or 'No'))\n                if ownership.captureDate then\n                    table.insert(info, ('Captured: %s'):format(ownership.captureDate))\n                end\n                \n                notify(source, table.concat(info, ' | '), 'info')\n            else\n                -- Show all territories\n                local info = { 'Territory Ownership Status:' }\n                local ownedCount = {}\n                \n                for tName, ownership in pairs(territoryOwnership) do\n                    local status = ''\n                    if ownership.underAttack then status = status .. '[ATTACK] ' end\n                    if ownership.isLocked then status = status .. '[LOCKED] ' end\n                    \n                    local ownerName = ownership.gangName and gangs[ownership.gangName].label or 'Neutral'\n                    table.insert(info, ('  %s%s: %s'):format(status, territories[tName].label, ownerName))\n                    \n                    if ownership.gangName then\n                        ownedCount[ownership.gangName] = (ownedCount[ownership.gangName] or 0) + 1\n                    end\n                end\n                \n                table.insert(info, '')\n                table.insert(info, 'Gang Territory Points:')\n                for gangName, count in pairs(ownedCount) do\n                    table.insert(info, ('  %s: %d territories (%d points)'):format(gangs[gangName].label, count, count * cfg.territorySystem.pointsPerTerritory))\n                end\n                \n                table.insert(info, '')\n                table.insert(info, ('Conquest Active: %s'):format(conquestState.active and 'Yes' or 'No'))\n                \n                local message = table.concat(info, '\\n')\n                -- Since notify might not handle long messages well, we'll send it as a print to console\n                print(message)\n                notify(source, 'Territory info printed to server console', 'info')\n            end\n        else\n            notify(source, 'You do not have permission to use this command', 'error')\n        end\n    end)\nend\n\n-- /forceclaim - Force claim territory for gang\nif cfg.commands.forceclaim then\n    lib.addCommand(cfg.commands.forceclaim, {\n        help = 'Force claim a territory for a gang',\n        params = {\n            { name = 'territory', help = 'Territory name (' .. getTerritoryList() .. ')', type = 'string' },\n            { name = 'gang', help = 'Gang name (' .. getGangList() .. ')', type = 'string' },\n        },\n    }, function(source, args, raw)\n        local identifiers = GetPlayerIdentifiers(source)\n        if IsPlayerAceAllowed(source, 'command') or isAllowedForTerritoryCommands(identifiers) then\n            local territoryName = args['territory']\n            local gangName = args['gang']\n            \n            if not territories[territoryName] then\n                return notify(source, 'Territory not found. Available: ' .. getTerritoryList(), 'error')\n            end\n            \n            if not gangs[gangName] then\n                return notify(source, 'Gang not found. Available: ' .. getGangList(), 'error')\n            end\n            \n            local success, message = claimTerritory(territoryName, gangName, source)\n            \n            if success then\n                notify(source, ('Forced claim: %s'):format(message), 'success')\n                local adminMessage = ('Admin %s force claimed territory %s for gang %s'):format(GetPlayerName(source), territories[territoryName].label, gangs[gangName].label)\n                notifyAdmins(adminMessage, 'warning')\n            else\n                notify(source, message, 'error')\n            end\n        else\n            notify(source, 'You do not have permission to use this command', 'error')\n        end\n    end)\nend\n\n-- Additional server events for admin actions\nRegisterNetEvent('rm_gangs:server:adminStartTerritoryAttack', function(territoryName, attackingGang)\n    local source = source\n    local identifiers = GetPlayerIdentifiers(source)\n    \n    if not (IsPlayerAceAllowed(source, 'command') or isAllowedForTerritoryCommands(identifiers)) then\n        return notify(source, 'You do not have permission to do this', 'error')\n    end\n    \n    local success, message = startTerritoryAttack(territoryName, attackingGang, source)\n    \n    if success then\n        notify(source, ('Admin started attack: %s'):format(message), 'success')\n        local adminMessage = ('Admin %s started territory attack on %s by %s'):format(\n            GetPlayerName(source),\n            territories[territoryName].label,\n            gangs[attackingGang].label\n        )\n        notifyAdmins(adminMessage, 'warning')\n    else\n        notify(source, message, 'error')\n    end\nend)
