local CutsceneManager = {}
CutsceneManager.__index = CutsceneManager

function CutsceneManager:new()
    local self = setmetatable({}, CutsceneManager)
    self.isPlaying = false
    self.fadeAlpha = 0
    self.fadeDuration = 1  -- Duration for fade transitions
    self.currentStep = 1
    self.stepTimer = 0  -- Timer for each step
    self.cutsceneData = {}
    self.callbackOnFinish = nil
    return self
end

function CutsceneManager:start(cutsceneData, callback)
    self.isPlaying = true
    self.cutsceneData = cutsceneData
    self.callbackOnFinish = callback
    self.fadeAlpha = 0
    self.currentStep = 1
    self.stepTimer = 0  -- Reset the timer for steps

    -- Stop any currently playing audio
    love.audio.stop()

    -- Start cutscene music if available
    if cutsceneData.music then
        cutsceneData.music:setVolume(cutsceneData.volume or 1)
        cutsceneData.music:play()
    end
end

function CutsceneManager:update(dt)
    if self.isPlaying then
        local currentStepData = self.cutsceneData.steps[self.currentStep]

        if currentStepData then
            -- Handle fade-in
            if self.fadeAlpha < 1 then
                self.fadeAlpha = math.min(self.fadeAlpha + (dt / self.fadeDuration), 1)
            end

            -- Update the step timer for the current step
            self.stepTimer = self.stepTimer + dt

            -- Debugging: Print current step and timer info
            print("Current step:", self.currentStep, currentStepData.text, "Timer:", self.stepTimer, "/", currentStepData.duration)

            -- If the time spent on the current step has exceeded the step's duration
            if self.stepTimer >= currentStepData.duration then
                -- Reset the timer for the next step
                self.stepTimer = 0

                -- Reset fadeAlpha for the next step
                self.fadeAlpha = 0

                -- Move to the next step
                self.currentStep = self.currentStep + 1

                -- End the cutscene if no more steps
                if self.currentStep > #self.cutsceneData.steps then
                    print("Cutscene complete, triggering callback.")
                    self.isPlaying = false
                    if self.callbackOnFinish then
                        self.callbackOnFinish()  -- Only call the callback once all steps are done
                    end
                end
            end
        end
    end
end

function CutsceneManager:draw()
    if not self.isPlaying then return end

    -- Get current step data
    local currentStepData = self.cutsceneData.steps[self.currentStep]

    if currentStepData then
        -- Draw the text for this step
        if currentStepData.text then
            local textX, textY = 0, love.graphics.getHeight() / 2
            local textWidth = love.graphics.getWidth()
            love.graphics.setFont(self.cutsceneData.font)
            love.graphics.setColor(1, 1, 1, self.fadeAlpha)
            love.graphics.printf(currentStepData.text, textX, textY, textWidth, "center")
        end

        -- Draw fade overlay (for transitions)
        love.graphics.setColor(0, 0, 0, 1 - self.fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    end
end

-- Handle skipping the cutscene
function CutsceneManager:keypressed(key)
    if key == "space" then
        self.isPlaying = false
        if self.callbackOnFinish then
            self.callbackOnFinish()
        end
    end
end

function CutsceneManager:isActive()
    return self.isPlaying
end

return CutsceneManager
