local game = {}
local player = require("player")

function game.load()
    player.load()  -- Load the player
end

function game.handleGameInput(key)
    -- Handle specific key presses
    player.handlePlayerInput(key)
end

function game.update(dt)
    player.update(dt)  -- Update the player
end

function game.draw()
    love.graphics.printf("Game Playing!", 0, 100, love.graphics.getWidth(), "center")
    player.draw()  -- Draw the player and effects
end

-- Capture keypress events and pass them to handleGameInput
function love.keypressed(key)
    handleGameInput(key)
end

return game
