turfWars = {}
local currentTurfWar

MySQL.ready(function()
    MySQL.query.await('DELETE FROM rm_gangs_turf_wars WHERE finishDate < (NOW() - INTERVAL 1 MONTH)')

    local currentTimestamp = os.time() * 1000
    local results = MySQL.query.await('SELECT * FROM rm_gangs_turf_wars')
    for i = 1, #results do
        local idx = #turfWars + 1
        if results[i].successful then
            turfWars[idx] = results[i]
            if turfWars[idx].successful == 1 then
                turfWars[idx].successful = true
            else
                turfWars[idx].successful = false
            end
        else
            MySQL.query('DELETE FROM rm_gangs_turf_wars WHERE id = ?', { results[i].id })
        end
    end
end)

RegisterNetEvent('rm_gangs:server:startTurfWar', function(targetGang)
    local playerId = source
    if currentTurfWar then
        return notify(playerId, locale('cannot_create_turf_when_ongoing'), 'error')
    end

    if not gangs[targetGang] then return end
    local targetMembers = getOnlineGangMembers(targetGang)
    if cfg.turfWarRequiredTargetMemberCount > #targetMembers then
        return notify(playerId, locale('cannot_create_turf_not_enough_target_member'), 'error')
    end

    local initiatorGang = getPlayerGang(playerId)
    if not gangs[initiatorGang?.name] then return end

    local currentTimestamp = os.time() * 1000
    local startDate = currentTimestamp + (cfg.turfWarStartDelay * 60 * 1000)
    local finishDate = startDate + (cfg.turfWarDuration * 60 * 1000)
    local idx = #turfWars + 1
    turfWars[idx] = {
        initiator = initiatorGang.name,
        target = targetGang,
        initiatorPersonCount = 0,
        targetPersonCount = 0,
        declareDate = currentTimestamp,
        startDate = startDate,
        finishDate = finishDate,
    }

    turfWars[idx].id = MySQL.insert.await('INSERT INTO rm_gangs_turf_wars (initiator, target, declareDate, startDate, finishDate) VALUES (?, ?, FROM_UNIXTIME(?), FROM_UNIXTIME(?), FROM_UNIXTIME(?))', {
        turfWars[idx].initiator,
        turfWars[idx].target,
        turfWars[idx].declareDate / 1000,
        turfWars[idx].startDate / 1000,
        turfWars[idx].finishDate / 1000,
    })

    currentTurfWar = { idx = idx }
    gangs[targetGang]._turfWarId = turfWars[idx].id

    local eventData = {
        id = turfWars[idx].id,
        initiatorName = initiatorGang.name,
        initiatorLabel = initiatorGang.label,
        targetName = targetGang,
        targetLabel = gangs[targetGang].label,
        declareDate = turfWars[idx].declareDate,
        startDate = turfWars[idx].startDate,
        finishDate = turfWars[idx].finishDate,
    }
    TriggerEvent('rm_gangs:server:onTurfWarStarted', eventData)
    TriggerClientEvent('rm_gangs:client:onTurfWarStarted', -1, eventData)

    while os.time() * 1000 < turfWars[idx].startDate do
        Wait(10000)
    end
    turfWars[idx].started = true

    local zoneData = lib.table.deepclone(gangs[targetGang].territory)
    currentTurfWar.zone = lib.zones.poly(zoneData)

    while os.time() * 1000 < turfWars[idx].finishDate do
        turfWars[idx].initiatorPersonCount = 0
        turfWars[idx].targetPersonCount = 0
        local players = getOnlineGangMembers()
        for i = 1, #players do
            local playerId = players[i]
            if isPlayerAlive(playerId) then
                local playerGang = getPlayerGang(playerId)
                if playerGang.name == targetGang then
                    local ped = GetPlayerPed(playerId)
                    local coord = GetEntityCoords(ped)
                    if currentTurfWar.zone:contains(coord) then
                        turfWars[idx].targetPersonCount += 1
                    end
                elseif playerGang.name == initiatorGang.name then
                    local ped = GetPlayerPed(playerId)
                    local coord = GetEntityCoords(ped)
                    if currentTurfWar.zone:contains(coord) then
                        turfWars[idx].initiatorPersonCount += 1
                    end
                end
            end
        end
        TriggerClientEvent('rm_gangs:client:updateTurfWar', -1, targetGang, turfWars[idx])
        Wait(10000)
    end

    turfWars[idx].successful = turfWars[idx].targetPersonCount < turfWars[idx].initiatorPersonCount
    if turfWars[idx].successful then
        gangs[initiatorGang.name].loyalty += cfg.turfWarLoyalty
        gangs[targetGang].loyalty -= cfg.turfWarLoyalty
    else
        gangs[initiatorGang.name].loyalty -= cfg.turfWarLoyalty
        gangs[targetGang].loyalty += cfg.turfWarLoyalty
    end

    MySQL.update('UPDATE rm_gangs_turf_wars SET successful = ?, initiatorPersonCount = ?, targetPersonCount = ? WHERE id = ?', {
        turfWars[idx].successful and 1 or 0,
        turfWars[idx].initiatorPersonCount,
        turfWars[idx].targetPersonCount,
        turfWars[idx].id,
    })
    MySQL.update('UPDATE rm_gangs_main SET loyalty = ? WHERE name = ?', {
        gangs[initiatorGang.name].loyalty,
        initiatorGang.name,
    })
    MySQL.update('UPDATE rm_gangs_main SET loyalty = ? WHERE name = ?', {
        gangs[targetGang].loyalty,
        targetGang,
    })

    local eventData = {
        id = turfWars[idx].id,
        initiatorName = initiatorGang.name,
        initiatorLabel = initiatorGang.label,
        initiatorNewLoyalty = gangs[initiatorGang.name].loyalty,
        initiatorPersonCount = turfWars[idx].initiatorPersonCount,
        targetName = targetGang,
        targetLabel = gangs[targetGang].label,
        targetNewLoyalty = gangs[targetGang].loyalty,
        targetPersonCount = turfWars[idx].targetPersonCount,
        successful = turfWars[idx].successful,
        declareDate = turfWars[idx].declareDate,
        startDate = turfWars[idx].startDate,
        finishDate = turfWars[idx].finishDate,
    }
    TriggerEvent('rm_gangs:server:onTurfWarFinished', eventData)
    TriggerClientEvent('rm_gangs:client:onTurfWarFinished', -1, eventData)

    currentTurfWar.zone:remove()
    currentTurfWar = nil
    gangs[targetGang]._turfWarId = nil
end)

RegisterNetEvent('rm_gangs:server:onPlayerDead', function(attackerId)
    if currentTurfWar then
        local idx = currentTurfWar.idx
        local zone = currentTurfWar.zone
        turfWars[idx].initiatorPersonCount = 0
        turfWars[idx].targetPersonCount = 0
        local players = getOnlineGangMembers()
        for i = 1, #players do
            local playerId = players[i]
            if isPlayerAlive(playerId) then
                local playerGang = getPlayerGang(playerId)
                if playerGang.name == turfWars[idx].target then
                    local ped = GetPlayerPed(playerId)
                    local coord = GetEntityCoords(ped)
                    if zone:contains(coord) then
                        turfWars[idx].targetPersonCount += 1
                    end
                elseif playerGang.name == turfWars[idx].initiator then
                    local ped = GetPlayerPed(playerId)
                    local coord = GetEntityCoords(ped)
                    if zone:contains(coord) then
                        turfWars[idx].initiatorPersonCount += 1
                    end
                end
            end
        end
        TriggerClientEvent('rm_gangs:client:updateTurfWar', -1, turfWars[idx].target, turfWars[idx])
    end
end)
