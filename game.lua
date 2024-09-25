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

-- Loading Ladder
local game = {}
local player = require("player")

-- Load function initializes camera, player, and cutscene
function game.load()
    -- Load the camera module and initialize it
    local Camera = require("camera")
    cam = Camera()
    cam:setZoom(4)

game.backgroundLayers = {
    love.graphics.newImage("assets/mapBackgrounds.png"),
    love.graphics.newImage("assets/mapRelics.png"),
    love.graphics.newImage("assets/mapTraps.png"),
    love.graphics.newImage("assets/mapLadders.png"),
    love.graphics.newImage("assets/LVLDoors.png"),
    love.graphics.newImage("assets/LVLWalls.png"),
    love.graphics.newImage("assets/mapPlatforms.png")
}

-- Set their positions (optional) if they need to be placed differently
game.backgroundPositions = {
    {x = 0, y = 0},
    {x = 0, y = 0},
    {x = 0, y = 0},
    {x = 0, y = 0},
    {x = 0, y = 0},
    {x = 0, y = 0},
    {x = 0, y = 0}
}


    

    -- Load the wall image
    wall.image = love.graphics.newImage("assets/mapPlatforms.png")
    wall.x = 0
    wall.y = 0
    wall.width = wall.image:getWidth()
    wall.height = wall.image:getHeight()


    player.load()  -- Load the player and its assets

    ladderImage = love.graphics.newImage("assets/mapLadders.png")
    player.load()  -- Load the player logic
end

-- Function to start the cutscene
function game.startCutscene(currentMusic, volume)
    game.cutscene = Cutscene:new({
        "Dennis was exploring the pyramid, when he became trapped inside ... Now its up to him to rescue himself!",
        "HINT: Dennis can't go through walls but his ghost can",
        "Let your journey begin, navigate this dream or be trapped forever"

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
    ---camera
    cam:lookAt(player:getWidth()/2,  player:getHeight()/2)
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
    player.update(dt)

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

        -- Draw the 7 background layers in order (no parallax effect)
        for i, layer in ipairs(game.backgroundLayers) do
            local posX = game.backgroundPositions[i].x
            local posY = game.backgroundPositions[i].y
            love.graphics.draw(layer, posX, posY)
        end

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
            love.graphics.rectangle("fill", 0, 0, 2000, 2000)
            love.graphics.setColor(1, 1, 1, 1)  -- Reset color after drawing
        end
    end
    love.graphics.draw(ladderImage, 0, 0)  -- Draw the ladder image

    player.draw()
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
