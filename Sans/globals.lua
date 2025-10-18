-- Globals
SANS = SANS or {}
SANS.sans = {state = false}

TL = TL or {}
TL.icons = TL.icons or { state = false, isFightSelected = false, isActSelected = false, isItemSelected = true, isMercySelected = false }

-- Combat zone specs
TL.zone = { left = 100, top = 100, right = 540, bottom = 380 } -- current
TL.old_zone = { left = 100, top = 100, right = 540, bottom = 380 } -- previous (if needed)
TL.target_zone = { left = 100, top = 100, right = 540, bottom = 380 } -- destination
TL.anim_time = 0
TL.anim_duration = 0.5 -- secs


local CHANNEL = love.thread.getChannel("sound_request")

function TL.CombatZoneResize(LeftPosition, TopPosition, RightPosition, BottomPosition)
    -- Store old zone
    TL.old_zone.left = TL.zone.left
    TL.old_zone.top = TL.zone.top
    TL.old_zone.right = TL.zone.right
    TL.old_zone.bottom = TL.zone.bottom

    -- Set new target
    TL.target_zone.left = LeftPosition
    TL.target_zone.top = TopPosition
    TL.target_zone.right = RightPosition
    TL.target_zone.bottom = BottomPosition

    -- Reset anim timer
    TL.anim_time = 0
end

local function lerp(a, b, t)
    return a + (b - a) * t
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

            TL.zone.left = lerp(TL.old_zone.left,   TL.target_zone.left,   t)
            TL.zone.top = lerp(TL.old_zone.top,    TL.target_zone.top,    t)
            TL.zone.right = lerp(TL.old_zone.right,  TL.target_zone.right,  t)
            TL.zone.bottom = lerp(TL.old_zone.bottom, TL.target_zone.bottom, t)
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
            print("Sans off")
            CHANNEL:push({ type = "stop" })  -- Stop all audio
        else
            print("Sans on")
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

    if scancode == "t" and not isrepeat and SANS.state then
        local minWidth, minHeight = 80, 60
        local maxWidth, maxHeight = 640, 480

        -- Random width/height within limits
        local width = love.math.random(minWidth, maxWidth)
        local height = love.math.random(minHeight, maxHeight)

        -- Random top-left corner, ensuring it fits inside framebuffer
        local left = love.math.random(0, 640 - width)
        local top = love.math.random(0, 480 - height)

        local right = left + width
        local bottom = top + height

        TL.CombatZoneResize(left, top, right, bottom)
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
        love.graphics.clear(1, 0, 0, 1) -- red bg (test only)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(2)

        local zone = TL.zone
        local width = zone.right - zone.left
        local height = zone.bottom - zone.top

        -- combat zone rectangle
        love.graphics.rectangle("line", zone.left, zone.top, width, height)
        love.graphics.setCanvas()

        -- black bg + framebuffer
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(framebuffer, offset_x, offset_y, 0, scale, scale)
    end
end