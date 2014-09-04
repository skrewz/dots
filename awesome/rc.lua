-- vim: fdm=marker fml=1
-- Standard awesome library
local awful = require("awful")
awful.autofocus = require("awful.autofocus")
awful.rules = require("awful.rules")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty   = require("naughty")

local scratch = require("scratch")

local keydoc = require("keydoc")

bashets  = require("bashets")

-- shifty - dynamic tagging library
shifty = require("shifty")

-- useful for debugging, marks the beginning of rc.lua exec
print("Entered rc.lua: " .. os.time())

-- Load Debian menu entries
require("debian.menu")




-- {{{ shifty.config configuration
shifty.config.tags = { -- {{{
    ["1"] = { position    = 1, init = false, },
    ["2"] = { position    = 2, init = false, },
    ["3"] = { position    = 3, init = false, },
    ["4"] = { position    = 4, init = false, },
    ["5"] = { position    = 5, init = false, },
    ["6"] = { position    = 6, init = false, },
    ["7"] = { position    = 7, init = false, },
    ["8"] = { position    = 8, init = false, },
    ["9"] = { position    = 9, init = false, },
    media = {
        layout      = awful.layout.suit.tile,
        mwfact      = 0.65,
        ncols       = 2,
        init        = true,
    },
    browsdump = {
        layout      = awful.layout.suit.tile,
        mwfact      = 0.65,
        ncols       = 2,
        init        = true,
    },
    netw = {
        layout      = awful.layout.suit.tile,
        mwfact      = 0.65,
        ncols       = 2,
        init        = true,
    },
--    w1 = {
--        mwfact    = 0.60,
--        init      = true,
--        screen    = 1,
--        slave     = true,
--    },
--    web = {
--        layout      = awful.layout.suit.tile.bottom,
--        mwfact      = 0.65,
--        --max_clients = 1,
--        --position    = 4,
--        spawn       = browser,
--    },
--    mail = {
--        layout    = awful.layout.suit.tile,
--        mwfact    = 0.55,
--        --spawn     = mail,
--    },
--    media = {
--        layout    = awful.layout.suit.float,
--    },
--    office = {
--        layout   = awful.layout.suit.tile,
--    },
} -- }}}

-- SHIFTY: application matching rules
-- order here matters, early rules will be applied first
-- shifty.config.apps = { -- {{{
--     {
--         match = {
--             "Navigator",
--             "Vimperator",
--             "Gran Paradiso",
--         },
--         tag = "web",
--     },
--     {
--         match = {
--             "Shredder.*",
--             "Thunderbird",
--             "mutt",
--         },
--         tag = "mail",
--     },
--     {
--         match = {
--             "pcmanfm",
--         },
--         slave = true
--     },
--     {
--         match = {
--             "OpenOffice.*",
--             "Abiword",
--             "Gnumeric",
--         },
--         tag = "office",
--     },
--     {
--         match = {
--             "Mplayer.*",
--             "Mirage",
--             "gimp",
--             "gtkpod",
--             "Ufraw",
--             "easytag",
--         },
--         tag = "media",
--         nopopup = true,
--     },
--     {
--         match = {
--             "MPlayer",
--             "Gnuplot",
--             "galculator",
--         },
--         float = true,
--     },
--     {
--         match = {
--             terminal,
--         },
--         honorsizehints = false,
--         slave = true,
--     },
--     {
--         match = {""},
--         buttons = awful.util.table.join(
--             awful.button({}, 1, function (c) client.focus = c; c:raise() end),
--             awful.button({modkey}, 1, function(c)
--                 client.focus = c
--                 c:raise()
--                 awful.mouse.client.move(c)
--                 end),
--             awful.button({modkey}, 3, awful.mouse.client.resize)
--             )
--     },
-- } -- }}}

-- SHIFTY: default tag creation rules
-- parameter description
--  * floatBars : if floating clients should always have a titlebar
--  * guess_name : should shifty try and guess tag names when creating
--                 new (unconfigured) tags?
--  * guess_position: as above, but for position parameter
--  * run : function to exec when shifty creates a new tag
--  * all other parameters (e.g. layout, mwfact) follow awesome's tag API
shifty.config.defaults = {
    layout = awful.layout.suit.tile,
    ncol = 1,
    mwfact = 0.60,
    persist = true,
    floatBars = true,
    guess_name = true,
    guess_position = true,
}
-- }}}


-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/skrewzawesometheme/theme.lua")

