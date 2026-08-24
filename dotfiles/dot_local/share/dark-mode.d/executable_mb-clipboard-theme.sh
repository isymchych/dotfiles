#!/usr/bin/env bash

sed -i --follow-symlinks 's/include=.*-theme\.ini/include=~\/.config\/mb-clipboard\/dark-theme.ini/' ~/.config/mb-clipboard/fuzzel.ini
