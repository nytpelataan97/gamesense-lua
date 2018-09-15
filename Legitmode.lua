local interface = {
	get = ui.get,
	set = ui.set,
    ref = ui.reference,
    visible = ui.set_visible,
    callback = ui.set_callback,
    multiselect = ui.new_multiselect,
	checkbox = ui.new_checkbox,
	slider = ui.new_slider,
	hotkey = ui.new_hotkey,
	combobox = ui.new_combobox,
	colorpicker = ui.new_color_picker
}

local cl = {
	log = client.log,
	exec = client.exec,
	indicator = client.draw_indicator,
	circle_outline = client.draw_circle_outline,
	circle = client.draw_circle,
	eye_pos = client.eye_position,
	camera_angles = client.camera_angles
}

local ent = {
	get_local = entity.get_local_player,
	get_prop = entity.get_prop,
	get_all = entity.get_all,
	get_players = entity.get_players,
	hitbox_pos = entity.hitbox_position
}

local dynamicfov_new_fov = 0
local cache = { rb_active = nil, aa_real = nil }
local inds = { "Automatic penetration", "Anti-aim resolver", "Fake lag", "FOV Overlay" }
local near = { "Head", "Chest", "Stomach", "Arms", "Legs", "Feet" }

local legitmode = interface.checkbox("MISC", "Settings", "Legit mode")
local restrictions = interface.checkbox("MISC", "Settings", "Restrictions")
local slowmo_correct = interface.checkbox("MISC", "Settings", "Slow motion correction")

local nearesthitbox_hitscan = interface.multiselect("Misc", "Settings", "Nearest Hitboxes", near)

local dynamicfov_mode = interface.combobox("MISC", "Settings", "Dynamic FOV",  "Off", "Static", "Auto")
local dynamicfov_min = interface.slider("MISC", "Settings", "Minimal FOV", 1, 10, 3, true, "°", 1)
local dynamicfov_max = interface.slider("MISC", "Settings", "Maximum FOV", 1, 10, 7, true, "°", 1)
local dynamicfov_auto_factor = interface.slider("MISC", "Settings", "Automatic Factor", 0, 250, 30, true, "x", 0.01)

local autowall_check = interface.checkbox("MISC", "Settings", "Override penetration")
local autowall_hk = interface.hotkey("MISC", "Settings", "Override penetration hotkey")

local resolver_check = interface.checkbox("MISC", "Settings", "Override resolver")
local resolver_hk = interface.hotkey("MISC", "Settings", "Override resolver hotkey")

local indicators = interface.multiselect("Misc", "Settings", "Indicators", inds)
local dynamicfov_color_picker = interface.colorpicker("MISC", "Settings", "Indicating Color", 0, 0, 0, 80)

-- Reffers
local rage, rage_hotkey = interface.ref("RAGE", "Aimbot", "Enabled")
local rage_target = interface.ref("RAGE", "Aimbot", "Target selection")
local rage_selection = interface.ref("RAGE", "Aimbot", "Target hitbox")
local rage_silent = interface.ref("RAGE", "Aimbot", "Silent aim")
local rage_awall = interface.ref("RAGE", "Aimbot", "Automatic penetration")
local rage_resolver = interface.ref("RAGE", "Other", "Anti-aim resolver")
local rage_recoil = interface.ref("RAGE", "Other", "Remove Recoil")
local rage_fov = interface.ref("RAGE", "Aimbot", "Maximum FOV")

local aa_fakelag, aa_fakelag_key = interface.ref("AA", "Fake lag", "Enabled")
local aa_fakelag_limit = interface.ref("AA", "Fake lag", "Limit")
local aa_pitch = interface.ref("AA", "Anti-aimbot angles", "Pitch")
local aa_yaw = interface.ref("AA", "Anti-aimbot angles", "Yaw")
local aa_fake = interface.ref("AA", "Anti-aimbot angles", "Fake yaw")

local slowmo, slowmo_hotkey = interface.ref("AA", "Other", "Slow motion")
local legit, legit_hotkey = interface.ref("LEGIT", "Aimbot", "Enabled")

local Hitscan = {
	head = { 0, 1 },
	chest = { 2, 3, 4 },
	stomach = { 5, 6 },
	arms = { 13, 14, 15, 16, 17, 18 },
	legs = { 7, 8, 9, 10 },
	feet = { 11, 12 }
}

