local player = {}
local bloodsplatter = require("bloodsplatter")
local wall = {}
local collisionLayers = {}  -- Holds different collision layers
local cam = require("camera")  -- Initialize the camera
-- Collision types
local LADDER, SPIKE, SACRIFICE_ALTAR, GROUND, WIN_BED = 1, 2, 3, 4, 5

-- Player properties
local spriteSheet
local quads = {}
local animations = {}
local currentAnimation
local direction = 1  -- 1 for right, -1 for left

-- Checkpoint properties
local checkpointStatus = 0  -- Tracks the checkpoint level (max of 3)
local checkpointCooldown = 0  -- Cooldown for adding checkpoints
local checkpointDuration = 30  -- 30 seconds cooldown duration for checkpoints
local checkpointPositions = {}  -- Stores positions of checkpoints

-- Movement properties
local isGhostMode, ghostTimer, ghostDuration = false, 0, 5
local gravity, jumpVelocity, wallSlideGravity = 800, -375, 200
local ghostSpeed = 40
local playerSpeed = 100
local ladderSpeed = 75
local flickerOffset = 0
local maxJumps, currentJumps = 1, 0

local akikaFont = love.graphics.newFont("assets/Akika.ttf", 12)
--Text properties
local displayText = nil
--win stuff/gameplay stuff

local victorySound  -- Declare variable for the victory sound
local winTimer = 5 -- Time in seconds before closing the game after winning
local gameWon = false  -- A flag to check if the game is won
local fadeAlpha = 0  -- Alpha value for fade-in effect (0: fully transparent, 1: fully opaque)
local fadeSpeed = 0.5  -- Speed of the fade-in effect
local isGhostModePossible = false  -- Flag to check if ghost mode is possible
-- Initialize player values
function player.load()
    player.x = player.x or 400
    player.y = player.y or 600  -- Adjust this value to ensure it's above the ground
    player.width = 30
    player.height = 30
    player.velocityY = player.velocityY or 0
    player.isGrounded = false
    player.isTouchingWall = false
    
    player.hitboxWidth = player.width * 0.6  -- Shrinks hitbox width by 40%
    player.hitboxHeight = player.height * 0.6  -- Shrinks hitbox height by 20%

    victorySound = love.audio.newSource("assets/winSound.mp3", "static")  -- Replace with your sound file path
    -- Load the wall image
    wall.image = love.graphics.newImage("assets/mapPlatforms.png")
    wall.x = 0
    wall.y = 0
    wall.width = wall.image:getWidth()
    wall.height = wall.image:getHeight()



    -- Load collision layers
    loadCollisionLayers()

    -- Load sprites and animations
    spriteSheet = love.graphics.newImage("assets/van.png")
    loadAnimations()
    currentAnimation = animations.idle
    bloodsplatter.load()

        -- Initialize checkpoint positions
        checkpointPositions = {
            {x = 1635, y = 339},  -- Default respawn position for checkpoint 1
            {x = 500, y = 600},  -- Respawn position for checkpoint 2
            {x = 600, y = 600}   -- Respawn position for checkpoint 3
        }
end

-- Load collision layers with different behaviors
function loadCollisionLayers()
    collisionLayers[GROUND] = loadCollisionData("assets/mapPlatforms.png")
    collisionLayers[LADDER] = loadCollisionData("assets/mapLadders.png")
    collisionLayers[SPIKE] = loadCollisionData("assets/mapTraps.png")
    collisionLayers[SACRIFICE_ALTAR] = loadCollisionData("assets/LVLDoors.png")
    collisionLayers[WIN_BED] = loadCollisionData("assets/WinBed.png")
end

-- Load collision data for a specific layer
function loadCollisionData(imagePath)
    local imageData = love.image.newImageData(imagePath)
    local mask = {}
    for x = 0, imageData:getWidth() - 1 do
        mask[x] = {}
        for y = 0, imageData:getHeight() - 1 do
            local r, g, b, a = imageData:getPixel(x, y)
            if a > 0 then
                mask[x][y] = true
            else
                mask[x][y] = false
            end
        end
    end
    return mask
end

