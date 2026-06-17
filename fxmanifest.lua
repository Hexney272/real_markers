fx_version 'cerulean'
game 'gta5'

name 'real_markers'
author 'RealRPG'
description 'Natív 3D DrawMarker rendszer — lebegő ikonok, bobbing, forgás, talajkör'
version '2.0.0'

lua54 'yes'

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

dependency 'oxmysql'
