#!/usr/bin/env bash

sed -i --follow-symlinks 's/include=.*-theme\.ini/include=~\/.config\/fuzzel\/light-theme.ini/' ~/.config/fuzzel/fuzzel.ini
