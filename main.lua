local game = require("game")  -- Assuming game.lua is in the same directory as main.lua
local pauseMenu = require("pauseMenu")
local CutsceneManager = require("CutsceneManager")
local player = require("player")
-- Game states
local currentState = "menu"  -- Initially in the menu state
local selectedOption = 1  -- Track selected menu option
local options = {"Start Game", "Options", "Exit"}  -- Main menu options

-- Music
local currentBackgroundMusic

-- Screen settings
local screenWidth, screenHeight = 1920, 1080

-- List of menu options (images)
local menuOptions = {}
local startImage, optionsImage, exitImage

-- Fonts
local akikaFont
-- Load the title image and background music
local titleImage
local levelImage

-- Load the images for options menu
local optionsBackgroundImage
local optionsMenuImageSlider
local optionMenuSliderKnob
local musicVolumeImage

-- Options menu settings
local volume = 1  -- Music volume (1 = max, 0 = mute)

-- Fade effect variables
local isFadingIn = true  -- Start with fade-in effect
local isFadingOut = false
local fadeAlpha = 1  -- Alpha starts fully opaque for fade-in
local fadeSpeed = 0.5  -- Speed of the fade effect
local nextState = nil  -- Store the next state after fade-out

-- Love2D callbacks
function love.load()
    -- Set screen size
    love.window.setMode(screenWidth, screenHeight)
    
    -- Set font size for the menu
    love.graphics.setFont(love.graphics.newFont(30))
    akikaFont = love.graphics.newFont("assets/AKIKA.ttf", 36)
    
    -- Load the title image for main menu
    titleImage = love.graphics.newImage("assets/title.png")

    -- Load the background image
    backgroundImage = love.graphics.newImage("assets/background.png")

    --load options menu images
    optionsBackgroundImage = love.graphics.newImage("assets/backgroundImageOptionsMenu.png")
    optionMenuSliderKnob = love.graphics.newImage("assets/sliderKnob.png")
    optionsMenuImageSlider = love.graphics.newImage("assets/sliderBackground.png")
    musicVolumeImage = love.graphics.newImage("assets/sandTexture.png")

    -- Load menu option images
    startImage = love.graphics.newImage("assets/start.png")
    optionsImage = love.graphics.newImage("assets/options.png")
    exitImage = love.graphics.newImage("assets/exit.png")
    menuOptions = {startImage, optionsImage, exitImage}

    -- Load and play background music
    currentBackgroundMusic = love.audio.newSource("assets/background_music.mp3", "stream")
    currentBackgroundMusic:setLooping(true)
    currentBackgroundMusic:play()

    game.load()
end
function love.update(dt)
    -- Handle fade transitions (in/out)
    if isFadingIn then
        fadeAlpha = math.max(fadeAlpha - fadeSpeed * dt, 0)
        isFadingIn = fadeAlpha > 0
    elseif isFadingOut then
        fadeAlpha = math.min(fadeAlpha + fadeSpeed * dt, 1)
        if fadeAlpha >= 1 then
            handleStateTransition()
        end
    end

    if game.currentState == "playing" then
        currentState = "playing"
    end
    -- Game state logic if not fading out
    if not isFadingOut then
        if currentState == "menu" then
            updateMenu()
        elseif currentState == "cutscene" then
            game.cutscene:update(dt)
        elseif currentState == "playing" then
        
            game.update(dt)
            player.update(dt)
        end
    end
    if pauseMenu.isPaused() then
        return  -- Skip the rest of the update logic
    end
end

-- Handle transitioning between states after fade out
function handleStateTransition()
    isFadingOut = false
    if nextState == "exit" then
        love.event.quit()
    elseif nextState == "cutscene" then
        game.startCutscene(currentMusic, volume)
        currentState = "cutscene"
    else
        currentState = nextState
    end
    isFadingIn = true  -- Start fading in again after transition
end


function love.volumeChecker()
    return volume
end

function love.draw()
    love.graphics.clear(0, 0, 0, 1)  -- Clear with a black background
    
    -- Delegate drawing based on the current game state
    if currentState == "menu" then
        drawMenu()
    elseif currentState == "options" then
        drawOptionsMenu()
    elseif currentState == "cutscene" or currentState == "playing" then
        game.draw()
    end

    if pauseMenu.isPaused() then
        pauseMenu.draw()
    end

    -- Draw the fade effect on top of everything if fading
    if isFadingIn or isFadingOut then
        love.graphics.setColor(0, 0, 0, fadeAlpha)
        love.graphics.rectangle("fill", 2000, 2000, screenWidth, screenHeight)
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color after drawing
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if currentState == "menu" then
            handleMenuMouseInput(x, y)
        elseif currentState == "options" then
            handleOptionsMenuMouseInput(x, y)
        end
    end
