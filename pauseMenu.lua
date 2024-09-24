local pauseMenu = {}
local isPaused = false

function pauseMenu.toggle()
    isPaused = not isPaused
end

function pauseMenu.isPaused()
    return isPaused
end

function love.load()
    screenWidth, screenHeight = love.graphics.getDimensions() 
end

function love.keypressed(key)
    -- Toggle the pause state. If paused, unpause
    if currentState == "playing" and key == "escape" then
        isPaused = not isPaused
    elseif currentState == "menu" then
        handleMenuInput(key)
    end
end

function love.update(dt)
    if currentState == "playing" then
        if not pauseMenu.isPaused() then
            game.update(dt)  -- Update the game only when not paused
        end
    end
end

function pauseMenu.draw()
    if currentState == "menu" then
        drawMenu()  -- Draw the menu when in the "menu" state
    elseif currentState == "playing" then
        drawGame()  -- Draw the game when in the "playing" state

        -- Draw the pause screen if paused
        if isPaused then
            -- Dim the game screen with a transparent black rectangle
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

            -- Reset the color to white for the text
            love.graphics.setColor(1, 1, 1)

            -- Display the "Paused" text in the center of the screen
            love.graphics.printf("Paused", 0, screenHeight / 2, screenWidth, "center")
        end
    end
end

return pauseMenu