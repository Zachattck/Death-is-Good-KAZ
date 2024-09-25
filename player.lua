local player = {}
local bloodsplatter = require("bloodsplatter")

local wall = {}
local imageData, imageDataLadders, collisionMask

local spriteSheet
local quads = {}
local currentFrame = 1
local frameTimer = 0
local frameSpeed = 0.1  -- Speed at which to switch frames
local totalFrames = 5  -- We're only looping the first 5 frames
local direction = 1  -- 1 for right, -1 for left
local state = "idle"  -- Can be "idle" or "moving"

-- Flicker parameters
local flickerTimer = 0
local flickerInterval = 0.01
local flickerStrength = 1  -- Adjusted strength to match old logic
local flickerOffset = 0

-- Ghost mode variables
local isGhostMode = false
local ghostTimer = 0
local ghostDuration = 5  -- Ghost mode lasts 5 seconds
local ghostQuad  -- Quad for the ghost sprite
local ghostSpeed = 20  -- Drastically reduced movement speed in ghost mode
local teleportSpeed = 10  -- Speed of teleportation

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

-- Ladder Logic
local LADDER = 2
local player = {}
local ladderSpriteSheet
local ladderQuad

player.isOnLadder = false
-- Teleport variables
local targetPosition = { x = 0, y = 0 }  -- Initialize targetPosition
local isTeleporting = false  -- Initialize teleporting flag

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
    print("Loading player...")  -- Debug log
    player.x = 1
    player.y = 1
    player.width = 32
    player.height = 32
    player.speed = 100  -- Movement speed

    -- Load the wall image
    wall.image = love.graphics.newImage("assets/mapPlatforms.png")
    wall.x = 0
    wall.y = 0
    wall.width = wall.image:getWidth()
    wall.height = wall.image:getHeight()

    -- Load the sprite sheet (128x128 sprites)
    spriteSheet = love.graphics.newImage("assets/van.png")
    local spriteSize = 128
    local sheetWidth, sheetHeight = spriteSheet:getWidth(), spriteSheet:getHeight()

    -- Create quads for each sprite (128x128) in the sprite sheet
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

    -- Load ladder climbing quads (2nd to 4th row, 6th to 8th row in 8th column)
    ladderQuads = {}  -- Reset or initialize ladderQuads

    -- Add quads from the 8th column and rows 2-4 and 6-8
    local column = 7  -- 8th column, zero-indexed
    local rowsToUse = {1, 2, 3, 5, 6, 7}  -- Rows 2-4 and 6-8, zero-indexed

    for _, row in ipairs(rowsToUse) do
        local quad = love.graphics.newQuad(
            column * spriteSize, row * spriteSize, 
            spriteSize, spriteSize, 
            sheetWidth, sheetHeight
        )
        table.insert(ladderQuads, quad)
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

-- Collision logic to detect collisio
-- Collision logic to detect collisions with walls
function player.checkCollision(x, y)
    if isGhostMode then return false end  -- No collision in ghost mode

    -- Shrink player's hitbox for collision
    local shrinkWidth = 6
    local shrinkHeight = 4

    -- Player's bounding box
    local playerLeft = x + shrinkWidth / 2
    local playerRight = x + player.width - shrinkWidth / 2
    local playerTop = y + shrinkHeight / 2
    local playerBottom = y + player.height - shrinkHeight / 2

    -- Wall bounding box
    local wallLeft = wall.x
    local wallRight = wall.x + wall.width
    local wallTop = wall.y
    local wallBottom = wall.y + wall.height

    -- Check if the player is within the wall bounds (basic AABB collision check)
    if playerRight > wallLeft and playerLeft < wallRight and
       playerBottom > wallTop and playerTop < wallBottom then
        -- Now check pixel-perfect collision using collisionMask
        local localPlayerX = math.floor(playerLeft - wall.x)
        local localPlayerY = math.floor(playerTop - wall.y)

        -- Iterate over player's pixels
        for px = 0, player.width - shrinkWidth - 1 do
            for py = 0, player.height - shrinkHeight - 1 do
                local maskX = localPlayerX + px
                local maskY = localPlayerY + py

                if maskX >= 0 and maskY >= 0 and maskX < wall.width and maskY < wall.height then
                    if collisionMask[maskX] and collisionMask[maskX][maskY] then
                        return true -- Collision detected with non-transparent pixel
                    end
                end
            end
        end
    end

    return false -- No collision
end

-- Check if the player is colliding with a ladder
function player.checkLadderCollision(x, y)
    local playerLeft = x
    local playerRight = x + player.width
    local playerTop = y
    local playerBottom = y + player.height

    -- Check if the player is within the bounds of the ladder image
    for px = 0, player.width - 1 do
        for py = 0, player.height - 1 do
            local maskX = math.floor(playerLeft + px)
            local maskY = math.floor(playerTop + py)

            if maskX >= 0 and maskY >= 0 and maskX < imageData:getWidth() and maskY < imageData:getHeight() then
                local maskValue = collisionMask[maskX][maskY]
                if maskValue == LADDER then
                    return true
                end
            end
        end
    end

    return false
end

