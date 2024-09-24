-- camera.lua
local Camera = {}
Camera.__index = Camera

function Camera:new()
    local cam = {}
    setmetatable(cam, Camera)
    cam.x = 0
    cam.y = 0
    return cam
end

function Camera:lookAt(x, y)
    self.x = x
    self.y = y
end

function Camera:attach()
    love.graphics.push()
    love.graphics.translate(-self.x + love.graphics.getWidth() / 2, -self.y + love.graphics.getHeight() / 2)
end

function Camera:detach()
    love.graphics.pop()
end

-- Return a function that creates a new camera instance
return function() 
    return Camera:new() 
end
