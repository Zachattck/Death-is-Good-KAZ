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

-- Ghost mode variables
local isGhostMode = false
local ghostTimer = 0
local ghostDuration = 5  -- Ghost mode lasts 5 seconds
local ghostQuad  -- Quad for the ghost sprite
local ghostSpeed = 20  -- Drastically reduced movement speed in ghost mode

-- Map boundaries
local mapWidth =  10000 -- Example map width
local mapHeight = 10000  -- Example map height

-- Gravity and movement variables
local gravity = 800  -- Increase gravity for faster falling
local jumpVelocity = -375  -- Lower jump height
local wallSlideGravity = 200  -- Reduced gravity while sliding down walls

player.velocityY = 0  -- Player's vertical velocity
player.isGrounded = false  -- Track whether the player is on the ground
player.isTouchingWall = false  -- Track whether the player is touching a wall
player.wallDirection = 0  -- Direction of the wall the player is sliding on

-- Jump Logic
local maxJumps = 1
local currentJumps = 0  -- Track how many times the player has jumped

-- Linear interpolation function for smooth teleportation
local function lerp(a, b, t)
    return a + (b - a) * t
end

-- Constrain the player within the map boundaries
local function constrainToBounds(x, y)
    x = math.max(0, math.min(mapWidth - player.width, x))  -- Ensure x is within bounds
    y = math.max(0, math.min(mapHeight - player.height, y))  -- Ensure y is within bounds
    return x, y
end

function player.load()
    player.x = 150
    player.y = 1015
    player.width = 32  
    player.height = 32
    player.speed = 100  -- Normal movement speed

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

    -- Load the ghost quad (11th column, 12th row)
    local ghostX = (11 - 1) * spriteSize  -- Convert 11th column to zero-indexed
    local ghostY = (12 - 1) * spriteSize  -- Convert 12th row to zero-indexed
    ghostQuad = love.graphics.newQuad(ghostX, ghostY, spriteSize, spriteSize, sheetWidth, sheetHeight)

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
    if isGhostMode then return false end  -- No collision in ghost mode

    -- Define the amount to shrink the player's collision box
    local shrinkWidth = 6  -- Reduce the hitbox width by 6 pixels (3 pixels on each side)
    local shrinkHeight = 4  -- Reduce the hitbox height by 4 pixels (2 pixels on top and bottom)

    -- Define player's bounds based on position, shrinking width and height
    local playerLeft = x + shrinkWidth / 2  -- Shrink from left
    local playerRight = x + player.width - shrinkWidth / 2  -- Shrink from right
    local playerTop = y + shrinkHeight / 2  -- Shrink from top
    local playerBottom = y + player.height - shrinkHeight / 2  -- Shrink from bottom

    -- Define wall bounds
    local wallLeft = wall.x
    local wallRight = wall.x + wall.width
    local wallTop = wall.y
    local wallBottom = wall.y + wall.height

    -- Check bounding box collision first (with adjusted player width/height)
    if playerRight > wallLeft and playerLeft < wallRight and
       playerBottom > wallTop and playerTop < wallBottom then
        -- Now check pixel-perfect collision using collisionMask
        local localPlayerX = math.floor(playerLeft - wall.x)
        local localPlayerY = math.floor(playerTop - wall.y)

        -- Check if the player's pixels are within the bounds of the wall image
        for px = 0, player.width - shrinkWidth - 1 do  -- Adjust pixel loop by shrink amount
            for py = 0, player.height - shrinkHeight - 1 do  -- Adjust pixel loop by shrink amount
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

    -- Handle smooth teleportation
    if isTeleporting then
        -- Use lerp for smooth movement and constrain the player to map bounds
        player.x = lerp(player.x, targetPosition.x, teleportSpeed * dt)
        player.y = lerp(player.y, targetPosition.y, teleportSpeed * dt)
        player.x, player.y = constrainToBounds(player.x, player.y)  -- Ensure player stays within map bounds

        -- Check if the player is close enough to the target position
        if math.abs(player.x - targetPosition.x) < 1 and math.abs(player.y - targetPosition.y) < 1 then
            isTeleporting = false  -- Stop teleporting once close enough
        end
        return
    end

    -- Handle ghost mode
    if isGhostMode then
        ghostTimer = ghostTimer - dt
        if ghostTimer <= 0 then
            isGhostMode = false
            player.exitGhostMode()  -- Handle exiting ghost mode
        end

        -- Omnidirectional movement in ghost mode using ghostSpeed
        if love.keyboard.isDown("a") then
            dx = -ghostSpeed * dt  -- Slower movement in ghost mode
            direction = -1  -- Facing left
        elseif love.keyboard.isDown("d") then
            dx = ghostSpeed * dt
            direction = 1  -- Facing right
        end
        if love.keyboard.isDown("w") then
            dy = -ghostSpeed * dt  -- Move up
        elseif love.keyboard.isDown("s") then
            dy = ghostSpeed * dt  -- Move down
        end

        -- Update player's position in ghost mode without resetting position
        player.x = player.x + dx
        player.y = player.y + dy
        player.x, player.y = constrainToBounds(player.x, player.y)  -- Ensure player stays within map bounds
        return  -- Skip gravity, collision, and regular movement
    end

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

