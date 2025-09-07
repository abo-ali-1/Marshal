if cfg.inventory == 'auto' then
    if not GetResourceState('origen_inventory'):find('start') then
        return
    end
elseif cfg.inventory ~= 'origen_inventory' then
    return
end

if not IsDuplicityVersion() then
    function openStash(name)
        TriggerServerEvent('rm_gangs:server:openStash', name)
        exports.origen_inventory:openInventory('stash', 'gang_' .. name)
    end
else
    function registerStash(name, label)
        exports.origen_inventory:registerStash('gang_' .. name, {
            label = label .. ' Storage',
            slots = 10,
            weight = 100,
        })
    end
end
