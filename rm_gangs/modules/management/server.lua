lib.callback.register('rm_gangs:server:getPlayerNames', function(source, players)
    for i = 1, #players do
        players[i].name = getPlayerName(players[i].serverId)
    end

    return players
end)

lib.callback.register('rm_gangs:server:getMembers', function(source)
    local playerGang = getPlayerGang(source)
    if not gangs[playerGang.name] then return {} end

    local members = getOnlineGangMembers(playerGang.name)

    for i = #members, 1, -1 do
        local targetPlayerGang = getPlayerGang(members[i])
        if targetPlayerGang.name == playerGang.name then
            members[i] = {
                serverId = members[i],
                name = getPlayerName(members[i]),
                grade = targetPlayerGang.grade.level,
            }
        else
            table.remove(members, i)
        end
    end

    return members
end)

lib.callback.register('rm_gangs:server:changeMemberGrade', function(source, targetPlayerId, grade)
    local playerGang = getPlayerGang(source)
    if not gangs[playerGang.name] or not playerGang.isboss or not fwGangs[playerGang.name].grades[grade] then return false end

    return setPlayerGang(targetPlayerId, playerGang.name, grade)
end)

lib.callback.register('rm_gangs:server:recruitNewMembers', function(source, players, grade)
    local playerGang = getPlayerGang(source)
    if not gangs[playerGang.name] or not playerGang.isboss then return false end

    if not fwGangs[playerGang.name].grades[grade] then
        grade = 0
    end

    for i = #players, 1, -1 do
        if not setPlayerGang(players[i], playerGang.name, grade) then
            table.remove(players, i)
        else
            players[i] = {
                serverId = players[i],
                name = getPlayerName(players[i]),
            }
        end
    end

    return true, players, grade
end)

lib.callback.register('rm_gangs:server:kickMember', function(source, targetPlayerId)
    local playerGang = getPlayerGang(source)
    if not gangs[playerGang.name] or not playerGang.isboss then return false end

    return setPlayerGang(targetPlayerId)
end)

lib.callback.register('rm_gangs:server:getMoney', function(source)
    return getMoney(source)
end)

lib.callback.register('rm_gangs:server:withdraw', function(source, amount)
    local playerGang = getPlayerGang(source)
    if not gangs[playerGang.name] or not playerGang.isboss then return false end

    if removeMoneyFromGang(playerGang.name, amount) then
        return addMoney(source, amount)
    else
        return false
    end
end)

lib.callback.register('rm_gangs:server:deposit', function(source, amount)
    local playerGang = getPlayerGang(source)
    if not gangs[playerGang.name] then return false end

    if removeMoney(source, amount) then
        return addMoneyToGang(playerGang.name, amount)
    else
        return false
    end
end)
