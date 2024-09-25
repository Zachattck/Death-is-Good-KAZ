local game = {}
local wall = {}
local player = require("player")
local pauseMenu = require("pauseMenu")
local Cutscene = require("cutscene")  -- Import the cutscene module

-- Camera is now globally accessible
cam = nil  -- Declare camera globally so it can be accessed anywhere
local screenWidth, screenHeight = love.graphics.getDimensions()
local cutscene  -- Cutscene variable

game.fadeInAlpha = 1  -- Initial fade-in alpha value

-- Flicker parameters
local flickerTimer = 0
local flickerInterval = 0.01
local flickerStrength = 3  -- Adjusted strength to match old logic
local flickerOffset = 0

game.cutscene = nil  -- Initialize cutscene as nil to avoid loading it prematurely
game.currentState = "menu"  -- Start in the menu state

-- Load function initializes camera, player, and cutscene
function game.load()
    -- Load the camera module and initialize it
    local Camera = require("camera")
    cam = Camera()
    cam:setZoom(4)

    -- Load the wall image
    wall.image = love.graphics.newImage("assets/mapPlatforms.png")
    wall.x = 0
    wall.y = 0
    wall.width = wall.image:getWidth()
    wall.height = wall.image:getHeight()

    player.load()  -- Load the player and its assets
end

-- Function to start the cutscene
function game.startCutscene(currentMusic, volume)
    game.cutscene = Cutscene:new({
        "It was a normal archeological dig... at the pyramids",
        "until...",
        "oh man I've gotta find my way out of this place now"
    }, 
    "assets/introImage.png",  -- Image
    "assets/introBackgroundMusic.mp3",  -- Background music
    "assets/introImageSound.mp3",  -- Sound effect for the image
    24,  -- Duration of the cutscene
    screenWidth,  -- Pass the screen width
    screenHeight,  -- Pass the screen height
    volume,  -- Pass the volume level
    currentMusic  -- Pass the current music to fade out
    )

    -- Switch to the cutscene state
    game.currentState = "cutscene"
    game.cutscene:load()  -- Load and start the cutscene
end

-- Game input handling, taking into account cutscene state
function game.handleGameInput(key)
    if not pauseMenu.isPaused() then
        player.handlePlayerInput(key)
    end
end

-- Update the game state
-- Game input handling, taking into account cutscene state
function game.handleGameInput(key)
    if not pauseMenu.isPaused() then
        player.handlePlayerInput(key)  -- Forward input to the player's handler
    end
end

-- Update the game state
function game.update(dt)
    if game.currentState == "cutscene" then
        game.cutscene:update(dt)  -- Update cutscene

        -- Check if the cutscene has ended
        if not game.cutscene.isActive then
            print("Cutscene ended. Switching to playing state.")
            game.currentState = "playing"  -- Switch back to the playing state
            game.cutscene = nil  -- Disable the cutscene object

            -- Fade-in reapply if needed
            game.fadeInAlpha = 1  

            -- Play main menu background music again
            if not game.mainMenuMusic then
                game.mainMenuMusic = love.audio.newSource("assets/background_Music.mp3", "static")
                game.mainMenuMusic:setLooping(true)
                game.mainMenuMusic:setVolume(0.5)
                game.mainMenuMusic:play()
            end
        end -- This is the missing `end` for the `if not game.cutscene.isActive` block
    elseif game.currentState == "playing" then
        if not pauseMenu.isPaused() then
            player.update(dt)  -- Update player logic
        end

        -- Camera should update *after* player has been updated
        cam:lookAt(player.x,player.y, player.width, player.height)  -- Follow the player

        -- Flicker logic (lighting effect, optional)
        flickerTimer = flickerTimer + dt
        if flickerTimer >= flickerInterval then
            flickerOffset = math.random(-flickerStrength, flickerStrength)
            flickerTimer = 0
        end
    end

    -- Handle fade-in effect on game launch
    if game.fadeInAlpha > 0 then
        game.fadeInAlpha = game.fadeInAlpha - dt * 0.5  -- Adjust fade speed as needed
    end
end