-- Load animations from the sprite sheet
function loadAnimations()
    local sheetWidth, sheetHeight = spriteSheet:getWidth(), spriteSheet:getHeight()
    local frameWidth, frameHeight = 128, 128  -- Assuming each frame is 128x128 pixels

    animations = {
        idle = {frames = {}, speed = 0.2},
        run = {frames = {}, speed = 0.1},
        jump = {frames = {}, speed = 0.15},
        climb = {frames = {}, speed = 0.2},
        ghost = {frames = {}, speed = 0.2},
    }

    -- Idle (First frame)
    table.insert(animations.idle.frames, love.graphics.newQuad(0, 0, frameWidth, frameHeight, sheetWidth, sheetHeight))

    -- Run/Walk (Next 8 frames: 2nd to 9th)
    for i = 1, 8 do
        table.insert(animations.run.frames, love.graphics.newQuad(i * frameWidth, 0, frameWidth, frameHeight, sheetWidth, sheetHeight))
    end

    -- Climb (8th row, 2nd-4th and 6th-8th frames)
    for i = 1, 3 do
        table.insert(animations.climb.frames, love.graphics.newQuad((i + 1) * frameWidth, 7 * frameHeight, frameWidth, frameHeight, sheetWidth, sheetHeight))
    end
    for i = 5, 7 do
        table.insert(animations.climb.frames, love.graphics.newQuad(i * frameWidth, 7 * frameHeight, frameWidth, frameHeight, sheetWidth, sheetHeight))
    end

    -- Jump (12th row, 6th frame)
    table.insert(animations.jump.frames, love.graphics.newQuad(5 * frameWidth, 11 * frameHeight, frameWidth, frameHeight, sheetWidth, sheetHeight))

    -- Ghost
    for col = 0, 15 do  -- Loop through 16 columns (from 0 to 15)
        table.insert(animations.ghost.frames, love.graphics.newQuad(col * frameWidth, 10 * frameHeight, frameWidth, frameHeight, sheetWidth, sheetHeight))
    end
end    

-- Checkpoint logic when touching a sacrifice altar
function handleCheckpoint()
    if checkpointStatus < 3 and checkpointCooldown <= 0 then
        checkpointStatus = checkpointStatus + 1  -- Increment the checkpoint status
        checkpointCooldown = checkpointDuration  -- Reset the cooldown
        print("Checkpoint set at: ", player.x, player.y)
        checkpointPositions[checkpointStatus] = {x = player.x, y = player.y}  -- Store the player's current position
    end
end


-- Update cooldown timer for checkpoints
function updateCheckpointCooldown(dt)
    if checkpointCooldown > 0 then
        checkpointCooldown = checkpointCooldown - dt
    end
end


function updateAnimation(dt)
    if not currentAnimation or not currentAnimation.frames or #currentAnimation.frames == 0 then
        currentAnimation = animations.idle
    end

    if currentAnimation and #currentAnimation.frames > 0 then
        currentAnimation.timer = (currentAnimation.timer or 0) + dt
        if currentAnimation.timer >= currentAnimation.speed then
            currentAnimation.timer = 0
            currentAnimation.currentFrame = (currentAnimation.currentFrame or 1) + 1
            if currentAnimation.currentFrame > #currentAnimation.frames then
                currentAnimation.currentFrame = 1
            end
        end
    end
end

-- Collision check for all layers
function player.checkCollision(x, y)
    if isGhostMode then return false end

    for collisionType, mask in pairs(collisionLayers) do
        if basicCollision(x, y, player.width, player.height, wall, mask) then
            return collisionType
        end
    end
    return false
end

