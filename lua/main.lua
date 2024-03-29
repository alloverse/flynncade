quat = require("modules.quat")

local client = Client(
    arg[2], 
    "flynncade"
)

app = App(client)

assets = {
    quit = ui.Asset.File("images/quit.png"),
    crt = ui.Asset.File("models/magnavox.glb"),
    arcade = ui.Asset.File("models/220120-arcade.glb"),
}
app.assetManager:add(assets)

local Emulator = require("Emulator")
local GameList = require("GameList")
local GameBrowser = require("GameBrowser")

local main = ui.View(Bounds(4, 0.1, -3,   1, 0.2, 1))
main:setGrabbable(true)
function math.sign(x)
    if x<0 then
      return -1
    elseif x>0 then
      return 1
    else
      return 0
    end
 end

function quat.rotation_around_x(q)
    local a = math.sqrt((q.w * q.w) + (q.x * q.x))
    return quat.new(q.x, 0, 0, q.w / a)
end
function quat.rotation_around_y(q)
    local a = math.sqrt((q.w * q.w) + (q.y * q.y))
    return quat.new(0,  q.y, 0, q.w / a)
end
function quat.rotation_around_z(q)
    local a = math.sqrt((q.w * q.w) + (q.z * q.z))
    return quat.new(0, 0, q.z, q.w / a)
end
 

if App.initialLocation then
    local loc = vec3.new(0,0,0)
    local at = App.initialLocation * loc
    at.y = 0
    local q = App.initialLocation:to_quat()
    local newQ = quat.rotation_around_y(q)

    App.initialLocation = mat4.new()
    App.initialLocation:rotate(App.initialLocation, newQ)
    App.initialLocation:translate(App.initialLocation, at)
end

local main = ui.View(Bounds(0.2, 0.1, -4.5,   1, 0.2, 1))
main:setGrabbable(true, {
    rotation_constraint= {0,1,0}
})

Bounds.unit = function ()
    return Bounds(0,0,0,1,1,1)
end

local emulator = Emulator(app)
local gameBrowser = nil
local gameList = GameList("roms")

local tv = main:addSubview(ui.ModelView(Bounds.unit():scale(0.3,0.3,0.3), assets.arcade))
tv.bounds:move(0,0,0)
local corners = {
    tl = {-1.2283, 5.7338, -0.49098},
    tr = {0.94936, 5.7338, -0.49098},
    bl = {-1.2283, 4.1062, 0.41123},
    br = {0.94936, 4.1062, 0.41123},
    norm = {0, 0.485, 0.875}
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

function playGameDesc(gameDesc)
    emulator:loadGame(gameDesc.rom)
    changeTexture(gameDesc.cabinetTexture)
end

local menuButton = tv:addSubview(
    ui.Button(ui.Bounds{size=ui.Size(0.5,0.2,0.1)}:move( -0.1, 2.6, 1.3))
)
menuButton.label:setText("Menu")
menuButton:setColor({0.60, 0.80, 0.95, 1})
menuButton.onActivated = function(hand)
  
  if gameBrowser then 
    gameBrowser:removeFromSuperview()
    gameBrowser = nil
  else 
    gameBrowser = GameBrowser(ui.Bounds{size=ui.Size(1,1,0.05), pose=ui.Pose(1, 1.5, 0)}:rotate(-3.14/8, 0, 1, 0), app, gameList)
    main:addSubview(gameBrowser)

    gameBrowser.onGameChosen = function(game)
      playGameDesc(game)

      gameBrowser:removeFromSuperview()
      gameBrowser = nil
    end

    gameBrowser.onSetting = function(name, newValue)
      if newValue then
          emulator[name] = newValue
      end
      return emulator[name]
    end

    gameBrowser.onRestartGame = function()
      emulator:restart()
    end

  end
end


function changeTexture(cabinetTextureAsset)
  tv.material.texture = cabinetTextureAsset
  tv.material.uvScale = { 1, -1 }
  tv:updateComponents()
end

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

local poller = nil
function run(console, game) 
    if poller then poller:cancel() end
    playGameDesc(gameList.consoles[console].games[game])

    poller = app:scheduleAction(1.0/emulator:getFps(), true, function()
        emulator:poll()
    end)
end

app:scheduleAction(5.0, true, function() 
    print("Network stats", app.client:getStats())
    print("Emulator stats", emulator:get_stats())
end)

local defaultConsole = "SNES"
local defaultGame = "sf2t"
if #arg > 4 then
    defaultConsole = arg[4]
    defaultGame = arg[5]
elseif ui.App.launchArguments.game then
    defaultConsole = ui.App.launchArguments.console
    defaultGame = ui.App.launchArguments.game
end
run(defaultConsole, defaultGame)




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
