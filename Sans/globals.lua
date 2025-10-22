-- TODO : set things in the right location;
-- name, level and hp display;
-- tackle menu navigation;
-- make items usable

-- Globals
SANS = SANS or {}
SANS.sans = {state = false}

local CHANNEL = love.thread.getChannel("sound_request")

TL = TL or {}

-- Combat zone specs
TL.zone = { left = 100, top = 100, right = 540, bottom = 380 } -- current
TL.old_zone = { left = 100, top = 100, right = 540, bottom = 380 } -- previous (if needed)
TL.target_zone = { left = 100, top = 100, right = 540, bottom = 380 } -- destination
TL.anim_time = 0
TL.anim_duration = 0.5 -- secs
TL.player = {max_hp = 92, max_kr = 40, hp = 92, kr = 0}

-- Images n animations table : useful for hiding
TL.images = TL.images or {}
TL.attacksCount = TL.attacksCount or {}

-- Menu Globals
TL.MENU = TL.MENU or {state = false}
TL.MENU.icons = TL.MENU.icons or { UIFight = false, UIAct = false, UIItem = false, UIMercy = false, previous_highlight = "UIFight"}

-- Function to load an image to the framebuffer
function TL.LoadImage(name, x, y, rotation, xScale, yScale, isAttack, color)
    rotation = rotation or 0
    xScale = xScale or 1
    yScale = yScale or 1

    local filename = name .. ".png"

    local base = SANS.path or ""
    local last = base:sub(-1)
    if last ~= "/" and last ~= "\\" then
        base = base .. "/"
    end

    local full_path = base .. "textures/" .. filename

    local file_data = NFS.newFileData(full_path)
    local image_data = love.image.newImageData(file_data)

    -- recolor table (for bones and heart)
    if color then
        image_data:mapPixel(function(xp, yp, r, g, b, a)
            if a > 0 then
                return color.r or 1, color.g or 1, color.b or 1, a
            else
                return r, g, b, a
            end
        end)
    end

    local imgObj = love.graphics.newImage(image_data)
    local key = name
    if isAttack then
        TL.attacksCount[name] = (TL.attacksCount[name] or 0) + 1
        if TL.attacksCount[name] > 1 then
            key = name .. TL.attacksCount[name]
        end
    end

    TL.images[key] = {
        img = imgObj,
        x = x,
        y = y,
        rotation = rotation,
        xScale = xScale,
        yScale = yScale,
        visible = true,
        isAttack = isAttack,
    }

    return key
end

-- hide all the images on screen except for the ones in the blacklist (must be loaded beforehand)
function TL.HideAllImages(blacklist)
    for key, img in pairs(TL.images) do
        if not blacklist[key] then
            TL.images[key].visible = false
        end
    end
end

-- function made at the end of the attacks : remove all the images that are for attacks in TL.images
function TL.DestroyAllAttacks()
    for key, img in pairs(TL.images) do
        if not TL.images[key].isAttack then
            table.remove(TL.images, key)
        end
    end
    TL.attacksCount = {}
end

function TL.CombatZoneResize(LeftPosition, TopPosition, RightPosition, BottomPosition)
    -- Store old zone
    TL.old_zone.left = TL.zone.left
    TL.old_zone.top = TL.zone.top
    TL.old_zone.right = TL.zone.right
    TL.old_zone.bottom = TL.zone.bottom

    -- Set new target zone
    TL.target_zone.left = LeftPosition
    TL.target_zone.top = TopPosition
    TL.target_zone.right = RightPosition
    TL.target_zone.bottom = BottomPosition

    -- Reset anim timer
    TL.anim_time = 0
end

-- linear interpolation
local function lerp(a, b, t)
    return a + (b - a) * t
end

