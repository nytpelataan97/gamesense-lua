local function setMath(int, max, declspec)
	local int = (int > max and max or int)

	local tmp = max / int;
	local i = (declspec / tmp)
	i = (i >= 0 and math.floor(i + 0.5) or math.ceil(i - 0.5))

	return i
end

local function getColor(number, max)
	local r, g, b
	i = setMath(number, max, 9)

	if i <= 1 then r, g, b = 255, 0, 0
		elseif i == 2 then r, g, b = 237, 27, 3
		elseif i == 3 then r, g, b = 235, 63, 6
		elseif i == 4 then r, g, b = 229, 104, 8
		elseif i == 5 then r, g, b = 228, 126, 10
		elseif i == 6 then r, g, b = 220, 169, 16
		elseif i == 7 then r, g, b = 213, 201, 19
		elseif i == 8 then r, g, b = 176, 205, 10
		elseif i == 9 then r, g, b = 124, 195, 13
	end

	return r, g, b
end

--[[

    Using:

    local cl = {
        indicator = client.draw_indicator
    }

    local function on_paint(c)
        local c_Latency = getPing() -- Some function
        local r, g, b = getColor(c_Latency, 999)

        cl.indicator(c, r, g, b, 255, "PING") -- Shows your ping
    end

    client.set_event_callback("paint", on_paint)

]]--