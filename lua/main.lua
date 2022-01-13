local client = Client(
    arg[2], 
    "flynncade",
    allonet.create(true)
)

app = App(client)

assets = {
    quit = ui.Asset.File("images/quit.png"),
    crt = ui.Asset.File("models/magnavox.glb"),
    arcade = ui.Asset.File("models/arcade.glb"),
}
app.assetManager:add(assets)

local RetroView = require("RetroView")

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
local emulator = tv:addSubview(RetroView(ui.Bounds.unit()))
local controllers = emulator:addSubview(View())
controllers.bounds:scale(5,5,5):move(0,5.6,-1.4)
emulator.controllers = {
    controllers:addSubview(RetroMote(Bounds(-0.2, -0.3, 0.6,   0.2, 0.05, 0.1), 1)),
    controllers:addSubview(RetroMote(Bounds( 0.2, -0.3, 0.6,   0.2, 0.05, 0.1), 2))
}
emulator.customSpecAttributes = {
    geometry = {
        type = "inline",
              --   #bl                   #br                  #tl                   #tr
        vertices= {corners.bl,      corners.br,      corners.tl,       corners.tr},
        uvs=      {{0.0, 0.0},           {1.0, 0.0},          {0.0, 1.0},           {1.0, 1.0}},
        triangles= {{0, 1, 3}, {0, 3, 2}, {1, 0, 2}, {1, 2, 3}},
    }
}

app:scheduleAction(1.0/emulator:getFps(), true, function()
    emulator:poll()
end)

app:scheduleAction(1.0, true, function() 
    print("Network stats", app.client.client:get_stats())
    print("Emulator stats", emulator:get_stats())
end)

app.mainView = main

app:connect()
app:run(emulator:getFps())
