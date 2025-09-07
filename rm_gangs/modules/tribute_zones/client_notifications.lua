-- Client-side notifications for tribute zones

-- Register event for big notifications
RegisterNetEvent('rm_gangs:client:showBigNotification', function(message, type, duration)
    duration = duration or 5000
    
    -- Show notification based on type
    if type == 'warning' then
        notify(message, 'warning', duration)
        -- Also show as a big screen notification if available
        if lib.notify then
            lib.notify({
                title = 'Gang Wars',
                description = message,
                type = 'warning',
                duration = duration,
                position = 'top'
            })
        end
    elseif type == 'success' then
        notify(message, 'success', duration)
        if lib.notify then
            lib.notify({
                title = 'Gang Wars',
                description = message,
                type = 'success',
                duration = duration,
                position = 'top'
            })
        end
    elseif type == 'info' then
        notify(message, 'info', duration)
        if lib.notify then
            lib.notify({
                title = 'Gang Wars',
                description = message,
                type = 'info',
                duration = duration,
                position = 'top'
            })
        end
    else
        notify(message, 'info', duration)
    end
    
    -- Also show as a screen effect for tribute zone events
    if message:find('under attack') or message:find('captured') then
        -- Create screen flash effect
        CreateThread(function()
            local flashColor = type == 'warning' and {255, 0, 0, 100} or {0, 255, 0, 100}
            local startTime = GetGameTimer()
            local flashDuration = 1000 -- 1 second flash
            
            while GetGameTimer() - startTime < flashDuration do
                local alpha = math.floor(100 * (1 - (GetGameTimer() - startTime) / flashDuration))
                DrawRect(0.0, 0.0, 1.0, 1.0, flashColor[1], flashColor[2], flashColor[3], alpha)
                Wait(0)
            end
        end)
    end
end)

-- Register event for tribute zone reset notifications
RegisterNetEvent('rm_gangs:client:onTributeZoneReset', function(data)
    if playerGang and playerGang.name == data.oldOwnerName then
        local lossMsg = ('💔 Your gang lost control of %s due to admin reset'):format(data.label)
        notify(lossMsg, 'error', 8000)
    end
    
    -- Update UI
    SendNUIMessage({
        action = 'update',
        data = {
            tributeZoneReset = data
        },
    })
end)

-- Register event for tribute zone capture cancelled
RegisterNetEvent('rm_gangs:client:onTributeEventCancelled', function(zoneName)
    local cancelMsg = ('⚠️ Tribute zone event for %s has been cancelled by admin'):format(
        cfg.tributeZones and cfg.tributeZones[zoneName] and cfg.tributeZones[zoneName].label or zoneName
    )
    notify(cancelMsg, 'warning', 5000)
    
    -- Update UI to hide any ongoing capture interface
    SendNUIMessage({
        action = 'update',
        data = {
            tributeEventCancelled = zoneName
        },
    })
end)
