local game = {}
local wall = {}
local player = require("player")
local pauseMenu = require("pauseMenu")
local CutsceneManager = require("CutsceneManager")

-- Camera is globally accessible
cam = nil  -- Declare camera globally so it can be accessed anywhere
local screenWidth, screenHeight = love.graphics.getDimensions()
local cutscene  -- Cutscene variable

-- Target volume level for the fade-in
local fadeInSpeed = 0.5

game.fadeInAlpha = 1  -- Initial fade-in alpha value
game.cutscene = nil  -- Initialize cutscene as nil to avoid loading it prematurely
game.currentState = "menu"  -- Start in the menu state

-- Load function initializes camera, player, and cutscene
function game.load()
    -- Load the camera module and initialize it
    local Camera = require("camera")
    cam = Camera()
    cam:setZoom(5)

    -- Load background images (add more if needed)
    game.backgroundLayers = {
        {image = love.graphics.newImage("assets/mapBackgrounds.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/mapRelics.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/mapTraps.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/mapLadders.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/LVLDoors.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/LVLWalls.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/mapPlatforms.png"), x = 0, y = 0}
    }

    -- Load the wall image
    wall.image = love.graphics.newImage("assets/mapPlatforms.png")
    wall.x = 0
    wall.y = 0
    wall.width = wall.image:getWidth()
    wall.height = wall.image:getHeight()

    player.load()  -- Load the player logic
end

function game.startCutscene(currentMusic, volume)
    -- Create the cutscene using CutsceneManager
    game.cutscene = CutsceneManager:new({
        steps = {
            {text = "Dennis was exploring the pyramid, when he became trapped inside ... Now it's up to him to rescue himself!", duration = 5},
            {text = "HINT: Dennis can't go through walls but his ghost can", duration = 5},
            {text = "Let your journey begin, navigate this dream or be trapped forever", duration = 5},
        },
        music = love.audio.newSource("assets/introBackgroundMusic.mp3", "stream"),  -- Cutscene background music
        imageSound = love.audio.newSource("assets/introImageSound.mp3", "static"), -- Sound effect
        image = love.graphics.newImage("assets/introImage.png"), -- Image to show at start
        font = love.graphics.newFont("assets/AKIKA.ttf", 36), -- AKIKA font
    }, function()
        -- Callback when cutscene finishes
        game.currentState = "playing"
        print("Cutscene finished. Now playing!")
    end, volume)

    -- Switch to cutscene state
    game.currentState = "cutscene"
end



-- Game input handling, taking into account cutscene state
function game.handleGameInput(key)
    if not pauseMenu.isPaused() then
        player.handleKeyPress(key)
    end
end

-- Update the game state
function game.update(dt)
    if game.currentState == "cutscene" then
        game.cutscene:update(dt)  -- Update cutscene

        -- Check if the cutscene has ended
        if not game.cutscene.isPlaying then
            print("Cutscene ended. Switching to playing state.")
            game.currentState = "playing"  -- Switch back to the playing state
            game.cutscene = nil  -- Disable the cutscene object

            -- Fade-in reapply if needed
            game.fadeInAlpha = 1  
            local targetVolume = love.volumeChecker() -- Get the target volume from the settings
            if game.mainMenuMusic then
                local currentVolume = game.mainMenuMusic:getVolume()
                
                -- Gradually increase the volume until it reaches the target volume
                if currentVolume < targetVolume then
                    local newVolume = math.min(currentVolume + fadeInSpeed * dt, targetVolume)
                    game.mainMenuMusic:setVolume(newVolume)
                end
            end
        end
    elseif game.currentState == "playing" then
        if not pauseMenu.isPaused() then
            player.update(dt)  -- Update player logic
        end

        -- Camera should update *after* player has been updated
        -- Ensure that the camera follows the center of the player
        cam:lookAt(player.x + player.width / 2, player.y + player.height / 2)  -- Center camera on player
    end

    -- Handle fade-in effect on game launch
    if game.fadeInAlpha > 0 then
        game.fadeInAlpha = game.fadeInAlpha - dt * 0.5  -- Adjust fade speed as needed
    end
end


-- Draw the game or the cutscene depending on the state
function game.draw()
    if game.currentState == "cutscene" and game.cutscene and game.cutscene.isPlaying then
        love.graphics.clear(0, 0, 0, 1)  -- Clear the screen to black for cutscene
        game.cutscene:draw()  -- Draw the cutscene
    else
        -- Clear the screen
        love.graphics.clear(0, 0, 0, 1)
        
        -- Attach the camera
        cam:attach()
        
        -- Draw the background layers first
        for _, layer in ipairs(game.backgroundLayers) do
            love.graphics.draw(layer.image, layer.x, layer.y)
        end

        -- Draw the wall and other objects
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(wall.image, wall.x, wall.y)

        -- Draw the player on top of the background
        player.draw()

        -- Detach the camera
        cam:detach()

        -- Draw the pause menu if necessary
        if pauseMenu.isPaused() then
            pauseMenu.draw()
        end

        -- Apply fade-in effect during launch
        if game.fadeInAlpha > 0 then
            love.graphics.setColor(0, 0, 0, game.fadeInAlpha)
            love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
            love.graphics.setColor(1, 1, 1, 1)  -- Reset color after drawing
        end
    end
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
