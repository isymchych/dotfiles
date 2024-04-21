;;; init.el --- main emacs config file -*- lexical-binding: t; -*-
;;; Commentary:
;; * Spacemacs https://github.com/syl20bnr/spacemacs
;; * Doom Emacs https://github.com/doomemacs/doomemacs
;; * Evil guide https://github.com/noctuid/evil-guide
;;; Code:



;; ---------------------------------------- VARS


(defvar mb-is-mac-os (eq system-type 'darwin))
(defvar mb-is-linux (eq system-type 'gnu/linux))

;; dir for temp files
(defvar mb-save-path (expand-file-name "save-files/" mb-dotfiles-dir))

(defvar mb-light-theme 'doom-one-light)
(defvar mb-dark-theme 'doom-one)

(defvar mb-tab-size        4)

(defvar mb-use-company  t)

;; see https://platform.openai.com/api-keys
(defcustom mb-openai-api-key nil "An OpenAI API key to be used by packages." :type 'string :group 'mb-customizations)

;; keep packages in emacs-version-specific directories
;; (setq package-user-dir (expand-file-name (concat "packages/" emacs-version "/elpa") mb-dotfiles-dir))


;; ---------------------------------------- INIT

(if (native-comp-available-p)
    (message "Native compilation enabled!")
  (warn "Native compilation not enabled!"))


(require 'package)

;; this is needed to install use-package
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)

(setq package-enable-at-startup nil)
(setq package-install-upgrade-built-in t)

(package-initialize)

(eval-when-compile
  (require 'use-package))

(setq use-package-verbose t)

(require 'bind-key)

;; create temp files dir if it does not exists
(unless (file-exists-p mb-save-path)
  (make-directory mb-save-path))



;; ---------------------------------------- CONFIG

;; keep menu bar enabled only on mac since it doesn't take vertical space
(if (and
     (fboundp 'menu-bar-mode)
     mb-is-mac-os)
    (menu-bar-mode t))

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

 ;; avoid some initial frame resizing to speed up startup
 frame-inhibit-implied-resize t

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

 ;; skip duplicates from the kill-ring to simplify yanking
 kill-do-not-save-duplicates t

 ;; Don't prompt for confirmation when we create a new file or buffer (assume the
 ;; user knows what they're doing).
 confirm-nonexistent-file-or-buffer nil

 ;; middle-click paste at point, not at click
 mouse-yank-at-point t

 ;; do not break line even if its too long
 truncate-lines t
 truncate-partial-width-windows t)

;; use keyboard dialogs instead of popups
(setq use-dialog-box nil)
(tooltip-mode -1)

(blink-cursor-mode t)

;; take the short answer, y/n is yes/no
(setq use-short-answers t)

;; do not ask if I want to execute `eval' from dir-locals
(setq enable-local-eval t)
;; do not ask if I want to set variables from dir-locals
(setq enable-local-variables :all)

;; disable only critical messages
(setq warning-minimum-level :emergency)

;; Emacs 30 and newer: Disable Ispell completion function.
(setq text-mode-ispell-word-completion nil)

;; Emacs 28 and newer: Hide commands in M-x which do not apply to the current mode.
(setq read-extended-command-predicate #'command-completion-default-include-p)

;; make urls in comments/strings clickable
(add-hook 'find-file-hook 'goto-address-prog-mode)

;; highlight current line
(global-hl-line-mode t)

;; Enable disabled features
(put 'downcase-region           'disabled nil)
(put 'upcase-region             'disabled nil)
(put 'narrow-to-region          'disabled nil)

(setq-default
 ;; start scratch in text mode (usefull to get a faster Emacs load time
 ;; because it avoids autoloads of elisp modes)
 initial-major-mode 'text-mode

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
(setq tramp-persistency-file-name (expand-file-name "tramp" mb-save-path))
;; dir to store some temporary files
(setq backup-directory-alist '(("." . mb-save-path)))
(setq url-configuration-directory (expand-file-name "url" mb-save-path))

;; Transparently open compressed files
(auto-compression-mode t)

;; Delete-selection mode: delete selected text when typing
(delete-selection-mode t)

;; Electric indent mode: enable autoindent on enter etc.
(electric-indent-mode 1)


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


;; Allow for minibuffer-ception. Sometimes we need another minibuffer command
;; while we're in the minibuffer.
(setq enable-recursive-minibuffers t)


;; Expand the minibuffer to fit multi-line text displayed in the echo-area
(setq resize-mini-windows 'grow-only)


;; Try to keep the cursor out of the read-only portions of the minibuffer.
(setq minibuffer-prompt-properties '(read-only t intangible t cursor-intangible t face minibuffer-prompt))
(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)


;; Default to soft line-wrapping in text modes. It is more sensibile for text
;; modes, even if hard wrapping is more performant.
(add-hook 'text-mode-hook #'visual-line-mode)



;; Use GNU ls as `gls' from `coreutils' if available.  Add `(setq
;; dired-use-ls-dired nil)' to your config to suppress the Dired warning when
;; not using GNU ls.  We must look for `gls' after `exec-path-from-shell' was
;; initialized to make sure that `gls' is in `exec-path'
(when mb-is-mac-os
  (let ((gls (executable-find "gls")))
    (when gls
      (setq insert-directory-program gls
            dired-listing-switches "-aBhl --group-directories-first"))))



;; ---------------------------------------- UTILS



;; https://github.com/syl20bnr/spacemacs/blob/a58a7d79b3713bcf693bb61d9ba83d650a6aba86/core/core-funcs.el#L331
(defun mb/alternate-buffer (&optional window)
  "Switch back and forth between current and last buffer in the WINDOW."
  (interactive)
  (cl-destructuring-bind (buf start pos)
      (or (cl-find (window-buffer window) (window-prev-buffers)
                   :key #'car :test-not #'eq)
          (list (other-buffer) nil nil))
    (if (not buf)
        (message "Last buffer not found.")
      (set-window-buffer-start-and-point window buf start pos))))


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
        (buffer (current-buffer)))
    (if (not (and filename (file-exists-p filename)))
        (ido-kill-buffer)
      (when (yes-or-no-p "Are you sure you want to remove this file? ")
        (delete-file filename)
        (kill-buffer buffer)
        (message "mb: File '%s' successfully removed" filename)))))

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

(defun mb/get-selected-text ()
  "Return the currently selected text in the current buffer."
  (if (region-active-p)
      (buffer-substring (region-beginning) (region-end))
    ""))


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


;; disable input methods
(global-unset-key (kbd "C-\\"))

;; prevent accidentally closed frames
(global-unset-key (kbd "C-x C-z"))

;; make M-tab work in terminal
(define-key input-decode-map [?\C-\M-i] [M-tab])
(global-set-key [M-tab]         'mb/alternate-buffer)

;; free up keybinding to be used as a prefix
(global-set-key (kbd "M-e")     'nil)

(global-set-key (kbd "M-/")     'hippie-expand)
(global-set-key (kbd "M-u")     'universal-argument)

(global-set-key [f6]    'mb/revert-buffer)


;; ---------------------------------------- BUILT-IN PACKAGES

;; evil uses dabbrev
(use-package dabbrev
  :config
  ;; do not split words on _ and -
  (setq dabbrev-abbrev-char-regexp "[a-zA-Z0-9?!_\-]")

  (add-to-list 'dabbrev-ignored-buffer-modes 'doc-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'pdf-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'tags-table-mode))



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



;; Project.el: project management
(use-package project
  :init
  (setq project-list-file (expand-file-name "projects" mb-save-path))
  :config
  (push '(project-dired "Root directory") project-switch-commands)

  ;; Improve detection of project root https://andreyor.st/posts/2022-07-16-project-el-enhancements/
  (defcustom project-root-markers
    '("Cargo.lock" ".git" ".emacs-project")
    "Files or directories that indicate the root of a project."
    :type '(repeat string)
    :group 'project)

  (defun project-root-p (path)
    "Check if the current PATH has any of the project root markers."
    (catch 'found
      (dolist (marker project-root-markers)
        (when (file-exists-p (concat path marker))
          (throw 'found marker)))))

  (defun project-find-root (path)
    "Search up the PATH for `project-root-markers'."
    (when-let ((root (locate-dominating-file path #'project-root-p)))
      (cons 'transient (expand-file-name root))))

  (add-to-list 'project-find-functions #'project-find-root))



;; Flyspell-mode: spell-checking on the fly as you type
(use-package flyspell
  :defer 1
  :diminish flyspell-mode
  :init
  (when (executable-find "aspell")
    (setq ispell-program-name "aspell") ; use aspell instead of ispell
    (setq ispell-personal-dictionary (expand-file-name "aspell.en.pws" mb-save-path))
    (setq-default ispell-extra-args '("--sug-mode=ultra"
                                      "--lang=en_GB"
                                      "--camel-case")))

  (add-hook 'text-mode-hook 'flyspell-mode)
  (add-hook 'prog-mode-hook (lambda ()
                              (setq flyspell-consider-dash-as-word-delimiter-flag t)
                              (flyspell-prog-mode)))
  :config
  (global-set-key [M-f8]  'flyspell-buffer))



;; Uniquify: unique buffer names
(use-package uniquify
  :config
  (setq uniquify-buffer-name-style 'forward
        uniquify-separator "/"
        ;; rename after killing uniquified
        uniquify-after-kill-buffer-p t
        ;; don't muck with special buffers
        uniquify-ignore-buffers-re "^\\*"))



;; IBuffer (local)
(use-package ibuffer
  :disabled
  :bind ([f2] . ibuffer)
  :init
  ;; use ibuffer on C-x C-b
  (defalias 'list-buffers 'ibuffer)
  ;; use ibuffer as default buffers list (:ls)
  (defalias 'buffer-menu 'ibuffer)

  :config
  (define-key ibuffer-mode-map [f2]      'ibuffer-quit))



;; Recentf: save recent files
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
  (add-to-list 'recentf-exclude "/save-files/")

  (add-hook 'server-done-hook 'recentf-save-list)
  (add-hook 'server-visit-hook 'recentf-save-list)
  (add-hook 'delete-frame-hook 'recentf-save-list)

  (recentf-mode t)
  (recentf-track-opened-file))



;; Save search history
(use-package savehist
  :config
  (setq savehist-file (expand-file-name "savehist" mb-save-path)
        savehist-save-minibuffer-history t
        savehist-autosave-interval nil ; save on kill only
        savehist-additional-variables
        '(
          mark-ring global-mark-ring       ; persist marks
          search-ring regexp-search-ring)) ; persist searches

  (savehist-mode t))



;; Saveplace: save cursor position
(use-package saveplace
  :init
  (setq-default save-place-file (expand-file-name "saveplace" mb-save-path))

  :config
  (save-place-mode t))



;; Automatically update unmodified buffers whose files have changed.
(use-package autorevert
  :diminish auto-revert-mode
  :config
  (setq auto-revert-verbose t ; let us know when it happens
        auto-revert-use-notify nil
        auto-revert-stop-on-user-input nil
        ;; Only prompts for confirmation when buffer is unsaved.
        revert-without-query (list "."))
  (global-auto-revert-mode t))



;; Subword-mode: navigate in CamelCase words
;; http://ergoemacs.org/emacs/emacs_subword-mode_superword-mode.html
(use-package subword
  :diminish subword-mode
  :init
  (global-subword-mode t))



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



;; Show parens mode: highlight matching parens
(use-package paren
  :config
  (setq show-paren-delay 0
        ;; decrease overlay priority because
        ;; it's higher than selection
        show-paren-priority 10
        ;; highlight everything inside parens
        show-paren-style 'expression

        show-paren-highlight-openparen t
        show-paren-when-point-inside-paren t
        show-paren-when-point-in-periphery t)
  (show-paren-mode 1))



;; Eldoc: documentation messages
(use-package eldoc
  :diminish eldoc-mode
  :init
  (add-hook  'emacs-lisp-mode-hook        'turn-on-eldoc-mode)
  (add-hook  'lisp-interaction-mode-hook  'turn-on-eldoc-mode)
  (add-hook  'ielm-mode-hook              'turn-on-eldoc-mode))



;; Dired extensions
(use-package dired-x
  :config
  (put 'dired-find-alternate-file 'disabled nil)

  (setq dired-auto-revert-buffer t)    ; automatically revert buffer

  (defun mb/dired-up-directory ()
    "Take dired up one directory, but behave like dired-find-alternate-file."
    (interactive)
    (let ((old (current-buffer)))
      (dired-up-directory)
      (kill-buffer old)))

  (defun mb/dired-find-file-or-alternate ()
    "In Dired, open directories with `dired-find-alternate-file' and files with `dired-find-file'."
    (interactive)
    (let ((file (dired-get-file-for-visit)))
      (if (file-directory-p file)
          (dired-find-alternate-file)
        (dired-find-file))))

  (define-key dired-mode-map [remap dired-up-directory] 'mb/dired-up-directory)
  (define-key dired-mode-map [remap quit-window]        'mb/kill-this-buffer)

  (define-key dired-mode-map [remap dired-find-file] 'mb/dired-find-file-or-alternate)
  (define-key dired-mode-map (kbd "RET") 'dired-find-alternate-file))



;; Emacs shell
(use-package eshell
  :defer t
  :init
  (setq eshell-directory-name (expand-file-name "eshell" mb-save-path)
        eshell-aliases-file   (expand-file-name "eshell-aliases" mb-dotfiles-dir)))


;; Flymake
(use-package flymake
  :disabled
  :defer t
  :after (evil)
  :init
  ;; as flymakes fail silently there is no need to activate it on a per major mode basis
  (add-hook 'prog-mode-hook #'flymake-mode)
  (add-hook 'text-mode-hook #'flymake-mode)
  :config
  (setq flymake-fringe-indicator-position 'right-fringe)

  (evil-add-command-properties #'flymake-goto-next-error :jump t)
  (evil-add-command-properties #'flymake-goto-prev-error :jump t)

  (evil-define-key 'normal 'global
    (kbd "M-e j") 'flymake-goto-next-error
    (kbd "M-e M-j") 'flymake-goto-next-error
    (kbd "M-e k") 'flymake-goto-prev-error
    (kbd "M-e l") 'flymake-show-project-diagnostics
    (kbd "M-e M-k") 'flymake-goto-prev-error
    (kbd "M-e b") 'flymake-start))



;; Comint-mode: interact with REPLs
(use-package comint
  :no-require
  :init
  (setq ansi-color-for-comint-mode t
        comint-prompt-read-only t
        comint-buffer-maximum-size 2048))



;; Compilation mode
(use-package compile
  :no-require
  :init
  (setq compilation-always-kill t       ; kill compilation process before starting another
        compilation-ask-about-save nil  ; save all buffers on `compile'
        compilation-save-buffers-predicate (lambda () nil)
        compilation-scroll-output 'first-error)

  (add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)

  ;; Automatically truncate compilation buffers so they don't accumulate too
  ;; much data and bog down the rest of Emacs.
  (autoload 'comint-truncate-buffer "comint" nil t)
  (add-hook 'compilation-filter-hook #'comint-truncate-buffer))




;; Ediff: resolve merge conflicts
(use-package ediff
  :defer t
  :init
  (setq ediff-diff-options "-w" ; turn off whitespace checking
        ediff-split-window-function #'split-window-horizontally
        ediff-window-setup-function #'ediff-setup-windows-plain))


;; ---------------------------------------- 3rd PARTY PACKAGES

;; Nord theme https://github.com/arcticicestudio/nord-emacs
;; Solarized theme https://github.com/bbatsov/solarized-emacs

;; Doom emacs themes https://github.com/doomemacs/themes
(use-package doom-themes
  :ensure t
  :config
  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)

  ;; (setq doom-themes-treemacs-theme "doom-atom") ; use "doom-colors" for less minimal icon theme
  ;; (doom-themes-treemacs-config)

  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))


;; Modus themes https://protesilaos.com/emacs/modus-themes
(use-package modus-themes
  :disabled
  :ensure t
  :config
  (setq modus-themes-italic-constructs t
        modus-themes-bold-constructs nil)

  (setq modus-themes-common-palette-overrides
        (append
         ;; Keep the border but make it the same color as the background of the
         ;; mode line (thus appearing borderless).  The difference with the
         ;; above is that this version is a bit thicker because the border are
         ;; still there.
         '((border-mode-line-active bg-mode-line-active)
           (border-mode-line-inactive bg-mode-line-inactive))

         modus-themes-preset-overrides-faint)))



;; Auto dark mode on Linux https://darkman.grtcdr.tn/
(use-package darkman
  :if mb-is-linux
  :ensure t

  :config
  (setq darkman-themes (list :light mb-light-theme :dark mb-dark-theme))
  (darkman-mode))



;; Auto dark mode on macOS
(use-package auto-dark
  :if mb-is-mac-os
  :ensure t
  :diminish auto-dark-mode
  :init
  ;; HACK: remove the applescript support so that this package doesn't break in CLI mode
  (unless window-system
    (fmakunbound 'ns-do-applescript))
  :config
  (setq
   auto-dark-allow-osascript t
   auto-dark-dark-theme mb-dark-theme
   auto-dark-light-theme mb-light-theme)

  (auto-dark-mode t))



;; Dimmer: make inactive tabs dim
(use-package dimmer
  :if window-system
  :disabled t
  :ensure t
  :defer 0.5
  :init
  ;; https://github.com/gonewest818/dimmer.el/issues/62#issuecomment-1820362245
  (defun advise-dimmer-config-change-handler ()
    "Advise to only force process if no predicate is truthy."
    (let ((ignore (cl-some (lambda (f) (and (fboundp f) (funcall f)))
                           dimmer-prevent-dimming-predicates)))
      (unless ignore
        (when (fboundp 'dimmer-process-all)
          (dimmer-process-all t)))))

  (defun corfu-frame-p ()
    "Check if the buffer is a corfu frame buffer."
    (string-match-p "\\` \\*corfu" (buffer-name)))

  (defun dimmer-configure-corfu ()
    "Convenience settings for corfu users."
    (add-to-list
     'dimmer-prevent-dimming-predicates
     #'corfu-frame-p))
  :config
  (setq dimmer-fraction 0.3)
  (setq dimmer-adjustment-mode :foreground)
  (setq dimmer-use-colorspace :rgb)
  (dimmer-configure-magit)
  (dimmer-configure-which-key)

  (advice-add
   'dimmer-config-change-handler
   :override 'advise-dimmer-config-change-handler)
  (dimmer-configure-corfu)

  (dimmer-mode 1))



;; Mode line
(use-package doom-modeline
  :ensure t
  :config
  (setq doom-modeline-buffer-file-name-style 'truncate-upto-project
        doom-modeline-icon nil
        doom-modeline-unicode-fallback nil
        doom-modeline-buffer-encoding nil
        doom-modeline-minor-modes t
        doom-modeline-env-version nil)

  ;; minibuffer colors for evil states https://emacs.stackexchange.com/a/76861
  (defun color-minibuffer (color)
    `(lambda ()
       (when (minibufferp)
         (face-remap-add-relative 'minibuffer-prompt :foreground ,color))))
  (add-hook 'evil-normal-state-entry-hook   (color-minibuffer (face-foreground 'doom-modeline-evil-normal-state nil t)))
  (add-hook 'evil-operator-state-entry-hook (color-minibuffer (face-foreground 'doom-modeline-evil-operator-state nil t)))
  (add-hook 'evil-insert-state-entry-hook   (color-minibuffer (face-foreground 'doom-modeline-evil-insert-state nil t)))
  (add-hook 'evil-replace-state-entry-hook  (color-minibuffer (face-foreground 'doom-modeline-evil-replace-state nil t)))
  (add-hook 'evil-visual-state-entry-hook   (color-minibuffer (face-foreground 'doom-modeline-evil-visual-state nil t)))
  (add-hook 'evil-motion-state-entry-hook   (color-minibuffer (face-foreground 'doom-modeline-evil-motion-state nil t)))
  (add-hook 'evil-emacs-state-entry-hook    (color-minibuffer (face-foreground 'doom-modeline-evil-emacs-state nil t)))

  (doom-modeline-mode 1))



;; Nyan mode: use nyan cat in mode line to indicate scroll position
(use-package nyan-mode
  :ensure t
  :config
  (setq nyan-minimum-window-width 128)
  (nyan-mode))



;; Diminish: cleanup mode line
(use-package diminish
  :ensure t
  :config
  (eval-after-load 'hi-lock
    '(diminish 'hi-lock-mode)))



;; Fix PATH on Mac
(use-package exec-path-from-shell
  ;; Not needed ATM since the emacs-plus injects path on build https://github.com/d12frosted/homebrew-emacs-plus#injected-path
  :disabled
  :if mb-is-mac-os
  :ensure t
  :config
  (exec-path-from-shell-initialize))



;; writable grep, complementary package for other packages
(use-package wgrep
  :ensure t
  :defer t
  :config
  (setq wgrep-auto-save-buffer t))



;; Make clipboard work on all platforms
(use-package xclip
  :ensure t
  :config
  (xclip-mode 1))



;; sync emacs input mode with OS keyboard layout
(use-package reverse-im
  :ensure t
  :custom
  (reverse-im-input-methods '("ukrainian-computer"))
  :config
  (reverse-im-mode t))



;; Improved undo/redo system (used by evil)
(use-package undo-fu
  :ensure t

  :init
  ;; increase emacs default undo limits
  (setq undo-limit 6710886400) ;; 64mb.
  (setq undo-strong-limit 100663296) ;; 96mb.
  (setq undo-outer-limit 1006632960) ;; 960mb.

  :config
  (global-set-key [remap undo] #'undo-fu-only-undo)
  (global-set-key (kbd "C-S-z") #'undo-fu-only-redo))


;; Save & restore undo/redo state
(use-package undo-fu-session
  :ensure t
  :after undo-fu
  :config
  (setq undo-fu-session-directory (expand-file-name "undo-fu-session" mb-save-path)
        undo-fu-session-compression 'zst
        undo-fu-session-incompatible-files '("\\.gpg$" "/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'"))

  (global-undo-fu-session-mode))


;; Evil: vim mode
(use-package evil
  :ensure t
  ;; this must be set before loading evil
  :init
  ;; use C-u as scroll-up
  (defvar evil-want-C-u-scroll t)
  (defvar evil-want-Y-yank-to-eol t)
  (defvar evil-want-C-i-jump t)
  (defvar evil-want-keybinding nil)
  (defvar evil-want-minibuffer t)
  (defvar evil-undo-system 'undo-fu)
  (defvar evil-lookup-func #'helpful-at-point)

  ;; enable subword mode CamelCase movement in evil
  (define-category ?U "Uppercase")
  (define-category ?u "Lowercase")
  (modify-category-entry (cons ?A ?Z) ?U)
  (modify-category-entry (cons ?a ?z) ?u)
  (make-variable-buffer-local 'evil-cjk-word-separating-categories)
  (add-hook 'subword-mode-hook
            (lambda ()
              (if subword-mode
                  (push '(?u . ?U) evil-cjk-word-separating-categories)
                (setq evil-cjk-word-separating-categories (default-value 'evil-cjk-word-separating-categories)))))
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

   evil-kbd-macro-suppress-motion-error t

   ;; search for whole words not only for part
   evil-symbol-word-search 'symbol)

  ;; Exit to normal state after save
  (add-hook 'after-save-hook 'evil-normal-state)

  (evil-set-initial-state 'minibuffer-mode           'emacs)
  (evil-set-initial-state 'inferior-emacs-lisp-mode  'emacs)
  (evil-set-initial-state 'pylookup-mode             'emacs)
  (evil-set-initial-state 'term-mode                 'emacs)
  (evil-set-initial-state 'help-mode                 'emacs)
  (evil-set-initial-state 'grep-mode                 'emacs)
  (evil-set-initial-state 'bc-menu-mode              'emacs)
  (evil-set-initial-state 'rdictcc-buffer-mode       'emacs)
  (evil-set-initial-state 'comint-mode               'normal)
  (evil-set-initial-state 'wdired-mode               'normal)
  (evil-set-initial-state 'shell-mode                'insert)

  (evil-mode 1)

  ;; set leader key in all states
  (evil-set-leader nil (kbd "C-SPC"))

  ;; set leader key in normal & visual state
  (evil-set-leader '(normal visual) (kbd "SPC"))

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
  (define-key evil-motion-state-map "K" 'eldoc)
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

  (evil-define-key 'emacs minibuffer-mode-map
    ;; insert newline with Alt-Enter
    (kbd "M-<return>") 'newline
    (kbd "M-RET") 'newline

    ;; make Enter work as expected in minibuffer default (emacs) state
    (kbd "<return>") 'exit-minibuffer
    (kbd "RET") 'exit-minibuffer)


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

  (which-key-add-key-based-replacements "SPC a" "AI actions")
  (which-key-add-key-based-replacements "SPC b" "Buffer actions")
  (which-key-add-key-based-replacements "SPC l" "List")
  (which-key-add-key-based-replacements "SPC m" "Mode actions")
  (which-key-add-key-based-replacements "SPC h" "Help")
  (which-key-add-key-based-replacements "SPC p" "Project actions")
  (which-key-add-key-based-replacements "SPC g" "Git")
  (which-key-add-key-based-replacements "SPC i" "Insert")
  (which-key-add-key-based-replacements "SPC j" "Jump to")
  (which-key-add-key-based-replacements "SPC D" "current Dir")
  (which-key-add-key-based-replacements "SPC t" "Toggle")

  ;; NOTE: m is reserved for mode-local bindings
  (evil-define-key 'normal 'global
    (kbd "<leader>2")   'call-last-kbd-macro
    (kbd "<leader>q")   'evil-quit
    (kbd "<leader>n")   'mb/narrow-or-widen-dwim
    (kbd "<leader>k")   'mb/kill-this-buffer
    (kbd "<leader>s")   'save-buffer
    (kbd "<leader>e")   'eshell
    (kbd "<leader>d")   'dired-jump

    (kbd "<leader>lm") 'evil-show-marks
    (kbd "<leader>li")  'imenu
    (kbd "<leader> l <SPC>") 'just-one-space

    (kbd "<leader>ie") 'emoji-search

    (kbd "<leader>bl") 'mb/cleanup-buffer
    (kbd "<leader>bd") 'mb/delete-current-buffer-file
    (kbd "<leader>br") 'mb/rename-file-and-buffer
    (kbd "<leader>bR") 'mb/revert-buffer

    (kbd "<leader>pp") 'project-switch-project
    (kbd "<leader>pD") 'project-dired
    (kbd "<leader>pe") 'project-eshell
    (kbd "<leader>pk") 'project-kill-buffers

    (kbd "<leader>tn") 'display-line-numbers-mode
    (kbd "<leader>tw") 'visual-line-mode
    (kbd "<leader>tf") 'auto-fill-mode
    (kbd "<leader>tm") 'menu-bar-mode)

  (evil-define-key 'visual 'global
    (kbd "<leader>n")  'mb/narrow-or-widen-dwim
    (kbd "<leader>lt") 'mb/sort-columns))

;; integration of evil with various packages
(use-package evil-collection
  :after evil
  :ensure t
  :init
  (setq
   evil-collection-setup-minibuffer t
   evil-collection-want-unimpaired-p nil)

  :config
  (evil-collection-init)

  (add-hook 'view-mode-hook
            (lambda ()
              (evil-collection-define-key 'normal 'view-mode-map
                " " 'nil)))

  (add-hook 'image-mode-hook
            (lambda ()
              (evil-collection-define-key 'normal 'image-mode-map
                " " 'nil)))

  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'mb/dired-up-directory
    "l" 'dired-find-file
    (kbd "RET") 'dired-find-alternate-file
    " " 'nil))


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
  :config
  (global-evil-surround-mode 1))

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
  :config
  (evil-exchange-install))

;; xml tag attribute as a text object (bound to x)
(use-package exato
  :after evil
  :ensure t
  :init
  (setq exato-key "a"))

;; align text into columns - gl<space> or gL<space>
(use-package evil-lion
  :after evil
  :ensure t
  :config
  (evil-lion-mode))

;; better jump list
(use-package better-jumper
  :after evil
  :ensure t
  :diminish better-jumper-local-mode
  :init
  (global-set-key [remap evil-jump-forward]  #'better-jumper-jump-forward)
  (global-set-key [remap evil-jump-backward] #'better-jumper-jump-backward)
  (global-set-key [remap xref-pop-marker-stack] #'better-jumper-jump-backward)
  (global-set-key [remap xref-go-back] #'better-jumper-jump-backward)
  (global-set-key [remap xref-go-forward] #'better-jumper-jump-forward)

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


;; manage comments
(use-package comment-dwim-2
  :after evil
  :ensure t
  :defer t
  :bind (([remap comment-line] . 'comment-dwim-2)
         ([remap comment-dwim] . 'comment-dwim-2)
         :map evil-normal-state-map
         ("gc"   . 'comment-dwim-2)))


;; Visualise the undo history
(use-package vundo
  :ensure t
  :defer t
  :bind
  ("<leader>u" . 'vundo)
  :config
  (setq vundo-glyph-alist vundo-unicode-symbols)

  (evil-define-key 'normal vundo-mode-map (kbd "<escape>") 'vundo-quit))



;; Vertical completion UI (like ido)
(use-package vertico
  :ensure t
  :init
  (vertico-mode)

  (setq
   ;; Show more candidates
   vertico-count 20
   ;; enable cycling for `vertico-next' and `vertico-previous'.
   vertico-cycle t)

  (add-hook 'minibuffer-setup-hook #'vertico-repeat-save)

  (define-key vertico-map (kbd "M-j") 'vertico-next)
  (define-key vertico-map (kbd "M-k") 'vertico-previous)

  (evil-define-key 'normal 'global (kbd "<leader>`") 'vertico-repeat))



;; Fuzzy matching algorithm
(use-package orderless
  :ensure t
  :init
  (defun without-if-bang (pattern _index _total)
    (cond
     ((equal "!" pattern)
      '(orderless-literal . ""))
     ((string-prefix-p "!" pattern)
      `(orderless-without-literal . ,(substring pattern 1)))))

  (setq completion-styles '(basic orderless)
        orderless-matching-styles '(orderless-literal)
        orderless-style-dispatchers '(without-if-bang)
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
  (setq
   consult-preview-key (list :debounce 1 'any)
   register-preview-delay 0.5
   register-preview-function #'consult-register-format)

  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  :config
  (setq
   consult-line-numbers-widen t
   consult-async-min-input 2
   consult-async-refresh-delay  0.15
   consult-async-input-throttle 0.2
   consult-async-input-debounce 0.1
   consult-narrow-key "C-+")

  ;; use consult instead of the standard *Completions* buffer
  (setq completion-in-region-function #'consult-completion-in-region)

  ;; These commands are problematic and automatically show the *Completions* buffer
  (advice-add #'tmm-add-prompt :after #'minibuffer-hide-completions)
  (advice-add #'ffap-menu-ask :around (lambda (&rest args)
                                        (cl-letf (((symbol-function #'minibuffer-completion-help)
                                                   #'ignore))
                                          (apply args))))


  ;; make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)

  ;;  consult-outline support for eshell prompts
  (add-hook 'eshell-mode-hook (lambda () (setq outline-regexp eshell-prompt-regexp)))

  (global-set-key (kbd "M-X") 'consult-mode-command)

  ;; remap existing commands
  (global-set-key [remap apropos]                       #'consult-apropos)
  (global-set-key [remap bookmark-jump]                 #'consult-bookmark)
  (global-set-key [remap evil-show-marks]               #'consult-mark)
  (global-set-key [remap evil-show-jumps]               #'evil-collection-consult-jump-list)
  (global-set-key [remap evil-show-registers]           #'consult-register)
  (global-set-key [remap goto-line]                     #'consult-goto-line)
  (global-set-key [remap imenu]                         #'consult-imenu)
  (global-set-key [remap locate]                        #'consult-locate)
  (global-set-key [remap load-theme]                    #'consult-theme)
  (global-set-key [remap man]                           #'consult-man)
  (global-set-key [remap recentf-open-files]            #'consult-recent-file)
  (global-set-key [remap switch-to-buffer]              #'consult-buffer)
  (global-set-key [remap switch-to-buffer-other-window] #'consult-buffer-other-window)
  (global-set-key [remap yank-pop]                      #'consult-yank-pop)

  (advice-add #'multi-occur :override #'consult-multi-occur)

  (setq consult-fd-args "fd --color=never")

  (defun consult-ripgrep-symbol-at-point (&optional dir)
    (interactive)
    (consult-ripgrep dir (if (region-active-p)
                             (mb/get-selected-text)
                           (thing-at-point 'symbol))))

  (defun consult-ripgrep-in-current-dir ()
    (interactive)
    (consult-ripgrep default-directory))

  (defun consult-fd-thing-at-point (&optional dir)
    (interactive)
    (consult-fd dir (if (region-active-p)
                        (mb/get-selected-text)
                      (thing-at-point 'filename))))

  (defun consult-fd-in-current-dir ()
    (interactive)
    (consult-fd default-directory))

  (evil-define-key 'normal 'global
    (kbd "<leader>r") 'consult-recent-file
    (kbd "<leader>y") 'consult-yank-from-kill-ring
    (kbd "<leader>li") 'consult-imenu
    (kbd "<leader>le") 'consult-flymake
    (kbd "<leader>ll") 'consult-line
    (kbd "<leader>lo") 'consult-outline
    (kbd "gb")         'consult-buffer
    (kbd "<leader>SPC") 'consult-buffer

    (kbd "<leader>Ds") 'consult-ripgrep-in-current-dir
    (kbd "<leader>Df") 'consult-fd-in-current-dir

    ;; project
    (kbd "<leader>pb") 'consult-project-buffer
    (kbd "<leader>ps") 'consult-ripgrep
    ;; (kbd "<leader>pS") 'consult-ripgrep-symbol-at-point
    (kbd "<leader>pf") 'consult-fd
    (kbd "<leader>pF") 'consult-fd-thing-at-point))


;; jump to project
(use-package consult-jump-project
  :after consult
  :defer t
  :commands (consult-jump-project)
  :init
  (if (not (package-installed-p 'consult-jump-project))
      (package-vc-install "https://github.com/jdtsmith/consult-jump-project"))
  (evil-define-key 'normal 'global
    (kbd "<leader>pp") 'consult-jump-project))


;; Jump to Flycheck error
(use-package consult-flycheck
  :after (consult flycheck)
  :ensure t
  :defer t
  :bind
  (("<leader>le" . 'consult-flycheck)
   ("M-e l"      . 'consult-flycheck)))



;; Context commands for things at a point
(use-package embark
  :ensure t
  :bind
  (("C-h B" . 'embark-bindings-at-point)
   ("M-." .  'embark-act)
   :map evil-normal-state-map
   ("M-."        . 'embark-act)
   ("<leader>hb" . 'embark-bindings-in-keymap)
   ("<leader>hB" . 'embark-bindings))

  :config
  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))



(use-package embark-consult
  :ensure t
  :after (embark consult)
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


;; Rg: search using ripgrep
(use-package rg
  :defer t
  :ensure t
  :commands (rg-menu rg-isearch-menu rg-project)
  :init
  (evil-define-key 'normal 'global
    (kbd "M-s R") 'rg-isearch-menu
    (kbd "M-s r") 'rg-menu

    (kbd "<leader>pS") 'rg-project))



;; Avy: jump to char/line
(use-package avy
  :ensure t
  :config
  (evil-define-key 'normal 'global
    (kbd "<leader>jr") 'avy-resume
    (kbd "<leader>jj") 'evil-avy-goto-char-timer
    (kbd "<leader>jl") 'evil-avy-goto-line))



;; Company-mode: autocomplete
(use-package company
  :if mb-use-company
  :ensure t
  :defer 0.5
  :diminish company-mode
  :config
  (setq
   company-idle-delay                0.15
   company-tooltip-limit             20
   company-tooltip-align-annotations t
   company-minimum-prefix-length     1
   company-echo-delay                0
   company-selection-wrap-around     t

   company-insertion-triggers        nil

   company-dabbrev-ignore-case       nil
   company-dabbrev-downcase          nil

   company-require-match             nil
   company-show-quick-access         t
   company-transformers             '(delete-dups)

   company-backends '((company-files
                       company-keywords
                       company-capf
                       company-dabbrev-code
                       company-dabbrev)))

  (defun mb/use-custom-matching-style (fn &rest args)
    "Use custom completion style specifically for the company-capf."
    (let ((orderless-matching-styles '(orderless-literal orderless-flex)))
      (apply fn args)))

  (advice-add #'company-capf :around #'mb/use-custom-matching-style)

  (add-hook 'evil-insert-state-exit-hook 'company-abort)

  (eval-after-load 'eldoc
    (eldoc-add-command 'company-complete-selection
                       'company-complete-common
                       'company-capf
                       'company-abort))

  (global-company-mode 1)

  ;; Make TAB always complete the current selection, instead of
  ;; only completing a common prefix.
  (define-key company-active-map (kbd "<tab>") #'company-complete-selection)
  (define-key company-active-map (kbd "TAB") #'company-complete-selection)

  ;; https://emacs.stackexchange.com/a/24800
  ;; <return> is for windowed Emacs; RET is for terminal Emacs
  (dolist (key '("<return>" "RET"))
    ;; Here we are using an advanced feature of define-key that lets
    ;; us pass an "extended menu item" instead of an interactive
    ;; function. Doing this allows RET to regain its usual
    ;; functionality when the user has not explicitly interacted with
    ;; Company.
    (define-key company-active-map (kbd key)
                `(menu-item nil company-complete
                            :filter ,(lambda (cmd)
                                       (when (or (company-explicit-action-p)
                                                 ;; or if previewing just one completion candidate
                                                 (eq company-candidates-length 1))
                                         cmd)))))

  (define-key company-active-map (kbd "<f1>") nil)

  (define-key company-active-map (kbd "C-w") nil)
  (define-key company-active-map (kbd "C-j") nil)
  (define-key company-active-map (kbd "C-s")  nil)
  (define-key company-active-map (kbd "M-l")  'company-show-location)
  (define-key company-active-map [remap scroll-down-command]  nil)
  (define-key company-active-map [remap scroll-up-command]  nil)

  (global-set-key (kbd "M-p") 'company-manual-begin))


;; Company-shell: better autocomplete in shell
(use-package company-shell
  :if mb-use-company
  :after (company sh-script)
  :ensure t
  :config
  (setq company-shell-dont-fetch-meta mb-is-mac-os) ;; fixes slowdown on mac https://github.com/Alexander-Miller/company-shell/issues/15
  (add-to-list 'company-backends 'company-shell))


;; Company-quickhelp: show docs for a candidate in a tooltip
;; NOTE: change tooltip font size on Mac: defaults write org.gnu.Emacs NSToolTipsFontSize -int 14
(use-package company-quickhelp
  :if mb-use-company
  :after company
  :ensure t
  :bind (:map company-active-map ("M-h" . #'company-quickhelp-manual-begin))
  :config
  (setq company-quickhelp-delay nil)
  (company-quickhelp-mode))



;; Completion-at-point (CAPF)
;; M-SPC during completion allows to filter candidates
;; M-g during completion shows candidate source
;; M-h during completion shows candidate documentation
;; NOTE: Feels "slow" comparing to company; has visual glitches
;; TODO: configure multiple completion sources
(use-package corfu
  :if (not mb-use-company)
  :ensure t
  :config
  (setq corfu-cycle t
        corfu-auto t
        corfu-auto-delay 0.1
        corfu-auto-prefix 1
        corfu-scroll-margin 5
        corfu-indexed-start 1
        corfu-count 16
        corfu-max-width 120
        corfu-on-exact-match nil)
  (global-corfu-mode)
  (corfu-indexed-mode)
  (corfu-popupinfo-mode)

  (corfu-history-mode 1)
  (add-to-list 'savehist-additional-variables 'corfu-history)

  ;; https://github.com/minad/corfu#completing-in-the-eshell-or-shell
  (add-hook 'eshell-mode-hook
            (lambda ()
              (setq-local corfu-auto nil)
              (corfu-mode)))

  (defun corfu-send-shell (&rest _)
    "Send completion candidate when inside comint/eshell."
    (cond
     ((and (derived-mode-p 'eshell-mode) (fboundp 'eshell-send-input))
      (eshell-send-input))
     ((and (derived-mode-p 'comint-mode)  (fboundp 'comint-send-input))
      (comint-send-input))))

  (advice-add #'corfu-insert :after #'corfu-send-shell)

  (mapc #'evil-declare-ignore-repeat
        '(corfu-next
          corfu-previous
          corfu-first
          corfu-last))

  (mapc #'evil-declare-change-repeat
        '(corfu-insert
          corfu-insert-exact
          corfu-complete))

  (global-set-key (kbd "M-p") 'completion-at-point))



;; YASnippet: snippets
(use-package yasnippet
  :ensure t
  :defer t
  :commands (yas-hippie-try-expand yas-insert-snippet yas-visit-snippet-file yas-new-snippet)
  :diminish yas-minor-mode
  :init
  ;; expand snippets with hippie expand
  (add-to-list 'hippie-expand-try-functions-list 'yas-hippie-try-expand)

  ;; free up the binding for a prefix
  (global-set-key (kbd "M-y") nil)
  (global-set-key (kbd "M-y i") 'yas-insert-snippet)
  (global-set-key (kbd "M-y e") 'yas-visit-snippet-file)
  (global-set-key (kbd "M-y n") 'yas-new-snippet)

  (evil-define-key 'normal 'global
    (kbd "<leader>is") 'yas-insert-snippet)

  :config
  (add-to-list 'yas-snippet-dirs (expand-file-name "snippets" mb-dotfiles-dir) t)
  (setq
   yas-verbosity          2
   yas-wrap-around-region t)

  ;; Remove GUI dropdown prompt (prefer ivy/helm)
  (delq 'yas-dropdown-prompt yas-prompt-functions)

  ;; disable `yas-expand` on TAB
  (define-key yas-minor-mode-map (kbd "<tab>") nil)
  (define-key yas-minor-mode-map (kbd "TAB") nil))

(use-package consult-yasnippet
  :after (yasnippet)
  :ensure t
  :defer t
  :commands (consult-yasnippet consult-yasnippet-visit-snippet-file)
  :init
  (global-set-key (kbd "M-y i") 'consult-yasnippet)
  (global-set-key (kbd "M-y e") 'consult-yasnippet-visit-snippet-file)

  (evil-define-key 'normal 'global
    (kbd "<leader>is") 'consult-yasnippet))

(use-package yasnippet-snippets
  :after (yasnippet)
  :ensure t
  :config
  (yasnippet-snippets-initialize)
  (yas-global-mode))



;; Correct word at point
(use-package flyspell-correct
  :ensure t
  :defer t
  :commands (flyspell-correct-at-point)
  :init
  (global-set-key [f8]    'flyspell-correct-at-point))



;; EditorConfig
(use-package editorconfig
  :ensure t
  :defer t
  :diminish editorconfig-mode
  :init
  (add-hook 'prog-mode-hook 'editorconfig-mode))



;; Anzu: show current search match/total matches
(use-package anzu
  :ensure t
  :diminish anzu-mode
  :init
  (global-anzu-mode t))

(use-package evil-anzu
  :after (evil anzu)
  :ensure t)



;; Show available keybindings in a separate window
(use-package which-key
  :ensure t
  :diminish which-key-mode
  :bind (("C-h w"            . 'which-key-show-major-mode)
         ("C-h W"            . 'which-key-show-top-level))
  :init
  (setq
   which-key-compute-remaps t
   which-key-allow-multiple-replacements t
   which-key-sort-order 'which-key-key-order-alpha)

  (which-key-mode)

  (push '((nil . "\\`evil-") . (nil . "😈-")) which-key-replacement-alist)
  (push '((nil . "\\`evil-collection-unimpaired-\\(.*\\)") . (nil . "😈-cu-\\1")) which-key-replacement-alist)
  (push '(("RET" . nil) . ("⏎" . nil)) which-key-replacement-alist))



;; Helpful: a better *help* buffer
(use-package helpful
  :ensure t
  :commands helpful--read-symbol
  :hook (helpful-mode . visual-line-mode)
  :init
  ;; Make `apropos' et co search more extensively. They're more useful this way.
  (setq apropos-do-all t)

  (global-set-key [remap describe-function] #'helpful-callable)
  (global-set-key [remap describe-command]  #'helpful-command)
  (global-set-key [remap describe-variable] #'helpful-variable)
  (global-set-key [remap describe-key]      #'helpful-key)
  (global-set-key [remap describe-symbol]   #'helpful-symbol))



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



;; Rainbow-mode: highlight colors in text (e.g "red" or #3332F3)
(use-package rainbow-mode
  :ensure t
  :defer t
  :hook ((web-mode . rainbow-mode)
         (css-mode . rainbow-mode)
         (scss-mode . rainbow-mode)
         (js-mode . rainbow-mode))
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
  :diminish highlight-indentation-current-column-mode
  :init
  (add-hook 'prog-mode-hook 'highlight-indentation-current-column-mode)
  (add-hook 'yaml-mode-hook 'highlight-indentation-current-column-mode)
  :config
  (set-face-background 'highlight-indentation-face (face-background 'highlight))
  (set-face-background 'highlight-indentation-current-column-face (face-background 'highlight)))



;; highlight todos
(use-package hl-todo
  :ensure t
  :defer t
  :init (add-hook 'prog-mode-hook 'hl-todo-mode))



;; Transient: menus, used by magit and other packages
(use-package transient
  :ensure t
  :init
  ;; Must be set early to prevent ~/.emacs.d/transient from being created
  (setq transient-levels-file  (expand-file-name "transient/levels.el" mb-save-path)
        transient-values-file  (expand-file-name "transient/values.el" mb-save-path)
        transient-history-file (expand-file-name "transient/history.el" mb-save-path))

  :config
  ;; Close transient with ESC
  (define-key transient-map [escape] #'transient-quit-one))



;; Magit: UI for git
(use-package magit
  :ensure t
  :defer t
  :bind
  (("<leader>gs" . 'magit-status)
   ("<leader>gl" . 'magit-log-all)
   ("<leader>gL" . 'magit-log-buffer-file)
   ("<leader>gb" . 'magit-blame))

  :config
  (setq vc-follow-symlinks nil

        ;; open magit status in same window as current buffer
        magit-status-buffer-switch-function 'switch-to-buffer
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
        magit-set-upstream-on-push 'askifnotset

        transient-default-level 5
        transient-display-buffer-action '(display-buffer-below-selected)

        magit-diff-refine-hunk t ; show granular diffs in selected hunk
        ;; Don't display parent/related refs in commit buffers; they are rarely
        ;; helpful and only add to runtime costs.
        magit-revision-insert-related-refs nil)

  (add-hook 'magit-process-mode-hook #'goto-address-mode)

  ;; make <leader> work in magit
  (define-key magit-mode-map (kbd "SPC") nil)
  (define-key magit-diff-mode-map (kbd "SPC") nil)

  (define-key magit-mode-map (kbd "M-w") nil)

  ;; make M-tab work in magit status
  (evil-define-key 'normal magit-mode-map [M-tab] 'mb/alternate-buffer)

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
  :defer 0.5
  :config
  (setq diff-hl-draw-borders nil)
  (add-hook 'dired-mode-hook 'diff-hl-dired-mode)

  (evil-define-key 'normal 'global
    (kbd "]c") 'diff-hl-next-hunk
    (kbd "[c") 'diff-hl-previous-hunk
    (kbd "<leader>gr") 'diff-hl-revert-hunk
    (kbd "<leader>gd") 'diff-hl-diff-goto-hunk)

  (add-hook 'magit-pre-refresh-hook  'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)

  ;; UX: Don't delete the current hunk's indicators while we're editing
  ;; https://github.com/doomemacs/doomemacs/blob/master/modules/ui/vc-gutter/config.el#L204
  (add-hook 'diff-hl-flydiff-mode-hook
            (defun +vc-gutter-init-flydiff-mode-h ()
              (if (not diff-hl-flydiff-mode)
                  (remove-hook 'evil-insert-state-exit-hook #'diff-hl-flydiff-update)
                (add-hook 'evil-insert-state-exit-hook #'diff-hl-flydiff-update))))

  (diff-hl-flydiff-mode)

  ;; there is no fringe in terminal emacs, so use margins
  (unless (display-graphic-p)
    (diff-hl-margin-mode))

  (global-diff-hl-mode))



;; Treemacs: file tree sidebar
(use-package treemacs
  :ensure t
  :defer t
  :bind (("<leader>tt" . 'treemacs)
         ("M-t" . 'treemacs-select-window)
         ("<f4>" . 'treemacs))
  :init
  (setq treemacs-follow-after-init t
        treemacs-is-never-other-window nil
        treemacs-sorting 'alphabetic-case-insensitive-asc
        treemacs-persist-file (expand-file-name "treemacs-persist" mb-save-path)
        treemacs-last-error-persist-file (expand-file-name "treemacs-last-error-persist" mb-save-path))

  :config
  ;; Don't follow the cursor (it's more disruptive/jarring than helpful as a default)
  (treemacs-follow-mode -1)
  (treemacs-project-follow-mode t))

;; Treemacs integration with evil
(use-package treemacs-evil
  :ensure t
  :after (treemacs evil))

;; Treemacs integration with magit
(use-package treemacs-magit
  :ensure t
  :after (treemacs magit))

;; Treemacs integration with lsp
(use-package lsp-treemacs
  :ensure t
  :after (treemacs lsp))



;; Download tree-sitter grammars
(use-package treesit-auto
  :ensure t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (setq treesit-font-lock-level 4)
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode)

  (add-hook 'hack-local-variables-hook
            (lambda () (when (derived-mode-p 'ts-mode) (lsp))))

  (add-hook 'tsx-ts-mode-hook #'lsp-deferred)
  (add-hook 'js-ts-mode-hook #'lsp-deferred)
  (add-hook 'typescript-ts-mode-hook #'lsp-deferred)
  (add-hook 'rust-ts-mode-hook #'lsp-deferred)
  (add-hook 'yaml-ts-mode-hook #'lsp-deferred) ;; https://github.com/redhat-developer/yaml-language-server
  )



;; Language server protocol
(use-package lsp-mode
  :ensure t
  :diminish lsp-mode
  :defer t
  :hook (lsp-mode . lsp-enable-which-key-integration)
  :init
  (setq lsp-session-file (expand-file-name "lsp-session-v1" mb-save-path)
        lsp-keymap-prefix "s-l"
        lsp-idle-delay 0.6
        lsp-keep-workspace-alive nil
        lsp-enable-suggest-server-download nil
        lsp-enable-file-watchers nil
        lsp-auto-execute-action nil

        lsp-diagnostics-provider :flycheck
        lsp-diagnostic-clean-after-change t

        lsp-inlay-hint-enable t

        lsp-rust-analyzer-proc-macro-enable t
        lsp-rust-analyzer-cargo-load-out-dirs-from-check t
        lsp-rust-analyzer-call-info-full t
        lsp-rust-build-on-save t

        lsp-javascript-display-return-type-hints t
        lsp-javascript-display-variable-type-hints t
        lsp-javascript-display-parameter-type-hints t

        lsp-eldoc-enable-hover t
        lsp-eldoc-render-all nil
        lsp-signature-render-documentation t
        lsp-signature-doc-lines 4 ;; render everything

        lsp-enable-folding nil
        lsp-enable-imenu t
        lsp-enable-indentation nil
        lsp-enable-links t
        lsp-enable-on-type-formatting  nil
        lsp-enable-symbol-highlighting nil
        lsp-enable-text-document-color t
        lsp-enable-xref t

        lsp-enable-snippet nil

        lsp-lens-enable nil

        lsp-semantic-tokens-enable t

        lsp-completion-default-behaviour :insert
        lsp-completion-provider (if mb-use-company :capf :none)
        lsp-completion-show-detail t
        lsp-completion-show-kind t

        lsp-modeline-code-actions-segments '(count name)

        lsp-headerline-breadcrumb-enable t
        lsp-headerline-breadcrumb-segments '(symbols)

        lsp-eslint-server-command '("vscode-eslint-language-server" "--stdio")) ;; https://github.com/hrsh7th/vscode-langservers-extracted
  :config
  (when mb-use-company
    (defun mb/lsp-mode-setup-completion ()
      (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
            '(orderless)))
    (add-hook 'lsp-completion-mode  'mb/lsp-mode-setup-completion))

  (evil-define-key 'normal lsp-mode-map
    (kbd "gd") 'lsp-find-definition
    (kbd "<leader>la") 'lsp-execute-code-action
    (kbd "<leader>lf") 'lsp-find-references
    (kbd "<leader>lt") 'lsp-goto-type-definition
    (kbd "<leader>lr") 'lsp-rename))



;; Flycheck: lint files
(use-package flycheck
  :diminish flycheck-mode
  :ensure t
  :defer 1
  :init (global-flycheck-mode)
  :config
  (setq
   flycheck-check-syntax-automatically '(mode-enabled save)

   ;; Display errors a little quicker (default is 0.9s)
   flycheck-display-errors-delay 0.25

   flycheck-temp-prefix "FLYCHECK_XXY")

  (if (display-graphic-p)
      (setq flycheck-indication-mode 'right-fringe)
    (progn
      (setq flycheck-indication-mode 'right-margin)))

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

  (evil-define-key 'normal 'global
    (kbd "M-e 1") 'flycheck-first-error
    (kbd "M-e j") 'flycheck-next-error
    (kbd "M-e M-j") 'flycheck-next-error
    (kbd "M-e k") 'flycheck-previous-error
    (kbd "M-e M-k") 'flycheck-previous-error
    (kbd "M-e e") 'flycheck-explain-error-at-point
    (kbd "M-e v") 'flycheck-verify-setup
    (kbd "M-e L") 'mb/toggle-flyckeck-errors-list
    (kbd "M-e b") 'flycheck-buffer))

;; Flycheck-pos-tip: display flycheck error in a tooltip
(use-package flycheck-pos-tip
  :ensure t
  :after (flycheck)
  :config
  (flycheck-pos-tip-mode))



;; Eat: terminal emulator
(use-package eat
  :ensure t
  :hook (eshell-load . eat-eshell-mode))



;; Run code formatters like Prettier
(use-package apheleia
  :defer 0.5
  :ensure t
  :diminish apheleia-mode
  :init (apheleia-global-mode +1)
  :bind (("<leader>ta" . 'apheleia-mode))
  :config
  (add-hook 'apheleia-post-format-hook 'flycheck-buffer)

  (setf (alist-get 'prettier apheleia-formatters)
        '("npx" "prettier" "--stdin-filepath" filepath))
  (setf (alist-get 'prettier-json apheleia-formatters)
        '("npx" "prettier" "--stdin-filepath" filepath "--parser=json")))



;; Robby mode: interact with OpenAI
(use-package robby-mode
  :if mb-openai-api-key
  :init
  (if (not (package-installed-p 'robby))
      (package-vc-install "https://github.com/stevemolitor/robby"))
  :defer t
  :bind (("<leader>ar" . 'robby-commands)
         ("<leader>aa" . 'robby-chat))
  :custom
  ((robby-openai-api-key mb-openai-api-key))
  :config
  (robby-mode)
  (diminish 'robby-mode "🤖")

  ;; load robby-transient so that robby-api-options command becomes available
  (require 'robby-transients)

  (add-hook 'robby-chat-mode-hook (lambda () (setq-local markdown-hide-markup-in-view-modes nil)))

  (define-key robby-chat-mode-map (kbd "v") nil t)

  (evil-define-key 'normal robby-chat-mode-map
    (kbd "a") 'robby-chat
    (kbd "q") 'kill-this-buffer
    (kbd "<leader>mm") 'robby-commands))



;; Dall-E-shell: talk with dall-e
(use-package dall-e-shell
  :if mb-openai-api-key
  :after chatgpt-shell
  :ensure t
  :defer
  :bind ("<leader>ad" . 'dall-e-shell)
  :custom
  ((dall-e-shell-welcome-function nil)
   (dall-e-shell-openai-key       mb-openai-api-key)))



;; Gptel: interact with chatgpt and other LLMs
(use-package gptel
  :after transient
  :if mb-openai-api-key
  :ensure t
  :custom
  ((gptel-api-key mb-openai-api-key)
   (gptel-max-tokens 2500)
   (gptel-model "gpt-4-turbo")
   (gptel-crowdsourced-prompts-file (expand-file-name "gptel-crowdsourced-prompts.csv" mb-save-path)))
  :bind ("C-x C-a" . 'gptel-send)
  :config
  (add-hook 'gptel-pre-response-hook 'evil-normal-state)
  (add-hook 'gptel-post-stream-hook 'gptel-auto-scroll)
  (add-hook 'gptel-post-response-functions 'gptel-end-of-response)

  (evil-define-key 'normal 'global
    (kbd "<leader>ae") 'gptel-send
    (kbd "<leader>ag") 'gptel)

  (define-key gptel-mode-map (kbd "<leader>mm") 'gptel-menu)
  (define-key gptel-mode-map (kbd "M-RET") 'gptel-send)
  (define-key gptel-mode-map (kbd "M-<return>") 'gptel-send))



;; Codeium: AI autocomplete
(use-package codeium
  :disabled
  :init
  (if (not (package-installed-p 'codeium))
      (package-vc-install "https://github.com/Exafunction/codeium.el")))


;; ---------------------------------------- BUILT-IN LANGUAGES


;; Makefile mode
(use-package makefile-mode
  :no-require t
  :init
  (defun mb/use-tabs ()
    "Use tabs."
    (setq tab-width        8
          indent-tabs-mode 1))

  (add-hook 'makefile-mode-hook 'mb/use-tabs)
  (add-hook 'makefile-bsdmake-mode-hook 'mb/use-tabs))


;; Python mode
(use-package python
  :disabled
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

  (add-hook 'java-mode-hook (lambda ()
                              ;; disable auto-indent
                              (electric-indent-local-mode 0)))

  (message "mb: CC MODE"))



;; XML
(use-package nxml-mode
  :mode ("\\.xml\\'" . nxml-mode)
  :mode ("\\.svg\\'" . nxml-mode)
  :config

  (setq nxml-child-indent  mb-tab-size)

  (message "mb: nXML MODE"))



;; Emacs Lisp
(use-package elisp-mode
  :init
  (evil-define-key 'normal emacs-lisp-mode-map
    (kbd "<leader>meb") 'eval-buffer
    (kbd "<leader>mer") 'eval-region
    (kbd "<leader>mes") 'eval-last-sexp)

  (add-hook 'emacs-lisp-mode-hook
            (lambda()
              (setq mode-name "ELisp")))
  (add-hook 'lisp-interaction-mode-hook
            (lambda() (setq mode-name "λ"))))



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



;; ---------------------------------------- 3rd PARTY LANGUAGES


;; Justfile mode syntax
(use-package just-mode
  :ensure t
  :defer t)

;; Run justfile recipes
(use-package justl
  :ensure t
  :defer t
  :bind (("<leader>pj" . 'justl))
  :config
  (evil-define-key 'normal justl-mode-map
    (kbd "<RET>") 'justl-exec-recipe
    (kbd "e")     'justl-exec-recipe
    (kbd "E")     'justl-exec-eshell
    (kbd "?")     'justl-help-popup
    (kbd "w")     'justl-no-exec-eshell))


;; Markdown
(use-package markdown-mode
  :ensure t
  :defer t
  :config
  (add-hook 'markdown-mode-hook 'flyspell-mode)
  (message "mb: MARKDOWN MODE"))

;; Markdown treesit mode
(use-package markdown-ts-mode
  :disabled
  :ensure t
  :mode ("\\.md\\'" . markdown-ts-mode)
  :defer t
  :config
  (add-hook 'markdown-ts-mode-hook 'flyspell-mode)
  (message "mb: MARKDOWN-TS MODE"))



;; Lua mode
(use-package lua-mode
  :ensure t
  :defer t
  :config
  (message "mb: LUA MODE"))



;; Groovy mode (for Jenkinsfile)
(use-package groovy-mode
  :disabled
  :ensure t
  :defer t
  :config
  (message "mb: GROOVY MODE"))



;; Dockerfile mode
(use-package dockerfile-mode
  :disabled
  :ensure t
  :defer t
  :config
  (message "mb: DOCKERFILE MODE"))



;; Graphql mode
(use-package graphql-mode
  :disabled
  :ensure t
  :defer t
  :config
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
