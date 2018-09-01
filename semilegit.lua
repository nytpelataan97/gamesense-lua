local interface = {
	get = ui.get,
	set = ui.set,
    ref = ui.reference,
	checkbox = ui.new_checkbox,
	slider = ui.new_slider
}

local cache, cache_aa = nil, nil
local lm = interface.checkbox("MISC", "Settings", "Legit mode")

local rage, rage_hotkey = interface.ref("RAGE", "Aimbot", "Enabled")
local rage_recoil = interface.ref("RAGE", "Other", "Remove Recoil")
local rage_fov = interface.ref("RAGE", "Aimbot", "Maximum FOV")
local aa_yaw = interface.ref("AA", "Anti-aimbot angles", "Yaw")

local legit, legit_hotkey = interface.ref("LEGIT", "Aimbot", "Enabled")

local function on_run_command(e)
    if cache == nil then
        cache = interface.get(rage)
    end
	
	if cache_aa == nil then
        cache_aa = interface.get(aa_yaw)
    end

	if not interface.get(lm) then 
		return
	end
	
	
    if interface.get(legit_hotkey) then
		interface.set(aa_yaw, "Off")
		interface.set(rage, false)
		interface.set(rage_recoil, false)
    else
	    if cache_aa ~= nil then
            interface.set(aa_yaw, cache_aa)
            cache_aa = nil
        end
	
        if cache ~= nil then
            interface.set(rage, cache)
			interface.set(rage_recoil, cache)
            cache = nil
        end
    end
end

client.set_event_callback("run_command", on_run_command)