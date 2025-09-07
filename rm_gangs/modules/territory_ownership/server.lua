territories = {}
territoryOwnership = {}
conquestState = {
    active = false,
    startTime = nil,
    endTime = nil,
    territories = {}
}
gangBans = {}

-- Initialize territory ownership system
MySQL.ready(function()
    if not cfg.territorySystem.enabled then return end
    
    -- Clean up old conquest schedules
    MySQL.query.await('DELETE FROM rm_gangs_conquest_schedule WHERE end_time < NOW()')
    
    -- Clean up expired gang bans
    MySQL.query.await('DELETE FROM rm_gangs_banned_gangs WHERE banned_until < NOW()')
    
    -- Load territory ownership data
    local ownershipResults = MySQL.query.await('SELECT * FROM rm_gangs_territory_ownership')
    for i = 1, #ownershipResults do
        local territory = ownershipResults[i]
        territoryOwnership[territory.territory_name] = {
            gangName = territory.gang_name,
            captureDate = territory.capture_date,
            lastAttackDate = territory.last_attack_date,
            isLocked = territory.is_locked == 1,
            underAttack = territory.under_attack == 1,
            attackEndTime = territory.attack_end_time
        }
    end
    
    -- Load gang bans
    local banResults = MySQL.query.await('SELECT * FROM rm_gangs_banned_gangs WHERE banned_until > NOW()')
    for i = 1, #banResults do
        local ban = banResults[i]
        gangBans[ban.gang_name] = {
            bannedUntil = ban.banned_until,
            reason = ban.reason,
            bannedBy = ban.banned_by,
            bannedDate = ban.banned_date
        }
    end
    
    -- Initialize territories from gang config
    for territoryName, territoryData in pairs(cfg.gangs) do
        territories[territoryName] = {
            name = territoryName,
            label = territoryData.label or territoryName,
            color = territoryData.color,
            territory = territoryData.territory,
            locations = territoryData.locations
        }
        
        -- Initialize ownership if not exists
        if not territoryOwnership[territoryName] then
            territoryOwnership[territoryName] = {
                gangName = nil,
                captureDate = nil,
                lastAttackDate = nil,
                isLocked = false,
                underAttack = false,
                attackEndTime = nil
            }
            MySQL.insert.await('INSERT IGNORE INTO rm_gangs_territory_ownership (territory_name) VALUES (?)', {territoryName})
        end
    end
    
    -- Add territory_points column if doesn't exist
    MySQL.query('ALTER TABLE rm_gangs_main ADD COLUMN IF NOT EXISTS territory_points INT(11) DEFAULT 0')
    
    -- Update territory points for all gangs
    updateAllTerritoryPoints()
    
    -- Schedule automatic conquest times
    scheduleAutomaticConquests()
    
    lib.print.info('Territory ownership system initialized')
end)

-- Function to update territory points for all gangs
function updateAllTerritoryPoints()
    if not cfg.territorySystem.enabled then return end
    
    -- Reset all territory points
    for gangName, _ in pairs(gangs) do
        gangs[gangName].territory_points = 0
    end
    
    -- Count owned territories for each gang
    for territoryName, ownership in pairs(territoryOwnership) do
        if ownership.gangName and gangs[ownership.gangName] then
            gangs[ownership.gangName].territory_points = (gangs[ownership.gangName].territory_points or 0) + cfg.territorySystem.pointsPerTerritory
        end
    end
    
    -- Update database
    for gangName, gangData in pairs(gangs) do
        MySQL.update('UPDATE rm_gangs_main SET territory_points = ? WHERE name = ?', {
            gangData.territory_points or 0,
            gangName
        })
    end
    
    -- Notify clients
    TriggerClientEvent('rm_gangs:client:updateTerritoryPoints', -1, gangs)
end

-- Function to check if gang is banned
function isGangBanned(gangName)
    if not gangBans[gangName] then return false end
    
    local currentTime = os.time()
    local bannedUntil = MySQL.scalar.await('SELECT UNIX_TIMESTAMP(banned_until) FROM rm_gangs_banned_gangs WHERE gang_name = ? AND banned_until > NOW()', {gangName})
    
    if not bannedUntil then
        gangBans[gangName] = nil
        return false
    end
    
    return true
end