function player.triggerGhostMode()
    -- Activate ghost mode without changing the player's position
    isGhostMode = true
    ghostTimer = ghostDuration  -- Set the ghost mode duration
end

function player.exitGhostMode()
    -- Find the nearest free space outside of the wall and teleport to it smoothly
    local teleportStep = 10  -- Step size to find a free space
    targetPosition.x = player.x
    targetPosition.y = player.y

    -- Check surrounding spaces and find a free position
    while player.checkCollision(targetPosition.x, targetPosition.y) do
        targetPosition.x = targetPosition.x + teleportStep
        targetPosition.y = targetPosition.y + teleportStep
    end

    -- Start teleporting smoothly and ensure the target position stays within the map bounds
    targetPosition.x, targetPosition.y = constrainToBounds(targetPosition.x, targetPosition.y)
    isTeleporting = true
end

function player.handlePlayerInput(key)
    if key == "space" and not isGhostMode and currentJumps < maxJumps then
        player.velocityY = jumpVelocity  -- Apply an upward force
        currentJumps = currentJumps + 1  -- Increment jump count
        player.isGrounded = false  -- Player is now in the air
    elseif key == "g" then
        player.triggerGhostMode()  -- Activate ghost mode when 'g' is pressed
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
    -- Use the ghost quad if in ghost mode, otherwise use the regular quads
    local currentQuad = isGhostMode and ghostQuad or quads[currentFrame]

    -- Scaling factors to scale down the sprite to player.width and player.height
    local scaleFactorX = player.width / 128  -- Original sprite width is 128
    local scaleFactorY = player.height / 128 -- Original sprite height is 128

    -- Flip the sprite if heading left
    local scaleX = direction * scaleFactorX  -- 1 when facing right, -1 when facing left
    local scaleY = scaleFactorY

    -- Set the origin to the center of the sprite
    local originX = 64  -- Half of the original sprite width (128 / 2)
    local originY = 64  -- Half of the original sprite height (128 / 2)

    -- Calculate the draw position (center of the player)
    local drawX = player.x + player.width / 2
    local drawY = player.y + player.height / 2

    -- Draw the player
    love.graphics.draw(
        spriteSheet, 
        currentQuad, 
        drawX, drawY, 
        0, 
        scaleX, scaleY,
        originX, originY
    )

    -- Draw the blood splatter effect
    bloodsplatter.draw()

    -- Draw blue overlay when in ghost mode
    if isGhostMode then
        love.graphics.setColor(0, 0, 1, 0.2)  -- Blue color with slight transparency

        -- Calculate the overlay dimensions relative to the player's position
        local overlayX = player.x - overlayWidth / 2  -- Center the overlay around the player
        local overlayY = player.y - overlayHeight / 2  -- Center the overlay around the player

        -- Draw the blue overlay relative to the player's position
        love.graphics.rectangle("fill", overlayX, overlayY, 2000, 2000)
        
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color after drawing
    end
end

function player.isInGhostMode()
    return isGhostMode
end


return player