-- Basic collision detection with smaller hitbox
function basicCollision(x, y, width, height, obj, mask, collisionType)
    local hitboxLeft = x + (player.width - player.hitboxWidth) / 2
    local hitboxTop = y + (player.height - player.hitboxHeight) / 2
    local hitboxRight = hitboxLeft + player.hitboxWidth
    local hitboxBottom = hitboxTop + player.hitboxHeight

    local wallLeft, wallRight = obj.x, obj.x + obj.width
    local wallTop, wallBottom = obj.y, obj.y + obj.height

    if hitboxRight > wallLeft and hitboxLeft < wallRight and hitboxBottom > wallTop and hitboxTop < wallBottom then
        -- For spikes, shrink the collision area
        local shrinkFactor = 0.5  -- Adjust this factor to change the spike hitbox size
        local shrinkLeft, shrinkRight, shrinkTop, shrinkBottom

        -- Check if we're dealing with the spike collision layer
        if collisionType == SPIKE then
            -- Shrink the hitbox for spikes
            shrinkLeft = hitboxLeft + player.width * (1 - shrinkFactor) / 2
            shrinkRight = hitboxRight - player.width * (1 - shrinkFactor) / 2
            shrinkTop = hitboxTop + player.height * (1 - shrinkFactor) / 2
            shrinkBottom = hitboxBottom - player.height * (1 - shrinkFactor) / 2
        else
            -- Use default hitbox for other objects
            shrinkLeft = hitboxLeft
            shrinkRight = hitboxRight
            shrinkTop = hitboxTop
            shrinkBottom = hitboxBottom
        end

        -- Check collision with the mask
        for px = math.floor(shrinkLeft - obj.x), math.floor(shrinkRight - obj.x - 1) do
            for py = math.floor(shrinkTop - obj.y), math.floor(shrinkBottom - obj.y - 1) do
                if mask[px] and mask[px][py] then
                    return true
                end
            end
        end
    end
    return false
end


-- Player movement update
function player.update(dt)
    updateCheckpointCooldown(dt)  -- Update the checkpoint cooldown
    flickerOffset = flickerOffset + (math.random(-5, 5) * dt * 10)  -- Adjust values to control speed and range
    flickerOffset = math.max(-5, math.min(flickerOffset, 5))  -- Limit the flicker offset between -10 and 10
    print("x", player.x, "Y", player.y)
    if isGhostMode then
        updateGhostMode(dt)
    elseif player.onLadder then
        updateLadderMode(dt)
    else
        updateNormalMode(dt)
    end
    updateAnimation(dt)
    player.updateWin(dt)
end

-- Update movement in normal mode
function updateNormalMode(dt)
    local dx, dy = 0, 0
    local moving = false
    if player.velocityY == nil then player.velocityY = 0 end
    -- Clear the text if no relevant object is nearby
    displayText = nil

    -- Horizontal movement
    if love.keyboard.isDown("a") then
        dx = -playerSpeed * dt
        direction = -1
        moving = true
    elseif love.keyboard.isDown("d") then
        dx = playerSpeed * dt
        direction = 1
        moving = true
    end

    -- Apply gravity
    player.velocityY = math.min(player.velocityY + gravity * dt, 2000)
    dy = player.velocityY * dt

    -- Check for collisions (horizontal)
    local collisionTypeX = player.checkCollision(player.x + dx, player.y)
    
    -- Handle different collision types
    if collisionTypeX == GROUND then
        dx = 0  -- Block movement horizontally if ground is hit
    elseif collisionTypeX == LADDER then
        player.onLadder = true
        currentAnimation = animations.climb
        return
    elseif collisionTypeX == SPIKE then
        print("Player has died! Returning to last known checkpoint.")
        bloodsplatter.trigger(player.x, player.y)  -- Trigger blood splatter effect
        player.respawn()
        return
-- Inside the collision detection for SACRIFICE_ALTAR:
elseif collisionTypeX == SACRIFICE_ALTAR then
    -- Show text above the player's head when near the sacrifice altar
    displayText = "[E] Sacrifice"
    player.isGhostModePossible = true
    handleCheckpoint()  -- Handle checkpoint
    elseif collisionTypeX == WIN_BED then
        -- Trigger win event but don't block movement
        player.win()
    end

    -- Check for collisions (vertical)
    local collisionTypeY = player.checkCollision(player.x, player.y + dy)
    
    if collisionTypeY == GROUND then
        dy = 0  -- Block movement vertically if ground is hit
        player.velocityY = 0
        player.isGrounded = true
        currentJumps = 0
    elseif collisionTypeY == SACRIFICE_ALTAR then
        -- Trigger ghost mode but don't block movement
        player.isGhostModePossible = true
        handleCheckpoint()  -- Handle checkpoint
    elseif collisionTypeY == WIN_BED then
        -- Trigger win event but don't block movement
        player.win()
    else
        player.isGrounded = false
    end

    -- Update position
    player.x = math.max(0, player.x + dx)
    player.y = math.max(0, player.y + dy)

    -- Update animation based on movement
    if not player.isGrounded then
        currentAnimation = animations.jump
    elseif moving then
        currentAnimation = animations.run
    else
        currentAnimation = animations.idle
    end
