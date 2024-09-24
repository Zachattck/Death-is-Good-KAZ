local game = {}
local player = require("player")
local pauseMenu = require("pauseMenu")
local screenWidth, screenHeight = 1920, 1080

-- Define a table to hold the wall properties
local wall = {}

--storing the camera position
local cameraX, cameraY

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
    --- Set camera position to follow the player
    cameraX, cameraY = player.x, player.y
    cam:lookAt(player.x, player.y, player.width, player.height)

end

function game.draw()
    -- Attach the camera before drawing the game world
    cam:attach()

    -- Draw the wall image
    love.graphics.draw(wall.image, wall.x, wall.y)

    -- Draw the player and other game objects
    player.draw()

    -- Draw the lighting mask before detaching the camera (so it uses world coordinates)
    drawLightingMask()

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

function drawLightingMask()
    -- Get the current camera position (assuming cam:position() gives the camera's center position)
    local cameraX, cameraY = cam:position()
    local zoom = cam.zoom  -- Use cam.scale or cam.zoom depending on your camera module

    -- Adjust the mask radius according to the zoom level
    local maskRadius = 150 / zoom  -- Dividing by zoom ensures the mask scales properly when zooming in or out

    -- Set up the stencil function for masking
    love.graphics.stencil(function()
        -- Define a circle mask at the center of the camera
        love.graphics.circle("fill", cameraX, cameraY, maskRadius)
    end, "replace", 1)

    -- Use the stencil to draw a dark overlay with a hole (the mask)
    love.graphics.setStencilTest("less", 1)

    -- Draw the dark overlay (lighting effect) relative to the camera position
    -- Offset the rectangle based on the camera's position so it aligns with the circle mask
    local rectangleX = cameraX - (screenWidth / 2) / zoom
    local rectangleY = cameraY - (screenHeight / 2) / zoom

    -- Draw the dark overlay (scaled to account for zoom)
    love.graphics.setColor(0, 0, 0, 0.8)  -- Dark, semi-transparent color -- CHANGE WHEN FULL GAME
    love.graphics.rectangle("fill", rectangleX, rectangleY, screenWidth / zoom, screenHeight / zoom)

    -- Reset stencil test and color
    love.graphics.setStencilTest()
    love.graphics.setColor(1, 1, 1)  -- Reset to white for future drawings
end




return game
