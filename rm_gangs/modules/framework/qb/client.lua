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

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    playerGang = {
        name = gang.name,
        grade = gang.grade.name,
        gradelevel = gang.grade.level,
        isboss = gang.isboss,
    }
    TriggerEvent('rm_gangs:playerGangUpdate')
end)

function notify(text, type)
    if nuiOpened then
        SendNUIMessage({
            action = 'notify',
            data = {
                text = text,
                type = type,
            },
        })
    else
        if type == 'info' then type = 'primary' end
        QBCore.Functions.Notify(text, type, 5000)
    end
end

RegisterNetEvent('rm_gangs:client:notify', function(text, type)
    notify(text, type)
end)
