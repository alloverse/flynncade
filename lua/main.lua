local Emulator = require("Emulator")

local client = Client(
    arg[2], 
    "myarcade"
)

app = App(client)

assets = {
    arcade = ui.Asset.File("models/220120-arcade.glb"),
}
app.assetManager:add(assets)


local main = ui.View(Bounds(0.2, 0.1, -4.5,   1, 0.2, 1))
main:setGrabbable(true)

local emulator = Emulator(app)


local tv = main:addSubview(ui.ModelView(Bounds.unit():scale(0.3,0.3,0.3), assets.arcade))
tv.bounds:move(0,0,0)
local corners = {
    tl = {-1.2283, 5.7338, -0.49098},
    tr = {0.94936, 5.7338, -0.49098},
    bl = {-1.2283, 4.1062, 0.41123},
    br = {0.94936, 4.1062, 0.41123},
    norm = {0, 0.485, 0.875}
}

function newScreen(resolution, cropDimensions)
    local screen = ui.VideoSurface(ui.Bounds.unit(), resolution)
    screen.specification = function()
        local spec = ui.VideoSurface.specification(screen)
        spec = table.merge(spec, {
            geometry = {
                type = "inline",
                --   #bl                  #br                         #tl               #tr
                vertices= {corners.bl,    corners.br,                 corners.tl,       corners.tr},
                uvs = {{0.0, screen.uvh}, {screen.uvw, screen.uvh},   {0.0, 0.0},       {screen.uvw, 0.0}},
                normals = {corners.norm, corners.norm, corners.norm, corners.norm},
                triangles= {{0, 1, 3}, {2, 0, 3}},
            },
            material = {
                roughness = 0.2,
                metalness = 1,
            }
        })
        return spec
    end

    return screen
end

local controllers = tv:addSubview(View())
controllers.bounds:scale(5,5,5):move(0,5.6,-1.4)
emulator.controllers = {
    controllers:addSubview(RetroMote(Bounds(-0.15, -0.35, 0.6,   0.2, 0.05, 0.1), 1)),
    controllers:addSubview(RetroMote(Bounds( 0.087, -0.35, 0.6,   0.2, 0.05, 0.1), 2))
}
emulator.speaker = tv:addSubview(ui.Speaker(Bounds(0, 0.3, 0.2, 0,0,0)))
emulator.onScreenSetup = function (resolution, resmax)
    -- the res we want the screen to be
    local res = resmax

    if emulator.screen then
        -- if res is differrent from the current screen we setup a new one.
        if emulator.screen.resolution[1] ~= res[1] and emulator.screen.resolution[2] ~= res[2] then
            emulator.screen:removeFromSuperview()
            emulator.screen = nil
        end
    end

    if not emulator.screen then 
        emulator.screen = tv:addSubview(newScreen(res))
    end
end

local poller = nil
function run(rom) 
    if poller then poller:cancel() end
    emulator:loadGame(rom)

    poller = app:scheduleAction(1.0/emulator:getFps(), true, function()
        emulator:poll()
    end)
end

app:scheduleAction(5.0, true, function() 
    print("Network stats", app.client:getStats())
    print("Emulator stats", emulator:get_stats())
end)

local defaultGame = "roms/SNES/sf2t/rom.sfc"
-- local defaultGame = "roms/NES/tmnt2/rom.nes"
--local defaultGame = "roms/Genesis/sor3/rom.smd"
if #arg > 3 then
    defaultGame = arg[4]
end
run(defaultGame)




local dropTarget = main:addSubview(View(ui.Bounds.unit():scale(0.7, 0.5, 0.05):rotate(-3.14/6, 1, 0, 0):move(0,1.4,0.0)))
dropTarget:setPointable(true)
dropTarget.acceptedFileExtensions = {"png", "jpg", "jpeg"}
for k,v in pairs(Emulator.coreMap) do table.insert(dropTarget.acceptedFileExtensions, k) end
dropTarget.onFileDropped = function (self, filename, assetid)
    local ext = assert(filename:match("^.+%.(.+)$"))

    if ext == "png" or ext == "jpg" or ext == "jpeg" then 
        app.assetManager:load(assetid, function (name, asset)
            app.assetManager:add(asset, true)
            tv.material.texture = asset
            tv.material.uvScale = {1, -1}
            tv:updateComponents()
        end)
    else
        app.assetManager:load(assetid, function (name, asset)
            local file = io.open(filename, "wb")
            file:write(asset:read())
            file:close()
            run(filename)
        end)
    end
end

app.mainView = main

app:connect()
app:run(emulator:getFps())
