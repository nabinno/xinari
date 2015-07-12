;;; xinari-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (global-xinari-mode xinari-minor-mode xinari-launch
;;;;;;  xinari-cap xinari-rake) "xinari" "xinari.el" (21906 24499
;;;;;;  789629 467000))
;;; Generated autoloads from xinari.el

(autoload 'xinari-rake "xinari" "\
Select and run a rake TASK using `ruby-compilation-rake'.

\(fn &optional TASK EDIT-CMD-ARGS)" t nil)

(autoload 'xinari-cap "xinari" "\
Select and run a capistrano TASK using `ruby-compilation-cap'.

\(fn &optional TASK EDIT-CMD-ARGS)" t nil)

(autoload 'xinari-launch "xinari" "\
Call function `xinari-minor-mode' if inside a rails project.
Otherwise, disable that minor mode if currently enabled.

\(fn)" t nil)

(autoload 'xinari-minor-mode "xinari" "\
Enable Xinari minor mode to support working with the Phoenix framework.

\(fn &optional ARG)" t nil)

(defvar global-xinari-mode nil "\
Non-nil if Global-Xinari mode is enabled.
See the command `global-xinari-mode' for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-xinari-mode'.")

(custom-autoload 'global-xinari-mode "xinari" nil)

(autoload 'global-xinari-mode "xinari" "\
Toggle Xinari minor mode in all buffers.
With prefix ARG, enable Global-Xinari mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Xinari minor mode is enabled in all buffers where
`xinari-launch-maybe' would do it.
See `xinari-minor-mode' for more information on Xinari minor mode.

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil nil ("xinari-pkg.el") (21906 24499 813181 88000))

;;;***

(provide 'xinari-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; xinari-autoloads.el ends here
