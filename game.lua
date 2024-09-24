local game = {}
local player = require("player")
local pauseMenu = require("pauseMenu")
local screenWidth, screenHeight = 1920, 1080

-- Define a table to hold the wall properties
local wall = {}

function game.load()
    player.load()  -- Load the player

    -- Load the wall image in game.lua
    wall.image = love.graphics.newImage("assets/mapPlatforms.png")
    wall.x = 0
    wall.y = 0
    wall.width = wall.image:getWidth()
    wall.height = wall.image:getHeight()

    -- Load the camera module and initialize it
    local Camera = require("camera")
    cam = Camera()  -- Initialize the camera object
    cam:setZoom(3)  -- Set the zoom level to 2x (you can adjust this value)
end


function game.handleGameInput(key)
    -- If the game is paused, don't handle input for the game
    if not pauseMenu.isPaused() then
        player.handlePlayerInput(key)
    end
end

function game.update(dt)
    -- Update only if the game is not paused
    if not pauseMenu.isPaused() then
        player.update(dt)  -- Update the player
    end
    ---camera
    cam:lookAt(player.x , player.y )
end


function game.draw()
    -- Attach the camera before drawing the game world
    cam:attach()  -- Make sure this is a method call, not an assignment

    -- Draw the wall image
    love.graphics.draw(wall.image, wall.x, wall.y)

    -- Draw the player and other game objects
    player.draw()

    -- Detach the camera after drawing the game world
    cam:detach()

    -- Draw the pause menu
    pauseMenu.draw()
end
    
-- Capture keypress events and pass them to handleGameInput
function love.keypressed(key)
    -- Toggle pause when escape is pressed
    if key == "escape" then
        pauseMenu.toggle()
    end

    -- Handle game input only if the game is not paused
    if not pauseMenu.isPaused() then
        game.handleGameInput(key)
    end
    ---camera detach
    cam.detach()
end

return game
