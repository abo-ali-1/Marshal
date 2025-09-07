tributeZones = {}

local intervalCount = 24 / cfg.tributePaymentInterval
local intervalDuration = cfg.tributePaymentInterval * 60 * 60 * 1000

local function getTimezoneOffset()
    local currentTime = os.time()
    local utcdate     = os.date('!*t', currentTime)
    local localdate   = os.date('*t', currentTime)
    localdate.isdst   = false
    return os.difftime(os.time(localdate), os.time(utcdate))
end

local tzOffset = getTimezoneOffset()

local function calculatePaymentIntervals()
    local currentTime = os.date('!*t')
    local intervals = {}

    local dayStart = os.time({
        year = currentTime.year,
        month = currentTime.month,
        day = currentTime.day,
        hour = 0,
        min = 0,
        sec = 0,
    })

    dayStart += tzOffset

    for i = 1, intervalCount do
        local intervalSeconds = (i - 1) * (24 * 60 * 60 / intervalCount)
        local timestamp = dayStart + intervalSeconds

        intervals[#intervals + 1] = {
            receipt = false,
            startTimestamp = timestamp * 1000,
        }
    end

    return intervals
end

function getIntervalIndex(intervals, timestamp)
    local timestamp = timestamp or os.time() * 1000
    for i = #intervals, 1, -1 do
        if timestamp >= intervals[i].startTimestamp then
            return i
        end
    end
    return nil
end