--beautiful.init("/usr/share/awesome/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
--layouts =
--{
--    awful.layout.suit.floating,
--    awful.layout.suit.tile,
--    awful.layout.suit.tile.left,
--    awful.layout.suit.tile.bottom,
--    awful.layout.suit.tile.top,
--    awful.layout.suit.fair,
--    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
--    awful.layout.suit.spiral.dwindle,
--    awful.layout.suit.max,
--    awful.layout.suit.max.fullscreen,
--    awful.layout.suit.magnifier
--}
layouts =
{
    --awful.layout.suit.tile,
    --awful.layout.suit.tile.left,
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    --awful.layout.suit.tile.top,
    --awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.floating
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    --awful.layout.suit.max,
    --awful.layout.suit.max.fullscreen,
    --awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
-- for s = 1, screen.count() do
--    -- Each screen has its own tag table.
--    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
-- end
--tags[1] = awful.tag({ '1 (media)', '2 (mail)', 3, 4, 5, 6, 7, '8 (dump)', 9 }, 1, layouts[1])
tags[1] = awful.tag({ }, 1, layouts[1])
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

--mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
--                                     menu = mymainmenu })
-- }}}

-- {{{ helper wibox widgets 
--3.5spacer_widget =  wibox.widget.textbox()
spacer_widget = widget({ type = "textbox"})
--3.5spacer_widget:set_text(' ')
spacer_widget.text = ''
-- }}}

-- {{{ bashets: 
-- See: http://awesome.naquadah.org/wiki/Bashets and clone https://gitorious.org/bashets

-- Scripts in here, where possible, will use a 0-100 scale:
bashets.set_script_path("~/.config/awesome/support_scripts/bashets/")

-- http://awesome.naquadah.org/wiki/Widgets_in_awesome says this is >3.5:
-- bashet_battery = wibox.widget.textbox()
--bashet_battery = widget({ type = "textbox", name = "bashet_battery" })
--bashet_battery = widget({ type = "progressbar", name = "bashet_battery" })


-- FIXME: Set up callbacks for bashets that don't neccesarily output anything
-- interesting. (battery that's full/absent, wifi that's absent), and let the
-- callback reduce the width of the bashet widget.

--bashet_battery = awful.widget.progressbar()
bashet_battery = awful.widget.graph()
bashet_battery:set_max_value(100)
bashet_battery:set_width(20)
bashet_battery:set_color('blue')
--bashet_battery:set_vertical(true)
bashets.register("battery_percentage.bashet.sh", {widget=bashet_battery, separator = ' ', update_time = 60, format='$1',})

bashet_ram = awful.widget.progressbar()
bashet_ram:set_max_value(100)
bashet_ram:set_width(2)
bashet_ram:set_color('green')
bashet_ram:set_vertical(true)
bashets.register("ram_usage_percentage.bashet.sh", {widget=bashet_ram, separator = ' ', update_time = 10, format='$1',})

--bashet_cpu = awful.widget.progressbar()
bashet_cpu = awful.widget.graph()
bashet_cpu:set_max_value(100)
bashet_cpu:set_width(20)
bashet_cpu:set_color('red')
--bashet_cpu:set_vertical(true)
bashets.register("cpu_usage_percentage.bashet.sh", {widget=bashet_cpu, separator = ' ', update_time = 2, format='$1',})

--bashet_wifi = awful.widget.progressbar()
bashet_wifi = awful.widget.graph()
bashet_wifi:set_max_value(100)
bashet_wifi:set_width(20)
bashet_wifi:set_color('darkgrey')
--bashet_wifi:set_vertical(true)
bashets.register("wifi_signal_usable_percentage.bashet.sh", {widget=bashet_wifi, separator = ' ', update_time = 6, format='$1',})

-- Needs to go after all bashet initialization:
bashets.start()
-- }}}
-- {{{ Wibox'es:
-- Create a textclock widget
mytextclock = awful.widget.textclock({},"%a, %Y-%m-%d, W%V, %H:%M:%S",1)

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
my_left_wibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),

                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    --mytasklist[s] = awful.widget.tasklist(function(c)
    --                                          return awful.widget.tasklist.label.currenttags(c, s)
    --                                      end, mytasklist.buttons)

    --my_left_wibox[s] = awful.wibox({ position = "bottom", screen = s, height = "17"})
    --my_left_wibox[s].widgets = {
    --  {
    --    spacer_widget,
    --    mytaglist[s],
    --    spacer_widget,
    --    layout = awful.widget.layout.horizontal.leftright
    --  }
    --}
    --awful.wibox.align(my_left_wibox[s],'center')
    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, height = "17" })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            --mylauncher,
            s = 1 and bashet_battery or nil,
            s = 1 and bashet_ram or nil,
            s = 1 and bashet_cpu or nil,
            spacer_widget,
            s = 1 and bashet_wifi or nil,
            spacer_widget,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        mytextclock,
        s == 1 and mysystray or nil,
        --mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}



