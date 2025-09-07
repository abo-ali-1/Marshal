if cfg.framework == 'auto' then
    if not GetResourceState('es_extended'):find('start') then
        return
    end
elseif cfg.framework ~= 'esx' then
    return
end

local ESX = exports['es_extended']:getSharedObject()
fwGangs = nil

local gangsCfg = lib.load('modules.framework.esx.gangs')

if gangsCfg.useJobsAsGangs then
    local jobs = {}

    lib.callback('rm_gangs:server:getESXJobs', false, function(data)
        jobs = data
        fwGangs = data
    end)

    RegisterNetEvent('esx:setJob', function(job)
        playerGang = {
            name = job.name,
            grade = job.grade_label,
            gradelevel = job.grade,
            isboss = jobs[job.name].grades[job.grade].isboss,
        }
        TriggerEvent('rm_gangs:playerGangUpdate')
    end)
else
    -- local gangs = gangsCfg.gangs
    fwGangs = gangsCfg.gangs

    RegisterNetEvent('rm_gangs:client:setGangOnESX', function(gang)
        playerGang = {
            name = gang.name,
            grade = gang.grade.name,
            gradelevel = gang.grade.level,
            isboss = gang.isboss,
        }
        TriggerEvent('rm_gangs:playerGangUpdate')
    end)
end
function notify(text, type)
    if nuiOpened then
        SendNUIMessage({
            action = 'notify',
            data = {
                text = text,
                type = type,
            },
        })
    elseif GetResourceState('esx_notify') ~= 'missing' then
        return exports['esx_notify']:Notify(type, 3000, text)
    else
        lib.notify({
            description = text,
            type = type,
        })
    end
end

RegisterNetEvent('rm_gangs:client:notify', function(text, type)
    notify(text, type)
end)
