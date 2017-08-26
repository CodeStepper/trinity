-- ==========================================================================================
-- ZMIENNE
-- ==========================================================================================

-- This is used later as the default terminal and editor to run.
terminal   = "terminator"
editor     = "nano"
editor_cmd = terminal .. " -x " .. editor
editor_gui = "mousepad"
my_theme   = "default"
home_dir   = os.getenv("HOME")
theme_dir  = home_dir .. "/.config/awesome/themes/" .. my_theme .. "/"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- ==========================================================================================
-- BIBLIOTEKI
-- ==========================================================================================

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")

-- Widget and layout library
local wibox = require("wibox")

-- Theme handling library
local beautiful = require("beautiful")

-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget

local trinity = require("trinity")
local vars    = require("trinity.Variables")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
        naughty.notify({ preset = naughty.config.presets.critical,
                                         title = "Oops, there were errors during startup!",
                                         text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
        local in_error = false
        awesome.connect_signal("debug::error", function (err)
                -- Make sure we don't go into an endless error loop
                if in_error then return end
                in_error = true

                naughty.notify({ preset = naughty.config.presets.critical,
                                                 title = "Oops, an error happened!",
                                                 text = tostring(err) })
                in_error = false
        end)
end
-- }}}

-- Themes define colours, icons, font and wallpapers.
beautiful.init( theme_dir .. "theme.lua" )

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init( theme_dir .. "theme.lua" )

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
        awful.layout.suit.floating,
        awful.layout.suit.tile,
        awful.layout.suit.tile.left,
        awful.layout.suit.tile.bottom,
        awful.layout.suit.tile.top,
        awful.layout.suit.fair,
        awful.layout.suit.fair.horizontal,
        awful.layout.suit.spiral,
        awful.layout.suit.spiral.dwindle,
        awful.layout.suit.max,
        awful.layout.suit.max.fullscreen,
        awful.layout.suit.magnifier,
        -- awful.layout.suit.corner.nw,
        -- awful.layout.suit.corner.ne,
        -- awful.layout.suit.corner.sw,
        -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
        local instance = nil

        return function ()
                if instance and instance.wibox.visible then
                        instance:hide()
                        instance = nil
                else
                        instance = awful.menu.clients({ theme = { width = 250 } })
                end
        end
end
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
     { "hotkeys", function() return false, hotkeys_popup.show_help end},
     { "manual", terminal .. " -e man awesome" },
     { "edit config", editor_cmd .. " " .. awesome.conffile },
     { "edit theme", editor_gui .. " " .. theme_dir .. "theme.lua" },
     { "restart", awesome.restart },
     { "quit", function() awesome.quit() end}
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                                                        { "open terminal", terminal }
                                                                    }
                                                })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                                                         menu = mymainmenu })
-- mylauncher = trinity.button({
--     background = beautiful.widget_color.launcher,
--     image      = beautiful.widget_icon.launcher,
--     worker     = trinity.launcher,
--     menu       = mymainmenu,
--     margin     = { 4, 0, 2, 0, 0 }
-- })


-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
                                        awful.button({ }, 1, function(t) t:view_only() end),
                                        awful.button({ modkey }, 1, function(t)
                                                                                            if client.focus then
                                                                                                    client.focus:move_to_tag(t)
                                                                                            end
                                                                                    end),
                                        awful.button({ }, 3, awful.tag.viewtoggle),
                                        awful.button({ modkey }, 3, function(t)
                                                                                            if client.focus then
                                                                                                    client.focus:toggle_tag(t)
                                                                                            end
                                                                                    end),
                                        awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                                        awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                                )

local tasklist_buttons = awful.util.table.join(
                                         awful.button({ }, 1, function (c)
                                                                                            if c == client.focus then
                                                                                                    c.minimized = true
                                                                                            else
                                                                                                    -- Without this, the following
                                                                                                    -- :isvisible() makes no sense
                                                                                                    c.minimized = false
                                                                                                    if not c:isvisible() and c.first_tag then
                                                                                                            c.first_tag:view_only()
                                                                                                    end
                                                                                                    -- This will also un-minimize
                                                                                                    -- the client, if needed
                                                                                                    client.focus = c
                                                                                                    c:raise()
                                                                                            end
                                                                                    end),
                                         awful.button({ }, 3, client_menu_toggle_fn()),
                                         awful.button({ }, 4, function ()
                                                                                            awful.client.focus.byidx(1)
                                                                                    end),
                                         awful.button({ }, 5, function ()
                                                                                            awful.client.focus.byidx(-1)
                                                                                    end))

