-- LIBRARIES
-- ==========================================================================================

local beautiful    = require("beautiful")
local surface      = require("gears.surface")

local sound = {
    mt     = {},
    images = {}
}

-- LOAD_IMAGE
-- ==========================================================================================

local function load_image( slot, image )
    if sound.images[slot] == nil then
        -- załaduj obrazek
        fsuc, fres = pcall( surface.load, image )
            
        -- zapisz obrazek
        if fsuc == true then
            sound.images[slot] = fres
        else
            sound.images[slot] = false
        end
    end
    
    return sound.images[slot]
end

-- SOUND.UPDATE
-- ==========================================================================================

function sound.update( widget )
    -- pobierz dane
    local con   = io.popen( "amixer -M get " .. widget.worker.mixer )
    local icons = beautiful.widget_icon.sound
    local image = nil
    
    local content = con:read( "*all" )
    con:close()
    
    -- poziom głośności i wyciszenie
    local vol, mute = string.match( content, "([%d]+)%%.*%[([%l]*)" )
    
    -- brak danych?
    if vol == nil then
    else
        if mute == "" and vol == "0" or mute == "off" then
            mute = true
        else
            mute = false
        end
    end
    
    -- wyświetl poziom głośności
    widget:set_text( vol .. "%" )
    
    -- wyciszenie
    if mute == true then
        image = load_image( "mute", icons.mute )
    else
        -- poziom 0
        if vol == "0" then
            image = load_image( "s0", icons.s0 )
        -- poziomy z uwzględnieniem 0
        elseif widget.worker.zwerosep ~= true then
            local idximg = "s" .. math.floor( vol * (icons.sc-1) / 100 + 0.49 )
            image = load_image( idximg, icons[idximg] )
        -- poziomy bez uwzględnienia 0
        else
            local idximg = "s" .. (math.floor( vol * (icons.sc-2) / 100 + 0.49 ) + 1)
            image = load_image( idximg, icons[idximg] )
        end
    end
    
    -- ustaw ikonę
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
    local timeout = args.timeout or 60

    -- dodawanie funkcji do obiektu
    for key, val in pairs(sound) do
        if type(val) == "function" then
            widget.worker[key] = val
        end
    end
    
    -- dane
    widget.worker.batpath = batpath .. batname .. "/"
    widget.worker.data    = {}
    widget.worker.zerosep = args.zerosep or true
    widget.worker.mixer   = args.mixer or "Master"
    
    -- oddzielna ikona dla 0
    if beautiful.widget_icon.sound.sc < 2 and widget.worker.zerosep == true then
        widget.worker.zerosep = false
    end
    
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

function sound.mt:__call(...)
    return new(...)
end

-- SETMETATABLE
-- ==========================================================================================

return setmetatable( sound, sound.mt )
