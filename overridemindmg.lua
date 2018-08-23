local interface = {
	get = ui.get,
	set = ui.set,
    ref = ui.reference,
    indicator = client.draw_indicator,
	slider = ui.new_slider,
    hotkey = ui.new_hotkey
}

local cache = nil
local ref = interface.ref("RAGE", "Aimbot", "Minimum damage")

local mdmg_key = interface.hotkey("RAGE", "Other", "Override minimum damage")
local mdmg_numeric = interface.slider("RAGE", "Other", "Minimum damage", 1, 126, 105, 1, "hp")

local function on_paint(c)
    if cache == nil then
        cache = interface.get(ref)
    end

    if interface.get(mdmg_key) then
        interface.set(ref, interface.get(mdmg_numeric))
        interface.indicator(c, 255, 255, 255, 150, "DMG")
    else
        if cache ~= nil then
            interface.set(ref, cache)
            cache = nil
        end
    end
end

client.set_event_callback("paint", on_paint)