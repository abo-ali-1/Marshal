if cfg.target == 'auto' then
    if not GetResourceState('qb-target'):find('start') or GetResourceState('ox_target'):find('start') then
        return
    end
elseif cfg.target ~= 'qb-target' then
    return
end

function addLocalEntity(entity, option)
    exports['qb-target']:AddTargetEntity(entity, {
        options = {
            {
                icon = option.icon,
                label = option.label,
                canInteract = option.canInteract,
                action = option.onSelect,
            },
        },
        distance = option.distance,
    })
end