-- Function to handle all player movement input
function player.update(dt)
    local dx, dy = 0, 0
    state = "idle"  -- Assume the player is idle unless they are moving

    -- Handle teleportation, skipping other movement during teleport
    if isTeleporting then
        player.x = lerp(player.x, targetPosition.x, teleportSpeed * dt)
        player.y = lerp(player.y, targetPosition.y, teleportSpeed * dt)
        player.x, player.y = constrainToBounds(player.x, player.y)

        -- Stop teleporting once close enough to the target position
        if math.abs(player.x - targetPosition.x) < 1 and math.abs(player.y - targetPosition.y) < 1 then
            isTeleporting = false
        end
        return
    end

    -- Handle ghost mode movement
    if isGhostMode then
        -- Omnidirectional movement in ghost mode
        if love.keyboard.isDown("a") then
            dx = -ghostSpeed * dt
            direction = -1
        elseif love.keyboard.isDown("d") then
            dx = ghostSpeed * dt
            direction = 1
        end
        if love.keyboard.isDown("w") then
            dy = -ghostSpeed * dt  -- Move up
        elseif love.keyboard.isDown("s") then
            dy = ghostSpeed * dt  -- Move down
        end

        -- Apply the ghost mode movement and skip other updates
        player.x = player.x + dx
        player.y = player.y + dy
        player.x, player.y = constrainToBounds(player.x, player.y)
        return
    end

    -- Handle horizontal movement
    if love.keyboard.isDown("a") then
        dx = -player.speed * dt
        direction = -1
        state = "moving"
    elseif love.keyboard.isDown("d") then
        dx = player.speed * dt
        direction = 1
        state = "moving"
    end

    -- Apply gravity if the player is not grounded
    if not player.isGrounded then
        if player.isTouchingWall then
            player.velocityY = player.velocityY + wallSlideGravity * dt  -- Wall sliding gravity
        else
            player.velocityY = player.velocityY + gravity * dt  -- Normal gravity
        end
        dy = player.velocityY * dt
    end

    -- Horizontal movement first (independent from ground collision)
    local canMoveHorizontally = not player.checkCollision(player.x + dx, player.y)
    if canMoveHorizontally then
        player.x = player.x + dx
    end

    -- Vertical collision check (for gravity and jumping)
    local canMoveVertically = not player.checkCollision(player.x, player.y + dy)
    if canMoveVertically then
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

    -- Update animation frames if the player is climbing
    if player.isOnLadder then
        frameTimer = frameTimer + dt
        if frameTimer >= frameSpeed then
            frameTimer = 0
            currentFrame = currentFrame + 1
            if currentFrame > #ladderQuads then
                currentFrame = 1  -- Loop back to the first frame
            end
        end
    end
end

-- Function to handle key presses (like jumping, ghost mode)
function player.handleKeyPress(key)
    if key == "space" and player.isGrounded and currentJumps < maxJumps then
        player.velocityY = jumpVelocity  -- Apply jump force
        currentJumps = currentJumps + 1  -- Track jumps
        player.isGrounded = false
    elseif key == "g" then
        player.triggerGhostMode()  -- Activate ghost mode when 'g' is pressed
    end
end

-- Call this in your main `love.keypressed` callback:
function love.keypressed(key)
    player.handleKeyPress(key)  -- Handle key presses like jump or ghost mode
end


-- Draw the player and handle the ladder/ghost mode display
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

    drawLightingEffect()  -- Draw the lighting effect
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

        -- Draw the blue overlay relative to the player's position
        love.graphics.rectangle("fill", 0, 0, 2000, 2000)
        
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color after drawing
    end


end

function drawLightingEffect()
    -- Check if ghost mode is enabled
    if player.isInGhostMode() then
        print("Ghost mode is active, skipping lighting effect")
        return -- Early exit if in ghost mode (lighting is not drawn)
    else
        print("Ghost mode is inactive, drawing lighting effect")

        local zoom = cam.zoom or 1

        -- Use player's current position directly (centered) and apply offset
        local offsetX = 16  -- Adjust this for manual horizontal offset
        local offsetY = 12  -- Adjust this for manual vertical offset
        local playerCenterX = player.x + offsetX
        local playerCenterY = player.y + offsetY

        -- Debugging information
        print("Player center X:", playerCenterX, "Player center Y:", playerCenterY)

        -- Step 1: Define the stencil function to create the light mask
        love.graphics.stencil(function()
            love.graphics.circle("fill", playerCenterX, playerCenterY, 50)  -- Adjust initial radius for smaller circle
        end, "replace", 1)

        -- Step 2: Enable stencil test to punch a hole in the darkness (where the light will be visible)
        love.graphics.setStencilTest("equal", 0)

        -- Step 3: Draw the dark rectangle (covering the whole screen)
        love.graphics.setColor(0, 0, 0, 0.99)
        love.graphics.rectangle("fill", playerCenterX, playerCenterY, 2000, 2000)

        -- Step 4: Disable the stencil test so that the light can be drawn freely
        love.graphics.setStencilTest()

        -- Step 5: Now draw the actual light circles
        local baseRadius = 10 + flickerOffset  -- Reduce base radius to make the light smaller
        local layers = 10  -- Fewer layers for a smaller effect
        local yellowHue = {1, 1, 0.8}

        -- Draw each layer with decreasing alpha and increasing size
        for i = layers, 1, -1 do
            print("Drawing light at X:", playerCenterX, "Y:", playerCenterY)

            local radius = baseRadius + (i * 5)  -- Reduce the layer increment for smaller rings
            local alpha = 0.10 * (i / layers)  -- Higher base alpha for more visible light
            love.graphics.setColor(yellowHue[1] * (i / layers), yellowHue[2] * (i / layers), yellowHue[3], alpha)
            love.graphics.circle("fill", playerCenterX, playerCenterY, radius)
        end

        -- Reset the color for future drawing operations
        love.graphics.setColor(1, 1, 1, 1)
    end
end
function player.isInGhostMode()
    return isGhostMode
end

return player
