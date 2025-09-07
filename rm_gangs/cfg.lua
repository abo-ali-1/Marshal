lib.locale('en')
cfg = {}

cfg.framework = 'qb'         -- 'auto' | 'qb' | 'esx'
cfg.target = 'qb-target'            -- 'auto' | 'ox_target' | 'qb-target'
cfg.inventory = 'qb-inventory'         -- 'auto' | 'ox_inventory' | 'qb-inventory' | 'qs-inventory' | 'origen_inventory' | 'ak47_inventory'

cfg.tributePaymentInterval = 2 -- hours | only values that can divide 24 by a whole number can be entered here
cfg.warLoyaltyPerKill = 10     -- calculated by multiplying the result of the war by the kill goal
cfg.turfWarLoyalty = 500
cfg.turfWarStartDelay = 1      --minutes
cfg.turfWarDuration = 4        --minutes
cfg.turfWarRequiredTargetMemberCount = 1
cfg.tributeZoneLoyalty = 100   -- loyalty points gained/lost when capturing/losing tribute zones
cfg.warMinWager = 0
cfg.warMaxWager = 10000
cfg.warMinKillGoal = 10
cfg.warMaxKillGoal = 1000
cfg.deathCooldown = 30                      --seconds | the time needed to score again from the dead person

cfg.timeAgoLocale = 'en_US'                 --You can see timeago translations via this link https://github.com/hustcc/timeago.js/tree/master/src/lang

cfg.showEventNotificationsToEveryone = true -- false: only visible in gangs
cfg.locationInfoTimer = 4000                -- hiding time of the zone information visible on the right, set to -1 to keep it permanently

-- Discord Webhook Settings
cfg.discord = {
    enabled = true,
    webhook = 'YOUR_DISCORD_WEBHOOK_URL_HERE', -- Replace with your webhook URL
    botName = 'Gang Wars Bot',
    embedColor = 15105570, -- Orange color
    tributeRoleMentions = {
        -- ['gangname'] = '<@&ROLE_ID>', -- Replace with actual role IDs
        -- Example: ['families'] = '<@&123456789012345678>',
    },
}

-- 'top-left' | 'top-center' | 'top-right' | 'center-left' | 'center-center' | 'center-right' | 'bottom-left' | 'bottom-center' | 'bottom-right'
cfg.locationInfoPosition = 'bottom-right'
cfg.notificationPosition = 'bottom-center'
cfg.notificationPositionWhenInterfaceOpened = 'top-left'
cfg.tributeScoreboardPosition = 'center-right'
cfg.turfScoreboardPosition = 'center-right'
cfg.warFeedPosition = 'top-right'

if lib.context == 'client' then
    cfg.openClothing = function(gangName)
        -- TriggerEvent('illenium-apearance:client:outfitsCommand')
        -- TriggerServerEvent('InteractSound_SV:PlayOnSource', 'Clothes1', 0.4)
        TriggerEvent('qb-clothing:client:openOutfitMenu')
        -- TriggerEvent('rcore_clothes:openOutfits')
        -- exports.renzu_clothes:OpenClotheInventory(true)
        -- exports['vms_clothestore']:OpenWardrobe()
        -- TriggerEvent('illenium-appearance:client:openOutfitMenu')
        -- exports.ak47_clothing:openOutfit()
    end

    RegisterCommand('startturfwar', function()
        TriggerEvent('rm_gangs:client:startTurfWar')
    end)

    RegisterCommand('gangmap', function()
        TriggerEvent('rm_gangs:client:openInterface')
    end)
end

cfg.clockFormat = '12' -- 12 - 24

