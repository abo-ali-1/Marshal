if cfg.inventory == 'auto' then
    if not GetResourceState('qb-inventory'):find('start') then
        return
    end
elseif cfg.inventory ~= 'qb-inventory' then
    return
end

local version = GetResourceMetadata('qb-inventory', 'version', 0) or '1'
local major = tonumber(version:match('^%d+'))
local isV2 = (major and major >= 2) or false

if not IsDuplicityVersion() then
    function openStash(name)
        if isV2 then
            TriggerServerEvent('rm_gangs:server:openQBV2Stash', name)
        else
            local stashName = 'Gang_' .. name

            TriggerServerEvent('inventory:server:OpenInventory', 'stash', stashName)
            TriggerEvent('inventory:client:SetCurrentStash', stashName)
        end
    end
else
    local stashLabels = {}
    function registerStash(name, label)
        if isV2 then
            stashLabels[name] = label .. ' Storage'
        end
    end

    if isV2 then
        RegisterNetEvent('rm_gangs:server:openQBV2Stash', function(name)
            exports['qb-inventory']:OpenInventory(source, 'Gang_' .. name, { label = stashLabels[name] or 'Storage', maxweight = 4000000, slots = 100 })
        end)
    end
end
