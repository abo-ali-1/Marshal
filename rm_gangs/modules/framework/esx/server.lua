if cfg.framework == 'auto' then
    if not GetResourceState('es_extended'):find('start') then
        return
    end
elseif cfg.framework ~= 'esx' then
    return
end

local ESX = exports['es_extended']:getSharedObject()
fwGangs = nil

function isPlayerAlive(playerId)
    return not Player(playerId).state.isDead
end

function notify(playerId, text, type)
    TriggerClientEvent('rm_gangs:client:notify', playerId, text, type)
end

function getPlayerName(playerId)
    local player = ESX.GetPlayerFromId(playerId)
    return player.name
end

local gangsCfg = lib.load('modules.framework.esx.gangs')

if gangsCfg.useJobsAsGangs then
    local fwJobs, jobsLoaded = {}

    function getPlayerGang(playerId)
        while not jobsLoaded do Wait(10) end

        local player = ESX.GetPlayerFromId(playerId)
        if not player then return end

        return {
            name = player.job.name,
            label = player.job.label,
            grade = {
                name = player.job.grade_label,
                level = player.job.grade,
                isboss = fwJobs[player.job.name].grades[player.job.grade].isboss,
            },
            isboss = fwJobs[player.job.name].grades[player.job.grade].isboss,
        }
    end

    function setPlayerGang(playerId, gangName, grade)
        if not grade then
            grade = 0
        end
        if not fwJobs[gangName] or not fwJobs[gangName].grades[grade] then
            gangName = 'unemployed'
        end

        local player = ESX.GetPlayerFromId(playerId)
        player.setJob(gangName, grade)
        return true
    end

    CreateThread(function()
        local _jobs = MySQL.rawExecute.await('SELECT name, label FROM jobs')
        for i = 1, #_jobs do
            fwJobs[_jobs[i].name] = {
                label = _jobs[i].label,
                _grades = {},
                grades = {},
            }
        end
        local _jobGrades = MySQL.rawExecute.await('SELECT job_name, grade, label FROM job_grades')
        for i = 1, #_jobGrades do
            if fwJobs[_jobGrades[i].job_name] then
                table.insert(fwJobs[_jobGrades[i].job_name]._grades, { grade = _jobGrades[i].grade, label = _jobGrades[i].label })
            end
        end

        for name, data in pairs(fwJobs) do
            table.sort(data._grades, function(a, b) return a.grade < b.grade end)
            for i = 1, #data._grades do
                fwJobs[name].grades[data._grades[i].grade] = {
                    name = data._grades[i].label,
                    isboss = i == #data._grades and true or false,
                }
            end
            fwJobs[name]._grades = nil
        end

        fwGangs = fwJobs
        jobsLoaded = true
    end)

    lib.callback.register('rm_gangs:server:getESXJobs', function()
        while not jobsLoaded do Wait(10) end
        return fwJobs
    end)

    AddEventHandler('onResourceStart', function(resourceName)
        if resourceName == cache.resource then
            while not jobsLoaded do Wait(10) end

            SetTimeout(1000, function()
                local players = ESX.GetExtendedPlayers()
                for i = 1, #players do
                    local player = players[i]

                    TriggerEvent('rm_gangs:playerLoaded', player.source, {
                        gang = {
                            name = player.job.name,
                            grade = player.job.grade_label,
                            gradelevel = player.job.grade,
                            isboss = fwJobs[player.job.name].grades[player.job.grade].isboss,
                        },
                        player = {
                            name = player.name,
                        },
                    })
                end
            end)
        end
    end)

    AddEventHandler('esx:playerLoaded', function(playerId, player)
        while not jobsLoaded do Wait(10) end

        TriggerEvent('rm_gangs:playerLoaded', playerId, {
            gang = {
                name = player.job.name,
                grade = player.job.grade_label,
                gradelevel = player.job.grade,
                isboss = fwJobs[player.job.name].grades[player.job.grade].isboss,
            },
            player = {
                name = player.name,
            },
        })
    end)

    function getOnlineGangMembers(filter)
        local members = {}
        local players = ESX.GetExtendedPlayers()
        for i = 1, #players do
            local player = players[i]
            if filter and filter == player.job.name or cfg.gangs[player.job.name] then
                members[#members + 1] = player.source
            end
        end
        return members
    end
else
    fwGangs = gangsCfg.gangs

    function setPlayerGang(playerId, gangName, grade)
        if not grade then
            grade = 0
        end
        if not fwGangs[gangName] or not fwGangs[gangName].grades[grade] then
            gangName = 'none'
        end

        local targetGangData = fwGangs[gangName]
        local targetGangGradeData = targetGangData.grades[grade]

        local player = ESX.GetPlayerFromId(playerId)
        local playerGang = {
            name = gangName,
            label = targetGangData.label,
            grade = {
                name = targetGangGradeData.name,
                level = grade,
                isboss = targetGangGradeData.isboss,
            },
            isboss = targetGangGradeData.isboss,
        }
        player.set('rm_gang', playerGang)
        TriggerClientEvent('rm_gangs:client:setGangOnESX', playerId, playerGang)

        MySQL.prepare('INSERT INTO rm_gangs_esx_players (identifier, name, grade) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), grade = VALUES(grade)', { player.identifier, gangName, grade })

        return playerGang
    end

    function getPlayerGang(playerId)
        local player = ESX.GetPlayerFromId(playerId)
        if not player then return end

        local playerGang = player.get('rm_gang')

        if not playerGang or not fwGangs[playerGang.name] or not fwGangs[playerGang.name].grades[playerGang.grade.level] then
            return setPlayerGang(playerId)
        end

        return playerGang
    end

    AddEventHandler('onServerResourceStart', function(resourceName)
        if resourceName == cache.resource then
            local success, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM rm_gangs_esx_players')
            if not success then
                lib.print.error('To use the built-in gangs system for esx, you need to execute rm_gangs/modules/esx/esx_gangs.sql in your database.')
                StopResource(cache.resource)
            end

            SetTimeout(1000, function()
                local players = ESX.GetExtendedPlayers()
                for i = 1, #players do
                    local player = players[i]

                    local result = MySQL.prepare.await('SELECT * FROM rm_gangs_esx_players WHERE identifier = ? LIMIT 1', { player.identifier })
                    local name = result and result.name
                    local grade = result and result.grade
                    local playerGang = setPlayerGang(player.source, name, grade)

                    TriggerEvent('rm_gangs:playerLoaded', player.source, {
                        gang = {
                            name = playerGang.name,
                            grade = playerGang.grade.name,
                            gradelevel = playerGang.grade.level,
                            isboss = playerGang.isboss,
                        },
                        player = {
                            name = player.name,
                        },
                    })
                end
            end)
        end
    end)

    AddEventHandler('esx:playerLoaded', function(playerId, player)
        local result = MySQL.prepare.await('SELECT * FROM rm_gangs_esx_players WHERE identifier = ? LIMIT 1', { player.identifier })
        local name = result and result.name
        local grade = result and result.grade
        local playerGang = setPlayerGang(player.source, name, grade)

        TriggerEvent('rm_gangs:playerLoaded', playerId, {
            gang = {
                name = playerGang.name,
                grade = playerGang.grade.name,
                gradelevel = playerGang.grade.level,
                isboss = playerGang.isboss,
            },
            player = {
                name = player.name,
            },
        })
    end)

    function getOnlineGangMembers(filter)
        local members = {}
        local players = ESX.GetExtendedPlayers()
        for i = 1, #players do
            local player = players[i]
            local playerGang = getPlayerGang(player.source)

            if filter and filter == playerGang.name or cfg.gangs[playerGang.name] then
                members[#members + 1] = player.source
            end
        end
        return members
    end

    local function isAllowedForSetGangCommand(identifiers)
        for i = 1, #identifiers do
            if cfg.adminList[identifiers[i]] then
                return true
            end
        end

        return false
    end

    if cfg.commands.setgang then
        lib.addCommand(cfg.commands.setgang, {
            help = locale('commands.setgang.help'),
            params = {
                { name = 'id', help = locale('commands.setgang.params.id'), type = 'playerId' },
                { name = 'gang', help = locale('commands.setgang.params.gang'), type = 'string' },
                { name = 'grade', help = locale('commands.setgang.params.grade'), type = 'number', optional = true },
            },
        }, function(source, args, raw)
            local identifiers = GetPlayerIdentifiers(source)
            if IsPlayerAceAllowed(source, 'command') or isAllowedForSetGangCommand(identifiers) then
                local playerId = args['id']
                local player = ESX.GetPlayerFromId(playerId)
                if not player then return notify(source, locale('target_not_online'), 'error') end

                local grade = args['grade'] or 0
                local playerGang = setPlayerGang(playerId, args['gang'], grade)

                notify(source, locale('setgang_result', playerId, playerGang.label, playerGang.grade.level, playerGang.grade.name), 'info')
            end
        end)
    end
end

AddEventHandler('esx:playerDropped', function(playerId)
    TriggerClientEvent('rm_gangs:client:playerUnloaded', playerId)
end)

function getPlayerIdentifier(playerId)
    local player = ESX.GetPlayerFromId(playerId)
    return player.identifier
end

function getMoney(playerId)
    local player = ESX.GetPlayerFromId(playerId)
    return player.getMoney()
end

function addMoney(playerId, amount)
    local player = ESX.GetPlayerFromId(playerId)
    player.addMoney(amount, 'gang system')
    return true
end

function removeMoney(playerId, amount)
    local player = ESX.GetPlayerFromId(playerId)
    if player.getMoney() >= amount then
        player.removeMoney(amount, 'gang system')
        return true
    else
        return false
    end
end
