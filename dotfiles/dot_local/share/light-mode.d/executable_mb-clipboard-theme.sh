#!/usr/bin/env bash

sed -i --follow-symlinks 's/include=.*-theme\.ini/include=~\/.config\/mb-clipboard\/light-theme.ini/' ~/.config/mb-clipboard/fuzzel.ini
