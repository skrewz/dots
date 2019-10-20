local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local vicious = require("vicious")
local localopts = require("localopts")


local M
do
  ---------------- RTT widget ---------------------
  local rtt_graph_widget = wibox.widget.graph()
  rtt_graph_widget:set_color({
    type = "linear",
    from = { 0, 0 },
    to = { 0, 10 },
    stops = { { 0, "#ff0000" },  {0.5, "#808000"}, { 1, "#002000" } }
  })
  local rtt_text_widget = wibox.widget.textbox()
  rtt_text_widget.align = 'right'
  local rtt_widget_stack = wibox.widget {
    rtt_graph_widget,
    rtt_text_widget,
    layout = wibox.layout.stack
  }
  rtt_graph_widget:set_height(10)
  rtt_graph_widget:set_background_color("#000000")

  -- https://awesomewm.org/apidoc/libraries/awful.spawn.html
  local rttcommand = [[lua -e '
    local socket = require("socket")
    local http = require("socket.http")
    socket.http.TIMEOUT = 2

    io.stdout:setvbuf "no"
    while true do
      local before = socket.gettime()
      http.request{
        url = "http://syd1.speedtest.telstra.net",
        -- To avoid DNS lookups:
        --url = "http://176.9.241.9",
        --headers = {Host="ping.skrewz.net"},
        redirect = false,
      }
      print (string.format("%.3f",socket.gettime()-before))
      socket.sleep(3)
    end
  ']]

  awful.spawn.with_line_callback(rttcommand, {
    stdout = function(line)
      local seconds = tonumber(line)
      local ms = string.format("%d",1000*seconds)
      rtt_graph_widget:add_value(seconds,1)
      local color = "111111"
      if seconds > 0.5 then
        color = "ff0000"
      elseif seconds > 0.2 then
        color = "551111"
      end
      rtt_text_widget.markup = '<span foreground="#'..color..'" size="8000">' .. ms .. "ms</span>"
    end
  })

  ---------------- network throughput widget ---------------------

  local net_graph_widget = wibox.widget.graph()
  net_graph_widget:set_color({
    type = "linear",
    from = { 0, 0 },
    to = { 0, 10 },
    stops = { { 0, "#ffffff" }, { 0.3, "#000080" }, { 1, "#000080" } }
  })
  --local net_text_widget = wibox.widget.textbox()
  --net_text_widget.align = 'right'
  local net_widget_stack = wibox.widget {
    net_graph_widget,
    --net_text_widget,
    layout = wibox.layout.stack
  }
  net_graph_widget:set_height(10)
  net_graph_widget:set_background_color("#000000")

  -- wlan0 rate graph:
  local function report_wifi_throughput (a)
    local intf = localopts.wifi_interface
    -- Dividing through with a "realistic maximal speed"
    return 100*( a['{'..intf..' down_kb}']+a['{'..intf..' up_kb}']) /2500
  end

  vicious.register(net_graph_widget, vicious.widgets.net, function (_,a) return report_wifi_throughput(a) end, 1)

  ---------------- cpu clock widget ---------------------

  local function report_cpufreq_avg ()
    local total_mhz = 0
    local total_cores = 0
    for l in io.lines('/proc/cpuinfo') do
      if string.find(l,'cpu MHz') then
        local otherfile = io.open('/sys/devices/system/cpu/cpu'..total_cores..'/cpufreq/scaling_cur_freq')
        if otherfile ~= nil then
          local ol = otherfile:read("*a")
          io.close(otherfile)
          total_mhz = total_mhz + tonumber(ol)
        else
          total_mhz = total_mhz + tonumber(string.match(l,'%d+.%d+'))
        end
        total_cores = total_cores + 1
      end
    end
    local retval = math.floor((total_mhz / total_cores) / 1000)
    return retval
  end

  local cpufreq_graph_widget = wibox.widget.graph()
  cpufreq_graph_widget:set_height(10)
  cpufreq_graph_widget:set_background_color("#000000")
  -- implicitly this asserts that all cpu's scale equally.
  local min_freq = tonumber(io.open(
    '/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq')
    :read("*a"))/1000
  local max_freq = tonumber(io.open(
    '/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq')
    :read("*a"))/1000
  cpufreq_graph_widget.min_value = min_freq
  cpufreq_graph_widget.max_value = max_freq
  cpufreq_graph_widget:set_color({
    type = "linear",
    from = { 0, 0 },
    to = { 0, 10 },
    stops = { { 0, "#ff0000" },  {0.7, "#000050"}, { 1, "#000000" } }
  })
  local cpufreq_text_widget = wibox.widget.textbox()
  cpufreq_text_widget.align = 'right'
  local cpufreq_widget_stack = wibox.widget {
    cpufreq_graph_widget,
    cpufreq_text_widget,
    layout = wibox.layout.stack
  }

  local cpufreq_tmr
  cpufreq_tmr = gears.timer({timeout = 1.00})
  cpufreq_tmr:connect_signal("timeout", function()
    local cpufreq = report_cpufreq_avg()

    cpufreq_graph_widget:add_value(cpufreq,1)
    local color = "111111"
    cpufreq_text_widget.markup = '<span foreground="#'..color..'" size="8000">' .. cpufreq .. "MHz</span>"
  end)
  cpufreq_tmr:start()

  M = {
    rtt_widget_stack = rtt_widget_stack,
    net_widget_stack = net_widget_stack,
    cpufreq_widget_stack = cpufreq_widget_stack
  }
end
return M
