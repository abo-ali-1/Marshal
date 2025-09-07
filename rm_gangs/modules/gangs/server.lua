initialized = nil
gangs = {}

CreateThread(function()
    while not fwGangs do Wait(100) end

    for name, data in pairs(cfg.gangs) do
        local gangData = fwGangs[name]
        if gangData then
            gangs[name] = data
            gangs[name].label = gangData.label

            MySQL.prepare.await('INSERT IGNORE INTO rm_gangs_main (name) VALUES (?)', { name })

            if data.locations.stash then
                if registerStash then
                    registerStash(name, data.label)
                else
                    gangs[name].locations.stash = nil
                end
            end
        else
            lib.print.info(name .. ' not found, being passed.')
        end
    end

    local results = MySQL.query.await('SELECT * FROM rm_gangs_main')
    for i = 1, #results do
        if gangs[results[i].name] then
            gangs[results[i].name].logoURL = results[i].logoURL
            gangs[results[i].name].loyalty = results[i].loyalty
            gangs[results[i].name].money = 0

            if results[i].money then
                gangs[results[i].name].money = results[i].money
            end
        else
            MySQL.prepare('DELETE FROM rm_gangs_main WHERE name = ?', { results[i].name })
        end
    end

    initialized = true
end)

RegisterServerEvent('rm_gangs:server:updateLogoURL', function(url)
    local playerId = source
    local playerGang = getPlayerGang(playerId)
    if playerGang.isboss then
        gangs[playerGang.name].logoURL = url
        MySQL.prepare.await('UPDATE rm_gangs_main SET logoURL = ? WHERE name = ?', {
            url, playerGang.name,
        })

        TriggerClientEvent('rm_gangs:client:updateLogoURL', -1, {
            gangName = playerGang.name,
            url = url,
        })
    end
end)

function setGangMoney(gangName, amount)
    if not gangs[gangName] then return end

    local oldAmount = gangs[gangName].money
    gangs[gangName].money = amount

    MySQL.prepare('UPDATE rm_gangs_main SET money = ? WHERE name = ?', { gangs[gangName].money, gangName })

    local data = {
        oldAmount = oldAmount,
        newAmount = gangs[gangName].money,
        gangName = gangName,
    }
    TriggerEvent('rm_gangs:server:onGangMoneySet', data)
    TriggerClientEvent('rm_gangs:client:onGangMoneySet', -1, data)

    return true
end

function addMoneyToGang(gangName, amount)
    if not gangs[gangName] then return end

    local oldAmount = gangs[gangName].money
    gangs[gangName].money += amount

    MySQL.prepare('UPDATE rm_gangs_main SET money = ? WHERE name = ?', { gangs[gangName].money, gangName })

    local data = {
        oldAmount = oldAmount,
        newAmount = gangs[gangName].money,
        gangName = gangName,
    }
    TriggerEvent('rm_gangs:server:onGangMoneyAdded', data)
    TriggerClientEvent('rm_gangs:client:onGangMoneyAdded', -1, data)

    return true
end

function removeMoneyFromGang(gangName, amount)
    if not gangs[gangName] then return end

    if gangs[gangName].money >= amount then
        local oldAmount = gangs[gangName].money
        gangs[gangName].money -= amount

        MySQL.prepare('UPDATE rm_gangs_main SET money = ? WHERE name = ?', { gangs[gangName].money, gangName })

        local data = {
            oldAmount = oldAmount,
            newAmount = gangs[gangName].money,
            gangName = gangName,
        }
        TriggerEvent('rm_gangs:server:onGangMoneyRemoved', data)
        TriggerClientEvent('rm_gangs:client:onGangMoneyRemoved', -1, data)

        return true
    else
        return false
    end
end

if cfg.commands.gang then
    lib.addCommand(cfg.commands.gang, {
        help = locale('commands.gang.help'),
    }, function(source, args, raw)
        local playerGang = getPlayerGang(source)
        notify(source, ('%s - [%s]%s.'):format(playerGang.label, playerGang.grade.level, playerGang.grade.name), 'info')
    end)
end

local function isAllowedForGangMoneyCommands(identifiers)
    for i = 1, #identifiers do
        if cfg.adminList[identifiers[i]] then
            return true
        end
    end

    return false
end

if cfg.commands.addgangmoney then
    lib.addCommand(cfg.commands.addgangmoney, {
        help = locale('commands.addgangmoney.help'),
        params = {
            { name = 'gang', help = locale('commands.addgangmoney.params.gang'), type = 'string' },
            { name = 'amount', help = locale('commands.addgangmoney.params.amount'), type = 'number' },
        },
    }, function(source, args, raw)
        local identifiers = GetPlayerIdentifiers(source)
        if IsPlayerAceAllowed(source, 'command') or isAllowedForGangMoneyCommands(identifiers) then
            if addMoneyToGang(args['gang'], args['amount']) then
                notify(source, locale('addgangmoney_result', locale('ui.$'), args['amount'], gangs[args['gang']].label), 'info')
            end
        end
    end)
end

if cfg.commands.setgangmoney then
    lib.addCommand(cfg.commands.setgangmoney, {
        help = locale('commands.setgangmoney.help'),
        params = {
            { name = 'gang', help = locale('commands.setgangmoney.params.gang'), type = 'string' },
            { name = 'amount', help = locale('commands.setgangmoney.params.amount'), type = 'number' },
        },
    }, function(source, args, raw)
        local identifiers = GetPlayerIdentifiers(source)
        if IsPlayerAceAllowed(source, 'command') or isAllowedForGangMoneyCommands(identifiers) then
            if setGangMoney(args['gang'], args['amount']) then
                notify(source, locale('setgangmoney_result', gangs[args['gang']].label, locale('ui.$'), args['amount']), 'info')
            end
        end
    end)
end

exports('getGangs', function()
    while not initialized do Wait(10) end

    return gangs
end)

exports('addLoyalty', function(gangName, amount)
    if not gangs[gangName] then
        return lib.print.error('no gang named ' .. gangName .. ' was found!')
    end

    gangs[gangName].loyalty += amount
    MySQL.update('UPDATE rm_gangs_main SET loyalty = ? WHERE name = ?', {
        gangs[gangName].loyalty,
        gangName,
    })

    TriggerClientEvent('rm_gangs:client:updateLoyalty', -1, {
        gangName = gangName,
        newPoint = gangs[gangName].loyalty,
    })
end)

exports('removeLoyalty', function(gangName, amount)
    if not gangs[gangName] then
        return lib.print.error('no gang named ' .. gangName .. ' was found!')
    end

    gangs[gangName].loyalty -= amount
    MySQL.update('UPDATE rm_gangs_main SET loyalty = ? WHERE name = ?', {
        gangs[gangName].loyalty,
        gangName,
    })

    TriggerClientEvent('rm_gangs:client:updateLoyalty', -1, {
        gangName = gangName,
        newPoint = gangs[gangName].loyalty,
    })
end)
