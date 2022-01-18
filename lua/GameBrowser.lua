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

function GameBrowser:_init(bounds, emulator, app)
  self:super(bounds)
  self.emulator = emulator
  self.app = app

  assets = {
    quit = ui.Asset.File("images/icon-quit.png"),
    restart = ui.Asset.File("images/icon-restart.png"),
  }
  self.app.assetManager:add(assets)

  self:_addSettingsButtons()

  self:listConsoles()
end

function GameBrowser:_addSettingsButtons()
  
  local header = ui.Surface(ui.Bounds(0, 0.2, 0.01,  MENU_ITEM_WIDTH, 0.2, 0.03));
  header:setColor({1, 0, 0.5, 0.8})
  self:addSubview(header)

  local settingsLabel = Label{bounds=Bounds(MENU_ITEM_PADDING, 0, 0.01, MENU_ITEM_WIDTH-(MENU_ITEM_PADDING*2), MENU_ITEM_HEIGHT-(MENU_ITEM_PADDING*4), 0.01), color={0.15,0.15,0.15,1}, text="GAME SELECT", halign="left"}
  header:addSubview(settingsLabel)



  local settingsPanel = ui.Surface(ui.Bounds(0.5, 0.2, 0.01,  0, 0, 0.01)) --:rotate(-3.14/8, 0, 1, 0):move(0.3, 0, 0)
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
    self.emulator:restart()
  end

  settingsPanel:addSubview(restartButton)
end


function GameBrowser:listConsoles()
  local path = "roms"
  local depth = 0

  -- Create a "page"; the surface on which the menu items will be drawn.
  local page = self:addSubview(ui.Surface(ui.Bounds(0,0,0, 0, 0, 0):move(depth/10, -depth/10, depth/10)))
  page:setColor({0, 0, 1, 0.9})

  -- Move the mainView up-and-back so that the newly created page always remains on "z=0"
  self.bounds:move(-depth/10, depth/10, -depth/10)
  self:markAsDirty("transform")

  -- Look through the console folders
  local p = io.popen('find ' .. path .. '/* -maxdepth 0')
  local i=0
  for gamePath in p:lines() do
    print("The Game Browser found lines: "..gamePath)

    -- TODO: substring magic to cut out the path from the label, just show the ultimate file- or folder name.
    local consoleName = string.sub(gamePath, 6)

    -- Create a menu item with bounds relative to its parent-to-be page
    local menuItem = ui.Surface(ui.Bounds(0, 0 - (i * MENU_ITEM_HEIGHT), 0.01, MENU_ITEM_WIDTH, MENU_ITEM_HEIGHT, 0.01))
    menuItem:setColor({1, 1, 1, 1})

    -- Create a Label inside said menu item
    local menuItemLabel = Label{bounds=Bounds(MENU_ITEM_PADDING, 0, 0.01, MENU_ITEM_WIDTH-(MENU_ITEM_PADDING*2), MENU_ITEM_HEIGHT-(MENU_ITEM_PADDING*4), 0.01), color={0.15,0.15,0.15,1}, text=consoleName, halign="left"}
    menuItem:addSubview(menuItemLabel)

    -- Make the menuItem interactive
    menuItem:setPointable(true)
    menuItem.onTouchUp = function(pointer)
      print("==================")
      print("Menu item clicked ")
      print("==================")
      self:listGames(gamePath)
    end

    menuItem.onPointerEntered = function(pointer)
      menuItem:setColor({0.9, 0.9, 1, 1})
    end

    menuItem.onPointerExited = function(pointer)
      menuItem:setColor({1, 1, 1, 1})
    end
    
    -- Why's this animation crashing? Also, is it possible to animate opacity?
    -- Needs to be in doWhenAwake()
    -- menuItem:addPropertyAnimation(ui.PropertyAnimation{
    --   path= "transform.matrix.translation.x",
    --   start_at = 0,
    --   from= -0.2,
    --   to=  0,
    --   duration = 2.0,
    --   repeats= false,
    --   autoreverses= false,
    --   easing= "quadIn",
    -- })

    -- Add the menuItem to the page
    page:addSubview(menuItem)
    
    i = i+1
  end
  p:close()
