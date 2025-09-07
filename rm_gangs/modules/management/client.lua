function editMemberMenu(member)
    if not gangs[playerGang.name] then return end

    local options = {
        {
            title = ('[%s] %s'):format(member.serverId, member.name),
            description = ('[%s]%s'):format(member.grade, fwGangs[playerGang.name].grades[member.grade].name),
            icon = 'fa-solid fa-user-large',
            readOnly = true,
        },
        {
            title = locale('change_grade'),
            icon = 'fa-solid fa-people-arrows',
            onSelect = function()
                local gradeOptions = {}

                for level, data in pairs(fwGangs[playerGang.name].grades) do
                    if level < playerGang.gradelevel then
                        gradeOptions[#gradeOptions + 1] = {
                            label = ('[%s] %s'):format(level, data.name),
                            value = level,
                        }
                    end
                end

                table.sort(gradeOptions, function(a, b) return a.value < b.value end)

                local inputs = {
                    {
                        type = 'select',
                        label = locale('new_grade'),
                        options = gradeOptions,
                        required = true,
                        default = fwGangs[playerGang.name].grades[member.grade] and member.grade or 0,
                    },
                }

                local input = lib.inputDialog(locale('recruit_new_member'), inputs)
                if not input then
                    editMemberMenu(member)
                    return
                end

                local grade = input[1]
                local success = lib.callback.await('rm_gangs:server:changeMemberGrade', false, member.serverId, grade)
                if success then
                    notify(locale('change_grade_successful', member.name, grade, fwGangs[playerGang.name].grades[grade].name))
                end

                editMemberMenu(member)
            end,
        },
        {
            title = locale('kick'),
            icon = 'fa-solid fa-person-burst',
            onSelect = function()
                local result = lib.alertDialog({
                    header = locale('kick_confirm_header'),
                    content = ('[%s] %s'):format(member.serverId, member.name) .. '  \n ' .. locale('kick_confirm_content', gangs[playerGang.name].label),
                    centered = true,
                    cancel = true,
                })

                if not result or result == 'cancel' then
                    editMemberMenu(member)
                    return
                end

                local success = lib.callback.await('rm_gangs:server:kickMember', false, member.serverId)
                if success then
                    notify(locale('kick_successful', member.name, gangs[playerGang.name].label), 'info')
                end

                memberListMenu()
            end,
        },
    }

    lib.registerContext({
        id = 'rm_gangs_management_edit_member',
        title = locale('edit_member'),
        options = options,
        menu = 'rm_gangs_management_members',
    })
    lib.showContext('rm_gangs_management_edit_member')
end

function memberListMenu()
    if not gangs[playerGang.name] then return end

    local options = {}
    local members = lib.callback.await('rm_gangs:server:getMembers')

    table.sort(members, function(a, b) return a.grade > b.grade end)

    for i = 1, #members do
        local member = members[i]
        options[#options + 1] = {
            title = ('[%s] %s'):format(member.serverId, member.name),
            description = ('[%s]%s'):format(member.grade, fwGangs[playerGang.name].grades[member.grade].name),
            icon = 'fa-solid fa-user-pen',
            disabled = member.serverId == cache.serverId or member.grade >= playerGang.gradelevel,
            onSelect = function()
                editMemberMenu(member)
            end,
        }
    end

    lib.registerContext({
        id = 'rm_gangs_management_member_list',
        title = locale('online_members'),
        options = options,
        menu = 'rm_gangs_management_members',
    })
    lib.showContext('rm_gangs_management_member_list')
end

