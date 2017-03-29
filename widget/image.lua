-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- @author    sobiemir
-- @release   v3.5.9
-- @license   GPL, see LICENSE file
--
-- Kontrolka obrazka.
-- Po ustawieniu przechwytywania akcji może spełniać rolę przycisku.
--
-- @todo Sprawdzić zachowanie przy skalowaniu obrazka...
-- @todo Podanie nieparzystej wysokości kontrolki przy parzystych wymiarach obrazka powoduje
--       brzydkie wyświetlanie obrazka (zrobić przyleganie tylko do liczb całkowitych)
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

local pcall        = pcall
local type         = type
local pairs        = pairs
local setmetatable = setmetatable

local signal  = require("trinity.signal")
local visual  = require("trinity.visual")
local surface = require("gears.surface")
local image   = {}

-- =================================================================================================
-- Konstruktor pola obrazkowego.
-- 
-- Lista możliwych do przekazania argumentów i funkcje do ich późniejszego przestawienia:
--   - show_empty   @ show_empty     : Rysowanie pustego pola obrazkowego.
--   - image        @ set_image      : Adres wyświetlanego obrazka.
--   - stretch      @ set_stretch    : Skalowanie obrazka.
--   - keep_aspect  @ keep_aspect    : Zachowanie proporcji podczas skalowania.
--   - valign       @ set_align      : Przyleganie obrazka w pionie.
--   - halign       @ set_align      : Przyleganie obrazka w poziomie.
-- # group["padding"]
--   - padding      @ set_padding    : Margines wewnętrzny.
-- # group["back"]
--   - background   @ set_background : Tło kontrolki.
-- # group["border"]
--   - border_color @ set_border     : Kolor ramki wokół kontrolki.
--   - border_size  @ set_border     : Rozmiar ramki wokół kontrolki.
--
-- @param args    Tablica zawierająca wyżej wymienione argumenty (opcjonalny).
-- @param signals Przechwytywane przez kontrolkę sygnały (opcjonalny).
--
-- @return Nowy obiekt pola obrazkowego.
-- =================================================================================================

local function new( args )
    local args = args or {}

    -- utwórz podstawę elementu
    local retval = {}
    
    signal.initialize( retval )

    -- przypisz funkcje do obiektu
    for key, val in pairs(image) do
        if type(val) == "function" then
            retval[key] = val
        end
    end
    
    -- pobierz grupy
    local groups = args.groups or {}
    
    -- nie pozwalaj na dodanie określonych grup
    for key, val in pairs(groups) do
        if val == "text" or val == "fore" then
            groups[key] = nil
        end
    end
    
    -- inicjalizacja grup i funkcji
    visual.initialize( retval, groups, args )
    
    -- ustaw dodatkowe zmienne
    retval:show_empty( args.show_empty or false, false )
    retval:set_image( args.image, false )
    retval:set_stretch( args.stretch or false, false )
    retval:keep_aspect( args.keep_aspect or false, false )
    retval:set_align( args.valign, args.halign, false )
    
    return retval
end

-- =================================================================================================
-- Rysuje obrazek na kontrolce nadrzędnej.
-- Przy rysowaniu sprawdza przyleganie obrazka do konkretnej krawędzi.
-- 
-- @param cr Obiekt CAIRO (biblioteka graficzna).
-- =================================================================================================

function image:draw( cr )
    -- nie rysuj gdy wymiary są zerowe...
    if self._bounds[5] == 0 or self._bounds[6] == 0 then
        return
    end

    -- część wizualna
    self:draw_visual( cr )
    
    -- rysuj obrazek
    cr:save()
    
    -- pobierz obszar rysowania i wymiary obrazka
    local x, y, w, h = self:get_inner_bounds()
    local ofx, ofy = 0, 0
    
    -- obrazek nie pasuje do obszaru
    if w ~= self._image_dim[1] or h ~= self._image_dim[2] then
        -- powiększanie obrazka
        if self._stretch then
            cr:scale( self._scale_dim[1], self._scale_dim[2] )
        end
        -- przyleganie w poziomie
        if self._halign ~= visual.halign_type.left then
            ofx = w - (self._scale_dim[1] * self._image_dim[1])
            if self._halign == visual.halign_type.center then
                ofx = ofx / 2
            end
        end
        -- przyleganie w pionie
        if self._valign ~= visual.valign_type.top then
            ofy = h - (self._scale_dim[2] * self._image_dim[2])
            
            if self._valign == visual.valign_type.center then
                ofy = ofy / 2
            end
        end
    end
    
    -- rysuj obrazek
    cr:set_source_surface( self._image, (x + ofx) / self._scale_dim[1], (y + ofy) / self._scale_dim[2] )
    cr:paint()
    
    cr:restore()
end

-- =================================================================================================
-- Dopasowywanie obrazu do podanych rozmiarów lub pobieranie rozmiaru obrazka.
-- W zależności od ustawień, pobierany rozmiar jest dopasowywany w zależności od ustawień
-- parametrów.
-- 
-- @param cr Obiekt CAIRO (biblioteka graficzna).
--
-- @return Szerokość i wysokość całkowita kontrolki.
-- =================================================================================================

