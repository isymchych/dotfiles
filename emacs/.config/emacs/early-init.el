;;; early-init.el --- Startup speed, annoyance suppression -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; base configs dir
(defvar mb-dotfiles-dir (file-name-directory (or (buffer-file-name) load-file-name)))

(defvar mb-customizations-file (expand-file-name "custom.el" mb-dotfiles-dir))

(defvar mb-font "Iosevka Nerd Font Mono:weight=semibold:size=26")

;; load customizations file if it exists
(load mb-customizations-file t)

;; reduce the frequency of garbage collection by making it happen on
;; each 100MB of allocated data (the default is on every 0.76MB)
(setq gc-cons-threshold 100000000)

;; Increase the amount of data which Emacs reads from the process.
;; default is too low 4k considering that the some of the language server responses are in 800k - 3M range.
(setq read-process-output-max (* 1024 1024)) ;; 1mb

(setq byte-compile-warnings '(not obsolete))
(setq warning-suppress-log-types '((comp) (bytecomp)))
(setq native-comp-async-report-warnings-errors 'silent)

;; Silence stupid startup message
(setq inhibit-startup-echo-area-message (user-login-name))
;; disable startup screen
(setq inhibit-startup-screen t)
;; remove message from scratch
(setq initial-scratch-message nil)

;; Default frame configuration: full screen, good-looking title bar on macOS
(setq frame-resize-pixelwise t)

;; Turn off mouse interface early in startup to avoid momentary display
(if (fboundp 'tool-bar-mode)   (tool-bar-mode   -1))
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'menu-bar-mode)   (menu-bar-mode -1))

;; default styles for *ALL* windows
(setq default-frame-alist '((fullscreen . maximized)
                            (vertical-scroll-bars . nil)
                            (horizontal-scroll-bars . nil)

                            ;; Setting the face in here prevents flashes of
                            ;; color as the theme gets activated
                            (background-color . "#2e3440")

                            (ns-appearance . dark)
                            (ns-transparent-titlebar . t)))

;; default styles for *THE FIRST* window
(setq initial-frame-alist '(
                            ;; Setting the face in here prevents flashes of
                            ;; color as the theme gets activated
                            (foreground-color . "#cccccc")
                            ))

;; Font
(setq font-use-system-font nil)
(setq-default default-font mb-font)

;; set font for all windows
(add-to-list 'default-frame-alist `(font . ,mb-font))

(message "Using font %s" mb-font)

;; Improve lsp-mode performance https://emacs-lsp.github.io/lsp-mode/page/performance/#use-plists-for-deserialization
(setenv "LSP_USE_PLISTS" "true")

;;; early-init.el ends here
