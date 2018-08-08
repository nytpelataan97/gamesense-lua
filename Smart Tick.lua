local interface = {
	get = ui.get,
	set = ui.set,
	ref = ui.reference,
	s_callback = ui.set_callback,
	checkbox = ui.new_checkbox,
	visible = ui.set_visible,
	slider = ui.new_slider
}

local ent = {
	get_local = entity.get_local_player,
	get_prop = entity.get_prop,
	get_all = entity.get_all
}

local cl = {
	draw = client.draw_text,
	size = client.screen_size,
	latency = client.latency,
	tickcount =  globals.tickcount
}

local flag, flag_hotkey = interface.ref("AA", "Fake lag", "Enabled")
local slowmo, slowmo_hotkey = interface.ref("AA", "Other", "Slow motion")
local pingspike, pingspike_hotkey = interface.ref("MISC", "Miscellaneous", "Ping spike")
local override, override_hotkey = interface.ref("RAGE", "Other", "Anti-aim resolver override")

local apr_ref = interface.ref("AA", "Fake Lag", "Enabled")
local apr_active = interface.checkbox("MISC", "Miscellaneous", "Anti pingspike reset")
local apr_maximum = interface.slider("MISC", "Miscellaneous", "Maximum ping", 1, 750, 250, true, "ms")

local m_iLatency = 0
local m_iOverride = 0
local sw, sh = cl.size()
local x, y = sw / 2, sh - 350
local y = y + 323

local function clamp(int, max)
	return int > max and max or int
end

local function getlatency()
	local var = ent.get_prop(ent.get_all("CCSPlayerResource")[1], string.format("%03d", ent.get_local()))
	return clamp(var, 999)
end

function get_velocity()
	local vel_x = ent.get_prop(ent.get_local(), "m_vecVelocity[0]")
	local vel_y = ent.get_prop(ent.get_local(), "m_vecVelocity[1]")
	local vel_z = ent.get_prop(ent.get_local(), "m_vecVelocity[2]")
	
	return math.sqrt(vel_x * vel_x + vel_y * vel_y + vel_z * vel_z)
end

local function HSVToRGB(h, s, v)
  local r, g, b
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)
  i = i % 6
  if i == 0 then r, g, b = v, t, p
     elseif i == 1 then r, g, b = q, v, p
     elseif i == 2 then r, g, b = p, v, t
     elseif i == 3 then r, g, b = p, q, v
     elseif i == 4 then r, g, b = t, p, v
     elseif i == 5 then r, g, b = v, p, q
  end

  return r * 255, g * 255, b * 255
end

local function lerp(h1, s1, v1, h2, s2, v2, t)
	local h = (h2 - h1) * t + h1
	local s = (s2 - s1) * t + s1
	local v = (v2 - v1) * t + v1
	return h, s, v
end

local function isActive(ping)
	return interface.get(apr_active) and not (interface.get(apr_maximum) > ping)
end

local function visibility(this)
	local v = interface.get(this)
	interface.visible(apr_maximum, v)
end

local function getIndYaw(y, cNum)
	return (y - (30 * cNum))
end

interface.s_callback(apr_active, visibility)

local function on_paint(c)
	if ent.get_prop(ent.get_local(), "m_iHealth") <= 0 then
		return
	end

	local shoudDraw = 0
	local ping = getlatency()
	local r_ping = math.floor(math.min(1000, cl.latency() * 1000) + 0.5);
	
	local cl_ping = ping - r_ping
	if cl_ping < 1 then cl_ping = 1 end
	
	local maxNum = interface.get(apr_maximum)
	local h, s, v = lerp(0, 1, 1, 120, 1, 1, 1000 - (clamp(cl_ping, maxNum) * (1/maxNum)))
	local r, g, b = HSVToRGB(h/360, s, v)
	
	if interface.get(apr_active) then
		interface.set(apr_ref, not (interface.get(pingspike_hotkey) and interface.get(apr_maximum) <= ping))
	end
	
	if interface.get(apr_ref) and not isActive(ping) then		
		shoudDraw = 1
	else
		local isr = 0
		r = 255
		g = 255
		b = 255
		
		if interface.get(apr_active) then
			if not interface.get(pingspike_hotkey) and interface.get(apr_maximum) <= ping then
				isr = 1
			end
		end
		
		if isr == 1 then
			
			local ticknum = 70
			local tickcount = (cl.tickcount() % ticknum)
			
			if tickcount >= (ticknum / 2) then 
				shoudDraw = 1
			end
		else
			shoudDraw = 1
		end
	end
	
	if get_velocity() > 0 and not interface.get(slowmo_hotkey) and not interface.get(pingspike_hotkey) then
		m_iLatency = 83 -- Latency X Position
	else
		m_iLatency = 105 -- Latency X Position
	end
	
	if shoudDraw == 1 then
		cl.draw(c, m_iLatency, getIndYaw(y, 1), r, g, b, 255, "c+", 0, "NA") -- Lag Factor IND
	end

--[[
	if interface.get(override_hotkey) then
		cl.draw(c, m_iLatency, getIndYaw(y, 2), 124, 195, 13, 255, "c+", 0, "OR") 
	else
	 	cl.draw(c, m_iLatency, getIndYaw(y, 2), 255, 0, 0, 255, "c+", 0, "OR")
	end
--]]

end

client.set_event_callback("paint", on_paint)