-- check out this link if you want add new gang properly: https://docs.rainmad.com/latest-resources/gangs-territory-wars-tribute-zones/add-gang-and-tribute-zone
cfg.gangs = {
    ['families'] = {
        color = '#71a46d',
        territory = {
            points = {
                vec3(-356.0, -1678.0, 35.0),
                vec3(-287.0, -1556.5, 35.0),
                vec3(-265.0, -1502.0, 35.0),
                vec3(-258.5, -1446.0, 35.0),
                vec3(-240.5, -1447.5, 35.0),
                vec3(-227.0, -1459.0, 35.0),
                vec3(-193.0, -1429.0, 35.0),
                vec3(-113.0, -1382.0, 35.0),
                vec3(102.5, -1383.0, 35.0),
                vec3(121.5, -1409.0, 35.0),
                vec3(-207.4, -1791.0, 35.0),
            },
            thickness = 28.6,
        },
        locations = { -- if you want remove any menu, just comment line example: garage below
            management = vec3(-9.6, -1441.58, 31.1),
            clothing = vec3(-18.3, -1432.19, 31.1),
            stash = vec3(-17.06, -1430.41, 31.1),
            -- garage = vec4(0.0, 0.0, 0.0, 0.0),
        },
    },
    ['ballas'] = {
        color = '#9a76ae',
        territory = {
            points = {
                vec3(-193.0, -1811.0, 30.0),
                vec3(-147.0, -1777.0, 30.0),
                vec3(-92.0, -1747.0, 30.0),
                vec3(-26.0, -1631.0, 30.0),
                vec3(248.0, -1860.0, 30.0),
                vec3(141.0, -1992.0, 30.0),
                vec3(130.0, -2027.0, 30.0),
                vec3(40.0, -2026.0, 30.0),
            },
            thickness = 38.6,
        },
        locations = { -- if you want remove any menu, just comment line example: garage below
            management = vec3(125.07, -1928.8, 21.38),
            clothing = vec3(118.06, -1920.65, 21.32),
            stash = vec3(84.9, -1958.47, 21.12),
            --garage = vec4(0.0, 0.0, 0.0, 0.0),
        },
    },
    ['ruff'] = {
        color = '#cb7a79',
        territory = {
            points = {
                vec3(77.0, -1669.0, 32.0),
                vec3(315.0, -1534.0, 32.0),
                vec3(429.0, -1626.0, 32.0),
                vec3(427.0, -1652.0, 32.0),
                vec3(270.0, -1833.0, 32.0),
            },
            thickness = 38.6,
        },
        locations = { -- if you want remove any menu, just comment line example: garage below
            management = vec3(259.46, -1740.65, 29.66),
            clothing = vec3(266.14, -1739.28, 29.48),
            stash = vec3(254.95, -1742.77, 29.66),
            -- garage = vec4(0.0, 0.0, 0.0, 0.0),
        },
    },
    ['bondi'] = {
        color = '#7b88c3',
        territory = {
            points = {
                vec3(-1613.0, -1144.0, 30.0),
                vec3(-1599.0, -1186.0, 30.0),
                vec3(-1539.0, -1277.0, 30.0),
                vec3(-1484.0, -1444.0, 30.0),
                vec3(-1491.0, -1458.0, 30.0),
                vec3(-1511.0, -1459.0, 30.0),
                vec3(-1483.0, -1508.0, 30.0),
                vec3(-1476.0, -1497.0, 30.0),
                vec3(-1465.0, -1499.0, 30.0),
                vec3(-1236.0, -1872.0, 30.0),
                vec3(-1274.0, -1915.0, 30.0),
                vec3(-1269.0, -1920.0, 30.0),
                vec3(-1015.0, -1665.0, 30.0),
                vec3(-1030.0, -1643.0, 30.0),
                vec3(-1013.0, -1608.0, 30.0),
                vec3(-1015.0, -1586.0, 30.0),
                vec3(-1340.0, -856.0, 30.0),
            },
            thickness = 38.6,
        },
        locations = { -- if you want remove any menu, just comment line example: garage below
            management = vec3(-1165.62, -1567.13, 4.45),
            clothing = vec3(-1157.03, -1569.73, 4.43),
            stash = vec3(-1147.04, -1562.05, 4.4),
            -- garage = vec4(0.0, 0.0, 0.0, 0.0),
        },
    },
    ['vagos'] = {
        color = '#ffed80',
        territory = {
            points = {
                vec3(67.0, -2052.0, 23.0),
                vec3(67.0, -2050.0, 23.0),
                vec3(157.0, -2054.0, 23.0),
                vec3(170.0, -2019.0, 23.0),
                vec3(490.0, -1635.0, 23.0),
                vec3(346.0, -1513.0, 23.0),
                vec3(472.0, -1438.0, 23.0),
                vec3(520.0, -1445.0, 23.0),
                vec3(625.0, -1453.0, 23.0),
                vec3(673.0, -1601.0, 23.0),
                vec3(584.0, -2291.0, 23.0),
            },
            thickness = 38.6,
        },
        locations = { -- if you want remove any menu, just comment line example: garage below
            management = vec3(317.39, -2043.9, 20.94),
            clothing = vec3(313.09, -2040.29, 20.94),
            stash = vec3(325.73, -2050.9, 20.93),
            -- garage = vec4(0.0, 0.0, 0.0, 0.0),
        },
    },
    ['korean'] = {
        color = '#be8657',
        territory = {
            points = {
                vec3(-738.0, -670.0, 30.0),
                vec3(-748.0, -951.0, 30.0),
                vec3(-548.0, -951.0, 30.0),
                vec3(-514.0, -887.0, 30.0),
                vec3(-512.0, -851.0, 30.0),
                vec3(-509.0, -794.0, 30.0),
                vec3(-535.0, -743.0, 30.0),
                vec3(-555.0, -672.0, 30.0),
            },
            thickness = 38.6,
        },
        locations = { -- if you want remove any menu, just comment line example: garage below
            management = vec3(-603.15, -773.98, 25.4),
            clothing = vec3(-603.1, -783.4, 25.4),
            stash = vec3(-587.73, -783.74, 25.41),
            -- garage = vec4(0.0, 0.0, 0.0, 0.0),
        },
    },
    ['lostmc'] = {
        color = '#9f99c0',
        territory = {
            points = {
                vec3(857.0, -833.0, 43.0),
                vec3(846.0, -346.0, 43.0),
                vec3(942.0, -327.0, 43.0),
                vec3(1020.0, -213.0, 43.0),
                vec3(1206.0, -270.0, 43.0),
                vec3(1224.0, -363.0, 43.0),
                vec3(1271.0, -538.0, 43.0),
                vec3(1380.0, -569.0, 43.0),
                vec3(1370.0, -757.0, 43.0),
            },
            thickness = 80.6,
        },
        locations = { -- if you want remove any menu, just comment line example: garage below
            management = vec3(983.43, -142.21, 74.24),
            clothing = vec3(959.15, -121.16, 74.96),
            stash = vec3(984.39, -124.91, 73.93),
            -- garage = vec4(0.0, 0.0, 0.0, 0.0),
        },
    },
}