function search_tag_interactive ()
    local theme = beautiful.get()
    local t = awful.tag.selected()
    local scr = t.screen

    -- http://awesome.naquadah.org/doc/api/modules/naughty.html <- awful.prompt.run luadoc
    awful.prompt.run({
        fg_cursor = '#ffffff', bg_cursor = '#000000', ul_cursor = "single",
        prompt = 'Tag-search: ', text = ""},
        mypromptbox[mouse.screen].widget,
        -- shifty.taglist[scr][shifty.tag2index(scr, t) * 2],
        function (name)
            if name:len() > 0 then
                local all_found = shifty.fuzzy_name2tags(name)
                if all_found then 
                    local found = all_found[1]
                    naughty.notify({ title = "Changed tag", text = "entered: \"" .. name .. "\" which yields " .. (#all_found) .. " tag(s); selected " .. found.name, timeout = 4 })
                    awful.tag.viewonly(found)
                end
            end
        end,
        shifty.completion,
        awful.util.getdir("cache") .. "/history_tags"
    )
end

-- {{{ Key bindings
-- Go to http://awesome.naquadah.org/doc/api/index.html for a bit of documentation.
globalkeys = awful.util.table.join(
    keydoc.group("layout manipulation"),
    --awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ,"view previous tag"),
    --awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ,"view previous tag"),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,"view previously selected tag"),
    awful.key({ modkey,           }, "F2", keydoc.display,"display this keydoc"),
    -- keydoc.group("awesome keys"),
    awful.key({ modkey,           }, "b",     function ()
      awful.tag.incmwfact(-0.05)
      naughty.notify({ title = "Decreased:  master width factor", text = "Now: mwfact=" .. awful.tag.getmwfact() .. ", mwnmaster=" .. awful.tag.getnmaster() .. ", ncol=" .. awful.tag.getncol(), timeout = 1 })
    end,"decrease master width factor"),
    awful.key({ modkey,           }, "m",     function ()
      awful.tag.incmwfact( 0.05)
      naughty.notify({ title = " Increased: master width factor", text = "Now: mwfact=" .. awful.tag.getmwfact() .. ", mwnmaster=" .. awful.tag.getnmaster() .. ", ncol=" .. awful.tag.getncol(), timeout = 1 })
    end,"increase master width factor"),
    awful.key({ modkey, "Shift"   }, "b",     function ()
      awful.tag.incnmaster( 1)
      naughty.notify({ title = "Increased: number of master windows", text = "Now: mwfact=" .. awful.tag.getmwfact() .. ", mwnmaster=" .. awful.tag.getnmaster() .. ", ncol=" .. awful.tag.getncol(), timeout = 1 })
    end,"increase number of master windows"),
    awful.key({ modkey, "Shift"   }, "m",     function ()
      awful.tag.incnmaster(-1)
      naughty.notify({ title = "Decreased: number of master windows", text = "Now: mwfact=" .. awful.tag.getmwfact() .. ", mwnmaster=" .. awful.tag.getnmaster() .. ", ncol=" .. awful.tag.getncol(), timeout = 1 })
    end,"decrease number of master windows"),
    awful.key({ modkey, "Control" }, "b",     function ()
      awful.tag.incncol( 1)
      naughty.notify({ title = "Increased: number of column windows", text = "Now: mwfact=" .. awful.tag.getmwfact() .. ", mwnmaster=" .. awful.tag.getnmaster() .. ", ncol=" .. awful.tag.getncol(), timeout = 1 })
    end,"increase number of column windows"),
    awful.key({ modkey, "Control" }, "m",     function ()
      awful.tag.incncol(-1)
      naughty.notify({ title = "Decreased: number of column windows", text = "Now: mwfact=" .. awful.tag.getmwfact() .. ", mwnmaster=" .. awful.tag.getnmaster() .. ", ncol=" .. awful.tag.getncol(), timeout = 1 })
    end,"decrease number of column windows"),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end,"cycle through layouts"),
    -- Directional focus with right hand of dvorak layout:
    keydoc.group("directional focus keymaps"),
    awful.key({ modkey,           }, "h",
        function ()
            awful.client.focus.bydirection('left')
            if client.focus then client.focus:raise() end
        end,"focus directionally left"),
    awful.key({ modkey,           }, "t",
        function ()
            awful.client.focus.bydirection('down')
            if client.focus then client.focus:raise() end
        end,"focus directionally down"),
    awful.key({ modkey,           }, "n",
        function ()
            awful.client.focus.bydirection('up')
            if client.focus then client.focus:raise() end
        end,"focus directionally up"),
    awful.key({ modkey,           }, "s",
        function ()
            awful.client.focus.bydirection('right')
            if client.focus then client.focus:raise() end
        end,"focus directionally right"),

    --keydoc.group("scratch controls"),
    -- awful.key({ modkey,           }, "q", function () scratch.pad.toggle() end,"toggle scratch pad"),
    -- awful.key({ modkey,           }, "q", function () scratch.drop("urxvt","top", "center",1, 0.40, true, 1) end,"toggle scratch drop-from-top"),


    -- Shifty: keybindings specific to shifty
    keydoc.group("tag interaction"),
    awful.key({modkey, "Shift"},   "c", shifty.del,"delete current tag"),
    awful.key({modkey, "Shift"},   "g", shifty.send_prev,"move client to next tag"),
    awful.key({modkey, "Shift"},   "l", shifty.send_next,"move client to previous tag"),
    awful.key({modkey},            "g", awful.tag.viewprev,"view previous tag"),
    awful.key({modkey},            "l", awful.tag.viewnext,"view next tag"),
    awful.key({modkey, "Control"}, "g", shifty.shift_prev,"exchange with previous tag"),
    awful.key({modkey, "Control"}, "l", shifty.shift_next,"exchange with next tag"),
    awful.key({modkey           }, "r", search_tag_interactive, "beta: search tagname"),

    awful.key({modkey, "Control"}, ",",
              function()
                  local t = awful.tag.selected()
                  local s = awful.util.cycle(screen.count(), t.screen + 1)
                  awful.tag.history.restore()
                  t = shifty.tagtoscr(s, t)
                  awful.tag.viewonly(t)
              end,"send tag to next screen"),
    awful.key({modkey},          ".", shifty.add,"create new tag"),
    awful.key({modkey},          "p", shifty.rename,"rename tag"),
    -- Circumvent for when you don't want your window manager in your way:
    awful.key({modkey, "Shift"}, ".", 
    function()
        shifty.add({name = 'emerg'})
    end,"create new tag called emerg"),




    keydoc.group("client interactions"),
    awful.key({ modkey, "Shift"   }, "h", function () awful.client.swap.byidx(  1) end,"rotate clients forward"),
    awful.key({ modkey, "Shift"   }, "s", function () awful.client.swap.byidx( -1) end,"rotate clients backward"),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,"jump to urgent clients"),

    keydoc.group("special keys"),
    awful.key({                   }, "#9", function () awful.util.spawn("xscreensaver-command -lock") end,"lock screen"),
    -- These bindings do it for my standard-layout keyboard with multimedia keys.
    awful.key({                   }, "#121", function () awful.util.spawn("amixer set Master mute") end,"enable mute"),
    awful.key({                   }, "#123", function () awful.util.spawn(".config/awesome/support_scripts/skrewz-volume.sh --increase") end,"increase volume"),
    awful.key({                   }, "#122", function () awful.util.spawn(".config/awesome/support_scripts/skrewz-volume.sh --decrease") end,"decrease volume"),
    awful.key({                   }, "#232", function () awful.util.spawn("xbacklight -dec 10"); end,"decrease backlight"),
    awful.key({                   }, "#233", function () awful.util.spawn("xbacklight -inc 10"); end,"increase backlight"),
    awful.key({ modkey, "Shift"   }, "F11", function () awful.util.spawn("xmodmap .config/Xmodmap.us") end,"xmodmap: us qwerty"),
    awful.key({ modkey, "Shift"   }, "F12", function () awful.util.spawn("xmodmap .config/Xmodmap.skrewzdvorak") end,"xmodmap: skrewz-dvorak"),

    -- Standard program
    keydoc.group("spawn commands"),
    awful.key({ modkey,           }, "q", function () scratch.drop(".config/awesome/support_scripts/s-scratch-left","center", "left",0.4, 0.80, true,1) end,"drop left-in scratch pad"),
    awful.key({ modkey,           }, "j", function () scratch.drop(".config/awesome/support_scripts/s-scratch-right","center", "right",0.4, 0.80, true,1) end,"drop right-in scratch pad"),
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end,"spawn terminal"),
    awful.key({ modkey,           }, "BackSpace", function () awful.util.spawn(".config/awesome/support_scripts/skrewz-spawn-browser.sh") end,"spawn browser"),
    awful.key({ modkey, "Control" }, "r", awesome.restart,"restart awesome (Xephyr?)")
    -- awful.key({ modkey, "Shift"   }, "q", awesome.quit), -- Don't want this. :S


    -- Prompt
    --awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end,"prompt for and run command"),

    --awful.key({ modkey }, "x",
    --          function ()
    --              awful.prompt.run({ prompt = "Run Lua code: " },
    --              mypromptbox[mouse.screen].widget,
    --              awful.util.eval, nil,
    --              awful.util.getdir("cache") .. "/history_eval")
    --          end,"prompt and run lua code")

)

