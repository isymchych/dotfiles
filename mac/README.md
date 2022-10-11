# Setting up
* Install brew
* Fonts:
    brew tap homebrew/cask-fonts
    brew install font-noto-sans, font-jetbrains-mono-nerd-font, font-dejavu
    brew install --cask font-iosevka-nerd-font
* ITerm 2:
  * brew tap homebrew/cask-versions
  * brew install --cask iterm2-beta
  * Preferences -> General/Preferences -> Check "Load preferences from a custom folder or URL" and use dotfiles/mac/ITerm2 dir
* brew install git git-delta stow zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions starship coreutils
* Clone dotfiles
* stow vim, zsh, emacs, git, mac, tools, kdiff
* Use zsh as a shell `chsh -s /bin/zsh`
* CLI tools
    brew install aspell editorconfig fd gitui htop jq just nnn nvm ripgrep tokei wget
* kdiff3 - diff tool
    brew install --cask kdiff3
* Install Alfred
* Install Owly - prevent Mac from sleeping in 15 minutes
* LinearMouse - disable mouse acceleration
    brew install --cask linearmouse --no-quarantine
* Rectangle - windows management
    brew install --cask rectangle
* Emacs https://github.com/d12frosted/homebrew-emacs-plus
    brew tap d12frosted/emacs-plus
    brew install emacs-plus@29 --without-cocoa --with-native-comp
* optional git-credentials-manager-core - for passwordless auth
    brew tap microsoft/git
    brew cask install git-credential-manager-core
* sad - code search and replace
    brew install ms-jpq/sad/sad
* Stretchly - break time reminder
    brew install --cask stretchly
* Install Telegram

# Settings
* Trackpad -> enable "Tap to click"
* Map caps lock to escape https://vim.fandom.com/wiki/Map_caps_lock_to_escape_in_macOS
* Make ctrl-c etc work https://apple.stackexchange.com/a/170671