end

-- Menu functions
function drawMenu()
    -- Draw background and menu options
    local scale = 0.4  -- Adjust this value to make images smaller or larger
    local buttonSpacing = 20  -- Spacing between buttons

    for i, option in ipairs(menuOptions) do
        local optionWidth = option:getWidth() * scale
        local optionHeight = option:getHeight() * scale
        local x = (screenWidth - optionWidth) / 2
        local y = 400 + ((optionHeight + buttonSpacing) * (i - 1))
        
        love.graphics.setColor(1, 1, 1)  -- Normal color for unselected options
        love.graphics.draw(option, x, y, 0, scale, scale)
    end
end

function handleMenuMouseInput(x, y)
    -- Detect click on the "Start Game" button to trigger the cutscene
    local scale = 0.40
    local buttonYStart = 400
    local startImageWidth = startImage:getWidth() * scale
    local startImageHeight = startImage:getHeight() * scale

    if isMouseOverButton(x, y, startImageWidth, startImageHeight, (screenWidth - startImageWidth) / 2, buttonYStart) then
        triggerFadeOut("cutscene")
    end
end

function triggerFadeOut(state)
    -- Trigger fade out effect and store next state
    isFadingOut = true
    nextState = state
end

function updateMenu()
    -- Update hover detection
    local mouseX, mouseY = love.mouse.getPosition()
    local scale = 0.40  -- Same scale as used in drawing
    local buttonYStart = 400
    local buttonSpacing = 20

    -- Get the scaled dimensions of each button
    local startImageWidth = startImage:getWidth() * scale
    local startImageHeight = startImage:getHeight() * scale
    local optionsImageWidth = optionsImage:getWidth() * scale
    local optionsImageHeight = optionsImage:getHeight() * scale
    local exitImageWidth = exitImage:getWidth() * scale
    local exitImageHeight = exitImage:getHeight() * scale

    -- Hover detection based on the dynamically calculated Y positions
    isHoveringStart = isMouseOverButton(mouseX, mouseY, startImageWidth, startImageHeight, (screenWidth - startImageWidth) / 2, buttonYStart)
    isHoveringOptions = isMouseOverButton(mouseX, mouseY, optionsImageWidth, optionsImageHeight, (screenWidth - optionsImageWidth) / 2, buttonYStart + startImageHeight + buttonSpacing)
    isHoveringExit = isMouseOverButton(mouseX, mouseY, exitImageWidth, exitImageHeight, (screenWidth - exitImageWidth) / 2, buttonYStart + startImageHeight + optionsImageHeight + (buttonSpacing * 2))
end

function handleMenuMouseInput(x, y)
    -- Mouse input handling logic for the menu

    local scale = 0.40
    local buttonYStart = 400
    local buttonSpacing = 20
    local startImageWidth = startImage:getWidth() * scale
    local startImageHeight = startImage:getHeight() * scale
    local optionsImageWidth = optionsImage:getWidth() * scale
    local optionsImageHeight = optionsImage:getHeight() * scale
    local exitImageWidth = exitImage:getWidth() * scale
    local exitImageHeight = exitImage:getHeight() * scale

    -- Check if the mouse is over the "Start Game" button
    if isMouseOverButton(x, y, startImageWidth, startImageHeight, (screenWidth - startImageWidth) / 2, buttonYStart) then
        triggerFadeOut("cutscene")  -- Start game with cutscene
    end

    -- Check if the mouse is over the "Options" button
    if isMouseOverButton(x, y, optionsImageWidth, optionsImageHeight, (screenWidth - optionsImageWidth) / 2, buttonYStart + startImageHeight + buttonSpacing) then
        currentState = "options"  -- Switch to the options menu
    end

    -- Check if the mouse is over the "Exit" button
    if isMouseOverButton(x, y, exitImageWidth, exitImageHeight, (screenWidth - exitImageWidth) / 2, buttonYStart + startImageHeight + optionsImageHeight + (buttonSpacing * 2)) then
        triggerFadeOut("exit")  -- Exit the game
    end
end

