RegisterNetEvent('rm_gangs:client:startTurfWar', function()
    if not playerGang then return end

    if not currentZone or currentZone.type ~= 'gang' then
        return notify(locale('need_to_be_in_enemy_territory'), 'error')
    elseif currentZone.name == playerGang.name then
        return notify(locale('cannot_start_turf_again_own_group'), 'error')
    else
        TriggerServerEvent('rm_gangs:server:startTurfWar', currentZone.name)
    end
end)

RegisterNetEvent('rm_gangs:client:onTurfWarStarted', function(data)
    SendNUIMessage({
        action = 'update',
        data = {
            turfWar = {
                id = data.id,
                initiator = data.initiatorName,
                target = data.targetName,
                initiatorPersonCount = 0,
                targetPersonCount = 0,
                declareDate = data.declareDate,
                startDate = data.startDate,
                finishDate = data.finishDate,
            },
        },
    })

    gangs[data.targetName]._turfWarId = data.id
    if currentZone?.type == 'gang' and currentZone?.name == data.targetName then
        SendNUIMessage({
            action = 'turfEventScoreboard',
            data = data.id,
        })
    end
end)

RegisterNetEvent('rm_gangs:client:updateTurfWar', function(targetGang, turfWar)
    SendNUIMessage({
        action = 'update',
        data = {
            turfWar = turfWar,
        },
    })

    gangs[targetGang]._turfWarId = turfWar.id
    if currentZone?.type == 'gang' and currentZone?.name == targetGang then
        SendNUIMessage({
            action = 'turfEventScoreboard',
            data = turfWar.id,
        })
    end
end)

RegisterNetEvent('rm_gangs:client:onTurfWarFinished', function(data)
    SendNUIMessage({
        action = 'update',
        data = {
            turfWar = {
                id = data.id,
                initiator = data.initiatorName,
                target = data.targetName,
                initiatorPersonCount = data.initiatorPersonCount,
                targetPersonCount = data.targetPersonCount,
                successful = data.successful,
                declareDate = data.declareDate,
                startDate = data.startDate,
                finishDate = data.finishDate,
            },
        },
    })

    SendNUIMessage({
        action = 'update',
        data = {
            loyalty = {
                gangName = data.initiatorName,
                newPoint = data.initiatorNewLoyalty,
            },
        },
    })
    SendNUIMessage({
        action = 'update',
        data = {
            loyalty = {
                gangName = data.targetName,
                newPoint = data.targetNewLoyalty,
            },
        },
    })

    gangs[data.targetName]._turfWarId = nil
    if currentZone?.type == 'gang' and currentZone?.name == data.targetName then
        SendNUIMessage({
            action = 'turfEventScoreboard',
            data = nil,
        })
    end
end)
