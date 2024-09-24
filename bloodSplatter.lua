-- bloodsplatter.lua
local bloodsplatter = {}

function bloodsplatter.load()
    bloodsplatter.active = false
    bloodsplatter.dots = {}  -- To store each blood dot
    bloodsplatter.gravity = 500  -- Gravity effect on the blood dots
    bloodsplatter.numDots = 50  -- Number of blood dots
end

-- Function to trigger blood splatter
function bloodsplatter.trigger(x, y)
    bloodsplatter.active = true
    bloodsplatter.dots = {}  -- Clear previous dots
    
    -- Create blood dots with random velocity
    for i = 1, bloodsplatter.numDots do
        local dot = {}
        dot.x = x
        dot.y = y
        dot.radius = math.random(2, 5)  -- Random size for each dot
        dot.vx = math.random(-300, 300)  -- Random velocity in x direction
        dot.vy = math.random(-300, 0)    -- Random velocity in y direction (upward)
        dot.lifetime = math.random(2, 5)  -- Each dot has a random lifetime
        table.insert(bloodsplatter.dots, dot)
    end
end

-- Update blood dots (apply gravity and movement)
function bloodsplatter.update(dt)
    if bloodsplatter.active then
        for i = #bloodsplatter.dots, 1, -1 do
            local dot = bloodsplatter.dots[i]
            dot.vy = dot.vy + bloodsplatter.gravity * dt  -- Apply gravity
            dot.x = dot.x + dot.vx * dt  -- Update horizontal position
            dot.y = dot.y + dot.vy * dt  -- Update vertical position
            dot.lifetime = dot.lifetime - dt  -- Reduce lifetime

            -- Remove the dot if its lifetime is over
            if dot.lifetime <= 0 then
                table.remove(bloodsplatter.dots, i)
            end
        end

        -- If all dots are gone, deactivate the splatter
        if #bloodsplatter.dots == 0 then
            bloodsplatter.active = false
        end
    end
end

-- Draw the blood dots
function bloodsplatter.draw()
    if bloodsplatter.active then
        for _, dot in ipairs(bloodsplatter.dots) do
            love.graphics.setColor(1, 0, 0)  -- Red color for the blood
            love.graphics.circle("fill", dot.x, dot.y, dot.radius)  -- Draw each blood dot
        end
        love.graphics.setColor(1, 1, 1)  -- Reset color to white
    end
end

return bloodsplatter