function image:fit( width, height )
    local new_width  = width
    local new_height = height

    -- obszar do pominięcia (wcięcie)
    local marw = self._padding[1] + self._padding[3]
    local marh = self._padding[2] + self._padding[4]
    
    -- przypisz wymiary obrazka
    self._scale_dim[1] = 1.0
    self._scale_dim[2] = 1.0

    -- nie licz jeżeli wymiary są mniejsze niż wcięcie
    if (width ~= -1 and width <= marw) or (height ~= -1 and height <= marh) then
        return 0, 0
    end

    -- pobierz wymiary obrazka gdy funkcja o to prosi
    if width == -1 or height == -1 then
        if width == -1 then
            new_width = self._image_dim[1] + marw
        end
        if height == -1 then
            new_height = self._image_dim[2] + marh
        end
    end

    -- rozciągnij gdy to potrzebne i sprawdź czy obrazek ma być rozciągany w stosunku 1:1
    if self._stretch then
        -- dopasuj szerokość
        if width == -1 and height > 0 then
            self._scale_dim[2] = (new_height - marh) / self._image_dim[2]
            self._scale_dim[1] = self._aspect and self._scale_dim[2] or 1.0

            new_width  = self._scale_dim[1] * self._image_dim[1] + marw
        -- dopasuj wysokość
        elseif height == -1 and width > 0 then
            self._scale_dim[1] = (new_width - marw) / self._image_dim[1] 
            self._scale_dim[2] = self._aspect and self._scale_dim[1] or 1.0

            new_height = self._scale_dim[2] * self._image_dim[2] + marh
        -- dopasuj cokolwiek
        elseif width > 0 and height > 0 then
            local calc_width  = (width  - marw) / self._image_dim[1]
            local calc_height = (height - marh) / self._image_dim[2]

            if self._aspect then
                self._scale_dim[1] = calc_width > calc_height and calc_height or calc_width
                self._scale_dim[2] = self._scale_dim[1]
            else
                self._scale_dim[1] = calc_width
                self._scale_dim[2] = calc_height
            end
        end
    end

    -- zero (tylko gdy 0 wyjdzie przy -1)...
    if not self._drawnil and (new_width == 0 or new_height == 0) then
        return 0, 0
    end
    
    return new_width, new_height
end

-- =================================================================================================
-- Wyświetlanie elementu nawet gdy jest pusty (brak obrazka).
-- 
-- @param value  Wyświetla lub chowa pustą kontrolkę.
-- @param update Wysyłanie sygnału aktualizacji kontrolki.
--
-- @return Obiekt kontrolki obrazka.
-- =================================================================================================

function image:show_empty( value, update )
    self._drawnil = value
    
    -- wyślij sygnał aktualizacji elementu
    if update == nil or update then
        self:emit_signal( "widget::resized" )
        self:emit_signal( "widget::updated" )
    end

    return self
end

-- =================================================================================================
-- Zmienia zachowanie stosunku szerokości do wysokości w przypadku skalowania obrazka.
-- 
-- @param value  Zachowuje lub nie stosunek szerokości do wysokości obrazka z jakim jest skalowany.
-- @param update Wysyłanie sygnału aktualizacji kontrolki.
--
-- @return Obiekt kontrolki obrazka.
-- =================================================================================================

function image:keep_aspect( value, update )
    self._aspect = value
    
    -- wyślij sygnał aktualizacji elementu
    if update == nil or update then
        self:emit_signal( "widget::resized" )
        self:emit_signal( "widget::updated" )
    end

    return self
end

-- =================================================================================================
-- Skalowanie obrazka do podanej w funkcji "fit" wysokości i szerokości.
-- 
-- @param value  Włączenie skalowania obrazka.
-- @param update Wysyłanie sygnału aktualizacji kontrolki.
--
-- @return Obiekt kontrolki obrazka.
-- =================================================================================================

function image:set_stretch( value, update )
    self._stretch = value
    
    -- wyślij sygnał aktualizacji elementu
    if update == nil or update then
        self:emit_signal( "widget::resized" )
        self:emit_signal( "widget::updated" )
    end

    return self
end

-- =================================================================================================
-- Zmienia obrazek wyświetlany w kontrolce.
-- 
-- @param img    Ścieżka do obrazka.
-- @param update Wysyłanie sygnału aktualizacji kontrolki.
--
-- @return Obiekt kontrolki obrazka.
-- =================================================================================================

function image:set_image( img, update )
    local img = img

    -- ściezka do obrazka - załaduj obrazek
    if type(img) == "string" then
        local success, result = pcall( surface.load, img )
        
        if not success then
            error( "Error while reading '" .. img .. "': " .. result )
            return
        end
        img = result
    end
    -- załaduj obiekt "surface"
    img = surface.load( img )

    -- błąd podczas ładowania?
    if img == nil then
        self._image_dim = { 0, 0 }
        self._scale_dim = { 0, 0 }
        self._image = nil
        
        return
    end

    -- zapisz wymiary obrazka
    self._image_dim = { img.width, img.height }
    self._scale_dim = { img.width, img.height }
    self._image     = img

    -- wyślij sygnał aktualizacji elementu
    if update == nil or update then
        self:emit_signal( "widget::resized" )
        self:emit_signal( "widget::updated" )
    end

    return self
end

-- =================================================================================================
-- Przyleganie obrazka do wybranej krawędz obszaru kontrolki.
-- Wszystkie możliwośći wypisane są w vars.image_halign i vars.image_valign. 
--
-- @param vert  Przyleganie w pionie.
-- @param horiz Przyleganie w poziomie.
--
-- @return Obiekt kontrolki obrazka.
-- =================================================================================================

function image:set_align( vert, horiz, update )
    -- przyleganie poziome
    if horiz ~= nil then
        self._halign = visual.halign_type[horiz] or 2
    end
    -- przyleganie pionowe
    if vert ~= nil then
        self._valign = visual.valign_type[vert] or 2
    end

    -- wyślij sygnał aktualizacji elementu
    if update == nil or update then
        -- do zmiany przylegania nie potrzeba odświeżania rozmiaru kontrolki
        self:emit_signal( "widget::updated" )
    end

    return self
end

-- =================================================================================================
-- Tworzenie metadanych obiektu.
-- =================================================================================================

image.mt = {}

function image.mt:__call(...)
    return new(...)
end

return setmetatable( image, image.mt )
