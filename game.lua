local game = {}
local player = require("player")

-- Define a table to hold the wall properties
local wall = {}

function game.load()
    player.load()  -- Load the player

    -- Load the wall image in game.lua
    wall.image = love.graphics.newImage("assets/mapPlatforms.png")
    wall.x = 300
    wall.y = 200
    wall.width = wall.image:getWidth()
    wall.height = wall.image:getHeight()
end

function game.handleGameInput(key)
    -- Handle specific key presses
    player.handlePlayerInput(key)
end

function game.update(dt)
    player.update(dt)  -- Update the player
end

function game.draw()

    -- Draw the wall image
    love.graphics.draw(wall.image, wall.x, wall.y)

    player.draw()  -- Draw the player and effects
end

-- Capture keypress events and pass them to handleGameInput
function love.keypressed(key)
    game.handleGameInput(key)
end

return game
