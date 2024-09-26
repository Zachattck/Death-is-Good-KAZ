local game = {}
local cutsceneManager = require("CutsceneManager")
local pauseMenu = require("pauseMenu")
local player = require("player")
local cam = nil  -- Declare camera globally for future use if needed
local screenWidth, screenHeight = love.graphics.getDimensions()
local gameWon = false  -- A flag to check if the game is won
-- Target volume level for the fade-in
local winTimer = 30
local victorySound
local fadeInSpeed = 0.5
game.fadeSpeed = 0.5  -- Speed of fade effect
game.fadeAlpha = 0.5
game.fadeInAlpha = 1  -- Initial fade-in alpha value
game.cutscene = nil  -- Initialize cutscene as nil to avoid loading it prematurely
game.currentState = "menu"  -- Start in the menu state

-- Load function initializes camera, and background images
function game.load()
    -- Load the camera module if needed in the future
    player.load(game)  -- Load the player module
    local Camera = require("camera")
    cam = Camera()
    cam:setZoom(6) 
    -- Load background images (add more if needed)
    victorySound = love.audio.newSource("assets/winSound.mp3", "static") -- Declare variable for the victory sound
    game.backgroundLayers = {
        {image = love.graphics.newImage("assets/mapBackgrounds.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/mapPlatforms.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/mapLadders.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/mapRelics.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/LVLDoors.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/mapTraps.png"), x = 0, y = 0},
        {image = love.graphics.newImage("assets/winbed.png"), x = 0, y = 0},
    }
end

-- Start cutscene function
function game.startCutscene()
    print("Starting cutscene...")  -- Debugging output
    game.currentState = "cutscene"
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
function game.update(dt)
    if pauseMenu.isPaused() then
        return  -- Skip all game updates
    end
    if game.currentState == "cutscene" and game.cutscene then
        game.cutscene:update(dt)  -- Update cutscene
    end

    -- Handle fade-in effect on game launch or after cutscene
    if game.fadeInAlpha > 0 then
        game.fadeInAlpha = game.fadeInAlpha - dt * fadeInSpeed
        if game.fadeInAlpha < 0 then
            game.fadeInAlpha = 0
        end
    end

    -- If game is won, handle fade out and win timer
    if game.gameWon then
        game.fadeAlpha = math.min(game.fadeAlpha + game.fadeSpeed * dt, 1)
        if game.fadeAlpha >= 1 then
            winTimer = winTimer - dt
        end
        if winTimer <= 0 then
            game.currentState = "menu"  -- Return to the menu after win
        end
    end

    -- Play music when entering the "playing" state
    if game.currentState == "playing" then
        if not game.gameMusicPlayed then
            -- Stop any cutscene music and start the game music
            love.audio.stop()  -- Stop any existing music
            local gameMusic = love.audio.newSource("assets/background_music.mp3", "stream")
            gameMusic:setVolume(0.5)
            gameMusic:play()
            game.gameMusicPlayed = true
        end
        player.update(dt)
        cam:lookAt(player.x, player.y)
    end
end



-- Draw the game or the cutscene depending on the state
function game.draw()
    love.graphics.clear(0, 0, 0, 1)  -- Clear the screen to black
    print("Cutscene active: ", game.currentState == "cutscene", game.cutscene and game.cutscene:isActive())
    -- Handle the cutscene drawing
    if game.currentState == "cutscene" and game.cutscene and game.cutscene:isActive() then
        
        game.cutscene:draw()
        return  -- Return so we only draw the cutscene and not the game
    end

    -- Draw the game in the playing state
    if game.currentState == "playing" then
        cam:attach()
        for _, layer in ipairs(game.backgroundLayers) do
            love.graphics.draw(layer.image, layer.x, layer.y)
        end
        player.draw()
        cam:detach()
    end

    -- Fade-out effect when the game is won
    if game.gameWon then
        love.graphics.setColor(0, 0, 0, game.fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    end
end



-- Handle key presses
function love.keypressed(key)
    if key == "escape" then
        pauseMenu.toggle()  -- Toggle the pause state when Escape is pressed
    end

    -- Block other key actions while paused
    if not pauseMenu.isPaused() then
        if game.currentState == "menu" and key == "return" then
            game.startCutscene()
        elseif game.currentState == "cutscene" and game.cutscene then
            game.cutscene:keypressed(key)  -- Call keypressed on cutscene
        elseif game.currentState == "playing" then
            player.keypressed(key)
        end
    end
end


function game.win()
    if not game.gameWon then
        
        game.startCreditsCutscene()  -- Start the credits cutscene
        game.gameWon = true
    end
end
function game.startCreditsCutscene()
    local targetVolume = love.volumeChecker() -- Get the target volume from settings

    -- Create a new CutsceneManager instance
    game.cutscene = cutsceneManager:new()

    -- Define cutscene data with longer durations
    local cutsceneData = {
        steps = {
            {text = "Thanks for playing!", duration = 5}, 
            {text = "Developed by: The Goats", duration = 5},  
            {text = "Zachary Lebel - Lead Developer/VFX Artist", duration = 5},
            {text = "Andrew Thomas - Level Designer", duration = 5},
            {text = "Keigan Macneil - Assistant Coder and Designer", duration = 5},
            {text = "Special Thanks to Denis and all the asset creators we borrowed from :)", duration = 5},
        },  
        music = love.audio.newSource("assets/creditsMusic.mp3", "stream"),  -- Cutscene background music
        font = love.graphics.newFont("assets/AKIKA.ttf", 36), -- Font for cutscene
        volume = targetVolume, -- Volume level
    }

    -- Set a proper callback to reset the state to the menu after all steps are complete
    game.cutscene:start(cutsceneData, function()
        print("Cutscene finished, returning to menu.")  -- Debugging output
        game.currentState = "menu"  -- Ensure the state is reset to "menu" after the cutscene
    end, targetVolume)
    
    -- Ensure the state is set to "cutscene"
    game.currentState = "cutscene"
end




return game
