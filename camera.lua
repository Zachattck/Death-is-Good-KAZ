-- camera.lua
local Camera = {}
Camera.__index = Camera

function Camera:new()
    local cam = {}
    setmetatable(cam, Camera)
    cam.x = 0
    cam.y = 0
    cam.zoom = 1  -- Add zoom level (1 means no zoom, > 1 zooms in, < 1 zooms out)
    return cam
end

function Camera:lookAt(x, y)
    self.x = x
    self.y = y
end

function Camera:setZoom(zoomLevel)
    self.zoom = zoomLevel
end

function Camera:attach()
    love.graphics.push()  -- Push current transformation onto the stack
    love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    love.graphics.scale(self.zoom, self.zoom)  -- Apply zoom before translation
    love.graphics.translate(-self.x, -self.y)
end

function Camera:detach()
    love.graphics.pop()  -- Pop the transformation off the stack
end

return function() 
    return Camera:new() 
end
