-- Function to check for collision between player and puck
local function checkCollision(TORC, puck)
    -- Check if puck is inside the bounding box of the player
    local TORCLeft = TORC.x
    local TORCRight = TORC.x + TORC.width
    local TORCTop = TORC.y
    local TORCBottom = TORC.y + TORC.height

    local puckLeft = puck.x - puck.radius
    local puckRight = puck.x + puck.radius
    local puckTop = puck.y - puck.radius
    local puckBottom = puck.y + puck.radius

    -- Check for overlap
    if playerRight > puckLeft and playerLeft < puckRight and
       playerBottom > puckTop and playerTop < puckBottom then
        return true
    end
    return false
end

-- Example usage
if checkCollision(TORC, puck) then
    print("Collision detected!")
else
    print("No collision.")
end
