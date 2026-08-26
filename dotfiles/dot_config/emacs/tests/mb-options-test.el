;;; mb-options-test.el --- tests for mb-options -*- lexical-binding: t; -*-
;;; Code:

(require 'ert)

(load
 (expand-file-name
  "../lisp/mb-options.el"
  (file-name-directory (or load-file-name buffer-file-name)))
 nil nil t)

(ert-deftest mb/editor-from-environment-defaults-to-evil ()
  (let ((process-environment (copy-sequence process-environment)))
    (setenv "MB_EMACS_EDITOR" nil)
    (should (eq (mb/editor-from-environment) 'evil))))

(ert-deftest mb/editor-from-environment-normalizes-valid-values ()
  (let ((process-environment (copy-sequence process-environment)))
    (setenv "MB_EMACS_EDITOR" "NONE")
    (should (eq (mb/editor-from-environment) 'none))))

(ert-deftest mb/editor-from-environment-rejects-invalid-values ()
  (let ((process-environment (copy-sequence process-environment)))
    (setenv "MB_EMACS_EDITOR" "meow")
    (should-error (mb/editor-from-environment) :type 'user-error)))

(provide 'mb-options-test)
;;; mb-options-test.el ends here