function drawMenu()
    local imageScaleFactor = 1.25  -- Scale factor for the images

    -- Get the background image width and height
    local backgroundWidth = backgroundImage:getWidth() * imageScaleFactor
    local backgroundHeight = backgroundImage:getHeight() * imageScaleFactor

    -- Calculate the position to center the background image
    local backgroundX = (screenWidth - backgroundWidth) / 2
    local backgroundY = (screenHeight - backgroundHeight) / 2

    -- Draw the centered background image
    love.graphics.draw(backgroundImage, backgroundX, backgroundY, 0, imageScaleFactor, imageScaleFactor)
    
    -- Draw the title image at the top of the screen
    local titleScale = 0.25  -- Scale factor for the title image
    local titleWidth = titleImage:getWidth() * titleScale
    local titleHeight = titleImage:getHeight() * titleScale
    local titleX = (screenWidth - titleWidth) / 2
    love.graphics.draw(titleImage, titleX, 65, 0, titleScale, titleScale)

    -- Set the scale for the menu option images
    local scale = 0.4  -- Adjust this value to make images smaller or larger
    local buttonSpacing = 20  -- Spacing between buttons

    -- Draw menu buttons and highlight the one that is hovered over
    for i, option in ipairs(menuOptions) do
        -- Get the original width and height of the images
        local optionWidth = option:getWidth() * scale
        local optionHeight = option:getHeight() * scale

        -- Calculate the position to center the scaled images
        local x = (screenWidth - optionWidth) / 2
        local y = 400 + ((optionHeight + buttonSpacing) * (i - 1))  -- Dynamically position buttons

        -- Highlight the selected option or hover by changing color
        if (i == 1 and isHoveringStart) or (i == 2 and isHoveringOptions) or (i == 3 and isHoveringExit) then
            love.graphics.setColor(0.5, 0.5, 0.5)  -- Highlight hovered option (grey)
        else
            love.graphics.setColor(1, 1, 1)  -- Normal color (white)
        end

        -- Draw the image with scaling applied
        love.graphics.draw(option, x, y, 0, scale, scale)
    end

    -- Reset color to white to prevent hover effects from affecting the fade
    love.graphics.setColor(1, 1, 1)

    -- Draw the fade effect on top of everything
    if isFadingIn or isFadingOut then
        love.graphics.setColor(0, 0, 0, fadeAlpha)  -- Black with changing opacity for fade
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        love.graphics.setColor(1, 1, 1)  -- Reset color after drawing the fade
    end
end


function isMouseOverButton(mouseX, mouseY, buttonWidth, buttonHeight, buttonX, buttonY)
    return mouseX >= buttonX and mouseX <= buttonX + buttonWidth and mouseY >= buttonY and mouseY <= buttonY + buttonHeight
end

