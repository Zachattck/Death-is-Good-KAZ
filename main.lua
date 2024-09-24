local game = require("game")  -- Assuming game.lua is in the same directory as main.lua

local pauseMenu = require("pauseMenu")

-- Game states
local currentState = "menu" -- Initially in the menu state
local selectedOption = 1    -- Track selected menu option
local options = {"Start Game", "Options", "Exit"}  -- Main menu options

-- Screen settings
local screenWidth, screenHeight = 1920, 1080

-- List of menu options (images)
local menuOptions = {}
local startImage, optionsImage, exitImage

--Fonts
local akikaFont
-- Load the title image and background music
local titleImage
local backgroundMusic
local levelImage 

-- Load the images for options menu
local optionsBackgroundImage
local optionsMenuImageSlider
local optionMenuSliderKnob
local musicVolumeImage
    

-- Options menu settings
local selectedOptionOption = 1  -- Track selected option in the options menu
local volume = 1  -- Music volume (1 = max, 0 = mute)
local volumeBarX, volumeBarY = 300, 250  -- Position of the volume bar
local volumeBarWidth, volumeBarHeight = 300, 20  -- Size of the volume bar
local volumeHandleRadius = 10 -- Handle size for the volume adjustment
local sliderScale = 0.5  -- Scale for consistency

-- Mouse hover tracking for menu options
local isHoveringStart = false
local isHoveringOptions = false
local isHoveringExit = false
local isDraggingVolume = false  -- Track if volume handle is being dragged



-- Fade effect variables
local isFadingIn = true  -- Start with fade-in effect
local isFadingOut = false
local fadeAlpha = 1  -- Alpha starts fully opaque for fade-in
local fadeSpeed = 0.5 -- Speed of the fade effect
local nextState = nil  -- Store the next state after fade-out


-- Love2D callbacks
function love.load()
    
    -- Set screen size
    love.window.setMode(screenWidth, screenHeight)
    
    -- Set font size for the menu
    love.graphics.setFont(love.graphics.newFont(30))
    --font
    akikaFont = love.graphics.newFont("assets/AKIKA.ttf", 36)
    -- Load the title image for main menu
    titleImage = love.graphics.newImage("assets/title.png")

    -- Load the background image
    backgroundImage = love.graphics.newImage("assets/background.png")
    
    -- Load menu option images
    startImage = love.graphics.newImage("assets/start.png")
    optionsImage = love.graphics.newImage("assets/options.png")  -- Added for options menu
    exitImage = love.graphics.newImage("assets/exit.png")
    menuOptions = {startImage, optionsImage, exitImage}

    levelImage = love.graphics.newImage("assets/levelImage.png")

    -- Load and play background music
    backgroundMusic = love.audio.newSource("assets/background_music.mp3", "stream")
    backgroundMusic:setLooping(true)
    love.audio.play(backgroundMusic)

    loadOptionsMenuImages()  -- Load images for the options menu

    game.load()
end

function loadOptionsMenuImages()
    optionsBackgroundImage = love.graphics.newImage("assets/backgroundImageOptionsMenu.png")
    optionsMenuImageSlider = love.graphics.newImage("assets/sliderBackground.png")
    optionMenuSliderKnob = love.graphics.newImage("assets/sliderKnob.png")
    musicVolumeImage = love.graphics.newImage("assets/sandTexture.png")
end

function love.update(dt)
    -- Update fade effect
    if isFadingIn then
        fadeAlpha = fadeAlpha - fadeSpeed * dt
        if fadeAlpha <= 0 then
            fadeAlpha = 0
            isFadingIn = false  -- Stop fading in when complete
        end
    elseif isFadingOut then
        fadeAlpha = fadeAlpha + fadeSpeed * dt
        if fadeAlpha >= 1 then
            fadeAlpha = 1
            isFadingOut = false  -- Stop fading out when complete

            -- Handle the state change after fade-out
            if nextState == "exit" then
                love.event.quit()  -- Close the game if 'exit' is selected
            else
                currentState = nextState  -- Switch to the next state
                isFadingIn = true  -- Start fading in after state change
            end
        end
    end

    -- Only update game logic if not fading out
    if not isFadingOut then
        if currentState == "menu" then
            updateMenu()
        elseif currentState == "playing" then
            if not pauseMenu.isPaused() then
                game.update(dt)
            end
        elseif currentState == "options" then
            -- Call volume set every frame while in the options menu to reflect slider position
            backgroundMusic:setVolume(volume)

            -- Update volume bar dragging if the knob is being dragged
            if isDraggingVolume then
                local mouseX = love.mouse.getX()

                -- Calculate new volume based on mouse position, keeping it within slider bounds
                local sliderX = (screenWidth - musicVolumeImage:getWidth() * 0.5) / 2
                local sliderWidth = musicVolumeImage:getWidth() * 0.5
                volume = math.min(math.max((mouseX - sliderX) / sliderWidth, 0), 1)

                -- Update background music volume as the knob moves
                backgroundMusic:setVolume(volume)
            end
        end
    end
