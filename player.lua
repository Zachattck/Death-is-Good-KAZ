local player = {}
local bloodsplatter = require("bloodsplatter")

local wall = {}  -- Table to hold wall properties
local imageData, collisionMask  -- To hold image data and collision mask for pixel-perfect collision

function player.load()
    player.x = 100
    player.y = 100
    player.width = 50
    player.height = 50
    player.speed = 200

    -- Load the wall image
    wall.image = love.graphics.newImage("assets/mapPlatforms.png")
    wall.x = 300
    wall.y = 200
    wall.width = wall.image:getWidth()
    wall.height = wall.image:getHeight()

    -- Load the wall image data and create the collision mask
    imageData = love.image.newImageData("assets/mapPlatforms.png")
    collisionMask = {}
    for x = 0, imageData:getWidth() - 1 do
        collisionMask[x] = {}
        for y = 0, imageData:getHeight() - 1 do
            local r, g, b, a = imageData:getPixel(x, y)
            collisionMask[x][y] = a > 0 -- True if the pixel is not transparent
        end
    end

    bloodsplatter.load()  -- Load the blood splatter effect
end

-- Function to check if the player is colliding with the non-alpha part of the wall
function player.checkCollision(x, y)
    local localX = math.floor(x - wall.x)
    local localY = math.floor(y - wall.y)

    -- Ensure we're within the bounds of the wall
    if localX >= 0 and localY >= 0 and localX < wall.width and localY < wall.height then
        return collisionMask[localX][localY] -- True if colliding with non-transparent part
    else
        return false
    end
end

function player.update(dt)
    -- Handle player movement
    local dx, dy = 0, 0
    if love.keyboard.isDown("left") then
        dx = -player.speed * dt
    elseif love.keyboard.isDown("right") then
        dx = player.speed * dt
    end
    if love.keyboard.isDown("up") then
        dy = -player.speed * dt
    elseif love.keyboard.isDown("down") then
        dy = player.speed * dt
    end

    -- Check for collision before moving the player
    if not player.checkCollision(player.x + dx, player.y + dy) then
        player.x = player.x + dx
        player.y = player.y + dy
    end

    bloodsplatter.update(dt)  -- Update the blood splatter
end

function player.handlePlayerInput(key)
    if key == "space" then
        player.triggerBloodSplatter()
    end
end

-- Function to trigger the blood splatter effect
function player.triggerBloodSplatter()
    bloodsplatter.trigger(player.x + player.width / 2, player.y + player.height / 2)
end

function player.draw()
    -- Draw player as a rectangle (can be replaced with an image if needed)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)

    -- Draw the wall image
    love.graphics.draw(wall.image, wall.x, wall.y)

    -- Draw the blood splatter effect
    bloodsplatter.draw()
end

return player
