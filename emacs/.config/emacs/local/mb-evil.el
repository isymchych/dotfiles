;;; mb-evil.el --- evil config file -*- lexical-binding: t; -*-
;;; Commentary:
;; * Evil guide https://github.com/noctuid/evil-guide
;;; Code:

;; Evil: vim mode
(use-package evil
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
  ;; https://github.com/syl20bnr/spacemacs/blob/a58a7d79b3713bcf693bb61d9ba83d650a6aba86/layers/%2Bspacemacs/spacemacs-defaults/packages.el#L434
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

   ;; It's infuriating that innocuous "beginning of line" or "end of line"
   ;; errors will abort macros, so suppress them:
   evil-kbd-macro-suppress-motion-error t

   ;; Only do highlighting in selected window so that Emacs has less work
   ;; to do highlighting them all.
   evil-ex-interactive-search-highlight 'selected-window

   ;; search for whole words not only for part
   evil-symbol-word-search 'symbol)

  ;; Exit to normal state after save
  (add-hook 'after-save-hook 'evil-normal-state)


  ;; PERF: Stop copying the selection to the clipboard each time the cursor
  ;; moves in visual mode. Why? Because on most non-X systems (and in terminals
  ;; with clipboard plugins like xclip.el active), Emacs will spin up a new
  ;; process to communicate with the clipboard for each movement. On Windows,
  ;; older versions of macOS (pre-vfork), and Waylang (without pgtk), this is
  ;; super expensive and can lead to freezing and/or zombie processes.
  ;;
  ;; UX: It also clobbers clipboard managers (see emacs-evil/evil#336).
  (setq evil-visual-update-x-selection-p nil)


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

  ;; in prog modes I want RET in comment to continue comment in new line
  (add-hook 'prog-mode-hook
            (lambda ()
              (when (derived-mode-p 'prog-mode)
                (define-key evil-insert-state-local-map (kbd "RET") #'default-indent-new-line))))


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
    (kbd "C-w") 'evil-delete-backward-word

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
  (which-key-add-key-based-replacements "SPC m" "Mode actions")
  (which-key-add-key-based-replacements "SPC h" "Help")
  (which-key-add-key-based-replacements "SPC p" "Project actions")
  (which-key-add-key-based-replacements "SPC g" "Git")
  (which-key-add-key-based-replacements "SPC i" "Insert")
  (which-key-add-key-based-replacements "SPC j" "Jump to")
  (which-key-add-key-based-replacements "SPC D" "current Dir")
  (which-key-add-key-based-replacements "SPC t" "Toggle")
  (which-key-add-key-based-replacements "SPC =" "Formatting actions")

  (evil-define-key '(normal visual) 'global
    (kbd "<leader>n")  'mb/narrow-or-widen-dwim)

  ;; NOTE: m is reserved for mode-local bindings
  (evil-define-key 'normal 'global
    (kbd "<leader>2")   'call-last-kbd-macro
    (kbd "<leader>q")   'evil-quit
    (kbd "<leader>k")   'mb/kill-this-buffer
    (kbd "<leader>s")   'save-buffer
    (kbd "<leader>e")   'eshell
    (kbd "<leader>d")   'dired-jump

    (kbd "<leader>jm") 'evil-show-marks
    (kbd "<leader>ji")  'imenu
    (kbd "<leader>= <SPC>") 'just-one-space
    (kbd "<leader>=s") 'sort-lines

    (kbd "<leader>ie") 'emoji-search
    (kbd "<leader>ic") 'insert-char

    (kbd "<leader>bl") 'mb/cleanup-buffer
    (kbd "<leader>bd") 'mb/delete-current-buffer-file
    (kbd "<leader>br") 'mb/rename-file-and-buffer
    (kbd "<leader>bR") 'mb/revert-buffer

    (kbd "<leader>pp") 'project-switch-project
    (kbd "<leader>pD") 'project-dired
    (kbd "<leader>pe") 'project-eshell
    (kbd "<leader>pk") 'project-kill-buffers

    (kbd "<leader>tn") 'display-line-numbers-mode
    (kbd "<leader>tf") 'mb/toggle-auto-fill-mode
    (kbd "<leader>tm") 'menu-bar-mode))

;; integration of evil with various packages
(use-package evil-collection
  :after evil
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
  :config
  (global-evil-visualstar-mode))

;; emulates surround.vim
(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))

;; match braces/tags with %
(use-package evil-matchit
  :after evil
  :config
  (global-evil-matchit-mode 1)
  (evil-add-command-properties #'evilmi-jump-items :jump t))

;; work with args in c-style functions
(use-package evil-args
  :after evil
  :init
  (define-key evil-inner-text-objects-map "a" 'evil-inner-arg)
  (define-key evil-outer-text-objects-map "a" 'evil-outer-arg))

;; text exchange operator (select, gx, select other word, gx)
(use-package evil-exchange
  :after evil
  :config
  (evil-exchange-install))

;; xml tag attribute as a text object (bound to x)
(use-package exato
  :after evil)

;; align text into columns - gl<space> or gL<space>
(use-package evil-lion
  :after evil
  :config
  (evil-lion-mode))



;; better-jumper
(with-eval-after-load 'better-jumper
  (global-set-key [remap evil-jump-forward]  #'better-jumper-jump-forward)
  (global-set-key [remap evil-jump-backward] #'better-jumper-jump-backward)

  (setq better-jumper-use-evil-jump-advice t)

  ;; Creates a jump point before killing a buffer. This allows you to undo
  ;; killing a buffer easily (only works with file buffers though; it's not
  ;; possible to resurrect special buffers).
  (advice-add #'kill-current-buffer :around #'evil-better-jumper/set-jump-a)

  ;; Create a jump point before jumping with imenu.
  (advice-add #'imenu :around #'evil-better-jumper/set-jump-a))



;; comment-dwim-2
(with-eval-after-load 'comment-dwim-2
  (define-key evil-normal-state-map "gc" 'comment-dwim-2))



;; vundo
(evil-define-key 'normal 'global (kbd "<leader>u") 'vundo)
(evil-define-key 'normal vundo-mode-map (kbd "<escape>") 'vundo-quit)



;; vertico
(evil-define-key 'normal 'global (kbd "<leader>`") 'vertico-repeat)



;; consult
(with-eval-after-load 'consult
  (global-set-key [remap evil-show-marks]               #'consult-mark)
  (global-set-key [remap evil-show-jumps]               #'evil-collection-consult-jump-list)
  (global-set-key [remap evil-show-registers]           #'consult-register)

  (evil-define-key 'normal 'global
    (kbd "<leader>r") 'consult-recent-file
    (kbd "<leader>y") 'consult-yank-from-kill-ring
    ;; (kbd "<leader>je") 'consult-flymake
    (kbd "<leader>jL") 'consult-line
    (kbd "<leader>jo") 'consult-outline
    (kbd "gb")         'consult-buffer
    (kbd "<leader>SPC") 'consult-buffer

    (kbd "<leader>Ds") 'mb/consult-ripgrep-in-current-dir
    (kbd "<leader>Df") 'mb/consult-fd-in-current-dir

    ;; project
    (kbd "<leader>pb") 'consult-project-buffer
    (kbd "<leader>ps") 'consult-ripgrep
    (kbd "<leader>pS") 'mb/consult-ripgrep-symbol-at-point
    (kbd "<leader>pf") 'consult-fd
    (kbd "<leader>pF") 'mb/consult-fd-thing-at-point))


;; consult-flycheck
(evil-define-key 'normal 'global (kbd "<leader>je") 'consult-flycheck)


;; consult-jump-project
(evil-define-key 'normal 'global (kbd "<leader>pp") 'consult-jump-project)


;; embark
(evil-define-key 'normal 'global (kbd "M-.") 'embark-act)


;; rg
(evil-define-key 'normal 'global
  (kbd "M-s R") 'rg-isearch-menu
  (kbd "M-s r") 'rg-menu
  (kbd "<leader>pr") 'rg-project)


;; avy
(evil-define-key 'normal 'global
  (kbd "<leader>jr") 'avy-resume
  (kbd "<leader>jj") 'evil-avy-goto-char-timer
  (kbd "<leader>jl") 'evil-avy-goto-line)


;; company-mode
(with-eval-after-load 'company
  (add-hook 'evil-insert-state-exit-hook 'company-abort))


;; corfu
(with-eval-after-load 'corfu
  (mapc #'evil-declare-ignore-repeat
        '(corfu-next
          corfu-previous
          corfu-first
          corfu-last))

  (mapc #'evil-declare-change-repeat
        '(corfu-insert
          corfu-insert-exact
          corfu-complete)))


;; yasnippet
(evil-define-key 'normal 'global (kbd "<leader>is") 'yas-insert-snippet)


;; consult-yasnippet
(evil-define-key 'normal 'global (kbd "<leader>is") 'consult-yasnippet)


;; evil-anzu: anzu integration for evil
(use-package evil-anzu
  :after (evil anzu))


;; which-key
(push '((nil . "\\`evil-") . (nil . "😈-")) which-key-replacement-alist)
(push '((nil . "\\`evil-collection-unimpaired-\\(.*\\)") . (nil . "😈-cu-\\1")) which-key-replacement-alist)


;; doom-modeline
(with-eval-after-load 'doom-modeline
  ;; show evil register macro while recording it
  (setq doom-modeline-always-show-macro-register t)

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
  )


;; expand-region
(evil-define-key 'normal 'global (kbd "<leader>w") 'er/expand-region)
(with-eval-after-load 'expand-region
  (evil-add-command-properties #'er/expand-region :jump t)
  (evil-add-command-properties #'er/contract-region :jump t))


;; visual-fill-column
(evil-define-key 'normal 'global (kbd "<leader>tv") 'mb/toggle-visual-fill-mode)


;; magit
(evil-define-key 'normal 'global
  (kbd "<leader>gs") 'magit-status
  (kbd "<leader>gl") 'magit-log-all
  (kbd "<leader>gL") 'magit-log-buffer-file
  (kbd "<leader>gb") 'magit-blame)
(with-eval-after-load 'magit
  ;; make <leader> work in magit
  (define-key magit-mode-map (kbd "SPC") nil)
  (define-key magit-diff-mode-map (kbd "SPC") nil)

  ;; make M-tab work in magit status
  (evil-define-key 'normal magit-mode-map [M-tab] 'mb/alternate-buffer))


;; git-timemachine
(evil-define-key 'normal 'global (kbd "<leader>gt") 'git-timemachine)
(with-eval-after-load 'git-timemachine
  (evil-make-overriding-map git-timemachine-mode-map 'normal)
  ;; force update evil keymaps after git-timemachine-mode loaded
  (add-hook 'git-timemachine-mode-hook #'evil-normalize-keymaps))


;; diff-hl
(with-eval-after-load 'diff-hl
  (evil-define-key 'normal 'global
    (kbd "]c") 'diff-hl-next-hunk
    (kbd "[c") 'diff-hl-previous-hunk
    (kbd "<leader>gr") 'diff-hl-revert-hunk
    (kbd "<leader>gd") 'diff-hl-diff-goto-hunk)


  ;; UX: Don't delete the current hunk's indicators while we're editing
  ;; https://github.com/doomemacs/doomemacs/blob/master/modules/ui/vc-gutter/config.el#L204
  (add-hook 'diff-hl-flydiff-mode-hook
            (defun +vc-gutter-init-flydiff-mode-h ()
              (if (not diff-hl-flydiff-mode)
                  (remove-hook 'evil-insert-state-exit-hook #'diff-hl-flydiff-update)
                (add-hook 'evil-insert-state-exit-hook #'diff-hl-flydiff-update)))))


;; Treemacs integration with evil
(evil-define-key 'normal 'global (kbd "<leader>tt") 'treemacs)
(use-package treemacs-evil
  :after (treemacs evil))


;; lsp-mode
(with-eval-after-load 'lsp-mode
  (add-hook 'lsp-mode-hook (lambda ()
                             (evil-local-set-key 'normal (kbd "gd") 'lsp-find-definition)
                             (evil-local-set-key 'normal (kbd "<leader>la") 'lsp-execute-code-action)
                             (evil-local-set-key 'normal (kbd "<leader>lf") 'lsp-find-references)
                             (evil-local-set-key 'normal (kbd "<leader>lt") 'lsp-goto-type-definition)
                             (evil-local-set-key 'normal (kbd "<leader>lr") 'lsp-rename))))


;; flycheck
(with-eval-after-load 'flycheck
  (evil-add-command-properties #'flycheck-first-error :jump t)
  (evil-add-command-properties #'flycheck-next-error :jump t)
  (evil-add-command-properties #'flycheck-previous-error :jump t)

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


;; flycheck-posframe
(with-eval-after-load 'flycheck-posframe
  ;; Don't display popups while in insert or replace mode, as it can affect
  ;; the cursor's position or cause disruptive input delays.
  (add-hook 'flycheck-posframe-inhibit-functions #'evil-insert-state-p)
  (add-hook 'flycheck-posframe-inhibit-functions #'evil-replace-state-p))


;; flymake
(with-eval-after-load 'flymake
  (evil-add-command-properties #'flymake-goto-next-error :jump t)
  (evil-add-command-properties #'flymake-goto-prev-error :jump t)

  (evil-define-key 'normal 'global
    (kbd "M-e j") 'flymake-goto-next-error
    (kbd "M-e M-j") 'flymake-goto-next-error
    (kbd "M-e k") 'flymake-goto-prev-error
    (kbd "M-e l") 'flymake-show-project-diagnostics
    (kbd "M-e M-k") 'flymake-goto-prev-error
    (kbd "M-e b") 'flymake-start))


;; apheleia
(evil-define-key 'normal 'global (kbd "<leader>ta") 'apheleia-mode)


;; robby-mode
(evil-define-key 'normal 'global
  (kbd "<leader>ar")  'robby-commands
  (kbd "<leader>aa")  'robby-chat)
(with-eval-after-load 'robby-mode
  (evil-define-key 'normal robby-chat-mode-map
    (kbd "a") 'robby-chat
    (kbd "q") 'kill-this-buffer
    (kbd "<leader>mm") 'robby-commands))


;; dall-e-shell
(evil-define-key 'normal 'global (kbd "<leader>ad") 'dall-e-shell)


;; gptel
(with-eval-after-load 'gptel
  (add-hook 'gptel-pre-response-hook 'evil-normal-state)

  (define-key gptel-mode-map (kbd "<leader>mm") 'gptel-menu)

  (evil-define-key 'normal 'global
    (kbd "<leader>ae") 'gptel-send
    (kbd "<leader>ak") 'gptel-abort
    (kbd "<leader>ag") 'gptel))


;; elisp-mode
(evil-define-key 'normal emacs-lisp-mode-map
  (kbd "<leader>meb") 'eval-buffer
  (kbd "<leader>mer") 'eval-region
  (kbd "<leader>mes") 'eval-last-sexp)


;; justl
(evil-define-key 'normal 'global (kbd "<leader>pj") 'justl)
(with-eval-after-load 'justl
  (evil-define-key 'normal justl-mode-map
    (kbd "<RET>") 'justl-exec-recipe
    (kbd "e")     'justl-exec-recipe
    (kbd "E")     'justl-exec-eshell
    (kbd "?")     'justl-help-popup
    (kbd "w")     'justl-no-exec-eshell))


;; rainbow-mode
(evil-define-key 'normal 'global (kbd "<leader>tc") 'rainbow-mode)


(provide 'mb-evil)
;;; mb-evil.el ends here
