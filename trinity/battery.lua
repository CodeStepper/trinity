-- LIBRARIES
-- ==========================================================================================

local beautiful    = require("beautiful")
local surface      = require("gears.surface")

local battery = {
    mt     = {},
    images = {},
    status = {
        ["Unknown"]     = 0,
        ["Charging"]    = 1,
        ["Discharging"] = 2,
        ["Charged"]     = 3,
        ["Full"]        = 3
    }
}

-- LOAD_FILE
-- ==========================================================================================

local function load_file( file )
    local file = io.open( file )
    local str  = nil
    
    -- nie można otworzyć pliku...
    if file ~= nil then
        str = file:read()
        file:close()
    end
    
    return str
end

-- LOAD_IMAGE
-- ==========================================================================================

local function load_image( slot, image )
    if battery.images[slot] == nil then
        -- załaduj obrazek
        fsuc, fres = pcall( surface.load, image )
            
        -- zapisz obrazek
        if fsuc == true then
            battery.images[slot] = fres
        else
            battery.images[slot] = false
        end
    end
    
    return battery.images[slot]
end

-- BATTERY.UPDATE
-- ==========================================================================================

function battery.update( widget )
    local path   = widget.worker.batpath
    local worker = widget.worker
    local image  = nil
    local icons  = beautiful.widget_icon.battery
    
    -- status i aktualny stan baterii
    worker.data.status   = battery.status[load_file(path .. "status") or "Unknown"]
    worker.data.capacity = math.min( tonumber(load_file( path .. "capacity" ) or 0), 100 )
    
    -- ustaw pojemność baterii
    widget:set_text( worker.data.capacity .. "%" )
    
    -- rozpoznaj odpowiedni status elementu
    if worker.data.status == 0 then
        image = load_image( "unknown", icons.unknown )
    elseif worker.data.status == 1 then
        local idximg = "c" .. math.floor( worker.data.capacity * (icons.cc-1) / 100 + 0.49 )
        image = load_image( idximg, icons[idximg] )
    elseif worker.data.status == 2 then
        local idximg = "d" .. math.floor( worker.data.capacity * (icons.dc-1) / 100 + 0.49 )
        image = load_image( idximg, icons[idximg] )
    else
        image = load_image( "charged", icons.charged )
    end
    
    -- ustaw ikonę baterii
    widget:set_image( image )
end

-- NEW
-- ==========================================================================================

local function new( widget, args )
    -- sprawdź czy argumenty nie są puste
    if args == nil or widget == nil then
        return
    end
    
    -- śnieżka do pliku z informacjami o baterii
    local batpath = args.batpath or "/sys/class/power_supply/"
    local batname = args.battery or "BAT0"
    local timeout = args.timeout or 2

    -- dodawanie funkcji do obiektu
    for key, val in pairs(battery) do
        if type(val) == "function" then
            widget.worker[key] = val
        end
    end
    
    -- dane
    widget.worker.batpath = batpath .. batname .. "/"
    widget.worker.data    = {}
    
    -- aktualizacja elementu
    widget.worker.update( widget )
    
    -- TODO global timeout
    -- dodaj czasomierz
    if type(timeout) == "number" then
        widget.worker.timer = timer({ timeout = timeout })
        widget.worker.timer:connect_signal( "timeout", function()
            widget.worker.update( widget )
        end )
        -- uruchom i zaktualizuj element
        widget.worker.timer:start()
        widget.worker.timer:emit_signal( "timeout" )
    end
end

-- BATTERY.MT:CALL
-- ==========================================================================================

function battery.mt:__call(...)
    return new(...)
end

-- SETMETATABLE
-- ==========================================================================================

return setmetatable( battery, battery.mt )
