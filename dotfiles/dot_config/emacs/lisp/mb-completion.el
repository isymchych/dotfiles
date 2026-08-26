;;; mb-completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'mb-core)
(require 'mb-navigation)
(require 'mb-ui)
(require 'use-package)

;; Vertical completion UI (like ido)
(use-package vertico
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

  (global-set-key (kbd "C-c `") #'vertico-repeat))



;; Fuzzy matching algorithm
(use-package orderless
  :init
  (defun mb/orderless-without-if-bang (pattern _index _total)
    (cond
     ((equal "!" pattern)
      '(orderless-literal . ""))
     ((string-prefix-p "!" pattern)
      `(orderless-without-literal . ,(substring pattern 1)))))

  (setq completion-styles '(basic orderless)
	;; orderless-matching-styles '(orderless-regexp)
	orderless-style-dispatchers '(mb/orderless-without-if-bang)
	completion-category-defaults nil
	completion-category-overrides '((file (styles partial-completion)))))



;; Enable rich annotations in the minibuffer
(use-package marginalia
  :init
  (marginalia-mode))



;; Advanced commands in vertical completion UI
(use-package consult
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

  ;; (setq consult-fd-args "fd --color=never")

  (defun mb/consult-ripgrep-symbol-at-point (&optional dir)
    (interactive)
    (consult-ripgrep dir (if (region-active-p)
                             (mb/get-selected-text)
                           (thing-at-point 'symbol))))

  (defun mb/consult-ripgrep-in-current-dir ()
    (interactive)
    (consult-ripgrep default-directory))

  (defun mb/consult-fd-thing-at-point (&optional dir)
    (interactive)
    (consult-fd dir (if (region-active-p)
			(mb/get-selected-text)
                      (thing-at-point 'filename))))

  (defun mb/consult-fd-in-current-dir ()
    (interactive)
    (consult-fd default-directory))


  ;; remap existing commands
  (global-set-key [remap execute-extended-command-for-buffer] #'consult-mode-command)
  (global-set-key [remap apropos]                             #'consult-apropos)
  (global-set-key [remap bookmark-jump]                       #'consult-bookmark)
  (global-set-key [remap goto-line]                           #'consult-goto-line)
  (global-set-key [remap imenu]                               #'consult-imenu)
  (global-set-key [remap locate]                              #'consult-locate)
  (global-set-key [remap load-theme]                          #'consult-theme)
  (global-set-key [remap man]                                 #'consult-man)
  (global-set-key [remap recentf-open-files]                  #'consult-recent-file)
  (global-set-key [remap recentf-open]                        #'consult-recent-file)
  (global-set-key [remap list-buffers]                        #'consult-buffer)
  (global-set-key [remap switch-to-buffer]                    #'consult-buffer)
  (global-set-key [remap switch-to-buffer-other-window]       #'consult-buffer-other-window)
  (global-set-key [remap yank-pop]                            #'consult-yank-pop)
  (global-set-key [remap yank-from-kill-ring]                 #'consult-yank-from-kill-ring)
  (global-set-key [remap project-switch-to-buffer]            #'consult-project-buffer)
  (global-set-key [remap project-list-buffers]                #'consult-project-buffer)
  (global-set-key [remap project-find-file]                   #'consult-fd)
  (global-set-key [remap project-or-external-find-file]       #'mb/consult-fd-thing-at-point)
  (global-set-key [remap project-find-regexp]                 #'consult-ripgrep)
  (global-set-key [remap project-or-external-find-regexp]     #'mb/consult-ripgrep-symbol-at-point)

  (global-set-key (kbd "M-g M-l") #'consult-line)
  (global-set-key (kbd "M-g o")   #'consult-outline)

  (define-key project-prefix-map (kbd "s") #'consult-ripgrep) ;; override project-shell, for convenience
  (define-key project-prefix-map (kbd "S") #'mb/consult-ripgrep-symbol-at-point)

  (advice-add #'multi-occur :override #'consult-multi-occur))


;; Jump to Flycheck error
(use-package consult-flycheck
  :after (consult flycheck)
  :defer t
  :commands (consult-flycheck)
  :bind
  (("M-g e" . 'consult-flycheck)))


;; Nerd icons for consult / completion
(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))



;; Context commands for things at a point
(use-package embark
  :commands (embark-act)
  :bind
  (("C-h B" . 'embark-bindings-at-point)
   ("M-." .  'embark-act))

  :config
  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
	       '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
		 nil
		 (window-parameters (mode-line-format . none)))))



(use-package embark-consult
  :after (embark consult)
  ;; if you want to have consult previews as you move around an
  ;; auto-updating embark collect buffer
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))



;; https://github.com/oantolin/embark/wiki/Additional-Configuration#use-which-key-like-a-key-menu-prompt
(use-package embark-which-key
  :ensure nil
  :no-require t
  :after (embark which-key)
  :config
  (defun mb/embark-which-key-indicator ()
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
	'(mb/embark-which-key-indicator
	  embark-highlight-indicator
	  embark-isearch-highlight-indicator))

  (defun mb/embark-hide-which-key-indicator (fn &rest args)
    "Hide the which-key indicator immediately when using the completing-read prompter."
    (which-key--hide-popup-ignore-command)
    (let ((embark-indicators
           (remq #'mb/embark-which-key-indicator embark-indicators)))
      (apply fn args)))

  (advice-add #'embark-completing-read-prompter
	      :around #'mb/embark-hide-which-key-indicator))


;; Rg: search using ripgrep
(use-package rg
  :defer t
  :commands (rg-menu rg-isearch-menu rg-project)
  :init
  ;; ensure rg-isearch-menu is loaded
  (with-eval-after-load 'rg-menu
    (require 'rg-isearch))

  (global-set-key (kbd "M-s g") 'rg-menu)
  (global-set-key (kbd "M-s G") 'rg-isearch-menu)
  (define-key project-prefix-map (kbd "R") 'rg-project))



;; Company-mode: autocomplete
(use-package company
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
   company-show-quick-access        'left
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

  (define-key company-active-map (kbd "<return>") #'company-complete-selection)
  (define-key company-active-map (kbd "RET") #'company-complete-selection)

  ;; https://emacs.stackexchange.com/a/24800
  ;; <return> is for windowed Emacs; RET is for terminal Emacs
  ;; (dolist (key '("<return>" "RET"))
  ;;   ;; Here we are using an advanced feature of define-key that lets
  ;;   ;; us pass an "extended menu item" instead of an interactive
  ;;   ;; function. Doing this allows RET to regain its usual
  ;;   ;; functionality when the user has not explicitly interacted with
  ;;   ;; Company.
  ;;   (define-key company-active-map (kbd key)
  ;;               `(menu-item nil company-complete
  ;;                           :filter ,(lambda (cmd)
  ;;                                      (when (or (company-explicit-action-p)
  ;;                                                ;; or if previewing just one completion candidate
  ;;                                                (eq company-candidates-length 1))
  ;;                                        cmd)))))

  (define-key company-active-map (kbd "<f1>") nil)

  (define-key company-active-map (kbd "C-w") nil)
  (define-key company-active-map (kbd "C-j") nil)
  (define-key company-active-map (kbd "C-s")  nil)
  (define-key company-active-map (kbd "M-l")  'company-show-location)
  (define-key company-active-map [remap scroll-down-command]  nil)
  (define-key company-active-map [remap scroll-up-command]  nil))


;; Company-shell: better autocomplete in shell
(use-package company-shell
  :after (company sh-script)
  :config
  (setq company-shell-dont-fetch-meta mb-is-mac-os) ;; fixes slowdown on mac https://github.com/Alexander-Miller/company-shell/issues/15
  (add-to-list 'company-backends 'company-shell))


;; Company-quickhelp: show docs for a candidate in a tooltip
;; NOTE: change tooltip font size on Mac: defaults write org.gnu.Emacs NSToolTipsFontSize -int 14
(use-package company-quickhelp
  :after company
  :bind (:map company-active-map ("M-h" . #'company-quickhelp-manual-begin))
  :config
  (setq company-quickhelp-delay nil)
  (company-quickhelp-mode))



(provide 'mb-completion)
;;; mb-completion.el ends here