end
 -- Respawn player at most recent checkpoint
 function player.respawn()
    if checkpointStatus > 0 then
        local checkpoint = checkpointPositions[checkpointStatus]
        player.x = checkpoint.x
        player.y = checkpoint.y
        player.velocityY = 0  -- Reset vertical velocity
        player.isGrounded = false  -- Reset grounded status
        currentJumps = 0  -- Reset jump count
        print("Respawned at checkpoint " .. checkpointStatus .. ": ", player.x, player.y)
    else
        print("No checkpoint found, respawning at default.")
        player.x = 400
        player.y = 600
    end
end

function updateLadderMode(dt)
    local dx, dy = 0, 0
    local moving = false
    displayText = nil
    -- Horizontal movement on the ladder
    if love.keyboard.isDown("a") then
        dx = -ladderSpeed * dt
        direction = -1
        moving = true
    elseif love.keyboard.isDown("d") then
        dx = ladderSpeed * dt
        direction = 1
        moving = true
    end

    -- Vertical movement on the ladder
    if love.keyboard.isDown("w") then
        dy = -ladderSpeed * dt
        moving = true
    elseif love.keyboard.isDown("s") then
        dy = ladderSpeed * dt
        moving = true
    end

    -- Check for wall collision while on the ladder
    local collisionTypeX = player.checkCollision(player.x + dx, player.y)
    local collisionTypeY = player.checkCollision(player.x, player.y + dy)

    -- Prevent horizontal movement through walls
    if collisionTypeX == GROUND then
        dx = 0  -- Stop horizontal movement if a wall is hit
    end

    -- Prevent vertical movement through walls
    if collisionTypeY == GROUND then
        dy = 0  -- Stop vertical movement if a wall is hit
    end

    -- Check if player leaves the ladder
    if collisionTypeX ~= LADDER and collisionTypeY ~= LADDER then
        player.onLadder = false
        player.velocityY = 0  -- Reset vertical velocity
        currentAnimation = animations.idle  -- Switch to idle animation
        return
    end

    -- Update player position
    player.x = player.x + dx
    player.y = player.y + dy

    -- Update animation
    if moving then
        currentAnimation = animations.climb  -- Switch to climbing animation
    else
        currentAnimation = animations.idle  -- Switch to idle animation
    end
end


-- Update movement in ghost mode
function updateGhostMode(dt)
    local dx, dy = 0, 0
    displayText = nil
    -- Change the animation to ghost mode
    currentAnimation = animations.ghost
    -- Update the ghost animation
    updateAnimation(dt)
    -- Movement is slower in ghost mode
    if love.keyboard.isDown("a") then
        dx = -ghostSpeed * dt  -- Use ghostSpeed for slower movement
        direction = -1
    elseif love.keyboard.isDown("d") then
        dx = ghostSpeed * dt
        direction = 1
    end
    if love.keyboard.isDown("w") then
        dy = -ghostSpeed * dt
    elseif love.keyboard.isDown("s") then
        dy = ghostSpeed * dt
    end

    -- Update position (without any collisions)
    player.x = player.x + dx
    player.y = player.y + dy



    -- Timer for ghost mode duration
    ghostTimer = ghostTimer + dt
    if ghostTimer >= ghostDuration then
        isGhostMode = false
        player.velocityY = 0
        currentAnimation = animations.idle  -- Revert to normal animation after ghost mode ends
        print("Exited Ghost Mode")
    end
end


function player.draw()
    currentAnimation = currentAnimation or animations.idle
    local frame = currentAnimation.frames[currentAnimation.currentFrame or 1]
    local scaleX = (direction == 1) and (player.width / 128) or -(player.width / 128)
    local scaleY = player.height / 128
    local offsetX = (direction == -1) and player.width or 0

    -- Draw the player sprite
    love.graphics.draw(spriteSheet, frame, player.x + offsetX, player.y, 0, scaleX, scaleY, player.width / 2, player.height / 2)

    -- Draw the text above the player's head, if available
