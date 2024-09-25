local Cutscene = {}
Cutscene.__index = Cutscene

function Cutscene:new(texts, imagePath, backgroundMusicPath, imageSoundPath, duration, screenWidth, screenHeight, volume, currentMusic)
    local instance = {
        texts = texts or {""},
        image = imagePath and love.graphics.newImage(imagePath),
        backgroundMusic = backgroundMusicPath and love.audio.newSource(backgroundMusicPath, "static") or nil,
        imageSound = imageSoundPath and love.audio.newSource(imageSoundPath, "static") or nil,
        textAlpha = 0,  -- Start with text fully invisible
        currentTextIndex = 1,
        fadeSpeed = 1.5,  -- Adjust this to make fading faster or slower
        cutsceneTimer = 0,
        maxCutsceneTime = duration,  -- Duration of cutscene
        isActive = true,
        imageDisplayed = false,
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        volume = volume or 1,
        currentMusic = currentMusic,
        fadeOutSpeed = 0.1,
        isMusicFaded = false,
        font = love.graphics.newFont("assets/AKIKA.ttf", 36),
        musicFadeTimer = 2,  -- Time to fade out music
        textOffsetX = 600,  -- Manual text offset on X
        textOffsetY = 200,  -- Manual text offset on Y
        imageOffsetX = 0,  -- Manual image offset on X
        imageOffsetY = 0,  -- Manual image offset on Y
    }
    setmetatable(instance, Cutscene)
    return instance
end

function Cutscene:fadeOutOtherMusic(dt)
    if self.currentMusic and not self.isMusicFaded then
        -- Fade out the current music
        self.musicFadeTimer = self.musicFadeTimer - dt
        local currentVolume = self.currentMusic:getVolume()
        local newVolume = math.max(0, currentVolume - (self.fadeOutSpeed * dt * 10))
        self.currentMusic:setVolume(newVolume)


        if newVolume <= 0 or self.musicFadeTimer <= 0 then
            self.currentMusic:stop()
            self.isMusicFaded = true

        end
    end
end

function Cutscene:load()
    -- Play background music if available
    if self.backgroundMusic then
        self.backgroundMusic:setLooping(true)
        self.backgroundMusic:setVolume(self.volume)
        self.backgroundMusic:play()
    end
end