-- Draw the Options Menu
function drawOptionsMenu()
    -- Draw the background image
    local backgroundWidth = optionsBackgroundImage:getWidth()
    local backgroundHeight = optionsBackgroundImage:getHeight()
    local backgroundX = (screenWidth - backgroundWidth) / 2
    local backgroundY = (screenHeight - backgroundHeight) / 2
    love.graphics.draw(optionsBackgroundImage, backgroundX, backgroundY)

    -- Set scale for images
    local optionsMenuImageScale = 1  -- Make the options image smaller and set it at the top

    -- Draw "Options Menu" image (scaled down and centered at the top)
    local optionsMenuImageWidth = optionsImage:getWidth() * optionsMenuImageScale
    local optionsMenuImageHeight = optionsImage:getHeight() * optionsMenuImageScale
    love.graphics.draw(optionsImage, (screenWidth - optionsMenuImageWidth) / 2, 50, 0, optionsMenuImageScale, optionsMenuImageScale)

    -- Adjustable values for the slider knob and fill Y position
    local sliderYOffset = 100  -- Adjust this value to move the slider knob and fill vertically

    -- Slider background size (making the image larger than the slider itself)
    local sliderBackgroundWidth = 600  -- Set a larger width for the slider background
    local sliderBackgroundHeight = 50  -- Set a larger height for the slider background
    local sliderX = (screenWidth - sliderBackgroundWidth) / 2
    local sliderY = screenHeight / 2 - sliderYOffset  -- Center the slider vertically

    -- Draw "Volume" text above the slider using the AKIKA font
    love.graphics.setFont(akikaFont)  -- Set the AKIKA font
    love.graphics.printf("Volume", 0, sliderY - 60, screenWidth, "center")  -- Draw centered "Volume" above the slider

    -- Draw the larger slider background image
    love.graphics.draw(optionsMenuImageSlider, sliderX, sliderY, 0, sliderBackgroundWidth / optionsMenuImageSlider:getWidth(), sliderBackgroundHeight / optionsMenuImageSlider:getHeight())

    -- Slider fill dimensions (smaller than the background)
    local actualSliderWidth = 500  -- Slider width inside the background
    local actualSliderHeight = 30  -- Slider height inside the background
    local actualSliderX = sliderX + (sliderBackgroundWidth - actualSliderWidth) / 2  -- Center the slider within the background
    local actualSliderY = sliderY + (sliderBackgroundHeight - actualSliderHeight) / 2  -- Vertically center the slider inside the background

    -- Draw the fill inside the slider background
    local musicFillWidth = volume * actualSliderWidth  -- The fill width is based on the volume
    local textureScaleX = musicFillWidth / musicVolumeImage:getWidth()
    local textureScaleY = actualSliderHeight / musicVolumeImage:getHeight()  -- Adjust fill height
    love.graphics.draw(musicVolumeImage, actualSliderX, actualSliderY, 0, textureScaleX, textureScaleY)

    -- Reset the color to white for the knob
    love.graphics.setColor(1, 1, 1)

    -- Draw the slider knob, positioned according to the volume fill
    local handleX = actualSliderX + (volume * actualSliderWidth)
    local handleWidth = optionMenuSliderKnob:getWidth() * (actualSliderHeight / optionMenuSliderKnob:getHeight()) * 1.5  -- Make the knob bigger
    local handleHeight = actualSliderHeight * 1.5  -- Adjust knob height for visibility
    love.graphics.draw(optionMenuSliderKnob, handleX - handleWidth / 2, actualSliderY - (handleHeight - actualSliderHeight) / 2, 0, handleWidth / optionMenuSliderKnob:getWidth(), handleHeight / optionMenuSliderKnob:getHeight())

    -- Draw "Back to Menu" using the exitImage as a button
    local backButtonWidth = exitImage:getWidth() * 0.6  -- Scale down the exit image
    local backButtonHeight = exitImage:getHeight() * 0.6
    local backButtonX = (screenWidth - backButtonWidth) / 2
    local backButtonY = sliderY + sliderBackgroundHeight + 100  -- Position the back button below the slider

    -- Check if hovering over the "Back to Menu" button to darken it
    if isMouseOverButton(love.mouse.getX(), love.mouse.getY(), backButtonWidth, backButtonHeight, backButtonX, backButtonY) then
        love.graphics.setColor(0.5, 0.5, 0.5)  -- Darken the button if hovered
    else
        love.graphics.setColor(1, 1, 1)  -- Normal color
    end

    -- Draw the exitImage as the "Back to Menu" button
    love.graphics.draw(exitImage, backButtonX, backButtonY, 0, 0.6, 0.6)

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Handle mouse input for the options menu
function handleOptionsMenuMouseInput(x, y)
    -- Check if the mouse is over the slider handle
    if isMouseOverVolumeHandle(x, y) then
        isDraggingVolume = true  -- Start dragging the volume handle
    else
        -- Handle "Back to Menu" button using the exitImage
        local backButtonWidth = exitImage:getWidth() * 0.6
        local backButtonHeight = exitImage:getHeight() * 0.6
        local backButtonX = (screenWidth - backButtonWidth) / 2
        local backButtonY = screenHeight / 2 + 100

        if isMouseOverButton(x, y, backButtonWidth, backButtonHeight, backButtonX, backButtonY) then
            triggerFadeOut("menu")  -- Fade out to menu
        end
    end
end

-- Check if the mouse is over the volume handle (knob)
function isMouseOverVolumeHandle(mouseX, mouseY)
    local sliderBackgroundWidth = 600
    local actualSliderWidth = 500
    local sliderX = (screenWidth - sliderBackgroundWidth) / 2
    local actualSliderX = sliderX + (sliderBackgroundWidth - actualSliderWidth) / 2
    local sliderY = screenHeight / 2 - 100
    local handleX = actualSliderX + (volume * actualSliderWidth)
    local handleRadius = optionMenuSliderKnob:getWidth() * 1.5 / 2  -- Adjust knob size
    return math.abs(mouseX - handleX) <= handleRadius and mouseY >= sliderY and mouseY <= sliderY + 50
end

-- Helper function to check if the mouse is over a button
function isMouseOverButton(mouseX, mouseY, buttonWidth, buttonHeight, buttonX, buttonY)
    return mouseX >= buttonX and mouseX <= buttonX + buttonWidth and mouseY >= buttonY and mouseY <= buttonY + buttonHeight
end

-- Handle mouse release for volume dragging
function love.mousereleased(x, y, button)
    if button == 1 then
        -- Stop dragging the volume handle
        isDraggingVolume = false
    end
end

-- Handle mouse movement while dragging the volume slider
function love.mousemoved(x, y, dx, dy)
    if isDraggingVolume then
        -- Calculate the slider movement based on the mouse X position
        local sliderBackgroundWidth = 600
        local actualSliderWidth = 500
        local sliderX = (screenWidth - sliderBackgroundWidth) / 2
        local actualSliderX = sliderX + (sliderBackgroundWidth - actualSliderWidth) / 2

        -- Calculate the new volume value based on mouse X position
        volume = (x - actualSliderX) / actualSliderWidth
        volume = math.max(0, math.min(1, volume))  -- Clamp the volume between 0 and 1

        -- Set the music volume accordingly
        currentBackgroundMusic:setVolume(volume)
    end
end
