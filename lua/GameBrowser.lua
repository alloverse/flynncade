local class = require('pl.class')
local pretty = require('pl.pretty')


class.GameBrowser(ui.View)

local MENU_ITEM_WIDTH = 1
local MENU_ITEM_HEIGHT = 0.15
local MENU_ITEM_PADDING = 0.02



function GameBrowser:_init(bounds, app, gameList)
  self:super(bounds)
  self.app = app
  self.gameList = gameList

  assets = {
    quit = ui.Asset.File("images/icon-quit.png"),
    restart = ui.Asset.File("images/icon-restart.png"),
    settings = ui.Asset.File("images/icon-settings.png"),
  }
  self.app.assetManager:add(assets)

  self.browserStack = ui.NavStack(ui.Bounds(0,0,0,1,1,1))
  self:addSubview(self.browserStack)

  self:_addSettingsButtons()

  self:listConsoles()
end

function GameBrowser:_addSettingsButtons()
  
  -- Right, vertical menu with quit & restart
  local settingsPanel = ui.Surface(ui.Bounds(0.5, 0.2, 0.01,  0, 0, 0.01))
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


  local settingsButton = ui.Surface(ui.Bounds(0.1, -0.4, 0.01,  0.2, 0.2, 0.01));
  local settingsButtonLabel = Label{bounds=Bounds(0.6, 0, 0.01, 1, 0.05, 0.01), color={1,1,1,0}, text="Settings", halign="left"}
  settingsButton:addSubview(settingsButtonLabel)

  settingsButton:setColor({0, 0, 0, 1})
  settingsButton:setTexture(assets.settings)
  settingsButton:setPointable(true)
  settingsButton.onPointerEntered = function(pointer)
    settingsButton:setColor({1, 1, 1, 1})
    settingsButtonLabel:setColor({1, 1, 1, 1})
  end
  settingsButton.onPointerExited = function(pointer)
    settingsButton:setColor({0, 0, 0, 1})
    settingsButtonLabel:setColor({1, 1, 1, 0})
  end
  settingsButton.onTouchUp = function(pointer)
    self:showAdvancedSettings()
  end

  settingsPanel:addSubview(settingsButton)
end

function GameBrowser:showAdvancedSettings()
  local page = ui.Surface(ui.Bounds(0,0,0, MENU_ITEM_WIDTH, 0.6, 0.03))
  page:setColor({1,1,1,1})
  self.browserStack:push(page)

  local frameskipLabel = page:addSubview(ui.Label{
    bounds= ui.Bounds(0,0.2,0,   MENU_ITEM_WIDTH-0.1, 0.06, 0),
    text= "Frameskip "..string.format("%.0f", self.onSetting("frameSkip")),
    color= {0,0,0,1},
    halign="left"
  })
  local frameskipSlider = page:addSubview(ui.Slider(ui.Bounds(0,0.1,0,  MENU_ITEM_WIDTH-0.1, 0.1, 0.1)))
  frameskipSlider:minValue(1)
  frameskipSlider:maxValue(10)
  frameskipSlider:currentValue(self.onSetting("frameSkip"))
  frameskipSlider.onValueChanged = function(s, v)
    v = math.floor(v)
    self.onSetting("frameSkip", v)
    frameskipLabel:setText("Frameskip "..string.format("%.0f", self.onSetting("frameSkip")))
  end

  local volumeLabel = page:addSubview(ui.Label{
    bounds= ui.Bounds(0,-0.1,0,   MENU_ITEM_WIDTH-0.1, 0.06, 0),
    text= "Sound volume "..string.format("%.0f", self.onSetting("soundVolume")*100).."%",
    color= {0,0,0,1},
    halign="left"
  })
  local volumeSlider = page:addSubview(ui.Slider(ui.Bounds(0,-0.2,0,  MENU_ITEM_WIDTH-0.1, 0.1, 0.1)))
  volumeSlider:minValue(0)
  volumeSlider:maxValue(1)
  volumeSlider:currentValue(self.onSetting("soundVolume"))
  volumeSlider.onValueChanged = function(s, v)
    self.onSetting("soundVolume", v)
    volumeLabel:setText("Sound volume "..string.format("%.0f", self.onSetting("soundVolume")*100).."%")
  end
end


