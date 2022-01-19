local class = require('pl.class')
local pretty = require('pl.pretty')
local json = require "allo.json"

class.GameBrowser(ui.View)

local MENU_ITEM_WIDTH = 1
local MENU_ITEM_HEIGHT = 0.15
local MENU_ITEM_PADDING = 0.02

function readfile(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

function GameBrowser:_init(bounds, app)
  self:super(bounds)
  self.app = app

  assets = {
    quit = ui.Asset.File("images/icon-quit.png"),
    restart = ui.Asset.File("images/icon-restart.png"),
  }
  self.app.assetManager:add(assets)

  self.browserStack = ui.NavStack(ui.Bounds(0,0,0,1,1,1))
  self:addSubview(self.browserStack)

  self:_addSettingsButtons()

  self:listConsoles()
end

function GameBrowser:_addSettingsButtons()
  
  -- Header + "Alloverse Arcade"
  local header = ui.Surface(ui.Bounds(0, 0.2, 0.01,  MENU_ITEM_WIDTH, 0.2, 0.03));
  header:setColor({0.60, 0.80, 0.95, 1})
  self:addSubview(header)

  local settingsLabel = Label{bounds=Bounds(MENU_ITEM_PADDING, 0, 0.01, MENU_ITEM_WIDTH-(MENU_ITEM_PADDING*2), MENU_ITEM_HEIGHT-(MENU_ITEM_PADDING*4), 0.01), color={1,1,1,1}, text="AlloArcade", halign="left"}
  header:addSubview(settingsLabel)

  -- Right, vertical menu with quit & restart
  local settingsPanel = ui.Surface(ui.Bounds(0.5, 0.2, 0.01,  0, 0, 0.01):rotate(-3.14/8, 0, 1, 0))
  settingsPanel:setColor({0, 0, 0, 0})
  self:addSubview(settingsPanel)

  local quitButton = ui.Surface(ui.Bounds(0.1, 0, 0.01,    0.2, 0.2, 0.01));
  local quitButtonLabel = Label{bounds=Bounds(0.6, 0, 0.01, 1, 0.05, 0.01), color={1,1,1,0}, text="Close App", halign="left"}
  quitButton:addSubview(quitButtonLabel)

  quitButton:setColor({0, 0, 0, 1})
  quitButton:setTexture(assets.quit)
  quitButton:setPointable(true)
  quitButton.onPointerEntered = function(pointer)
    quitButton:setColor({1, 1, 1, 1})
    quitButtonLabel:setColor({1,1,1,1})
  end
  quitButton.onPointerExited = function(pointer)
    quitButton:setColor({0, 0, 0, 1})
    quitButtonLabel:setColor({1,1,1,0})
  end
  quitButton.onTouchUp = function(pointer)
    self.app:quit()
  end

  settingsPanel:addSubview(quitButton)

  local restartButton = ui.Surface(ui.Bounds(0.1, -0.2, 0.01,  0.2, 0.2, 0.01));
  local restartButtonLabel = Label{bounds=Bounds(0.6, 0, 0.01, 1, 0.05, 0.01), color={1,1,1,0}, text="Reset Machine", halign="left"}
  restartButton:addSubview(restartButtonLabel)

  restartButton:setColor({0, 0, 0, 1})
  restartButton:setTexture(assets.restart)
  restartButton:setPointable(true)
  restartButton.onPointerEntered = function(pointer)
    restartButton:setColor({1, 1, 1, 1})
    restartButtonLabel:setColor({1, 1, 1, 1})
  end
  restartButton.onPointerExited = function(pointer)
    restartButton:setColor({0, 0, 0, 1})
    restartButtonLabel:setColor({1, 1, 1, 0})
  end
  restartButton.onTouchUp = function(pointer)
    self.onRestartGame()
  end

  settingsPanel:addSubview(restartButton)
end


function GameBrowser:listConsoles()
  local path = "roms"
  local depth = 0

  -- Create a "page"; the surface on which the menu items will be drawn.
  local page = ui.Surface(ui.Bounds(0,0,0, 0, 0, 0):move(depth/60, -depth/60, depth/60))
  page:setColor({0, 0, 1, 0.9})

  self.browserStack:push(page)

  -- Move the mainView up-and-back so that the newly created page always remains on "z=0"
  self.bounds:move(-depth/60, depth/60, -depth/60)
  self:markAsDirty("transform")

  -- Look through the console folders
  local p = io.popen('find ' .. path .. '/* -maxdepth 0')
  local i=0
  for gamePath in p:lines() do

    -- Quick hack to get the console's name from the path
    local consoleName = string.sub(gamePath, 6)

    -- Create a menu item with bounds relative to its parent-to-be page
    local menuItem = ui.Surface(ui.Bounds(0, 0 - (i * MENU_ITEM_HEIGHT), 0.01, MENU_ITEM_WIDTH, MENU_ITEM_HEIGHT, 0.01))
    menuItem:setColor({1, 1, 1, 1})

    -- Create a Label inside said menu item
    local menuItemLabel = Label{bounds=Bounds(MENU_ITEM_PADDING, 0, 0.001, MENU_ITEM_WIDTH-(MENU_ITEM_PADDING*2), MENU_ITEM_HEIGHT-(MENU_ITEM_PADDING*4), 0.001), color={0.15,0.15,0.15,1}, text=consoleName, halign="left"}
    menuItem:addSubview(menuItemLabel)

    -- Make the menuItem interactive
    menuItem:setPointable(true)
    menuItem.onTouchUp = function(pointer)
      self:listGames(gamePath, consoleName)
    end

    menuItem.onPointerEntered = function(pointer)
      menuItem:setColor({0.78, 0.82, 0.88, 1})
    end

    menuItem.onPointerExited = function(pointer)
      menuItem:setColor({1, 1, 1, 1})
    end

    -- Add the menuItem to the page
    page:addSubview(menuItem)
    
    i = i+1
  end
  p:close()
end

function GameBrowser:listGames(path, platform)
  local depth = 1
  
  -- Create a "page"; the surface on which the menu items will be drawn.
  local page = ui.Surface(ui.Bounds(0,0,0, 0, 0, 0):move(depth/60, -depth/60, depth/60))
  page:setColor({0, 0, 1, 0.9})
  --self:addSubview(page)
  self.browserStack:push(page)

  -- Move the mainView up-and-back so that the newly created page always remains on "z=0"
  self.bounds:move(-depth/60, depth/60, -depth/60)
  self:markAsDirty("transform")

  -- Iterate through the folder
  local p = io.popen('find ' .. path .. '/* -maxdepth 0')
  local i=0
  for gamePath in p:lines() do

    local infojsonstr = readfile(gamePath.."/info.json")
    if infojsonstr then

      local platformToExtensionMap = {
        NES = "nes",
        SNES = "sfc",
        Genesis = "smd"
      }

      local extension = platformToExtensionMap[platform]

      local game = {
          path= gamePath,
          meta= json.decode(infojsonstr),
          rom= gamePath.."/rom."..extension,
          boxArt= ui.Asset.File(gamePath.."/boxArt.jpg"),
      }

      self.app.assetManager:add(game.boxArt, true)

      -- Create a menu item with bounds relative to its parent-to-be page
      local menuItem = ui.Surface(ui.Bounds(0, 0 - (i * MENU_ITEM_HEIGHT), 0.01,  MENU_ITEM_WIDTH, MENU_ITEM_HEIGHT, 0.01))
      menuItem:setColor({1, 1, 1, 1})

      -- Create a Label inside said menu item
      local menuItemLabel = Label{bounds=Bounds(MENU_ITEM_PADDING, 0, 0.001, MENU_ITEM_WIDTH-(MENU_ITEM_PADDING*2), MENU_ITEM_HEIGHT-(MENU_ITEM_PADDING*4), 0.001), color={0.15,0.15,0.15,1}, text=game.meta.gameName, halign="left"}
      menuItem:addSubview(menuItemLabel)

      -- Make the menuItem interactive
      menuItem:setPointable(true)
      menuItem.onTouchUp = function(pointer)
        self:showGame(game)
      end

      menuItem.onPointerEntered = function(pointer)
        menuItem:setColor({0.78, 0.82, 0.88, 1})
      end

      menuItem.onPointerExited = function(pointer)
        menuItem:setColor({1, 1, 1, 1})
      end
      
      -- Add the menuItem to the page
      page:addSubview(menuItem)

      i = i+1
    end

    
  end
  p:close()
end

function GameBrowser:showGame(game)
  local depth = 2

  -- Create a "page"; the surface on which the menu items will be drawn.
  local page = ui.Surface(ui.Bounds(0, 0, 0.01, 1, MENU_ITEM_HEIGHT*4, 0.01):move(depth/60, -depth/60, depth/60))
  page:setColor({1, 1, 1, 1})
  page:setTexture(game.meta.albumArt)
  -- self:addSubview(page)
  self.browserStack:push(page)

  -- Move the mainView up-and-back so that the newly created page always remains on "z=0"
  self.bounds:move(-depth/60, depth/60, -depth/60)
  self:markAsDirty("transform")

  local gameTitle = Label{bounds=Bounds(0.15, 0.25, 0, MENU_ITEM_WIDTH-MENU_ITEM_PADDING*4, 0.05, 0.001), color={0.1,0.1,0.1,1}, text=game.meta.gameName, halign="left" }
  page:addSubview(gameTitle)

  local gameInfo = Label{bounds=Bounds(0, 0.2, 0, MENU_ITEM_WIDTH-MENU_ITEM_PADDING*4, 0.03, 0.001), color={0.1,0.1,0.1,1}, text=game.meta.blurb, halign="left", valign="top", wrap=true}
  page:addSubview(gameInfo)

  -- local gameBoxArt = Surface(ui.Bounds(-MENU_ITEM_WIDTH/2 + MENU_ITEM_PADDING, MENU_ITEM_PADDING, 0.001, 0.1, 0.1, 0.001))
  -- gameBoxArt:setTexture(game.boxArt)
  -- page:addSubview(gameBoxArt)

  local playButton = ui.Button(ui.Bounds(0, -0.2, 0, MENU_ITEM_WIDTH-MENU_ITEM_PADDING*2, 0.1, 0.1))
  playButton:setColor({0.83, 0.53, 0.78, 1})
  playButton.label:setText("Play")

  playButton.onActivated = function()
    pretty.dump(game)
    self.onGameChosen(game.rom)
  end

  page:addSubview(playButton)

end



return GameBrowser