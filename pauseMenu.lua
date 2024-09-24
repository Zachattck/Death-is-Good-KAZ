local pauseMenu = {}
local isPaused = false

function pauseMenu.toggle()
    isPaused = not isPaused
end

function pauseMenu.isPaused()
    return isPaused
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
    if currentState == "playing" and not isPaused then
        updateGame(dt)
    end
end

function pauseMenu.draw()
     -- Draw menu elements
    if currentState == "menu" then
        drawMenu()
        -- Draw game elements
    elseif currentState == "playing" then
        drawGame()
        if isPaused then
            -- Set color to black with 50% transparency
            love.graphics.setColor(0, 0, 0, 0.5)
            -- Dim the game screen
            love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
            -- Reset the color to white
            love.graphics.setColor(1, 1, 1)
            -- Display the "Paused" text in the center of the screen.
            love.graphics.printf("Paused", 0, screenHeight / 2, screenWidth, "center")
        end
    end
end

return pauseMenu