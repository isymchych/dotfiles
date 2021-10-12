# Installation steps

## Linux & Windows
In case of dual-booting install Windows first.
It will create an `EFI` partition.
During Arch installation mount it as `/efi` and use `reFind` boot manager.

## Partitioning
* Partition table: `gpt`
* 2 partitions
  * (if not dual-booting) create EFI system partition as `/boot`  - 512Mb
  * `/ (root)` - rest
* use `systemd-boot` boot manager

## Install Arch
* locale en_GB.UTF-8 cause week starts from Monday not from Sunday like in en_US.UTF-8 (but generate both locales, just in case)
* in /etc/systemd/logind.conf
  * set KillUserProcesses=yes to kill user processes on logout
  * set HandlePowerKey=suspend
  * set HandleLidSwitch=lock
* in /etc/pacman.conf
  * enable multilib
  * enable color output
* add kernel parameters: mitigations=off random.trust_cpu=on

* create/configure Swapfile if needed
* set vm.swappiness=10

* if SSD install util-linux; enable fstrim.timer
* start/enable systemd-timesyncd
* install networkmanager, enable/start NetworkManager.service
* install dnsmasq, enable/start it
* if laptop, install tlp and enable service

* install & configure sudo
* create user, set password
```
# useradd -m -G wheel,video -s /bin/zsh <username>
# passwd <username>
```

## Install basic cli and configs
* install pacman -S --needed base-devel git go vim just
* install yay
* install openssh, stow, rustup, sccache, lld
* install zsh, zsh-completions, starship, ttf-nerd-fonts-symbols-extra, powerline-fonts
* install udisks2 to mount usb drives
* htop
* zip
* man-db
* tmux
* tree
* ntfs-3g
* upower
* downgrade - allows to downgrade packages
* reflector - rate pacman mirrors
* hunspell, en_GB
* use usb drive to copy ssh config & certificates, fix permissions:
```
$ chmod 700 ~/.ssh
$ chmod 600 ~/.ssh/key
```
* clone dotfiles from github
* stow zsh & git; switch user to zsh
* stow vim, cd dotfiles/vim; ./install.sh
* mkdir ~/.local/share/applications ~/.cargo
* stow linux, utils, kdiff3, emacs, newsboat
* install pipewire pipewire-pulse

## GUI
* install video drivers
 * Radeon: install mesa, lib32-mesa, vulkan-radeon, lib32-vulkan-radeon
 * radeontop - to monitor radeon graphics card
 * intel-gpu-tools - to monitor intel graphics card
* install greetd
 * enable `greetd.service`
 * copy dotfiles/linux/run-sway.sh into /usr/local/bin/
 * Update `/etc/greetd/config.toml`: `command = "agreety --cmd run-sway.sh"`
 * `systemctl edit greetd` and change service type to `idle` to prevent systemd logs overwriting login prompt

## Environment
* sway, ttf-dejavu
* swaylock
* swayidle
* waybar, otf-font-awesome
* xorg-xwayland
* kanshi - automatically switch display configurations
* wl-clipboard - cli tools for interacting with clipboard
* clipman - clipboard manager
* mako - notification daemon
* wev - monitor keypresses, like xev
* libnotify
* light - to control backlight
* gnome-keyring, seahorse - GUI for storing & unlocking SSH keys
  * To automatically unlock gnome-keyring on login, edit `/etc/pam.d/greetd`:
  * Add `auth optional pam_gnome_keyring.so` at the end of the `auth` section
  * Add `session optional pam_gnome_keyring.so auto_start` at the end of the `session` section
* polkit-gnome - allow apps to ask for root password if needed
* xorg-xrdb
* xorg-xhost
* wmname
* alacritty - terminal
* safeeyes - break reminder
* wlsunset - adjust display color temperature at night
* udiskie - automounter for removable media
* network-manager-applet - network manager applet
* nm-connection-editor, networkmanager-openvpn - network manager ui
* pavucontrol - pulseaudio utils
* wofi - command runner
* gsimplecal - calendar
* grim - capture the screenshot
* slurp - select the part of the screen
* wf-recorder - record the screen
* swappy - simple drawing on top of images
* nnn - file manager
* translate-shell - Google Translate
* mate-calc - calculator
* easyeffects - enable "auto gain" plugin, for volume normalisation

* nordic - dark GTK3 theme
* adwaita (gtk default) - light GTK3 theme
* papirus-icon-theme - icon theme
* xcursor-simpleandsoft - cursor theme
* ttf-jetbrains-mono - JetBrains Mono font
* ttf-droid - Droid font
* ttf-fira-mono - Fira Mono font
* noto-fonts, noto-fonts-emoji, noto-fonts-extra, noto-fonts-cjk - Noto fonts

* if bluetooth
 * install bluez bluez-utils
 * start and enable bluetooth service
 * install blueman - bluetooth manager GUI

* trash-cli
* libsecret
* xdg-utils
* imagemagick
* xdg-desktop-portal-wlr - for screensharing
  * enable pipewire user service
  * enable chrome://flags/#enable-webrtc-pipewire-capturer

* run `rustup default stable`
* clone typed-v and install mb-binutils
* for backlight, add user to video group; https://wiki.archlinux.org/index.php/Backlight#ACPI

## Apps
* Firefox
  * install config from dotfiles
  * tweak settings of Cookie Auto Delete
* Thunderbird
  * add accounts
  * configure to synchronise only latest 30 days
* Chromium
* transmission-gtk
* telegram-desktop
* newsboat - rss reader
* file-roller - archive manager
* gparted
* wdisplays-git - display configuration GUI
* zathura, zathura-pdf-mupdf - pdf viewer
* mpv - video player
* imv - image viewer
* youtube-dl - download videos from video hosting services

* slack
* skype
* google chrome


## Dev tools
* emacs, aspell, aspell-en
* ripgrep - search in files
* jq - filter json
* fd - better "find"
* tokei - count lines of code
* kdiff3
* watchexec - run commands on file change
* cargo-outdated
* cargo-release - helpers for release management
* rust-analyzer
* Node.js
* npm
* yarn
* editorconfig-core-c
* install yarn global typescript typescript-language-server
* android-tools, android-udev


## Configure hardware acceleration
* video acceleration
  * libva-utils for `vainfo`
  * vdpauinfo
  * VA-API support: libva-mesa-driver, lib32-libva-mesa-driver
  * VDPAU support: mesa-vdpau, lib32-mesa-vdpau
* Gstreamer support - gstreamer-vaapi
* tweak video acceleration settings in firefox config

## Hibernation
* create swapfile
* add `resume` and `resume_offset` kernel parameters
* add `resume` hook into `/etc/mkinitcpio.conf` and run `# mkinitcpio -P`
