local territoryOwnership = {}
local conquestState = { active = false }
local currentAttacks = {}
local territoryBlips = {}
local attackBlips = {}

-- Initialize territory ownership on client
AddEventHandler('rm_gangs:client:playerLoaded', function(data, myData)
    if not cfg.territorySystem.enabled then return end
    
    -- Clear existing blips
    clearTerritoryBlips()
    
    -- Update territory ownership data
    territoryOwnership = data.territoryOwnership or {}
    conquestState = data.conquestState or { active = false }
    
    -- Update gang data with territory points
    for name, gangData in pairs(data.gangs) do
        if gangs[name] then
            gangs[name].territory_points = gangData.territory_points or 0
        end
    end
    
    -- Create territory blips
    createTerritoryBlips()
    
    -- Update UI with territory data
    SendNUIMessage({
        action = 'update',
        data = {
            territoryOwnership = territoryOwnership,
            conquestState = conquestState,
            gangs = gangs
        },
    })
end)

-- Create territory blips on map
function createTerritoryBlips()
    if not cfg.territorySystem.enabled then return end
    
    clearTerritoryBlips()
    
    for territoryName, ownership in pairs(territoryOwnership) do
        local territory = cfg.gangs[territoryName]
        if territory and territory.territory and territory.territory.points and #territory.territory.points > 0 then
            -- Calculate center point of territory
            local centerX, centerY = 0, 0
            for _, point in pairs(territory.territory.points) do
                centerX = centerX + point.x
                centerY = centerY + point.y
            end
            centerX = centerX / #territory.territory.points
            centerY = centerY / #territory.territory.points
            
            -- Create blip
            local blip = AddBlipForCoord(centerX, centerY, 0.0)
            
            if ownership.gangName and gangs[ownership.gangName] then
                -- Territory is owned
                local gangData = gangs[ownership.gangName]
                local color = gangData.color and convertHexToBlipColor(gangData.color) or 1
                
                SetBlipSprite(blip, 84) -- Territory sprite
                SetBlipColour(blip, color)
                SetBlipScale(blip, 0.8)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(('%s - %s'):format(territory.label or territoryName, gangData.label))
                EndTextCommandSetBlipName(blip)
                
                if ownership.underAttack then
                    -- Territory under attack - add flashing effect
                    SetBlipFlashes(blip, true)
                    SetBlipFlashTimer(blip, 3000)
                end
            else
                -- Neutral territory
                SetBlipSprite(blip, 84)
                SetBlipColour(blip, 0) -- White
                SetBlipScale(blip, 0.6)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(('%s - Neutral'):format(territory.label or territoryName))
                EndTextCommandSetBlipName(blip)
            end
            
            territoryBlips[territoryName] = blip
        end
    end
end

