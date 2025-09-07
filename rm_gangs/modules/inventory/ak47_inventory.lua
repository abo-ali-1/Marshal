if cfg.inventory == 'auto' then
    if not GetResourceState('ak47_qb_inventory'):find('start') and not GetResourceState('ak47_inventory'):find('start') then
        return
    end
elseif cfg.inventory ~= 'ak47_inventory' then
    return
end

if not IsDuplicityVersion() then
    function openStash(name)
        exports.ak47_inventory:OpenInventory('gang_' .. name)
    end
else
    function registerStash(name, label)
        exports.origen_inventory:CreateInventory('gang_' .. name, {
            label = label .. ' Storage',
            slots = 10,
            weight = 100,
        })
    end
end
