-- pauseMenu.lua
local pauseMenu = {}
local isPaused = false

function pauseMenu.toggle()
    isPaused = not isPaused
end

function pauseMenu.isPaused()
    return isPaused
end

function pauseMenu.draw()
    if isPaused then
        -- Dim the game screen with a transparent black rectangle
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        -- Display the "Paused" text in the center of the screen
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(50))  -- Larger font for the pause menu
        love.graphics.printf("Paused", 0, love.graphics.getHeight() / 2 - 50, love.graphics.getWidth(), "center")
        
    end
end

return pauseMenu
