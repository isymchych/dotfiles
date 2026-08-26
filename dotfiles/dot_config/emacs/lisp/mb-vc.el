;;; mb-vc.el --- Version control integration -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'mb-core)
(require 'use-package)

;; Transient: menus, used by magit and other packages
(use-package transient
  :config
  ;; Close transient with ESC
  (define-key transient-map [escape] #'transient-quit-one))



;; Magit: UI for git
(use-package magit
  :defer t
  :commands (magit-status magit-log-all magit-log-buffer-file magit-blame)
  :config
  (setq vc-follow-symlinks nil

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
    git-commit-summary-max-length 72

    ;; ask me if I want a tracking upstream
    magit-set-upstream-on-push 'askifnotset

    transient-default-level 5
    transient-display-buffer-action '(display-buffer-below-selected)

    magit-bury-buffer-function #'magit-restore-window-configuration

    magit-diff-refine-hunk t ; show granular diffs in selected hunk
    ;; Don't display parent/related refs in commit buffers; they are rarely
    ;; helpful and only add to runtime costs.
    magit-revision-insert-related-refs nil)

  (add-hook 'git-commit-mode-hook
    (lambda ()
      (setq-local fill-column git-commit-summary-max-length)
      (mb/toggle-auto-fill-mode)))

  (add-hook 'magit-process-mode-hook #'goto-address-mode)

  (message "mb: initialized MAGIT"))



;; Git-modes: modes for .gitattributes, .gitconfig and .gitignore
(use-package git-modes
  :defer t)



;; Git-diff mode
(use-package diff-mode
  :defer t
  :config
  (define-key diff-mode-map (kbd "j") 'diff-hunk-next)
  (define-key diff-mode-map (kbd "k") 'diff-hunk-prev))



;; Difftastic: syntax-aware diffs
(use-package difftastic
  :ensure t
  :defer t)



;; Git-timemachine: browse through file history
(use-package git-timemachine
  :defer t)



;; Diff-hl: highlight changes in gutter
(use-package diff-hl
  :defer 0.5
  :config
  (setq diff-hl-draw-borders nil)
  (add-hook 'dired-mode-hook 'diff-hl-dired-mode)

  (add-hook 'magit-pre-refresh-hook  'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)

  (diff-hl-flydiff-mode)

  ;; there is no fringe in terminal emacs, so use margins
  (unless (display-graphic-p)
    (diff-hl-margin-mode))

  (global-diff-hl-mode))

(provide 'mb-vc)
;;; mb-vc.el ends here