local function set_wallpaper(s)
        -- Wallpaper
        if beautiful.wallpaper then
                local wallpaper = beautiful.wallpaper
                -- If wallpaper is a function, call it with the screen
                if type(wallpaper) == "function" then
                        wallpaper = wallpaper(s)
                end
                gears.wallpaper.maximized(wallpaper, s, true)
        end
end

-- dostępne tagi (w tym przypadku dla każdego pulpitu)
tags = {
        names = {
                "term",
                "www",
                "gcc",
                "dir",
                "graf",
                "inne"
        },
        layout = {
                awful.layout.layouts[1],
                awful.layout.layouts[1],
                awful.layout.layouts[1],
                awful.layout.layouts[1],
                awful.layout.layouts[1],
                awful.layout.layouts[1]
        },
        images = nil
}

-- odśwież tapetę gdy zmienią się wymiary (np. zmiana rozdzielczości)
screen.connect_signal("property::geometry", set_wallpaper)

local topbar = {}
local widgets = {
    lays = {},
    wids = {},

    battery = {}
}

function avcxx()
            naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

function avcxx2(a)
    a:set_background("#000000")
end

-- bateria
-- widgets.battery = trinity.widget.label({
--     groups     = {"padding"},
--     groups     = {"back"},
--     padding    = {5, 0, 5, 0},
--     background = beautiful.widget_color.battery,
--     foreground = beautiful.fg_normal,
--     worker     = trinity.worker.layout,
--     margin     = { 0, 0, 5, 0, 0 },
--     battery    = "BAT0",
--     text       = false,
--     image      = true
-- })