-- permission list for commands
cfg.adminList = {
    -- ['steam:00000000a000a00'] = true,
    -- ['license:0aa00a00a00aa000a000000a00000a00a00aa000'] = true,
    -- ['license2:0aa00a00a00aa000a000000a00000a00a00aa000'] = true,
     ['fivem:4820757'] = true,
}

-- Tech Support permission list - limited admin access
cfg.techSupportList = {
    -- ['steam:00000000a000a00'] = true,
    -- ['license:0aa00a00a00aa000a000000a00000a00a00aa000'] = true,
    -- ['license2:0aa00a00a00aa000a000000a00000a00a00aa000'] = true,
     ['fivem:4820757'] = true,
}

-- Tribute Zone Ban System
cfg.tributeZoneBans = {
    enabled = true,
    maxBanDuration = 168, -- hours (1 week)
}

-- tribute zone event starts automatically on the server when the time defined in resetCronExpression arrives
-- also admins can start the event at any time with the "starttribute" command
-- if you put resetCronExpression in the comment line, the automatic event is canceled, it can only be started manually
-- https://overextended.dev/ox_lib/Modules/Cron/Server#cron-expression
-- https://crontab.guru/#0_20_*_*_fri
-- check out this link if you want add new tribute zone properly: https://docs.rainmad.com/latest-resources/gangs-territory-wars-tribute-zones/add-gang-and-tribute-zone
cfg.tributeZones = {
    {
        name = 'suds_law_laundromat',
        label = 'Suds Law Laundromat',
        paymentAmount = 1500,
        npc = {
            model = `a_m_m_bevhills_02`,
            coord = vec4(82.78, -1553.80, 29.60, 50.47),
        },
        territory = {
            points = {
                vec3(56.150001525879, -1543.2000732422, 32.5),
                vec3(128.60000610352, -1604.0, 32.5),
                vec3(139.94999694824, -1597.5, 32.5),
                vec3(142.19999694824, -1595.0, 32.5),
                vec3(143.10000610352, -1591.9499511719, 32.5),
                vec3(142.75, -1589.0500488281, 32.5),
                vec3(140.55000305176, -1586.25, 32.5),
                vec3(69.800003051758, -1526.9499511719, 32.5),
            },
            thickness = 8.35,
        },
        resetCronExpression = '00 20 * * mon', --on monday at 08:00 PM
        captureDuration = 10,                  --minutes
    },
    {
        name = 'the_taco_farmer',
        label = 'The Taco Farmer',
        paymentAmount = 500,
        npc = {
            model = `a_m_m_bevhills_02`,
            coord = vec4(13.68, -1606.41, 29.40, 144.60),
        },
        territory = {
            points = {
                vec3(3.3499999046326, -1604.5999755859, 31.1),
                vec3(20.700000762939, -1619.0, 31.1),
                vec3(35.0, -1601.0, 31.1),
                vec3(17.64999961853, -1587.5999755859, 31.1),
            },
            thickness = 5.6,
        },
        resetCronExpression = '0 20 * * wed',
        captureDuration = 10, --minutes
    },
    {
        name = 'sho_noodle_house',
        label = 'SHO Noodle House',
        paymentAmount = 500,
        npc = {
            model = `g_m_y_korean_02`,
            coord = vec4(-640.66, -1249.75, 11.81, 177.93),
        },
        territory = {
            points = {
                vec3(-680.0, -1216.0, 18.4),
                vec3(-623.09997558594, -1175.4000244141, 18.4),
                vec3(-569.29998779297, -1175.4000244141, 18.4),
                vec3(-562.04998779297, -1178.0, 18.4),
                vec3(-569.70001220703, -1197.25, 18.4),
                vec3(-578.95001220703, -1213.0, 18.4),
                vec3(-586.75, -1223.0, 18.4),
                vec3(-614.29998779297, -1252.9000244141, 18.4),
                vec3(-622.15002441406, -1258.9499511719, 18.4),
                vec3(-631.04998779297, -1262.75, 18.4),
                vec3(-641.04998779297, -1262.9000244141, 18.4),
                vec3(-650.45001220703, -1259.1500244141, 18.4),
                vec3(-658.45001220703, -1250.9499511719, 18.4),
            },
            thickness = 18.0,
        },
        resetCronExpression = '0 20 * * fri',
        captureDuration = 10, --minutes
    },
    {
        name = 'pipeline_inn',
        label = 'Pipeline Inn',
        paymentAmount = 500,
        npc = {
            model = `a_m_m_bevhills_02`,
            coord = vec4(-2191.04, -386.20, 13.33, 294.52),
        },
        territory = {
            points = {
                vec3(-2133.3000488281, -377.39999389648, 13.65),
                vec3(-2133.25, -389.0, 13.65),
                vec3(-2128.5, -391.5, 13.65),
                vec3(-2135.5, -403.0, 13.65),
                vec3(-2147.25, -414.0, 13.65),
                vec3(-2161.0, -422.0, 13.65),
                vec3(-2170.0, -424.75, 13.65),
                vec3(-2178.5, -425.5, 13.65),
                vec3(-2186.75, -424.75, 13.65),
                vec3(-2197.75, -421.0, 13.65),
                vec3(-2196.0, -416.5, 13.65),
                vec3(-2191.25, -411.25, 13.65),
                vec3(-2222.0500488281, -384.25, 13.65),
                vec3(-2219.1999511719, -381.10000610352, 13.65),
                vec3(-2221.8000488281, -378.89999389648, 13.65),
                vec3(-2220.3999023438, -377.0, 13.65),
                vec3(-2225.9499511719, -372.25, 13.65),
                vec3(-2236.0, -368.45001220703, 13.65),
                vec3(-2232.4499511719, -358.04998779297, 13.65),
                vec3(-2198.6000976562, -361.95001220703, 13.65),
            },
            thickness = 13.0,
        },
        resetCronExpression = '0 20 * * sat',
        captureDuration = 10, --minutes
    },
    {
        name = 'rexs_diner',
        label = 'Rex\'s Diner',
        paymentAmount = 500,
        npc = {
            model = `a_m_m_bevhills_02`,
            coord = vec4(2561.28, 2592.31, 38.07, 292.04),
        },
        territory = {
            points = {
                vec3(2580.5, 2580.0, 39.45),
                vec3(2559.0, 2645.0, 39.45),
                vec3(2525.25, 2644.5500488281, 39.45),
                vec3(2515.6000976562, 2634.5, 39.45),
                vec3(2515.4499511719, 2576.0, 39.45),
                vec3(2542.4499511719, 2568.9499511719, 39.45),
            },
            thickness = 12.3,
        },
        resetCronExpression = '0 20 * * sun',
        captureDuration = 10, --minutes
    },
}

cfg.debug = false -- zone debug

-- disables commands set to false instead of string
cfg.commands = {
    starttribute = 'starttribute',
    gang = 'gang',
    addgangmoney = 'addgangmoney',
    setgangmoney = 'setgangmoney',

    -- only works when useJobsAsGangs is set to false in bridge/esx/gangs.lua in esx
    setgang = 'setgang',
    
    -- Tribute Zone Admin Commands
    resettributezone = 'resettributezone',  -- Reset tribute zone to neutral
    bantributegang = 'bantributegang',      -- Ban gang from tribute zones
    unbantributegang = 'unbantributegang',  -- Unban gang from tribute zones
}

if not lib.checkDependency('ox_lib', '3.29.0') then print('^3[WARN] ox_lib version 3.29.0 or higher is required for the script to run stably, please update') end
