;;; mb-speedbar-test.el --- tests for mb-speedbar -*- lexical-binding: t; -*-
;;; Code:

(require 'cl-lib)
(require 'ert)

(load
 (expand-file-name
  "../lisp/mb-speedbar.el"
  (file-name-directory (or load-file-name buffer-file-name)))
 nil nil t)

(defun mb/speedbar-test-cleanup ()
  "Close Speedbar and remove its test buffers."
  (ignore-errors (speedbar-window-mode -1))
  (when (and (boundp 'speedbar-buffer)
             (buffer-live-p speedbar-buffer))
    (kill-buffer speedbar-buffer))
  (setq speedbar-buffer nil
	mb/speedbar-last-window nil))

(ert-deftest mb/speedbar-configures-native-window ()
  (should speedbar-prefer-window)
  (should (eq speedbar-window-side 'left))
  (should (= speedbar-window-default-width 32))
  (should speedbar-show-unknown-files)
  (should speedbar-hide-button-brackets-flag)
  (should-not speedbar-use-images)
  (should speedbar-update-flag)
  (should speedbar-smart-directory-expand-flag)
  (should speedbar-use-imenu-flag)
  (should (eq (key-binding (kbd "M-1")) #'mb/speedbar-dwim)))

(ert-deftest mb/speedbar-dwim-opens-focuses-and-closes ()
  (save-window-excursion
    (unwind-protect
	(progn
          (mb/speedbar-test-cleanup)
          (delete-other-windows)
          (switch-to-buffer (get-buffer-create " *mb-speedbar-editor*"))
          (let ((editor-window (selected-window)))
            (mb/speedbar-dwim)
            (let ((speedbar-window (get-buffer-window speedbar-buffer)))
              (should (window-live-p speedbar-window))
              (should (eq (selected-window) speedbar-window))
              (should (eq mb/speedbar-last-window editor-window))
              (should (eq (window-parameter speedbar-window 'window-side) 'left))

              (select-window editor-window)
              (mb/speedbar-dwim)
              (should (eq (selected-window) speedbar-window))

              (mb/speedbar-dwim)
              (should-not (window-live-p speedbar-window))
              (should (eq (selected-window) editor-window)))))
      (mb/speedbar-test-cleanup)
      (when-let* ((buffer (get-buffer " *mb-speedbar-editor*")))
        (kill-buffer buffer)))))

(ert-deftest mb/speedbar-open-in-active-window-visits-file-without-splitting ()
  (save-window-excursion
    (let* ((directory (make-temp-file "mb-speedbar-" t))
           (file (expand-file-name "target.txt" directory))
           (editor-buffer (get-buffer-create " *mb-speedbar-editor*")))
      (unwind-protect
          (progn
            (mb/speedbar-test-cleanup)
            (write-region "target" nil file nil 'silent)
            (delete-other-windows)
            (switch-to-buffer editor-buffer)
            (setq default-directory directory)
            (let ((editor-window (selected-window)))
              (mb/speedbar-dwim)
              (with-current-buffer speedbar-buffer
		(cl-letf (((symbol-function 'speedbar-line-file)
                           (lambda () file)))
                  (mb/speedbar-open-in-active-window)))
              (should (eq (selected-window) editor-window))
              (should (equal (buffer-file-name (window-buffer editor-window)) file))
              (should (= (length (window-list nil 'no-minibuffer)) 2))))
        (mb/speedbar-test-cleanup)
        (when (buffer-live-p editor-buffer)
          (kill-buffer editor-buffer))
        (when-let* ((buffer (get-file-buffer file)))
          (kill-buffer buffer))
        (delete-directory directory t)))))

(provide 'mb-speedbar-test)
;;; mb-speedbar-test.el ends here
