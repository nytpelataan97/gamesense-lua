local interface = {
	get = ui.get,
	set = ui.set,
	ref = ui.reference,
	callback = ui.set_callback,
	checkbox = ui.new_checkbox,
	visible = ui.set_visible,
	slider = ui.new_slider,
	multiselect = ui.new_multiselect
}

local ent = {
	get_local = entity.get_local_player,
	get_prop = entity.get_prop,
	get_all = entity.get_all
}

local cl = {
	indicator = client.draw_indicator,
	circle_outline = client.draw_circle_outline,

	draw = client.draw_text,
	size = client.screen_size,
	exec = client.exec,
	ute = client.userid_to_entindex,
	latency = client.latency,
	tickcount = globals.tickcount,
	curtime = globals.curtime,
	realtime = globals.realtime
}

-- Some functions

local function inArr(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function getlatency()
	local prop = ent.get_all("CCSPlayerResource")[1]
	local latency_client = ent.get_prop(prop, string.format("%03d", ent.get_local()))
	local latency_server = math.floor(math.min(1000, cl.latency() * 1000) + 0.5)

	latency_client = (latency_client > 999 and 999 or latency_client)

	local latency_decl = latency_client - latency_server - 5
	if latency_decl < 1 then latency_decl = 1 end

	return latency_client, latency_server, latency_decl
end

local function setMath(int, max, declspec)
	local int = (int > max and max or int)

	local tmp = max / int;
	local i = (declspec / tmp)
	i = (i >= 0 and math.floor(i + 0.5) or math.ceil(i - 0.5))

	return i
end

local function getColor(number, max)
	local r, g, b
	local i = setMath(number, max, 9)

	if i == 9 then r, g, b = 255, 0, 0
		elseif i == 8 then r, g, b = 237, 27, 3
		elseif i == 7 then r, g, b = 235, 63, 6
		elseif i == 6 then r, g, b = 229, 104, 8
		elseif i == 5 then r, g, b = 228, 126, 10
		elseif i == 4 then r, g, b = 220, 169, 16
		elseif i == 3 then r, g, b = 213, 201, 19
		elseif i == 2 then r, g, b = 176, 205, 10
		elseif i <= 1 then r, g, b = 124, 195, 13
	end

	return r, g, b
end

local function draw_indicator_circle(c, x, y, r, g, b, a, percentage, outline)
    local outline = outline or true
    local radius, start_degrees = 9, 0

	if outline then 
		cl.circle_outline(c, x, y, 0, 0, 0, 200, radius, start_degrees, 1.0, 5)
	end

    cl.circle_outline(c, x, y, r, g, b, 255, radius-1, start_degrees, percentage, 3) -- Inner Circle
end

-- Menu
local flag, flag_hotkey = interface.ref("AA", "Fake lag", "Enabled")
local slowmo, slowmo_hotkey = interface.ref("AA", "Other", "Slow motion")
local pingspike, pingspike_hotkey = interface.ref("MISC", "Miscellaneous", "Ping spike")
local accuracyboost = interface.ref("RAGE", "Other", "Accuracy boost options")

local ms = { "Refine shot", "Extended backtrack" }
local actions = { "Fakelag trigger", "Accuracy boost correction" }

local apr_active = interface.checkbox("MISC", "Miscellaneous", "Ping spike correction")
local apr_mselect = interface.multiselect("MISC", "Miscellaneous", "Lag triggers", actions)
local apr_pingthreshold = interface.slider("MISC", "Miscellaneous", "Ping spike threshold", 1, 750, 250, true, "ms")
local apr_acthreshold = interface.slider("MISC", "Miscellaneous", "Accuracy boost threshold", 0, 450, 180, true, "ms")
local apr_acboost = interface.multiselect("MISC", "Miscellaneous", "Accuracy boost flags", ms)

-- Event Functions

local factor, timechange = 0, 0
local function on_paint(c)
	if not interface.get(apr_active) or ent.get_prop(ent.get_local(), "m_iHealth") <= 0 then
		return
	end

	local alpha = 255
	local latency_client, latency_server, latency_decl = getlatency()

	if inArr(interface.get(apr_mselect), actions[1]) then
		interface.set(flag, not (interface.get(pingspike_hotkey) and interface.get(apr_pingthreshold) <= latency_client))
	end

	local pNum, d = setMath(latency_decl, interface.get(apr_pingthreshold), 100)
	if factor ~= pNum and timechange < cl.realtime() then
		if factor > pNum then d = -1 else d = 1 end
		
		timechange = cl.realtime() + 0.05
		factor = factor + d
	end

	local r, g, b = getColor(factor, 100)
	if not (interface.get(flag) and interface.get(apr_pingthreshold) > latency_client) then

		local tickcount = (cl.tickcount() % 127.5)
		if not interface.get(pingspike_hotkey) and (interface.get(apr_pingthreshold) <= latency_client) then
			if tickcount > 63.75 then
				alpha = 255 - (tickcount * 4)
			else
				alpha = tickcount * 4
			end
		end

	end

	if inArr(interface.get(apr_mselect), actions[1]) and not interface.get(flag) and interface.get(apr_pingthreshold) < latency_client then
		r, g, b = 53, 110, 254
	else
		if inArr(interface.get(apr_mselect), actions[2]) and interface.get(apr_acthreshold) > 0 then
			if interface.get(pingspike_hotkey) and interface.get(apr_acthreshold) < latency_decl then
				r, g, b = 124, 195, 13
			end
		end
	end

	if factor >= 1 then
		_r, _g, _b = 255, 255, 255
		if not interface.get(pingspike_hotkey) then
			_r, _g, _b = 255, 0, 0
		end

		local y = cl.indicator(c, _r, _g, _b, alpha, "LAG") -- Lag Factor
		draw_indicator_circle(c, 75, (y + 14), r, g, b, alpha, factor / 100)
	end
end

local function on_run_cmd(e)
	if not interface.get(apr_active) or ent.get_prop(ent.get_local(), "m_iHealth") <= 0 then
		return
	end

	local choken_n = e.chokedcommands
	local latency, latency_server, latency_decl = getlatency()
	
	if inArr(interface.get(apr_mselect), actions[2]) and interface.get(apr_acthreshold) > 0 then
	
		if interface.get(pingspike_hotkey) and interface.get(apr_acthreshold) < latency_decl then
			interface.set(accuracyboost, interface.get(apr_acboost))
		else
			interface.set(accuracyboost, "")
		end

	end
end

local function visibility(this)
	interface.visible(apr_mselect, interface.get(this))
	interface.visible(apr_pingthreshold, interface.get(this))

	-- Accuracy boost
	interface.visible(apr_acthreshold, interface.get(this))
	interface.visible(apr_acboost, interface.get(this))
end

interface.callback(apr_active, visibility)

client.set_event_callback("paint", on_paint)
client.set_event_callback("run_command", on_run_cmd)