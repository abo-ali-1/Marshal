fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

author 'rainmad <store.rainmad.com>'
version '1.5.5'

ui_page 'build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'cfg.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
    'modules/inventory/*.lua',
    'modules/**/server.lua',
    'modules/territory_ownership/server.lua',
    'modules/territory_ownership/admin_commands.lua',
    'modules/tribute_zones/discord_webhook.lua',
    'modules/tribute_zones/admin_commands.lua',
}

client_scripts {
    'client.lua',
    'modules/target/*.lua',
    'modules/inventory/*.lua',
    'modules/**/client.lua',
    'modules/territory_ownership/client.lua',
    'modules/tribute_zones/client_notifications.lua',
}

files {
    'locales/*.json',
    'build/**',

    'modules/framework/esx/gangs.lua',
}

escrow_ignore {
    'cfg.lua',
    'client.lua',
    'server.lua',
    'modules/**/client.lua',
    'modules/**/server.lua',
    'modules/framework/**.lua',
    'modules/inventory/*.lua',
    'modules/target/*.lua',
    'modules/garage/*.lua',

    'modules/framework/esx/gangs.lua',
}
dependency '/assetpacks'