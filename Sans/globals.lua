-- Global toggle variable
G = G or {}
G.sans = {state = false}
local CHANNEL = love.thread.getChannel("sound_request")

-- Update hook
local update_hook = Game.update
function Game:update(dt)
    if not G.sans.state then
        update_hook(self, dt)
    else
        print("sans") -- custom pause behavior
    end
end

-- Keypressed hook
local keypressed_hook = love.keypressed
function love.keypressed(key, scancode, isrepeat)
    if not G.sans.state then
        keypressed_hook(key, scancode, isrepeat)
    end

    if scancode == "u" and not isrepeat then
        G.sans.state = not G.sans.state

        if G.sans.state then
            print("Sans mode activated — Game paused.")
            CHANNEL:push({ type = "stop" })  -- Stop all audio
        else
            print("Sans mode deactivated — Game resumed.")
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
end

-- Draw hook
local draw_hook = love.draw or function() end
function love.draw()
    draw_hook()

    if G.sans.state then
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        love.graphics.setColor(0, 0, 0, 1) -- solid black
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(1, 1, 1, 1) -- reset color for future draws
    end
end
