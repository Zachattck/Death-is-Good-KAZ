local CutsceneManager = {}
CutsceneManager.__index = CutsceneManager


function CutsceneManager:new(cutsceneData, callbackOnFinish)
    local instance = {
        cutsceneData = cutsceneData,
        currentStep = 1,
        isPlaying = true,
        callbackOnFinish = callbackOnFinish,  -- Callback after the cutscene finishes
        cutsceneTimer = 0,
        stepDuration = cutsceneData.steps[1].duration or 5  -- Default to 5 seconds if no duration specified
    }
    setmetatable(instance, CutsceneManager)
    return instance
end

function CutsceneManager:update(dt)
    if self.isPlaying then
        self.cutsceneTimer = self.cutsceneTimer + dt

        -- Check if the current step's duration is reached
        if self.cutsceneTimer >= self.stepDuration then
            self.currentStep = self.currentStep + 1
            self.cutsceneTimer = 0

            -- Check if the cutscene is over
            if self.currentStep > #self.cutsceneData.steps then
                self.isPlaying = false
                if self.callbackOnFinish then
                    self.callbackOnFinish()  -- Trigger the callback
                end
            else
                -- Set the duration for the next step (use default if not provided)
                self.stepDuration = self.cutsceneData.steps[self.currentStep].duration or 5
            end
        end
    end
end


function CutsceneManager:draw()
    if self.isPlaying then
        local step = self.cutsceneData.steps[self.currentStep]
        love.graphics.clear(0, 0, 0, 1)  -- Clear screen with black

        if step.text then
            love.graphics.printf(step.text, 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
        end

        if step.image then
            local image = love.graphics.newImage(step.image)
            love.graphics.draw(image, (love.graphics.getWidth() - image:getWidth()) / 2, 100)
        end
    end
end

return CutsceneManager
