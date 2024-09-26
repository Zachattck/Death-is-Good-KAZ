local game = {}
local cutsceneManager = require("CutsceneManager")
local pauseMenu = require("pauseMenu")
local player = require("player")
local cam = nil  -- Declare camera globally for future use if needed
local screenWidth, screenHeight = love.graphics.getDimensions()

-- Target volume level for the fade-in
local fadeInSpeed = 0.5
game.fadeInAlpha = 1  -- Initial fade-in alpha value
game.cutscene = nil  -- Initialize cutscene as nil to avoid loading it prematurely
game.currentState = "menu"  -- Start in the menu state

-- Load function initializes camera, and background images
function game.load()
    -- Load the camera module if needed in the future
    local Camera = require("camera")
    cam = Camera()
    cam:setZoom(6)
    player.load()  -- Load the player module
    -- Load background images (add more if needed)
    game.backgroundLayers = {
        {image = love.graphics.newImage("assets/mapBackgrounds.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/mapPlatforms.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/LVLWalls.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/mapLadders.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/mapRelics.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/LVLDoors.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/mapTraps.png"), x = 0, y = 0},
    }
end

-- Start cutscene function
function game.startCutscene()
    local targetVolume = love.volumeChecker() -- Get the target volume from settings

    -- Create a new CutsceneManager instance
    game.cutscene = cutsceneManager:new()

    -- Define cutscene data
    local cutsceneData = {
        steps = {
            {text = "Dennis was exploring the pyramid, when he became trapped inside ...", duration = 5},
            {text = "HINT: Dennis can't go through walls but his ghost can", duration = 5},
            {text = "Let your journey begin, navigate this dream or be trapped forever", duration = 5},
        },
        music = love.audio.newSource("assets/introBackgroundMusic.mp3", "stream"),  -- Cutscene background music
        imageSound = love.audio.newSource("assets/introImageSound.mp3", "static"), -- Sound effect
        image = love.graphics.newImage("assets/introImage.png"), -- Image to show at start
        font = love.graphics.newFont("assets/AKIKA.ttf", 36), -- Font for cutscene
        volume = targetVolume, -- Volume level
    }

    -- Start the cutscene
    game.cutscene:start(cutsceneData, function()
        game.currentState = "playing"
        game.fadeInAlpha = 1  -- Start with full opacity for fade effect
    end, targetVolume)

    -- Switch to cutscene state
    game.currentState = "cutscene"
end

-- Update the game state
-- Update the game state
function game.update(dt)
    if game.currentState == "cutscene" and game.cutscene then
        game.cutscene:update(dt)  -- Update cutscene
    end

    -- Assume you have a player object and player.x, player.y are its positions
    -- Center the camera on the player
    if game.currentState == "playing" and player then
        -- Assuming player.x and player.y are the player's position
        cam:lookAt(player.x, player.y)
    end

    -- Handle fade-in effect on game launch or after cutscene
    if game.fadeInAlpha > 0 then
        game.fadeInAlpha = game.fadeInAlpha - dt * fadeInSpeed  -- Use the fadeInSpeed variable
        if game.fadeInAlpha < 0 then
            game.fadeInAlpha = 0  -- Clamp to 0 to avoid negative alpha
        end
    end
end


-- Draw the game or the cutscene depending on the state
function game.draw()
    love.graphics.clear(0, 0, 0, 1)  -- Clear the screen to black

    -- Handle the cutscene drawing
    if game.currentState == "cutscene" and game.cutscene and game.cutscene:isActive() then
        game.cutscene:draw()  -- Draw the cutscene
        return  -- Exit early, no need to draw game elements during cutscene
    end

    -- Attach the camera transform
    cam:attach()  -- Begin camera transformation

    -- Draw the background layers when in the "playing" state or after the cutscene
    if game.currentState == "playing" then
        for _, layer in ipairs(game.backgroundLayers) do
            love.graphics.draw(layer.image, layer.x, layer.y)
        end

        -- Draw the player (make sure your player drawing function is inside the camera transformation)
        
            player.draw()
        
    end

    -- Detach the camera transform after drawing
    cam:detach()

    -- Apply fade-in effect when transitioning from cutscene to gameplay
    if game.fadeInAlpha > 0 then
        love.graphics.setColor(0, 0, 0, game.fadeInAlpha)
        love.graphics.rectangle("fill", 0, 0, 2000, 2000)
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color after drawing
    end
end


-- Handle key presses
function love.keypressed(key)
    if key == "escape" then
        pauseMenu.pauseGame()  -- Pause the game when Escape is pressed
    end

    if game.currentState == "menu" and key == "return" then
        game.startCutscene()  -- Start the cutscene when Enter is pressed in the menu
    elseif game.currentState == "cutscene" and game.cutscene then
        game.cutscene:keypressed(key)  -- Pass key presses to CutsceneManager
    elseif game.currentState == "playing" then
        player.keypressed(key)  -- Pass key presses   
    end
end

return game
