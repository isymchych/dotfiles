;;; init.el --- main emacs config file
;;; Commentary:
;; * Emacs Prelude https://github.com/bbatsov/prelude
;; * Emacs Graphene https://github.com/rdallasgray/graphene
;; * Spacemacs https://github.com/syl20bnr/spacemacs
;; * Ohai https://github.com/bodil/ohai-emacs
;;; Code:



;; ---------------------------------------- VARS


(defvar mb-is-mac-os (eq system-type 'darwin))
(defvar mb-is-linux (eq system-type 'gnu/linux))

;; base configs dir
(defvar mb-dotfiles-dir (file-name-directory (or (buffer-file-name) load-file-name)))

(defvar mb-customizations-file (expand-file-name "custom.el" mb-dotfiles-dir))

;; dir for temp files
(defvar mb-save-path (expand-file-name "save-files/" mb-dotfiles-dir))

(defvar mb-terminal (getenv "TERMINAL"))

(defvar mb-font "jetbrains mono-14")

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
(setq package-enable-at-startup nil)

(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)

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

 enable-recursive-minibuffers t

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
  (let ((commands (if mb-is-mac-os
                      (-concat (list "open" "-a" mb-terminal default-directory) args)
                    (-concat (list mb-terminal) args))))
    (apply 'mb/launch-application commands)))

(defun mb/projectile-base-term (&rest args)
  "Launches terminal in projectile root with ARGS."
  (interactive)
  (message default-directory)
  (let ((default-directory (projectile-project-root)))
    (apply 'mb/terminal args)))

(defun mb/company-complete-common-or-selection ()
  "Complete common part if there is one, or insert selected candidate."
  (interactive)
  (when (company-manual-begin)
    (let ((tick (buffer-chars-modified-tick)))
      (call-interactively 'company-complete-common)
      (when (eq tick (buffer-chars-modified-tick))
        (call-interactively 'company-complete-selection)))))


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
    (mb/projectile-base-term "-e" command "--hold")))

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

;; @see https://emacs.stackexchange.com/questions/653/how-can-i-find-out-in-which-keymap-a-key-is-bound
(defun mb/key-binding-at-point (key)
  "Find keymap by KEY."
  (mapcar (lambda (keymap) (when (keymapp keymap)
                             (lookup-key keymap key)))
          (list
           ;; More likely
           (get-text-property (point) 'keymap)
           (mapcar (lambda (overlay)
                     (overlay-get overlay 'keymap))
                   (overlays-at (point)))
           ;; Less likely
           (get-text-property (point) 'local-map)
           (mapcar (lambda (overlay)
                     (overlay-get overlay 'local-map))
                   (overlays-at (point))))))

(defun mb/locate-key-binding (key)
  "Determine in which keymap KEY is defined."
  (interactive "kPress key: ")
  (let ((ret
         (list
          (mb/key-binding-at-point key)
          (minor-mode-key-binding key)
          (local-key-binding key)
          (global-key-binding key))))
    (when (called-interactively-p 'any)
      (message "At Point: %s\nMinor-mode: %s\nLocal: %s\nGlobal: %s"
               (or (nth 0 ret) "")
               (or (mapconcat (lambda (x) (format "%s: %s" (car x) (cdr x)))
                              (nth 1 ret) "\n             ")
                   "")
               (or (nth 2 ret) "")
               (or (nth 3 ret) "")))
    ret))


(defun mb/ensure-bin-tool-exists (name)
  "Check if bin tool `NAME' exists and show warning if it doesn't."
  (if (executable-find name)
      (message "MB: found required bin tool %s" name)
    (warn "MB: executable %s not found!" name)))


(defmacro mb/load-theme! (theme)
  "Load THEME even when starting Emacs as a daemon."
  `(if (daemonp)
       (add-hook 'after-make-frame-functions
                 (lambda (frame)
                   (select-frame frame)
                   (load-theme ,theme t)))
     (load-theme ,theme t)))


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



;; Nord theme https://github.com/arcticicestudio/nord-emacs
(use-package nord-theme
  :disabled
  :ensure t
  :config
  (mb/load-theme! 'nord))


(use-package solarized-theme
  :disabled
  :ensure t
  :config
  (mb/load-theme! 'solarized-light))



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
  (setq undo-tree-visualizer-timestamps t
        undo-tree-visualizer-diff       t))


;; evil uses dabbrev and hippie-expand

;; do not split words on _ and -
(require 'dabbrev)
(setq dabbrev-abbrev-char-regexp "[a-zA-Z0-9?!_\-]")

;; Hippie expand is dabbrev expand on steroids
(require 'hippie-exp)
(setq hippie-expand-try-functions-list '(yas-hippie-try-expand
                                         try-expand-dabbrev
                                         try-expand-dabbrev-all-buffers
                                         try-expand-dabbrev-from-kill
                                         try-complete-file-name-partially
                                         try-complete-file-name
                                         try-expand-all-abbrevs
                                         try-expand-list
                                         try-expand-line))



;; Evil: vim mode

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
               (setq evil-cjk-word-separating-categories (default-value 'evil-cjk-word-separating-categories)))))

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

  ;; insert tabs only in emacs state
  (define-key evil-motion-state-map (kbd "TAB")
    (lambda () (interactive) (if (evil-emacs-state-p) (indent-for-tab-command) (evil-jump-forward))))

  ;; insert newline only in emacs state
  (define-key evil-motion-state-map (kbd "RET")
    (lambda () (interactive) (when (evil-emacs-state-p) (newline))))

  (define-key evil-motion-state-map (kbd " ") nil)

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

  (add-hook 'evil-insert-state-exit-hook 'company-abort)
  )

;; integration of evil with various packages
(use-package evil-collection
  :after evil
  :ensure t
  :custom
  (evil-collection-setup-minibuffer nil)
  :init
  (evil-collection-init))

;; vim leader feature
(use-package evil-leader
  :after evil
  :ensure t
  :config
  (setq evil-leader/in-all-states     t
        evil-leader/non-normal-prefix "M-")
  (global-set-key (kbd "M-<SPC>") evil-leader--default-map)
  (evil-leader/set-leader "<SPC>")
  (global-evil-leader-mode))

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
  :ensure t)

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



;; Ido mode: text menu item selecting
(use-package ido
  :config
  (setq
   ido-enable-prefix          nil
   ido-enable-flex-matching   t
   ido-create-new-buffer      'always
   ido-use-filename-at-point  'guess

   ;; disable ido faces to see flx highlights
   ido-use-faces                nil

   ido-cannot-complete-command  'ido-next-match

   ;; make ido use completion-ignored-extensions
   ido-ignore-extensions        t

   ido-max-prospects 10

   ;; do not complete automatically unique result on tab
   ido-confirm-unique-completion t

   ;; ignore system buffers in ido-switch-buffer
   ido-ignore-buffers '("^[\s-]*\\*")

   ido-save-directory-list-file  (expand-file-name  "ido.hist"  mb-save-path)
   ido-default-file-method       'selected-window
   ido-auto-merge-work-directories-length  -1)

  (add-hook 'ido-setup-hook
            (lambda()
              (define-key ido-completion-map (kbd "<backtab>") 'ido-prev-match)
              (define-key ido-completion-map (kbd "C-w") 'ido-delete-backward-updir)
              (define-key ido-file-dir-completion-map (kbd "C-w") 'ido-delete-backward-updir)
              (define-key ido-completion-map (kbd "M-j") 'ido-next-match)
              (define-key ido-completion-map (kbd "M-k") 'ido-prev-match))))

;; smarter fuzzy matching for ido
(use-package flx-ido
  :after ido
  :ensure t
  :config (flx-ido-mode 1))

;; vertical menu for ido
(use-package ido-vertical-mode
  :after ido
  :ensure t
  :config (ido-vertical-mode 1))



;; Ivy
(use-package ivy
  :ensure t
  :diminish ivy-mode
  :bind*
  ("M-`" . 'ivy-resume)
  :config
  (ivy-mode 1)

  (setq ivy-re-builders-alist '((t . ivy--regex-ignore-order)))

  (setq
   ivy-initial-inputs-alist nil ; remove the ^ (caret) symbol from the input
   ivy-use-virtual-buffers t
   ivy-count-format "(%d/%d) "
   ivy-wrap t
   ivy-height 25)

  (define-key ivy-minibuffer-map (kbd "M-j") 'ivy-next-line)
  (define-key ivy-minibuffer-map (kbd "M-k") 'ivy-previous-line)
  (define-key ivy-minibuffer-map (kbd "M-<return>") 'ivy-immediate-done)
  (define-key ivy-minibuffer-map (kbd "C-j") 'ivy-immediate-done)

  (evil-leader/set-key
    "`" 'ivy-resume))


;; show references to variables in ivy
(use-package ivy-xref
  :after ivy
  :ensure t
  :init
  ;; xref initialization is different in Emacs 27 - there are two different
  ;; variables which can be set rather than just one
  (when (>= emacs-major-version 27)
    (setq xref-show-definitions-function #'ivy-xref-show-defs))
  ;; Necessary in Emacs <27. In Emacs 27 it will affect all xref-based
  ;; commands other than xref-find-definitions (e.g. project-find-regexp)
  ;; as well
  (setq xref-show-xrefs-function #'ivy-xref-show-xrefs))

;; counsel use it for M-x
(use-package smex
  :ensure t
  :bind*
  ("C-M-x" . 'smex-major-mode-commands)
  :config
  (setq smex-save-file (expand-file-name  "smex-items"  mb-save-path)))

;; writable grep for counsel
(use-package wgrep
  :ensure t)

(use-package counsel
  :after ivy
  :ensure t
  :bind*
  ("M-x" . 'counsel-M-x)
  ("C-x C-f" . 'counsel-find-file)
  ("<f1> f" . 'counsel-describe-function)
  ("<f1> v" . 'counsel-describe-variable)
  ("<f1> i" . 'counsel-info-lookup-symbol)
  ("<f1> u" . 'counsel-unicode-char)
  :config
  (setq counsel-yank-pop-truncate-radius 5)
  (ivy-configure 'counsel-yank-pop
    :height 25)
  (evil-leader/set-key
    "SPC" 'counsel-recentf
    "r" 'counsel-recentf
    "y" 'counsel-yank-pop
    "ff" 'counsel-find-file
    "bb" 'counsel-ibuffer
    ))



;; Avy: jump to char/line
(use-package avy
  :ensure t
  :config
  (evil-leader/set-key
    "jj" 'evil-avy-goto-char-timer
    "jl" 'evil-avy-goto-line))



;; Projectile: project management tool
(use-package projectile
  :after ivy
  :ensure t
  :init
  ;; variables must be set BEFORE requiring projectile
  (setq-default
   projectile-cache-file          (expand-file-name "projectile.cache"         mb-save-path)
   projectile-known-projects-file (expand-file-name "projectile-bookmarks.eld" mb-save-path)

   projectile-mode-line          '(:eval (format " [%s]" (projectile-project-name)))

   projectile-completion-system  'ivy
   projectile-sort-order         'modification-time)

  :config
  (projectile-mode)

  (evil-leader/set-key
    "pD" 'projectile-dired
    "pe" 'projectile-run-eshell
    "pr" 'projectile-recentf
    "pR" 'projectile-replace
    "pk" 'projectile-kill-buffers))


(use-package counsel-projectile
  :after projectile
  :ensure t
  :config
  (mb/ensure-bin-tool-exists "rg") ; use ripgrep
  (defun mb/counsel-projectile-rg-dwim ()
    "Search in the project with ag using thing at the point"
    (interactive)
    (let ((counsel-projectile-rg-initial-input '(let ((value (projectile-symbol-or-selection-at-point)))
                                                  (if (string= value "")
                                                      value
                                                    (shell-quote-argument value)))))
      (counsel-projectile-rg)))

  (evil-leader/set-key
    "pd" 'counsel-projectile-find-dir
    "pf" 'counsel-projectile-find-file
    "pF" 'counsel-projectile-find-file-dwim
    "ps" 'counsel-projectile-rg
    "pS" 'mb/counsel-projectile-rg-dwim
    "pb" 'counsel-projectile-switch-to-buffer
    "pp" 'counsel-projectile-switch-project
    ))



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
   company-minimum-prefix-length     2
   company-echo-delay                0
   company-auto-commit               nil
   company-selection-wrap-around     t

   company-dabbrev-ignore-case       nil
   company-dabbrev-downcase          nil

   company-require-match             nil
   company-tooltip-align-annotations t
   company-show-quick-access         t)

  ;; Sort completion candidates that already occur in the current
  ;; buffer at the top of the candidate list.
  (setq company-transformers '(company-sort-by-occurrence))

  (delete 'company-xcode company-backends)
  (delete 'company-ropemacs company-backends)

  (global-company-mode 1)

  ;; (define-key company-active-map (kbd "TAB") 'mb/company-complete-common-or-selection)
  ;; (define-key company-active-map (kbd "<tab>") 'mb/company-complete-common-or-selection)
  (define-key company-active-map (kbd "C-w") nil)
  (define-key company-active-map (kbd "C-j") nil)

  ;; (define-key company-active-map (kbd "<f1>") nil)

  (global-set-key (kbd "M-p") 'company-manual-begin))



;; YASnippet: snippets
(use-package yasnippet
  :ensure t
  :diminish yas-minor-mode
  :config
  (setq yas-verbosity                       1
        yas-wrap-around-region              t)

  (yas-global-mode)

  ;; disable `yas-expand` on TAB
  (define-key yas-minor-mode-map (kbd "<tab>") nil)
  (define-key yas-minor-mode-map (kbd "TAB") nil)

  (defun mb/yas-next-field ()
    "Switch to next yasnippet field.
Clear field placeholder if field was not modified."
    (interactive)
    (let ((field (and yas--active-field-overlay
                      (overlay-buffer yas--active-field-overlay)
                      (overlay-get yas--active-field-overlay 'yas--field))))
      (if (and field
               (not (yas--field-modified-p field))
               (eq (point) (marker-position (yas--field-start field))))
          (progn
            (yas--skip-and-clear field)
            (yas-next-field 1))
        (yas-next-field-or-maybe-expand))))

  (defun mb/complete-common-or-yas-next-field ()
    "Complete common prefix in company-mode or switch to next yasnippet field."
    (interactive)
    (if (> (or company-candidates-length 0) 0)
        (mb/company-complete-common-or-selection)
      (yas-next-field)))

  (defun mb/complete-selection-or-yas-next-field ()
    "Complete selection in company-mode or switch to next yasnippet field."
    (interactive)
    (if (> (or company-candidates-length 0) 0)
        (company-complete-selection)
      (mb/yas-next-field)))

  (setq yas-keymap
        (let ((map (make-sparse-keymap)))
          (define-key map (kbd "RET")   'mb/complete-selection-or-yas-next-field)
          (define-key map [return]      'mb/complete-selection-or-yas-next-field)

          (define-key map (kbd "TAB")   'mb/complete-common-or-yas-next-field)
          (define-key map (kbd "<tab>") 'mb/complete-common-or-yas-next-field)

          (define-key map (kbd "<backtab>") 'yas-prev-field)
          (define-key map (kbd "C-g") 'yas-abort-snippet)
          map)))



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
  (global-set-key [M-f8]  'flyspell-buffer))


(use-package flyspell-correct-ivy
  :after flyspell
  :ensure t
  :bind*
  ("<f8>" . 'flyspell-correct-at-point)
  :init
  (setq flyspell-correct-interface #'flyspell-correct-ivy))



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

  (evil-leader/set-key "le" 'mb/reload-editorconfig))



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


;; Ace-window: switch windows
(use-package ace-window
  :ensure t
  :bind*
  ("M-w" . ace-window)
  :config
  (defun mb/other-window ()
    (other-window 1))
  (setq aw-keys '(?a ?s ?d ?f ?g ?j ?k ?l))
  (setq aw-scope 'frame)
  (setq aw-dispatch-always t)
  (setq aw-dispatch-alist
        '((?w mb/other-window)
          (?q evil-window-delete) ; delete focused window
          (?Q aw-delete-window " Ace - Delete Window") ; select which window to delete
          (?p aw-flip-window) ; focus previous window
          (?m aw-swap-window " Ace - Swap Window")

          (?v aw-split-window-vert " Ace - Split Vert Window")
          (?h aw-split-window-horz " Ace - Split Horz Window")

          (?o delete-other-windows)
          (?O delete-other-windows " Ace - Maximize Window"))))



;; Uniquify: unique buffer names
(require 'uniquify)
(setq uniquify-buffer-name-style 'forward
      uniquify-separator "/"
      ;; rename after killing uniquified
      uniquify-after-kill-buffer-p t
      ;; don't muck with special buffers
      uniquify-ignore-buffers-re "^\\*")



;; Show available keybindings in a separate window
(use-package which-key
  :ensure t
  :diminish which-key-mode
  :init
  (which-key-mode))



;; IBuffer (local)
;; use ibuffer on C-x C-b
(defalias 'list-buffers 'ibuffer)
;; use ibuffer as default buffers list (:ls)
(defalias 'buffer-menu 'ibuffer)

(use-package ibuffer
  :bind ([f2] . ibuffer)
  :config
  (define-key ibuffer-mode-map [f2]      'ibuffer-quit)
  (define-key ibuffer-mode-map (kbd "j") 'ibuffer-forward-line)
  (define-key ibuffer-mode-map (kbd "k") 'ibuffer-backward-line)
  (define-key ibuffer-mode-map (kbd "J") 'ibuffer-jump-to-buffer)
  (define-key ibuffer-mode-map (kbd "l") 'ibuffer-visit-buffer)
  (define-key ibuffer-mode-map (kbd "v") 'ibuffer-toggle-marks))



;; Saveplace: save cursor position
(require 'saveplace)
(setq-default save-place t
              save-place-file (expand-file-name "saveplace" mb-save-path))



;; Delete-selection mode: delete seleted text when typing
(delete-selection-mode t)



;; Subword-mode: navigate in CamelCase words
;; http://ergoemacs.org/emacs/emacs_subword-mode_superword-mode.html
(global-subword-mode t)
(diminish 'subword-mode)



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
(use-package dired
  :defer t
  :config
  (require 'dired-x)

  (setq dired-auto-revert-buffer t)    ; automatically revert buffer

  (evil-set-initial-state 'wdired-mode 'normal)
  (evil-leader/set-key "d" 'dired-jump)

  (defun mb/dired-up-directory ()
    "Take dired up one directory, but behave like dired-find-alternate-file."
    (interactive)
    (let ((old (current-buffer)))
      (dired-up-directory)
      (kill-buffer old)))

  (evil-define-key 'normal dired-mode-map
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
  :bind*
  ("M-e 1" . flycheck-first-error)
  ("M-e j" . flycheck-next-error)
  ("M-e M-j" . flycheck-next-error)
  ("M-e k" . flycheck-previous-error)
  ("M-e M-k" . flycheck-previous-error)
  ("M-e l" . mb/toggle-flyckeck-errors-list)
  ("M-e b" . flycheck-buffer)
  :init
  (setq flycheck-indication-mode 'right-margin)
  (global-flycheck-mode)

  :config
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
      (flycheck-list-errors))))



;; Expand-region: expand selection like C-w in intellij idea
(use-package expand-region
  :ensure t
  :defer t
  :init
  (evil-leader/set-key "w" 'er/expand-region)
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
  (evil-leader/set-key
    "gs" 'magit-status
    "gl" 'magit-log-all
    "gL" 'magit-log-buffer-file
    "gb" 'magit-blame)

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
  :init (evil-leader/set-key "gt" 'git-timemachine)
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

  (evil-leader/set-key
    "gj" 'diff-hl-next-hunk
    "gk" 'diff-hl-previous-hunk
    "gr" 'diff-hl-revert-hunk
    "gd" 'diff-hl-diff-goto-hunk)

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
  (setq lsp-keymap-prefix "s-l"
        lsp-idle-delay 0.6
        lsp-keep-workspace-alive nil
        lsp-rust-analyzer-server-display-inlay-hints nil
        ;; lsp-rust-analyzer-cargo-watch-command "clippy"
        lsp-rust-server 'rust-analyzer
        lsp-rust-analyzer-proc-macro-enable t
        lsp-rust-analyzer-cargo-load-out-dirs-from-check t
        lsp-rust-build-on-save t
        lsp-enable-folding nil
        lsp-enable-snippet nil
        lsp-enable-symbol-highlighting nil
        lsp-enable-file-watchers nil
        lsp-enable-on-type-formatting  nil
        lsp-completion-provider :capf

        lsp-modeline-code-actions-segments '(count name)

        lsp-signature-render-documentation nil
        lsp-headerline-breadcrumb-enable nil
        lsp-enable-indentation nil
        lsp-enable-on-type-formatting nil

        lsp-eldoc-render-all nil
        lsp-eldoc-enable-hover t)
  :config
  (evil-leader/set-key "a" 'lsp-execute-code-action))



;; ---------------------------------------- LANGUAGES



;; Makefile mode

(defun mb/use-tabs ()
  "Use tabs."
  (setq tab-width        8
        indent-tabs-mode 1))

(add-hook 'makefile-mode-hook 'mb/use-tabs)
(add-hook 'makefile-bsdmake-mode-hook 'mb/use-tabs)



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

  (use-package prettier
    :ensure t)


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



;; XML
(use-package nxml-mode
  :mode ("\\.xml\\'" . nxml-mode)
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
(evil-leader/set-key-for-mode 'emacs-lisp-mode "meb" 'eval-buffer)
(evil-leader/set-key-for-mode 'emacs-lisp-mode "mer" 'eval-region)
(evil-leader/set-key-for-mode 'emacs-lisp-mode "mes" 'eval-last-sexp)
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
  (message "mb: ESHELL MODE"))



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

;; ---------------------------------------- GLOBAL KEYBINDINGS


;; disable input methods
(global-set-key (kbd "C-\\") nil)

;; prevent accidentally closed frames
(global-unset-key (kbd "C-x C-z"))


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

(global-set-key (kbd "C-x e")   'mb/eval-and-replace)
(global-set-key [M-tab]         'mb/prev-buffer)
(global-set-key (kbd "M-S-SPC") 'just-one-space)
(global-set-key (kbd "M-/")     'hippie-expand)

(global-set-key [f3]    'mb/toggle-verbose-mode)
(global-set-key [f4]    'mb/terminal)
(global-set-key [M-f4]  'mb/projectile-base-term)
(global-set-key [f5]    'make-frame)
(global-set-key [f6]    'mb/revert-buffer)
(global-set-key [f12]   'menu-bar-mode)


;; NOTE: m is reserved for mode-local bindings
(evil-leader/set-key
  "2"  'call-last-kbd-macro
  "q"  'evil-quit
  "n"  'mb/narrow-or-widen-dwim
  "ll" 'mb/cleanup-buffer
  "lt" 'mb/sort-columns
  "k"  'mb/kill-this-buffer
  "s"  'save-buffer
  "lm" 'evil-show-marks
  "u"  'undo-tree-visualize
  "i"  'counsel-semantic-or-imenu

  "bd" 'mb/delete-current-buffer-file
  "br" 'mb/rename-file-and-buffer
  "bs" 'scratch)

(provide 'init)
;;; init.el ends here