local function inArr(tab, val)
    for index, value in ipairs(tab) do
        if value == val then return true end
    end

    return false
end

local function draw_indicator_circle(c, x, y, r, g, b, a, percentage, outline)
    local outline = outline or true
    local radius, start_degrees = 9, 0

	if outline then 
		cl.circle_outline(c, x, y, 0, 0, 0, 200, radius, start_degrees, 1.0, 5)
	end

    cl.circle_outline(c, x, y, r, g, b, 255, radius-1, start_degrees, percentage, 3) -- Inner Circle
end

local function getNearestEnemy()
	local enemy_players = ent.get_players(true)
	if #enemy_players ~= 0 then
		local own_x, own_y, own_z = cl.eye_pos()
		local own_pitch, own_yaw = cl.camera_angles()
		local closest_enemy = nil
		local closest_distance = 999999999
		        
		for i = 1, #enemy_players do
			local enemy = enemy_players[i]
			local enemy_x, enemy_y, enemy_z = ent.hitbox_pos(enemy, 0)
		            
			local x = enemy_x - own_x
			local y = enemy_y - own_y
			local z = enemy_z - own_z 

			local yaw = ((math.atan2(y, x) * 180 / math.pi))
			local pitch = -(math.atan2(z, math.sqrt(math.pow(x, 2) + math.pow(y, 2))) * 180 / math.pi)

			local yaw_dif = math.abs(own_yaw % 360 - yaw % 360) % 360
			local pitch_dif = math.abs(own_pitch - pitch ) % 360
	            
			if yaw_dif > 180 then yaw_dif = 360 - yaw_dif end
			local real_dif = math.sqrt(math.pow(yaw_dif, 2) + math.pow(pitch_dif, 2))

			if closest_distance > real_dif then
				closest_distance = real_dif
				closest_enemy = enemy
			end
		end

		if closest_enemy ~= nil then
			return closest_enemy, closest_distance
		end
	end

	return nil, nil
end

local function nearestHitbox() 
	if table.getn(interface.get(nearesthitbox_hitscan)) > 0 then 
		scanlist = {} 

		if inArr(interface.get(nearesthitbox_hitscan), near[1]) then
			table.insert(scanlist, "0")
			table.insert(scanlist, "1")
		end

		if inArr(interface.get(nearesthitbox_hitscan), near[2]) then
			table.insert(scanlist, "5")
			table.insert(scanlist, "6")
		end

		if inArr(interface.get(nearesthitbox_hitscan), near[3]) then
			table.insert(scanlist, "2")
			table.insert(scanlist, "3")
			table.insert(scanlist, "4")
		end

		if inArr(interface.get(nearesthitbox_hitscan), near[4]) then
			table.insert(scanlist, "13")
			table.insert(scanlist, "14")
			table.insert(scanlist, "15")
			table.insert(scanlist, "16")
			table.insert(scanlist, "17")
			table.insert(scanlist, "18")
		end

		if inArr(interface.get(nearesthitbox_hitscan), near[5]) then
			table.insert(scanlist, "7")
			table.insert(scanlist, "8")
			table.insert(scanlist, "9")
			table.insert(scanlist, "10")
		end

		if inArr(interface.get(nearesthitbox_hitscan), near[6]) then
			table.insert(scanlist, "11")
			table.insert(scanlist, "12")
		end

		closest_enemy, closest_distance = getNearestEnemy()

		if closest_enemy ~= nil then

			local table_size = table.getn(scanlist)

			local besthitbox = nil
			local besthitbox_dist = 999999999

			for i = 1, table_size do

				local own_x, own_y, own_z = cl.eye_pos()
				local own_pitch, own_yaw = cl.camera_angles()

				local enemy_x, enemy_y, enemy_z = ent.hitbox_pos(closest_enemy, tonumber(scanlist[i]))
			            
				local x = enemy_x - own_x
				local y = enemy_y - own_y
				local z = enemy_z - own_z 

				local yaw = ((math.atan2(y, x) * 180 / math.pi))
				local pitch = -(math.atan2(z, math.sqrt(math.pow(x, 2) + math.pow(y, 2))) * 180 / math.pi)

				local yaw_dif = math.abs(own_yaw % 360 - yaw % 360) % 360
				local pitch_dif = math.abs(own_pitch - pitch ) % 360
		            
				if yaw_dif > 180 then yaw_dif = 360 - yaw_dif end
				local real_dif = math.sqrt(math.pow(yaw_dif, 2) + math.pow(pitch_dif, 2))

				if besthitbox_dist > real_dif then
					besthitbox = tonumber(scanlist[i])
					besthitbox_dist = real_dif
				end

			end

			if besthitbox ~= nil then

				if besthitbox == 0 or besthitbox == 1 then ui.set(rage_selection, "Head") end
				if besthitbox == 5 or besthitbox == 6 then ui.set(rage_selection, "Chest") end
				if besthitbox == 2 or besthitbox == 3 or besthitbox == 4 then ui.set(rage_selection, "Stomach") end

				if besthitbox == 13 or besthitbox == 14 or besthitbox == 16 or besthitbox == 17 or besthitbox == 18 then
					ui.set(rage_selection, "Arms")
				end

				if besthitbox == 7 or besthitbox == 8 or besthitbox == 9 or besthitbox == 10 then
					ui.set(rage_selection, "Legs")
				end

				if besthitbox == 11 or besthitbox == 12 then
					ui.set(rage_selection, "Feet")
				end

			end

		end
	end