clientkeys = awful.util.table.join(
    keydoc.group("further client interactions"),
    awful.key({ modkey,           }, "c",      function (c) c:kill()                         end,"kill client"),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,"toggle floating for client"),
    -- awful.key({ modkey, "Shift"   }, "Return", awful.client.setmaster                           ,"make client master"),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,"swap client with master"),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end,"redraw current client"),
    awful.key({ modkey,           }, "w",      function (c)
      naughty.notify({ title = "Window ID", text = "Client: "..
      "class = " .. c.class .. "\n" ..
      "name = " .. c.name .. "\n" ..
      "window id = " .. c.window .. "\n" ..
      "type = " .. tostring(c.type) .. "\n" ..
      "instance = " .. tostring(c.instance) .. "\n" ..
      ".", timeout = 10 })
    end,"toggle on-top for client"),
    awful.key({ modkey, "Shift"   }, "w", function (c) 
      -- Attempt at getting initial sizing for this one too:
      --  naughty.notify({ title = "Debug", text = "Now: size_hints=" .. c.size_hints.user_position .. ".", timeout = 2 })
      if c.sticky == true then
        c.sticky = false
        c.ontop = false
        c.size_hints_honor = false
        awful.client.floating.set(c,false)
      else
        c.sticky = true
        c.ontop = true
        c.size_hints_honor = true
        awful.client.floating.set(c,true)
      end
      naughty.notify({ title = "Omni+mini+sticky", text = "For this client: " .. tostring(c.sticky) .. ".", timeout = 2 })
    end,"minimal-omnipresent-mode for client"),
    --awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end,"minimze client"),
    awful.key({ modkey,           }, "f", function (c)
      c.maximized_horizontal = not c.maximized_horizontal
      c.maximized_vertical   = not c.maximized_vertical
    end, "toggle fullscreen for client")
)