-- Function to claim territory for a gang
function claimTerritory(territoryName, gangName, playerId)
    if not cfg.territorySystem.enabled then return false, 'Territory system is disabled' end
    if not territories[territoryName] then return false, 'Territory does not exist' end
    if not gangs[gangName] then return false, 'Gang does not exist' end
    
    -- Check if gang is banned
    if isGangBanned(gangName) then
        return false, 'Your gang is currently banned from claiming territories'
    end
    
    -- Check if territory is locked
    if territoryOwnership[territoryName].isLocked then
        return false, 'This territory is currently locked by administrators'
    end
    
    local oldOwner = territoryOwnership[territoryName].gangName
    
    -- Update territory ownership
    territoryOwnership[territoryName].gangName = gangName
    territoryOwnership[territoryName].captureDate = os.date('%Y-%m-%d %H:%M:%S')
    territoryOwnership[territoryName].underAttack = false
    territoryOwnership[territoryName].attackEndTime = nil
    
    -- Update database
    MySQL.update('UPDATE rm_gangs_territory_ownership SET gang_name = ?, capture_date = NOW(), under_attack = 0, attack_end_time = NULL WHERE territory_name = ?', {
        gangName, territoryName
    })
    
    -- Update territory points
    updateAllTerritoryPoints()
    
    -- Send notifications
    local eventData = {
        territoryName = territoryName,
        territoryLabel = territories[territoryName].label,
        newOwner = gangName,
        newOwnerLabel = gangs[gangName].label,
        oldOwner = oldOwner,
        oldOwnerLabel = oldOwner and gangs[oldOwner] and gangs[oldOwner].label or nil,
        claimedBy = playerId
    }
    
    TriggerEvent('rm_gangs:server:onTerritoryClaimed', eventData)
    TriggerClientEvent('rm_gangs:client:onTerritoryClaimed', -1, eventData)
    
    if cfg.territorySystem.adminNotifications then
        local adminMessage = ('Territory %s claimed by %s'):format(
            territories[territoryName].label,
            gangs[gangName].label
        )
        notifyAdmins(adminMessage, 'info')
    end
    
    return true, 'Territory claimed successfully'
end

-- Function to start territory attack
function startTerritoryAttack(territoryName, attackingGang, playerId)
    if not cfg.territorySystem.enabled then return false, 'Territory system is disabled' end
    if not territories[territoryName] then return false, 'Territory does not exist' end
    if not gangs[attackingGang] then return false, 'Gang does not exist' end
    
    -- Check if gang is banned
    if isGangBanned(attackingGang) then
        return false, 'Your gang is currently banned from attacking territories'
    end
    
    -- Check if territory is locked
    if territoryOwnership[territoryName].isLocked then
        return false, 'This territory is currently locked by administrators'
    end
    
    -- Check if territory is already under attack
    if territoryOwnership[territoryName].underAttack then
        return false, 'This territory is already under attack'
    end
    
    -- Check conquest time (if not in conquest period, only allow if territory is unowned or admin override)
    if not conquestState.active and territoryOwnership[territoryName].gangName then
        return false, 'Territory attacks are only allowed during conquest periods'
    end
    
    -- Check cooldown
    if territoryOwnership[territoryName].lastAttackDate then
        local lastAttack = MySQL.scalar.await('SELECT UNIX_TIMESTAMP(last_attack_date) FROM rm_gangs_territory_ownership WHERE territory_name = ?', {territoryName})
        local cooldownEnd = lastAttack + (cfg.territorySystem.attackCooldown * 60)
        if os.time() < cooldownEnd then
            local remainingTime = math.ceil((cooldownEnd - os.time()) / 60)
            return false, ('Territory is on cooldown. %d minutes remaining'):format(remainingTime)
        end
    end
    
    -- Check minimum attackers requirement
    local attackingMembers = getOnlineGangMembers(attackingGang)
    if #attackingMembers < cfg.territorySystem.minAttackersRequired then
        return false, ('At least %d gang members must be online to attack a territory'):format(cfg.territorySystem.minAttackersRequired)
    end
    
    -- Start attack
    local attackEndTime = os.time() + (cfg.territorySystem.attackDuration * 60)
    
    territoryOwnership[territoryName].underAttack = true
    territoryOwnership[territoryName].lastAttackDate = os.date('%Y-%m-%d %H:%M:%S')
    territoryOwnership[territoryName].attackEndTime = os.date('%Y-%m-%d %H:%M:%S', attackEndTime)
    
    -- Update database
    MySQL.update('UPDATE rm_gangs_territory_ownership SET under_attack = 1, last_attack_date = NOW(), attack_end_time = FROM_UNIXTIME(?) WHERE territory_name = ?', {
        attackEndTime, territoryName
    })
    
    -- Create attack event
    local eventData = {
        territoryName = territoryName,
        territoryLabel = territories[territoryName].label,
        attackingGang = attackingGang,
        attackingGangLabel = gangs[attackingGang].label,
        defendingGang = territoryOwnership[territoryName].gangName,
        defendingGangLabel = territoryOwnership[territoryName].gangName and gangs[territoryOwnership[territoryName].gangName].label or 'Neutral',
        startTime = os.time() * 1000,
        endTime = attackEndTime * 1000,
        initiatedBy = playerId
    }
    
    TriggerEvent('rm_gangs:server:onTerritoryAttackStarted', eventData)
    TriggerClientEvent('rm_gangs:client:onTerritoryAttackStarted', -1, eventData)
    
    -- Start attack monitoring thread
    CreateThread(function()
        monitorTerritoryAttack(territoryName, attackingGang, eventData)
    end)
    
    return true, ('Territory attack started! Attack duration: %d minutes'):format(cfg.territorySystem.attackDuration)
