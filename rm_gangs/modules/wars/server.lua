wars = {}
local activeWars = {}

MySQL.ready(function()
    MySQL.query.await('DELETE FROM rm_gangs_wars WHERE declareDate < (NOW() - INTERVAL 1 MONTH)')

    local results = MySQL.query.await('SELECT * FROM rm_gangs_wars')
    for i = 1, #results do
        local idx = #wars + 1
        wars[idx] = results[i]

        if wars[idx].acceptRejectDate == 0 then
            wars[idx].acceptRejectDate = nil
        end

        if wars[idx].accepted then
            if wars[idx].accepted == 1 then
                wars[idx].accepted = true
            else
                wars[idx].accepted = false
            end

            if wars[idx].surrendered == 0 then
                wars[idx].surrendered = nil
            end

            if wars[idx].finishDate == 0 then
                wars[idx].finishDate = nil
            end

            if not results[i].finishDate then
                if not activeWars[results[i].initiator] then activeWars[results[i].initiator] = {} end
                if not activeWars[results[i].target] then activeWars[results[i].target] = {} end

                activeWars[results[i].initiator][results[i].target] = idx
                activeWars[results[i].target][results[i].initiator] = idx
            end
        elseif wars[idx].cancelled and wars[idx].cancelled == 1 then
            wars[idx].cancelled = true
        end
    end
end)

RegisterNetEvent('rm_gangs:server:onPlayerDead', function(attackerId)
    local playerId = source
    local playerGang = getPlayerGang(playerId)
    local attackerGang = getPlayerGang(attackerId)
    if not playerGang?.name or not attackerGang?.name then return end

    local warIdx = activeWars[playerGang.name] and activeWars[playerGang.name][attackerGang.name]
    if not warIdx then
        return
    end

    local war = wars[warIdx]
    if not war then
        lib.print.warn(('war index %s does not exist wars table'):format(warIdx))
        return
    end

    if war.initiator == attackerGang.name then
        war.initiatorScore += 1
    elseif war.target == attackerGang.name then
        war.targetScore += 1
    end

    if war.initiatorScore >= war.killGoal or war.targetScore >= war.killGoal then
        local currentTimestamp = os.time() * 1000
        war.finishDate = currentTimestamp

        activeWars[war.initiator][war.target] = nil
        activeWars[war.target][war.initiator] = nil

        local affectedLoyalty, winnerSide = (cfg.warLoyaltyPerKill * war.killGoal)
        if war.initiatorScore > war.targetScore then
            winnerSide = 'initiator'
            addMoneyToGang(war.initiator, war.wager * 2)

            gangs[war.initiator].loyalty += affectedLoyalty
            gangs[war.target].loyalty -= affectedLoyalty
        elseif war.targetScore >= war.initiatorScore then
            winnerSide = 'target'
            addMoneyToGang(war.target, war.wager * 2)

            gangs[war.initiator].loyalty -= affectedLoyalty
            gangs[war.target].loyalty += affectedLoyalty
        end

        MySQL.prepare('UPDATE rm_gangs_wars SET initiatorScore = ?, targetScore = ?, finishDate = FROM_UNIXTIME(?) WHERE id = ?', {
            war.initiatorScore, war.targetScore, currentTimestamp / 1000, war.id,
        })

        MySQL.prepare('UPDATE rm_gangs_main SET loyalty = ? WHERE name = ?', {
            gangs[war.initiator].loyalty, war.initiator,
        })
        MySQL.prepare('UPDATE rm_gangs_main SET loyalty = ? WHERE name = ?', {
            gangs[war.target].loyalty, war.target,
        })

        local eventData = {
            id = war.id,
            initiatorName = war.initiator,
            initiatorLabel = gangs[war.initiator].label,
            initiatorIdentifier = war.initiatorIdentifier,
            initiatorScore = war.initiatorScore,
            initiatorNewLoyalty = gangs[war.initiator].loyalty,
            targetName = war.target,
            targetLabel = gangs[war.target].label,
            targetIdentifier = war.targetIdentifier,
            targetScore = war.targetScore,
            targetNewLoyalty = gangs[war.target].loyalty,
            killGoal = war.killGoal,
            wager = war.wager,
            declareDate = war.declareDate,
            acceptRejectDate = war.acceptRejectDate,
            accepted = war.accepted,
            finishDate = war.finishDate,
        }

        TriggerEvent('rm_gangs:server:onWarFinished', eventData)
        TriggerClientEvent('rm_gangs:client:onWarFinished', -1, eventData)
    else
        MySQL.prepare('UPDATE rm_gangs_wars SET initiatorScore = ?, targetScore = ? WHERE id = ?', {
            war.initiatorScore, war.targetScore, war.id,
        })

        local feedData = {
            initiator = war.initiator,
            target = war.target,
            initiatorScore = war.initiatorScore,
            targetScore = war.targetScore,
            highlightedSide = war.initiator == attackerGang.name and 'initiator' or 'target',
        }
        TriggerClientEvent('rm_gangs:client:warFeed', playerId, feedData)
        TriggerClientEvent('rm_gangs:client:warFeed', attackerId, feedData)

        TriggerClientEvent('rm_gangs:client:updateWar', -1, war)
    end
end)

