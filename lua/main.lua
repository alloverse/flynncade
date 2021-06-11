local RetroView = require("RetroView")

local client = Client(
    arg[2], 
    "flynncade",
    allonet.create(true)
)
local app = App(client)

if not arg[3] then
    print("Usage: ./allo/assist run [url] [path to retroarch cores]")
    return 0
end
local cores = arg[3]

assets = {
    quit = ui.Asset.File("images/quit.png"),
}
app.assetManager:add(assets)

local mainView = RetroView(Bounds(0, 1.5, -2,   2, 2, 0.1), cores)
app:scheduleAction(1/mainView:getFps(), true, function()
    mainView:poll()
end)

app:scheduleAction(5.0, true, function() 
    print("Network stats", app.client.client:get_stats())
end)

app.mainView = mainView

app:connect()
app:run()
