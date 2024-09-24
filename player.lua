-- player.lua
local player = {}
local bloodsplatter = require("bloodsplatter")



function player.load()
    player.x = 100
    player.y = 100
    player.width = 50
    player.height = 50


    bloodsplatter.load()  -- Load the blood splatter effect
end


function player.handlePlayerInput(key)
    if key == "space" then
        player.triggerBloodSplatter()
    end
end

function player.update(dt)

    bloodsplatter.update(dt)  -- Update the blood splatter
end

-- Function to trigger the blood splatter effect
function player.triggerBloodSplatter()
    bloodsplatter.trigger(player.x + player.width / 2, player.y + player.height / 2)
end

function player.draw()
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
    bloodsplatter.draw()  -- Draw the blood splatter effect
end

return player
