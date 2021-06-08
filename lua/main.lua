local RetroView = require("RetroView")

local client = Client(
    arg[2], 
    "flynncade"
)
local app = App(client)

assets = {
    quit = ui.Asset.File("images/quit.png"),
}
app.assetManager:add(assets)

local mainView = RetroView(Bounds(0, 1.5, -2,   2, 2, 0.1))
app:scheduleAction(1/60.0, true, function()
    mainView:poll()
end)

app.mainView = mainView

app:connect()
app:run()