end

-- Function to monitor territory attack progress
function monitorTerritoryAttack(territoryName, attackingGang, eventData)
    local attackEndTime = os.time() + (cfg.territorySystem.attackDuration * 60)
    local updateInterval = 10000 -- 10 seconds
    
    while os.time() < attackEndTime and territoryOwnership[territoryName].underAttack do
        -- Count players in territory
        local attackerCount = 0
        local defenderCount = 0
        
        local zoneData = lib.table.deepclone(territories[territoryName].territory)
        local zone = lib.zones.poly(zoneData)
        
        local players = getOnlineGangMembers()
        for i = 1, #players do
            local playerId = players[i]
            if isPlayerAlive(playerId) then
                local playerGang = getPlayerGang(playerId)
                if playerGang and playerGang.name == attackingGang then
                    local ped = GetPlayerPed(playerId)
                    local coord = GetEntityCoords(ped)
                    if zone:contains(coord) then
                        attackerCount = attackerCount + 1
                    end
                elseif playerGang and playerGang.name == territoryOwnership[territoryName].gangName then
                    local ped = GetPlayerPed(playerId)
                    local coord = GetEntityCoords(ped)
                    if zone:contains(coord) then
                        defenderCount = defenderCount + 1
                    end
                end
            end
        end
        
        -- Apply defense bonus
        defenderCount = math.floor(defenderCount * cfg.territorySystem.defenseBonus)
        
        -- Update attack progress
        local progressData = {
            territoryName = territoryName,
            attackerCount = attackerCount,
            defenderCount = defenderCount,
            timeRemaining = attackEndTime - os.time(),
            attackingGang = attackingGang,
            defendingGang = territoryOwnership[territoryName].gangName
        }
        
        TriggerClientEvent('rm_gangs:client:updateTerritoryAttack', -1, progressData)
        
        zone:remove()
        Wait(updateInterval)
    end
    
    -- Resolve attack
    resolveTerritoryAttack(territoryName, attackingGang)
end

-- Function to resolve territory attack
function resolveTerritoryAttack(territoryName, attackingGang)
    if not territoryOwnership[territoryName].underAttack then return end
    
    -- Final count
    local attackerCount = 0
    local defenderCount = 0
    
    local zoneData = lib.table.deepclone(territories[territoryName].territory)
    local zone = lib.zones.poly(zoneData)
    
    local players = getOnlineGangMembers()
    for i = 1, #players do
        local playerId = players[i]
        if isPlayerAlive(playerId) then
            local playerGang = getPlayerGang(playerId)
            if playerGang and playerGang.name == attackingGang then
                local ped = GetPlayerPed(playerId)
                local coord = GetEntityCoords(ped)
                if zone:contains(coord) then
                    attackerCount = attackerCount + 1
                end
            elseif playerGang and playerGang.name == territoryOwnership[territoryName].gangName then
                local ped = GetPlayerPed(playerId)
                local coord = GetEntityCoords(ped)
                if zone:contains(coord) then
                    defenderCount = defenderCount + 1
                end
            end
        end
    end
    
    zone:remove()
    
    -- Apply defense bonus
    defenderCount = math.floor(defenderCount * cfg.territorySystem.defenseBonus)
    
    -- Determine winner
    local attackSuccessful = attackerCount > defenderCount
    local oldOwner = territoryOwnership[territoryName].gangName
    
    if attackSuccessful then
        -- Claim territory for attacking gang
        claimTerritory(territoryName, attackingGang, nil)
    else
        -- Attack failed, clear attack status
        territoryOwnership[territoryName].underAttack = false
        territoryOwnership[territoryName].attackEndTime = nil
        
        MySQL.update('UPDATE rm_gangs_territory_ownership SET under_attack = 0, attack_end_time = NULL WHERE territory_name = ?', {
            territoryName
        })
    end
    
    -- Send results
    local resultData = {
        territoryName = territoryName,
        territoryLabel = territories[territoryName].label,
        attackingGang = attackingGang,
        attackingGangLabel = gangs[attackingGang].label,
        defendingGang = oldOwner,
        defendingGangLabel = oldOwner and gangs[oldOwner] and gangs[oldOwner].label or 'Neutral',
        attackerCount = attackerCount,
        defenderCount = defenderCount,
        successful = attackSuccessful,
        newOwner = territoryOwnership[territoryName].gangName
    }
    
    TriggerEvent('rm_gangs:server:onTerritoryAttackFinished', resultData)
    TriggerClientEvent('rm_gangs:client:onTerritoryAttackFinished', -1, resultData)
