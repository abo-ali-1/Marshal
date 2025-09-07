if cfg.inventory == 'auto' then
    -- qs-inventory fxmanifest has “provide ‘ox_inventory’” for some reason?
    if not GetResourceState('ox_inventory'):find('start') or GetResourceState('qs-inventory'):find('start') then
        return
    end
elseif cfg.inventory ~= 'ox_inventory' then
    return
end

if not IsDuplicityVersion() then
    function openStash(name)
        exports.ox_inventory:openInventory('stash', 'gang_' .. name)
    end
else
    function registerStash(name, label)
        exports.ox_inventory:RegisterStash('gang_' .. name, label .. ' Storage', 100, 4000000, false)
    end
end