function openMembersMenu()
    if not gangs[playerGang.name] then return end

    local options = {
        {
            title = locale('recruit_new_member'),
            icon = 'fa-solid fa-person-walking-arrow-right',
            onSelect = function()
                local inputs = {}
                local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 5.0, false)

                if #nearbyPlayers > 0 then
                    for i = 1, #nearbyPlayers do
                        nearbyPlayers[i] = {
                            serverId = GetPlayerServerId(nearbyPlayers[i].id),
                        }
                    end

                    local nearbyPlayers = lib.callback.await('rm_gangs:server:getPlayerNames', false, nearbyPlayers)

                    local playerOptions = {}
                    for i = 1, #nearbyPlayers do
                        playerOptions[#playerOptions + 1] = {
                            label = ('[%s] %s'):format(nearbyPlayers[i].serverId, nearbyPlayers[i].name),
                            value = nearbyPlayers[i].serverId,
                        }
                    end

                    inputs[#inputs + 1] = {
                        type = 'multi-select',
                        label = locale('nearby_people'),
                        description = locale('nearby_people_desc'),
                        options = playerOptions,
                        clearable = true,
                    }
                end

                inputs[#inputs + 1] = {
                    type = 'number',
                    label = locale('serverid'),
                    description = locale('serverid_want_to_recruit_desc'),
                    min = 1,
                }

                local gradeOptions = {}
                for level, data in pairs(fwGangs[playerGang.name].grades) do
                    if level < playerGang.gradelevel then
                        gradeOptions[#gradeOptions + 1] = {
                            label = ('[%s] %s'):format(level, data.name),
                            value = level,
                        }
                    end
                end

                table.sort(gradeOptions, function(a, b) return a.value < b.value end)

                inputs[#inputs + 1] = {
                    type = 'select',
                    label = locale('grade'),
                    description = locale('grade_desc'),
                    options = gradeOptions,
                    required = true,
                    default = 0,
                }

                local input = lib.inputDialog(locale('recruit_new_member'), inputs)
                if not input then
                    openMembersMenu()
                    return
                end

                local selectedServerIds = {}
                local selectedGrade = 0

                if type(input[1]) == 'table' then
                    if #input[1] > 0 then
                        selectedServerIds = input[1]
                    elseif type(input[2]) == 'number' then
                        selectedServerIds[1] = input[2]
                    end

                    selectedGrade = input[3]
                elseif type(input[1]) == 'nil' and type(input[2]) == 'number' then
                    selectedServerIds[1] = input[2]
                    selectedGrade = input[3]
                elseif type(input[1]) == 'number' then
                    selectedServerIds[1] = input[1]
                    selectedGrade = input[2]
                end

                local success, players, grade = lib.callback.await('rm_gangs:server:recruitNewMembers', false, selectedServerIds, selectedGrade)
                if success then
                    for i = 1, #players do
                        notify(locale('recruit_successful', players[i].serverId, players[i].name, gangs[playerGang.name].label, grade, fwGangs[playerGang.name].grades[grade].name), 'info')
                    end
                end
            end,
        },
        {
            title = locale('online_members'),
            icon = 'fa-solid fa-people-group',
            onSelect = function()
                memberListMenu()
            end,
        },
    }

    lib.registerContext({
        id = 'rm_gangs_management_members',
        title = locale('member_management'),
        options = options,
        menu = 'rm_gangs_management_main',
    })
    lib.showContext('rm_gangs_management_members')
end

function getAmount(actionType)
    local max = 0
    if actionType == 'deposit' then
        local balance = lib.callback.await('rm_gangs:server:getMoney')
        max = balance or 0
    elseif actionType == 'withdraw' then
        max = gangs[playerGang.name].money
    end

    local input = lib.inputDialog(locale(actionType), {
        { type = 'number', label = locale('amount'), required = true, default = 0, min = 0, max = max },
    })

    if not input or not input[1] then return end

    return input[1]
end

function openMoneyMenu()
    if not gangs[playerGang.name] then return end

    local options = {
        {
            title = locale('management_balance', locale('ui.$'), gangs[playerGang.name].money),
            icon = 'fa-solid fa-sack-dollar',
            readOnly = true,
        },
        {
            title = locale('deposit'),
            icon = 'fa-solid fa-money-bill-transfer',
            onSelect = function()
                local amount = getAmount('deposit')
                if amount and amount > 0 then
                    local status = lib.callback.await('rm_gangs:server:deposit', false, amount)
                    if status then
                        notify(locale('deposit_successful', locale('ui.$'), amount, gangs[playerGang.name].label))
                        Wait(100)
                    else
                        notify(locale('deposit_failed', gangs[playerGang.name].label))
                    end
                end

                openMoneyMenu()
            end,
        },
    }

    if playerGang.isboss then
        options[#options + 1] = {
            title = locale('withdraw'),
            icon = 'fa-solid fa-money-bill-transfer',
            onSelect = function()
                local amount = getAmount('withdraw')
                if amount and amount > 0 then
                    local status = lib.callback.await('rm_gangs:server:withdraw', false, amount)
                    if status then
                        notify(locale('withdraw_successful', locale('ui.$'), amount, gangs[playerGang.name].label))
                        Wait(100)
                    else
                        notify(locale('withdraw_failed', gangs[playerGang.name].label))
                    end
                end

                openMoneyMenu()
            end,
        }
    end

    lib.registerContext({
        id = 'rm_gangs_management_money',
        title = locale('money_management'),
        options = options,
        menu = 'rm_gangs_management_main',
    })
    lib.showContext('rm_gangs_management_money')
end

function openManagementMenu()
    if not gangs[playerGang.name] then return end

    local options = {
        {
            title = locale('money_management'),
            description = playerGang.isboss and ('%s & %s'):format(locale('deposit'), locale('withdraw')) or locale('deposit'),
            icon = 'fa-solid fa-sack-dollar',
            onSelect = function()
                openMoneyMenu()
            end,
        },
    }

    if playerGang.isboss then
        options[#options + 1] = {
            title = locale('member_management'),
            description = locale('member_management_desc'),
            icon = 'fa-solid fa-list',
            onSelect = function()
                openMembersMenu()
            end,
        }
    end

    lib.registerContext({
        id = 'rm_gangs_management_main',
        title = locale('management_main_title', gangs[playerGang.name].label),
        options = options,
    })
    lib.showContext('rm_gangs_management_main')
end