RegisterNetEvent('rm_gangs:server:surrenderInWar', function(data)
    local playerId = source
    local playerGang = getPlayerGang(playerId)
    if not playerGang?.name then return end

    for i = #wars, 1, -1 do
        if wars[i].id == data.id then
            local war = wars[i]
            local currentTimestamp = os.time() * 1000
            war.finishDate = currentTimestamp

            local affectedLoyalty, surrendered = (cfg.warLoyaltyPerKill * war.killGoal)
            if war.initiator == playerGang.name then
                surrendered = 1

                addMoneyToGang(war.target, war.wager * 2)

                gangs[war.initiator].loyalty -= affectedLoyalty
                gangs[war.target].loyalty += affectedLoyalty
            elseif war.target == playerGang.name then
                surrendered = 2

                addMoneyToGang(war.initiator, war.wager * 2)

                gangs[war.initiator].loyalty += affectedLoyalty
                gangs[war.target].loyalty -= affectedLoyalty
            else
                break
            end

            activeWars[war.initiator][war.target] = nil
            activeWars[war.target][war.initiator] = nil

            MySQL.prepare('UPDATE rm_gangs_wars SET initiatorScore = ?, targetScore = ?, surrendered = ?, finishDate = FROM_UNIXTIME(?) WHERE id = ?', {
                war.initiatorScore, war.targetScore, surrendered, currentTimestamp / 1000, war.id,
            })

            MySQL.prepare('UPDATE rm_gangs_main SET loyalty = ? WHERE name = ?', {
                gangs[war.initiator].loyalty, war.initiator,
            })
            MySQL.prepare('UPDATE rm_gangs_main SET loyalty = ? WHERE name = ?', {
                gangs[war.target].loyalty, war.target,
            })

            local eventData = {
                id = war.id,
                initiatorName = war.initiator,
                initiatorLabel = gangs[war.initiator].label,
                initiatorIdentifier = war.initiatorIdentifier,
                initiatorScore = war.initiatorScore,
                initiatorNewLoyalty = gangs[war.initiator].loyalty,
                targetName = war.target,
                targetLabel = gangs[war.target].label,
                targetIdentifier = war.targetIdentifier,
                targetScore = war.targetScore,
                targetNewLoyalty = gangs[war.target].loyalty,
                killGoal = war.killGoal,
                wager = war.wager,
                declareDate = war.declareDate,
                acceptRejectDate = war.acceptRejectDate,
                accepted = war.accepted,
                surrendered = surrendered,
                finishDate = war.finishDate,
            }

            TriggerEvent('rm_gangs:server:onWarFinished', eventData)
            TriggerClientEvent('rm_gangs:client:onWarFinished', -1, eventData)

            break
        end
    end
end)

