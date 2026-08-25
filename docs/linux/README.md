# Installation steps

## Linux & Windows

In case of dual-booting install Windows first.
It will create an `EFI` partition.
During Arch installation mount it as `/efi` and use `reFind` boot manager.

## Partitioning

- Partition table: `gpt`
- 2 partitions
  - (if not dual-booting) create EFI system partition as `/boot` - 512Mb
  - `/ (root)` - rest
- use `systemd-boot` boot manager

## Install Arch

- to make terminal font larger type `setfont ter-132b`
- locale en_GB.UTF-8 cause week starts from Monday not from Sunday like in en_US.UTF-8 (but generate both locales, just in case)
- `systemd-logind` is configured automatically to kill user processes on logout
  and suspend when the power key is pressed
- in /etc/pacman.conf
  - enable multilib
  - enable color output
  - enable parallel downloads (5)
- add kernel parameters: mitigations=off random.trust_cpu=on

- create/configure Swapfile if needed
- `vm.swappiness=10` is configured and applied automatically

- NetworkManager manages networking and DNS; do not run a standalone dnsmasq service
- `fstrim.timer`, `systemd-timesyncd.service`, and `NetworkManager.service` are
  enabled automatically
- if laptop, install tlp and enable service - good preferences by default

- install & configure sudo
- create user, set password

```
# useradd -m -G wheel,video -s /bin/zsh <username>
# passwd <username>
```

- Workstation hosts install Terminus and use `ter-124n` as the Linux console font.
  Other `/etc/vconsole.conf` settings remain unmanaged.

## Install basic cli and configs

- Bootstrap a fresh installation with `base-devel`, `git`, `chezmoi`, `zsh`,
  and an AUR helper (`yay`) before applying the dotfiles.
- Standard CLI, shell, editor, development, filesystem, and desktop application
  packages are installed automatically for hosts with the `workstation`
  feature.
- use usb drive to copy ssh config & certificates, fix permissions:

```
$ chmod 700 ~/.ssh
$ chmod 600 ~/.ssh/key
```

- clone accel-os from github
- `chezmoi init --source="$HOME/accel-os/dotfiles" --destination="$HOME"`
- `chezmoi apply` (run with `--dry-run` first on a fresh host)
- switch user to zsh `chsh -s /bin/zsh`

## GUI

- install video drivers
- Radeon: install mesa, lib32-mesa, vulkan-radeon, lib32-vulkan-radeon
- radeontop - to monitor radeon graphics card
- intel-gpu-tools - to monitor intel graphics card
- Sway hosts install and configure greetd automatically. Autologin is disabled
  unless enabled explicitly for the host in `dotfiles/.chezmoidata/hosts.yaml`;
  `mbTPLin` preserves its current autologin behavior.

## Environment

Packages required by the tracked Sway session, user services, and `mb-*`
desktop helpers are installed automatically from
`dotfiles/.chezmoidata/packages.yaml`. Keep that manifest as the source of truth
instead of duplicating its package inventory here.

Notable configured behavior:

- Host capabilities are declared in `dotfiles/.chezmoidata/hosts.yaml`.
  Package installation, service enablement, and hardware-specific configuration
  are derived from each host's feature list. Undeclared hosts receive only the
  baseline Arch packages and services. Removing a feature disables its managed
  services and removes its managed configuration, but does not uninstall its
  packages.
- `cliphist`, `darkman`, `kanshi`, `mako`, `swayidle`, `swayosd`, and
  `wlsunset` are started by `sway-session.target`.
- `$mod+i` opens clipboard history; `Ctrl+T` switches between history and
  templates.
- Clipboard templates are regular files in
  `~/.config/mb-clipboard/templates/`.
- The configured terminal backend is installed with the Sway package group;
  change both `~/bin/xterm` and the package manifest when switching backends.
- System services declared in `dotfiles/.chezmoidata/services.yaml` are enabled
  and started automatically after package installation.
- TLP is the sole system power manager. `tlp-pd` exposes the standard
  PowerProfiles D-Bus API used by Waybar while retaining TLP's automatic
  AC/battery profiles and hardware controls. Do not install
  `power-profiles-daemon` alongside it because the services conflict.
- Per-host battery charge thresholds are configured in
  `dotfiles/.chezmoidata/tlp.yaml`. Opted-in hosts install the settings as
  `/etc/tlp.d/01-accel-os.conf`; hosts without settings remove that managed
  drop-in.
- Repo-managed Node commands run directly from their TypeScript sources through
  wrappers installed in `~/bin`. The wrappers use `fnm` and the repository's
  `.node-version`; Chezmoi installs that runtime during host setup.
