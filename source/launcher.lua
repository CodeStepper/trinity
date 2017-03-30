-- LIBRARIES
-- ==========================================================================================

local launcher = {
    mt = {}
}

-- NEW
-- ==========================================================================================

local function new( widget, args )
    -- sprawdź czy argumenty nie są puste
    if args == nil or widget == nil or args.menu == nil then
        return
    end
    
    -- reagowanie na naciśnięcie przycisku
    widget:connect_signal( "button::release", function(widget, x, y, button)
        args.menu:toggle()
    end )
    
    widget.worker = { menu = menu }
end

-- BATTERY.MT:CALL
-- ==========================================================================================

function launcher.mt:__call(...)
    return new(...)
end

-- SETMETATABLE
-- ==========================================================================================

return setmetatable( launcher, launcher.mt )
