local game = {}
local wall = {}
local player = require("player")
local pauseMenu = require("pauseMenu")
local screenWidth, screenHeight = love.graphics.getDimensions()

-- Flicker parameters
local flickerTimer = 0
local flickerInterval = 0.01
local flickerStrength = 3
local flickerOffset = 0

-- Camera
local cameraX, cameraY

function game.load()
    -- Load the camera module and initialize it
    local Camera = require("camera")
    cam = Camera()
    cam:setZoom(4)

    
    -- Load the wall image
    wall.image = love.graphics.newImage("assets/mapPlatforms.png")
    wall.x = 0
    wall.y = 0
    wall.width = wall.image:getWidth()
    wall.height = wall.image:getHeight()

    player.load()
end

function game.handleGameInput(key)
    if not pauseMenu.isPaused() then
        player.handlePlayerInput(key)
    end
end

function game.update(dt)
    if not pauseMenu.isPaused() then
        player.update(dt)
    end

    -- Set camera position to follow the player
    cam:lookAt(player.x, player.y, player.width, player.height)

    -- Debug: Print player and camera positions for troubleshooting
    print("Player Position: ", player.x, player.y)
    print("Camera Position: ", cam.x, cam.y)

    -- Flicker logic (if any lighting flicker effect exists)
    flickerTimer = flickerTimer + dt
    if flickerTimer >= flickerInterval then
        flickerOffset = math.random(-flickerStrength, flickerStrength)
        flickerTimer = 0
    end
end



function game.draw()
    -- Clear the screen
    love.graphics.clear(0, 0, 0, 1)

    -- Step 1: Attach the camera for drawing world objects
    cam:attach()

    -- Step 2: Draw the background (e.g., the wall)
    love.graphics.setColor(1, 1, 1)  -- Reset color to normal
    love.graphics.draw(wall.image, wall.x, wall.y)

    -- Step 3: Draw the player
    player.draw()

    -- Step 4: Detach the camera to draw UI or effects
    cam:detach()

    -- Step 5: Draw the lighting effect (which includes the stencil-based darkness and light punch-through)
    drawLightingEffect()

    -- Draw the pause menu if necessary
    pauseMenu.draw()
end


function drawLightingEffect()
    -- Retrieve zoom level
    local zoom = cam.zoom or 1  -- Default to 1 if zoom is nil

    -- Manual offsets for fine-tuning the light position
    local offsetX = 570  -- Adjust this value to move the light horizontally
    local offsetY = 220  -- Adjust this value to move the light vertically

    -- Calculate the player's center position in world coordinates
    local playerCenterX = player.x + player.width / 2
    local playerCenterY = player.y + player.height / 2

    -- Convert player's position to screen coordinates using camera's transformation
    local playerScreenX = (playerCenterX - cam.x) * zoom + screenWidth / 2 + offsetX
    local playerScreenY = (playerCenterY - cam.y) * zoom + screenHeight / 2 + offsetY

    -- Step 1: Define the stencil function to create the light mask
    love.graphics.stencil(function()
        -- Draw the base light circle to define where the light will be visible
        love.graphics.circle("fill", playerScreenX, playerScreenY, 150)
    end, "replace", 1)

    -- Step 2: Enable stencil test to punch a hole in the darkness (where the light will be visible)
    love.graphics.setStencilTest("equal", 0)

    -- Step 3: Draw the dark rectangle relative to the camera with the same offsets
    love.graphics.setColor(0, 0, 0, 0.99)  -- Adjust alpha for darkness
    -- Draw the rectangle based on the camera's screen coordinates with offsets
    love.graphics.rectangle("fill",0,0, 1920 ,1080)

    -- Step 4: Disable the stencil test so that the light can be drawn freely
    love.graphics.setStencilTest()

    -- Step 5: Now draw the actual light circles
    local baseRadius = 80 + flickerOffset  -- Base radius of the light
    local layers = 10  -- Number of layers for the light
    local yellowHue = {1, 1, 0.8}  -- Slight yellow hue for the light effect

    -- Draw each layer with decreasing alpha and increasing size
    for i = layers, 1, -1 do
        local radius = baseRadius + (i * 15)  -- Increase radius for each layer
        local alpha = 0.05 * (i / layers)  -- Decrease alpha with each layer
        love.graphics.setColor(yellowHue[1] * (i / layers), yellowHue[2] * (i / layers), yellowHue[3], alpha)
        love.graphics.circle("fill", playerScreenX, playerScreenY, radius)
    end

    -- Reset the color for future drawing operations
    love.graphics.setColor(1, 1, 1, 1)
end





-- Capture keypress events and pass them to handleGameInput
function love.keypressed(key)
    if key == "escape" then
        pauseMenu.toggle()
    end

    if not pauseMenu.isPaused() then
        game.handleGameInput(key)
    end
end

return game
