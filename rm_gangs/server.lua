QBCore = exports['qb-core']:GetCoreObject()
Config = Config or {}

-- دالة مساعدة لتحويل "HH:MM" إلى عدد دقائق من بداية اليوم
local function TimeToMinutes(timeStr)
    local hour, min = timeStr:match("^(%d+):(%d+)$")
    return (tonumber(hour) * 60) + tonumber(min)
end

-- دالة تجيب اليوم الحالي كـ string (Sunday, Monday, ...)
local function GetCurrentDay()
    return os.date("%A") -- يرجع مثل "Sunday"
end

-- دالة تجيب الوقت الحالي بالدقائق
local function GetCurrentMinutes()
    local h = tonumber(os.date("%H"))
    local m = tonumber(os.date("%M"))
    return (h * 60) + m
end

-- كومان /starttribute
QBCore.Commands.Add("starttribute", "Start tribute event (check config by time/day)", {}, false, function(source, _)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local currentDay = GetCurrentDay()
    local currentMinutes = GetCurrentMinutes()

    local todayTributes = Config.Tributes[currentDay]
QBCore.Commands.Add("starttribute", "Start tribute event (check config by time/day)", {}, false, function(source, _)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local currentDay = os.date("%A")
    local currentMinutes = (tonumber(os.date("%H")) * 60) + tonumber(os.date("%M"))
    local todayTributes = Config.Tributes[currentDay]

    if not todayTributes then
        TriggerClientEvent('QBCore:Notify', source, "لا يوجد Tributes لليوم: " .. currentDay, "error")
        return
    end

    local selectedArea = nil
    for _, tribute in ipairs(todayTributes) do
        local h, m = tribute.start:match("^(%d+):(%d+)$")
        local tributeMinutes = (tonumber(h) * 60) + tonumber(m)
        if currentMinutes >= tributeMinutes then
            selectedArea = tribute.Area
        end
    end

    if selectedArea then
        -- هذا هو التريقر الصحيح
        TriggerEvent('rm_gangs:server:manuelTributeStart', selectedArea)
        TriggerClientEvent('QBCore:Notify', source, "تم فتح Tribute للمنطقة: " .. selectedArea, "success")
    else
        TriggerClientEvent('QBCore:Notify', source, "مافي أي Tribute مناسب للوقت الحالي", "error")
    end
end)

-- هذا الحدث شكله من سكربتك الأساسي (rm_gangs)، أنا خليته زي ما هو
AddEventHandler('rm_gangs:playerLoaded', function(playerId, data)
    TriggerClientEvent('rm_gangs:client:playerLoaded', playerId, {
        gangs = gangs,
        wars = wars,
        tributeZones = tributeZones,
        turfWars = turfWars,
    }, data)
end)