-- przechodź po wszystkich pulpitach
awful.screen.connect_for_each_screen(function(s)

        -- tapeta
        set_wallpaper(s)

        -- tagi
        awful.tag( tags.names, s, tags.layout )

        topbar[s] = trinity.panel({
            position     = "bottom",
            screen       = s,
            height       = 30,
            border_width = 0,
            background   = "#004444",
            foreground   = "#ffffff"
        })

        widgets.lays[s] = {}

        widgets.lays[s][1] = trinity.layout.fixed({
            direction = "x",
            emiter    = { "button::press", "button::release" } 
        })
        widgets.lays[s][2] = trinity.layout.fixed({
            direction = "x"
        })
        widgets.lays[s][3] = trinity.layout.flex({
            direction = "x"
        })
        widgets.lays[s][0] = trinity.layout.fillcenter({
            direction = "x",
            left      = widgets.lays[s][1],
            center    = widgets.lays[s][3],
            right     = widgets.lays[s][2],
            emiter    = { "button::press", "button::release" }
        })

        widgets.wids[s] = {}

        -- widgets.wids[s][0] = trinity.widget.image({
        --     groups      = {"padding"},
        --     padding     = {15, 0, 15, 0},
        --     stretch     = false,
        --     keep_aspect = false,
        --     image       = beautiful.widget_icon.launcher
        -- })

        -- widgets.wids[s][0]:connect_signal("button::press", avcxx)

        widgets.wids[s][1] = trinity.widget.label({
            text       = "Drugi widżet",
            groups     = {"padding"},
            groups     = {"background"},
            padding    = {5, 0, 5, 0},
            background = "#111399"
        })
        :connect_signal("button::press", avcxx2)
        :connect_signal("button::release", avcxx)

        widgets.wids[s][2] = trinity.widget.label({
            text       = "Trzeci widżet",
            background = "#425349"
        })

        widgets.wids[s][3] = trinity.widget.label({
            text       = "Pierwszy widżet",
            groups     = {"background"},
            background = "#011349"
        })
        widgets.wids[s][4] = trinity.widget.label({
            text    = "Drugi widżet",
            groups  = {"background"},
            back_color = "#111399"
        })
        widgets.wids[s][5] = trinity.widget.label({
            text    = "Trzeci widżet",
            groups  = {"background"},
            back_color = "#425349"
        })

        widgets.wids[s][6] = trinity.widget.label({
            text       = "Pierwszy widżet",
            groups     = {"background"},
            background = "#011349",
            halign     = "Right",
            valign     = "Bottom"
        })

        trinity.Useful.create_font_description("Font8DJV", {
            family = "DejaVu Sans",
            size = 8
        })

        widgets.wids[s][7] = trinity.widget.label({
            text       = "Drugi widżet",
            groups     = {"background", "border"},
            back_color = "#111399",
            halign     = "Center",
            valign     = "Center",
            border_size = 5,
            border_color = "#ff0000",
            font       = trinity.Useful.get_font_description("Font8DJV")
        })

        widgets.wids[s][8] = trinity.widget.label({
            text       = "Trzeci widżet",
            groups     = {"background"},
            background = "#425349",
            halign     = "Left",
            valign     = "Top"
        })

        widgets.wids[s][9] = trinity.widget.arrow({
            bind_left  = widgets.wids[s][1],
            bind_right = widgets.wids[s][2],
            direction  = "right",
            emiter     = {"button::press", "button::release"}
        })

        widgets.lays[s][1]--:add( widgets.wids[s][0], true )
                          :add( widgets.wids[s][1], true )
                          :add( widgets.wids[s][9], true )
                          :add( widgets.wids[s][2] )

        widgets.lays[s][2]:add( widgets.wids[s][3] )
                          :add( widgets.wids[s][4] )
                          :add( widgets.wids[s][5] )

        widgets.lays[s][3]:add( widgets.wids[s][6] )
                          :add( widgets.wids[s][7] )
                          :add( widgets.wids[s][8] )
                          -- :add( widgets.battery )

        topbar[s]:set_widget( widgets.lays[s][0] )

        s.prompt = trinity.widget.prompt({
                background   = "#483C70",
                foreground   = "#D0D0D0",
                border_color = "#261F3D",
                border_size  = 1,
                min_width    = 170,
                max_width    = 248,
                posx         = 0,
                posy         = 18,
                padding      = 7,
                elem_space   = 3,
                cursor_color = "#D0D0D0"
        })

        -- Create a promptbox for each screen
        s.mypromptbox = awful.widget.prompt()
        -- Create an imagebox widget which will contains an icon indicating which layout we're using.
        -- We need one layoutbox per screen.
        s.mylayoutbox = awful.widget.layoutbox(s)
        s.mylayoutbox:buttons(awful.util.table.join(
                                                     awful.button({ }, 1, function () awful.layout.inc( 1) end),
                                                     awful.button({ }, 3, function () awful.layout.inc(-1) end),
                                                     awful.button({ }, 4, function () awful.layout.inc( 1) end),
                                                     awful.button({ }, 5, function () awful.layout.inc(-1) end)))
        -- Create a taglist widget
        s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

        -- Create a tasklist widget
        s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

        -- Create the wibox
        s.mywibox = awful.wibar({ position = "top", screen = s })

        -- Add widgets to the wibox
        s.mywibox:setup {
                layout = wibox.layout.align.horizontal,
                { -- Left widgets
                        layout = wibox.layout.fixed.horizontal,
                        mylauncher,
                        s.mytaglist,
                        s.mypromptbox,
                },
                s.mytasklist, -- Middle widget
                { -- Right widgets
                        layout = wibox.layout.fixed.horizontal,
                        mykeyboardlayout,
                        wibox.widget.systray(),
                        mytextclock,
                        s.mylayoutbox,
                },
        }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
        awful.button({ }, 3, function () mymainmenu:toggle() end),
        awful.button({ }, 4, awful.tag.viewnext),
        awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- funkcje do zarządzania głosem
local function raise_volume()
        awful.util.spawn( "amixer set Master 5%+", false )
        -- widgets.sound.worker.update( widgets.sound )
end
local function lower_volume()
        awful.util.spawn( "amixer set Master 5%-", false )
        -- widgets.sound.worker.update( widgets.sound )
end
local function mute_volume()
        awful.util.spawn( "amixer set Master toggle", false )
        -- widgets.sound.worker.update( widgets.sound )
end

-- {{{ Key bindings
globalkeys = awful.util.table.join(
        
        -- skróty dla dźwięku
        awful.key({}, "XF86AudioRaiseVolume", raise_volume, {description="increase volume", group="audio"}),
        awful.key({}, "XF86AudioLowerVolume", lower_volume, {description="decrease volume", group="audio"}),
        awful.key({}, "XF86AudioMute",        mute_volume,  {description="mute volume",     group="audio"}),


        awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
                            {description="show help", group="awesome"}),
        awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
                            {description = "view previous", group = "tag"}),
        awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
                            {description = "view next", group = "tag"}),
        awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
                            {description = "go back", group = "tag"}),

        awful.key({ modkey,           }, "j",
                function ()
                        awful.client.focus.byidx( 1)
                end,
                {description = "focus next by index", group = "client"}
        ),
        awful.key({ modkey,           }, "k",
                function ()
                        awful.client.focus.byidx(-1)
                end,
                {description = "focus previous by index", group = "client"}
        ),
        awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
                            {description = "show main menu", group = "awesome"}),

        -- Layout manipulation
        awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
                            {description = "swap with next client by index", group = "client"}),
        awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
                            {description = "swap with previous client by index", group = "client"}),
        awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
                            {description = "focus the next screen", group = "screen"}),
        awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
                            {description = "focus the previous screen", group = "screen"}),
        awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
                            {description = "jump to urgent client", group = "client"}),
        awful.key({ modkey,           }, "Tab",
                function ()
                        awful.client.focus.history.previous()
                        if client.focus then
                                client.focus:raise()
                        end
                end,
                {description = "go back", group = "client"}),

        -- Standard program
        awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
                            {description = "open a terminal", group = "launcher"}),
        awful.key({ modkey, "Control" }, "r", awesome.restart,
                            {description = "reload awesome", group = "awesome"}),
        awful.key({ modkey, "Shift"   }, "q", awesome.quit,
                            {description = "quit awesome", group = "awesome"}),

        awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
                            {description = "increase master width factor", group = "layout"}),
        awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
                            {description = "decrease master width factor", group = "layout"}),
        awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
                            {description = "increase the number of master clients", group = "layout"}),
        awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
                            {description = "decrease the number of master clients", group = "layout"}),
        awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
                            {description = "increase the number of columns", group = "layout"}),
        awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
                            {description = "decrease the number of columns", group = "layout"}),
        awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
                            {description = "select next", group = "layout"}),
        awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
                            {description = "select previous", group = "layout"}),

        awful.key({ modkey, "Control" }, "n",
                            function ()
                                    local c = awful.client.restore()
                                    -- Focus restored client
                                    if c then
                                            client.focus = c
                                            c:raise()
                                    end
                            end,
                            {description = "restore minimized", group = "client"}),

        -- Prompt
        awful.key({ modkey },            "r",     function ()
                        -- awful.screen.focused().mypromptbox:run()
                        awful.screen.focused().prompt:run()
                end,
                    {description = "run prompt", group = "launcher"}),

        awful.key({ modkey }, "x",
                            function ()
                                    awful.prompt.run {
                                        prompt       = "Run Lua code: ",
                                        textbox      = awful.screen.focused().mypromptbox.widget,
                                        exe_callback = awful.util.eval,
                                        history_path = awful.util.get_cache_dir() .. "/history_eval"
                                    }
                            end,
                            {description = "lua execute prompt", group = "awesome"}),
        -- Menubar
        awful.key({ modkey }, "p", function() menubar.show() end,
                            {description = "show the menubar", group = "launcher"})
)

