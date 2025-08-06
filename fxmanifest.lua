fx_version 'cerulean'
games { 'gta5' }
author 'mano.6195'
lua54 'yes'

client_scripts {
    'Client/*.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'Server/*.lua'
}

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
    '@ox_lib/init.lua'
}

ui_page 'UI/index.html'

files {
    'UI/*.*',
    'UI/sound.mp3'
}

escrow_ignore {
    'config.lua',
}