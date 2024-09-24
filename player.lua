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

-- Gravity and movement variables
local gravity = 800  -- Increase gravity for faster falling
local jumpVelocity = -375  -- Lower jump height
local wallSlideGravity = 200  -- Reduced gravity while sliding down walls
player.velocityY = 0  -- Player's vertical velocity
player.isGrounded = false  -- Track whether the player is on the ground
player.isTouchingWall = false  -- Track whether the player is touching a wall
player.wallDirection = 0  -- Direction of the wall the player is sliding on

--Jump Logic
local maxJumps = 1
local currentJumps = 0  -- Track how many times the player has jumped

function player.load()
    player.x = 150
    player.y = 1015
    player.width = 32  
    player.height = 32
    player.speed = 100  -- Movement speed

    -- Load the wall image
    wall.image = love.graphics.newImage("assets/mapPlatforms.png")
    wall.x = 0
    wall.y = 0
    wall.width = wall.image:getWidth()
    wall.height = wall.image:getHeight()

    -- Load the sprite sheet (2048x2048 with 128x128 sprites)
    spriteSheet = love.graphics.newImage("assets/van.png")

    -- Create quads for each sprite (128x128) in the sprite sheet
    local spriteSize = 128
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

    -- Amount to shrink the player's collision width
    local collisionShrinkWidth = 10  -- Total amount to shrink by
    local halfShrink = collisionShrinkWidth / 2  -- Split shrink on both sides

    -- Define player's bounds based on current quad and position, shrinking width
    local playerLeft = x + halfShrink  -- Shrink from left
    local playerRight = x + player.width - halfShrink  -- Shrink from right
    local playerTop = y
    local playerBottom = y + player.height

    -- Define wall bounds
    local wallLeft = wall.x
    local wallRight = wall.x + wall.width
    local wallTop = wall.y
    local wallBottom = wall.y + wall.height

    -- Check bounding box collision first (with adjusted player width)
    if playerRight > wallLeft and playerLeft < wallRight and
       playerBottom > wallTop and playerTop < wallBottom then
        -- Now check pixel-perfect collision using collisionMask
        local localPlayerX = math.floor(playerLeft - wall.x)
        local localPlayerY = math.floor(playerTop - wall.y)

        -- Check if the player's pixels are within the bounds of the wall image
        for px = 0, player.width - 1 do
            for py = 0, player.height - 1 do
                local maskX = localPlayerX + px
                local maskY = localPlayerY + py

                -- Make sure we're within the bounds of the wall image
                if maskX >= 0 and maskY >= 0 and maskX < wall.width and maskY < wall.height then
                    if collisionMask[maskX] and collisionMask[maskX][maskY] then
                        return true -- Collision detected with non-transparent pixel
                    end
                end
            end
        end
    end

    return false -- No collision detected
end

function player.update(dt)
    local dx, dy = 0, 0
    state = "idle"  -- Assume the player is idle unless they are moving

    -- Horizontal movement
    if love.keyboard.isDown("a") then
        dx = -player.speed * dt
        direction = -1  -- Facing left
        state = "moving"
    elseif love.keyboard.isDown("d") then
        dx = player.speed * dt
        direction = 1  -- Facing right
        state = "moving"
    end

    -- Apply gravity if the player is not grounded
    if not player.isGrounded then
        if player.isTouchingWall then
            -- If the player is touching a wall, reduce the gravity effect for wall sliding
            player.velocityY = player.velocityY + wallSlideGravity * dt
        else
            -- Normal gravity when not sliding on a wall
            player.velocityY = player.velocityY + gravity * dt
        end
    end

    dy = player.velocityY * dt  -- Apply vertical velocity

    -- Horizontal movement first (independent from ground collision)
    local canMoveHorizontally = not player.checkCollision(player.x + dx, player.y)
    if canMoveHorizontally then
        player.x = player.x + dx
    end

    -- Vertical collision check (for gravity and jumping)
    local canMoveVertically = not player.checkCollision(player.x, player.y + dy)
    if canMoveVertically then
        -- Apply vertical movement
        player.y = player.y + dy
        player.isGrounded = false  -- Player is in the air if no collision with ground
    else
        -- Stop vertical movement when hitting the ground
        if dy > 0 then  -- If the player is falling
            player.velocityY = 0  -- Stop falling
            player.isGrounded = true  -- Player is on the ground
            currentJumps = 0  -- Reset jump count when the player is grounded
        end
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
    if key == "space" and currentJumps < maxJumps then
        player.velocityY = jumpVelocity  -- Apply an upward force
        currentJumps = currentJumps + 1  -- Increment jump count
        player.isGrounded = false  -- Player is now in the air
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