-- }}}

-- Compute the maximum number of digit we need, limited to 9
-- keynumber = 0
-- for s = 1, screen.count() do
--    keynumber = math.min(9, math.max(#tags[s], keynumber));
-- end

--for s = 1, screen.count() do
--    globalkeys = awful.util.table.join(globalkeys,
--    -- Function keys F1-F10 correspond to this rule:
--    --awful.key({ modkey }, "#" .. s + 66, function () awful.screen.focus(s) end)
--    awful.key({ modkey }, "F" .. screen.count() + 1 - s, function () awful.screen.focus(s) end)
--    )
--end

globalkeys = awful.util.table.join(globalkeys,keydoc.group("screen manipulation"))
globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey },          "a", function ()           awful.screen.focus(1) end,"focus screen 1"))
clientkeys = awful.util.table.join(clientkeys, awful.key({ modkey, "Shift" }, "a", function (c) awful.client.movetoscreen(c,1) end,"move to screen 1"))
globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey },          "o", function ()           awful.screen.focus(2) end,"focus screen 2"))
clientkeys = awful.util.table.join(clientkeys, awful.key({ modkey, "Shift" }, "o", function (c) awful.client.movetoscreen(c,2) end,"move to screen 2"))
globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey },          "e", function ()           awful.screen.focus(3) end,"focus screen 3"))
clientkeys = awful.util.table.join(clientkeys, awful.key({ modkey, "Shift" }, "e", function (c) awful.client.movetoscreen(c,3) end,"move to screen 3"))
globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey },          "u", function ()           awful.screen.focus(4) end,"focus screen 4"))
clientkeys = awful.util.table.join(clientkeys, awful.key({ modkey, "Shift" }, "u", function (c) awful.client.movetoscreen(c,4) end,"move to screen 4"))

