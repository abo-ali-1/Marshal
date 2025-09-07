if cfg.framework == 'auto' then
    if not GetResourceState('qb-core'):find('start') then
        return
    end
elseif cfg.framework ~= 'qb' then
    return
end

local QBCore = exports['qb-core']:GetCoreObject()
fwGangs = QBCore.Shared.Gangs

SetTimeout(500, function()
    local _, firstGang = next(fwGangs)
    local gradeIndex = next(firstGang and firstGang.grades or {})

    if type(gradeIndex) == 'string' then
        for name, gangData in pairs(fwGangs) do
            local grades = {}

            for gradeLevel, gradeData in pairs(gangData.grades) do
                local numIndex = math.tointeger(tonumber(gradeLevel))
                if numIndex then
                    grades[numIndex] = gradeData
                end
            end

            fwGangs[name].grades = grades
        end
    end
end)

function isPlayerAlive(playerId)
    local player = QBCore.Functions.GetPlayer(playerId)
    -- return not player.PlayerData.metadata.inlaststand and not player.PlayerData.metadata.isdead
    return not player.PlayerData.metadata.inlaststand
end

function notify(playerId, text, type)
    TriggerClientEvent('rm_gangs:client:notify', playerId, text, type)
end

function getPlayerName(playerId)
    local player = QBCore.Functions.GetPlayer(playerId)
    return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == cache.resource then
        SetTimeout(1000, function()
            local players = QBCore.Functions.GetQBPlayers()
            for _, player in pairs(players) do
                TriggerEvent('rm_gangs:playerLoaded', player.PlayerData.source, {
                    gang = {
                        name = player.PlayerData.gang.name,
                        grade = player.PlayerData.gang.grade.name,
                        gradelevel = player.PlayerData.gang.grade.level,
                        isboss = player.PlayerData.gang.isboss,
                    },
                    player = {
                        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                        citizenId = player.PlayerData.citizenid,
                    },
                })
            end
        end)
    end
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    TriggerEvent('rm_gangs:playerLoaded', player.PlayerData.source, {
        gang = {
            name = player.PlayerData.gang.name,
            grade = player.PlayerData.gang.grade.name,
            gradelevel = player.PlayerData.gang.grade.level,
            isboss = player.PlayerData.gang.isboss,
        },
        player = {
            name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
            citizenId = player.PlayerData.citizenid,
        },
    })
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(playerId)
    TriggerClientEvent('rm_gangs:client:playerUnloaded', playerId)
end)

function getPlayerIdentifier(playerId)
    local player = QBCore.Functions.GetPlayer(playerId)
    return player.PlayerData.citizenid
end

function getOnlineGangMembers(filter)
    local members = {}
    local players = QBCore.Functions.GetQBPlayers()
    for _, player in pairs(players) do
        if filter then
            if filter == player.PlayerData.gang.name then
                members[#members + 1] = player.PlayerData.source
            end
        elseif cfg.gangs[player.PlayerData.gang.name] then
            members[#members + 1] = player.PlayerData.source
        end
    end
    return members
end

function getPlayerGang(playerId)
    local player = QBCore.Functions.GetPlayer(playerId)
    if not player then return end
    return player.PlayerData.gang
end

function setPlayerGang(playerId, gangName, grade)
    if not grade then
        grade = 0
    end
    if not fwGangs[gangName] or not fwGangs[gangName].grades[grade] then
        gangName = 'none'
    end

    local player = QBCore.Functions.GetPlayer(playerId)
    return player.Functions.SetGang(gangName, grade)
end

function getMoney(playerId)
    local player = QBCore.Functions.GetPlayer(playerId)
    return player.Functions.GetMoney('cash')
end

function addMoney(playerId, amount)
    local player = QBCore.Functions.GetPlayer(playerId)
    return player.Functions.AddMoney('cash', amount, 'gang system')
end

function removeMoney(playerId, amount)
    local player = QBCore.Functions.GetPlayer(playerId)
    return player.Functions.RemoveMoney('cash', amount, 'gang system')
end
