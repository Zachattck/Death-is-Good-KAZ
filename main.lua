local game = require("game")  -- Assuming game.lua is in the same directory as main.lua

-- Game states
local currentState = "menu" -- Initially in the menu state
local selectedOption = 1    -- Track selected menu option
local options = {"Start Game", "Options", "Exit"}  -- Main menu options

-- Screen settings
local screenWidth, screenHeight = 1920, 1080

-- List of menu options (images)
local menuOptions = {}
local startImage, optionsImage, exitImage

-- Load the title image and background music
local titleImage
local backgroundMusic
local levelImage 

-- Options menu settings
local selectedOptionOption = 1  -- Track selected option in the options menu
local volume = 1  -- Music volume (1 = max, 0 = mute)

-- Mouse hover tracking for menu options
local isHoveringStart = false
local isHoveringOptions = false
local isHoveringExit = false

-- Love2D callbacks
function love.load()
    -- Set screen size
    love.window.setMode(screenWidth, screenHeight)
    
    -- Set font size for the menu
    love.graphics.setFont(love.graphics.newFont(30))

    -- Load the title image
    titleImage = love.graphics.newImage("assets/title.png")
    
    -- Load menu option images
    startImage = love.graphics.newImage("assets/start.png")
    optionsImage = love.graphics.newImage("assets/options.png")  -- Added for options menu
    exitImage = love.graphics.newImage("assets/exit.png")
    menuOptions = {startImage, optionsImage, exitImage}

    titleImage = love.graphics.newImage("assets/levelImage.png")

    -- Load and play background music
    backgroundMusic = love.audio.newSource("assets/background_music.mp3", "stream")
    backgroundMusic:setLooping(true)
    love.audio.play(backgroundMusic)

    game.load()
end

function love.update(dt)
    if currentState == "menu" then
        updateMenu()
    elseif currentState == "options" then
        updateOptionsMenu()
    elseif currentState == "playing" then
        updateGame(dt)
    end
end

function love.draw()
    if currentState == "menu" then
        -- Menu drawing logic
        drawMenu()
    elseif currentState == "options" then
        -- Draw options menu
        drawOptionsMenu()
    elseif currentState == "playing" then
        -- Call draw logic from game.lua
        game.draw()
    end
end

-- Handle mouse input
function love.mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        if currentState == "menu" then
            handleMenuMouseInput(x, y)
        elseif currentState == "options" then
            handleOptionsMenuMouseInput(x, y)
        end
    end
end

-- Menu functions
function drawMenu()
    -- Draw title image at the top center
    local imageWidth = titleImage:getWidth()
    local imageHeight = titleImage:getHeight()
    love.graphics.draw(titleImage, (screenWidth - imageWidth) / 2, 50)

    -- Set the scale for the menu option images
    local scale = 0.5  -- Adjust this value to make images smaller or larger

    -- Draw menu option images (Start, Options, and Exit)
    for i, option in ipairs(menuOptions) do
        -- Get the original width and height of the images
        local optionWidth = option:getWidth() * scale
        local optionHeight = option:getHeight() * scale

        -- Calculate the position to center the scaled images
        local x = (screenWidth - optionWidth) / 2
        local y = 200 + i * 100

        -- Highlight the selected option or hover by changing color
        if (i == 1 and isHoveringStart) or (i == 2 and isHoveringOptions) or (i == 3 and isHoveringExit) then
            love.graphics.setColor(1, 0, 0)  -- Highlight hovered option in red
        else
            love.graphics.setColor(1, 1, 1)  -- Normal color for unselected options
        end

        -- Draw the image with scaling applied
        love.graphics.draw(option, x, y, 0, scale, scale)
    end

    love.graphics.setColor(1, 1, 1) -- Reset color
end

function updateMenu()
    -- Update hover detection
    local mouseX, mouseY = love.mouse.getPosition()
    local scale = 0.5  -- Same scale as used in drawing
    local buttonYStart = 200

    isHoveringStart = isMouseOverButton(mouseX, mouseY, startImage, (screenWidth - startImage:getWidth() * scale) / 2, buttonYStart, scale)
    isHoveringOptions = isMouseOverButton(mouseX, mouseY, optionsImage, (screenWidth - optionsImage:getWidth() * scale) / 2, buttonYStart + 100, scale)
    isHoveringExit = isMouseOverButton(mouseX, mouseY, exitImage, (screenWidth - exitImage:getWidth() * scale) / 2, buttonYStart + 200, scale)
end

-- Handle mouse input for the main menu
function handleMenuMouseInput(x, y)
    local scale = 0.5  -- Same scale as used in drawing
    local buttonYStart = 200

    -- Check if Start Game was clicked
    if isMouseOverButton(x, y, startImage, (screenWidth - startImage:getWidth() * scale) / 2, buttonYStart, scale) then
        currentState = "playing"  -- Start the game
    -- Check if Options was clicked
    elseif isMouseOverButton(x, y, optionsImage, (screenWidth - optionsImage:getWidth() * scale) / 2, buttonYStart + 100, scale) then
        currentState = "options"  -- Go to options menu
    -- Check if Exit was clicked
    elseif isMouseOverButton(x, y, exitImage, (screenWidth - exitImage:getWidth() * scale) / 2, buttonYStart + 200, scale) then
        love.event.quit()  -- Exit the game
    end
end

-- Options Menu Functions
function drawOptionsMenu()
    love.graphics.printf("Options Menu", 0, 100, love.graphics.getWidth(), "center")

    -- Draw volume option
    local volumeText = "Music Volume: " .. math.floor(volume * 100) .. "%"
    love.graphics.printf(volumeText, 0, 200, love.graphics.getWidth(), "center")

    -- Highlight selected option
    love.graphics.printf("Back to Menu", 0, 300, love.graphics.getWidth(), "center")
end

-- Handle mouse input for the options menu
function handleOptionsMenuMouseInput(x, y)
    -- Check if Back to Menu was clicked
    if x > 0 and x < screenWidth and y > 300 and y < 350 then
        currentState = "menu"  -- Back to main menu
    end
end

-- Check if the mouse is over a button (image)
function isMouseOverButton(mouseX, mouseY, image, buttonX, buttonY, scale)
    local buttonWidth = image:getWidth() * scale
    local buttonHeight = image:getHeight() * scale
    return mouseX >= buttonX and mouseX <= buttonX + buttonWidth and mouseY >= buttonY and mouseY <= buttonY + buttonHeight
end

-- Game functions (in game.lua)
function updateGame(dt)
    game.update(dt)
end