end

-- Function to start conquest period
function startConquestPeriod(duration, territories_list, startedBy)
    if conquestState.active then
        return false, 'Conquest period is already active'
    end
    
    duration = duration or cfg.territorySystem.conquestDuration
    territories_list = territories_list or {}
    
    -- If no specific territories provided, include all territories
    if #territories_list == 0 then
        for territoryName, _ in pairs(territories) do
            table.insert(territories_list, territoryName)
        end
    end
    
    local startTime = os.time()
    local endTime = startTime + (duration * 60)
    
    conquestState = {
        active = true,
        startTime = startTime,
        endTime = endTime,
        territories = territories_list,
        startedBy = startedBy
    }
    
    -- Store in database
    local conquestId = MySQL.insert.await('INSERT INTO rm_gangs_conquest_schedule (conquest_name, start_time, end_time, is_active, territories_included, created_by) VALUES (?, FROM_UNIXTIME(?), FROM_UNIXTIME(?), 1, ?, ?)', {
        'Manual Conquest - ' .. os.date('%Y-%m-%d %H:%M:%S'),
        startTime,
        endTime,
        json.encode(territories_list),
        startedBy or 'System'
    })
    
    -- Notify all players
    local eventData = {
        conquestId = conquestId,
        startTime = startTime * 1000,
        endTime = endTime * 1000,
        duration = duration,
        territories = territories_list,
        startedBy = startedBy
    }
    
    TriggerEvent('rm_gangs:server:onConquestStarted', eventData)
    TriggerClientEvent('rm_gangs:client:onConquestStarted', -1, eventData)
    
    -- Schedule conquest end
    SetTimeout(duration * 60 * 1000, function()
        endConquestPeriod()
    end)
    
    return true, ('Conquest period started for %d minutes'):format(duration)
end

-- Function to end conquest period
function endConquestPeriod()
    if not conquestState.active then return false, 'No conquest period is active' end
    
    -- Update database
    MySQL.update('UPDATE rm_gangs_conquest_schedule SET is_active = 0 WHERE is_active = 1')
    
    -- End all ongoing attacks
    for territoryName, ownership in pairs(territoryOwnership) do
        if ownership.underAttack then
            resolveTerritoryAttack(territoryName, nil) -- This will resolve based on current status
        end
    end
    
    local eventData = {
        endTime = os.time() * 1000,
        duration = conquestState.endTime - conquestState.startTime,
        territories = conquestState.territories
    }
    
    conquestState = {
        active = false,
        startTime = nil,
        endTime = nil,
        territories = {}
    }
    
    TriggerEvent('rm_gangs:server:onConquestEnded', eventData)
    TriggerClientEvent('rm_gangs:client:onConquestEnded', -1, eventData)
    
    return true, 'Conquest period ended'
end

-- Function to schedule automatic conquest times
function scheduleAutomaticConquests()
    if not cfg.territorySystem.enabled then return end
    
    for _, conquestTime in pairs(cfg.territorySystem.defaultConquestTimes) do
        local cronExpr = ('0 %d %d * * %s'):format(
            conquestTime.minute,
            conquestTime.hour,
            conquestTime.day:sub(1, 3):upper()
        )
        
        lib.cron.new(cronExpr, function()
            startConquestPeriod(cfg.territorySystem.conquestDuration, {}, 'Automatic')
        end)
    end
end

-- Helper function to notify admins
function notifyAdmins(message, type)
    local players = GetPlayers()
    for i = 1, #players do
        local playerId = tonumber(players[i])
        if IsPlayerAceAllowed(playerId, 'command') then
            notify(playerId, message, type or 'info')
        end
    end
end

-- Export functions for other scripts
exports('claimTerritory', claimTerritory)
exports('startTerritoryAttack', startTerritoryAttack)
exports('getTerritoryOwnership', function() return territoryOwnership end)
exports('getConquestState', function() return conquestState end)
exports('isGangBanned', isGangBanned)