function TL.ShowHealth()
    -- bool check so it only does all the math once
    if not TL.healthbar then
        local screenW, screenH = 640, 480  -- framebuffer size

        -- Scaled dimensions (*0.44 factor)
        local containerW, containerH = 176, 22
        local imgW, imgH = 23, 10
        local healthW, healthH = 100, 22

        -- Centered vertically
        local containerX = (screenW - containerW) / 2
        local containerY = (screenH - containerH) / 2

        -- Spacing
        local spacing = (containerW - (2 * imgW + healthW)) / 2

        -- Positions
        local hpX = containerX
        local healthX = hpX + imgW + spacing
        local krX = containerX + containerW - imgW
        local imgY = containerY + (containerH - imgH) / 2
        local healthY = containerY


        -- Load once
        TL.LoadImage("HP", hpX, imgY, 0, 1, 1, true)
        TL.LoadImage("KR", krX, imgY, 0, 1, 1, true)
        TL.healthbar = {
            rectX = healthX,
            rectY = healthY,
            rectW = healthW,
            rectH = healthH
        }
    end

    local hb = TL.healthbar
    local maxhpW = hb.rectW
    local currenthpW = maxhpW * TL.player.hp / TL.player.max_hp
    local currentkrW = maxhpW * TL.player.kr / TL.player.max_kr

    -- Lost hp
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("fill", hb.rectX, hb.rectY, hb.rectW, hb.rectH) -- never changes

    -- hp
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.rectangle("fill", hb.rectX, hb.rectY, currenthpW, hb.rectH) -- diminushes

    -- karma
    love.graphics.setColor(1, 0, 1, 1)
    love.graphics.rectangle("fill", hb.rectX + currenthpW - (TL.player.kr == 0 and 1 or currentkrW) , hb.rectY, 1, hb.rectH)
    -- god im so good at programming for finding the (TL.player.kr == 0 and 1 or currentkrW) expression :pray_emoji:

    -- reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function TL.LoadUI()
    -- Get last highlighted icon
    local last = TL.MENU.icons.previous_highlight or "UIFight"

    -- Layout settings
    local iconW, iconH = 110, 42
    local paddingSides, paddingBot = 40, 40
    local containerW = 640 - 2 * paddingSides
    local containerH = iconH
    local containerX = paddingSides
    local containerY = 480 - paddingBot - containerH

    local totalIconWidth = 4 * iconW
    local spaceBetween = (containerW - totalIconWidth) / 3

    -- Load all normal + highlighted versions
    for i, name in ipairs({ "UIFight", "UIAct", "UIItem", "UIMercy" }) do
        local x = containerX + (i - 1) * (iconW + spaceBetween)
        local y = containerY

        -- Normal version
        local normalKey = name
        TL.LoadImage(normalKey, x, y, 0, 1, 1, false)

        -- Highlighted version
        local highlightedKey = name .. "_Highlight"
        TL.LoadImage(highlightedKey, x, y, 0, 1, 1, false)

        -- Set visibility right
        if TL.images[normalKey] then
            TL.images[normalKey].visible = (name ~= last)
        end
        if TL.images[highlightedKey] then
            TL.images[highlightedKey].visible = (name == last)
        end
    end
end

function TL.EndAttack()
    TL.MENU.state = true
    TL.CombatZoneResize(33, 251, 608, 391)

    -- Hide everything except not all of them lol
    TL.HideAllImages({ HP = true, KR = true, PlayerHeart = true })

    -- Destroy all attacks
    TL.DestroyAllAttacks()

    -- Reset all icon states (will prolly change when i get to the attack loader)
    for name, _ in pairs(TL.MENU.icons) do
        if name ~= "previous_highlight" then
            TL.MENU.icons[name] = false
        end
    end

    -- Get last highlighted
    local last = TL.MENU.icons.previous_highlight or "UIFight"

    -- Set the right one in highlight mode, the others no
    for _, name in ipairs({ "UIFight", "UIAct", "UIItem", "UIMercy" }) do
        local normal = TL.images[name]
        local highlighted = TL.images[name .. "_Highlight"]

        if normal then
            normal.visible = (name ~= last)
        end
        if highlighted then
            highlighted.visible = (name == last)
        end
    end
end



