local class = require('pl.class')
local pretty = require('pl.pretty')
local json = require "allo.json"
function readfile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

local platformToExtensionMap = {
    NES = "nes",
    SNES = "sfc",
    Genesis = "smd"
}

class.GameList()
function GameList:_init(root)
    self.root = root
    self.consoles = {}

    self:populateConsoles()
    self:populateGames()
end

function GameList:populateConsoles()
    local p = io.popen('find ' .. self.root .. '/* -maxdepth 0')
    local i=0
    for consolePath in p:lines() do
        local consoleName = string.sub(consolePath, #self.root+2)
        self.consoles[consoleName] = {
            path= consolePath,
            games= {},
            name= consoleName
        }
    end
    p:close()
end

function GameList:populateGames()
    for _, console in pairs(self.consoles) do
        self:populateGamesInConsole(console)
    end
end

function GameList:populateGamesInConsole(console)
    local p = io.popen('find ' .. console.path .. '/* -maxdepth 0')
    local i=0
    local extension = platformToExtensionMap[console.name]

    for gamePath in p:lines() do
        local gameName = string.sub(gamePath, #console.path+2)
        local infojsonstr = readfile(gamePath.."/info.json")
        if infojsonstr then
            local game = {
                name= gameName,
                path= gamePath,
                meta= json.decode(infojsonstr),
                rom= gamePath.."/rom."..extension,
                boxArt= ui.Asset.File(gamePath.."/boxArt.jpg"),
                cabinetTexture= ui.Asset.File(gamePath.."/cabinet-texture.png"),
            }
            console.games[gameName] = game
        end
    end
    p:close()
end

return GameList
