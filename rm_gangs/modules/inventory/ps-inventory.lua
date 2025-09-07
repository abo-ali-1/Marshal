if cfg.inventory == 'auto' then
    if not GetResourceState('ps-inventory'):find('start') then
        return
    end
elseif cfg.inventory ~= 'ps-inventory' then
    return
end

if not IsDuplicityVersion() then
    function openStash(name)
        TriggerServerEvent('ps-inventory:server:OpenInventory', 'stash', 'Gang_' .. name)
        TriggerEvent('ps-inventory:client:SetCurrentStash', 'Gang_' .. name)
    end
else
    function registerStash(name, label)
        --
    end
end
