local RetroView = require("RetroView")

local client = Client(
    arg[2], 
    "flynncade",
    allonet.create(true)
)
local app = App(client)

assets = {
    quit = ui.Asset.File("images/quit.png"),
    crt = ui.Asset.File("models/magnavox.glb"),
    snesmote = ui.Asset.File("models/snesmote.glb"),
}
app.assetManager:add(assets)

local main = ui.View(Bounds(0.2, 1.1, -4.5,   1, 1, 1))
main:setGrabbable(true)

local tv = main:addSubview(ui.ModelView(Bounds(-1.32,0,0,  1,1,1):rotate(-3.14/2, 0,1,0), assets.crt))

local background = main:addSubview(ui.Surface(Bounds(0, 0.05, -0.01,   0.80, 0.50, 0.01)))
background:setColor({0,0,0,1})
local emulator = main:addSubview(RetroView(Bounds(0,0.05,0,   0.65, 0.50, 0.01)))
app:scheduleAction(1/emulator:getFps(), true, function()
    emulator:poll()
end)

local scale = 0.00035
emulator.controllers[1]:addSubview(ui.ModelView(Bounds(0,0,0, 0.2,0.1,0.1):scale(scale,scale,scale):rotate(-3.14/2,1,0,0), assets.snesmote))
emulator.controllers[2]:addSubview(ui.ModelView(Bounds(0,0,0, 0.2,0.1,0.1):scale(scale,scale,scale):rotate(-3.14/2,1,0,0), assets.snesmote))

app:scheduleAction(5.0, true, function() 
    print("Network stats", app.client.client:get_stats())
end)

app.mainView = main

app:connect()
app:run()
