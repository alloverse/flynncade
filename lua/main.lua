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

local main = ui.View(Bounds(4, 0.1, -3,   1, 0.2, 1))
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

local helpPlate = main:addSubview(ui.Surface(ui.Bounds(-0.048, 1.02, 0.5,   0.65, 0.12, 0.05)))
helpPlate:setColor({0.4,0.4,0.4,1.0})
helpPlate:addSubview(ui.Label{
    bounds= ui.Bounds(0, 0.05, 0,  0.4, 0.025, 0.01),
    text= "How to play",
    color= {0.5, 0.1, 0.1, 1.0},
    halign="center",
})
helpPlate:addSubview(ui.Label{
    bounds= ui.Bounds(-0.09, 0.00, 0,  0.4, 0.015, 0.01),
    text= "VR: Grab the two gamepad parts.\n  Left stick   ABXY  Triggers  Sticks\n  D-pad        ABYX   LR           Select/Start",
    color= {0.5, 0.1, 0.1, 1.0},
    halign="left",
})
helpPlate:addSubview(ui.Label{
    bounds= ui.Bounds(0.24, 0.00, 0,  0.4, 0.015, 0.01),
    text= "Desktop: Press 'Use keyboard'.\n WASD     IJKL      UO    Tab       Enter\n D-pad      YXBA   LR     Select   Start",
    color= {0.5, 0.1, 0.1, 1.0},
    halign="left",
})


local menuButton = tv:addSubview(
    ui.Button(ui.Bounds{size=ui.Size(0.5,0.5,0.5)}:move( -0.1, 2.6, 1.3))
)
menuButton:setColor({1,1,1,1})
menuButton.onActivated = function(hand)
    -- TODO: If the browser is already open, close it.

    print("=======================")
    print("Opening Game Browser...")
    print("=======================")
    local gameBrowser = GameBrowser(ui.Bounds{size=ui.Size(1,1,0.05)}, emulator, app)
    main:addSubview(gameBrowser)
end


function newScreen(resolution, cropDimensions)
    local screen = ui.VideoSurface(ui.Bounds.unit(), resolution)
    screen.uvw = cropDimensions and cropDimensions[1] or 1.0
    screen.uvh = cropDimensions and cropDimensions[2] or 1.0
    screen.specification = function()
        local spec = ui.VideoSurface.specification(screen)
        table.merge(spec, {
            geometry = {
                type = "inline",
                --   #bl                  #br                         #tl               #tr
                vertices= {corners.bl,    corners.br,                 corners.tl,       corners.tr},
                uvs = {{0.0, screen.uvh}, {screen.uvw, screen.uvh},   {0.0, 0.0},       {screen.uvw, 0.0}},
                triangles= {{0, 1, 3}, {0, 3, 2}, {1, 0, 2}, {1, 2, 3}},
            },
            material = {
                roughness = 0,
                metalness = 1,
            }
        })
        return spec
    end

    return screen
end

local emulator = Emulator(app)
local controllers = tv:addSubview(View())
controllers.bounds:scale(5,5,5):move(0,5.6,-1.4)
emulator.controllers = {
    controllers:addSubview(RetroMote(Bounds(-0.15, -0.35, 0.6,   0.2, 0.05, 0.1), 1)),
    controllers:addSubview(RetroMote(Bounds( 0.087, -0.35, 0.6,   0.2, 0.05, 0.1), 2))
}
emulator.speaker = tv:addSubview(ui.Speaker(Bounds(0, 0.3, 0.2, 0,0,0)))
emulator.onScreenSetup = function (resolution, crop)
    if emulator.screen and emulator.screen.resolution[1] == resolution[1] and emulator.screen.resolution[2] == resolution[2] then
        if crop then 
            emulator.screen.setCropDimensions(crop[1], crop[2])
        end
        return
    end
    if emulator.screen then 
        emulator.screen:removeFromSuperview()
        emulator.screen = nil
    end
    emulator.screen = tv:addSubview(newScreen(resolution, crop))
end

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
    emulator:loadCore(core)
    emulator:loadGame(rom)

    poller = app:scheduleAction(1.0/emulator:getFps(), true, function()
        emulator:poll()
    end)
end

local coreMap = {
    sfc = "snes9x",
    smc = "snes9x",
    nes = "nestopia",
    smd = "genesis_plus_gx",
}

function runGame(filename)
    local ext = assert(filename:match("^.+%.(.+)$"))
    local core = assert(coreMap[ext])
    run(core, filename)
end

app:scheduleAction(5.0, true, function() 
    print("Network stats", app.client.client:get_stats())
    print("Emulator stats", emulator:get_stats())
end)

--local defaultGame = "roms/SNES/sf2t/sf2t.sfc"
-- local defaultGame = "roms/NES/tmnt2/tmnt2.nes"
local defaultGame = "roms/Genesis/sor3/sor3.smd"
if #arg > 2 then
    defaultGame = arg[3]
end
runGame(defaultGame)


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
