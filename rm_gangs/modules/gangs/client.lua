gangs = {}
local points, garageHandle = {}

local function unloadPoints()
    for i = 1, #points do
        if points[i] then
            points[i]:remove()
        end
    end
    if removeGarage then
        pcall(function() removeGarage(garageHandle) end)
    end
    garageHandle = nil
end

local function loadPoints(locations, name, label)
    for locationType, coord in pairs(locations) do
        if locationType == 'garage' then
            if registerGarage then
                pcall(function()
                    garageHandle = registerGarage({
                        garageType = 'group',
                        vehicleType = 'land',
                        label = label .. ' Garage',
                        coord = coord,
                        gang = name,
                    })
                end)
            end

            if openGarage then
                local shownTextUI = false
                points[#points + 1] = lib.points.new({
                    coords = coord.xyz,
                    distance = 30,
                    onExit = function()
                        shownTextUI = false
                        lib.hideTextUI()
                    end,
                    nearby = function(self)
                        if self.currentDistance < 1 then
                            if not shownTextUI then
                                shownTextUI = true
                                lib.showTextUI('[E] - ' .. locale(locationType) or locationType:gsub('^%l', string.upper))
                            else
                                if IsControlJustReleased(0, 38) then
                                    lib.hideTextUI()
                                    pcall(function()
                                        openGarage({
                                            garageType = 'group',
                                            vehicleType = 'land',
                                            label = label .. ' Garage',
                                            coord = coord,
                                            gang = name,
                                            vehicle = cache.vehicle,
                                            garageHandle = garageHandle,
                                        })
                                    end)
                                end
                            end
                        elseif shownTextUI then
                            lib.hideTextUI()
                            shownTextUI = false
                        else
                            DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 0.2, 0.2, 0.2, 255, 255, 255, 255, false, true, 2, false)
                        end
                    end,
                })
            end
        else
            local shownTextUI = false
            points[#points + 1] = lib.points.new({
                coords = coord.xyz,
                distance = 3,
                type = locationType,
                onExit = function()
                    shownTextUI = false
                    lib.hideTextUI()
                end,
                nearby = function(self)
                    if self.currentDistance < 1 then
                        if not shownTextUI then
                            shownTextUI = true
                            lib.showTextUI('[E] - ' .. locale(locationType) or locationType:gsub('^%l', string.upper))
                        else
                            if IsControlJustReleased(0, 38) then
                                lib.hideTextUI()
                                if locationType == 'management' and openManagementMenu then
                                    openManagementMenu(name)
                                elseif locationType == 'clothing' and cfg.openClothing then
                                    cfg.openClothing(name)
                                elseif locationType == 'stash' and openStash then
                                    openStash(name)
                                end
                            end
                        end
                    elseif shownTextUI then
                        lib.hideTextUI()
                        shownTextUI = false
                    else
                        DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 0.2, 0.2, 0.2, 255, 255, 255, 255, false, true, 2, false)
                    end
                end,
            })
        end
    end
end

AddEventHandler('rm_gangs:client:playerLoaded', function(_data, myData)
    for name, data in pairs(_data.gangs) do
        gangs[name] = {
            name = name,
            label = data.label,
            money = data.money,
            territory = data.territory,
            locations = data.locations,
            color = data.color,
            logoURL = data.logoURL,
            loyalty = data.loyalty or 0,
            _turfWarId = data._turfWarId,
        }

        local zoneData = table.clone(data.territory)
        zoneData.onEnter = function()
            currentZone = { type = 'gang', name = name }
            SendNUIMessage({
                action = 'locationInfo',
                data = currentZone,
            })
            if _data.gangs[playerGang.name] then
                if gangs[name]._turfWarId then
                    SendNUIMessage({
                        action = 'turfEventScoreboard',
                        data = gangs[name]._turfWarId,
                    })
                end
            end
        end
        zoneData.onExit = function()
            currentZone = nil
            SendNUIMessage({
                action = 'locationInfo',
                data = nil,
            })
            SendNUIMessage({
                action = 'turfEventScoreboard',
                data = nil,
            })
        end
        zoneData.debug = cfg.debug or zoneData.debug
        gangs[name].zone = lib.zones.poly(zoneData)

        if name == myData.gang.name then
            loadPoints(data.locations, name, data.label)
        end
    end
end)

AddEventHandler('rm_gangs:client:playerUnloaded', function()
    unloadPoints()
    for name, data in pairs(gangs) do
        if data.zone then
            data.zone:remove()
        end
    end
    gangs = {}
end)

AddEventHandler('rm_gangs:playerGangUpdate', function()
    unloadPoints()
    SendNUIMessage({
        action = 'update',
        data = {
            playerGang = playerGang,
        },
    })
    if gangs[playerGang.name] then
        loadPoints(gangs[playerGang.name].locations, playerGang.name, gangs[playerGang.name].label)
    end
end)

RegisterNUICallback('updateLogoURL', function(data, cb)
    cb(1)
    TriggerServerEvent('rm_gangs:server:updateLogoURL', data.url)
end)

RegisterNetEvent('rm_gangs:client:updateLogoURL', function(data)
    SendNUIMessage({
        action = 'update',
        data = {
            logoURL = data,
        },
    })
end)

RegisterNetEvent('rm_gangs:client:updateLoyalty', function(loyalty)
    SendNUIMessage({
        action = 'update',
        data = {
            loyalty = loyalty,
        },
    })
end)

RegisterNetEvent('rm_gangs:client:onGangMoneyAdded', function(data)
    if not gangs[data.gangName] then return end
    gangs[data.gangName].money = data.newAmount

    SendNUIMessage({
        action = 'update',
        data = {
            money = {
                gangName = data.gangName,
                amount = data.newAmount,
            },
        },
    })
end)

RegisterNetEvent('rm_gangs:client:onGangMoneyRemoved', function(data)
    if not gangs[data.gangName] then return end
    gangs[data.gangName].money = data.newAmount

    SendNUIMessage({
        action = 'update',
        data = {
            money = {
                gangName = data.gangName,
                amount = data.newAmount,
            },
        },
    })
end)

RegisterNetEvent('rm_gangs:client:onGangMoneySet', function(data)
    if not gangs[data.gangName] then return end
    gangs[data.gangName].money = data.newAmount

    SendNUIMessage({
        action = 'update',
        data = {
            money = {
                gangName = data.gangName,
                amount = data.newAmount,
            },
        },
    })
end)

exports('getCurrentGangZone', function()
    if currentZone and currentZone.type == 'gang' and gangs[currentZone.name] then
        local name = currentZone.name
        local data = gangs[name]
        return {
            name = name,
            label = data.label,
            color = data.color,
            loyalty = data.loyalty,
            territory = data.territory,
            logoURL = data.logoURL,
        }
    else
        return nil
    end
end)

exports('getPlayerGangInfo', function()
    return playerGang
end)