if displayText then
    love.graphics.setFont(akikaFont)  -- Set Akika font
    local textX = player.x + player.width
    local textY = player.y - player.height - 3  -- Position above player's head
    love.graphics.setColor(1, 1, 1, 1)  -- Set color to white
    love.graphics.print(displayText, textX, textY)
    love.graphics.setFont(love.graphics.getFont())  -- Reset font to default after drawing
end
    

    bloodsplatter.draw()
    drawLightingEffect()
end


-- Draw lighting effect
function drawLightingEffect()
    -- Check if ghost mode is enabled
    if player.isGhostMode then
        return -- Early exit if in ghost mode (lighting is not drawn)
    else
        
        local offsetX = 16  -- Adjust this for manual horizontal offset
        local offsetY = 12  -- Adjust this for manual vertical offset
        local playerCenterX = player.x + offsetX
        local playerCenterY = player.y + offsetY

        -- Step 1: Define the stencil function to create the light mask
        love.graphics.stencil(function()
            love.graphics.circle("fill", playerCenterX, playerCenterY, 50)
        end, "replace", 1)

        -- Step 2: Enable stencil test to punch a hole in the darkness
        love.graphics.setStencilTest("equal", 0)

        -- Step 3: Draw the dark rectangle
        love.graphics.setColor(0, 0, 0, 0.99)
        love.graphics.rectangle("fill", 0, 0, 10000, 10000)

        -- Step 4: Disable the stencil test
        love.graphics.setStencilTest()

        -- Step 5: Draw the light circles
        local baseRadius = 10 + flickerOffset
        local layers = 10
        local yellowHue = {1, 1, 0.8}

        -- Draw each layer with decreasing alpha and increasing size
        for i = layers, 1, -1 do
            local radius = baseRadius + (i * 5)
            local alpha = 0.10 * (i / layers)
            love.graphics.setColor(yellowHue[1] * (i / layers), yellowHue[2] * (i / layers), yellowHue[3], alpha)
            love.graphics.circle("fill", playerCenterX, playerCenterY, radius)
        end

        -- Reset the color for future drawing operations
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function player.keypressed(key)
    if key == "space" then
        player.handleJump()  -- Trigger jump when space is pressed
    end
    if key == "e" and player.isGhostModePossible then
        isGhostMode = true
        ghostTimer = 0  -- Reset ghost timer
        player.isGhostModePossible = false  -- Reset the possibility to enter ghost mode until triggered again
        print("Entered Ghost Mode")
    end
end



function player.handleJump()
    if not player.isGhostMode then
        print("Jump Attempt: isGrounded =", player.isGrounded, " currentJumps =", currentJumps, " onLadder =", player.onLadder)
        if player.isGrounded or player.onLadder or currentJumps < maxJumps then
            player.velocityY = jumpVelocity
            currentJumps = currentJumps + 1
            player.isGrounded = false
            player.onLadder = false
            print("Jump Successful! VelocityY =", player.velocityY, " currentJumps =", currentJumps)
        else
            print("Jump Failed! Player cannot jump.")
        end
    end
end

function player.win()
    if not gameWon then
        gameWon = true  -- Set the flag to true to start the winning sequence
        love.audio.play(victorySound)  -- Play the victory sound
    end
end

function player.updateWin(dt)
    if gameWon then
        -- Increase fadeAlpha over time until it's fully opaque (fadeAlpha reaches 1)
        fadeAlpha = math.min(fadeAlpha + fadeSpeed * dt, 1)
        
        -- Decrease the win timer only after the screen is fully black
        if fadeAlpha >= 1 then
            winTimer = winTimer - dt  -- Decrease the timer
        end

        -- Close the game after the winTimer runs out
        if winTimer <= 0 then
            love.event.quit()  -- Close the game
        end
    end
end

-- Draw function to blacken the screen with a fade-in effect when the game is won
function player.drawWin()
    if gameWon then
        -- Draw a black rectangle over the entire screen with fadeAlpha controlling opacity
        love.graphics.setColor(0, 0, 0, fadeAlpha)  -- Black color with fadeAlpha for transparency
        love.graphics.rectangle("fill", 0, 0, 2000, 2000)
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    end
end
return player