function GameBrowser:listConsoles()

  -- Create a "page"; the surface on which the menu items will be drawn.
  local page = ui.Surface(ui.Bounds(0,0,0, 0, 0, 0)) --:move(depth/60, -depth/60, depth/60)
  page:setColor({0, 0, 1, 0.9})
  self.browserStack:push(page)


  -- Header + "Alloverse Arcade"
  local header = ui.Surface(ui.Bounds(0, 0.2, 0.015,  MENU_ITEM_WIDTH, 0.2, 0.03));
  header:setColor({0.60, 0.80, 0.95, 1})
  page:addSubview(header)

  local headerLabel = Label{bounds=Bounds(MENU_ITEM_PADDING, 0, 0.01, MENU_ITEM_WIDTH-(MENU_ITEM_PADDING*2), MENU_ITEM_HEIGHT-(MENU_ITEM_PADDING*4), 0.01), color={1,1,1,1}, text="Choose Console", halign="left"}
  header:addSubview(headerLabel)


  -- Look through the console folders
  local i=0
  for _, console in pairs(self.gameList.consoles) do

    -- Create a menu item with bounds relative to its parent-to-be page
    local menuItem = ui.Surface(ui.Bounds(
                                          0, 
                                          0 - (i * MENU_ITEM_HEIGHT), 
                                          0.01, 
                                          MENU_ITEM_WIDTH, 
                                          MENU_ITEM_HEIGHT, 
                                          0.01
    ))

    menuItem:setColor({1, 1, 1, 1})

    -- Create a Label inside said menu item
    local menuItemLabel = Label{bounds=Bounds(MENU_ITEM_PADDING, 0, 0.001, MENU_ITEM_WIDTH-(MENU_ITEM_PADDING*2), MENU_ITEM_HEIGHT-(MENU_ITEM_PADDING*4), 0.001), color={0.15,0.15,0.15,1}, text=console.name, halign="left"}
    menuItem:addSubview(menuItemLabel)

    -- Make the menuItem interactive
    menuItem:setPointable(true)
    menuItem.onTouchUp = function(pointer)
      self:listGames(console)
    end

    menuItem.onPointerEntered = function(pointer)
      menuItem:setColor({0.83, 0.89, 0.93, 1})
    end

    menuItem.onPointerExited = function(pointer)
      menuItem:setColor({1, 1, 1, 1})
    end

    -- Add the menuItem to the page
    page:addSubview(menuItem)
    
    i = i+1
  end
end

function GameBrowser:listGames(console)
  -- Create a "page"; the surface on which the menu items will be drawn.
  local page = ui.Surface(ui.Bounds(0,0,0, 0, 0, 0)) --:move(depth/60, -depth/60, depth/60)
  page:setColor({0, 0, 1, 0.9})

  self.browserStack:push(page)

  -- Header + "Alloverse Arcade"
  local header = ui.Surface(ui.Bounds(0, 0.2, 0.01,  MENU_ITEM_WIDTH, 0.2, 0.03));
  header:setColor({0.60, 0.80, 0.95, 1})
  page:addSubview(header)

  local headerLabel = Label{bounds=Bounds(MENU_ITEM_PADDING, 0, 0.01, MENU_ITEM_WIDTH-(MENU_ITEM_PADDING*2), MENU_ITEM_HEIGHT-(MENU_ITEM_PADDING*4), 0.01), color={1,1,1,1}, text="Choose Game", halign="left"}
  header:addSubview(headerLabel)

  -- Iterate through the folder
  local i=0
  for _, game in pairs(console.games) do
    self.app.assetManager:add(game.boxArt, true)
    self.app.assetManager:add(game.cabinetTexture, true)

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
      menuItem:setColor({0.83, 0.89, 0.93, 1})
    end

    menuItem.onPointerExited = function(pointer)
      menuItem:setColor({1, 1, 1, 1})
    end
    
    -- Add the menuItem to the page
    page:addSubview(menuItem)

    i = i+1
  end
end

function GameBrowser:showGame(game)
  local depth = 2

  -- Create a "page"; the surface on which the menu items will be drawn.
  local page = ui.Surface(ui.Bounds(
                                    0, 
                                    0,
                                    0.01, 
                                    1, 
                                    MENU_ITEM_HEIGHT*4, 
                                    0.01)) --:move(depth/60, -depth/60, depth/60)
  page:setColor({1, 1, 1, 1})
  self.browserStack:push(page)

  -- Header w/ game title & box art
  local header = ui.Surface(ui.Bounds(0, 0.2, 0.01,  MENU_ITEM_WIDTH, 0.2, 0.03));
  header:setColor({0.60, 0.80, 0.95, 1})
  page:addSubview(header)

  local gameTitle = Label{bounds=Bounds(0.10,
                                        0,
                                        0.01, 
                                        MENU_ITEM_WIDTH - 0.15 - MENU_ITEM_PADDING*2,
                                        MENU_ITEM_HEIGHT-(MENU_ITEM_PADDING*4),
                                        0.01),
                                        color={1,1,1,1}, text=game.meta.gameName, halign="left", fitToWidth=MENU_ITEM_WIDTH - 0.15 - MENU_ITEM_PADDING*2}
  header:addSubview(gameTitle)


  local gameBoxArt = Surface(ui.Bounds(-MENU_ITEM_WIDTH/2 + 0.075 + MENU_ITEM_PADDING, 
                                        0,  
                                        0.001, 
                                        0.15, 0.15, 0.001))
  gameBoxArt:setTexture(game.boxArt)
  header:addSubview(gameBoxArt)


  -- Game info blurb + "play" button
  local gameInfo = Label{bounds=Bounds(
                                          0,
                                          0.1 - MENU_ITEM_PADDING,
                                          0,
                                          MENU_ITEM_WIDTH-MENU_ITEM_PADDING*4,
                                          0.03, --height/fontsize
                                          0.001
                                      ), color={0.1,0.1,0.1,1}, text=game.meta.blurb, halign="left", valign="top", wrap=true}
  page:addSubview(gameInfo)

  local playButton = ui.Button(ui.Bounds(0, -0.2, 0, MENU_ITEM_WIDTH-MENU_ITEM_PADDING*2, 0.1, 0.1))
  playButton:setColor({0.83, 0.53, 0.78, 1})
  playButton.label:setText("Play")

  playButton.onActivated = function()
    pretty.dump(game)
    self.onGameChosen(game)
  end

  page:addSubview(playButton)

end



return GameBrowser
