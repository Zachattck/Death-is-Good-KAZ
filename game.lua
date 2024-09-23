-- game.lua
local game = {}

function game.load()
    -- put loading code here for draw functions
end


function handleGameInput(key)
    -- put input code here
end


function game.update(dt)

    -- update code here
end

function game.draw()
    -- draw code here for drawing images
    love.graphics.printf("Game Playing!", 0, 100, love.graphics.getWidth(), "center")

end

return game  -- This is the critical part you're missing