RegisterNetEvent('rm_gangs:server:declareWar', function(data)
    local playerId = source
    local playerGang = getPlayerGang(playerId)

    if not gangs[playerGang.name] or not gangs[data.target] then return end
    if activeWars[playerGang.name] and activeWars[playerGang.name][data.target] then return notify(playerId, locale('alreay_at_war'), 'error') end

    if removeMoneyFromGang(playerGang.name, data.wager) then
        local identifier = getPlayerIdentifier(playerId)
        local currentTimestamp = os.time() * 1000
        local idx = #wars + 1
        wars[idx] = {
            initiator = playerGang.name,
            target = data.target,
            initiatorIdentifier = identifier,
            initiatorScore = 0,
            targetScore = 0,
            killGoal = data.killGoal,
            wager = data.wager,
            declareDate = currentTimestamp,
        }
        wars[idx].id = MySQL.insert.await('INSERT INTO rm_gangs_wars (initiator, target, initiatorIdentifier, killGoal, wager, declareDate) VALUES (?, ?, ?, ?, ?, FROM_UNIXTIME(?))', {
            playerGang.name, data.target, identifier, data.killGoal, data.wager, currentTimestamp / 1000,
        })

        TriggerClientEvent('rm_gangs:client:declareWar', -1, wars[idx])
    else
        notify(playerId, locale('gang_doesnt_afford_wager'), 'error')
    end
end)

RegisterNetEvent('rm_gangs:server:replyToWarRequest', function(data)
    local playerId = source
    for i = #wars, 1, -1 do
        if wars[i].id == data.id then
            local war = wars[i]
            if data.answer then
                if not removeMoneyFromGang(war.target, war.wager) then
                    return notify(playerId, locale('gang_doesnt_afford_wager'), 'error')
                end

                if not activeWars[war.initiator] then activeWars[war.initiator] = {} end
                if not activeWars[war.target] then activeWars[war.target] = {} end
                activeWars[war.initiator][war.target] = war.id
                activeWars[war.target][war.initiator] = war.id
            else
                activeWars[war.initiator][war.target] = nil
                activeWars[war.target][war.initiator] = nil

                addMoneyToGang(war.initiator, war.wager)
            end

            local identifier = getPlayerIdentifier(playerId)
            local currentTimestamp = os.time() * 1000
            war.acceptRejectDate = currentTimestamp
            war.accepted = data.answer
            war.initiatorScore = 0
            war.targetScore = 0
            war.targetIdentifier = identifier

            MySQL.prepare('UPDATE rm_gangs_wars SET accepted = ?, targetIdentifier = ?, acceptRejectDate = FROM_UNIXTIME(?) WHERE id = ?', {
                data.answer == true and 1 or 0, identifier, currentTimestamp / 1000, war.id,
            })

            local eventData = {
                id = war.id,
                initiatorName = war.initiator,
                initiatorLabel = gangs[war.initiator].label,
                initiatorIdentifier = war.initiatorIdentifier,
                initiatorScore = 0,
                targetName = war.target,
                targetLabel = gangs[war.target].label,
                targetIdentifier = war.targetIdentifier,
                targetScore = 0,
                killGoal = war.killGoal,
                wager = war.wager,
                accepted = war.accepted,
                declareDate = war.declareDate,
                acceptRejectDate = war.acceptRejectDate,
            }

            TriggerEvent('rm_gangs:server:onWarReplied', eventData)
            TriggerClientEvent('rm_gangs:client:onWarReplied', -1, eventData)

            break
        end
    end
end)

RegisterNetEvent('rm_gangs:server:cancelWarRequest', function(data)
    local playerId = source
    for i = #wars, 1, -1 do
        if wars[i].id == data.id then
            local war = wars[i]
            addMoneyToGang(war.initiator, war.wager)

            local currentTimestamp = os.time() * 1000
            war.acceptRejectDate = currentTimestamp
            war.cancelled = true

            MySQL.prepare('UPDATE rm_gangs_wars SET cancelled = ?, acceptRejectDate = FROM_UNIXTIME(?) WHERE id = ?', {
                1, currentTimestamp / 1000, war.id,
            })

            local eventData = {
                id = war.id,
                initiatorName = war.initiator,
                initiatorLabel = gangs[war.initiator].label,
                initiatorIdentifier = war.initiatorIdentifier,
                targetName = war.target,
                targetLabel = gangs[war.target].label,
                killGoal = war.killGoal,
                wager = war.wager,
                declareDate = war.declareDate,
                acceptRejectDate = war.acceptRejectDate,
                cancelled = war.cancelled,
            }

            TriggerEvent('rm_gangs:server:onWarRequestCancelled', eventData)
            TriggerClientEvent('rm_gangs:client:onWarRequestCancelled', -1, eventData)

            break
        end
    end
end)
