-- vim: fdm=marker fml=1
-- Standard awesome library
local awful = require("awful")
awful.remote = require("awful.remote")
awful.autofocus = require("awful.autofocus")
awful.rules = require("awful.rules")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty   = require("naughty")
local gears = require("gears")
local scratch = require("scratch")
local s_widgets = require("widgets")

--local keydoc = require("keydoc")
local wibox = require("wibox")

local vicious  = require("vicious")

-- shifty - dynamic tagging library
local shifty = require("shifty")

local localopts = require("localopts")

--local lain = require("lain")

-- useful for debugging, marks the beginning of rc.lua exec
print("Entered rc.lua: " .. os.time())

-- Load Debian menu entries
-- require("debian.menu")




-- {{{ shifty.config configuration
shifty.config.tags = { -- {{{
--  media = {
--      layout      = awful.layout.suit.tile,
--      mwfact      = 0.65,
--      ncols       = 2,
--      init        = true,
--  },
--  netw = {
--      layout      = awful.layout.suit.tile,
--      mwfact      = 0.65,
--      ncols       = 2,
--      init        = true,
--  },
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

-- skrewz@20160304: using a different approach:
--shifty.config.tags = shifty.load_saved_tag_names();
shifty.restore_saved_tag_names();

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
    mwfact = 0.33,
    persist = true,
    floatBars = true,
    guess_name = true,
    guess_position = false,
}
-- }}}


-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/skrewzawesometheme/theme.lua")

--beautiful.init("/usr/share/awesome/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.
local terminal = "urxvt"
local editor = os.getenv("EDITOR") or "editor"
local editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"

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
local layouts =
{
    --awful.layout.suit.tile,
    --awful.layout.suit.tile.left,
    awful.layout.suit.tile,
    --awful.layout.suit.tile.bottom,
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
--local tags = {}
-- for s = 1, screen.count() do
--    -- Each screen has its own tag table.
--    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
-- end
--tags[1] = awful.tag({ '1 (media)', '2 (mail)', 3, 4, 5, 6, 7, '8 (dump)', 9 }, 1, layouts[1])
--tags[1] = awful.tag({ }, 1, layouts[1])
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
local myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

local mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    --{ "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

--mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
--                                     menu = mymainmenu })
-- }}}

-- lain widgets {{{
--[[
lain_cpu_widget = lain.widget.cpu({
    settings = function()
        widget:set_markup("Cpu " .. cpu_now.usage)
    end
})
-- https://github.com/copycat-killer/lain/wiki/bat :
lain_bat_widget = lain.widget.bat(
)
--]]
-- }}}

-- {{{ helper wibox widgets
local spacer_widget =  wibox.widget.textbox()
spacer_widget.text = ''
-- }}}


-- Textual memory output:
local vicious_memwidget = wibox.widget.textbox ()
vicious.register(vicious_memwidget, vicious.widgets.mem, "😊 $1 ☹ $5",5)

-- cpu utilization graph:
local vicious_cpuwidget = wibox.widget.graph()
vicious_cpuwidget:set_background_color("#000000")
vicious_cpuwidget:set_height(10)
vicious_cpuwidget:set_color({
  type = "linear",
  from = { 0, 0 },
  to = { 0, 10 },
  stops = { { 0, "#ff0000" },  { 1, "#000000" } }
})
vicious.register(vicious_cpuwidget, vicious.widgets.cpu, "$1", 1.0)



-- {{{ Wibox'es:
-- Create a textclock widget
local my_home_textclock = wibox.widget.textclock("%a  %H:%M:%S\n%Y-%m-%d",10,"Australia/Sydney")
local my_cph_textclock = wibox.widget.textclock("CPH %a %H:%M",1,"Europe/Copenhagen")
--local my_us_textclock   = wibox.widget.textclock("CA %a %H:%M",1,"America/Los_Angeles")

-- Create a wibox for each screen and add it
local mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function (t) client.focus:move_to_tag(t) end),

                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )

-- cf. http://stackoverflow.com/a/31299971
local awful_widget_common = require("awful.widget.common")
local function list_update(w, buttons, label, data, objects)
    -- call default widget drawing function
    awful_widget_common.list_update(w, buttons, label, data, objects)
    -- set widget size
    w:set_max_widget_size(16)
end

awful.screen.connect_for_each_screen(function(s)
    -- Create a promptbox for each screen
    --skrewz@20170207: s.mypromptbox = awful.widget.prompt()
    s.mypromptbox = wibox.widget.textbox()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    --s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    s.mytaglist = awful.widget.taglist(
      s,
      awful.widget.taglist.filter.all,
      mytaglist.buttons,
      nil,
      list_update,
      wibox.layout.flex.vertical()
      )
      --base_widget=wibox.layout.fixed.horizontal}

    -- Create a tasklist widget
    --s.mytasklist = awful.widget.tasklist(function(c)
    --                                          return awful.widget.tasklist.label.currenttags(c, s)
    --                                      end, mytasklist.buttons)

    --s.my_left_wibox = awful.wibox({ position = "left", screen = s, width = "64"})
    -- Widgets that are aligned up and down
    --local leftbar_layout = wibox.layout.fixed.vertical()
    --leftbar_layout:add(s.mytaglist)
    --s.my_left_wibox.widgets = {
    --  {
    --    spacer_widget,
    --    s.mytaglist,
    --    spacer_widget,
    --    layout = awful.widget.layout.horizontal.leftright
    --  }
    --}
    --awful.wibox.align(s.my_left_wibox,'center')
    -- Create the wibox
    s.mywibox = awful.wibar({ position = "left", screen = s, width = "100" })
    --s.my_bottomwibox = awful.wibox({ position = "bottom", screen = s, height = "32" })
    -- Add widgets to the wibox - order matters

    -- Widgets that are aligned to the left
    local top_layout = wibox.layout.fixed.vertical()
    --top_layout:add(mylauncher)
    --top_layout:add(lain_cpu_widget)
    --top_layout:add(lain_bat_widget)
    top_layout:add(vicious_memwidget)
    top_layout:add(s_widgets.net_widget_stack)
    top_layout:add(s_widgets.rtt_widget_stack)
    top_layout:add(s_widgets.cpufreq_widget_stack)
    top_layout:add(vicious_cpuwidget)
    top_layout:add(s.mytaglist)

    -- Widgets that are aligned to the right
    local bottom_layout = wibox.layout.fixed.vertical()
    bottom_layout:add(s.mypromptbox)
    --if s == 1 then bottom_layout:add(wibox.widget.systray()) end
    bottom_layout:add(wibox.widget.systray())
    --bottom_layout:add(memwidget)
    --bottom_layout:add(batwidget)
    --bottom_layout:add(my_us_textclock)
    bottom_layout:add(my_cph_textclock)
    bottom_layout:add(my_home_textclock)
    -- skrewz@20160207: This currently is a bit big:
    --bottom_layout:add(s.mylayoutbox)

    -- http://awesome.naquadah.org/doc/api/modules/wibox.layout.align.html :
    -- Returns a new vertical align layout. An align layout can display up to
    -- three widgets. The widget set via :set_top() is top-aligned.
    -- :set_bottom() sets a widget which will be bottom-aligned. The remaining
    -- space between those two will be given to the widget set via :set_middle().
    local layout = wibox.layout.align.vertical()
    layout:set_top(top_layout)
    layout:set_middle(s.mytasklist)
    layout:set_bottom(bottom_layout)

    s.mywibox:set_widget(layout)
end
)
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

local function generate_tag_layout_info ()
  local t = awful.screen.focused().selected_tag
  return "Now: \n\n" ..
    "layout      " .. awful.layout.getname(awful.layout.get(awful.screen.focused())) .. "\n" ..
    "mwfact      " .. t.master_width_factor .. "\n" ..
    "mwnmaster   " .. t.master_count .. "\n" ..
    "ncol        " .. t.column_count
end

-- {{{ Key bindings
-- Go to http://awesome.naquadah.org/doc/api/index.html for a bit of documentation.
local globalkeys = awful.util.table.join(
    --keydoc.group("layout manipulation"),
    --awful.key({ modkey,           }, "Left",   awful.tag.viewprev),
    --awful.key({ modkey,           }, "Right",  awful.tag.viewnext),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),
    -- keydoc.group("awesome keys"),
    awful.key({ modkey,           }, "b",     function ()
      awful.tag.incmwfact(-0.05)
      naughty.notify({ title = "Decreased:  master width factor", text = generate_tag_layout_info() , timeout = 1 })
    end),
    awful.key({ modkey,           }, "m",     function ()
      awful.tag.incmwfact( 0.05)
      naughty.notify({ title = "Increased: master width factor", text = generate_tag_layout_info(), timeout = 1 })
    end),
    awful.key({ modkey, "Shift"   }, "b",     function ()
      awful.tag.incnmaster(-1)
      naughty.notify({ title = "Decreased: number of master windows", text = generate_tag_layout_info(), timeout = 1 })
    end),
    awful.key({ modkey, "Shift"   }, "m",     function ()
      awful.tag.incnmaster(1)
      naughty.notify({ title = "Increased: number of master windows", text = generate_tag_layout_info(), timeout = 1 })
    end),
    awful.key({ modkey, "Control" }, "b",     function ()
      awful.tag.incncol(-1)
      naughty.notify({ title = "Decreased: number of column windows", text = generate_tag_layout_info(), timeout = 1 })
    end),
    awful.key({ modkey, "Control" }, "m",     function ()
      awful.tag.incncol(1)
      naughty.notify({ title = "Increased: number of column windows", text = generate_tag_layout_info(), timeout = 1 })
    end),
    awful.key({ modkey,           }, "space", function ()
      awful.layout.inc(layouts,  1)
      naughty.notify({ title = "Changed layout", text = generate_tag_layout_info(), timeout = 1 })
    end),
    -- Directional focus with right hand of dvorak layout:
    --keydoc.group("directional focus keymaps"),
    awful.key({ modkey,           }, "h",
        function ()
            awful.client.focus.bydirection('left')
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "t",
        function ()
            awful.client.focus.bydirection('down')
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "n",
        function ()
            awful.client.focus.bydirection('up')
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "s",
        function ()
            awful.client.focus.bydirection('right')
            if client.focus then client.focus:raise() end
        end),

    --keydoc.group("scratch controls"),
    -- awful.key({ modkey,           }, "q", function () scratch.pad.toggle() end),
    -- awful.key({ modkey,           }, "q", function () scratch.drop("urxvt","top", "center",1, 0.40, true, 1) end),


    -- Shifty: keybindings specific to shifty
    --keydoc.group("tag interaction"),
    awful.key({modkey, "Shift"},   "c", shifty.del),
    awful.key({modkey, "Shift"},   "g", shifty.send_prev),
    awful.key({modkey, "Shift"},   "l", shifty.send_next),
    awful.key({modkey},            "g", awful.tag.viewprev),
    awful.key({modkey},            "l", awful.tag.viewnext),
    awful.key({modkey, "Control"}, "g", shifty.shift_prev),
    awful.key({modkey, "Control"}, "l", shifty.shift_next),
    awful.key({modkey           }, "r", shifty.search_tag_interactive),

    awful.key({modkey, "Control"}, ",",
              function()
                  local t = awful.tag.selected()
                  local s = awful.util.cycle(screen.count(), t.screen + 1)
                  awful.tag.history.restore()
                  t = shifty.tagtoscr(s, t)
                  t:view_only()
              end),
    awful.key({modkey},          "p", shifty.rename),
    awful.key({modkey},          ".", shifty.add),
    awful.key({modkey, "Shift"}, ".", function()
        shifty.add({name = '━━━━━━━━━━━━━━━'})
    end),




    --keydoc.group("client interactions"),
    -- skrewz@20160206: hardly ever use these:
    --awful.key({ modkey, "Shift"   }, "h", function () awful.client.swap.byidx(  1) end),
    --awful.key({ modkey, "Shift"   }, "s", function () awful.client.swap.byidx( -1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),

    --keydoc.group("special keys"),
    awful.key({                   }, "KP_End", function ()
      awful.spawn(".config/awesome/support_scripts/s-screensaver-wrap --lock-now")
    end),
    awful.key({ modkey            }, "KP_End", function () awful.spawn("xtrlock") end),
    -- These bindings do it for my standard-layout keyboard with multimedia keys.
    --awful.key({                   }, "#121", function () awful.spawn("amixer set Master mute") end,"enable mute"),
    awful.key({                   }, "#121", function ()
      awful.spawn(".config/awesome/support_scripts/skrewz-volume.sh --mute")
    end),
    awful.key({                   }, "#122", function ()
      awful.spawn(".config/awesome/support_scripts/skrewz-volume.sh --decrease")
    end),
    awful.key({                   }, "#123", function ()
      awful.spawn(".config/awesome/support_scripts/skrewz-volume.sh --increase")
    end),
    awful.key({                   }, "#232", function ()
      awful.spawn("xbacklight -dec 10")
      end),
    awful.key({                   }, "#233", function ()
      awful.spawn("xbacklight -inc 10")
      end),
    awful.key({                   }, "XF86AudioPlay",    function ()
      awful.spawn(".config/awesome/support_scripts/s-audio-control --play")
      end),
    awful.key({                   }, "XF86AudioPause",   function ()
      awful.spawn(".config/awesome/support_scripts/s-audio-control --pause")
      end),
    awful.key({                   }, "XF86AudioNext",    function ()
      awful.spawn(".config/awesome/support_scripts/s-audio-control --next")
      end),
    awful.key({                   }, "XF86AudioPrev",    function ()
      awful.spawn(".config/awesome/support_scripts/s-audio-control --prev")
      end),
    awful.key({                   }, "XF86AudioRewind",  function ()
      awful.spawn(".config/awesome/support_scripts/s-audio-control --rewind")
      end),
    awful.key({                   }, "XF86AudioForward", function ()
      awful.spawn(".config/awesome/support_scripts/s-audio-control --forward")
      end),
    awful.key({ modkey,           }, "F7",   function ()
      awful.spawn(".config/awesome/support_scripts/s-screenshot-capture")
    end),
    awful.key({ modkey, "Shift"   }, "F7",   function ()
      awful.spawn(".config/awesome/support_scripts/s-screenshot-capture --block")
    end),
    awful.key({ modkey,           }, "F5", function ()
      awful.spawn(".config/awesome/support_scripts/s-wifi-control --re-setup-on-osd")
    end),
    awful.key({ modkey,           }, "F12", function ()
      awful.spawn(".config/awesome/support_scripts/s-screen-setup")
    end),

    awful.key({ modkey, "Ctrl"    },  "a", function ()
      awful.screen.focused().selected_tag.screen = localopts.left_screen
    end),
    awful.key({ modkey, "Ctrl"    },  "o", function ()
      awful.screen.focused().selected_tag.screen = localopts.middle_screen
    end),
    awful.key({ modkey, "Ctrl"    },  "e", function ()
      awful.screen.focused().selected_tag.screen = localopts.right_screen
    end),

    awful.key({ modkey            },  "a", function ()
      awful.screen.focus(localopts.left_screen)
      if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey            },  "o", function ()
      awful.screen.focus(localopts.middle_screen)
      if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey            },  "e", function ()
      awful.screen.focus(localopts.right_screen)
      if client.focus then client.focus:raise() end
    end),

    -- Standard program
    --keydoc.group("spawn commands"),
    awful.key({ modkey,           }, "q", function ()
      scratch.drop(".config/awesome/support_scripts/s-scratch-left","center", "left",0.5, 0.80, true,1)
    end),
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end),
    awful.key({ modkey,           }, "BackSpace", function ()
      awful.spawn(".config/awesome/support_scripts/skrewz-spawn-browser.sh")
    end),
    awful.key({ modkey, "Shift"   }, "BackSpace", function ()
      awful.spawn(".config/awesome/support_scripts/skrewz-spawn-browser.sh --non-private")
    end),
    awful.key({ modkey, "Control" }, "r", awesome.restart)
    -- awful.key({ modkey, "Shift"   }, "q", awesome.quit), -- Don't want this. :S


    -- Prompt
    --awful.key({ modkey },            "r",     function ()
    --  mypromptbox[mouse.screen]:run()
    --end),

    --awful.key({ modkey }, "x",
    --          function ()
    --              awful.prompt.run({ prompt = "Run Lua code: " },
    --              mypromptbox[mouse.screen].widget,
    --              awful.util.eval, nil,
    --              awful.util.getdir("cache") .. "/history_eval")
    --          end,"prompt and run lua code")

)

local clientkeys = awful.util.table.join(
    --keydoc.group("further client interactions"),
    awful.key({ modkey,           }, "c",      function (c) c:kill()                         end,"kill client"),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle),
    -- awful.key({ modkey, "Shift"   }, "Return", awful.client.setmaster),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "w",      function (c)
      naughty.notify({ title = "Window ID", text = "Client: "..
      "class = " .. c.class .. "\n" ..
      "name = " .. c.name .. "\n" ..
      "window id = " .. c.window .. "\n" ..
      "type = " .. tostring(c.type) .. "\n" ..
      "instance = " .. tostring(c.instance) .. "\n" ..
      ".", timeout = 10 })
    end),
    awful.key({ modkey, "Shift" }, "a", function (c) awful.client.movetoscreen(c,localopts.left_screen) end),
    awful.key({ modkey, "Shift" }, "o", function (c) awful.client.movetoscreen(c,localopts.middle_screen) end),
    awful.key({ modkey, "Shift" }, "e", function (c) awful.client.movetoscreen(c,localopts.right_screen) end),
    awful.key({ modkey, "Shift"   }, "w", function (c)
      -- Attempt at getting initial sizing for this one too:
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
      naughty.notify({
	title = "Omni+mini+sticky",
	text = "For this client: " .. tostring(c.sticky) .. ".",
	timeout = 2
      })
    end),
    --awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "f", function (c)
        c.maximized = not c.maximized
	c:raise()
    end)
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

--globalkeys = awful.util.table.join(globalkeys,keydoc.group("screen manipulation"))
-- https://awesomewm.org/doc/api/classes/screen.html screen.geometry might be useful for this:
--


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
--globalkeys = awful.util.table.join(globalkeys,keydoc.group("extra tag manipulation"))
-- }}}

-- mouse binds for clients {{{
local clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
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
client.connect_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
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

client.connect_signal("focus", function(c)
  c.border_color = beautiful.border_focus
  -- skrewz@20160207: debugging where the initial frame color goes:
  --naughty.notify({ title = "Window ID", text = "focus hook: "..  " = " .. c.class .. "\n" .. "window id = " .. c.window .. "\n" .. "border color: " ..c.border_color })

end)
client.connect_signal("unfocus", function(c)
  c.border_color = beautiful.border_normal
  -- skrewz@20160207: debugging where the initial frame color goes:
  --naughty.notify({ title = "Window ID", text = "unfocus hook: "..  " = " .. c.class .. "\n" .. "window id = " .. c.window .. "\n" .. "border color: " ..c.border_color })
end)
-- }}}

-- End

print("Exited rc.lua: " .. os.time())
