;;; mb-speedbar.el --- same-frame Speedbar config -*- lexical-binding: t; -*-
;;; Commentary:
;; Native Speedbar configuration and commands shared by the main config and
;; focused ERT tests.
;;; Code:

(setq speedbar-prefer-window t
      speedbar-window-side 'left
      speedbar-window-default-width 32
      speedbar-show-unknown-files t
      speedbar-hide-button-brackets-flag t
      speedbar-use-images nil
      speedbar-update-flag t
      speedbar-smart-directory-expand-flag t
      speedbar-use-imenu-flag t)

(defvar mb/speedbar-last-window nil
  "Window selected before focusing Speedbar.")

(defun mb/speedbar-dwim ()
  "Open or focus Speedbar, or close it when already focused."
  (interactive)
  (require 'speedbar)
  (let* ((buffer (and (boundp 'speedbar-buffer)
                      (symbol-value 'speedbar-buffer)))
         (window (and (buffer-live-p buffer)
                      (get-buffer-window buffer))))
    (if (and (window-live-p window)
             (eq (selected-window) window))
	(let ((return-window mb/speedbar-last-window))
          (speedbar-window-mode -1)
          (when (window-live-p return-window)
            (select-window return-window)))
      (setq mb/speedbar-last-window (selected-window))
      (speedbar-get-focus))))

(defun mb/speedbar-help ()
  "Show bindings for the active Speedbar keymap."
  (interactive)
  (which-key-show-keymap "Speedbar" (current-local-map)))

(defun mb/speedbar-open-in-active-window ()
  "Visit the item at point in the active editor window.
Directories and non-file items retain Speedbar's native behavior."
  (interactive)
  (let ((file (speedbar-line-file)))
    (if (and file (not (file-directory-p file)))
	(let ((target (or (and (window-live-p mb/speedbar-last-window)
                               mb/speedbar-last-window)
			  (get-mru-window nil nil t t)
			  (window-main-window)))
              (speedbar-buffer (current-buffer)))
          (run-hooks 'speedbar-before-visiting-file-hook)
          (select-window target)
          (find-file file)
          (run-hooks 'speedbar-visiting-file-hook)
          (with-current-buffer speedbar-buffer
            (speedbar-stealthy-updates)
            (speedbar-set-timer dframe-update-speed)))
      (speedbar-edit-line))))

(global-set-key (kbd "M-1") #'mb/speedbar-dwim)

(provide 'mb-speedbar)
;;; mb-speedbar.el ends here