clientkeys = awful.util.table.join(
        awful.key({ modkey,           }, "f",
                function (c)
                        c.fullscreen = not c.fullscreen
                        c:raise()
                end,
                {description = "toggle fullscreen", group = "client"}),
        awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
                            {description = "close", group = "client"}),
        awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
                            {description = "toggle floating", group = "client"}),
        awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
                            {description = "move to master", group = "client"}),
        awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
                            {description = "move to screen", group = "client"}),
        awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
                            {description = "toggle keep on top", group = "client"}),
        awful.key({ modkey,           }, "n",
                function (c)
                        -- The client currently has the input focus, so it cannot be
                        -- minimized, since minimized clients can't have the focus.
                        c.minimized = true
                end ,
                {description = "minimize", group = "client"}),
        awful.key({ modkey,           }, "m",
                function (c)
                        c.maximized = not c.maximized
                        c:raise()
                end ,
                {description = "maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
        globalkeys = awful.util.table.join(globalkeys,
                -- View tag only.
                awful.key({ modkey }, "#" .. i + 9,
                                    function ()
                                                local screen = awful.screen.focused()
                                                local tag = screen.tags[i]
                                                if tag then
                                                     tag:view_only()
                                                end
                                    end,
                                    {description = "view tag #"..i, group = "tag"}),
                -- Toggle tag display.
                awful.key({ modkey, "Control" }, "#" .. i + 9,
                                    function ()
                                            local screen = awful.screen.focused()
                                            local tag = screen.tags[i]
                                            if tag then
                                                 awful.tag.viewtoggle(tag)
                                            end
                                    end,
                                    {description = "toggle tag #" .. i, group = "tag"}),
                -- Move client to tag.
                awful.key({ modkey, "Shift" }, "#" .. i + 9,
                                    function ()
                                            if client.focus then
                                                    local tag = client.focus.screen.tags[i]
                                                    if tag then
                                                            client.focus:move_to_tag(tag)
                                                    end
                                         end
                                    end,
                                    {description = "move focused client to tag #"..i, group = "tag"}),
                -- Toggle tag on focused client.
                awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                                    function ()
                                            if client.focus then
                                                    local tag = client.focus.screen.tags[i]
                                                    if tag then
                                                            client.focus:toggle_tag(tag)
                                                    end
                                            end
                                    end,
                                    {description = "toggle focused client on tag #" .. i, group = "tag"})
        )
end

clientbuttons = awful.util.table.join(
        awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
        awful.button({ modkey }, 1, awful.mouse.client.move),
        awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
        -- All clients will match this rule.
        { rule = { },
            properties = { border_width = beautiful.border_width,
                                         border_color = beautiful.border_normal,
                                         focus = awful.client.focus.filter,
                                         raise = true,
                                         keys = clientkeys,
                                         buttons = clientbuttons,
                                         screen = awful.screen.preferred,
                                         placement = awful.placement.no_overlap+awful.placement.no_offscreen
         }
        },

        -- Floating clients.
        { rule_any = {
                instance = {
                    "DTA",  -- Firefox addon DownThemAll.
                    "copyq",  -- Includes session name in class.
                },
                class = {
                    "Arandr",
                    "Gpick",
                    "Kruler",
                    "MessageWin",  -- kalarm.
                    "Sxiv",
                    "Wpa_gui",
                    "pinentry",
                    "veromix",
                    "xtightvncviewer"},

                name = {
                    "Event Tester",  -- xev.
                },
                role = {
                    "AlarmWindow",  -- Thunderbird's calendar.
                    "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
                }
            }, properties = { floating = true }},

        -- Add titlebars to normal clients and dialogs
        { rule_any = {type = { "normal", "dialog" }
            }, properties = { titlebars_enabled = false }
        },

        -- Set Firefox to always map on the tag named "2" on screen 1.
        -- { rule = { class = "Firefox" },
        --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- if not awesome.startup then awful.client.setslave(c) end

        if awesome.startup and
            not c.size_hints.user_position
            and not c.size_hints.program_position then
                -- Prevent clients from being unreachable after screen count changes.
                awful.placement.no_offscreen(c)
        end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                        client.focus = c
                        c:raise()
                        awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                        client.focus = c
                        c:raise()
                        awful.mouse.client.resize(c)
                end)
        )

        awful.titlebar(c) : setup {
                { -- Left
                        awful.titlebar.widget.iconwidget(c),
                        buttons = buttons,
                        layout  = wibox.layout.fixed.horizontal
                },
                { -- Middle
                        { -- Title
                                align  = "center",
                                widget = awful.titlebar.widget.titlewidget(c)
                        },
                        buttons = buttons,
                        layout  = wibox.layout.flex.horizontal
                },
                { -- Right
                        awful.titlebar.widget.floatingbutton (c),
                        awful.titlebar.widget.maximizedbutton(c),
                        awful.titlebar.widget.stickybutton   (c),
                        awful.titlebar.widget.ontopbutton    (c),
                        awful.titlebar.widget.closebutton    (c),
                        layout = wibox.layout.fixed.horizontal()
                },
                layout = wibox.layout.align.horizontal
        }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
                and awful.client.focus.filter(c) then
                client.focus = c
        end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}