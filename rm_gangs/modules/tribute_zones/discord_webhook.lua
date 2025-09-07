-- Discord Webhook Utility for Tribute Zones
-- This module handles Discord notifications and role mentions

local function sendDiscordWebhook(title, description, color, mentionText)
    if not cfg.discord or not cfg.discord.enabled or not cfg.discord.webhook then
        return
    end
    
    if cfg.discord.webhook == 'YOUR_DISCORD_WEBHOOK_URL_HERE' then
        lib.print.warn('Discord webhook URL not configured properly')
        return
    end
    
    local embed = {
        {
            title = title,
            description = description,
            color = color or cfg.discord.embedColor,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer = {
                text = "Gang Wars System",
                icon_url = "https://i.imgur.com/fKEFLuJ.png"
            }
        }
    }
    
    local payload = {
        username = cfg.discord.botName,
        embeds = embed
    }
    
    -- Add role mention if specified
    if mentionText then
        payload.content = mentionText
    end
    
    PerformHttpRequest(cfg.discord.webhook, function(errorCode, resultData, resultHeaders, errorData)
        if errorCode ~= 200 then
            lib.print.error('Discord webhook failed with error code: ' .. errorCode)
            if errorData then
                lib.print.error('Error data: ' .. errorData)
            end
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

-- Function to send tribute zone attack notification
function sendTributeZoneAttackNotification(zoneName, zoneLabel, oldOwner)
    if not cfg.discord.enabled then return end
    
    local title = "🚨 TRIBUTE ZONE UNDER ATTACK! 🚨"
    local description = string.format("**%s** is now under attack!\n\n", zoneLabel)
    
    if oldOwner and gangs[oldOwner] then
        description = description .. string.format("Previous Owner: **%s**\n", gangs[oldOwner].label)
    else
        description = description .. "Previous Owner: **Neutral**\n"
    end
    
    description = description .. string.format("Zone: **%s**", zoneLabel)
    
    local mentionText = ""
    if oldOwner and cfg.discord.tributeRoleMentions[oldOwner] then
        mentionText = cfg.discord.tributeRoleMentions[oldOwner] .. " Your zone is under attack!"
    end
    
    sendDiscordWebhook(title, description, 15158332, mentionText) -- Red color
end

-- Function to send tribute zone captured notification
function sendTributeZoneCapturedNotification(zoneName, zoneLabel, newOwner, oldOwner)
    if not cfg.discord.enabled then return end
    
    local title = "🏰 TRIBUTE ZONE CAPTURED! 🏰"
    local description = ""
    
    if newOwner and gangs[newOwner] then
        description = string.format("**%s** has captured **%s**!\n\n", gangs[newOwner].label, zoneLabel)
        description = description .. string.format("New Owner: **%s**\n", gangs[newOwner].label)
    else
        description = string.format("**%s** is now neutral!\n\n", zoneLabel)
        description = description .. "New Owner: **Neutral**\n"
    end
    
    if oldOwner and gangs[oldOwner] then
        description = description .. string.format("Previous Owner: **%s**\n", gangs[oldOwner].label)
    else
        description = description .. "Previous Owner: **Neutral**\n"
    end
    
    description = description .. string.format("Zone: **%s**", zoneLabel)
    
    local mentionText = ""
    if newOwner and cfg.discord.tributeRoleMentions[newOwner] then
        mentionText = cfg.discord.tributeRoleMentions[newOwner] .. " Your gang captured a zone!"
    elseif oldOwner and cfg.discord.tributeRoleMentions[oldOwner] then
        mentionText = cfg.discord.tributeRoleMentions[oldOwner] .. " Your zone was lost!"
    end
    
    sendDiscordWebhook(title, description, 3066993, mentionText) -- Green color
end

-- Function to send manual tribute zone start notification
function sendManualTributeStartNotification(zoneName, zoneLabel, adminName)
    if not cfg.discord.enabled then return end
    
    local title = "⚔️ TRIBUTE ZONE MANUALLY STARTED ⚔️"
    local description = string.format("Admin **%s** manually started tribute zone event for **%s**", adminName, zoneLabel)
    
    sendDiscordWebhook(title, description, 15105570) -- Orange color
end

-- Function to send scheduled tribute zone notification
function sendScheduledTributeNotification(zoneName, zoneLabel)
    if not cfg.discord.enabled then return end
    
    local title = "⏰ SCHEDULED TRIBUTE ZONE ACTIVE ⏰"
    local description = string.format("Scheduled tribute zone event has started for **%s**", zoneLabel)
    
    sendDiscordWebhook(title, description, 3447003) -- Blue color
end

-- Export functions
exports('sendTributeZoneAttackNotification', sendTributeZoneAttackNotification)
exports('sendTributeZoneCapturedNotification', sendTributeZoneCapturedNotification)
exports('sendManualTributeStartNotification', sendManualTributeStartNotification)
exports('sendScheduledTributeNotification', sendScheduledTributeNotification)