end



function love.draw()
    if currentState == "menu" then
        drawMenu()
    elseif currentState == "options" then
        drawOptionsMenu()
    elseif currentState == "playing" then
        game.draw()
    elseif currentState == "isPaused" then
        pauseMenu.draw()
    end

    -- Draw the fade effect on top of everything
    if isFadingIn or isFadingOut then
        love.graphics.setColor(0, 0, 0, fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color after drawing
    end
end

-- Handle mouse input
function love.mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        if currentState == "menu" then
            handleMenuMouseInput(x, y)
        elseif currentState == "options" then
            -- Check if the user clicked the volume handle or bar to start dragging
            if isMouseOverVolumeHandle(x, y) then
                isDraggingVolume = true
            else
                handleOptionsMenuMouseInput(x, y)
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        -- Stop dragging the volume handle
        isDraggingVolume = false
    end
end
-- Pause game by "escape"
function love.keypressed(key)

    if currentState == "playing" then
        if key == "escape" then
            -- Toggle pause menu when escape is pressed
            pauseMenu.toggle()
        else
            if not pauseMenu.isPaused() then
                game.handleGameInput(key)
            end
        end
    end
end

-- Menu functions
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

    for i, option in ipairs(menuOptions) do
        -- Get the original width and height of the images
        local optionWidth = option:getWidth() * scale
        local optionHeight = option:getHeight() * scale

        -- Calculate the position to center the scaled images
        local x = (screenWidth - optionWidth) / 2
        local y = 400 + ((optionHeight + buttonSpacing) * (i - 1))  -- Dynamically position buttons

        -- Highlight the selected option or hover by changing color
        if (i == 1 and isHoveringStart) or (i == 2 and isHoveringOptions) or (i == 3 and isHoveringExit) then
            love.graphics.setColor(0.5, 0.5, 0.5)  -- Highlight hovered option
        else
            love.graphics.setColor(1, 1, 1)  -- Normal color for unselected options
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


-- Handle mouse input for the main menu
function handleMenuMouseInput(x, y)
    local scale = 0.40
    local buttonYStart = 400
    local buttonSpacing = 20

    -- Get the scaled dimensions of each button
    local startImageWidth = startImage:getWidth() * scale
    local startImageHeight = startImage:getHeight() * scale
    local optionsImageWidth = optionsImage:getWidth() * scale
    local optionsImageHeight = optionsImage:getHeight() * scale
    local exitImageWidth = exitImage:getWidth() * scale
    local exitImageHeight = exitImage:getHeight() * scale

    -- Check if Start Game was clicked
    if isMouseOverButton(x, y, startImageWidth, startImageHeight, (screenWidth - startImageWidth) / 2, buttonYStart) then
        triggerFadeOut("playing")  -- Start the game after fading out
    -- Check if Options was clicked
    elseif isMouseOverButton(x, y, optionsImageWidth, optionsImageHeight, (screenWidth - optionsImageWidth) / 2, buttonYStart + startImageHeight + buttonSpacing) then
        triggerFadeOut("options")  -- Go to options menu after fading out
    -- Check if Exit was clicked
    elseif isMouseOverButton(x, y, exitImageWidth, exitImageHeight, (screenWidth - exitImageWidth) / 2, buttonYStart + startImageHeight + optionsImageHeight + (buttonSpacing * 2)) then
        triggerFadeOut("exit")  -- Quit the game after fading out
    end
end



function triggerFadeOut(state)
    isFadingOut = true
    nextState = state  -- Set the next state to transition to after fading out
end



function drawOptionsMenu()
    -- Draw the background image
    local backgroundWidth = optionsBackgroundImage:getWidth()
    local backgroundHeight = optionsBackgroundImage:getHeight()
    local backgroundX = (screenWidth - backgroundWidth) / 2
    local backgroundY = (screenHeight - backgroundHeight) / 2
    love.graphics.draw(optionsBackgroundImage, backgroundX, backgroundY)

    -- Set scale for images
    local optionsMenuImageScale = 0.75  -- Make the options image smaller and set it at the top

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




-- Game functions (in game.lua)
function updateGame(dt)
    

    game.update(dt)
end

