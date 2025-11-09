fx_version 'cerulean'
game 'gta5'

author 'Rey Panda'
description 'Item Show - Visualizador de items para administradores'
version '1.0.0'

-- Dependencia obligatoria: qb-core
-- QBCore es necesario para acceder a QBCore.Shared.Items y funciones de permisos
dependencies {
    'qb-core'
}

-- Archivos del servidor
server_scripts {
    'config.lua',
    'server/server.lua'
}

-- Archivos del cliente
client_scripts {
    'config.lua',
    'client/client.lua'
}

-- Recursos NUI (interfaz web)
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

