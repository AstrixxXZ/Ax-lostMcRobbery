fx_version 'cerulean'
game 'gta5'

author 'Astrix2'
description 'Обир на оръжеен камион'
version '3.5.8'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target',
    'ox_inventory'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

lua54 'yes'