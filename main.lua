
local game = require("game")  -- Assuming game.lua is in the same directory as main.lua

-- Game states
local currentState = "menu" -- Initially in the menu state
local selectedOption = 1    -- Track selected menu option

-- Screen settings
local screenWidth, screenHeight = 1920, 1080

-- List of menu options (images)
local menuOptions = {}
local startImage, exitImage

-- Load the title image and background music
local titleImage
local backgroundMusic
local levelImage 
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
    exitImage = love.graphics.newImage("assets/exit.png")
    menuOptions = {startImage, exitImage}

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
    elseif currentState == "playing" then
        updateGame(dt)
    end
end

function love.draw()
    if currentState == "menu" then
        -- Menu drawing logic
        drawMenu()
    elseif currentState == "playing" then
        -- Call draw logic from game.lua
        game.draw()
    end
end

function love.keypressed(key)
    if currentState == "menu" then
        handleMenuInput(key)
    elseif currentState == "playing" then
        -- Add game controls here, like player movement
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

    -- Draw menu option images (Start and Exit)
    for i, option in ipairs(menuOptions) do
        -- Get the original width and height of the images
        local optionWidth = option:getWidth() * scale
        local optionHeight = option:getHeight() * scale

        -- Calculate the position to center the scaled images
        local x = (screenWidth - optionWidth) / 2
        local y = 200 + i * 100

        -- Highlight the selected option by changing color or adding a border (optional)
        if i == selectedOption then
            love.graphics.setColor(1, 0, 0)  -- Highlight selected option in red
        else
            love.graphics.setColor(1, 1, 1)  -- Normal color for unselected options
        end

        -- Draw the image with scaling applied
        love.graphics.draw(option, x, y, 0, scale, scale)
    end

    love.graphics.setColor(1, 1, 1) -- Reset color
end


function updateMenu()
    -- Placeholder for any logic if needed
end

function handleMenuInput(key)
    if key == "down" then
        selectedOption = selectedOption + 1
        if selectedOption > #menuOptions then
            selectedOption = 1 -- Loop back to the top
        end
    elseif key == "up" then
        selectedOption = selectedOption - 1
        if selectedOption < 1 then
            selectedOption = #menuOptions -- Loop to the bottom
        end
    elseif key == "return" or key == "enter" then
        if selectedOption == 1 then
            currentState = "playing" -- Start the game
        elseif selectedOption == 2 then
            love.event.quit() -- Exit game
        end
    end
end

-- Game functions (these are placeholders for your actual game)
function updateGame(dt)

game.update(dt)
end
