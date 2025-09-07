-- Admin Commands for Tribute Zones
-- This file contains admin commands for managing tribute zones

local tributeZoneBans = {}

-- Helper functions
local function isAllowedForTributeCommands(identifiers)
    for i = 1, #identifiers do
        if cfg.adminList[identifiers[i]] or cfg.techSupportList[identifiers[i]] then
            return true
        end
    end
    return false
end

local function getTributeZoneList()
    local zoneNames = {}
    for i = 1, #cfg.tributeZones do
        table.insert(zoneNames, cfg.tributeZones[i].name)
    end
    return table.concat(zoneNames, ', ')
end

local function getGangList()
    local gangNames = {}
    for name, _ in pairs(gangs) do
        table.insert(gangNames, name)
    end
    return table.concat(gangNames, ', ')
end

-- Load tribute zone bans from database
MySQL.ready(function()
    if not cfg.tributeZoneBans or not cfg.tributeZoneBans.enabled then return end
    
    -- Clean up expired bans
    MySQL.query.await('DELETE FROM rm_gangs_tribute_zone_bans WHERE banned_until < NOW()')
    
    -- Load active bans
    local banResults = MySQL.query.await('SELECT * FROM rm_gangs_tribute_zone_bans WHERE banned_until > NOW()')
    for i = 1, #banResults do
        local ban = banResults[i]
        tributeZoneBans[ban.gang_name] = {
            bannedUntil = ban.banned_until,
            reason = ban.reason,
            bannedBy = ban.banned_by,
            bannedDate = ban.banned_date
        }
    end
    
    lib.print.info(('Loaded %d tribute zone bans'):format(#banResults))
end)

-- Function to check if gang is banned from tribute zones
function isTributeZoneBanned(gangName)
    if not cfg.tributeZoneBans or not cfg.tributeZoneBans.enabled then return false end
    if not tributeZoneBans[gangName] then return false end
    
    local bannedUntil = MySQL.scalar.await('SELECT UNIX_TIMESTAMP(banned_until) FROM rm_gangs_tribute_zone_bans WHERE gang_name = ? AND banned_until > NOW()', {gangName})
    
    if not bannedUntil then
        tributeZoneBans[gangName] = nil
        return false
    end
    
    return true
end

-- /resettributezone - Reset tribute zone to neutral
if cfg.commands.resettributezone then
    lib.addCommand(cfg.commands.resettributezone, {
        help = 'Reset a tribute zone to neutral state',
        params = {
            { name = 'zone', help = 'Tribute zone name (' .. getTributeZoneList() .. ')', type = 'string' },
        },
    }, function(source, args, raw)
        local identifiers = GetPlayerIdentifiers(source)
        if IsPlayerAceAllowed(source, 'command') or isAllowedForTributeCommands(identifiers) then
            local zoneName = args['zone']
            
            if not tributeZones[zoneName] then
                return notify(source, 'Tribute zone not found. Available: ' .. getTributeZoneList(), 'error')
            end
            
            -- Cancel any ongoing capture event
            if tributeZones[zoneName]._captureEventData then
                tributeZones[zoneName]._captureEventData = nil
                TriggerClientEvent('rm_gangs:client:onTributeEventCancelled', -1, zoneName)
            end
            
            local oldOwner = tributeZones[zoneName].owner
            
            -- Reset zone to neutral
            tributeZones[zoneName].owner = nil
            tributeZones[zoneName].captureDate = nil
            tributeZones[zoneName].lastReceiptDate = nil
            
            -- Update database
            MySQL.update('UPDATE rm_gangs_tribute_zones SET owner = NULL, captureDate = NULL, lastReceiptDate = NULL WHERE name = ?', {
                zoneName
            })
            
            -- Deduct loyalty points from old owner
            if oldOwner and cfg.tributeZoneLoyalty and cfg.tributeZoneLoyalty > 0 then
                if gangs[oldOwner] then
                    gangs[oldOwner].loyalty = math.max(0, (gangs[oldOwner].loyalty or 0) - cfg.tributeZoneLoyalty)
                    MySQL.update('UPDATE rm_gangs_main SET loyalty = ? WHERE name = ?', {
                        gangs[oldOwner].loyalty,
                        oldOwner,
                    })
                    
                    TriggerClientEvent('rm_gangs:client:updateLoyalty', -1, {
                        gangName = oldOwner,
                        newPoint = gangs[oldOwner].loyalty,
                    })
                end
            end
            
            -- Reset payment intervals
            for i = 1, #tributeZones[zoneName].paymentIntervals do
                tributeZones[zoneName].paymentIntervals[i].receipt = false
            end
            
            notify(source, ('Tribute zone %s has been reset to neutral'):format(tributeZones[zoneName].label), 'success')
            
            -- Send notifications
            local resetMsg = ('🔄 Admin reset %s to neutral'):format(tributeZones[zoneName].label)
            TriggerClientEvent('rm_gangs:client:showBigNotification', -1, resetMsg, 'info')
            
            local eventData = {
                name = zoneName,
                label = tributeZones[zoneName].label,
                ownerName = nil,
                ownerLabel = nil,
                captureDate = nil,
                oldOwnerName = oldOwner,
                oldOwnerLabel = oldOwner and gangs[oldOwner] and gangs[oldOwner].label or nil,
                resetBy = GetPlayerName(source)
            }
            
            TriggerEvent('rm_gangs:server:onTributeZoneReset', eventData)
            TriggerClientEvent('rm_gangs:client:onTributeZoneReset', -1, eventData)
            
            local adminMessage = ('Admin %s reset tribute zone %s to neutral'):format(GetPlayerName(source), tributeZones[zoneName].label)
            lib.print.info(adminMessage)
            
        else
            notify(source, 'You do not have permission to use this command', 'error')
        end
    end)
end

-- /bantributegang - Ban gang from tribute zones
if cfg.commands.bantributegang then
    lib.addCommand(cfg.commands.bantributegang, {
        help = 'Ban a gang from participating in tribute zones',
        params = {
            { name = 'gang', help = 'Gang name (' .. getGangList() .. ')', type = 'string' },
            { name = 'hours', help = 'Ban duration in hours (max: ' .. (cfg.tributeZoneBans.maxBanDuration or 168) .. ')', type = 'number' },
            { name = 'reason', help = 'Ban reason (optional)', type = 'string', optional = true },
        },
    }, function(source, args, raw)
        local identifiers = GetPlayerIdentifiers(source)
        if IsPlayerAceAllowed(source, 'command') or isAllowedForTributeCommands(identifiers) then
            if not cfg.tributeZoneBans or not cfg.tributeZoneBans.enabled then
                return notify(source, 'Tribute zone ban system is disabled', 'error')
            end
            
            local gangName = args['gang']
            local hours = args['hours']
            local reason = args['reason'] or 'Admin ban'
            local maxHours = cfg.tributeZoneBans.maxBanDuration or 168
            
            if not gangs[gangName] then
                return notify(source, 'Gang not found. Available: ' .. getGangList(), 'error')
            end
            
            if hours > maxHours then
                return notify(source, ('Ban duration cannot exceed %d hours'):format(maxHours), 'error')
            end
            
            if isTributeZoneBanned(gangName) then
                return notify(source, 'Gang is already banned from tribute zones', 'error')
            end
            
            local bannedUntil = os.date('%Y-%m-%d %H:%M:%S', os.time() + (hours * 3600))
            
            -- Insert ban
            MySQL.insert.await('INSERT INTO rm_gangs_tribute_zone_bans (gang_name, banned_until, reason, banned_by) VALUES (?, ?, ?, ?)', {
                gangName,
                bannedUntil,
                reason,
                GetPlayerName(source)
            })
            
            -- Update local ban cache
            tributeZoneBans[gangName] = {
                bannedUntil = bannedUntil,
                reason = reason,
                bannedBy = GetPlayerName(source),
                bannedDate = os.date('%Y-%m-%d %H:%M:%S')
            }
            
            notify(source, ('Gang %s has been banned from tribute zones for %d hours'):format(gangs[gangName].label, hours), 'success')
            
            -- Send notification to gang members
            local banMsg = ('⚠️ Your gang has been banned from tribute zones for %d hours. Reason: %s'):format(hours, reason)
            local gangMembers = getOnlineGangMembers(gangName)
            for i = 1, #gangMembers do
                notify(gangMembers[i], banMsg, 'error', 10000)
            end
            
            local adminMessage = ('Admin %s banned gang %s from tribute zones for %d hours'):format(GetPlayerName(source), gangs[gangName].label, hours)
            lib.print.info(adminMessage)
            
        else
            notify(source, 'You do not have permission to use this command', 'error')
        end
    end)
end

-- /unbantributegang - Unban gang from tribute zones
if cfg.commands.unbantributegang then
    lib.addCommand(cfg.commands.unbantributegang, {
        help = 'Unban a gang from tribute zones',
        params = {
            { name = 'gang', help = 'Gang name (' .. getGangList() .. ')', type = 'string' },
        },
    }, function(source, args, raw)
        local identifiers = GetPlayerIdentifiers(source)
        if IsPlayerAceAllowed(source, 'command') or isAllowedForTributeCommands(identifiers) then
            if not cfg.tributeZoneBans or not cfg.tributeZoneBans.enabled then
                return notify(source, 'Tribute zone ban system is disabled', 'error')
            end
            
            local gangName = args['gang']
            
            if not gangs[gangName] then
                return notify(source, 'Gang not found. Available: ' .. getGangList(), 'error')
            end
            
            if not isTributeZoneBanned(gangName) then
                return notify(source, 'Gang is not banned from tribute zones', 'error')
            end
            
            -- Remove ban
            MySQL.query.await('DELETE FROM rm_gangs_tribute_zone_bans WHERE gang_name = ?', {gangName})
            
            -- Update local ban cache
            tributeZoneBans[gangName] = nil
            
            notify(source, ('Gang %s has been unbanned from tribute zones'):format(gangs[gangName].label), 'success')
            
            -- Send notification to gang members
            local unbanMsg = ('✅ Your gang ban from tribute zones has been lifted!')
            local gangMembers = getOnlineGangMembers(gangName)
            for i = 1, #gangMembers do
                notify(gangMembers[i], unbanMsg, 'success', 5000)
            end
            
            local adminMessage = ('Admin %s unbanned gang %s from tribute zones'):format(GetPlayerName(source), gangs[gangName].label)
            lib.print.info(adminMessage)
            
        else
            notify(source, 'You do not have permission to use this command', 'error')
        end
    end)
end

-- Export functions
exports('isTributeZoneBanned', isTributeZoneBanned)

-- Override tribute zone capture to check bans
local originalTributeEventHandler = tributeEventHandler
tributeEventHandler = function(zoneName, startedBy)
    -- Check if any participating gangs are banned
    local bannedGangs = {}
    for gangName, _ in pairs(gangs) do
        if isTributeZoneBanned(gangName) then
            table.insert(bannedGangs, gangs[gangName].label)
        end
    end
    
    if #bannedGangs > 0 and startedBy then -- Only show warning for manual starts
        local warnMsg = ('Warning: The following gangs are banned from tribute zones: %s'):format(table.concat(bannedGangs, ', '))
        notify(GetPlayerIdFromName(startedBy) or -1, warnMsg, 'warning')
    end
    
    -- Call original function
    originalTributeEventHandler(zoneName, startedBy)
end
