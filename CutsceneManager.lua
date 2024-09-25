local CutsceneManager = {}
CutsceneManager.__index = CutsceneManager

function CutsceneManager:new(cutsceneData, callbackOnFinish, volume)
    local instance = {
        cutsceneData = cutsceneData,
        currentStep = 1,
        isPlaying = true,
        callbackOnFinish = callbackOnFinish,
        cutsceneTimer = 0,
        fadeAlpha = 0,                -- Alpha for fading text and images
        isFadingIn = true,            -- Start with fading in
        fadeDuration = 1.5,           -- Duration for fade in/out
        stepDuration = cutsceneData.steps[1].duration or 5,
        mainMenuMusicFadedOut = false, -- Tracks if the main menu music is fully faded out
        music = cutsceneData.music,   -- Cutscene background music
        imageSound = cutsceneData.imageSound, -- Sound effect for image
        font = cutsceneData.font or love.graphics.newFont(12), -- Use AKIKA or default font
        imageDisplayed = false,       -- Track whether the image is displayed
        menuVolume = volume or 1,     -- Use the passed menu volume (default is 1)
        showImageOnly = true,         -- Track whether to show the image only (no text)
        backgroundMusicPlayed = false, -- Track whether background music has started
        isImageFadedOut = false,      -- Track when the image has faded out
        skipCutscene = false          -- Flag for skipping the cutscene
    }
    setmetatable(instance, CutsceneManager)
    return instance
end

-- Function to fade out the main menu music
function CutsceneManager:fadeOutMainMenuMusic(dt, currentMusic)
    if currentMusic and not self.mainMenuMusicFadedOut then
        local currentVolume = currentMusic:getVolume()
        local newVolume = math.max(0, currentVolume - (0.5 * dt))  -- Adjust fade out speed
        currentMusic:setVolume(newVolume)
        if newVolume <= 0 then
            currentMusic:stop()
            self.mainMenuMusicFadedOut = true
            -- Play cutscene background music with the adjusted volume
            if self.music and not self.backgroundMusicPlayed then
                self.music:setLooping(true)
                self.music:setVolume(self.menuVolume)  -- Use the menu volume
                self.music:play()
                self.backgroundMusicPlayed = true
            end
        end
    end
end

-- Function to fade out the background music at the end
function CutsceneManager:fadeOutBackgroundMusic(dt)
    if self.music and self.backgroundMusicPlayed then
        local currentVolume = self.music:getVolume()
        local newVolume = math.max(0, currentVolume - (0.5 * dt))  -- Adjust fade out speed
        self.music:setVolume(newVolume)
        if newVolume <= 0 then
            self.music:stop()
        end
    end
end

-- Function to handle skipping the cutscene
function CutsceneManager:skip()
    self:fadeOutBackgroundMusic(1)  -- Immediately fade out the background music
    self.isPlaying = false          -- Stop the cutscene
    if self.callbackOnFinish then
        self.callbackOnFinish()     -- Call the callback to switch the game state
    end
end

-- Update the cutscene
function CutsceneManager:update(dt, currentMusic)
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
        if currentMusic and not self.mainMenuMusicFadedOut then
            self:fadeOutMainMenuMusic(dt, currentMusic)
        end

        -- Play image and sound effect at the start of the cutscene
        if self.currentStep == 1 and not self.imageDisplayed then
            if self.imageSound then
                self.imageSound:setVolume(self.menuVolume)  -- Apply menu volume to image sound
                self.imageSound:play()
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
            if self.cutsceneTimer >= (self.stepDuration - 1) then
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
        end

        -- If all steps are finished, end the cutscene
        if self.currentStep > #self.cutsceneData.steps then
            self:fadeOutBackgroundMusic(dt) -- Fade out background music at the end
            self.isPlaying = false
            if self.callbackOnFinish then
                self.callbackOnFinish()
            end
        else
            -- Update the duration of the next step
            self.stepDuration = self.cutsceneData.steps[self.currentStep].duration or 5
        end
    end
end

-- Draw the current step with fading in/out
function CutsceneManager:draw()
    if self.isPlaying then
        local step = self.cutsceneData.steps[self.currentStep]
        love.graphics.clear(0, 0, 0, 1)  -- Clear screen with black

        -- Set the font to AKIKA
        love.graphics.setFont(self.font)

        -- Set fade alpha transparency
        love.graphics.setColor(1, 1, 1, self.fadeAlpha)

        -- Display the image for the first step
        if self.currentStep == 1 and self.cutsceneData.image and self.imageDisplayed and self.showImageOnly then
            love.graphics.draw(self.cutsceneData.image, (love.graphics.getWidth() - self.cutsceneData.image:getWidth()) / 2, 100)
        else
            -- Draw the text for each step after the image has been shown
            if step.text then
                love.graphics.printf(step.text, 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
            end
        end

        -- Reset color after drawing
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return CutsceneManager