-- Update hook
local update_hook = Game.update
function Game:update(dt)
    if not SANS.state then
        update_hook(self, dt)
    else
        -- Update combat zone transition
        if TL.anim_time < TL.anim_duration then
            TL.anim_time = math.min(TL.anim_time + dt, TL.anim_duration)
            local t = TL.anim_time / TL.anim_duration

            TL.zone.left = lerp(TL.old_zone.left, TL.target_zone.left, t)
            TL.zone.top = lerp(TL.old_zone.top, TL.target_zone.top, t)
            TL.zone.right = lerp(TL.old_zone.right, TL.target_zone.right, t)
            TL.zone.bottom = lerp(TL.old_zone.bottom, TL.target_zone.bottom, t)
        end

        -- heart movement + clamping for every rotation
        if TL.heartKey and TL.images[TL.heartKey] and not TL.MENU.state then
            local heart = TL.images[TL.heartKey]
            local spd = TL.heartSpeed or 200

            -- movement input
            if love.keyboard.isDown("left") then heart.x = heart.x - spd * dt end
            if love.keyboard.isDown("right") then heart.x = heart.x + spd * dt end
            if love.keyboard.isDown("up") then heart.y = heart.y - spd * dt end
            if love.keyboard.isDown("down") then heart.y = heart.y + spd * dt end

            -- clamp area (clampin' my shi')(tbh i don't understand fully the code bellow but it works)
            local zone = TL.zone
            local imgw, imgh = heart.img:getWidth(), heart.img:getHeight()
            local sx, sy = heart.xScale or 1, heart.yScale or 1
            local rot = heart.rotation or 0

            -- origin coords
            local ox, oy = 0, 0

            -- corners coords (before rotation)
            local localCorners = {
                {(0 - ox) * sx, (0 - oy) * sy}, -- top left
                {(imgw - ox) * sx, (0 - oy) * sy}, -- top right
                {(imgw - ox) * sx, (imgh - oy) * sy}, -- bottom right
                {(0 - ox) * sx, (imgh - oy) * sy},   -- bottom left
            }

            local cosr, sinr = math.cos(rot), math.sin(rot)
            local min_x, max_x = math.huge, -math.huge
            local min_y, max_y = math.huge, -math.huge

            -- Transform local corners by rotation around the draw point (heart.x, heart.y)
            for i = 1,4 do
                local currx = localCorners[i][1]
                local curry = localCorners[i][2]
                local rotx = heart.x + currx * cosr - curry * sinr
                local roty = heart.y + currx * sinr + curry * cosr
                if rotx < min_x then min_x = rotx end
                if rotx > max_x then max_x = rotx end
                if roty < min_y then min_y = roty end
                if roty > max_y then max_y = roty end
            end

            -- actually modifies everything
            local eps,dx,dy = 3,0,0 --eps is magic number that makes everything works somehow

            if min_x < zone.left then
                dx = zone.left - min_x
            elseif max_x > zone.right - eps then
                dx = zone.right - eps - max_x
            end

            if min_y < zone.top then
                dy = zone.top - min_y
            elseif max_y > zone.bottom - eps then
                dy = zone.bottom - eps - max_y
            end


            -- apply translation to the heart draw position
            heart.x = heart.x + dx
            heart.y = heart.y + dy

        end


    end
end

-- Keypressed hook
local keypressed_hook = love.keypressed
function love.keypressed(key, scancode, isrepeat)
    if not SANS.state then
        keypressed_hook(key, scancode, isrepeat)
    end

    if scancode == "u" and not isrepeat then
        SANS.state = not SANS.state

        if SANS.state then
            print("Sans on")
            CHANNEL:push({ type = "stop" })  -- Stops all audio
            TL.LoadUI()
        else
            print("Sans off")
            CHANNEL:push({
                type = "restart_music",
                dt = 0,
                sound_settings = {
                    volume = 100,
                    music_volume = 100,
                    game_sounds_volume = 100
                },
                desired_track = "",
                pitch_mod = 1,
                per = 1,
                vol = 1
            })
        end
    end
    if scancode == "t" and not isrepeat then
        local minWidth, minHeight = 80, 60
        local maxWidth, maxHeight = 640, 480

        -- Random width/height within limits
        local width = love.math.random(minWidth, maxWidth)
        local height = love.math.random(minHeight, maxHeight)

        -- Random top left corner
        local left = love.math.random(0, 640 - width)
        local top = love.math.random(0, 480 - height)

        local right = left + width
        local bottom = top + height

        TL.CombatZoneResize(left, top, right, bottom)
    end

    if scancode == "h" and not isrepeat and not TL.heartKey then
        TL.heartKey = TL.LoadImage("PlayerHeart", 300, 200, math.pi / 2, 1, 1, true, { r = 1, g = 0, b = 0 })
        TL.heartSpeed = 200
    end
    if scancode == "o" and not isrepeat then
        TL.EndAttack()
    end
end

-- Create framebuffer/canvas
local framebuffer

-- Load hook
local load_hook = love.load or function() end
function love.load()
    load_hook()
    framebuffer = love.graphics.newCanvas(640, 480)
end

-- Draw hook
local draw_hook = love.draw or function() end
function love.draw()
    if not SANS.state then
        draw_hook()
    else
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()

        if framebuffer == nil then
            framebuffer = love.graphics.newCanvas(640, 480)
        end

        local scale = math.min(w / 640, h / 480)
        local scaled_w, scaled_h = 640 * scale, 480 * scale
        local offset_x = (w - scaled_w) / 2
        local offset_y = (h - scaled_h) / 2

        -- combat zone into framebuffer
        love.graphics.setCanvas(framebuffer)

        love.graphics.clear(0, 1, 0.5, 1) -- green bg (test only)
        love.graphics.setColor(1, 1, 1, 1)

        TL.ShowHealth() -- important

        -- load all visible images
        for _, img in pairs(TL.images) do
            if img.visible then
                love.graphics.draw(img.img, img.x, img.y, img.rotation, img.xScale, img.yScale)
            end
        end

        local border = 5
        love.graphics.setLineWidth(border)

        local halfborder = border/2
        local zone = TL.zone
        local width = zone.right - zone.left
        local height = zone.bottom - zone.top

        -- combat zone rectangle (outside stroke)
        love.graphics.rectangle("line", zone.left-halfborder, zone.top-halfborder, width+halfborder, height+halfborder)
        

        love.graphics.setCanvas()

        -- black bg + framebuffer
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(framebuffer, offset_x, offset_y, 0, scale, scale)
    end
end