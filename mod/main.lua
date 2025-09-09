sans = {
    funcs = {},
}

local mod_path = "" .. SMODS.current_mod.path
sans.path = mod_path
sans_config = SMODS.current_mod.config

SMODS.current_mod.optional_features = {
    retrigger_joker = true,
	post_trigger = true,
}

-- effect manager for particles etc (idk what this does lmao)
G.effectmanager = {}

-- Load global
assert(SMODS.load_file("globals.lua"))()


--Load item files
local files = NFS.getDirectoryItems(mod_path .. "items")
for _, file in ipairs(files) do
	if not file:match("%.lua$") then
		file = file .. ".lua"
	end
	print("[sans] Loading lua file" .. file)
	local f, err = SMODS.load_file("items/" .. file)
	if err then
		error(err) 
	end
	f()
end

-- --Load lib files
-- local files = NFS.getDirectoryItems(mod_path .. "libs/")
-- for _, file in ipairs(files) do
-- 	print("[sans] Loading lib file " .. file)
-- 	local f, err = SMODS.load_file("libs/" .. file)
-- 	if err then
-- 		error(err) 
-- 	end
-- 	f()
-- end