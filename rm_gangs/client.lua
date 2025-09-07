currentZone, playerGang, playerData, nuiOpened, initialized = nil, nil, nil, nil, nil

RegisterNetEvent('rm_gangs:client:playerLoaded')
RegisterNetEvent('rm_gangs:client:playerUnloaded')

AddEventHandler('rm_gangs:client:playerLoaded', function(data, myData)
    playerGang = myData.gang
    playerData = myData.player
    local _gangs, _tributeZones = {}, {}
    for name, data in pairs(data.gangs) do
        local idx = #_gangs + 1
        _gangs[idx] = {
            name = name,
            label = data.label,
            logoURL = data.logoURL,
            color = data.color,
            money = data.money,
            territory = data.territory,
            loyalty = data.loyalty or 0,
        }
    end
    for name, data in pairs(data.tributeZones) do
        local idx = #_tributeZones + 1
        _tributeZones[idx] = {
            name = name,
            label = data.label,
            territory = data.territory,
            captureTimerLabel = data.captureTimerLabel,
            paymentAmount = data.paymentAmount,
            owner = data.owner,
            captureDate = data.captureDate,
            paymentResetTime = data.paymentResetTime,
        }
    end
    local locales = lib.getLocales()
    local uiLocales = {}
    for key, str in pairs(locales) do
        if key:find('ui.') then
            uiLocales[key:gsub('ui%.', '')] = str
        end
    end
    SendNUIMessage({
        action = 'setup',
        data = {
            cfg = {
                tributePaymentInterval = cfg.tributePaymentInterval,
                turfWarLoyalty = cfg.turfWarLoyalty,
                warLoyaltyPerKill = cfg.warLoyaltyPerKill,
                showEventNotificationsToEveryone = cfg.showEventNotificationsToEveryone,
                locationInfoTimer = cfg.locationInfoTimer,
                warMinWager = cfg.warMinWager,
                warMaxWager = cfg.warMaxWager,
                warMinKillGoal = cfg.warMinKillGoal,
                warMaxKillGoal = cfg.warMaxKillGoal,
                locationInfoPosition = cfg.locationInfoPosition,
                notificationPosition = cfg.notificationPosition,
                notificationPositionWhenInterfaceOpened = cfg.notificationPositionWhenInterfaceOpened,
                tributeScoreboardPosition = cfg.tributeScoreboardPosition,
                turfScoreboardPosition = cfg.turfScoreboardPosition,
                warFeedPosition = cfg.warFeedPosition,
            },
            locales = uiLocales,
            gangs = _gangs,
            tributeZones = _tributeZones,
            wars = data.wars,
            turfWars = data.turfWars,
        },
    })
    initialized = true
    lib.print.info('initialized')
end)

AddEventHandler('rm_gangs:client:playerUnloaded', function()
    initialized = nil
    playerGang = nil
    playerData = nil
    SendNUIMessage({
        action = 'unload',
    })
end)

RegisterNUICallback('setOnGPS', function(data, cb)
    cb(1)
    SetNewWaypoint(data.x, data.y)
end)

RegisterNetEvent('rm_gangs:client:openInterface', function()
    while not initialized do Wait(10) end

    local coord = GetEntityCoords(cache.ped)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = {
            player = {
                name = playerData.name,
                citizenId = playerData.citizenId,
                serverId = cache.serverId,
                coord = vec2(coord.x, coord.y),
                gang = playerGang,
            },
        },
    })
    nuiOpened = true
end)

RegisterNUICallback('nuiClosed', function(_, cb)
    cb(1)
    SetNuiFocus(false, false)
    nuiOpened = false
end)

local killed, deathCooldown = false, (cfg.deathCooldown or 30) * 1000
AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= 'CEventNetworkEntityDamage' then return end
    local victim, attacker, victimDied = data[1], data[2], data[4]
    if not IsPedAPlayer(attacker) or NetworkGetPlayerIndexFromPed(victim) ~= cache.playerId then return end
    if killed then return end
    if victimDied and IsPedDeadOrDying(victim, true) then
        Wait(500)
        TriggerServerEvent('rm_gangs:server:onPlayerDead', GetPlayerServerId(NetworkGetPlayerIndexFromPed(attacker)))

        killed = true
        SetTimeout(deathCooldown, function()
            killed = nil
        end)
    end
end)
