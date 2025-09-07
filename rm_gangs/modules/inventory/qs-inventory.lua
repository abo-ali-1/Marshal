if cfg.inventory == 'auto' then
    if not GetResourceState('qs-inventory'):find('start') then
        return
    end
elseif cfg.inventory ~= 'qs-inventory' then
    return
end

if not IsDuplicityVersion() then
    function openStash(name)
        local other = {}
        other.maxweight = 10000 -- Custom weight statsh
        other.slots = 50        -- Custom slots spaces
        TriggerServerEvent('inventory:server:OpenInventory', 'stash', 'Gang_' .. name, other)
        TriggerEvent('inventory:client:SetCurrentStash', 'Gang_' .. name)
    end
else
    function registerStash(name, label)
        --
    end
end
