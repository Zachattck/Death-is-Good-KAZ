-- CutsceneManager.lua

local CutsceneManager = {}
CutsceneManager.__index = CutsceneManager

-- Initialize CutsceneManager state
function CutsceneManager:new()
    local self = setmetatable({}, CutsceneManager)
    self.isPlaying = false
    self.skipCutscene = false
    self.fadeAlpha = 0
    self.isFadingIn = true
    self.fadeDuration = 1  -- Duration for fade transitions
    self.currentStep = 1
    self.cutsceneTimer = 0
    self.backgroundMusicFadedOut = false 
    self.mainMenuMusicFadedOut = false
    self.isImageFadedOut = false
    self.showImageOnly = true
    self.cutsceneData = {}  -- To be filled when a cutscene starts
    self.callbackOnFinish = nil
    return self
end

-- Load function (if needed)
function CutsceneManager:load()
    -- Initialize any necessary resources here
end

-- Start a new cutscene
function CutsceneManager:start(cutsceneData, callback, volume)
    self.isPlaying = true
    self.cutsceneData = cutsceneData
    self.callbackOnFinish = callback
    self.fadeAlpha = 0
    self.isFadingIn = true
    self.currentStep = 1
    self.cutsceneTimer = 0
    self.skipCutscene = false
    self.mainMenuMusicFadedOut = false
    self.isImageFadedOut = false
    self.showImageOnly = true

    -- Handle music fade-out if main menu music exists
    if cutsceneData.music and volume then
        cutsceneData.music:setVolume(volume)
        cutsceneData.music:play()
    end
end

-- Check if a cutscene is active
function CutsceneManager:isActive()
    return self.isPlaying
end

-- Update function
-- Update function
function CutsceneManager:update(dt)
    if self.isPlaying then
        -- Check if the spacebar is pressed to skip the cutscene
        if love.keyboard.isDown("space") then
            self.skipCutscene = true
        end

        -- Skip the cutscene if the flag is set
        if self.skipCutscene then
            self:skip()
            return
        end

        -- Fade out the main menu music before starting the cutscene
        if self.cutsceneData.music and not self.mainMenuMusicFadedOut then
            self:fadeOutMainMenuMusic(dt, self.cutsceneData.music)
        end

        -- Play image and sound effect at the start of the cutscene
        if self.currentStep == 1 and not self.imageDisplayed then
            if self.cutsceneData.imageSound then
                self.cutsceneData.imageSound:setVolume(self.cutsceneData.volume or 1)  -- Apply volume
                self.cutsceneData.imageSound:play()
            end
            self.imageDisplayed = true  -- Ensure it only plays once
        end

        -- Handle fade in/out transitions for each step
        if self.isFadingIn then
            self.fadeAlpha = self.fadeAlpha + (dt / self.fadeDuration)
            if self.fadeAlpha >= 1 then
                self.fadeAlpha = 1
                self.isFadingIn = false
            end
        else
            self.cutsceneTimer = self.cutsceneTimer + dt

            -- Check if the current step exists before accessing its properties
            if self.cutsceneData.steps and self.cutsceneData.steps[self.currentStep] then
                local stepDuration = self.cutsceneData.steps[self.currentStep].duration or 5  -- Use default if missing

                if self.cutsceneTimer >= (stepDuration - 1) then
                    self.fadeAlpha = self.fadeAlpha - (dt / self.fadeDuration)
                    if self.fadeAlpha <= 0 then
                        self.fadeAlpha = 0
                        self.isFadingIn = true
                        self.cutsceneTimer = 0

                        -- If we are at the first step and we just finished displaying the image, move to text
                        if self.currentStep == 1 and not self.isImageFadedOut then
                            self.showImageOnly = false  -- Stop showing the image, proceed to the text
                            self.isImageFadedOut = true
                        else
                            -- For other steps, proceed to the next step
                            self.currentStep = self.currentStep + 1
                            self.imageDisplayed = false  -- Reset for the next step if needed
                        end
                    end
                end
            else
                -- If the step does not exist, consider it the end of the cutscene
                self.isPlaying = false
                if self.callbackOnFinish then
                    self.callbackOnFinish()
                end
            end
        end

        -- If all steps are finished, end the cutscene
        if self.currentStep > #self.cutsceneData.steps then
            self:fadeOutBackgroundMusic(dt)  -- Fade out background music
            if self.backgroundMusicFadedOut then
                self.isPlaying = false
                if self.callbackOnFinish then
                    self.callbackOnFinish()
                end
            end
        end
    end
end


-- Function to fade out main menu music
function CutsceneManager:fadeOutMainMenuMusic(dt, music)
    local fadeSpeed = 1  -- Volume units per second
    local currentVolume = music:getVolume()
    if currentVolume > 0 then
        local newVolume = math.max(currentVolume - fadeSpeed * dt, 0)
        music:setVolume(newVolume)
    else
        self.mainMenuMusicFadedOut = true
    end
end

-- Function to fade out background music at the end of cutscene
function CutsceneManager:fadeOutBackgroundMusic(dt)
    if self.cutsceneData.music then
        local fadeSpeed = 1  -- Volume units per second
        local currentVolume = self.cutsceneData.music:getVolume()
        if currentVolume > 0 then
            local newVolume = math.max(currentVolume - fadeSpeed * dt, 0)
            self.cutsceneData.music:setVolume(newVolume)
            print("Fading out background music: Volume =", newVolume)
        else
            self.backgroundMusicFadedOut = true
            print("Background music fully faded out.")
        end
    else
        self.backgroundMusicFadedOut = true
        print("No background music to fade out.")
    end
end


-- Draw function
function CutsceneManager:draw()
    if self.isPlaying then
        -- Handle drawing the current step
        if self.showImageOnly and self.cutsceneData.image then
            love.graphics.draw(self.cutsceneData.image, 700, 200)
        else
            -- Draw text or other elements for the current step
            love.graphics.setFont(self.cutsceneData.font)
            love.graphics.setColor(1, 1, 1, self.fadeAlpha)
            love.graphics.printf(
                self.cutsceneData.steps[self.currentStep].text,
                0,
                love.graphics.getHeight() / 2,
                love.graphics.getWidth(),
                "center"
            )
        end

        -- Draw fade overlay
        love.graphics.setColor(0, 0, 0, 1 - self.fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    end
end

-- Handle key presses during cutscene
function CutsceneManager:keypressed(key)
    if key == "space" then
        self.skipCutscene = true
    end
end

-- Function to skip the cutscene
function CutsceneManager:skip()
    self.isPlaying = false
    if self.callbackOnFinish then
        self.callbackOnFinish()
    end
end

-- Function to fade out main menu music
function CutsceneManager:fadeOutMainMenuMusic(dt, music)
    local fadeSpeed = 1  -- Adjust as needed
    local currentVolume = music:getVolume()
    if currentVolume > 0 then
        local newVolume = math.max(currentVolume - fadeSpeed * dt, 0)
        music:setVolume(newVolume)
    else
        self.mainMenuMusicFadedOut = true
    end
end


return CutsceneManager