function Cutscene:update(dt)
    if self.isActive then
        -- Increment the cutscene timer
        self.cutsceneTimer = self.cutsceneTimer + dt


        -- Fade out any other playing music
        self:fadeOutOtherMusic(dt)

        -- Timeline logic for text and image display
        if self.cutsceneTimer <= 4 then
            -- Fade in the first text
            self.textAlpha = math.min(self.textAlpha + self.fadeSpeed * dt, 1)

        elseif self.cutsceneTimer > 4 and self.cutsceneTimer <= 6 then
            -- Fade out the first text
            self.textAlpha = math.max(self.textAlpha - self.fadeSpeed * dt, 0)
            print("[DEBUG] Fading out first text. Alpha:", self.textAlpha)
            if self.textAlpha == 0 and self.currentTextIndex == 1 then
                self.currentTextIndex = 2
                self.textAlpha = 0  -- Reset alpha for new text

            end
        elseif self.cutsceneTimer > 6 and self.cutsceneTimer <= 10 then
            -- Fade in the second text
            self.textAlpha = math.min(self.textAlpha + self.fadeSpeed * dt, 1)

        elseif self.cutsceneTimer > 10 and self.cutsceneTimer <= 12 then
            -- Fade out the second text and prepare for the image
            self.textAlpha = math.max(self.textAlpha - self.fadeSpeed * dt, 0)

            if self.textAlpha == 0 and self.currentTextIndex == 2 then
                self.imageDisplayed = true  -- Display the image now
                self.imageAlpha = 0 -- Start image fully invisible
                if self.imageSound then
                    self.imageSound:setVolume(self.volume)
                    self.imageSound:play()
                end
                self.currentTextIndex = 3  -- Move to the next (final) text after the image
 
            end
        elseif self.cutsceneTimer > 12 and self.cutsceneTimer <= 14 then
            -- Fade in the image during this time
            self.imageAlpha = math.min(self.imageAlpha + self.fadeSpeed * dt, 1)

        elseif self.cutsceneTimer > 14 and self.cutsceneTimer <= 16 then
            -- Hold the image at full opacity
            self.imageAlpha = 1

        elseif self.cutsceneTimer > 16 and self.cutsceneTimer <= 18 then
            -- Fade out the image
            self.imageAlpha = math.max(self.imageAlpha - self.fadeSpeed * dt, 0)

            if self.imageAlpha == 0 then
                self.imageDisplayed = false
             
            end
        elseif self.cutsceneTimer > 18 and self.cutsceneTimer <= 22 then
            -- Fade in the final text after the image disappears
            self.textAlpha = math.min(self.textAlpha + self.fadeSpeed * dt, 1)
           
        elseif self.cutsceneTimer > 22 and self.cutsceneTimer <= 24 then
            -- Fade out the final text
            self.textAlpha = math.max(self.textAlpha - self.fadeSpeed * dt, 0)
            
        end

        -- Fade out cutscene background music at the end
        if self.cutsceneTimer >= (self.maxCutsceneTime - 2) and self.backgroundMusic and not self.isMusicFaded then
            local currentVolume = self.backgroundMusic:getVolume()
            self.backgroundMusic:setVolume(math.max(0, currentVolume - self.fadeOutSpeed * dt))
            if self.backgroundMusic:getVolume() == 0 then
                self.backgroundMusic:stop()
                self.isMusicFaded = true
              
            end
        end
        
        

        -- End the cutscene after the max time
        if self.cutsceneTimer >= self.maxCutsceneTime then
            fadeOutMusic(self.backgroundMusic, self.fadeOutSpeed, dt)
            self.isActive = false

        end
    end
end

function fadeOutMusic(currentMusic, fadeOutSpeed, dt)
    if currentMusic and currentMusic:isPlaying() then
        local currentVolume = currentMusic:getVolume()
        local newVolume = math.max(0, currentVolume - fadeOutSpeed * dt)  -- Decrease volume gradually
        currentMusic:setVolume(newVolume)

        -- If volume has reached zero, stop the music
        if newVolume <= 0 then
            currentMusic:stop()
        end
    end
end


function Cutscene:draw()
    if self.isActive then
        -- Clear screen
        love.graphics.clear(0, 0, 0, 1)
        
        -- Set font and color for the text
        love.graphics.setFont(self.font)
        love.graphics.setColor(1, 1, 1, self.textAlpha)

        -- Draw the current text, with manual offset applied
        local textY = (self.screenHeight / 2) - 100 + self.textOffsetY
        love.graphics.printf(
            self.texts[self.currentTextIndex], 
            self.textOffsetX, 
            textY, 
            self.screenWidth, 
            "center"
        )

        -- Debug if image is displayed
        if self.imageDisplayed and self.image then
            -- Display the image centered with the text
            local imageCenterX = (self.screenWidth / 2) + self.textOffsetX  -- Center X of the image
            local imageCenterY = (self.screenHeight / 2) + 100 + self.textOffsetY  -- Center Y of the image
            local imageX = imageCenterX - (self.image:getWidth() / 2)  -- Adjust X to center the image
            local imageY = imageCenterY - (self.image:getHeight() / 2)  -- Adjust Y to center the image

            love.graphics.setColor(1, 1, 1, self.imageAlpha)  -- Use imageAlpha for fade
            love.graphics.draw(self.image, imageX, imageY)
        end

        -- Reset color after drawing
        love.graphics.setColor(1, 1, 1, 1)
    end
end



return Cutscene
