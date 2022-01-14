local class = require('pl.class')


class.GameBrowser(ui.View)


local BROWSER_WIDTH = 1
local MENU_ITEM_HEIGHT = 0.3
local MENU_ITEM_PADDING = 0.05


function GameBrowser:_init(bounds, emulator)
  self:super(bounds)
  self.emulator = emulator

  local mainView = ui.Surface(ui.Bounds(0, 0, 0,   BROWSER_WIDTH, MENU_ITEM_HEIGHT*3, 0.01):move(1, 1.5, 0))
  mainView:setColor({0, 0, 0, 1})
  mainView.grabbable = true

  -- Iterate through all folders

  local menuItem = ui.Surface(ui.Bounds(MENU_ITEM_PADDING, MENU_ITEM_PADDING, 0.01,   BROWSER_WIDTH-(MENU_ITEM_PADDING*2), MENU_ITEM_HEIGHT, 0.01))
  menuItem:setColor({0.15,0.15,0.15})

  local menuItemLabel = Label{bounds=Bounds(0, 0, 0, 1.0, 0.1, 0.001), color={0.85,0.85,0.85,1}, text="Item 1", halign="left"}
  menuItem:addSubview(menuItemLabel)

  -- save number of folders & set the height of the browser to match, possibly by using "inset" with the negative of #menuItems * MENU_ITEM_HEIGHT

  
  mainView:addSubview(menuItem)

  self:addSubview(mainView)

  



  -- TODO: Add close button

  -- local quitButton = mainView:addSubview(
  --   ui.Button(ui.Bounds{size=ui.Size(0.12,0.12,0.05)}:move( 0.52,0.62,0.025))
  -- )
  -- quitButton:setDefaultTexture(assets.quit)
  -- quitButton.onActivated = function()
  --     app:quit()
  -- end

  -- local backButton = mainView:addSubview(
  --   ui.Button(ui.Bounds{size=ui.Size(0.12,0.12,0.05)}:move( 0.52,0.62,0.025))
  -- )
  -- backButton:setDefaultTexture(assets.back)
  -- backButton.onActivated = function()
  --   --app:quit()
  -- end

end

return GameBrowser