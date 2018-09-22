local interface = {
	get = ui.get,
	set = ui.set
}

local cl = {
	log = client.log,
	exec = client.exec,
	indicator = client.draw_indicator,
	circle_outline = client.draw_circle_outline,
	realtime = globals.realtime
}

local ent = {
	get_local = entity.get_local_player,
	get_prop = entity.get_prop,
	uid_to_ent = client.userid_to_entindex
}

local IDLE, IN_ATTACK, IN_JUMP, IN_DUCK, IN_FORWARD, IN_BACK, IN_USE, IN_CANCEL, IN_LEFT, IN_RIGHT, IN_MOVELEFT, IN_MOVERIGHT, IN_ATTACK2, IN_RUN, IN_RELOAD, IN_ALT1, IN_ALT2, IN_SCORE, IN_WALK = 0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072

local rb, rb_toggle = ui.reference("RAGE", "Aimbot", "Enabled")
local slowmo, slowmo_toggle = ui.reference("AA", "Other", "Slow motion")
local rf = ui.reference("RAGE", "Other", "Double tap")


local rapid = ui.new_checkbox("RAGE", "Other", "Rapid fire")
local rapid_stuff = ui.new_checkbox("RAGE", "Other", "Disable rapid fire on stuff")
local rapid_fakelag = ui.new_checkbox("RAGE", "Other", "Fake lag with rapid fire")
local rapid_time = ui.new_slider("RAGE", "Other", "Rapid reset time", 1, 50, 15, true, "s", 0.1)

local function draw_indicator_circle(c, x, y, r, g, b, a, percentage, outline)
    local outline = outline or true
    local radius, start_degrees = 9, 0

	if outline then 
		cl.circle_outline(c, x, y, 0, 0, 0, 200, radius, start_degrees, 1.0, 5)
	end

    cl.circle_outline(c, x, y, r, g, b, 255, radius-1, start_degrees, percentage, 3) -- Inner Circle
end

local function setMath(int, max, declspec)
	local int = (int > max and max or int)

	local tmp = max / int;
	local i = (declspec / tmp)
	i = (i >= 0 and math.floor(i + 0.5) or math.ceil(i - 0.5))

	return i
end

local function getTickcount()
	return (1 / globals.tickinterval())
end

local function notAlive(entity)
	return (entity == nil or ent.get_prop(entity, "m_lifeState") ~= 0)
end

local release_at = nil
local number, timechange = 0, 0, 0
local wpn_type = nil

local function on_item_equip(e)
	if interface.get(rapid) and e.userid ~= nil and ent.uid_to_ent(e.userid) == ent.get_local() then
		number = 0
		wpn_type = e.weptype

		if interface.get(rapid) and (e.item == "scar20" or e.item == "sg556") then
			client.exec("-attack2; -lookatweapon; +attack2; +lookatweapon")
			release_at = globals.realtime() + 0.1
		else
			if release_at ~= nil then
				client.exec("-attack2; -lookatweapon")
				release_at = nil
			end
		end

	end
end

local timeon = 0
local function on_paint(c)
	if not interface.get(rapid) then return end
	if release_at ~= nil and release_at < globals.realtime() then
		release_at = nil
		client.exec("-attack2; -lookatweapon; +lookatweapon; -lookatweapon")
	end

	if notAlive(ent.get_local()) or not interface.get(rapid) then
		number = 0
		return
	end

	local tick = (0.2 - (getTickcount() / 1000))
	local weapon_id = ent.get_prop(ent.get_local(), "m_hActiveWeapon")
	local ammo = tonumber(ent.get_prop(weapon_id, "m_iClip1"))

	-- Earisng 
	local shots_fired = tonumber(ent.get_prop(ent.get_local(), "m_iShotsFired"))
	if shots_fired > 0 --[[ and timeon < cl.realtime() ]] then
		interface.set(rf, "On hotkey")
		timeon = cl.realtime() + (interface.get(rapid_time) / 10)
	elseif timeon < cl.realtime() then
		interface.set(rf, "Always on")
	end

	if interface.get(rapid_fakelag) then
		--[[
			local vel_x = ent.get_prop(ent.get_local(), "m_vecVelocity[0]")
			local vel_y = ent.get_prop(ent.get_local(), "m_vecVelocity[1]")
			local vel_z = ent.get_prop(ent.get_local(), "m_vecVelocity[2]")
			local vel = math.sqrt(vel_x * vel_x + vel_y * vel_y + vel_z * vel_z)
		]] -- Shit try to make some checks on movement

		if interface.get(slowmo_toggle) then
			interface.set(rf, "On hotkey")
		end
	end

	if interface.get(rapid_stuff) and (wpn_type == 0 or wpn_type == 7 or wpn_type == 8 or wpn_type == 9) then
		interface.set(rf, "On hotkey")
		return
	end

	-- Indicator
	local n, d = ammo
	if number ~= n and timechange < cl.realtime() then
		if number > n then d = -1 else d = 1 end
		timechange = cl.realtime() + tick
		number = number + d
	end

	if ammo ~= nil and ammo > 1 then
		local y = cl.indicator(c, 255, 255, 255, 255, number)

		if timeon > cl.realtime() then
			local i = setMath(timeon - cl.realtime(), interface.get(rapid_time) / 10, 100)
			draw_indicator_circle(c, 72.5, (y + 14), 53, 110, 254, alpha, i / 100)
		end
	end
end

local function m_visible()
	local act = interface.get(rapid)

	ui.set_visible(rapid_stuff, act)
	ui.set_visible(rapid_fakelag, act)
	ui.set_visible(rapid_time, act)
end

m_visible()
ui.set_callback(rapid, m_visible)

client.set_event_callback("paint", on_paint)
client.set_event_callback("item_equip", on_item_equip)