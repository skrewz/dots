-- use these to control local changes to awesome configuration


-- Control which keybinds send clients where, etc.
--
-- (Modkey+{a,o,e} (Dvorak binds) should handle "naturally" so that
-- left-middle-right is preserved. RandR however seems to place screen numbers
-- somewhat arbitrary, so this allows for local changes.)
--
-- Please do tell if there's a more stable way to do this.

local module = {}
module.left_screen         = 3
module.middle_screen       = 2
module.right_screen        = 1

module.wifi_interface      = 'wlp2s0'

return module
