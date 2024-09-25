local game = {}
local wall = {}
local player = require("player")
local pauseMenu = require("pauseMenu")
local Cutscene = require("cutscene")  -- Import the cutscene module

-- Camera is now globally accessible
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
            local targetVolume = love.volumeChecker() -- Get the target volume from the settings
            if game.mainMenuMusic then
                local currentVolume = game.mainMenuMusic:getVolume()
                
                -- Gradually increase the volume until it reaches the target volume
                if currentVolume < targetVolume then
                    local newVolume = math.min(currentVolume + fadeInSpeed * dt, targetVolume)
                    game.mainMenuMusic:setVolume(newVolume)
                end
            end
        end -- This is the missing `end` for the `if not game.cutscene.isActive` block
    elseif game.currentState == "playing" then
        if not pauseMenu.isPaused() then
            player.update(dt)  -- Update player logic
        end

        -- Camera should update *after* player has been updated
        cam:lookAt(player.x,player.y, player.width, player.height)  -- Follow the player


    end

    -- Handle fade-in effect on game launch
    if game.fadeInAlpha > 0 then
        game.fadeInAlpha = game.fadeInAlpha - dt * 0.5  -- Adjust fade speed as needed
    end
end


function playMainMenuMusic()
    if not game.mainMenuMusic then
        game.mainMenuMusic = love.audio.newSource("assets/background_Music.mp3", "static")
        game.mainMenuMusic:setLooping(true)
        game.mainMenuMusic:setVolume(0)  -- Start with volume at 0
        game.mainMenuMusic:play()
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
