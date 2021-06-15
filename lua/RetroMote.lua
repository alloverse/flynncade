local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")


local alloToDeviceIdMap = {
    ["hand/left-x"]= "start",
    ["hand/left-y"]= "select",
    ["hand/left-trigger"]= "l",
    ["hand/right-a"]= "a",
    ["hand/right-b"]= "b",
    ["hand/right-trigger"]= "r",
}

local retroDeviceIdMap = {
    "b", "y", "select", "start", "up", "down", "left", "right",
    "a", "x", "l", "r", "l2", "r2", "l3", "r3"
}

class.RetroMote(ui.Cube)

function RetroMote:_init(bounds, playerIndex)
    self:super(bounds)
    self.playerIndex = playerIndex
    self.controllerStates = {false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false}
    self:setGrabbable(true, {
        capture_controls= {"trigger", "thumbstick", "a", "b", "x", "y", "menu"}
    })
end

----- input

function RetroMote:onCapturedButtonPressed(hand, handName, buttonName)
    local alloname = handName.."-"..buttonName
    local retrobutton = alloToDeviceIdMap[alloname]
    if not retrobutton then return end
    local buttonId = tablex.find(retroDeviceIdMap, retrobutton)
    self.controllerStates[buttonId] = true
end
function RetroMote:onCapturedButtonReleased(hand, handName, buttonName)
    local alloname = handName.."-"..buttonName
    local retrobutton = alloToDeviceIdMap[alloname]
    if not retrobutton then return end
    local buttonId = tablex.find(retroDeviceIdMap, retrobutton)
    self.controllerStates[buttonId] = false
end
function RetroMote:onCapturedAxis(hand, handName, axisName, data)
    if handName == "hand/left" and axisName == "thumbstick" then
        local up = tablex.find(retroDeviceIdMap, "up")
        local down = tablex.find(retroDeviceIdMap, "down")
        local left = tablex.find(retroDeviceIdMap, "left")
        local right = tablex.find(retroDeviceIdMap, "right")
        local x, y = unpack(data)
        if y > 0.1 then 
            self.controllerStates[up] = true 
            self.controllerStates[down] = false
        elseif y < -0.1 then
            self.controllerStates[up] = false
            self.controllerStates[down] = true
        else
            self.controllerStates[up] = false
            self.controllerStates[down] = false
        end
        if x > 0.1 then 
            self.controllerStates[left] = false
            self.controllerStates[right] = true
        elseif x < -0.1 then
            self.controllerStates[left] = true 
            self.controllerStates[right] = false
        else
            self.controllerStates[left] = false 
            self.controllerStates[right] = false
        end
    end
end

return RetroMote