-- Draw the game or the cutscene depending on the state
function game.draw()
    if game.currentState == "cutscene" and game.cutscene and game.cutscene.isActive then
        love.graphics.clear(0, 0, 0, 1)  -- Clear the screen to black for cutscene
        game.cutscene:draw()  -- Draw the cutscene
        print("Drawing cutscene")
    else
        -- Otherwise, draw the regular game elements
        love.graphics.clear(0, 0, 0, 1)  -- Clear the screen to black

        -- Attach the camera and draw game objects
        cam:attach()  -- Only attach the camera when rendering the game world
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(wall.image, wall.x, wall.y)
        -- Draw the player
        print("Drawing player at position: ", player.x, player.y)
        player.draw()  -- Draw the player
        drawLightingEffect()

        -- Detach the camera for any UI or effects
        cam:detach()

        

        -- Draw the pause menu if necessary
        if pauseMenu.isPaused() then
            pauseMenu.draw()
        end

        -- Apply fade-in effect during launch
        if game.fadeInAlpha > 0 then
            love.graphics.setColor(0, 0, 0, game.fadeInAlpha)
            love.graphics.rectangle("fill", 0, 0, 2000 , 2000)
            love.graphics.setColor(1, 1, 1, 1)  -- Reset color after drawing
        end
    end
end

function drawLightingEffect()
    -- Check if ghost mode is enabled
    if player.isInGhostMode() then
        print("Ghost mode is active, skipping lighting effect")
        return -- Early exit if in ghost mode (lighting is not drawn)
    end
    
    print("Ghost mode is inactive, drawing lighting effect")

    local zoom = cam.zoom or 1

    -- Calculate player center in world space
    local playerCenterX = player.x + player.width / 2
    local playerCenterY = player.y + player.height / 2
    
    -- Convert world position to screen coordinates
    local playerScreenX = (playerCenterX - cam.x) * zoom + screenWidth / 2
    local playerScreenY = (playerCenterY - cam.y) * zoom + screenHeight / 2
    
    print("Player center X:", playerCenterX, "Player center Y:", playerCenterY)
    print("Camera X:", cam.x, "Camera Y:", cam.y, "Zoom:", zoom)
    print("Screen coordinates X:", playerScreenX, "Y:", playerScreenY)
    
    -- Step 1: Define the stencil function to create the light mask
    love.graphics.stencil(function()
        love.graphics.circle("fill", playerScreenX, playerScreenY, 200)
    end, "replace", 1)

    -- Step 2: Enable stencil test to punch a hole in the darkness (where the light will be visible)
    love.graphics.setStencilTest("equal", 0)

    -- Step 3: Draw the dark rectangle covering the entire screen
    love.graphics.setColor(0, 0, 0, 0.99)  -- Adjust alpha for darkness
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Step 4: Disable the stencil test so that the light can be drawn freely
    love.graphics.setStencilTest()

    -- Step 5: Now draw the actual light circles
    local baseRadius = 80 + flickerOffset
    local layers = 10
    local yellowHue = {1, 1, 0.8}

    -- Draw each layer with decreasing alpha and increasing size
    for i = layers, 1, -1 do
        print("Drawing light at X:", playerScreenX, "Y:", playerScreenY)

        local radius = baseRadius + (i * 15)
        local alpha = 0.3 * (i / layers)  -- Increased alpha for visibility
        love.graphics.setColor(yellowHue[1] * (i / layers), yellowHue[2] * (i / layers), yellowHue[3], alpha)
        love.graphics.circle("fill", playerScreenX, playerScreenY, radius)
    end

    -- Reset the color for future drawing operations
    love.graphics.setColor(1, 1, 1, 1)
end


-- Capture keypress events and pass them to handleGameInput
function love.keypressed(key)
    if key == "escape" then
        pauseMenu.toggle()
    end

    if game.currentState == "menu" and key == "return" then
        game.startCutscene()  -- Start the cutscene when Enter is pressed in the menu
    elseif game.currentState == "playing" and not pauseMenu.isPaused() then
        game.handleGameInput(key)
    end
end

return game
