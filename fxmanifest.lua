fx_version 'cerulean'
game 'gta5'

name 'real_markers'
author 'RealRPG'
description 'Natív 3D DrawMarker rendszer — lebegő ikonok + NUI editor'
version '2.1.0'

lua54 'yes'

ui_page 'web/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/icons/*.svg',
    'web/icons/*.png',
    'web/icons/*.webp'
}

dependency 'oxmysql'
