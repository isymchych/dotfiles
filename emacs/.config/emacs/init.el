;;; init.el --- main emacs config file
;;; Commentary:
;; * Spacemacs https://github.com/syl20bnr/spacemacs
;; * Doom Emacs https://github.com/doomemacs/doomemacs
;; * Evil guide https://github.com/noctuid/evil-guide
;;; Code:



;; ---------------------------------------- VARS


(defvar mb-is-mac-os (eq system-type 'darwin))
(defvar mb-is-linux (eq system-type 'gnu/linux))

;; base configs dir
(defvar mb-dotfiles-dir (file-name-directory (or (buffer-file-name) load-file-name)))

(defvar mb-customizations-file (expand-file-name "custom.el" mb-dotfiles-dir))

;; dir for temp files
(defvar mb-save-path (expand-file-name "save-files/" mb-dotfiles-dir))

(defvar mb-font "iosevka term medium-12")

(defvar mb-tab-size        4)
(defvar mb-web-indent-size 2)

;; load customizations file if it exists
(load mb-customizations-file t)

;; load local settings if file exists
(load (expand-file-name "local.el" mb-dotfiles-dir) t)

;; keep packages in emacs-version-specific directories
(setq package-user-dir (expand-file-name (concat "packages/" emacs-version "/elpa") mb-dotfiles-dir))


;; ---------------------------------------- INIT



(require 'package)

;; this is needed to install use-package
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)

(setq package-enable-at-startup nil)

(package-initialize)

;; Bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

(setq use-package-verbose t)

(require 'bind-key)

;; create temp files dir if it does not exists
(unless (file-exists-p mb-save-path)
  (make-directory mb-save-path))



;; ---------------------------------------- CONFIG



;; Turn off mouse interface early in startup to avoid momentary display
(if (fboundp 'menu-bar-mode)   (menu-bar-mode   -1))
(if (fboundp 'tool-bar-mode)   (tool-bar-mode   -1))
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; Terminal mouse support
(unless window-system
  (require 'mouse)
  (xterm-mouse-mode t)
  (defun track-mouse (e)))

(setq-default
 ;; scroll one line at a time (less "jumpy" than defaults)
 mouse-wheel-scroll-amount '(2 ((shift) . 2))
 ;; don't accelerate scrolling
 mouse-wheel-progressive-speed nil
 ;; scroll window under mouse
 mouse-wheel-follow-mouse 't)


(setq-default
 frame-title-format '(buffer-file-name "%f" ("%b"))
 ;; no beep and blinking
 visible-bell       nil
 ring-bell-function 'ignore

 ;; keyboard scroll one line at a time
 scroll-step 1

 ;; display column numbers in status line
 column-number-mode t
 ;; display line numbers in status line
 line-number-mode t
 ;; max line number to show
 line-number-display-limit 999999
 ;; max line width after which you will see ??? instead of line number
 line-number-display-limit-width 999999

 ;; draw underline lower
 x-underline-at-descent-line t

 ;; Show keystrokes in progress
 echo-keystrokes 0.1

 ;; hide empty lines after buffer end
 indicate-empty-lines nil

 font-lock-maximum-decoration t
 color-theme-is-global t

 ;; Don't defer screen updates when performing operations.
 redisplay-dont-pause t

 ;; file to save customizations done through UI
 custom-file mb-customizations-file

 ;; do not break line even if its too long
 truncate-lines t
 truncate-partial-width-windows t)

(tooltip-mode -1)
(blink-cursor-mode t)

;; take the short answer, y/n is yes/no
(defalias 'yes-or-no-p 'y-or-n-p)

;; do not ask if I want to execute `eval' from dir-locals
(setq enable-local-eval t)
;; do not ask if I want to set variables from dir-locals
(setq enable-local-variables :all)

;; make urls in comments/strings clickable
(add-hook 'find-file-hooks 'goto-address-prog-mode)

;; Font
(setq font-use-system-font nil)
(setq-default default-font mb-font)
;; set font for all windows
(add-to-list 'default-frame-alist `(font . ,mb-font))

;; highlight current line
(global-hl-line-mode t)

;; Enable disabled features
(put 'downcase-region           'disabled nil)
(put 'upcase-region             'disabled nil)
(put 'narrow-to-region          'disabled nil)
(put 'dired-find-alternate-file 'disabled nil)

(setq-default
 ;; disable startup screen
 inhibit-startup-screen t
 ;; remove message from scratch
 initial-scratch-message nil
 ;; start scratch in text mode (usefull to get a faster Emacs load time
 ;; because it avoids autoloads of elisp modes)
 initial-major-mode 'text-mode

 ;; reduce the frequency of garbage collection by making it happen on
 ;; each 100MB of allocated data (the default is on every 0.76MB)
 gc-cons-threshold 100000000

 ;; Increase the amount of data which Emacs reads from the process.
 ;; default is too low 4k considering that the some of the language server responses are in 800k - 3M range.
 read-process-output-max (* 1024 1024) ;; 1mb

 ;; prevent creating backup files
 make-backup-files nil
 ;; prevent creating .save files
 auto-save-list-file-name nil
 ;; prevent auto saving
 auto-save-default nil
 create-lockfiles nil

 ;; Always rescan buffer for imenu
 imenu-auto-rescan t

 ;; Add ukrainian input method
 default-input-method "ukrainian-computer"

 ;; set default mode for unknown files
 major-mode 'text-mode

 ;; compilation mode
 compilation-scroll-output t
 compilation-ask-about-save nil
 compilation-save-buffers-predicate '(lambda () nil)

 ;; move files to trash when deleting
 delete-by-moving-to-trash t)

;; Encoding
(set-language-environment     'utf-8)
(set-default-coding-systems   'utf-8)
(setq locale-coding-system    'utf-8)
(set-terminal-coding-system   'utf-8)
(set-keyboard-coding-system   'utf-8)
(set-selection-coding-system  'utf-8)
(prefer-coding-system         'utf-8)

;; dir to save info about interrupted sessions
(setq auto-save-list-file-prefix mb-save-path)

;; Transparently open compressed files
(auto-compression-mode t)

;; Automatically update unmodified buffers whose files have changed.
(global-auto-revert-mode t)

;; Tabs: use only spaces for indent
(setq-default
 indent-tabs-mode  nil
 tab-always-indent nil

 tab-width          mb-tab-size
 c-basic-offset     mb-tab-size
 py-indent-offset   mb-tab-size)

(setq-default
 ;; Sentences do not need double spaces to end
 sentence-end-double-space nil

 ;; lines should be 80 characters wide, not 72
 fill-column 80)


;; display margins in terminal emacs
(unless (display-graphic-p)
  (setq-default
   right-margin-width 1
   left-margin-width 1))


;; make sure emacs will try to split windows horizontally by default
(setq split-height-threshold nil)
(setq split-width-threshold 160)


(setq enable-recursive-minibuffers t)

;; Do not allow the cursor in the minibuffer prompt
(setq minibuffer-prompt-properties
      '(read-only t cursor-intangible t face minibuffer-prompt))
(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)



;; ---------------------------------------- UTILS



(defun mb/prev-buffer ()
  "Switch to previous buffer."
  (interactive)
  (mode-line-other-buffer))

(defun mb/untabify-buffer ()
  "Replace tabs with spaces in buffer."
  (interactive)
  (untabify (point-min) (point-max))
  (message "mb: untabify buffer"))

(defun mb/indent-buffer ()
  "Reindent buffer."
  (interactive)
  (save-excursion
    (indent-region (point-min) (point-max) nil)))

(defun mb/cleanup-buffer ()
  "Perform a bunch of operations on the whitespace content of a buffer."
  (interactive)
  (mb/indent-buffer)
  (whitespace-cleanup)
  (message "mb: cleanup and indent buffer"))

(defun mb/rename-file-and-buffer ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (message "mb: Buffer is not visiting a file!")
      (let ((new-name (read-file-name "New name: " filename)))
        (cond
         ((vc-backend filename) (vc-rename-file filename new-name))
         (t
          (rename-file filename new-name t)
          (set-visited-file-name new-name t t)))))))

(defun mb/delete-current-buffer-file ()
  "Remove file connected to current buffer and kill buffer."
  (interactive)
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        (name (buffer-name)))
    (if (not (and filename (file-exists-p filename)))
        (ido-kill-buffer)
      (when (yes-or-no-p "Are you sure you want to remove this file? ")
        (delete-file filename)
        (kill-buffer buffer)
        (message "mb: File '%s' successfully removed" filename)))))

(defun mb/launch-application (application-name &rest args)
  "Asynchronously start application APPLICATION-NAME with ARGS.
It wouldn't be associated with the buffer."
  (interactive)
  (apply 'start-process
         (-concat (list application-name nil application-name) args))
  (message "mb: started %s %S" application-name args))

(defun mb/terminal (&rest args)
  "Launches terminal emulator with ARGS."
  (interactive)
  (if mb-is-mac-os
      (start-process "terminal" nil "osascript" "-e" (format "
   tell application \"iTerm2\"
        set newWindow to (create window with default profile)
        tell current session of newWindow
            write text \"cd %s;\"
        end tell
      end tell
" default-directory)) ;; TODO handle args

    (apply 'mb/launch-application (-concat (list (getenv "TERMINAL")) args))))

(defun mb/project-base-term (&rest args)
  "Launches terminal in project root with ARGS."
  (interactive)

  (if-let ((fboundp 'project-root)
           (proj (project-current))
           (default-directory proj))
      (apply 'mb/terminal args)
    (error "MB: buffer is not in the project")))

(defun mb/eval-and-replace ()
  "Replace the preceding sexp with its value."
  (interactive)
  (right-char)
  (backward-kill-sexp)
  (condition-case nil
      (prin1 (eval (read (current-kill 0)))
             (current-buffer))
    (error (message "Invalid expression")
           (insert (current-kill 0)))))


(defun mb/revert-buffer ()
  "Revert active buffer without asking."
  (interactive)
  (revert-buffer nil t t)
  (message (concat "Reverted buffer " (buffer-name))))


(defun mb/narrow-or-widen-dwim (p)
  "If the buffer is narrowed, it widens.  Otherwise, it narrows intelligently.
Intelligently means: region, subtree, or defun, whichever applies
first.

With prefix P, don't widen, just narrow even if buffer is already
narrowed."
  (interactive "P")
  (declare (interactive-only))
  (cond ((and (buffer-narrowed-p) (not p)) (widen))
        ((region-active-p)
         (narrow-to-region (region-beginning) (region-end)))
        ((derived-mode-p 'org-mode) (org-narrow-to-subtree))
        (t (narrow-to-defun))))

(defun mb/sort-columns ()
  "Align selected columns using `column'."
  (interactive)
  (let (beg end column-command)
    (setq column-command (if mb-is-linux "column -o \" \" -t" "column -t"))
    (if (region-active-p)
        (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (shell-command-on-region beg end column-command (current-buffer) t nil)))

(defun mb/run-command (command)
  "Save and run COMMAND in current project if defined."
  (interactive)
  (when command
    (save-buffer)
    (mb/project-base-term "-e" command "--hold")))

(defun mb/display-ansi-colors ()
  "Replace ANSI escape chars with real colors in current buffer."
  (interactive)
  (ansi-color-apply-on-region (point-min) (point-max)))

(defun mb/eslint-fix-file ()
  "Fix some issues in current file using `eslint --fix'."
  (interactive)
  (message "mb: eslint --fix this file")
  (when (buffer-modified-p)
    (save-buffer))
  (shell-command (concat "eslint --fix " (buffer-file-name)))
  ;; revert buffer to see changes in FS
  (revert-buffer t t))


(defun mb/ensure-bin-tool-exists (name)
  "Check if bin tool `NAME' exists and show warning if it doesn't."
  (if (executable-find name)
      (message "MB: found required bin tool %s" name)
    (warn "MB: executable %s not found!" name)))


;; spacemax implementation of kill-this-buffer
;; @see https://github.com/syl20bnr/spacemacs/pull/6225
(defun mb/kill-this-buffer ()
  "Kill the current buffer."
  (interactive)
  (if (window-minibuffer-p)
      (abort-recursive-edit)
    (kill-buffer (current-buffer))))

(defun mb/js-to-json ()
  "Convert JS value into JSON."
  (interactive)
  (save-excursion
    (shell-command-on-region (mark) (point) "node-transform 'x => JSON.stringify(eval(`(${x})`), null, 2)'" (buffer-name) t "*MB ERROR BUFFER*" t)))


(defvar mb-verbose-mode nil)
(defun mb/toggle-verbose-mode ()
  "Toggle line numbers and visual line wrapping."
  (interactive)

  (setq mb-verbose-mode (not mb-verbose-mode))
  (message "mb/toggle-verbose-mode: %s" mb-verbose-mode)

  (let ((arg (if mb-verbose-mode 1 0)))
    (global-display-line-numbers-mode arg)
    (global-visual-line-mode arg)
    ))



;; ---------------------------------------- GLOBAL KEYBINDINGS


(if (window-system)
    (progn
      ;; zoom in / zoom out in editor
      (global-set-key [C-mouse-4] 'text-scale-increase)
      (global-set-key [C-mouse-5] 'text-scale-decrease)

      (when mb-is-mac-os
        (global-set-key (kbd "C-<wheel-up>")   'text-scale-increase)
        (global-set-key (kbd "C-<wheel-down>") 'text-scale-decrease)))

  (progn
    ;; activate mouse-based scrolling
    (global-set-key (kbd "<mouse-4>") 'scroll-down-line)
    (global-set-key (kbd "<mouse-5>") 'scroll-up-line)))


(define-key input-decode-map [?\C-\M-i] [M-tab]) ;; make M-tab work in terminal

;; disable input methods
(global-unset-key (kbd "C-\\"))

;; prevent accidentally closed frames
(global-unset-key (kbd "C-x C-z"))

(global-set-key (kbd "C-x e")   'mb/eval-and-replace)
(global-set-key (kbd "C-x C-f") 'find-file)
(global-set-key [M-tab]         'mb/prev-buffer)
(global-set-key (kbd "M-/")     'hippie-expand)
(global-set-key (kbd "M-u")     'universal-argument)

(global-set-key [f3]    'mb/toggle-verbose-mode)
(global-set-key [f4]    'mb/terminal)
(global-set-key [M-f4]  'mb/project-base-term)
(global-set-key [f5]    'make-frame)
(global-set-key [f6]    'mb/revert-buffer)
(global-set-key [f12]   'menu-bar-mode)



;; ---------------------------------------- PLUGINS


;; Diminish: cleanup mode line
(use-package diminish
  :ensure t
  :config
  (eval-after-load 'hi-lock
    '(diminish 'hi-lock-mode)))



;; Fix PATH on Mac
(use-package exec-path-from-shell
  :ensure t

  :if mb-is-mac-os

  :config
  (exec-path-from-shell-initialize)
  ;; Use GNU ls as `gls' from `coreutils' if available.  Add `(setq
  ;; dired-use-ls-dired nil)' to your config to suppress the Dired warning when
  ;; not using GNU ls.  We must look for `gls' after `exec-path-from-shell' was
  ;; initialized to make sure that `gls' is in `exec-path'
  (let ((gls (executable-find "gls")))
    (when gls
      (setq insert-directory-program gls
            dired-listing-switches "-aBhl --group-directories-first"))))



;; Dash.el modern list library (helpers)
(use-package dash
  :ensure t
  :config (dash-enable-font-lock))



;; s.el strings manipulation library
(use-package s
  :ensure t)



;; writable grep, complementary package for other packages
(use-package wgrep
  :ensure t
  :config
  (setq wgrep-auto-save-buffer t))



(use-package mb-theme
  :no-require t

  :config

  ;; Nord theme https://github.com/arcticicestudio/nord-emacs
  (use-package nord-theme
    :disabled
    :ensure t)


  ;; Solarized theme https://github.com/bbatsov/solarized-emacs
  (use-package solarized-theme
    :disabled
    :ensure t)

  ;; Different background for "unreal" buffers (that aren't files), supported by some themes
  (use-package solaire-mode
    :ensure t
    :init
    (solaire-global-mode +1))

  ;; Doom emacs themes https://github.com/doomemacs/themes
  (use-package doom-themes
    :ensure t
    :config
    ;; Enable flashing mode-line on errors
    (doom-themes-visual-bell-config)

    ;; Corrects (and improves) org-mode's native fontification.
    (doom-themes-org-config))

  (defvar mb-light-theme 'doom-one-light)
  (defvar mb-dark-theme 'doom-one)

  ;; Auto dark mode on Linux
  (use-package mb-darkman
    :no-require t

    :if mb-is-linux

    :config
    (load "dbus")

    (defun activate-mode (mode)
      (message "MB: activate %s mode" mode)
      (if (equal mode "dark")
          (load-theme mb-dark-theme t)
        (load-theme mb-light-theme t)))

    (defun set-darkman-theme (mode)
      (message "MB: darkman mode changed to %s" mode)
      (activate-mode mode))

    (dbus-register-signal :session nil "/nl/whynothugo/darkman" "nl.whynothugo.darkman" "ModeChanged" #'set-darkman-theme)

    (activate-mode
     (if (member "nl.whynothugo.darkman" (dbus-list-names :session))
         (dbus-get-property :session "nl.whynothugo.darkman" "/nl/whynothugo/darkman" "nl.whynothugo.darkman" "Mode")
       "light")))


  ;; Auto dark mode on macOS
  (use-package auto-dark
    :ensure t

    :if mb-is-mac-os

    :init
    ;; HACK: remove the applescript support so that this package doesn't break in CLI mode
    (unless window-system
      (fmakunbound 'ns-do-applescript))

    :config
    (setq
     auto-dark--allow-osascript t
     auto-dark--dark-theme mb-dark-theme
     auto-dark--light-theme mb-light-theme)))



;; Make clipboard work on all platforms
(use-package xclip
  :ensure t
  :config
  (xclip-mode 1))



;; Undo-tree: save/show undo tree
;; also required by evil
(use-package undo-tree
  :ensure t
  :diminish undo-tree-mode
  :config
  (global-undo-tree-mode)

  (let ((history-dir (expand-file-name "undo-tree-history" mb-save-path)))
    ;; create temp dir if it does not exists
    (unless (file-exists-p history-dir)
      (make-directory history-dir))

    (setq undo-tree-history-directory-alist (list `(".*" . ,history-dir))
          undo-tree-visualizer-timestamps t
          undo-tree-visualizer-diff       t)))



;; evil uses dabbrev
(use-package dabbrev
  :config
  ;; do not split words on _ and -
  (setq dabbrev-abbrev-char-regexp "[a-zA-Z0-9?!_\-]"))



;; Hippie expand is dabbrev expand on steroids, used by evil
(use-package hippie-exp
  :config
  (setq hippie-expand-try-functions-list '(try-expand-dabbrev
                                           try-expand-dabbrev-all-buffers
                                           try-expand-dabbrev-from-kill
                                           try-complete-file-name-partially
                                           try-complete-file-name
                                           try-expand-all-abbrevs
                                           try-expand-list
                                           try-expand-line)))



;; Evil: vim mode
(use-package evil
  :ensure t
  :after undo-tree
  ;; this must be set before loading evil
  :init
  ;; use C-u as scroll-up
  (defvar evil-want-C-u-scroll t)
  (defvar evil-want-Y-yank-to-eol t)
  (defvar evil-want-C-i-jump t)
  (defvar evil-want-keybinding nil)
  (defvar evil-undo-system 'undo-tree)

  :config
  (setq
   evil-shift-width mb-tab-size
   ;; more granular undo
   evil-want-fine-undo t
   evil-flash-delay 10
   ;; Don't wait for any other keys after escape is pressed.
   evil-esc-delay 0
   ;; h/l do not wrap around to next lines
   evil-cross-lines nil
   evil-want-visual-char-semi-exclusive t
   ;; do not move cursor back 1 position when exiting insert mode
   evil-move-cursor-back nil
   ;; search for whole words not only for part
   evil-symbol-word-search 'symbol)

  ;; Exit to normal state after save
  (add-hook 'after-save-hook 'evil-normal-state)

  (cl-loop for (mode . state) in '((inferior-emacs-lisp-mode . emacs)
                                   (pylookup-mode . emacs)
                                   (comint-mode . normal)
                                   (shell-mode . insert)
                                   (term-mode . emacs)
                                   (help-mode . emacs)
                                   (grep-mode . emacs)
                                   (bc-menu-mode . emacs)
                                   (rdictcc-buffer-mode . emacs))
           do (evil-set-initial-state mode state))

  (evil-mode 1)

  ;; set leader key in all states
  (evil-set-leader nil (kbd "C-SPC"))

  ;; set leader key in normal & visual state
  (evil-set-leader '(normal visual) (kbd "SPC"))

  (add-hook 'view-mode-hook
            (lambda()
              (define-key view-mode-map (kbd "SPC") nil)))

  ;; Use escape to quit, and not as a meta-key.
  (define-key evil-normal-state-map           [escape] 'keyboard-quit)
  (define-key evil-visual-state-map           [escape] 'keyboard-quit)
  (define-key minibuffer-local-map            [escape] 'minibuffer-keyboard-quit)
  (define-key minibuffer-local-ns-map         [escape] 'minibuffer-keyboard-quit)
  (define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
  (define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
  (define-key minibuffer-local-isearch-map    [escape] 'minibuffer-keyboard-quit)

  (define-key evil-insert-state-map [escape] 'evil-normal-state)

  ;; disable man look up
  (define-key evil-motion-state-map "K" nil)
  (define-key evil-motion-state-map (kbd " ") nil)

  ;; Replace Emacs kill-ring-save with window management commands
  (global-set-key (kbd "M-w") 'evil-window-map)

  ;; insert tabs only in emacs state
  (define-key evil-emacs-state-map (kbd "TAB") #'indent-for-tab-command)
  ;; insert newline only in emacs state
  (define-key evil-emacs-state-map (kbd "RET") #'newline)

  ;; in many modes q is close/exit etc., so leave it unbound
  (define-key evil-normal-state-map "q" nil)
  (define-key evil-normal-state-map "Q" 'evil-record-macro)
  (define-key evil-window-map "q" 'evil-window-delete)

  (define-key evil-normal-state-map (kbd "M-f") 'evil-scroll-page-down)
  (define-key evil-normal-state-map (kbd "M-b") 'evil-scroll-page-up)

  (define-key evil-normal-state-map "gr" 'xref-find-references)
  (define-key evil-normal-state-map "gD" 'xref-find-definitions-other-window)

  ;; move everywhere with M-hjkl
  (global-set-key (kbd "M-j") 'evil-next-line)
  (global-set-key (kbd "M-k") 'evil-previous-line)
  (global-set-key (kbd "M-h") 'left-char)
  (global-set-key (kbd "M-l") 'right-char)

  (evil-ex-define-cmd "Q[uit]" 'evil-quit)

  ;; Overload shifts so that they don't lose the selection
  ;; @see http://superuser.com/a/789156
  (defun mb/evil-shift-left-visual ()
    (interactive)
    (evil-shift-left (region-beginning) (region-end))
    (evil-normal-state)
    (evil-visual-restore))
  (defun mb/evil-shift-right-visual ()
    (interactive)
    (evil-shift-right (region-beginning) (region-end))
    (evil-normal-state)
    (evil-visual-restore))
  (define-key evil-visual-state-map (kbd ">") 'mb/evil-shift-right-visual)
  (define-key evil-visual-state-map (kbd "<") 'mb/evil-shift-left-visual)

  ;; NOTE: m is reserved for mode-local bindings
  (evil-define-key 'normal 'global
    (kbd "<leader>2")  'call-last-kbd-macro
    (kbd "<leader>q") 'evil-quit
    (kbd "<leader>n") 'mb/narrow-or-widen-dwim
    (kbd "<leader>ff") 'find-file
    (kbd "<leader>k")  'mb/kill-this-buffer
    (kbd "<leader>s")  'save-buffer
    (kbd "<leader>e")  'eshell
    (kbd "<leader>u")  'undo-tree-visualize

    (kbd "<leader>lm") 'evil-show-marks
    (kbd "<leader>li")  'imenu
    (kbd "<leader> l <SPC>") 'just-one-space

    (kbd "<leader>bb") 'switch-to-buffer
    (kbd "<leader>bl") 'mb/cleanup-buffer
    (kbd "<leader>bd") 'mb/delete-current-buffer-file
    (kbd "<leader>br") 'mb/rename-file-and-buffer)

  (evil-define-key 'visual 'global
    (kbd "<leader>n") 'mb/narrow-or-widen-dwim
    (kbd "<leader>lt") 'mb/sort-columns))

;; integration of evil with various packages
(use-package evil-collection
  :after evil
  :ensure t
  :init
  (setq evil-collection-setup-minibuffer nil)
  (evil-collection-init))

;; match visual selection with * and #
(use-package evil-visualstar
  :after evil
  :ensure t
  :config
  (global-evil-visualstar-mode))

;; emulates surround.vim
(use-package evil-surround
  :after evil
  :ensure t
  :config (global-evil-surround-mode 1))

;; match braces/tags with %
(use-package evil-matchit
  :after evil
  :ensure t
  :config
  (global-evil-matchit-mode 1)
  (evil-add-command-properties #'evilmi-jump-items :jump t))

;; text exchange operator (select, gx, select other word, gx)
(use-package evil-exchange
  :after evil
  :ensure t
  :config (evil-exchange-install))

;; xml tag attribute as a text object (bound to x)
(use-package exato
  :after evil
  :ensure t
  :init
  (setq exato-key "a"))

;; manage comments
(use-package evil-commentary
  :after evil
  :ensure t
  :diminish evil-commentary-mode
  :config
  (evil-commentary-mode)
  (define-key evil-commentary-mode-map (kbd "M-;") 'evil-commentary-line))

;; align text into columns - gl<space> or gL<space>
(use-package evil-lion
  :ensure t
  :config
  (evil-lion-mode))


(use-package better-jumper
  :ensure t

  :init
  (global-set-key [remap evil-jump-forward]  #'better-jumper-jump-forward)
  (global-set-key [remap evil-jump-backward] #'better-jumper-jump-backward)
  (global-set-key [remap xref-pop-marker-stack] #'better-jumper-jump-backward)

  :config
  (setq better-jumper-use-evil-jump-advice t
        better-jumper-use-savehist t)

  (better-jumper-mode 1)

  ;; Creates a jump point before killing a buffer. This allows you to undo
  ;; killing a buffer easily (only works with file buffers though; it's not
  ;; possible to resurrect special buffers).
  (advice-add #'kill-current-buffer :around #'evil-better-jumper/set-jump-a)

  ;; Create a jump point before jumping with imenu.
  (advice-add #'imenu :around #'evil-better-jumper/set-jump-a))



;; Project management
(use-package project
  :init
  (setq project-list-file (expand-file-name "projects" mb-save-path))
  :config
  (push '(project-dired "Root directory") project-switch-commands)
  (evil-define-key 'normal 'global
    (kbd "<leader>pp") 'project-switch-project
    (kbd "<leader>pD") 'project-dired
    (kbd "<leader>pe") 'project-eshell
    (kbd "<leader>pk") 'project-kill-buffers))



;; Vertical completion UI (like ido)
(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  ;; Show more candidates
  (setq vertico-count 20
        ;; enable cycling for `vertico-next' and `vertico-previous'.
        vertico-cycle t)

  (add-hook 'minibuffer-setup-hook #'vertico-repeat-save)

  (setq completion-in-region-function #'consult-completion-in-region)

  (define-key vertico-map (kbd "M-j") 'vertico-next)
  (define-key vertico-map (kbd "M-k") 'vertico-previous)

  (evil-define-key 'normal 'global
    (kbd "<leader>`") 'vertico-repeat
    (kbd "<leader>jj") 'evil-avy-goto-char-timer
    (kbd "<leader>jl") 'evil-avy-goto-line))



;; Fuzzy matching algorithm
(use-package orderless
  :ensure t
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))



;; Enable rich annotations in the minibuffer
(use-package marginalia
  :ensure t
  :init
  (marginalia-mode))



;; Advanced commands in vertical completion UI
(use-package consult
  :ensure t
  :init
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  :config
  (consult-customize consult-recent-file :preview-key '([M-k] [M-j]))

  ;; make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)

  ;;  consult-outline support for eshell prompts
  (add-hook 'eshell-mode-hook (lambda () (setq outline-regexp eshell-prompt-regexp)))

  (defun consult-ripgrep-symbol-at-point (&optional dir)
    (interactive)
    (consult-ripgrep dir (thing-at-point 'symbol)))

  (evil-define-key 'normal 'global
    (kbd "<leader>r") 'consult-recent-file
    (kbd "<leader>y") 'consult-yank-from-kill-ring
    (kbd "<leader>li") 'consult-imenu
    (kbd "<leader>ll") 'consult-line
    (kbd "<leader>o") 'consult-outline
    (kbd "<leader>bb") 'consult-buffer
    (kbd "<leader>SPC") 'consult-buffer

    ;; project
    (kbd "<leader>pb") 'consult-project-buffer
    (kbd "<leader>pf") 'consult-fd
    (kbd "<leader>ps") 'consult-ripgrep
    (kbd "<leader>pS") 'consult-ripgrep-symbol-at-point))



;; https://github.com/minad/consult/wiki#find-files-using-fd
(use-package consult-fd
  :no-require t
  :after consult
  :config
  (defvar consult--fd-command nil)
  (defun consult--fd-builder (input)
    (unless consult--fd-command
      (setq consult--fd-command
            (if (eq 0 (call-process-shell-command "fdfind"))
                "fdfind"
              "fd")))
    (pcase-let* ((`(,arg . ,opts) (consult--command-split input))
                 (`(,re . ,hl) (funcall consult--regexp-compiler
                                        arg 'extended t)))
      (when re
        (list :command (append
                        (list consult--fd-command
                              "--color=never" "--full-path"
                              (consult--join-regexps re 'extended))
                        opts)
              :highlight hl))))

  (defun consult-fd (&optional dir initial)
    (interactive "P")
    (let* ((prompt-dir (consult--directory-prompt "Fd" dir))
           (default-directory (cdr prompt-dir)))
      (find-file (consult--find (car prompt-dir) #'consult--fd-builder initial))))


  (defun consult-fd-thing-at-point (&optional dir)
    (interactive)
    (consult-fd dir (thing-at-point 'filename)))

  (evil-define-key 'normal 'global
    (kbd "<leader>pf") 'consult-fd
    (kbd "<leader>pF") 'consult-fd-thing-at-point))



;; Context commands for things at a point
(use-package embark
  :ensure t

  :config
  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  (global-set-key (kbd "C-h B") 'embark-bindings-at-point)
  (global-set-key (kbd "M-.") 'embark-act)
  (define-key evil-normal-state-map (kbd "M-.") 'embark-act)

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))



(use-package embark-consult
  :ensure t
  :after (embark consult)
  :demand t ; only necessary if you have the hook below
  ;; if you want to have consult previews as you move around an
  ;; auto-updating embark collect buffer
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))



;; https://github.com/oantolin/embark/wiki/Additional-Configuration#use-which-key-like-a-key-menu-prompt
(use-package embark-which-key
  :no-require t
  :after (embark which-key)
  :config
  (defun embark-which-key-indicator ()
    "An embark indicator that displays keymaps using which-key.
The which-key help message will show the type and value of the
current target followed by an ellipsis if there are further
targets."
    (lambda (&optional keymap targets prefix)
      (if (null keymap)
          (which-key--hide-popup-ignore-command)
        (which-key--show-keymap
         (if (eq (plist-get (car targets) :type) 'embark-become)
             "Become"
           (format "Act on %s '%s'%s"
                   (plist-get (car targets) :type)
                   (embark--truncate-target (plist-get (car targets) :target))
                   (if (cdr targets) "…" "")))
         (if prefix
             (pcase (lookup-key keymap prefix 'accept-default)
               ((and (pred keymapp) km) km)
               (_ (key-binding prefix 'accept-default)))
           keymap)
         nil nil t (lambda (binding)
                     (not (string-suffix-p "-argument" (cdr binding))))))))

  (setq embark-indicators
        '(embark-which-key-indicator
          embark-highlight-indicator
          embark-isearch-highlight-indicator))

  (defun embark-hide-which-key-indicator (fn &rest args)
    "Hide the which-key indicator immediately when using the completing-read prompter."
    (which-key--hide-popup-ignore-command)
    (let ((embark-indicators
           (remq #'embark-which-key-indicator embark-indicators)))
      (apply fn args)))

  (advice-add #'embark-completing-read-prompter
              :around #'embark-hide-which-key-indicator))



;; Avy: jump to char/line
(use-package avy
  :ensure t
  :config
  (evil-define-key 'normal 'global
    (kbd "<leader>jj") 'evil-avy-goto-char-timer
    (kbd "<leader>jl") 'evil-avy-goto-line))



;; Company-mode: autocomplete
(use-package company
  :ensure t
  :diminish company-mode
  :defines
  company-dabbrev-ignore-case
  company-dabbrev-downcase
  :config
  (setq
   company-idle-delay                0.1
   company-tooltip-limit             20
   company-tooltip-align-annotations t
   company-minimum-prefix-length     2
   company-echo-delay                0
   company-selection-wrap-around     t

   company-dabbrev-ignore-case       nil
   company-dabbrev-downcase          nil

   company-require-match             nil
   company-show-quick-access         t)

  (delete 'company-xcode company-backends)
  (delete 'company-ropemacs company-backends)

  (add-hook 'evil-insert-state-exit-hook 'company-abort)

  (eval-after-load 'eldoc
    (eldoc-add-command 'company-complete-selection
                       'company-complete-common
                       'company-capf
                       'company-abort))

  (global-company-mode 1)

  (define-key company-active-map (kbd "C-w") nil)
  (define-key company-active-map (kbd "C-j") nil)

  (global-set-key (kbd "M-p") 'company-manual-begin))



;; YASnippet: snippets
(use-package yasnippet
  :ensure t
  :config
  (setq
   yas-snippet-dirs (list (expand-file-name "snippets" mb-save-path))
   yas-verbosity          2
   yas-wrap-around-region t)

  (yas-global-mode)

  ;; expand snippets with hippie expand
  (add-to-list 'hippie-expand-try-functions-list 'yas-hippie-try-expand)

  ;; Remove GUI dropdown prompt (prefer ivy/helm)
  (delq 'yas-dropdown-prompt yas-prompt-functions)

  ;; disable `yas-expand` on TAB
  (define-key yas-minor-mode-map (kbd "<tab>") nil)
  (define-key yas-minor-mode-map (kbd "TAB") nil)

  ;; free up the binding for a prefix
  (global-set-key (kbd "M-y") nil)

  (global-set-key (kbd "M-y i") 'yas-insert-snippet)
  (global-set-key (kbd "M-y e") 'yas-visit-snippet-file)
  (global-set-key (kbd "M-y n") 'yas-new-snippet))

(use-package consult-yasnippet
  :ensure t
  :config
  ;; free up the binding for a prefix
  (global-set-key (kbd "M-y") nil)

  (global-set-key (kbd "M-y i") 'consult-yasnippet)
  (global-set-key (kbd "M-y e") 'consult-yasnippet-visit-snippet-file))

(use-package yasnippet-snippets
  :after (yasnippet)
  :ensure t
  :config
  (yasnippet-snippets-initialize))



;; Flyspell-mode: spell-checking on the fly as you type
(use-package flyspell
  :ensure t
  :diminish flyspell-mode
  :init

  (when (executable-find "aspell")
    (setq ispell-program-name "aspell") ; use aspell instead of ispell
    (setq ispell-personal-dictionary (expand-file-name "aspell.en.pws" mb-dotfiles-dir))
    (setq-default ispell-extra-args '("--sug-mode=ultra"
                                      "--lang=en_GB"
                                      "--camel-case")))

  (add-hook 'text-mode-hook 'flyspell-mode)
  (add-hook 'prog-mode-hook (lambda ()
                              (setq flyspell-consider-dash-as-word-delimiter-flag t)
                              (flyspell-prog-mode)))
  :config
  (global-set-key [M-f8]  'flyspell-buffer)
  (global-set-key [f8]    'flyspell-correct-at-point))



;; Recentf: show recent files
(use-package recentf
  :config
  (setq recentf-save-file (expand-file-name "recentf" mb-save-path)
        recentf-max-menu-items 25
        recentf-max-saved-items 1000
        ;; cleanup non-existing files on startup
        ;; may have problems with remote files
        recentf-auto-cleanup 'mode)
  ;; Ignore ephemeral git commit message files
  (add-to-list 'recentf-exclude "/COMMIT_EDITMSG$")
  (add-to-list 'recentf-exclude "/elpa/")
  (add-to-list 'recentf-exclude ".recentf")

  (add-hook 'server-done-hook 'recentf-save-list)
  (add-hook 'server-visit-hook 'recentf-save-list)
  (add-hook 'delete-frame-hook 'recentf-save-list)

  (evil-set-initial-state 'recentf-mode 'normal)

  (recentf-mode t)
  (recentf-track-opened-file))



;; EditorConfig
(use-package editorconfig
  :ensure t
  :defer t
  :diminish editorconfig-mode
  :init
  (mb/ensure-bin-tool-exists "editorconfig")
  (add-hook 'prog-mode-hook 'editorconfig-mode)

  (defun mb/reload-editorconfig ( )
    "Reload editorconfig file and set variables for current major mode."
    (interactive)
    (message "mb: reloading EditorConfig...")
    (editorconfig-apply))

  (evil-define-key 'normal 'prog-mode (kbd "<leader>le") 'mb/reload-editorconfig))



;; Anzu: show current search match/total matches
(use-package anzu
  :ensure t
  :diminish anzu-mode
  :init
  (setq anzu-cons-mode-line-p nil)

  ;; from spacemacs
  (defun mb/anzu-update-mode-line (here total)
    "Custom update function which does not propertize the status.
                HERE is current position, TOTAL is total matches count."
    (when anzu--state
      (let ((status (cl-case anzu--state
                      (search (format "(%s/%d%s)"
                                      (anzu--format-here-position here total)
                                      total (if anzu--overflow-p "+" "")))
                      (replace-query (format "(%d replace)" total))
                      (replace (format "(%d/%d)" here total)))))
        status)))
  (setq anzu-mode-line-update-function 'mb/anzu-update-mode-line)
  (global-anzu-mode t))

(use-package evil-anzu
  :after (evil anzu)
  :ensure t)



;; Uniquify: unique buffer names
(use-package uniquify
  :config
  (setq uniquify-buffer-name-style 'forward
        uniquify-separator "/"
        ;; rename after killing uniquified
        uniquify-after-kill-buffer-p t
        ;; don't muck with special buffers
        uniquify-ignore-buffers-re "^\\*"))



;; Show available keybindings in a separate window
(use-package which-key
  :ensure t
  :diminish which-key-mode
  :init
  (which-key-mode)
  (evil-define-key nil 'global (kbd "<leader><escape>") 'which-key-abort))



;; IBuffer (local)
(use-package ibuffer
  :bind ([f2] . ibuffer)
  :init
  ;; use ibuffer on C-x C-b
  (defalias 'list-buffers 'ibuffer)
  ;; use ibuffer as default buffers list (:ls)
  (defalias 'buffer-menu 'ibuffer)

  :config
  (define-key ibuffer-mode-map [f2]      'ibuffer-quit))



;; Saveplace: save cursor position
(use-package saveplace
  :init
  (setq-default save-place-file (expand-file-name "saveplace" mb-save-path))

  :config
  (save-place-mode t))



;; Delete-selection mode: delete seleted text when typing
(delete-selection-mode t)



;; Subword-mode: navigate in CamelCase words
;; http://ergoemacs.org/emacs/emacs_subword-mode_superword-mode.html
(use-package subword
  :diminish subword-mode
  :init
  (global-subword-mode t)

  ;; enable subword mode CamelCase movement in evil
  (define-category ?U "Uppercase")
  (define-category ?u "Lowercase")
  (modify-category-entry (cons ?A ?Z) ?U)
  (modify-category-entry (cons ?a ?z) ?u)
  (make-variable-buffer-local 'evil-cjk-word-separating-categories)
  (add-hook 'subword-mode-hook
            '(lambda ()
               (if subword-mode
                   (push '(?u . ?U) evil-cjk-word-separating-categories)
                 (setq evil-cjk-word-separating-categories (default-value 'evil-cjk-word-separating-categories))))))



;; Electric indent mode: enable autoindent on enter etc.
(electric-indent-mode 1)



;; Electric-pair mode: auto insert closing brackets
;; skip over and delete white space if it stands between the cursor and the closing delimiter
(use-package elec-pair
  :init
  (setq electric-pair-skip-whitespace 'chomp)
  :config
  (electric-pair-mode 1)
  (defun mb/emulate-disabled-electric-pair ()
    "Disable auto-inserting parens."
    (setq-local electric-pair-pairs nil)
    (setq-local electric-pair-text-pairs nil)
    (setq-local electric-pair-inhibit-predicate #'identity))
  (add-hook 'minibuffer-setup-hook 'mb/emulate-disabled-electric-pair))



;; Eldoc
(add-hook  'emacs-lisp-mode-hook        'turn-on-eldoc-mode)
(add-hook  'lisp-interaction-mode-hook  'turn-on-eldoc-mode)
(add-hook  'ielm-mode-hook              'turn-on-eldoc-mode)
(add-hook 'eldoc-mode-hook
          (lambda() (diminish 'eldoc-mode)))



;; Dired
(use-package dired-x
  :config
  (setq dired-auto-revert-buffer t)    ; automatically revert buffer

  (evil-set-initial-state 'wdired-mode 'normal)
  (evil-define-key 'normal 'global (kbd "<leader>d") 'dired-jump)

  (defun mb/dired-up-directory ()
    "Take dired up one directory, but behave like dired-find-alternate-file."
    (interactive)
    (let ((old (current-buffer)))
      (dired-up-directory)
      (kill-buffer old)))

  (evil-define-key 'normal dired-mode-map
    " " 'evil-send-leader
    "h" 'mb/dired-up-directory
    "l" 'dired-find-alternate-file
    "o" 'dired-sort-toggle-or-edit
    "v" 'dired-toggle-marks
    "m" 'dired-mark
    "u" 'dired-unmark
    "U" 'dired-unmark-all-marks
    "n" 'evil-search-next
    "N" 'evil-search-previous
    "q" 'mb/kill-this-buffer))



;; Highlight all matches of the word under the cursor
(use-package highlight-thing
  :ensure t
  :defer t
  :diminish highlight-thing-mode
  :hook (prog-mode . highlight-thing-mode)
  :config
  (set-face-attribute 'highlight-thing nil
                      :foreground (face-foreground 'highlight)
                      :background (face-background 'highlight))
  ;; Don't highlight the thing at point itself
  (setq highlight-thing-exclude-thing-under-point t)
  (setq highlight-thing-delay-seconds 1.5))



;; Mode line
(use-package doom-modeline
  :ensure t
  :config
  (setq doom-modeline-buffer-file-name-style 'truncate-upto-project
        doom-modeline-icon nil
        doom-modeline-unicode-fallback nil
        doom-modeline-buffer-encoding nil
        doom-modeline-env-version nil)
  (doom-modeline-mode 1))



;; Flycheck: error checking on the fly
(use-package flycheck
  :ensure t
  :defer t
  :init
  (setq flycheck-indication-mode 'right-margin)
  (global-flycheck-mode)

  :config
  (evil-define-key 'normal 'global
    (kbd "M-e 1") 'flycheck-first-error
    (kbd "M-e j") 'flycheck-next-error
    (kbd "M-e M-j") 'flycheck-next-error
    (kbd "M-e k") 'flycheck-previous-error
    (kbd "M-e M-k") 'flycheck-previous-error
    (kbd "M-e l") 'mb/toggle-flyckeck-errors-list
    (kbd "M-e b") 'flycheck-buffer)

  (if (display-graphic-p)
      (setq flycheck-indication-mode 'right-fringe)
    (progn
      (setq flycheck-indication-mode 'right-margin)))

  (setq flycheck-temp-prefix "FLYCHECK_XXY")
  (setq flycheck-check-syntax-automatically '(mode-enable save))

  (evil-add-command-properties #'flycheck-first-error :jump t)
  (evil-add-command-properties #'flycheck-next-error :jump t)
  (evil-add-command-properties #'flycheck-previous-error :jump t)

  ;; from Spacemacs
  (defun mb/toggle-flyckeck-errors-list ()
    "Toggle flycheck's error list window."
    (interactive)
    (-if-let (window (flycheck-get-error-list-window))
        (quit-window nil window)
      (flycheck-list-errors)))


  ;; https://github.com/flycheck/flycheck/issues/1428#issuecomment-591320954
  (defun flycheck-node_modules-executable-find (executable)
    (or
     (let* ((base (locate-dominating-file buffer-file-name "node_modules"))
            (cmd  (if base (expand-file-name (concat "node_modules/.bin/" executable)  base))))
       (if (and cmd (file-exists-p cmd))
           cmd))
     (flycheck-default-executable-find executable)))

  (defun my-node_modules-flycheck-hook ()
    (setq-local flycheck-executable-find #'flycheck-node_modules-executable-find))

  (add-hook 'js2-mode-hook 'my-node_modules-flycheck-hook)
  (add-hook 'js-mode-hook 'my-node_modules-flycheck-hook)
  (add-hook 'web-mode-hook 'my-node_modules-flycheck-hook)
  )



;; Expand-region: expand selection like C-w in intellij idea
(use-package expand-region
  :ensure t
  :defer t
  :init
  (evil-define-key 'normal 'global (kbd "<leader>w") 'er/expand-region)
  (setq expand-region-contract-fast-key "W"
        expand-region-reset-fast-key    "r")
  :config
  (evil-add-command-properties #'er/expand-region :jump t)
  (evil-add-command-properties #'er/contract-region :jump t))



;; Show parens mode: highlight matching parens
(use-package paren
  :config
  (setq show-paren-delay 0
        ;; decrease overlay priority because
        ;; it's higher than selection
        show-paren-priority 10
        ;; highlight everything inside parens
        show-paren-style 'expression)
  (show-paren-mode 1))



;; Rainbow-mode: highlight colors in text (e.g "red" or #3332F3)
(use-package rainbow-mode
  :ensure t
  :defer t
  :diminish rainbow-mode)



;; Rainbow delimiters
(use-package rainbow-delimiters
  :ensure t
  :defer t
  :init
  (add-hook 'prog-mode-hook 'rainbow-delimiters-mode))



;; Highlight-indentation: highlight indentation columns
(use-package highlight-indentation
  :ensure t
  :defer t
  :init
  (add-hook 'ruby-mode-hook 'highlight-indentation-current-column-mode)
  (add-hook 'yaml-mode-hook 'highlight-indentation-current-column-mode)
  :config
  (set-face-background 'highlight-indentation-face (face-background 'highlight))
  (set-face-background 'highlight-indentation-current-column-face (face-background 'highlight)))



;; highlight todos
(use-package hl-todo
  :ensure t
  :defer t
  :init (add-hook 'prog-mode-hook 'hl-todo-mode))



;; Magit: UI for git
(use-package magit
  :ensure t
  :defer t
  :defines
  magit-last-seen-setup-instructions
  magit-status-buffer-switch-function
  magit-rewrite-inclusive
  magit-save-some-buffers
  magit-auto-revert-mode-lighter
  magit-push-always-verify
  magit-set-upstream-on-push

  :init
  (mb/ensure-bin-tool-exists "git")
  (evil-define-key 'normal 'global
    (kbd "<leader>gs") 'magit-status
    (kbd "<leader>gl") 'magit-log-all
    (kbd "<leader>gL") 'magit-log-buffer-file
    (kbd "<leader>gb") 'magit-blame)

  :config
  (setq vc-follow-symlinks nil

        ;; open magit status in same window as current buffer
        magit-status-buffer-switch-function 'switch-to-buffer
        ;; highlight word/letter changes in hunk diffs
        magit-diff-refine-hunk 'all
        ;; ask me if I want to include a revision when rewriting
        magit-rewrite-inclusive 'ask
        ;; ask me to save buffers
        magit-save-some-buffers t
        ;; pop the process buffer if we're taking a while to complete
        magit-process-popup-time 10
        ;; don't show " MRev" in modeline
        magit-auto-revert-mode-lighter ""
        magit-push-always-verify nil

        ;; max length of first line of commit message
        git-commit-summary-max-length 70

        ;; ask me if I want a tracking upstream
        magit-set-upstream-on-push 'askifnotset)

  (diminish 'auto-revert-mode)

  ;; make <leader> work in magit
  (define-key magit-mode-map (kbd "SPC") nil)

  (message "mb: initialized MAGIT"))



;; Git-modes: modes for .gitattributes, .gitconfig and .gitignore
(use-package git-modes
  :ensure t
  :defer t)



;; Git-diff mode
(use-package diff-mode
  :ensure t
  :defer t
  :config
  (define-key diff-mode-map (kbd "j") 'diff-hunk-next)
  (define-key diff-mode-map (kbd "k") 'diff-hunk-prev))



;; Git-timemachine: browse through file history
(use-package git-timemachine
  :ensure t
  :defer t
  :init (evil-define-key 'normal 'global (kbd "<leader>gt") 'git-timemachine)
  :config
  (evil-make-overriding-map git-timemachine-mode-map 'normal)
  ;; force update evil keymaps after git-timemachine-mode loaded
  (add-hook 'git-timemachine-mode-hook #'evil-normalize-keymaps))



;; Diff-hl: highlight changes in gutter
(use-package diff-hl
  :ensure t
  :config
  (setq diff-hl-draw-borders nil)
  (add-hook 'dired-mode-hook 'diff-hl-dired-mode)

  (evil-define-key 'normal 'global
    (kbd "<leader>gj") 'diff-hl-next-hunk
    (kbd "<leader>gk") 'diff-hl-previous-hunk
    (kbd "<leader>gr") 'diff-hl-revert-hunk
    (kbd "<leader>gd") 'diff-hl-diff-goto-hunk)

  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)

  (diff-hl-flydiff-mode)

  ;; there is no fringe in terminal emacs, so use margins
  (unless (display-graphic-p)
    (diff-hl-margin-mode))

  (global-diff-hl-mode))



;; Language server protocol
(use-package lsp-mode
  :ensure t
  :defer t
  :hook (lsp-mode . lsp-enable-which-key-integration)
  :init
  (setq lsp-session-file (expand-file-name "lsp-session-v1" mb-save-path)
        lsp-keymap-prefix "s-l"
        lsp-idle-delay 0.6
        lsp-keep-workspace-alive nil
        lsp-enable-suggest-server-download nil
        lsp-rust-analyzer-server-display-inlay-hints nil
        ;; lsp-rust-analyzer-cargo-watch-command "clippy"
        lsp-rust-server 'rust-analyzer
        lsp-rust-analyzer-proc-macro-enable t
        lsp-rust-analyzer-cargo-load-out-dirs-from-check t
        lsp-rust-build-on-save t
        lsp-enable-file-watchers nil

        lsp-enable-folding nil
        lsp-enable-snippet nil
        lsp-enable-symbol-highlighting nil
        lsp-enable-on-type-formatting  nil
        lsp-enable-indentation nil

        lsp-completion-provider :capf
        lsp-completion-show-detail t
        lsp-completion-show-kind t

        lsp-modeline-code-actions-segments '(count name)

        ;; UI https://emacs-lsp.github.io/lsp-mode/tutorials/how-to-turn-off/
        lsp-lens-enable nil

        lsp-ui-doc-enable nil

        lsp-eldoc-enable-hover nil

        lsp-headerline-breadcrumb-enable t
        lsp-headerline-breadcrumb-segments '(symbols)

        lsp-ui-sideline-enable t
        lsp-ui-sideline-show-hover t
        lsp-ui-sideline-delay 1.0
        lsp-ui-sideline-show-diagnostics nil)
  :config
  (evil-define-key 'normal 'lsp-mode-map
    (kbd "<leader>la") 'lsp-execute-code-action
    (kbd "<leader>lg") 'lsp-find-definition
    (kbd "<leader>lf") 'lsp-find-references
    (kbd "<leader>lr") 'lsp-rename))


;; Advanced UI elements for lsp-mode
(use-package lsp-ui
  :ensure t
  :commands lsp-ui-mode)



;; ---------------------------------------- LANGUAGES



;; Makefile mode

(defun mb/use-tabs ()
  "Use tabs."
  (setq tab-width        8
        indent-tabs-mode 1))

(add-hook 'makefile-mode-hook 'mb/use-tabs)
(add-hook 'makefile-bsdmake-mode-hook 'mb/use-tabs)


;; Justfile mode
(use-package just-mode
  :ensure t
  :defer t)



;; Python mode
(use-package python
  :interpreter ("python" . python-mode)
  :config
  (setq python-indent-offset mb-tab-size)
  (message "mb: PYTHON MODE"))



;; C-based languages like Java
(use-package cc-mode
  :mode
  ("\\.java\\'" . java-mode)
  :config
  ;; Set the default formatting styles for various C based modes.
  ;; Particularly, change the default style from GNU to Java.
  (setq c-default-style
        '((awk-mode . "awk")
          (other . "java")))

  (defvar flycheck-antrc "build.xml" "Ant build file name.")

  (flycheck-define-checker java
    "Java syntax checker using ant."
    :command ("ant" "-e"
              (config-file "-buildfile"flycheck-antrc)
              "compile")
    :error-patterns
    ((error line-start (file-name) ":" line ": error:"
            (message (zero-or-more not-newline)) line-end))
    :modes java-mode)

  (add-to-list 'flycheck-checkers 'java)

  (add-hook 'java-mode-hook (lambda ()
                              ;; disable auto-indent
                              (electric-indent-local-mode 0)))

  (message "mb: CC MODE"))



(use-package json-mode
  :ensure t
  :defer t
  :config
  (message "mb: JSON MODE"))



;; Javascript
(use-package js
  :defines javascript-indent-level js-indent-level js-switch-indent-offset
  :mode
  ("\\.cjs\\'" . js-mode)
  ("\\.js\\'"  . js-mode)
  ("\\.jsx\\'" . js-mode)
  :config
  (setq javascript-indent-level mb-web-indent-size
        js-switch-indent-offset mb-web-indent-size
        js-indent-level         mb-web-indent-size)

  (add-hook 'js-mode-hook 'rainbow-mode)
  (add-hook 'js-mode-hook (lambda ()
                            (when (not (eq major-mode 'json-mode))
                              (lsp)
                              (lsp-diagnostics-mode)
                              (flycheck-add-next-checker 'lsp '(warning . javascript-eslint) 'append))
                            ))


  (message "mb: JS MODE"))



;; WebMode
(use-package web-mode
  :ensure t
  :mode
  ("\\.phtml\\'"      . web-mode)
  ("\\.tpl\\.php\\'"  . web-mode)
  ("\\.twig\\'"       . web-mode)
  ("\\.html\\'"       . web-mode)
  ("\\.htm\\'"        . web-mode)
  ("\\.[gj]sp\\'"     . web-mode)
  ("\\.as[cp]x?\\'"   . web-mode)
  ("\\.eex\\'"        . web-mode)
  ("\\.erb\\'"        . web-mode)
  ("\\.mustache\\'"   . web-mode)
  ("\\.handlebars\\'" . web-mode)
  ("\\.hbs\\'"        . web-mode)
  ("\\.tera\\'"       . web-mode)
  ("\\.eco\\'"        . web-mode)
  ("\\.ejs\\'"        . web-mode)
  ("\\.djhtml\\'"     . web-mode)
  ("\\.vue\\'"        . web-mode)
  ("\\.ts\\'"         . web-mode)
  ("\\.tsx\\'"        . web-mode)
  ("\\.svelte\\'"     . web-mode)
  :init
  (setq web-mode-enable-auto-pairing  nil
        web-mode-enable-auto-quoting nil
        web-mode-markup-indent-offset mb-web-indent-size ; html tag in html file
        web-mode-css-indent-offset    mb-web-indent-size ; css in html file
        web-mode-code-indent-offset   mb-web-indent-size ; js code in html file
        )

  :config

  (add-hook 'web-mode-hook 'rainbow-mode)

  (add-hook 'web-mode-hook (lambda ()
                             (when (or
                                    (string-equal "ts" (file-name-extension buffer-file-name))
                                    (string-equal "tsx" (file-name-extension buffer-file-name))
                                    (string-equal "js" (file-name-extension buffer-file-name))
                                    (string-equal "jsx" (file-name-extension buffer-file-name))
                                    (string-equal "svelte" (file-name-extension buffer-file-name))
                                    )

                               (flycheck-add-mode 'javascript-eslint 'web-mode)

                               (lsp)
                               (lsp-diagnostics-mode)
                               (flycheck-add-next-checker 'lsp '(warning . javascript-eslint) 'append)
                               )))

  ;; (add-hook 'web-mode-hook
  ;;           (lambda ()
  ;;             (when (or (string-equal "tsx" (file-name-extension buffer-file-name))
  ;;                       (string-equal "ts" (file-name-extension buffer-file-name)))

  ;;               (tide-setup)
  ;;               (eldoc-mode)
  ;;               (message "mb: WEB MODE FOR TS(X)"))))

  (message "mb: WEB MODE"))



;; Run code formatters like Prettier
(use-package apheleia
  :disabled t ;; buggy, prettier doesn't works
  :ensure t
  :init (apheleia-global-mode +1)
  :config
  (setf (alist-get 'prettier apheleia-formatters)
        '("yarn" "run" "-s" "prettier" "--stdin-filepath" filepath)))

(use-package prettier
  :ensure t
  :defer t
  :hook ((web-mode . prettier-mode)
         (css-mode . prettier-mode)
         (js-mode . prettier-mode))
  )



;; XML
(use-package nxml-mode
  :mode ("\\.xml\\'" . nxml-mode)
  :mode ("\\.svg\\'" . nxml-mode)
  :config

  (setq nxml-child-indent  mb-tab-size)

  (message "mb: nXML MODE"))



;; Css
(use-package css-mode
  :mode ("\\.css\\'" . css-mode)
  :config
  (setq css-indent-offset mb-web-indent-size)

  (add-hook 'css-mode-hook 'rainbow-mode)

  (message "mb: CSS MODE"))



;; SCSS-mode
(use-package scss-mode
  :ensure t
  :mode ("\\.scss\\'" . scss-mode)
  :defer t
  :config
  (add-hook 'scss-mode-hook 'rainbow-mode)
  (setq scss-compile-at-save nil)
  (message "mb: SCSS MODE"))



;; Yaml
(use-package yaml-mode
  :ensure t
  :defer t
  :hook (yaml-mode . lsp) ;; https://github.com/redhat-developer/yaml-language-server
  :config (message "mb: YAML MODE"))



;; Rust
(use-package rust-mode
  :ensure t
  :defer t
  :mode ("\\.rs$" . rust-mode)
  :hook (rust-mode . lsp)
  :config
  (setq rust-format-on-save t)

  (message "mb: RUST MODE"))



;; Toml
(use-package toml-mode
  :ensure t
  :defer t
  :config (message "mb: TOML MODE"))



;; Markdown
(use-package markdown-mode
  :ensure t
  :defer t
  :config
  (add-hook 'markdown-mode-hook 'flyspell-mode)
  (message "mb: MARKDOWN MODE"))



;; Emacs Lisp
(evil-define-key 'normal 'emacs-lisp-mode
  (kbd "<leader>meb") 'eval-buffer
  (kbd "<leader>mer") 'eval-region
  (kbd "<leader>mes") 'eval-last-sexp)

(add-hook 'emacs-lisp-mode-hook
          (lambda()
            (setq mode-name "ELisp")))
(add-hook 'lisp-interaction-mode-hook
          (lambda() (setq mode-name "λ")))



;; Shell mode
(use-package sh-script
  :defer t
  :init
  ;; Use sh-mode when opening `.zsh' files, and when opening Prezto runcoms.
  (dolist (pattern '("\\.zsh\\'"
                     "zlogin\\'"
                     "zlogout\\'"
                     "zpreztorc\\'"
                     "zprofile\\'"
                     "zshenv\\'"
                     "zshrc\\'"))
    (add-to-list 'auto-mode-alist (cons pattern 'sh-mode)))
  :config
  (message "mb: SH MODE"))

(use-package company-shell
  :after (company sh-script)
  :ensure t
  :config
  (setq company-shell-dont-fetch-meta t) ;; fixes slowdown on mac https://github.com/Alexander-Miller/company-shell/issues/15
  (add-to-list 'company-backends 'company-shell))

(use-package eshell
  :defer t
  :init
  (add-hook 'eshell-mode-hook
            (lambda ()
              (define-key eshell-mode-map (kbd "M-<tab>") nil)))
  :config
  (defalias 'open 'find-file-other-window)

  (message "mb: ESHELL MODE"))


;; Lua mode
(use-package lua-mode
  :ensure t
  :defer t
  :config
  (message "mb: LUA MODE"))



;; Groovy mode (for Jenkinsfile)
(use-package groovy-mode
  :ensure t
  :defer t
  :config
  (message "mb: GROOVY MODE"))



;; Dockerfile mode
(use-package dockerfile-mode
  :ensure t
  :defer t
  :config
  (message "mb: DOCKERFILE MODE"))



;; Graphql mode
(use-package graphql-mode
  :ensure t
  :defer t
  :config
  (flycheck-add-mode 'javascript-eslint 'graphql-mode)
  (message "mb: GRAPHQL MODE"))



;; PKGBUILD mode
(use-package pkgbuild-mode
  :ensure t
  :defer t
  :mode ("\\PKGBUILD.template\\'" . pkgbuild-mode)
  :config
  (message "mb: PKGBUILD MODE"))



(provide 'init)
;;; init.el ends here
