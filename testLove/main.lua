WINDOW_WIDTH = 1464
WINDOW_HEIGHT = 850


function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT,{fullscreen = true})
end

    camera = require 'Codes/camera'
    cam = camera()

    

    -- Initialize puck
    local puck = {
        x = 722,
        y = 418,
        width = 0.10,
        height = 0.10,
        radius = 0.0564,
        speedX = 350,
        speedY = 350,
        sprite = love.graphics.newImage('sprites/puck.png')
    }
    -- Initialize box dimensions
    box = {
        width = 1464,
        height = 850,
        x = 0,
        y = 0
    }

    ---------TORONTO----------
    -- TOR Center
    local TORC = {
        x = 600,
        y = 415,
        speed = 6,
        width = 0.70,
        height = 0.70,
        radius = 0.40,
        sprite = love.graphics.newImage('sprites/TORC.png')
    }
    -- TOR Rwing
    TORR = {
        x = 600,
        y = 630,
        speed = 6,
        width = 0.70,
        height = 0.70,
        radius = 0.40,
        sprite = love.graphics.newImage('sprites/TORR.png')
    }
    -- TOR LWING
    TORL = {
        x = 600,
        y = 170,
        speed = 6,
        width = 0.70,
        height = 0.70,
        sprite = love.graphics.newImage('sprites/TORL.png')
    }
    --TOR DEFENCE
    TORD = {
        x = 300,
        y = 258,
        speed = 6,
        width = 0.70,
        height = 0.70,
        sprite = love.graphics.newImage('sprites/TORD.png')
    }
    --TOR DEFENCE1
    TORD1 = {
        x = 300,
        y = 542,
        speed = 6,
        width = 0.70,
        height = 0.70,
        sprite = love.graphics.newImage('sprites/TORD1.png')
    }

---------MONTREAL--------
    
    -- MTL Center
    MTLC = {
        x = 842,
        y = 415,
        speed = 6,
        width = 0.70,
        height = 0.70,
        sprite = love.graphics.newImage('sprites/MTLC.png')
    }

    -- MTL Rwing
    MTLR = {
        x = 842,
        y = 630,
        speed = 6,
        width = 0.70,
        height = 0.70,
        sprite = love.graphics.newImage('sprites/MTLR.png')
    }

    -- MTL Lwing
    MTLL = {
        x = 842,
        y = 170,
        speed = 6,
        width = 0.70,
        height = 0.70,
        sprite = love.graphics.newImage('sprites/MTLL.png')
    }

    -- MTL DEFENCE1
    MTLD1 = {
        x = 1145,
        y = 542,
        speed = 6,
        width = 0.70,
        height = 0.70,
        sprite = love.graphics.newImage('sprites/MTLD1.png')
    }

    -- MTL DEFENCE
    MTLD = {
        x = 1145,
        y = 258,
        speed = 6,
        width = 0.70,
        height = 0.70,
        sprite = love.graphics.newImage('sprites/MTLD.png')
    }

--------BACKGROUND----------

    -- Initialize background
    background = love.graphics.newImage('sprites/rink.png')

-- Clamp function to restrict values within min and max bounds
function clamp(value, min, max)
    return math.max(min, math.min(value, max))
end

function love.update(dt)
--------Puck Movement--------
    puck.x = puck.x + puck.speedX * dt
    puck.y = puck.y + puck.speedY * dt

    ----top collision------
if puck.y - puck.radius < 0 then
    puck.y = puck.radius
    puck.speedY = -puck.speedY
end

------- bottom collision------
if puck.y + puck.radius > box.height then 
    puck.y = box.height - puck.radius
    puck.speedY = -puck.speedY
end
-------Right side collision-------
if puck.x + puck.radius > box.width then 
    puck.x = box.width - puck.radius
    puck.speedX = -puck.speedX
end
-------Left side collision--------
if puck.x - puck.radius < 0 then
    puck.x = puck.radius
    puck.speedX = -puck.speedX
end
 
--------MONTREAL----------
    -- Move MTLC
    if love.keyboard.isDown("up") then
        MTLC.y = MTLC.y - MTLC.speed
    end
    if love.keyboard.isDown("down") then
        MTLC.y = MTLC.y + MTLC.speed
    end

    -- Move MTLR
     if love.keyboard.isDown("up") then
        MTLR.y = MTLR.y - MTLR.speed
    end
    if love.keyboard.isDown("down") then
        MTLR.y = MTLR.y + MTLR.speed
    end

    -- Move MTLL
    if love.keyboard.isDown("up") then
        MTLL.y = MTLL.y - MTLL.speed
    end
    if love.keyboard.isDown("down") then
        MTLL.y = MTLL.y + MTLL.speed
    end

    -- Move MTLD
    if love.keyboard.isDown("up") then
        MTLD.y = MTLD.y - MTLD.speed
    end
    if love.keyboard.isDown("down") then
        MTLD.y = MTLD.y + MTLD.speed
    end

    -- Move MTLD1
    if love.keyboard.isDown("up") then
        MTLD1.y = MTLD1.y - MTLD1.speed
    end
        if love.keyboard.isDown("down") then
        MTLD1.y = MTLD1.y + MTLD1.speed
    end

