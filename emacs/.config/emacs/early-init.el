;;; early-init.el --- Startup speed, annoyance suppression -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

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


(setq default-frame-alist '((fullscreen . maximized)
                            ;; You can turn off scroll bars by uncommenting these lines:
                            (vertical-scroll-bars . nil)
                            (horizontal-scroll-bars . nil)

                            ;; Setting the face in here prevents flashes of
                            ;; color as the theme gets activated
                            (background-color . "#2e3440")
                            (foreground-color . "white")
                            (ns-appearance . dark)
                            (ns-transparent-titlebar . t)))

;; Improve lsp-mode performance https://emacs-lsp.github.io/lsp-mode/page/performance/#use-plists-for-deserialization
(setenv "LSP_USE_PLISTS" "true")

;;; early-init.el ends here
