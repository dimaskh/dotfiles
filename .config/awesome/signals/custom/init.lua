local awful = require'awful'

-- Run authentication agent on startup
awesome.connect_signal(
    'startup',
    function(args)
        awful.util.spawn('/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1')
    end
)