-------TORONTO----------

    -- Move TORC
    if love.keyboard.isDown("w") then
        TORC.y = TORC.y - TORC.speed
    end
    if love.keyboard.isDown("s") then
        TORC.y = TORC.y + TORC.speed
    end

    -- Move TORR
    if love.keyboard.isDown("w") then
        TORR.y = TORR.y - TORR.speed
    end
    if love.keyboard.isDown("s") then
        TORR.y = TORR.y + TORR.speed
    end

    -- Move TORL
    if love.keyboard.isDown("w") then
        TORL.y = TORL.y - TORL.speed
    end
    if love.keyboard.isDown("s") then
        TORL.y = TORL.y + TORL.speed
    end

    -- Move TORD
    if love.keyboard.isDown("q") then
        TORD.y = TORD.y - TORD.speed
    end
    if love.keyboard.isDown("a") then
        TORD.y = TORD.y + TORD.speed
    end

    -- Move TORD1
    if love.keyboard.isDown("q") then
        TORD1.y = TORD1.y - TORD1.speed
    end
    if love.keyboard.isDown("a") then
        TORD1.y = TORD1.y + TORD1.speed
    end
    -- Clamp player and player1 within box bounds
    local boxRight = box.x + box.width
    local boxBottom = box.y + box.height

    TORC.y = clamp(TORC.y, box.y + TORC.height / 2, boxBottom - TORC.height / 2)
    TORR.y = clamp(TORR.y, box.y + TORR.height / 2, boxBottom - TORR.height / 2)
    TORL.y = clamp(TORL.y, box.y + TORL.height / 2, boxBottom - TORL.height / 2)
    TORD.y = clamp(TORD.y, box.y + TORD.height / 2, boxBottom - TORD.height / 2)
    TORD1.y = clamp(TORD1.y, box.y + TORD1.height / 2, boxBottom - TORD1.height / 2)
    
    MTLC.y = clamp(MTLC.y, box.y + MTLC.height / 2, boxBottom - MTLC.height / 2)
    MTLR.y = clamp(MTLR.y, box.y + MTLR.height / 2, boxBottom - MTLR.height / 2)
    MTLL.y = clamp(MTLL.y, box.y + MTLL.height / 2, boxBottom - MTLL.height / 2)
    MTLD.y = clamp(MTLD.y, box.y + MTLD.height / 2, boxBottom - MTLD.height / 2)
    MTLD1.y = clamp(MTLD1.y, box.y + MTLD1.height / 2, boxBottom - MTLD1.height / 2)

    cam:lookAt(background:getWidth()/2, background:getHeight()/2)
end

---------End Game Function-----------
    function love.keypressed(key)
        if key == 'escape' then
            love.event.quit()
    end
    ---- collision----
    if puck.x + puck.radius < TORC.x +TORC.height and
    puck.y + puck.radius > TORC.y + TORC.width then
        puck.speedX = -puck.speedX 
    end
end
function love.draw()

    cam:attach()
        love.graphics.draw(background, 0, 0)
        love.graphics.rectangle("line", box.x, box.y, box.width, box.height)


        -- Toronto Sprites
        love.graphics.draw(TORC.sprite, TORC.x, TORC.y, 0, TORC.width, TORC.height, TORC.sprite:getWidth()/2, TORC.sprite:getHeight()/2)
        love.graphics.draw(TORR.sprite, TORR.x, TORR.y, 0, TORR.width, TORR.height, TORR.sprite:getWidth()/2, TORR.sprite:getHeight()/2)
        love.graphics.draw(TORL.sprite, TORL.x, TORL.y, 0, TORL.width, TORL.height, TORL.sprite:getWidth()/2, TORL.sprite:getHeight()/2)
        love.graphics.draw(TORD.sprite, TORD.x, TORD.y, 0, TORD.width, TORD.height, TORD.sprite:getWidth()/2, TORD.sprite:getHeight()/2)
        love.graphics.draw(TORD1.sprite, TORD1.x, TORD1.y, 0, TORD1.width, TORD1.height, TORD1.sprite:getWidth()/2, TORD1.sprite:getHeight()/2)
        
        --Montreal Sprites
        love.graphics.draw(MTLC.sprite, MTLC.x, MTLC.y, 0, MTLC.width, MTLC.height, MTLC.sprite:getWidth()/2, MTLC.sprite:getHeight()/2)
        love.graphics.draw(MTLR.sprite, MTLR.x, MTLR.y, 0, MTLR.width, MTLR.height, MTLR.sprite:getWidth()/2, MTLR.sprite:getHeight()/2)
        love.graphics.draw(MTLL.sprite, MTLL.x, MTLL.y, 0, MTLL.width, MTLL.height, MTLL.sprite:getWidth()/2, MTLL.sprite:getHeight()/2)
        love.graphics.draw(MTLD.sprite, MTLD.x, MTLD.y, 0, MTLD.width, MTLD.height, MTLD.sprite:getWidth()/2, MTLD.sprite:getHeight()/2)
        love.graphics.draw(MTLD1.sprite, MTLD1.x, MTLD1.y, 0, MTLD1.width, MTLD1.height, MTLD1.sprite:getWidth()/2, MTLD1.sprite:getHeight()/2)
        
        --Puck Sprite
        love.graphics.draw(puck.sprite, puck.x, puck.y, 0, puck.width, puck.height, puck.sprite:getWidth()/2, puck.sprite:getHeight()/2)
        cam:detach()
end















