#!/bin/bash

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
run nm-applet
run variety
run picom -b
# run picom --experimental-backends
# run picom --experimental-backends --config $HOME/.config/picom/picom.conf
# run picom
#run caffeine
# run pamac-tray
# run xfce4-power-manager
run blueberry-tray
# run numlockx on
# run volumeicon
#run nitrogen --restore
# run conky -c $HOME/.config/awesome/system-overview
#you can set wallpapers in themes as well
# feh --bg-fill /usr/share/backgrounds/archlinux/arch-wallpaper.jpg &
# feh --bg-fill /usr/share/backgrounds/arcolinux/arco-wallpaper.jpg &
#run applications from startup
#run firefox
#run atom
#run dropbox
#run insync start
#run spotify
#run ckb-next -b
#run discord
#run telegram-desktop
