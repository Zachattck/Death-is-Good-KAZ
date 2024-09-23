-- Game states
local currentState = "menu" -- Initially in the menu state
local selectedOption = 1    -- Track selected menu option

-- List of menu options
local menuOptions = {"Start Game", "Exit"}

-- Load the title image
local titleImage

-- Love2D callbacks
function love.load()
    love.graphics.setFont(love.graphics.newFont(30)) -- Set font size for the menu
    
    -- Load the title image
    titleImage = love.graphics.newImage("assets/title.png")
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
        drawMenu()
    elseif currentState == "playing" then
        drawGame()
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
    love.graphics.draw(titleImage, (love.graphics.getWidth() - imageWidth) / 2, 50)
    
    -- Draw menu options below the image
    for i, option in ipairs(menuOptions) do
        local color = {1, 1, 1}
        if i == selectedOption then
            color = {1, 0, 0} -- Highlight selected option
        end
        love.graphics.setColor(color)
        love.graphics.printf(option, 0, 200 + i * 50, love.graphics.getWidth(), "center")
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
    -- Game logic here
end

function drawGame()
    love.graphics.printf("Game Playing!", 0, 100, love.graphics.getWidth(), "center")
end
