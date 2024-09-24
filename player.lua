local player = {}
local bloodsplatter = require("bloodsplatter")

local wall = {}
local imageData, collisionMask

local spriteSheet
local quads = {}
local currentFrame = 1
local frameTimer = 0
local frameSpeed = 0.1  -- Speed at which to switch frames
local totalFrames = 5  -- We're only looping the first 5 frames
local direction = 1  -- 1 for right, -1 for left
local state = "idle"  -- Can be "idle" or "moving"

function player.load()
    player.x = 960 
    player.y = 200
    player.width = 64  -- Reduced player size
    player.height = 64
    player.speed = 200

    -- Load the wall image
    wall.image = love.graphics.newImage("assets/mapPlatforms.png")
    wall.x = 300
    wall.y = 200
    wall.width = wall.image:getWidth()
    wall.height = wall.image:getHeight()

    -- Load the sprite sheet (2048x2048 with 128x128 sprites)
    spriteSheet = love.graphics.newImage("assets/van.png")

    -- Create quads for each sprite (128x128) in the sprite sheet
    local spriteSize = 128  -- Original size of each sprite in the sheet
    local sheetWidth, sheetHeight = spriteSheet:getWidth(), spriteSheet:getHeight()

    for y = 0, (sheetHeight / spriteSize) - 1 do
        for x = 0, (sheetWidth / spriteSize) - 1 do
            local quad = love.graphics.newQuad(
                x * spriteSize, y * spriteSize, 
                spriteSize, spriteSize, 
                sheetWidth, sheetHeight
            )
            table.insert(quads, quad)
        end
    end

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


function player.checkCollision(x, y)
    -- Get the current quad's width and height
    local _, _, quadWidth, quadHeight = quads[currentFrame]:getViewport()

    -- Define player's bounds based on current quad and position
    local playerLeft = x
    local playerRight = x + player.width
    local playerTop = y
    local playerBottom = y + player.height

    -- Define wall bounds
    local wallLeft = wall.x
    local wallRight = wall.x + wall.width
    local wallTop = wall.y
    local wallBottom = wall.y + wall.height

    -- Check for a collision between the player and the wall
    if playerRight > wallLeft and playerLeft < wallRight and
       playerBottom > wallTop and playerTop < wallBottom then
        return true
    else
        return false
    end
end

function player.update(dt)
    -- Handle player movement
    local dx, dy = 0, 0
    state = "idle"  -- Assume the player is idle unless they are moving

    if love.keyboard.isDown("left") then
        dx = -player.speed * dt
        direction = -1  -- Facing left
        state = "moving"
    elseif love.keyboard.isDown("right") then
        dx = player.speed * dt
        direction = 1  -- Facing right
        state = "moving"
    end
    if love.keyboard.isDown("up") then
        dy = -player.speed * dt
        state = "moving"
    elseif love.keyboard.isDown("down") then
        dy = player.speed * dt
        state = "moving"
    end

    -- Check for collision before moving the player
    if not player.checkCollision(player.x + dx, player.y + dy) then
        player.x = player.x + dx
        player.y = player.y + dy
    end

    -- Update the frame timer for animation only when moving
    if state == "moving" then
        frameTimer = frameTimer + dt
        if frameTimer >= frameSpeed then
            frameTimer = 0
            currentFrame = currentFrame + 1
            if currentFrame > totalFrames then
                currentFrame = 1  -- Loop back to the first frame of the first 5
            end
        end
    else
        -- If idle, always set to the first frame
        currentFrame = 1
    end

    bloodsplatter.update(dt)  -- Update the blood splatter
end

function player.handlePlayerInput(key)
    if key == "space" then
        player.triggerBloodSplatter()
    end
end

function player.triggerBloodSplatter()
    bloodsplatter.trigger(player.x + player.width / 2, player.y + player.height / 2)
end


function player.getWidth()
    return player.width
end

function player.getHeight()
    return player.height
end



function player.draw()
    -- Flip the quad horizontally when facing left
    local scaleX = direction  -- 1 when facing right, -1 when facing left
    local offsetX = 0
    if direction == -1 then
        offsetX = player.width  -- Offset to flip around the player's center
    end

    -- Draw the player with scaling to match the smaller size
    local scaleFactorX = player.width / 128  -- Scale down the width
    local scaleFactorY = player.height / 128 -- Scale down the height

    love.graphics.draw(
        spriteSheet, 
        quads[currentFrame], 
        player.x + offsetX, player.y, 
        0, 
        scaleX * scaleFactorX, scaleFactorY
    )

    -- Draw the wall image
    love.graphics.draw(wall.image, wall.x, wall.y)

    -- Draw the blood splatter effect
    bloodsplatter.draw()
end


return player