-- {{{ Shifty keys

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
-- for i = 1, keynumber do
--     globalkeys = awful.util.table.join(globalkeys,
--         awful.key({ modkey }, "#" .. i + 9,
--                   function ()
--                         local screen = mouse.screen
--                         if tags[screen][i] then
--                             awful.tag.viewonly(tags[screen][i])
--                         end
--                   end),
--         awful.key({ modkey, "Control" }, "#" .. i + 9,
--                   function ()
--                       local screen = mouse.screen
--                       if tags[screen][i] then
--                           awful.tag.viewtoggle(tags[screen][i])
--                       end
--                   end),
--         awful.key({ modkey, "Shift" }, "#" .. i + 9,
--                   function ()
--                       if client.focus and tags[client.focus.screen][i] then
--                           awful.client.movetotag(tags[client.focus.screen][i])
--                       end
--                   end),
--         awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
--                   function ()
--                       if client.focus and tags[client.focus.screen][i] then
--                           awful.client.toggletag(tags[client.focus.screen][i])
--                       end
--                   end))
-- end

-- Shifty: 
globalkeys = awful.util.table.join(globalkeys,keydoc.group("extra tag manipulation"))
for i=1,9 do
    globalkeys = awful.util.table.join(
                        globalkeys,
                        awful.key({modkey}, i,
                            function()
                                awful.tag.viewonly(shifty.getpos(i))
                            end))
    globalkeys = awful.util.table.join(
                        globalkeys,
                        awful.key({modkey, "Control"}, i,
                            function ()
                                local t = shifty.getpos(i)
                                t.selected = not t.selected
                            end))
    globalkeys = awful.util.table.join(globalkeys,
                                awful.key({modkey, "Control", "Shift"}, i,
                function ()
                    if client.focus then
                        awful.client.toggletag(shifty.getpos(i))
                    end
                end))
    -- move clients to other tags
    globalkeys = awful.util.table.join(
                    globalkeys,
                    awful.key({modkey, "Shift"}, i,
                        function ()
                            if client.focus then
                                local t = shifty.getpos(i)
                                awful.client.movetotag(t)
                                awful.tag.viewonly(t)
                            end
                        end))
end

for i = 1, (shifty.config.maxtags or 9) do
    globalkeys = awful.util.table.join(globalkeys,
        -- modkey + number ~~> go to numeric tag
        awful.key({modkey}, i, function()
            local t =  awful.tag.viewonly(shifty.getpos(i))
            end),
        -- modkey + control + number ~~> also show numeric tag (?)
        -- awful.key({modkey, "Control"}, i, function()
        --  local t = shifty.getpos(i)
        --  t.selected = not t.selected
        --  end),
        -- modkey + control + shift + number ~~> also show numeric tag (?)
        -- awful.key({modkey, "Control", "Shift"}, i, function()
        --    if client.focus then
        --        awful.client.toggletag(shifty.getpos(i))
        --    end
        --    end),
        -- move clients to other tags
        awful.key({modkey, "Shift"}, i, function()
            if client.focus then
                t = shifty.getpos(i)
                awful.client.movetotag(t)
                awful.tag.viewonly(t)
            end
        end))
    end

-- }}}


-- mouse binds for clients {{{
clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    --awful.button({ modkey }, 2 , function () awful.util.spawn("scripts/daily_tasks/open_iceweasel_on_pastebuffer.sh") end),
    awful.button({ modkey }, 3, awful.mouse.client.resize),
    awful.button({ modkey }, 4, function () awful.util.spawn("transset --point --min 0.1 --inc 0.02") end),
    awful.button({ modkey }, 5, function () awful.util.spawn("transset --point --min 0.1 --dec 0.05") end))
-- }}}

-- {{{ Shifty config (continued)
-- SHIFTY: initialize shifty
-- the assignment of shifty.taglist must always be after its actually
-- initialized with awful.widget.taglist.new()
shifty.taglist = mytaglist
shifty.init()


-- SHIFTY: assign client keys to shifty for use in
-- match() function(manage hook)
shifty.config.clientkeys = clientkeys
shifty.config.globalkeys = globalkeys
shifty.config.modkey = modkey


-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}


-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- End

print("Exited rc.lua: " .. os.time())
