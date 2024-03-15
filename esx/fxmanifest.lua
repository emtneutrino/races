fx_version "cerulean"
game "gta5"

lua54 "yes"

dependency "chat"

client_script "races_client.lua"

server_scripts {
    "races_server.lua",
    "port.lua"
}

shared_script "@es_extended/imports.lua"

ui_page "html/index.html"
files {
    "html/index.css",
    "html/index.html",
    "html/index.js",
    "html/reset.css"
}