local function parseDayOfWeekPart(part)
    local days = { locale('sun'), locale('mon'), locale('tue'), locale('wed'), locale('thu'), locale('fri'), locale('sat') }
    local dayNames = {}
    for token in part:gmatch('%S+') do
        local rangeStart, rangeEnd, step = token:match('(%d+)-(%d+)/(%d+)')
        if rangeStart and rangeEnd and step then
            for day = tonumber(rangeStart), tonumber(rangeEnd), tonumber(step) do
                table.insert(dayNames, days[(day % 7) + 1])
            end
        elseif token:match('/') then
            local _, step = token:match('.*/(%d+)')
            for day = 0, 6, tonumber(step) do
                table.insert(dayNames, days[(day % 7) + 1])
            end
        elseif token:match('%d+-%d+') then
            local start, _, step = token:match('(%d+)-(%d+)/(%d+)')
            if start and step then
                for day = tonumber(start), 6, tonumber(step) do
                    table.insert(dayNames, days[(day % 7) + 1])
                end
            end
        elseif tonumber(token) then
            local day = tonumber(token)
            table.insert(dayNames, days[(day % 7) + 1])
        else
            local index = 1
            while days[index] do
                if days[index]:lower():sub(1, #token) == token:lower() then
                    table.insert(dayNames, days[index])
                end
                index = index + 1
            end
        end
    end
    return dayNames
end

local function cronExpressionToReadable(expression)
    local parts = {}
    for part in expression:gmatch('%S+') do
        parts[#parts + 1] = part
    end

    local minutePart = parts[1]
    local hourPart = parts[2]
    local hourReadable
    if hourPart == '*' then
        hourReadable = locale('every_hour')
    else
        local hour = tonumber(hourPart)
        local minute = tonumber(minutePart)
        if cfg.clockFormat == '24' then
            hourReadable = string.format('%02d', hour) .. ':' .. string.format('%02d', minute)
        else
            if hour < 12 then
                hourReadable = string.format('%02d', hour) .. ':' .. string.format('%02d', minute) .. ' AM'
            elseif hour == 12 then
                hourReadable = '12:00 PM'
            else
                hourReadable = string.format('%02d', hour - 12) .. ':' .. string.format('%02d', minute) .. ' PM'
            end
        end
    end

    local dayOfWeekPart = parts[5]
    local dayOfWeekReadable
    if dayOfWeekPart == '*' then
        dayOfWeekReadable = locale('every_day')
    else
        local dayNames = parseDayOfWeekPart(dayOfWeekPart)
        dayOfWeekReadable = table.concat(dayNames, ', ')
    end

    local result = locale('on_day_at_hour', dayOfWeekReadable, hourReadable)
    return result
end

local function tributeEventHandler(zoneName, startedBy)
    if tributeZones[zoneName]._captureEventData then return lib.print.warn(locale('ongoing_tribute_war', tributeZones[zoneName].label)) end

    local oldOwner = tributeZones[zoneName].owner
    tributeZones[zoneName].owner = nil
    
    -- Send notifications to all players
    local notificationMsg = ('🚨 Tribute zone %s is now under attack!'):format(tributeZones[zoneName].label)
    TriggerClientEvent('rm_gangs:client:showBigNotification', -1, notificationMsg, 'warning')
    
    -- Send Discord notification
    if sendTributeZoneAttackNotification then
        sendTributeZoneAttackNotification(zoneName, tributeZones[zoneName].label, oldOwner)
    end
    
    -- Log admin/scheduled start
    if startedBy then
        if sendManualTributeStartNotification then
            sendManualTributeStartNotification(zoneName, tributeZones[zoneName].label, startedBy)
        end
        lib.print.info(('Tribute zone %s manually started by %s'):format(tributeZones[zoneName].label, startedBy))
    else
        if sendScheduledTributeNotification then
            sendScheduledTributeNotification(zoneName, tributeZones[zoneName].label)
        end
        lib.print.info(('Tribute zone %s started by schedule'):format(tributeZones[zoneName].label))
    end
    tributeZones[zoneName]._captureEventData = {
        finishDate = (os.time() * 1000) + (tributeZones[zoneName].captureDuration * 60 * 1000),
        points = {},
        zoneLabel = tributeZones[zoneName].label,
    }

    local eventData = {
        name = zoneName,
        label = tributeZones[zoneName].label,
        finishDate = tributeZones[zoneName]._captureEventData.finishDate,
        paymentAmount = tributeZones[zoneName].paymentAmount,
        captureDuration = tributeZones[zoneName].captureDuration,
        coords = tributeZones[zoneName].npc.coord,
        territory = tributeZones[zoneName].territory,
        oldOwnerName = oldOwner,
        oldOwnerLabel = gangs[oldOwner]?.label or nil,
    }
    TriggerEvent('rm_gangs:server:onTributeEventStarted', eventData)
    TriggerClientEvent('rm_gangs:client:onTributeEventStarted', -1, eventData)


    local zoneData = lib.table.deepclone(tributeZones[zoneName].territory)
    local zone = lib.zones.poly(zoneData)
    while tributeZones[zoneName]._captureEventData and os.time() * 1000 < tributeZones[zoneName]._captureEventData.finishDate do
        local players = getOnlineGangMembers()
        for i = 1, #players do
            local playerId = players[i]
            if isPlayerAlive(playerId) then
                local playerGang = getPlayerGang(playerId)
                local ped = GetPlayerPed(playerId)
                local coord = GetEntityCoords(ped)
                if zone:contains(coord) then
                    if not tributeZones[zoneName]._captureEventData.points[playerGang.name] then
                        tributeZones[zoneName]._captureEventData.points[playerGang.name] = 0
                    end
                    tributeZones[zoneName]._captureEventData.points[playerGang.name] += 10
                end
            end
        end
        TriggerClientEvent('rm_gangs:client:updateCaptureEvent', -1, zoneName, tributeZones[zoneName]._captureEventData)
        Wait(10000)
    end
    zone:remove()
    local newOwner
    if tributeZones[zoneName]._captureEventData then
        for gangName, point in pairs(tributeZones[zoneName]._captureEventData.points) do
            if point > 0 then
                if not newOwner then
                    newOwner = gangName
                elseif tributeZones[zoneName]._captureEventData.points[newOwner] < tributeZones[zoneName]._captureEventData.points[gangName] then
                    newOwner = gangName
                end
            end
        end

        tributeZones[zoneName]._captureEventData = nil
        if newOwner then
            local currentTimestamp = os.time() * 1000
            tributeZones[zoneName].owner = newOwner
            tributeZones[zoneName].captureDate = currentTimestamp
            tributeZones[zoneName].lastReceiptDate = nil

            MySQL.prepare.await('UPDATE rm_gangs_tribute_zones SET lastReceiptDate = NULL, owner = ?, captureDate = FROM_UNIXTIME(?) WHERE name = ?', {
                newOwner, currentTimestamp / 1000, zoneName,
            })

            for i = 1, #tributeZones[zoneName].paymentIntervals do
                tributeZones[zoneName].paymentIntervals[i].receipt = false
            end
            
            -- Award loyalty points for capturing tribute zone
            if cfg.tributeZoneLoyalty and cfg.tributeZoneLoyalty > 0 then
                if gangs[newOwner] then
                    gangs[newOwner].loyalty = (gangs[newOwner].loyalty or 0) + cfg.tributeZoneLoyalty
                    MySQL.update('UPDATE rm_gangs_main SET loyalty = ? WHERE name = ?', {
                        gangs[newOwner].loyalty,
                        newOwner,
                    })
                    
                    TriggerClientEvent('rm_gangs:client:updateLoyalty', -1, {
                        gangName = newOwner,
                        newPoint = gangs[newOwner].loyalty,
                    })
                    
                    lib.print.info(('Gang %s gained %d loyalty points for capturing %s'):format(gangs[newOwner].label, cfg.tributeZoneLoyalty, tributeZones[zoneName].label))
                end
            end
            
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
                    
                    lib.print.info(('Gang %s lost %d loyalty points for losing %s'):format(gangs[oldOwner].label, cfg.tributeZoneLoyalty, tributeZones[zoneName].label))
                end
            end
        end
    else
        newOwner = oldOwner
    end

    local eventData = {
        name = zoneName,
        label = tributeZones[zoneName].label,
        paymentAmount = tributeZones[zoneName].paymentAmount,
        captureDuration = tributeZones[zoneName].captureDuration,
        coords = tributeZones[zoneName].npc.coord,
        territory = tributeZones[zoneName].territory,
        ownerName = newOwner,
        ownerLabel = gangs[newOwner]?.label or nil,
        captureDate = tributeZones[zoneName].captureDate or nil,
        oldOwnerName = oldOwner,
        oldOwnerLabel = gangs[oldOwner]?.label or nil,
    }
    
    -- Send capture completion notifications
    local captureMsg
    if newOwner and gangs[newOwner] then
        captureMsg = ('🏰 %s captured %s!'):format(gangs[newOwner].label, tributeZones[zoneName].label)
    else
        captureMsg = ('🏰 %s is now neutral!'):format(tributeZones[zoneName].label)
    end
    TriggerClientEvent('rm_gangs:client:showBigNotification', -1, captureMsg, 'success')
    
    -- Send Discord capture notification
    if sendTributeZoneCapturedNotification then
        sendTributeZoneCapturedNotification(zoneName, tributeZones[zoneName].label, newOwner, oldOwner)
    end
    
    TriggerEvent('rm_gangs:server:onTributeEventFinished', eventData)
    TriggerClientEvent('rm_gangs:client:onTributeEventFinished', -1, eventData)
end

local function isAllowedForStartTribute(identifiers)
    for i = 1, #identifiers do
        if cfg.adminList[identifiers[i]] then
            return true
        end
    end

    return false
end

if cfg.commands.starttribute then
    lib.addCommand(cfg.commands.starttribute, {
        help = locale('commands.starttribute.help'),
    }, function(source, args, raw)
        local identifiers = GetPlayerIdentifiers(source)
        if cfg.disableStartTributePermissionCheck or IsPlayerAceAllowed(source, 'command') or isAllowedForStartTribute(identifiers) then
            local _tributeZones = {}
            for zoneName, data in pairs(tributeZones) do
                _tributeZones[#_tributeZones + 1] = {
                    name = data.name,
                    label = data.label,
                    started = data._captureEventData and true or false,
                    paymentAmount = data.paymentAmount,
                }
            end
            TriggerClientEvent('rm_gangs:client:openManuelTributeStartMenu', source, _tributeZones)
        end
    end)
end

RegisterNetEvent('rm_gangs:server:manuelTributeStart', function(zoneName)
    local playerId = source

    local identifiers = GetPlayerIdentifiers(playerId)
    if cfg.disableStartTributePermissionCheck or IsPlayerAceAllowed(playerId, 'command.starttribute') or isAllowedForStartTribute(identifiers) then
        local adminName = GetPlayerName(playerId)
        tributeEventHandler(zoneName, adminName)
    end
end)

exports('cancelTributeEvent', function(zoneName)
    if tributeZones[zoneName]._captureEventData then
        tributeZones[zoneName]._captureEventData = nil
        lib.print.info(locale('cancel_tribute_war', tributeZones[zoneName].label))
    end
end)

MySQL.ready(function()
    for i = 1, #cfg.tributeZones do
        local zoneName = cfg.tributeZones[i].name

        MySQL.prepare.await('INSERT IGNORE INTO rm_gangs_tribute_zones (name) VALUES (?)', { zoneName })

        tributeZones[zoneName] = cfg.tributeZones[i]
        tributeZones[zoneName].paymentIntervals = calculatePaymentIntervals()

        if tributeZones[zoneName].resetCronExpression then
            tributeZones[zoneName].captureTimerLabel = cronExpressionToReadable(tributeZones[zoneName].resetCronExpression)
            lib.cron.new(tributeZones[zoneName].resetCronExpression, function()
                tributeEventHandler(zoneName, nil) -- nil means scheduled start
            end, { maxDelay = 30 })
        end
    end

    local results = MySQL.query.await('SELECT * FROM rm_gangs_tribute_zones')
    while not initialized do Wait(100) end

    for i = 1, #results do
        local zoneName = results[i].name
        if tributeZones[zoneName] then
            local owner = results[i].owner
            if owner then
                if gangs[owner] then
                    tributeZones[zoneName].owner = owner
                    tributeZones[zoneName].captureDate = results[i].captureDate

                    if results[i].lastReceiptDate == 0 then
                        tributeZones[zoneName].lastReceiptDate = nil
                    elseif results[i].lastReceiptDate then
                        local lastIntervalIndex = getIntervalIndex(tributeZones[zoneName].paymentIntervals, results[i].lastReceiptDate)
                        if lastIntervalIndex then
                            tributeZones[zoneName].paymentIntervals[lastIntervalIndex].receipt = true
                            tributeZones[zoneName].paymentResetTime = tributeZones[zoneName].paymentIntervals[lastIntervalIndex].startTimestamp + intervalDuration
                        end
                        tributeZones[zoneName].lastReceiptDate = results[i].lastReceiptDate
                    end
                else
                    tributeZones[zoneName].owner = nil
                    MySQL.prepare('UPDATE rm_gangs_tribute_zones SET owner = NULL, lastReceiptDate = NULL WHERE name = ?', {
                        zoneName,
                    })
                end
            end
        else
            MySQL.prepare('DELETE FROM rm_gangs_tribute_zones WHERE name = ?', { zoneName })
        end
    end

    lib.cron.new('0 0 * * *', function()
        for i = 1, #cfg.tributeZones do
            local zoneName = cfg.tributeZones[i].name
            if tributeZones[zoneName].paymentIntervals then
                tributeZones[zoneName].paymentIntervals = calculatePaymentIntervals()
            end
        end
    end, { maxDelay = 30 })
end)

RegisterNetEvent('rm_gangs:server:getTributePayment', function(zoneName)
    local playerId = source
    if not tributeZones[zoneName] then return end

    local currentIntervalIndex = getIntervalIndex(tributeZones[zoneName].paymentIntervals)
    if not currentIntervalIndex then return end

    if tributeZones[zoneName].paymentIntervals[currentIntervalIndex].receipt then
        return notify(playerId, locale('tribute_already_taken'), 'error')
    end

    if addMoneyToGang(tributeZones[zoneName].owner, tributeZones[zoneName].paymentAmount) then
        notify(playerId, locale('tribute_was_added_to_gang_money'), 'info')
    else
        notify(playerId, locale('add_gang_money_failed'), 'error')
        return
    end

    tributeZones[zoneName].paymentIntervals[currentIntervalIndex].receipt = true
    tributeZones[zoneName].paymentResetTime = tributeZones[zoneName].paymentIntervals[currentIntervalIndex].startTimestamp + intervalDuration

    local currentTime = os.time()
    MySQL.prepare.await('UPDATE rm_gangs_tribute_zones SET lastReceiptDate = FROM_UNIXTIME(?) WHERE name = ?', {
        currentTime, zoneName,
    })
    tributeZones[zoneName].lastReceiptDate = currentTime * 1000

    TriggerClientEvent('rm_gangs:client:updateTribute', -1, {
        name = zoneName,
        paymentResetTime = tributeZones[zoneName].paymentResetTime,
    })
end)

exports('getGangTributeZones', function(gangName)
    if gangName then
        local ownedZones = {}
        for zoneName, data in pairs(tributeZones) do
            if data.owner == gangName then
                ownedZones[#ownedZones + 1] = {
                    name = zoneName,
                    label = data.label,
                    paymentAmount = data.paymentAmount,
                    territory = data.territory,
                    owner = data.owner,
                    captureDate = data.captureDate,
                }
            end
        end

        return ownedZones
    else
        return
    end
end)
