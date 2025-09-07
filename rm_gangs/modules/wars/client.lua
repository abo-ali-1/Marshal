RegisterNUICallback('declareWar', function(data, cb)
    cb(1)
    TriggerServerEvent('rm_gangs:server:declareWar', data)
end)

RegisterNUICallback('replyToWarRequest', function(data, cb)
    cb(1)
    TriggerServerEvent('rm_gangs:server:replyToWarRequest', data)
end)

RegisterNUICallback('cancelWarRequest', function(data, cb)
    cb(1)
    TriggerServerEvent('rm_gangs:server:cancelWarRequest', data)
end)

RegisterNUICallback('surrenderInWar', function(data, cb)
    cb(1)
    TriggerServerEvent('rm_gangs:server:surrenderInWar', data)
end)

RegisterNetEvent('rm_gangs:client:declareWar', function(data)
    SendNUIMessage({
        action = 'update',
        data = {
            war = data,
        },
    })
end)

RegisterNetEvent('rm_gangs:client:onWarReplied', function(data)
    SendNUIMessage({
        action = 'update',
        data = {
            war = {
                id = data.id,
                initiator = data.initiatorName,
                initiatorIdentifier = data.initiatorIdentifier,
                target = data.targetName,
                targetIdentifier = data.targetIdentifier,
                initiatorScore = 0,
                targetScore = 0,
                killGoal = data.killGoal,
                wager = data.wager,
                declareDate = data.declareDate,
                acceptRejectDate = data.acceptRejectDate,
                accepted = data.accepted,
            },
        },
    })
end)

RegisterNetEvent('rm_gangs:client:onWarRequestCancelled', function(data)
    SendNUIMessage({
        action = 'update',
        data = {
            war = {
                id = data.id,
                initiator = data.initiatorName,
                initiatorIdentifier = data.initiatorIdentifier,
                target = data.targetName,
                initiatorScore = 0,
                targetScore = 0,
                killGoal = data.killGoal,
                wager = data.wager,
                declareDate = data.declareDate,
                acceptRejectDate = data.acceptRejectDate,
                cancelled = data.cancelled,
            },
        },
    })
end)

RegisterNetEvent('rm_gangs:client:updateWar', function(data)
    SendNUIMessage({
        action = 'update',
        data = {
            war = data,
        },
    })
end)

RegisterNetEvent('rm_gangs:client:onWarFinished', function(data)
    SendNUIMessage({
        action = 'update',
        data = {
            war = {
                id = data.id,
                initiator = data.initiatorName,
                initiatorIdentifier = data.initiatorIdentifier,
                initiatorScore = data.initiatorScore,
                target = data.targetName,
                targetIdentifier = data.targetIdentifier,
                targetScore = data.targetScore,
                killGoal = data.killGoal,
                wager = data.wager,
                declareDate = data.declareDate,
                acceptRejectDate = data.acceptRejectDate,
                accepted = data.accepted,
                surrendered = data.surrendered,
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

    if data.surrendered or data.finishDate then
        if data.initiatorName == playerGang.name or data.targetName == playerGang.name then
            local winnerSide
            if data.surrendered == 1 then
                winnerSide = 'target'
            elseif data.surrendered == 2 then
                winnerSide = 'initiator'
            elseif data.initiatorScore > data.targetScore then
                winnerSide = 'initiator'
            elseif data.targetScore >= data.initiatorScore then
                winnerSide = 'target'
            end

            SendNUIMessage({
                action = 'warFeed',
                data = {
                    initiator = data.initiatorName,
                    target = data.targetName,
                    initiatorScore = data.initiatorScore,
                    targetScore = data.targetScore,
                    finished = true,
                    highlightedSide = winnerSide,
                },
            })
        end
    end
end)

RegisterNetEvent('rm_gangs:client:warFeed', function(feed)
    SendNUIMessage({
        action = 'warFeed',
        data = feed,
    })
end)
