fx_version '5.4.0-hologram-color-fix'
game 'gta5'

name 'real_markers'
author 'RealRPG / ChatGPT'
description 'Subtle RP marker system with sticky-icon fix and color selectable hologram icons'
version '5.4.0-hologram-color-fix'

lua54 'yes'

ui_page 'web/index.html'

shared_scripts {
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/icons/*.svg',
    'sql/*.sql'
}