-- Clear territory blips
function clearTerritoryBlips()
    for _, blip in pairs(territoryBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    territoryBlips = {}
    
    for _, blip in pairs(attackBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    attackBlips = {}
end

-- Convert hex color to blip color (approximate)
function convertHexToBlipColor(hexColor)
    if not hexColor then return 1 end
    
    -- Remove # if present
    hexColor = hexColor:gsub('#', '')
    
    -- Simple color mapping (you can expand this)
    local colorMap = {
        ['71a46d'] = 2,  -- Green (families)
        ['9a76ae'] = 27, -- Purple (ballas)
        ['cb7a79'] = 6,  -- Red (ruff)
        ['7b88c3'] = 3,  -- Blue (bondi)
        ['ffed80'] = 5,  -- Yellow (vagos)
        ['be8657'] = 17, -- Orange (korean)
        ['9f99c0'] = 27  -- Purple (lostmc)
    }
    
    return colorMap[hexColor:lower()] or 1
end

-- Handle territory attack start
RegisterNetEvent('rm_gangs:client:onTerritoryAttackStarted', function(data)
    currentAttacks[data.territoryName] = data
    
    -- Update blip for attacking territory
    if territoryBlips[data.territoryName] then
        SetBlipFlashes(territoryBlips[data.territoryName], true)
        SetBlipFlashTimer(territoryBlips[data.territoryName], 5000)
    end
    
    -- Show notification
    if cfg.showEventNotificationsToEveryone or (playerGang and (playerGang.name == data.attackingGang or playerGang.name == data.defendingGang)) then
        local message = ('%s is attacking %s!'):format(data.attackingGangLabel, data.territoryLabel)
        notify(message, 'warning')
    end
    
    -- Update UI
    SendNUIMessage({
        action = 'update',
        data = {
            territoryAttack = data
        },
    })
    
    -- If player is in the territory, show attack scoreboard
    if currentZone and currentZone.type == 'gang' and currentZone.name == data.territoryName then
        SendNUIMessage({
            action = 'territoryAttackScoreboard',
            data = data,
        })
    end
end)

-- Handle territory attack updates
RegisterNetEvent('rm_gangs:client:updateTerritoryAttack', function(progressData)
    currentAttacks[progressData.territoryName] = progressData
    
    -- Update UI
    SendNUIMessage({
        action = 'update',
        data = {
            territoryAttackProgress = progressData
        },
    })
    
    -- If player is in the territory, update attack scoreboard
    if currentZone and currentZone.type == 'gang' and currentZone.name == progressData.territoryName then
        SendNUIMessage({
            action = 'updateTerritoryAttackScoreboard',
            data = progressData,
        })
    end
end)

-- Handle territory attack finished
RegisterNetEvent('rm_gangs:client:onTerritoryAttackFinished', function(data)
    currentAttacks[data.territoryName] = nil
    
    -- Update blip
    if territoryBlips[data.territoryName] then
        SetBlipFlashes(territoryBlips[data.territoryName], false)
    end
    
    -- Show notification
    local message
    if data.successful then
        message = ('%s successfully captured %s!'):format(data.attackingGangLabel, data.territoryLabel)
    else
        message = ('%s successfully defended %s!'):format(data.defendingGangLabel, data.territoryLabel)
    end
    
    if cfg.showEventNotificationsToEveryone or (playerGang and (playerGang.name == data.attackingGang or playerGang.name == data.defendingGang)) then
        notify(message, data.successful and 'success' or 'info')
    end
    
    -- Update UI
    SendNUIMessage({
        action = 'update',
        data = {
            territoryAttackResult = data
        },
    })
    
    -- Hide attack scoreboard if player was in the territory
    if currentZone and currentZone.type == 'gang' and currentZone.name == data.territoryName then
        SendNUIMessage({
            action = 'territoryAttackScoreboard',
            data = nil,
        })
    end
end)

-- Handle territory claimed
RegisterNetEvent('rm_gangs:client:onTerritoryClaimed', function(data)
    -- Update local ownership data
    territoryOwnership[data.territoryName] = {
        gangName = data.newOwner,
        captureDate = os.date('%Y-%m-%d %H:%M:%S'),
        underAttack = false
    }
    
    -- Update gang territory points
    if gangs[data.newOwner] then
        gangs[data.newOwner].territory_points = (gangs[data.newOwner].territory_points or 0) + cfg.territorySystem.pointsPerTerritory
    end
    
    if data.oldOwner and gangs[data.oldOwner] then
        gangs[data.oldOwner].territory_points = math.max(0, (gangs[data.oldOwner].territory_points or 0) - cfg.territorySystem.pointsPerTerritory)
    end
    
    -- Update blips
    createTerritoryBlips()
    
    -- Show notification
    local message = ('%s claimed %s!'):format(data.newOwnerLabel, data.territoryLabel)
    if cfg.showEventNotificationsToEveryone or (playerGang and (playerGang.name == data.newOwner or playerGang.name == data.oldOwner)) then
        notify(message, 'success')
    end
    
    -- Update UI
    SendNUIMessage({
        action = 'update',
        data = {
            territoryOwnership = territoryOwnership,
            gangs = gangs,
            territoryClaimed = data
        },
    })
end)

-- Handle conquest period start
RegisterNetEvent('rm_gangs:client:onConquestStarted', function(data)
    conquestState = {
        active = true,
        startTime = data.startTime,
        endTime = data.endTime,
        territories = data.territories
    }
    
    -- Show big notification
    notify('🏰 CONQUEST PERIOD STARTED! All territories can now be attacked!', 'warning', 10000)
    
    -- Update blips to show conquest is active
    createTerritoryBlips()
    
    -- Update UI
    SendNUIMessage({
        action = 'update',
        data = {
            conquestState = conquestState,
            conquestStarted = data
        },
    })
end)

-- Handle conquest period end
RegisterNetEvent('rm_gangs:client:onConquestEnded', function(data)
    conquestState = { active = false }
    
    -- Show notification
    notify('🏰 Conquest period ended!', 'info', 5000)
    
    -- Update blips
    createTerritoryBlips()
    
    -- Update UI
    SendNUIMessage({
        action = 'update',
        data = {
            conquestState = conquestState,
            conquestEnded = data
        },
    })
end)

-- Handle territory points update
RegisterNetEvent('rm_gangs:client:updateTerritoryPoints', function(gangData)
    for gangName, data in pairs(gangData) do
        if gangs[gangName] then
            gangs[gangName].territory_points = data.territory_points or 0
        end
    end
    
    -- Update UI
    SendNUIMessage({
        action = 'update',
        data = {
            gangs = gangs
        },
    })
end)

-- Command to start territory attack
RegisterNetEvent('rm_gangs:client:startTerritoryAttack', function()
    if not playerGang then
        return notify('You must be in a gang to attack territories', 'error')
    end
    
    if not currentZone or currentZone.type ~= 'gang' then
        return notify('You must be in a territory to attack it', 'error')
    end
    
    if currentZone.name == playerGang.name then
        return notify('You cannot attack your own territory', 'error')
    end
    
    TriggerServerEvent('rm_gangs:server:startTerritoryAttack', currentZone.name, playerGang.name)
end)

-- Register attack command
if lib.context == 'client' then
    RegisterCommand('attackterritory', function()
        TriggerEvent('rm_gangs:client:startTerritoryAttack')
    end)
end

-- Override gang zone enter/exit to include territory ownership info
local originalGangZoneEnter = function() end
local originalGangZoneExit = function() end

-- Modify gang zones to show territory ownership
AddEventHandler('rm_gangs:client:playerLoaded', function(data, myData)
    -- Override gang zone behavior to include territory ownership
    for name, gangData in pairs(data.gangs) do
        if gangs[name] and gangs[name].zone then
            -- Store original functions if needed
            local zone = gangs[name].zone
            local originalOnEnter = zone.onEnter
            local originalOnExit = zone.onExit
            
            zone.onEnter = function()
                currentZone = { type = 'gang', name = name }
                
                -- Get territory ownership info
                local ownership = territoryOwnership[name]
                local ownerInfo = ''
                local attackInfo = ''
                
                if ownership then
                    if ownership.gangName and gangs[ownership.gangName] then
                        ownerInfo = ('\\nOwned by: %s'):format(gangs[ownership.gangName].label)
                    else
                        ownerInfo = '\\nOwned by: Neutral'
                    end
                    
                    if ownership.underAttack and currentAttacks[name] then
                        local attack = currentAttacks[name]
                        local timeRemaining = math.max(0, (attack.endTime - (os.time() * 1000)) / 1000 / 60)
                        attackInfo = ('\\n🔥 UNDER ATTACK! %d min remaining'):format(math.ceil(timeRemaining))
                    end
                end
                
                local conquestInfo = ''
                if conquestState.active then
                    conquestInfo = '\\n⚔️ CONQUEST PERIOD ACTIVE'
                end
                
                SendNUIMessage({
                    action = 'locationInfo',
                    data = {
                        type = 'gang',
                        name = name,
                        label = gangData.label .. ownerInfo .. attackInfo .. conquestInfo
                    },
                })
                
                -- Show territory attack scoreboard if territory is under attack
                if ownership and ownership.underAttack and currentAttacks[name] then
                    SendNUIMessage({
                        action = 'territoryAttackScoreboard',
                        data = currentAttacks[name],
                    })
                end
                
                -- Call original function if it exists
                if originalOnEnter then originalOnEnter() end
            end
            
            zone.onExit = function()
                currentZone = nil
                SendNUIMessage({
                    action = 'locationInfo',
                    data = nil,
                })
                SendNUIMessage({
                    action = 'territoryAttackScoreboard',
                    data = nil,
                })
                
                -- Call original function if it exists
                if originalOnExit then originalOnExit() end
            end
        end
    end
end)

-- Clean up on unload
AddEventHandler('rm_gangs:client:playerUnloaded', function()
    clearTerritoryBlips()
    territoryOwnership = {}
    conquestState = { active = false }
    currentAttacks = {}
end)

-- Export functions
exports('getTerritoryOwnership', function() return territoryOwnership end)
exports('getConquestState', function() return conquestState end)
exports('getCurrentAttacks', function() return currentAttacks end)
