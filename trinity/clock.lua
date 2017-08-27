-- LIBRARIES / VARIABLES
-- ==========================================================================================

local clock = { mt = {} }
local timer = (type(timer) == 'table' and timer or require("gears.timer"))

-- NEW
-- ==========================================================================================

local function new( widget, args )
    -- sprawdź potrzebne argumenty
    if args == nil or widget == nil then
        return
    end
    
    -- format daty
    local format  = args.format or "%d/%m/%Y %H:%M"
    local timeout = args.timeout or 60
    
    -- TODO global timeout
    -- dodaj czasomierz
    if type(timeout) == "number" then
        widget.worker.timer = timer({ timeout = timeout })
        widget.worker.timer:connect_signal( "timeout", function()
            widget:set_text( os.date(format) )
        end )
        -- uruchom i zaktualizuj element
        widget.worker.timer:start()
        widget.worker.timer:emit_signal( "timeout" )
    end
end

-- LAYOUT.MT:CALL
-- ==========================================================================================

function clock.mt:__call(...)
    return new(...)
end

-- SETMETATABLE
-- ==========================================================================================

return setmetatable( clock, clock.mt )