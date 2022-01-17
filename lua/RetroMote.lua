local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")

local snesmote_left = app.assetManager:add(ui.Asset.File("models/snesmote-left.glb"), true)
local snesmote_right = app.assetManager:add(ui.Asset.File("models/snesmote-right.glb"), true)

local alloToDeviceIdMap = {
    ["hand/left-x"]= "y",
    ["hand/left-y"]= "x",
    ["hand/left-thumbstick"] = "select",
    ["hand/left-trigger"]= "l",
    ["hand/left-menu"]= "start",
    ["hand/right-a"]= "a",
    ["hand/right-b"]= "b",
    ["hand/right-thumbstick"] = "start",
    ["hand/right-trigger"]= "r",
}

local keebToDeviceIdMap = {
    ["w"]= "up",
    ["s"]= "down",
    ["a"]= "left",
    ["d"]= "right",
    ["tab"]= "select",
    ["return"]= "start",
    ["i"]= "x",
    ["j"]= "y",
    ["k"]= "b",
    ["l"]= "a",
    ["u"]= "l",
    ["o"]= "r",

    ["space"]= "b",
}

local retroDeviceIdMap = {
    "b", "y", "select", "start", "up", "down", "left", "right",
    "a", "x", "l", "r", "l2", "r2", "l3", "r3"
}

class.RetroMote(ui.View)

function RetroMote:_init(bounds, playerIndex)
    self:super(bounds)
    self.playerIndex = playerIndex
    self.controllerStates = {false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false}

    self.backplate = self:addSubview(ui.Surface(ui.Bounds(0,0,0,   0.20, 0.18, 0.05):rotate(-3.14/3, 1,0,0):move(0,0,-0.07)))
    self.backplate:setColor({0.4,0.4,0.4,1.0})
    self.playerLabel = self.backplate:addSubview(ui.Label{
        bounds= ui.Bounds(0,-0.07,0,  0.4, 0.020, 0.01),
        text= "Player "..tostring(playerIndex),
        color= {0.5, 0.1, 0.1, 1.0},
    })

    self.leftPart = self:addSubview(RetroMotePart(Bounds(-0.05, 0.03, -0.09,   0.08, 0.06, 0.06), snesmote_left))
    self.leftPart:setGrabbable(true, {
      capture_controls= {"trigger", "thumbstick", "x", "y", "menu"},
      target_hand_transform= mat4.identity()
    })

    self.rightPart = self:addSubview(RetroMotePart(Bounds(0.05, 0.03, -0.09,   0.08, 0.06, 0.06), snesmote_right))
    self.rightPart:setGrabbable(true, {
      capture_controls= {"trigger", "thumbstick", "a", "b" },
      target_hand_transform= mat4.identity()
    })

    self.useKeebButton = self.backplate:addSubview(ui.Button(Bounds(0,-0.035,0,   0.1, 0.03, 0.02)))
    self.useKeebButton:setColor({0.45, 0.45, 0.45, 1.0})
    self.useKeebButton.label.bounds.size.height = 0.013
    self.useKeebButton.label:setText("Use keyboard")
    self.useKeebButton.label:setColor({0.5, 0.1, 0.1, 1.0})
    local retromote = self
    self.useKeebButton.onActivated = function(hand)
        retromote:askToFocus(hand:getAncestor())
    end
    self.useKeebButton:doWhenAwake(function()
        print("retromote", retromote.entity.id, "button", self.useKeebButton.entity.id)
    end)
end


function RetroMote:specification()
    local mySpec = tablex.union(View.specification(self), {
        focus = {
            type= "key"
        },
    })
    return mySpec
end

function RetroMote:onFocus(by)
    View.onFocus(self, by)
    self.playerLabel:setText("Player "..tostring(self.playerIndex)..(by and " (keys)" or ""))
    return true
end

function RetroMote:onKeyDown(code, scancode, repetition)
    if repetition then return end
    local retrobutton = keebToDeviceIdMap[code]
    if not retrobutton then return end
    local buttonId = tablex.find(retroDeviceIdMap, retrobutton)
    self.controllerStates[buttonId] = true
end

function RetroMote:onKeyUp(code, scancode)
    local retrobutton = keebToDeviceIdMap[code]
    if not retrobutton then return end
    local buttonId = tablex.find(retroDeviceIdMap, retrobutton)
    self.controllerStates[buttonId] = false
end


function RetroMote:onInteraction(inter, body, sender)
    View.onInteraction(self, inter, body, sender)
    if body[1] == "keydown" then
        self:onKeyDown(body[2], body[3], body[4])
    elseif body[1] == "keyup" then
        self:onKeyUp(body[2], body[3])
    end
end

----- input


class.RetroMotePart(ui.ModelView)

function RetroMotePart:onCapturedButtonPressed(hand, handName, buttonName)
    local alloname = handName.."-"..buttonName
    local retrobutton = alloToDeviceIdMap[alloname]
    if not retrobutton then return end
    local buttonId = tablex.find(retroDeviceIdMap, retrobutton)
    self.superview.controllerStates[buttonId] = true
end
function RetroMotePart:onCapturedButtonReleased(hand, handName, buttonName)
    local alloname = handName.."-"..buttonName
    local retrobutton = alloToDeviceIdMap[alloname]
    if not retrobutton then return end
    local buttonId = tablex.find(retroDeviceIdMap, retrobutton)
    self.superview.controllerStates[buttonId] = false
end
function RetroMotePart:onCapturedAxis(hand, handName, axisName, data)
    if handName == "hand/left" and axisName == "thumbstick" then
        local up = tablex.find(retroDeviceIdMap, "up")
        local down = tablex.find(retroDeviceIdMap, "down")
        local left = tablex.find(retroDeviceIdMap, "left")
        local right = tablex.find(retroDeviceIdMap, "right")
        local x, y = unpack(data)
        if y > 0.1 then 
            self.superview.controllerStates[up] = true 
            self.superview.controllerStates[down] = false
        elseif y < -0.2 then
            self.superview.controllerStates[up] = false
            self.superview.controllerStates[down] = true
        else
            self.superview.controllerStates[up] = false
            self.superview.controllerStates[down] = false
        end
        if x > 0.1 then 
            self.superview.controllerStates[left] = false
            self.superview.controllerStates[right] = true
        elseif x < -0.2 then
            self.superview.controllerStates[left] = true 
            self.superview.controllerStates[right] = false
        else
            self.superview.controllerStates[left] = false 
            self.superview.controllerStates[right] = false
        end
    end
end

function RetroMotePart:onGrabEnded(hand)
    self:markAsDirty("transform")
end

return RetroMote
