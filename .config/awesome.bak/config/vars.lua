local _M = {}

local awful = require'awful'

_M.layouts = {
    awful.layout.suit.max,
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    -- awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}

_M.tags = { '1', '2', '3', '4' }

local l = awful.layout.suit
_M.default_layouts = { l.max, l.max, l.max, l.max, l.max, l.max, l.max, l.max, l.max }

return _M
