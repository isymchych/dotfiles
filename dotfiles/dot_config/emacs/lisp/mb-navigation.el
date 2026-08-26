;;; mb-navigation.el --- Projects, files, and movement -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'mb-core)
(require 'use-package)

;; Project.el: project management
(use-package project
  :ensure nil
  :config
  (push '(project-dired "Root directory") project-switch-commands)

  ;; Improve detection of project root https://andreyor.st/posts/2022-07-16-project-el-enhancements/
  (defcustom mb/project-root-markers
    '("Cargo.lock" ".git" ".emacs-project")
    "Files or directories that indicate the root of a project."
    :type '(repeat string)
    :group 'mb-customizations)

  (defun mb/project-root-p (path)
    "Check if the current PATH has any of the project root markers."
    (catch 'found
      (dolist (marker mb/project-root-markers)
        (when (file-exists-p (concat path marker))
          (throw 'found marker)))))

  (defun mb/project-find-root (path)
    "Search up PATH for `mb/project-root-markers'."
    (when-let* ((root (locate-dominating-file path #'mb/project-root-p)))
      (cons 'transient (expand-file-name root))))

  (add-to-list 'project-find-functions #'mb/project-find-root))



;; Speedbar: file and tag browser
(require 'mb-speedbar)



;; Dired extensions
(use-package dired-x
  :ensure nil
  :config
  ;; Use GNU ls as `gls' from `coreutils' if available.  Add `(setq
  ;; dired-use-ls-dired nil)' to your config to suppress the Dired warning when
  ;; not using GNU ls.  We must look for `gls' after `exec-path-from-shell' was
  ;; initialized to make sure that `gls' is in `exec-path'
  (when mb-is-mac-os
    (let ((gls (executable-find "gls")))
      (when gls
        (setq insert-directory-program gls))))

  (setq dired-listing-switches "-aBhl  --group-directories-first")

  (add-hook 'dired-mode-hook 'dired-hide-details-mode)

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

  (define-key dired-mode-map (kbd "h")                  'mb/dired-up-directory)
  (define-key dired-mode-map [remap dired-up-directory] 'mb/dired-up-directory)
  (define-key dired-mode-map [remap quit-window]        'mb/kill-this-buffer)

  (define-key dired-mode-map [remap dired-find-file] 'dired-find-alternate-file)
  (define-key dired-mode-map (kbd "l") 'dired-find-alternate-file)
  (define-key dired-mode-map (kbd "L") 'mb/dired-find-file-or-alternate)
  (define-key dired-mode-map (kbd "RET") 'dired-find-alternate-file)

  (global-set-key [remap dired]          'dired-jump)
  (global-set-key [remap list-directory] 'dired-jump))



(use-package better-jumper
  :diminish better-jumper-local-mode
  :init
  (global-set-key [remap xref-pop-marker-stack] #'better-jumper-jump-backward)
  (global-set-key [remap xref-go-back] #'better-jumper-jump-backward)
  (global-set-key [remap xref-go-forward] #'better-jumper-jump-forward)

  :config
  (setq better-jumper-use-savehist t)

  (better-jumper-mode 1))



;; Goto last change
(use-package goto-chg
  :bind
  (("C-," . goto-last-change)
    ("C-." . goto-last-change-reverse)))



;; Avy: jump to char/line
(use-package avy
  :config
  ;; FIXME
  ;; (advice-add #'avy-goto-char-timer :around #'better-jumper-set-jump)
  ;; (advice-add #'avy-goto-line :around #'better-jumper-set-jump)

  (global-set-key [remap goto-char] 'avy-goto-char-timer)
  (global-set-key (kbd "M-g l") 'avy-goto-line))
;; Casual-avy: transient bindings for avy
(use-package casual-avy
  :ensure t
  :bind ("M-g a" . casual-avy-tmenu))

(provide 'mb-navigation)
;;; mb-navigation.el ends here
