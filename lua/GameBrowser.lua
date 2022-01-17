local class = require('pl.class')
local json = require "allo.json"

class.GameBrowser(ui.View)

local BROWSER_WIDTH = 1.5
local MENU_ITEM_WIDTH = 1.5
local MENU_ITEM_HEIGHT = 0.15
local MENU_ITEM_PADDING = 0.02

mainView = ui.Surface(ui.Bounds(1.5, 1.5, 0,   BROWSER_WIDTH, MENU_ITEM_HEIGHT*3, 0.01))
mainView:setColor({1, 0, 0, 0})
mainView.grabbable = true

games = {}

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
  
  self:addSubview(mainView)

  self:_addSettingsButtons()

  self:_listFolderContents("roms", 0)
end

function GameBrowser:_addSettingsButtons()
  local quitButton = ui.Surface(ui.Bounds(0, 0.4, 0.01,  0.2, 0.2, 0.01));
  
  quitButton:setColor({0, 0, 0, 1})
  quitButton:setTexture(assets.quit)
  quitButton:setPointable(true)
  quitButton.onTouchUp = function(pointer)
    print("==========")
    print(" QUIT APP ")
    print("==========")
    self.app:quit()
  end

  mainView:addSubview(quitButton)


  local restartButton = ui.Surface(ui.Bounds(0.2, 0.4, 0.01,  0.2, 0.2, 0.01));
  
  restartButton:setColor({0, 0, 0, 1})
  restartButton:setTexture(assets.restart)
  restartButton:setPointable(true)
  restartButton.onTouchUp = function(pointer)
    print("==================")
    print(" RESTART EMULATOR ")
    print("==================")
    self.emulator:restart()
  end

  mainView:addSubview(restartButton)
end


function GameBrowser:_listFolderContents(path, depth)
  
  -- Create a "page"; the surface on which the menu items will be drawn.
  local page = ui.Surface(ui.Bounds(0,0,0, 0, 0, 0):move(depth/10, -depth/10, depth/10))
  page:setColor({0, 0, 1, 0.9})
  mainView:addSubview(page)

  -- Move the mainView up-and-back so that the newly created page always remains on "z=0"
  mainView.bounds:move(-depth/10, depth/10, -depth/10)


  -- Iterate through the folder
  local p = io.popen('find ' .. path .. '/* -maxdepth 0')
  local i=0
  for gamePath in p:lines() do
    print("Index: "..i)
    print("The Game Browser found lines: "..gamePath)

    local infojsonstr = readfile(gamePath.."/info.json")
    if infojsonstr then
      print("GameBrowser found a json: "..infojsonstr)

      local game = {
          path= gamePath,
          meta= json.decode(infojsonstr),
          rom= ui.Asset.File(gamePath.."/sor3.smd"),
          icon= ui.Asset.File(gamePath.."/sor3.jpg"),
      }
      games[gamePath] = game

      print("GAME NAME (from json):", game.meta.gameName)
    end


    -- TODO: substring magic to cut out the path from the label, just show the ultimate file- or folder name.
    --local labelString = string.substring(gamePath, )


    -- Create a menu item with bounds relative to its parent-to-be page
    local menuItem = ui.Surface(ui.Bounds(0, 0 - (i * MENU_ITEM_HEIGHT), 0.01, MENU_ITEM_WIDTH, MENU_ITEM_HEIGHT, 0.01))
    menuItem:setColor({1, 1, 1, 1})

    -- Create a Label inside said menu item
    local menuItemLabel = Label{bounds=Bounds(MENU_ITEM_PADDING, -MENU_ITEM_PADDING, 0.01, MENU_ITEM_WIDTH-(MENU_ITEM_PADDING*2), MENU_ITEM_HEIGHT-(MENU_ITEM_PADDING*2), 0.01), color={0.15,0.15,0.15,1}, text=gamePath, halign="left"}
    menuItem:addSubview(menuItemLabel)

    -- Make the menuItem interactive
    menuItem:setPointable(true)
    menuItem.onTouchUp = function(pointer)
      print("==================")
      print("Menu item clicked ")
      print("==================")

      self:_listFolderContents(gamePath, depth+1)
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
  p:close()
end


return GameBrowser