end

local function doDynamicFOV()
	local mode = interface.get(dynamicfov_mode)
	if mode ~= 'Off' then

	 	local old_fov = interface.get(rage_fov)
	    local min_fov = interface.get(dynamicfov_min)
	    local max_fov = interface.get(dynamicfov_max)

	    local own_x, own_y, own_z = cl.eye_pos()
	   	closest_enemy, closest_distance = getNearestEnemy()
	        
		if closest_enemy ~= nil then
			local closest_enemy_x, closest_enemy_y, closest_enemy_z = ent.hitbox_pos(closest_enemy, 0)
			local real_distance = math.sqrt(math.pow(own_x - closest_enemy_x, 2) + math.pow(own_y - closest_enemy_y, 2) + math.pow(own_z - closest_enemy_z, 2))

			if mode == "Static" then
				dynamicfov_new_fov = max_fov - ((max_fov - min_fov) * (real_distance - 250) / 1000)
			elseif mode == "Auto"  then
				dynamicfov_new_fov = (3800 / real_distance) * (interface.get(dynamicfov_auto_factor) * 0.01)
			end

			if (dynamicfov_new_fov > max_fov) then
				dynamicfov_new_fov = max_fov
			elseif dynamicfov_new_fov < min_fov then
				dynamicfov_new_fov = min_fov
			end
	    else 
	        dynamicfov_new_fov = min_fov
	    end

	    dynamicfov_new_fov = math.floor(dynamicfov_new_fov)
	    if dynamicfov_new_fov ~= old_fov then
	    	interface.set(rage_fov, dynamicfov_new_fov)
	    end
	    
	end
end

local function doDynamicFOV_Draw(ctx)
	if interface.get(dynamicfov_mode) ~= "Off" and inArr(interface.get(indicators), inds[4]) then
		local i_r, i_g, i_b, i_a = interface.get(dynamicfov_color_picker)

		local screen_width, screen_height = client.screen_size()
		local screen_width_mid, screen_height_mid = screen_width / 2, screen_height / 2
		local vm_fov = client.get_cvar('viewmodel_fov')
		local fov_radius = dynamicfov_new_fov / vm_fov * screen_width / 2

		cl.circle(ctx, screen_width_mid, screen_height_mid, i_r, i_g, i_b, i_a, fov_radius, 0, 1)
	end
end

-- Main stuff

