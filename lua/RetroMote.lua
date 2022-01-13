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

local retroDeviceIdMap = {
    "b", "y", "select", "start", "up", "down", "left", "right",
    "a", "x", "l", "r", "l2", "r2", "l3", "r3"
}

class.RetroMote(ui.View)

function RetroMote:_init(bounds, playerIndex)
    self:super(bounds)
    self.playerIndex = playerIndex
    self.controllerStates = {false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false}

    self.leftPart = RetroMotePart(Bounds(-0.05, 0, 0, 0.1,0.1,0.1), snesmote_left)
    self.leftPart:setGrabbable(true, {
      capture_controls= {"trigger", "thumbstick", "x", "y", "menu"},
      target_hand_transform= mat4.identity()
    })
    self:addSubview(self.leftPart)

    self.rightPart = RetroMotePart(Bounds(0.05, 0, 0, 0.1,0.1,0.1), snesmote_right)
    self.rightPart:setGrabbable(true, {
      capture_controls= {"trigger", "thumbstick", "a", "b" },
      target_hand_transform= mat4.identity()
    })
    self:addSubview(self.rightPart)
end

----- input


class.RetroMotePart(ui.ModelView)

function RetroMotePart:onCapturedButtonPressed(hand, handName, buttonName)
    local alloname = handName.."-"..buttonName
    local retrobutton = alloToDeviceIdMap[alloname]
    print("pressed", alloname, "which corresponds to", retrobutton)
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
        elseif y < -0.1 then
            self.superview.controllerStates[up] = false
            self.superview.controllerStates[down] = true
        else
            self.superview.controllerStates[up] = false
            self.superview.controllerStates[down] = false
        end
        if x > 0.1 then 
            self.superview.controllerStates[left] = false
            self.superview.controllerStates[right] = true
        elseif x < -0.1 then
            self.superview.controllerStates[left] = true 
            self.superview.controllerStates[right] = false
        else
            self.superview.controllerStates[left] = false 
            self.superview.controllerStates[right] = false
        end
    end
end

return RetroMote
