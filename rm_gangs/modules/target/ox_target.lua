if cfg.target == 'auto' then
    if not GetResourceState('ox_target'):find('start') then
        return
    end
elseif cfg.target ~= 'ox_target' then
    return
end

function addLocalEntity(entity, option)
    exports.ox_target:addLocalEntity(entity, option)
end
