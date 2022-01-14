local client = Client(
    arg[2], 
    "flynncade",
    allonet.create(true)
)

app = App(client)

assets = {
    quit = ui.Asset.File("images/quit.png"),
    crt = ui.Asset.File("models/magnavox.glb"),
    arcade = ui.Asset.File("models/220111-arcade.glb"),
}
app.assetManager:add(assets)

local emulator = require("Emulator")

local main = ui.View(Bounds(0.2, 0.1, -4.5,   1, 0.2, 1))
main:setGrabbable(true)

Bounds.unit = function ()
    return Bounds(0,0,0,1,1,1)
end

local tv = main:addSubview(ui.ModelView(Bounds.unit():scale(0.3,0.3,0.3), assets.arcade))
tv.bounds:move(0,0,0)
local corners = {
    tl = {-1.2283, 5.7338, -0.49098},
    tr = {0.94936, 5.7338, -0.49098},
    bl = {-1.2283, 4.1062, 0.41123},
    br = {0.94936, 4.1062, 0.41123}
}

function newScreen(resolution)
    local screen = ui.VideoSurface(ui.Bounds.unit(), resolution)
    screen.customSpecAttributes = {
        geometry = {
            type = "inline",
            --   #bl                   #br                  #tl                   #tr
            vertices= {corners.bl,      corners.br,      corners.tl,       corners.tr},
            uvs = {{0.0, 1.0},           {1.0, 1.0},          {0.0, 0.0},           {1.0, 0.0}},
            triangles= {{0, 1, 3}, {0, 3, 2}, {1, 0, 2}, {1, 2, 3}},
        },
        material = {
            roughness = 0,
            metalness = 1,
        }
    }
    return screen
end

local emulator = Emulator(app)
local controllers = tv:addSubview(View())
controllers.bounds:scale(5,5,5):move(0,5.6,-1.4)
emulator.controllers = {
    controllers:addSubview(RetroMote(Bounds(-0.15, -0.35, 0.6,   0.2, 0.05, 0.1), 1)),
    controllers:addSubview(RetroMote(Bounds( 0.08, -0.35, 0.6,   0.2, 0.05, 0.1), 2))
}
emulator.speaker = tv:addSubview(ui.Speaker(Bounds(0, 0.3, 0.2, 0,0,0)))

local quitButton = main:addSubview(
    ui.Button(ui.Bounds{size=ui.Size(0.12,0.12,0.05)}:rotate(3.14,0,1,0):move( 0.22,1.95,-0.3))
)
quitButton:setDefaultTexture(assets.quit)
quitButton.onActivated = function()
    main:addPropertyAnimation(ui.PropertyAnimation{
        path= "transform.matrix.scale",
        from=   {1, 1, 1},
        to= {0.01, 1, 1},
        duration= 0.2,
        easing="quadOut" 
    })
    app:scheduleAction(0.2, false, function() 
        app:quit()
    end)
end

main:doWhenAwake(function()
    main:addPropertyAnimation(ui.PropertyAnimation{
        path= "transform.matrix.scale",
        to=   {1, 1, 1},
        from= {0.01, 1, 1},
        duration= 0.3,
        easing="quadOut" 
    })
end)

local poller = nil
function run(core, rom) 
    if poller then poller:cancel() end
    if emulator.screen then 
        emulator.screen:removeFromSuperview()
        emulator.screen = nil
    end
    emulator:loadCore(core)
    emulator:loadGame(rom)
    emulator.screen = tv:addSubview(newScreen(emulator.resolution))

    poller = app:scheduleAction(1.0/emulator:getFps(), true, function()
        emulator:poll()
    end)
end

run("snes9x", "roms/SNES/sf2t/sf2t.sfc")
-- run("nestopia", "roms/NES/tmnt2/tmnt2.nes")
-- run("genesis_plus_gx", "roms/Genesis/sor3/sor3.smd")

app:scheduleAction(5.0, true, function() 
    print("Network stats", app.client.client:get_stats())
    print("Emulator stats", emulator:get_stats())
end)

local coreMap = {
    sfc = "snes9x",
    nes = "nestopia",
    smd = "genesis_plus_gx",
}

local dropTarget = main:addSubview(View(ui.Bounds.unit():scale(0.7, 0.5, 0.05):rotate(-3.14/6, 1, 0, 0):move(0,1.4,0.0)))
dropTarget:setPointable(true)
dropTarget.acceptedFileExtensions = {"png"}
for k,v in pairs(coreMap) do table.insert(dropTarget.acceptedFileExtensions, k) end
dropTarget.onFileDropped = function (self, filename, assetid)
    local ext = assert(filename:match("^.+%.(.+)$"))

    if ext == "png" then 
        app.assetManager:load(assetid, function (name, asset)
            app.assetManager:add(asset, true)
            tv.texture = asset
            tv:updateComponents()
        end)
    else
        local core = assert(coreMap[ext])
        app.assetManager:load(assetid, function (name, asset)
            local file = io.open(filename, "wb")
            file:write(asset:read())
            file:close()
            run(core, filename)
        end)
    end
end


app.mainView = main

app:connect()
app:run(emulator:getFps())