local choked, alp = 0, 0
local function on_run_command(e)

	if not interface.get(legitmode) or ent.get_prop(ent.get_local(), "m_iHealth") <= 0 then 
		return
	end

	choked = e.chokedcommands
	nearestHitbox() 
	doDynamicFOV()

	if interface.get(slowmo_correct) then
		if interface.get(slowmo) then
			cl.exec("unbind shift")
		else
			cl.exec("bind shift +speed")
		end

	end

    if cache.rb_active == nil then cache.rb_active = interface.get(rage) end
	if cache.aa_real == nil then cache.aa_real = interface.get(aa_yaw) end
	
    if interface.get(legit_hotkey) then
		interface.set(aa_yaw, "Off")
		interface.set(rage, false)
		interface.set(rage_recoil, false)
    else
	    if cache.aa_real ~= nil then
            interface.set(aa_yaw, cache.aa_real)
            cache.aa_real = nil
        end
	
        if cache.rb_active ~= nil then
            interface.set(rage, cache.rb_active)
			interface.set(rage_recoil, cache.rb_active)
            cache.rb_active = nil
        end
    end

    if interface.get(autowall_check) then
		interface.set(rage_awall, interface.get(autowall_hk))
	end

	if interface.get(resolver_check) then
    	interface.set(rage_resolver, interface.get(resolver_hk))
	end

    if interface.get(restrictions) then

    	if interface.get(aa_pitch) ~= "Off" then
    		cl.log("Restrictions: Pitch changed to OFF")
    		interface.set(aa_pitch, "Off")
    	end

    	if interface.get(aa_fake) ~= "Local view" then
    		cl.log("Restrictions: Fake yaw changed to Local view")
    		interface.set(aa_fake, "Local view")
    	end

    	if interface.get(rage_fov) > 10 then
    		cl.log("Restrictions: Maximum fov changed to 10")
    		interface.set(rage_fov, 10)
    	end

    	if interface.get(rage_silent) then
    		cl.log("Restrictions: Silent aim disabled")
    		interface.set(rage_silent, false)
    	end

    	if interface.get(rage_target) ~= "Near crosshair" then
    		cl.log("Restrictions: Target selection changed to Nearest")
    		interface.set(rage_target, "Near crosshair")
    	end

    end
end

local varcached = {
	awall = nil,
	res = nil
}

local alpha = 0
local function on_paint(c)
	if not interface.get(legitmode) or ent.get_prop(ent.get_local(), "m_iHealth") <= 0 then 
		return
	end

	doDynamicFOV_Draw(c)
	
	if not interface.get(restrictions) then
		cl.indicator(c, 255, 0, 0, 255, "IS")
	end

	-- AutoWall
	if inArr(interface.get(indicators), inds[1]) and interface.get(autowall_check) then
		if varcached.awall ~= interface.get(autowall_hk) then
			varcached.awall = interface.get(autowall_hk)
			alpha = 512
		end

		if alpha > 0 then
			if interface.get(rage_awall) then
				cl.indicator(c, 124, 195, 13, alp, "AW")
			else
				cl.indicator(c, 255, 0, 0, alp, "AW")
			end
		end
	end

	-- RESOLVER
	if inArr(interface.get(indicators), inds[2]) and interface.get(resolver_check) then
		if varcached.res ~= interface.get(resolver_hk) then
			varcached.res = interface.get(resolver_hk)
			alpha = 512
		end

		if alpha > 0 then
			if interface.get(rage_resolver) then
				cl.indicator(c, 124, 195, 13, alp, "SO")
			else
				cl.indicator(c, 255, 0, 0, alp, "SO")
			end
		end
	end

	if inArr(interface.get(indicators), inds[3]) and interface.get(aa_fakelag_key) then
		local y = cl.indicator(c, 255, 255, 255, 255, "FL")
		if choked == 1 then choked = 0 end

		draw_indicator_circle(c, 55.5, (y + 14), 53, 110, 254, alpha, choked / interface.get(aa_fakelag_limit))
	end

	if alpha > -1 then 
		alpha = alpha - 1
	end

	alp = (alpha > 255 and 255 or alpha)
end

local function visibility()
	local r = interface.get(legitmode)
	local m = interface.get(dynamicfov_mode)

	interface.visible(restrictions, r)
	interface.visible(nearesthitbox_hitscan, r)
	interface.visible(dynamicfov_mode, r)

	if m == "Off" or not r then
		interface.visible(dynamicfov_min, false)
		interface.visible(dynamicfov_max, false)
		interface.visible(dynamicfov_auto_factor, false)
	elseif m == "Static" and r then
        interface.visible(dynamicfov_min, true)
        interface.visible(dynamicfov_max, true)
        interface.visible(dynamicfov_auto_factor, false)
    elseif m == "Auto" and r then
        interface.visible(dynamicfov_min, true)
        interface.visible(dynamicfov_max, true)
        interface.visible(dynamicfov_auto_factor, true)
    end

	interface.visible(autowall_check, r)
	interface.visible(autowall_hk, r)

	interface.visible(resolver_check, r)
	interface.visible(resolver_hk, r)

	interface.visible(indicators, r)
	interface.visible(dynamicfov_color_picker, r)
end


visibility(legitmode)
interface.callback(dynamicfov_mode, visibility)
interface.callback(legitmode, visibility)

client.set_event_callback("run_command", on_run_command)
client.set_event_callback("paint", on_paint)