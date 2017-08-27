-- LIBRARIES
-- ==========================================================================================

local awful_tag    = require("awful.tag")
local awful_layout = require("awful.layout")
local beautiful    = require("beautiful")
local surface      = require("gears.surface")

local layout = { mt = {}, images = {} }

-- LAYOUT.UPDATE
-- ==========================================================================================

function layout.update( widget, screen )
	local name = awful_layout.getname( awful_layout.get(screen) )
	
	-- załaduj obrazek
	if layout.images[name] == nil then
		fsuc, fres = pcall( surface.load, beautiful.layouts[name] )
		
		-- zapisz obrazek
		if fsuc == true then
			layout.images[name] = fres
		else
			layout.images[name] = false
		end
	end
	-- ustaw obrazek
	if layout.images[name] ~= false then
		widget:set_image( layout.images[name] )
	end
end

-- NEW
-- ==========================================================================================

local function new( widget, args )
	if args == nil or widget == nil then
		return
	end

	local screen = args.screen or 1
	
	-- dodawanie funkcji do obiektu
	for key, val in pairs(layout) do
		if type(val) == "function" then
			widget.worker[key] = val
		end
	end
	
	widget.worker.widget = widget
	widget.worker.update( widget, screen )
	
	-- aktualizacja rozmieszczenia okien
	local function tag_update( tag )
		return widget.worker.update( widget, awful_tag.getscreen(tag) )
	end
	
	-- odbieranie sygnałów
	awful_tag.attached_connect_signal( screen, "property::layout", tag_update )
	awful_tag.attached_connect_signal( screen, "property::selected", tag_update )
	
	-- reagowanie na naciśnięcie przycisku
	-- if args.nosignal ~= true then
	--     widget:connect_signal( "button::release", function(widget, x, y, button)
	--         if button == 1 then
	--             awful_layout.inc( args.layouts, 1 )
	--         elseif button == 3 then
	--             awful_layout.inc( args.layouts, -1 )
	--         end
	--     end )
	-- end
end

-- LAYOUT.MT:CALL
-- ==========================================================================================

function layout.mt:__call(...)
	return new(...)
end

-- SETMETATABLE
-- ==========================================================================================

return setmetatable( layout, layout.mt )