end

function GameBrowser:listGames(path)
  local depth = 1
  
  -- Create a "page"; the surface on which the menu items will be drawn.
  local page = ui.Surface(ui.Bounds(0,0,0, 0, 0, 0):move(depth/10, -depth/10, depth/10))
  page:setColor({0, 0, 1, 0.9})
  self:addSubview(page)

  -- Move the mainView up-and-back so that the newly created page always remains on "z=0"
  self.bounds:move(-depth/10, depth/10, -depth/10)
  self:markAsDirty("transform")

  -- Iterate through the folder
  local p = io.popen('find ' .. path .. '/* -maxdepth 0')
  local i=0
  for gamePath in p:lines() do
    print("The Game Browser found lines: "..gamePath)

    local infojsonstr = readfile(gamePath.."/info.json")
    if infojsonstr then
      print("GameBrowser found a json: "..infojsonstr)

      local game = {
          path= gamePath,
          meta= json.decode(infojsonstr),
          rom= gamePath.."/sor3.smd",
          --albumArt= ui.Asset.File(gamePath.."/albumArt.jpg"),
      }

      print("GAME NAME (from json):", game.meta.gameName)
      
      -- Create a menu item with bounds relative to its parent-to-be page
      local menuItem = ui.Surface(ui.Bounds(0, 0 - (i * MENU_ITEM_HEIGHT), 0.01,  MENU_ITEM_WIDTH, MENU_ITEM_HEIGHT, 0.01))
      menuItem:setColor({1, 1, 1, 1})

      -- Create a Label inside said menu item
      local menuItemLabel = Label{bounds=Bounds(MENU_ITEM_PADDING, 0, 0.01, MENU_ITEM_WIDTH-(MENU_ITEM_PADDING*2), MENU_ITEM_HEIGHT-(MENU_ITEM_PADDING*4), 0.01), color={0.15,0.15,0.15,1}, text=game.meta.gameName, halign="left"}
      menuItem:addSubview(menuItemLabel)

      -- Make the menuItem interactive
      menuItem:setPointable(true)
      menuItem.onTouchUp = function(pointer)
        print("==================")
        print("Menu item clicked ")
        print("==================")

        self:showGame(game)
      end

      menuItem.onPointerEntered = function(pointer)
        menuItem:setColor({0.9, 0.9, 1, 1})
      end

      menuItem.onPointerExited = function(pointer)
        menuItem:setColor({1, 1, 1, 1})
      end
      
      -- Why's this animation crashing? Also, is it possible to animate opacity?
      -- menuItem:addPropertyAnimation(ui.PropertyAnimation{
      --   path= "transform.matrix.translation.x",
      --   start_at = 0,
      --   from= -0.2,
      --   to=  0,
      --   duration = 2.0,
      --   repeats= false,
      --   autoreverses= false,
      --   easing= "quadIn",
      -- })

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
  local page = ui.Surface(ui.Bounds(0,0,0, 1, 1, 0.01):move(depth/10, -depth/10, depth/10))
  page:setColor({0.1, 0.1, 0.1, 1})
  page:setTexture(game.meta.albumArt)
  self:addSubview(page)

  -- Move the mainView up-and-back so that the newly created page always remains on "z=0"
  self.bounds:move(-depth/10, depth/10, -depth/10)
  self:markAsDirty("transform")

  local playButton = ui.Button(ui.Bounds(0, 0, 0,  1, 0.1, 0.1))
  playButton.label:setText("Play " .. game.meta.gameName)

  local gameInfo = Label{bounds=Bounds(0, 0, 0, 1.0, 0.05, 0.001), color={0.9,0.9,0.9,1}, text=game.meta.blurb, halign="left", wrap=true}



  playButton.onActivated = function()
    pretty.dump(game)
    self.emulator:loadGame(game.rom)
  end

  page:addSubview(playButton)

end



return GameBrowser