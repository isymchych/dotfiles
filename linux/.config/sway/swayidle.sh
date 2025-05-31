#!/usr/bin/env bash

pkill swayidle || true

# turn off screen in 70s
# lock screen in 1 min
# lock screen before sleep and on lock hint
swayidle -d -w \
    timeout 60 'mb-lock-screen' \
    timeout 70 'swaymsg "output * dpms off"' \
    resume 'swaymsg "output * dpms on"' \
    before-sleep 'mb-lock-screen' \
    lock 'mb-lock-screen'

echo "Started swayidle"
