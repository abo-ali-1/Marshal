tributeZones = {}

AddEventHandler('rm_gangs:client:playerLoaded', function(_data)
    for name, data in pairs(_data.tributeZones) do
        tributeZones[name] = {
            name = name,
            label = data.label,
            territory = data.territory,
            paymentAmount = data.paymentAmount,
            captureTimerLabel = data.captureTimerLabel,
            owner = data.owner,
            captureDate = data.captureDate,
            paymentResetTime = data.paymentResetTime,
            _captureEventData = data._captureEventData,
        }
        lib.requestModel(data.npc.model)
        tributeZones[name].npc = CreatePed(0, data.npc.model, data.npc.coord.x, data.npc.coord.y, data.npc.coord.z - 0.96, data.npc.coord.w, false, true)
        SetEntityInvincible(tributeZones[name].npc, true)
        FreezeEntityPosition(tributeZones[name].npc, true)
        SetBlockingOfNonTemporaryEvents(tributeZones[name].npc, true)
        SetEntityInvincible(tributeZones[name].npc, true)
        TaskStartScenarioInPlace(tributeZones[name].npc, 'WORLD_HUMAN_AA_COFFEE', 0, true)
        SetModelAsNoLongerNeeded(data.npc.model)

        addLocalEntity(tributeZones[name].npc, {
            label = locale('collect_tribute'),
            distance = 1.5,
            icon = 'fa-solid fa-hand-holding-dollar',
            canInteract = function()
                if not playerGang or tributeZones[name].owner ~= playerGang.name then return false end
                return true
            end,
            onSelect = function()
                TriggerServerEvent('rm_gangs:server:getTributePayment', name)
            end,
        })

        local zoneData = table.clone(data.territory)
        zoneData.onEnter = function()
            currentZone = { type = 'tributeZone', name = name }
            SendNUIMessage({
                action = 'locationInfo',
                data = currentZone,
            })
            if _data.gangs[playerGang.name] then
                if tributeZones[name]._captureEventData then
                    SendNUIMessage({
                        action = 'tributeEventScoreboard',
                        data = tributeZones[name]._captureEventData,
                    })
                end
            end
        end
        zoneData.onExit = function()
            currentZone = nil
            SendNUIMessage({
                action = 'locationInfo',
                data = nil,
            })
            SendNUIMessage({
                action = 'tributeEventScoreboard',
                data = nil,
            })
        end
        zoneData.debug = cfg.debug or zoneData.debug
        tributeZones[name].zone = lib.zones.poly(zoneData)
    end
end)

AddEventHandler('rm_gangs:client:playerUnloaded', function()
    for name, data in pairs(tributeZones) do
        DeleteEntity(tributeZones[name].npc)
        if data.zone then
            data.zone:remove()
        end
    end
    tributeZones = {}
end)

RegisterNetEvent('rm_gangs:client:updateTribute', function(data)
    if not data.name or not tributeZones[data.name] then return end

    SendNUIMessage({
        action = 'update',
        data = {
            tributeZone = data,
        },
    })
end)

RegisterNetEvent('rm_gangs:client:onTributeEventStarted', function(data)
    if not data.name or not tributeZones[data.name] then return end

    tributeZones[data.name].owner = nil
    SendNUIMessage({
        action = 'update',
        data = {
            tributeZone = {
                name = data.name,
                owner = nil,
            },
        },
    })

    local _captureEventData = {
        finishDate = data.finishDate,
        points = {},
        zoneLabel = data.label,
    }
    tributeZones[data.name]._captureEventData = _captureEventData
    if gangs[playerGang.name] then
        if currentZone?.type == 'tributeZone' and currentZone?.name == data.name then
            SendNUIMessage({
                action = 'tributeEventScoreboard',
                data = _captureEventData,
            })
        end
    end
end)

RegisterNetEvent('rm_gangs:client:updateCaptureEvent', function(zoneName, data)
    if not zoneName or not tributeZones[zoneName] then return end

    tributeZones[zoneName]._captureEventData = data
    if gangs[playerGang.name] then
        if currentZone?.type == 'tributeZone' and currentZone?.name == zoneName then
            SendNUIMessage({
                action = 'tributeEventScoreboard',
                data = data,
            })
        end
    end
end)

RegisterNetEvent('rm_gangs:client:onTributeEventFinished', function(data)
    if not data.name or not tributeZones[data.name] then return end

    tributeZones[data.name].owner = data.ownerName
    if data.ownerName and data.captureDate then
        SendNUIMessage({
            action = 'update',
            data = {
                tributeZone = {
                    name = data.name,
                    owner = data.ownerName,
                    captureDate = data.captureDate,
                },
            },
        })
    end

    tributeZones[data.name]._captureEventData = nil
    if currentZone?.type == 'tributeZone' and currentZone?.name == data.name then
        SendNUIMessage({
            action = 'tributeEventScoreboard',
            data = nil,
        })
    end
end)

RegisterNetEvent('rm_gangs:client:openManuelTributeStartMenu', function(data)
    local zoneOptions = {}
    for i = 1, #data do
        zoneOptions[#zoneOptions + 1] = {
            value = data[i].name,
            label = data[i].label .. ' | ' .. locale('ui.$') .. data[i].paymentAmount .. ' ' .. (data[i].started and '| ' .. locale('already_started') or ''),
        }
    end
    local input = lib.inputDialog(locale('choose_a_tribute_zone'), {
        { type = 'select', label = locale('zones'), description = locale('tribute_manuel_warning'), options = zoneOptions, clearable = true },
    })

    if input and input[1] then
        TriggerServerEvent('rm_gangs:server:manuelTributeStart', input[1])
    end
end)

exports('getCurrentTributeZone', function()
    if currentZone and currentZone.type == 'tributeZone' and tributeZones[currentZone.name] then
        local name = currentZone.name
        local data = tributeZones[name]
        return {
            name = name,
            label = data.label,
            paymentAmount = data.paymentAmount,
            territory = data.territory,
            owner = data.owner,
            captureDate = data.captureDate,
            captureTimerLabel = data.captureTimerLabel,
            paymentResetTime = data.paymentResetTime,
        }
    else
        return nil
    end
end)