- Run `mb-doctor` after applying Chezmoi to verify required packages, service
  states, managed system configuration, and repo-managed command wrappers. The
  command is read-only; repair reported drift with `chezmoi apply`.

Manual and hardware-specific setup:

- Verify the configured power manager after bootstrapping a host:

  ```
  $ tlp-stat -s
  $ tlpctl get
  ```

- gnome-keyring, seahorse - GUI for storing & unlocking SSH keys
  - To automatically unlock gnome-keyring on login, edit `/etc/pam.d/greetd`:
  - Add `auth optional pam_gnome_keyring.so` at the end of the `auth` section
  - Add `session optional pam_gnome_keyring.so auto_start` at the end of the `session` section
  - For git/ssh integration enable the gcr-ssh-agent <https://wiki.archlinux.org/title/GNOME/Keyring>

- interception-tools and interception-caps2esc are installed and configured
  automatically to bind CapsLock to Escape when pressed and Control when held.

- BlueZ, its command-line and TUI administration tools, `bluetooth.service`,
  and the `mpris-proxy` user service are installed and enabled automatically.

- Browser screen sharing uses `xdg-desktop-portal-wlr`.
  - enable `chrome://flags/#enable-webrtc-pipewire-capturer`

Optional desktop tools not installed automatically:

- `wev`, `wtype`, `xorg-xhost`
- `nm-connection-editor`, `networkmanager-openvpn`, `libnma-gtk4`
- `kooha`, `android-file-transfer`, `systemctl-tui`
- `ttf-dejavu`, `gnome-themes-extra`, `adwaita-qt5`, `papirus-icon-theme`
- `ttc-iosevka`, `ttf-iosevka-nerd`, `ttf-iosevkaterm-nerd`

<!-- * nordic - dark GTK3 theme -->
<!-- * ttf-jetbrains-mono - JetBrains Mono font -->
<!-- * ttf-droid - Droid font -->
<!-- * ttf-fira-mono - Fira Mono font -->

- run `rustup default stable`
- for backlight, add user to video group; https://wiki.archlinux.org/index.php/Backlight#ACPI

## Apps

Standard open-source workstation applications are installed automatically from
`dotfiles/.chezmoidata/packages.yaml`.

Manual application setup:

- Firefox: install the tracked preferences from `firefox/` for the local profile,
  then tweak Cookie Auto Delete settings.
- Thunderbird: add accounts and configure it to synchronize only the latest 30
  days.
- EasyEffects: enable the auto-gain plugin for volume normalization.
- Proprietary applications such as Spotify, Slack, Skype, and Google Chrome are
  not installed automatically.

## Dev tools

- Development packages are installed automatically for hosts with the
  `workstation` feature.
- Install `git-spr` manually:
  <https://github.com/ejoffe/spr>
- Install npm-only language servers needed by Emacs:

  ```
  $ npm i -g vscode-langservers-extracted eslint-language-server@2.4.4
  ```

- Configure Docker for rootless operation after its packages are installed.

## Configure hardware acceleration

- video acceleration
  - libva-utils for `vainfo`
  - vdpauinfo
  - VA-API support: libva-mesa-driver, lib32-libva-mesa-driver
  - VDPAU support: mesa-vdpau, lib32-mesa-vdpau
- Gstreamer support - gstreamer-vaapi
- tweak video acceleration settings in firefox config

# Fingerprint scanner

- install fprintd
- add these lines to `/etc/pam.d/{system-local-login,swaylock,sudo,su}`

```
# the first line is only needed for swaylock, to be able to auth with password
auth            sufficient      pam_unix.so try_first_pass likeauth nullok
auth            sufficient      pam_fprintd.so
```

# Firmware update service

- fwupd and its graphical interface are installed automatically, and the
  metadata refresh timer is enabled

## Hibernation

- create swapfile
- add `resume` and `resume_offset` kernel parameters
- add `resume` hook into `/etc/mkinitcpio.conf` and run `# mkinitcpio -P`

## Printing

- CUPS, Avahi, and `nss-mdns` are installed automatically for hosts with the
  `printing` feature.
- NetworkManager owns unicast DNS and `/etc/resolv.conf`; Avahi owns mDNS and
  DNS-SD. The managed `hosts` entry in `/etc/nsswitch.conf` routes `.local`
  lookups through Avahi, while `systemd-resolved` remains disabled to keep
  resolver ownership unambiguous.

## Tips

- configure max login attempts and login block time in `/etc/security/faillock.conf` [more info](https://wiki.archlinux.org/title/security#Lock_out_user_after_three_failed_login_attempts)