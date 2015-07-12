;;; xinari.el --- Xinari Is Not A Phoenix IDE

;; Copyright (C) 2008 Phil Hagelberg, Eric Schulte
;; Copyright (C) 2009-2015 Steve Purcell

;; Author: Nab Inno
;; URL: https://github.com/nabinno/xinari
;; Version: DEV
;; Created: 2015-07-12
;; Keywords: elixir, phoenix, project, convenience, web
;; Package-Requires: ((elixir-mode "2.2.5") (jump "2.0"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Xinari Is Not A Elixir IDE.

;; Well, ok it kind of is.  Xinari is a set of Emacs Lisp modes that is
;; aimed towards making Emacs into a top-notch Elixir and Phoenix
;; development environment.

;; To install from source, copy the directory containing this file
;; into your Emacs Lisp directory, assumed here to be ~/.emacs.d.  Add
;; these lines of code to your .emacs file:

;; ;; xinari
;; (add-to-list 'load-path "~/.emacs.d/xinari")
;; (require 'xinari)
;; (global-xinari-mode)

;; ;; ido
;; (require 'ido)
;; (ido-mode t)

;; Note: if you cloned this from a git repo, you will have to grab the
;; submodules which can be done by running the following commands from
;; the root of the xinari directory

;;  git submodule init
;;  git submodule update

;;; Code:
;;;###begin-elpa-ignore
(let* ((this-dir (file-name-directory (or load-file-name buffer-file-name)))
       (util-dir (file-name-as-directory (expand-file-name "util" this-dir)))
       (inf-ruby-dir (file-name-as-directory (expand-file-name "inf-ruby" util-dir)))
       (jump-dir (file-name-as-directory (expand-file-name "jump" util-dir))))
  (dolist (dir (list util-dir inf-ruby-dir jump-dir))
    (when (file-exists-p dir)
      (add-to-list 'load-path dir))))
;;;###end-elpa-ignore
(require 'elixir-mode)
(require 'ruby-mode)
(require 'inf-ruby)
(require 'ruby-compilation)
(require 'jump)
(require 'cl)
(require 'json)
(require 'easymenu)

;; fill in some missing variables for XEmacs
(when (eval-when-compile (featurep 'xemacs))
  ;;this variable does not exist in XEmacs
  (defvar safe-local-variable-values ())
  ;;find-file-hook is not defined and will otherwise not be called by XEmacs
  (define-compatible-variable-alias 'find-file-hook 'find-file-hooks))

(defgroup xinari nil
  "Xinari customizations."
  :prefix "xinari-"
  :group 'xinari)

(defcustom xinari-major-modes nil
  "Major Modes from which to launch Xinari."
  :type '(repeat symbol)
  :group 'xinari)

(defcustom xinari-exclude-major-modes nil
  "Major Modes in which to never launch Xinari."
  :type '(repeat symbol)
  :group 'xinari)

(defcustom xinari-tags-file-name
  "TAGS"
  "Path to your TAGS file inside of your rails project.  See `tags-file-name'."
  :group 'xinari)

(defcustom xinari-fontify-rails-keywords t
  "When non-nil, fontify keywords such as 'before_filter', 'url_for'.")

(defcustom xinari-controller-keywords
  '("logger" "polymorphic_path" "polymorphic_url" "mail" "render" "attachments"
    "default" "helper" "helper_attr" "helper_method" "layout" "url_for"
    "serialize" "exempt_from_layout" "filter_parameter_logging" "hide_action"
    "cache_sweeper" "protect_from_forgery" "caches_page" "cache_page"
    "caches_action" "expire_page" "expire_action" "rescue_from" "params"
    "request" "response" "session" "flash" "head" "redirect_to"
    "render_to_string" "respond_with"
    ;; Rails < 4
    "before_filter" "append_before_filter"
    "prepend_before_filter" "after_filter" "append_after_filter"
    "prepend_after_filter" "around_filter" "append_around_filter"
    "prepend_around_filter" "skip_before_filter" "skip_after_filter" "skip_filter"
    ;; Rails >= 4
    "after_action" "append_after_action" "append_around_action"
    "append_before_action" "around_action" "before_action" "prepend_after_action"
    "prepend_around_action" "prepend_before_action" "skip_action_callback"
    "skip_after_action" "skip_around_action" "skip_before_action")
  "List of keywords to highlight for controllers"
  :group 'xinari
  :type '(repeat string))

(defcustom xinari-migration-keywords
  '("create_table" "change_table" "drop_table" "rename_table" "add_column"
    "rename_column" "change_column" "change_column_default" "remove_column"
    "add_index" "remove_index" "rename_index" "execute")
  "List of keywords to highlight for migrations"
  :group 'xinari
  :type '(repeat string))

(defcustom xinari-model-keywords
  '("default_scope" "named_scope" "scope" "serialize" "belongs_to" "has_one"
    "has_many" "has_and_belongs_to_many" "composed_of" "accepts_nested_attributes_for"
    "before_create" "before_destroy" "before_save" "before_update" "before_validation"
    "before_validation_on_create" "before_validation_on_update" "after_create"
    "after_destroy" "after_save" "after_update" "after_validation"
    "after_validation_on_create" "after_validation_on_update" "around_create"
    "around_destroy" "around_save" "around_update" "after_commit" "after_find"
    "after_initialize" "after_rollback" "after_touch" "attr_accessible"
    "attr_protected" "attr_readonly" "validates" "validate" "validate_on_create"
    "validate_on_update" "validates_acceptance_of" "validates_associated"
    "validates_confirmation_of" "validates_each" "validates_exclusion_of"
    "validates_format_of" "validates_inclusion_of" "validates_length_of"
    "validates_numericality_of" "validates_presence_of" "validates_size_of"
    "validates_uniqueness_of" "validates_with")
  "List of keywords to highlight for models"
  :group 'xinari
  :type '(repeat string))

(defvar xinari-minor-mode-hook nil
  "*Hook for customising Xinari.")

(defcustom xinari-rails-env nil
  "Use this to force a value for RAILS_ENV when running xinari.
Leave this set to nil to not force any value for RAILS_ENV, and
leave this to the environment variables outside of Emacs.")

(defvar xinari-minor-mode-prefixes
  (list ";" "'")
  "List of characters, each of which will be bound (with control-c) as a prefix for `xinari-minor-mode-map'.")

(defvar xinari-partial-regex
  "render \\(:partial *=> \\)?*[@'\"]?\\([A-Za-z/_]+\\)['\"]?"
  "Regex that matches a partial rendering call.")

(defadvice ruby-compilation-do (around xinari-compilation-do activate)
  "Set default directory to the rails root before running ruby processes."
  (let ((default-directory (or (xinari-root) default-directory)))
    ad-do-it
    (xinari-launch)))

(defadvice ruby-compilation-rake (around xinari-compilation-rake activate)
  "Set default directory to the rails root before running rake processes."
  (let ((default-directory (or (xinari-root) default-directory)))
    ad-do-it
    (xinari-launch)))

(defadvice ruby-compilation-cap (around xinari-compilation-cap activate)
  "Set default directory to the rails root before running cap processes."
  (let ((default-directory (or (xinari-root) default-directory)))
    ad-do-it
    (xinari-launch)))

(defun xinari-parse-yaml (file)
  "Parse the YAML contents of FILE."
  (json-read-from-string
   (shell-command-to-string
    (concat ruby-compilation-executable
            " -ryaml -rjson -e 'JSON.dump(YAML.load(ARGF.read), STDOUT)' "
            (shell-quote-argument file)))))

(defun xinari-root (&optional dir home)
  "Return the root directory of the project within which DIR is found.
Optional argument HOME is ignored."
  (let ((default-directory (or dir default-directory)))
    (when (file-directory-p default-directory)
      (if (file-exists-p (expand-file-name "config.exs" (expand-file-name "config")))
          default-directory
        ;; regexp to match windows roots, tramp roots, or regular posix roots
        (unless (string-match "\\(^[[:alpha:]]:/$\\|^/[^\/]+:/?$\\|^/$\\)" default-directory)
          (xinari-root (expand-file-name (file-name-as-directory ".."))))))))

(defun xinari-highlight-keywords (keywords)
  "Highlight the passed KEYWORDS in current buffer.
Use `font-lock-add-keywords' in case of `ruby-mode' or
`ruby-extra-keywords' in case of Enhanced Ruby Mode."
  (if (boundp 'ruby-extra-keywords)
      (progn
        (setq ruby-extra-keywords (append ruby-extra-keywords keywords))
        (ruby-local-enable-extra-keywords))
    (font-lock-add-keywords
     nil
     (list (list
            (concat "\\(^\\|[^_:.@$]\\|\\.\\.\\)\\b"
                    (regexp-opt keywords t)
                    (eval-when-compile (if (string-match "\\_>" "ruby")
                                           "\\_>"
                                         "\\>")))
            (list 2 'font-lock-builtin-face))))))

(defun xinari-apply-keywords-for-file-type ()
  "Apply extra font lock keywords specific to models, controllers etc."
  (when (and xinari-fontify-rails-keywords (buffer-file-name))
    (loop for (re keywords) in `(("_controller\\.ex$"   ,xinari-controller-keywords)
                                 ("web/models/.+\\.ex$" ,xinari-model-keywords)
                                 ("db/migrate/.+\\.ex$" ,xinari-migration-keywords))
          do (when (string-match-p re (buffer-file-name))
               (xinari-highlight-keywords keywords)))))


(add-hook 'ruby-mode-hook 'xinari-apply-keywords-for-file-type)

;;--------------------------------------------------------------------------------
;; user functions

;;;###autoload
(defun xinari-rake (&optional task edit-cmd-args)
  "Select and run a rake TASK using `ruby-compilation-rake'."
  (interactive "P")
  (ruby-compilation-rake task edit-cmd-args
                         (when xinari-rails-env
                           (list (cons "RAILS_ENV" xinari-rails-env)))))

(defun xinari-rake-migrate-down (path &optional edit-cmd-args)
  "Perform a down migration for the migration with PATH."
  (interactive "fMigration: ")
  (let* ((file (file-name-nondirectory path))
         (n (if (string-match "^\\([0-9]+\\)_[^/]+$" file)
                (match-string 1 file)
              (error "Couldn't determine migration number"))))
    (ruby-compilation-rake "db:migrate:down"
                           edit-cmd-args
                           (list (cons "VERSION" n)))))

;;;###autoload
(defun xinari-cap (&optional task edit-cmd-args)
  "Select and run a capistrano TASK using `ruby-compilation-cap'."
  (interactive "P")
  (ruby-compilation-cap task edit-cmd-args
                        (when xinari-rails-env
                          (list (cons "RAILS_ENV" xinari-rails-env)))))

(defun xinari--discover-rails-commands ()
  "Return a list of commands supported by the main rails script."
  (let ((rails-script (xinari--rails-path)))
    (when rails-script
      (ruby-compilation-extract-output-matches rails-script "^ \\([a-z]+\\)[[:space:]].*$"))))

(defvar xinari-rails-commands-cache nil
  "Cached values for commands that can be used with 'script/rails' in Rails 3.")

(defun xinari-get-rails-commands ()
  "Return a cached list of commands supported by the main rails script."
  (when (null xinari-rails-commands-cache)
    (setq xinari-rails-commands-cache (xinari--discover-rails-commands)))
  xinari-rails-commands-cache)

(defun xinari-script (&optional script)
  "Select and run SCRIPT from the script/ directory of the rails application."
  (interactive)
  (let* ((completions (append (and (file-directory-p (xinari-script-path))
                                   (directory-files (xinari-script-path) nil "^[^.]"))
                              (xinari-get-rails-commands)))
         (script (or script (jump-completing-read "Script: " completions)))
         (ruby-compilation-error-regexp-alist ;; for jumping to newly created files
          (if (equal script "generate")
              '(("^ +\\(create\\) +\\([^[:space:]]+\\)" 2 3 nil 0 2)
                ("^ +\\(identical\\) +\\([^[:space:]]+\\)" 2 3 nil 0 2)
                ("^ +\\(exists\\) +\\([^[:space:]]+\\)" 2 3 nil 0 2)
                ("^ +\\(conflict\\) +\\([^[:space:]]+\\)" 2 3 nil 0 2))
            ruby-compilation-error-regexp-alist))
         (script-path (concat (xinari--wrap-rails-command script) " ")))
    (when (string-match-p "^\\(db\\)?console" script)
      (error "Use the dedicated xinari function to run this interactive script"))
    (ruby-compilation-run (concat script-path " " (read-from-minibuffer (concat script " ")))
                          nil
                          (concat "rails " script))))

(defun xinari-test (&optional edit-cmd-args)
  "Run the current ruby function as a test, or run the corresponding test.
If current function is not a test,`xinari-find-test' is used to
find the corresponding test.  Output is sent to a compilation buffer
allowing jumping between errors and source code.  Optional prefix
argument EDIT-CMD-ARGS lets the user edit the test command
arguments."
  (interactive "P")
  (or (xinari-test-function-name)
      (string-match "test" (or (ruby-add-log-current-method)
                               (file-name-nondirectory (buffer-file-name))))
      (xinari-find-test))
  (let* ((fn (xinari-test-function-name))
         (path (buffer-file-name))
         (ruby-options (list "-I" (expand-file-name "test" (xinari-root)) path))
         (default-command (mapconcat
                           'identity
                           (append (list path) (when fn (list "--name" (concat "/" fn "/"))))
                           " "))
         (command (if edit-cmd-args
                      (read-string "Run w/Compilation: " default-command)
                    default-command)))
    (if path
        (ruby-compilation-run command ruby-options)
      (message "no test available"))))

(defun xinari-test-function-name()
  "Return the name of the test function at point, or nil if not found."
  (save-excursion
    (when (re-search-backward (concat "^[ \t]*\\(def\\|test\\)[ \t]+"
                                      "\\([\"'].*?[\"']\\|" ruby-symbol-re "*\\)"
                                      "[ \t]*") nil t)
      (let ((name (match-string 2)))
        (if (string-match "^[\"']\\(.*\\)[\"']$" name)
            (replace-regexp-in-string
             "\\?" "\\\\\\\\?"
             (replace-regexp-in-string " +" "_" (match-string 1 name)))
          (when (string-match "^test" name)
            name))))))

(defun xinari--rails-path ()
  "Return the path of the 'rails' command, or nil if not found."
  (let* ((script-rails (expand-file-name "rails" (xinari-script-path)))
         (bin-rails (expand-file-name "rails" (xinari-bin-path))))
    (cond
     ((file-exists-p bin-rails) bin-rails)
     ((file-exists-p script-rails) script-rails)
     (t (executable-find "rails")))))

(defun xinari--maybe-wrap-with-ruby (command-line)
  "If the first part of COMMAND-LINE is not executable, prepend with ruby."
  (if (file-executable-p (first (split-string-and-unquote command-line)))
      command-line
    (concat ruby-compilation-executable " " command-line)))

(defun xinari--wrap-rails-command (command)
  "Given a COMMAND such as 'console', return a suitable command line.
Where the corresponding script is executable, it will be run
as-is.  Otherwise, as can be the case on Windows, the command will
be prepended with `ruby-compilation-executable'."
  (let* ((default-directory (xinari-root))
         (script (xinari-script-path))
         (script-command (expand-file-name command script)))
    (if (file-exists-p script-command)
        script-command
      (concat (xinari--rails-path) " " command))))

(defun xinari-console (&optional edit-cmd-args)
  "Run a Rails console in a compilation buffer.
The buffer will support command history and links between errors
and source code.  Optional prefix argument EDIT-CMD-ARGS lets the
user edit the console command arguments."
  (interactive "P")
  (let* ((default-directory (xinari-root))
         (command (xinari--maybe-wrap-with-ruby
                   (xinari--wrap-rails-command "console"))))

    ;; Start console in correct environment.
    (when xinari-rails-env
      (setq command (concat command " " xinari-rails-env)))

    ;; For customization of the console command with prefix arg.
    (setq command (if edit-cmd-args
                      (read-string "Run Ruby: " (concat command " "))
                    command))
    (with-current-buffer (run-ruby command "rails console")
      (xinari-launch))))

(defun xinari-sql ()
  "Browse the application's database.
Looks up login information from your conf/database.sql file."
  (interactive)
  (let* ((environment (or xinari-rails-env (getenv "RAILS_ENV") "development"))
         (existing-buffer (get-buffer (concat "*SQL: " environment "*"))))
    (if existing-buffer
        (pop-to-buffer existing-buffer)
      (unless (featurep 'sql)
        (require 'sql))
      (let* ((database-yaml (xinari-parse-yaml
                             (expand-file-name
                              "database.yml"
                              (file-name-as-directory
                               (expand-file-name "config" (xinari-root))))))
             (database-alist (or (cdr (assoc (intern environment) database-yaml))
                                 (error "Couldn't parse database.yml")))
             (product (let* ((adapter (or (cdr (assoc 'adapter database-alist)) "sqlite")))
                        (cond
                         ((string-match "mysql" adapter) "mysql")
                         ((string-match "sqlite" adapter) "sqlite")
                         ((string-match "postgresql" adapter) "postgres")
                         (t adapter))))
             (port (cdr (assoc 'port database-alist)))
             (sql-login-params (or (intern-soft (concat "sql-" product "-login-params"))
                                   (error "`%s' is not a known product; use `sql-add-product' to add it first" product))))
        (with-temp-buffer
          (set (make-local-variable 'sql-user) (cdr (assoc 'username database-alist)))
          (set (make-local-variable 'sql-password) (cdr (assoc 'password database-alist)))
          (set (make-local-variable 'sql-database) (or (cdr (assoc 'database database-alist))
                                                       (when (string-match-p "sqlite" product)
                                                         (expand-file-name (concat "db/" environment ".sqlite3")
                                                                           (xinari-root)))
                                                       (concat (file-name-nondirectory
                                                                (directory-file-name (xinari-root)))
                                                               "_" environment)))
          (when (string= "sqlite" product)
            ;; Always expand sqlite DB filename relative to RAILS_ROOT
            (setq sql-database (expand-file-name sql-database (xinari-root))))
          (set (make-local-variable 'sql-server) (or (cdr (assoc 'host database-alist)) "localhost"))
          (when port
            (set (make-local-variable 'sql-port) port)
            (set (make-local-variable sql-login-params) (add-to-list sql-login-params 'port t)))
          (funcall
           (intern (concat "sql-" product))
           environment))))
    (xinari-launch)))

(defun xinari-web-server (&optional edit-cmd-args)
  "Start a Rails webserver.
Dumps output to a compilation buffer allowing jumping between
errors and source code.  Optional prefix argument EDIT-CMD-ARGS
lets the user edit the server command arguments."
  (interactive "P")
  (let* ((default-directory (xinari-root))
         (command (xinari--wrap-rails-command "server")))

    ;; Start web server in correct environment.
    (when xinari-rails-env
      (setq command (concat command " -e " xinari-rails-env)))

    ;; For customization of the web server command with prefix arg.
    (setq command (if edit-cmd-args
                      (read-string "Run Ruby: " (concat command " "))
                    command))

    (ruby-compilation-run command nil "server"))
  (xinari-launch))

(defun xinari-web-server-restart (&optional edit-cmd-args)
  "Ensure a fresh `xinari-web-server' is running, first killing any old one.
Optional prefix argument EDIT-CMD-ARGS lets the user edit the
server command arguments."
  (interactive "P")
  (let ((xinari-web-server-buffer "*server*"))
    (when (get-buffer xinari-web-server-buffer)
      (set-process-query-on-exit-flag (get-buffer-process xinari-web-server-buffer) nil)
      (kill-buffer xinari-web-server-buffer))
    (xinari-web-server edit-cmd-args)))

(defun xinari-insert-erb-skeleton (no-equals)
  "Insert an erb skeleton at point.
With optional prefix argument NO-EQUALS, don't include an '='."
  (interactive "P")
  (insert "<%")
  (insert (if no-equals "  -" "=  "))
  (insert "%>")
  (backward-char (if no-equals 4 3)))

(defun xinari-extract-partial (begin end partial-name)
  "Extracts the region from BEGIN to END into a partial called PARTIAL-NAME."
  (interactive "r\nsName your partial: ")
  (let ((path (buffer-file-name))
        (ending (xinari-ending)))
    (if (string-match "view" path)
        (let ((partial-name
               (replace-regexp-in-string "[[:space:]]+" "_" partial-name)))
          (kill-region begin end)
          (if (string-match "\\(.+\\)/\\(.+\\)" partial-name)
              (let ((default-directory (expand-file-name (match-string 1 partial-name)
                                                         (expand-file-name ".."))))
                (find-file (concat "_" (match-string 2 partial-name) ending)))
            (find-file (concat "_" partial-name ending)))
          (yank) (pop-to-buffer nil)
          (xinari-insert-partial partial-name ending))
      (message "not in a view"))))

(defun xinari-insert-output (ruby-expr ending)
  "Insert view code which outputs RUBY-EXPR, suitable for the file's ENDING."
  (let ((surround
         (cond
          ((string-match "\\.eex" ending)
           (cons "<%= " " %>"))
          ((string-match "\\.haml" ending)
           (cons "= " " ")))))
    (insert (concat (car surround) ruby-expr (cdr surround) "\n"))))

(defun xinari-insert-partial (partial-name ending)
  "Insert a call to PARTIAL-NAME, formatted for the file's ENDING.

Supported markup languages are: Erb, Haml"
  (xinari-insert-output (concat "render :partial => \"" partial-name "\"") ending))

(defun xinari-goto-partial ()
  "Visits the partial that is called on the current line."
  (interactive)
  (let ((line (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
    (when (string-match xinari-partial-regex line)
      (setq line (match-string 2 line))
      (let ((file
             (if (string-match "/" line)
                 (concat (xinari-root) "web/views/"
                         (replace-regexp-in-string "\\([^/]+\\)/\\([^/]+\\)$" "\\1/_\\2" line))
               (concat default-directory "_" line))))
        (find-file (concat file (xinari-ending)))))))

(defvar xinari-rgrep-file-endings
  "*.[^l]*"
  "Ending of files to search for matches using `xinari-rgrep'.")

(defun xinari-rgrep (&optional arg)
  "Search through the rails project for a string or `regexp'.
With optional prefix argument ARG, just run `rgrep'."
  (interactive "P")
  (grep-compute-defaults)
  (if arg
      (call-interactively 'rgrep)
    (let ((query (if mark-active
                     (buffer-substring-no-properties (point) (mark))
                   (thing-at-point 'word))))
      (funcall 'rgrep (read-from-minibuffer "search for: " query)
               xinari-rgrep-file-endings (xinari-root)))))

(defun xinari-ending ()
  "Return the file extension of the current file."
  (let* ((path (buffer-file-name))
         (ending
          (and (string-match ".+?\\(\\.[^/]*\\)$" path)
               (match-string 1 path))))
    ending))

(defun xinari-script-path ()
  "Return the absolute path to the script folder."
  (concat (file-name-as-directory (expand-file-name "script" (xinari-root)))))

(defun xinari-bin-path ()
  "Return the absolute path to the bin folder."
  (concat (file-name-as-directory (expand-file-name "bin" (xinari-root)))))

;;--------------------------------------------------------------------
;; xinari movement using jump.el

(defun xinari-generate (type name)
  "Run the generate command to generate a TYPE called NAME."
  (let* ((default-directory (xinari-root))
         (command (xinari--wrap-rails-command "generate")))
    (shell-command
     (xinari--maybe-wrap-with-ruby
      (concat command " " type " " (read-from-minibuffer (format "create %s: " type) name))))))

(defvar xinari-ruby-hash-regexp
  "\\(:[^[:space:]]*?\\)[[:space:]]*\\(=>[[:space:]]*[\"\':]?\\([^[:space:]]*?\\)[\"\']?[[:space:]]*\\)?[,){}\n]"
  "Regexp to match subsequent key => value pairs of a ruby hash.")

(defun xinari-ruby-values-from-render (controller action)
  "Return (CONTROLLER . ACTION) after adjusting for the hash values at point."
  (let ((end (save-excursion
               (re-search-forward "[^,{(]$" nil t)
               (1+ (point)))))
    (save-excursion
      (while (and (< (point) end)
                  (re-search-forward xinari-ruby-hash-regexp end t))
        (when (> (length (match-string 3)) 1)
          (case (intern (match-string 1))
            (:partial
             (let ((partial (match-string 3)))
               (if (string-match "\\(.+\\)/\\(.+\\)" partial)
                   (progn
                     (setf controller (match-string 1 partial))
                     (setf action (concat "_" (match-string 2 partial))))
                 (setf action (concat "_" partial)))))
            (:action  (setf action (match-string 3)))
            (:controller (setf controller (match-string 3)))))))
    (cons controller action)))

(defun xinari-which-render (renders)
  "Select and parse one of the RENDERS supplied."
  (let ((path (jump-completing-read
               "Follow: "
               (mapcar (lambda (lis)
                         (concat (car lis) "/" (cdr lis)))
                       renders))))
    (string-match "\\(.*\\)/\\(.*\\)" path)
    (cons (match-string 1 path) (match-string 2 path))))

(defun xinari-follow-controller-and-action (controller action)
  "Follow CONTROLLER and ACTION through to the final controller or view.
The user is prompted to follow through any intermediate renders
and redirects."
  (save-excursion ;; if we can find the controller#action pair
    (if (and (jump-to-path (format "web/controllers/%s_controller.ex#%s" controller action))
             (equalp (jump-method) action))
        (let ((start (point)) ;; demarcate the borders
              (renders (list (cons controller action))) render view)
          (ruby-forward-sexp)
          ;; collect redirection options and pursue
          (while (re-search-backward "re\\(?:direct_to\\|nder\\)" start t)
            (add-to-list 'renders (xinari-ruby-values-from-render controller action)))
          (let ((render (if (equalp 1 (length renders))
                            (car renders)
                          (xinari-which-render renders))))
            (if (and (equalp (cdr render) action)
                     (equalp (car render) controller))
                (list controller action) ;; directed to here so return
              (xinari-follow-controller-and-action (or (car render)
                                                       controller)
                                                   (or (cdr render)
                                                       action)))))
      ;; no controller entry so return
      (list controller action))))

(defvar xinari-jump-schema
 '((model
    "m"
    (("web/controllers/\\1_controller.ex#\\2$" . "web/models/\\1.ex#\\2")
     ("web/views/\\1_view.ex"                  . "web/models/\\1.ex")
     ("web/templates/\\1/.*"                   . "web/models/\\1.ex")
     ("web/helpers/\\1_helper.ex"              . "web/models/\\1.ex")
     ("db/migrate/.*create_\\1.ex"             . "web/models/\\1.ex")
     ("spec/models/\\1_spec.ex"                . "web/models/\\1.ex")
     ("spec/controllers/\\1_controller_spec.ex". "web/models/\\1.ex")
     ("spec/views/\\1/.*"                      . "web/models/\\1.ex")
     ("spec/fixtures/\\1.yml"                  . "web/models/\\1.ex")
     ("test/functional/\\1_controller_test.ex" . "web/models/\\1.ex")
     ("test/unit/\\1_test.ex#test_\\2$"        . "web/models/\\1.ex#\\2")
     ("test/unit/\\1_test.ex"                  . "web/models/\\1.ex")
     ("test/fixtures/\\1.yml"                  . "web/models/\\1.ex")
     (t                                        . "web/models/"))
    (lambda (path)
      (xinari-generate "model"
                       (and (string-match ".*/\\(.+?\\)\.ex" path)
                            (match-string 1 path)))))
   (controller
    "c"
    (("web/models/\\1.ex"                      . "web/controllers/\\1_controller.ex")
     ("web/views/\\1_view.ex"                  . "web/controllers/\\1_controller.ex")
     ("web/templates/\\1/\\2\\..*"             . "web/controllers/\\1_controller.ex#\\2")
     ("web/helpers/\\1_helper.ex"              . "web/controllers/\\1_controller.ex")
     ("db/migrate/.*create_\\1.ex"             . "web/controllers/\\1_controller.ex")
     ("spec/models/\\1_spec.ex"                . "web/controllers/\\1_controller.ex")
     ("spec/controllers/\\1_spec.ex"           . "web/controllers/\\1.ex")
     ("spec/views/\\1/\\2\\.*_spec.ex"         . "web/controllers/\\1_controller.ex#\\2")
     ("spec/fixtures/\\1.yml"                  . "web/controllers/\\1_controller.ex")
     ("test/functional/\\1_test.ex#test_\\2$"  . "web/controllers/\\1.ex#\\2")
     ("test/functional/\\1_test.ex"            . "web/controllers/\\1.ex")
     ("test/unit/\\1_test.ex#test_\\2$"        . "web/controllers/\\1_controller.ex#\\2")
     ("test/unit/\\1_test.ex"                  . "web/controllers/\\1_controller.ex")
     ("test/fixtures/\\1.yml"                  . "web/controllers/\\1_controller.ex")
     (t                                        . "web/controllers/"))
    (lambda (path)
      (xinari-generate "controller"
                       (and (string-match ".*/\\(.+?\\)_controller\.ex" path)
                            (match-string 1 path)))))
   (view
    "v"
    (("web/controllers/\\1_controller.ex"      . "web/views/\\1_view.ex")
     ("web/helpers/\\1_helper.ex"              . "web/views/\\1_view.ex")
     ("db/migrate/.*create_\\1.ex"             . "web/views/\\1_view.ex")
     ("spec/models/\\1_spec.ex"                . "web/views/\\1_view.ex")
     ("spec/controllers/\\1_spec.ex"           . "web/views/\\1_view.ex")
     ("spec/views/\\1_spec.ex"                 . "web/views/\\1_view.ex")
     ("spec/templates/\\1/\\2_spec.ex"         . "web/views/\\1_view.ex#\\2")
     ("spec/fixtures/\\1.yml"                  . "web/views/\\1_view.ex")
     ("test/functional/\\1_controller_test.ex" . "web/views/\\1_view.ex")
     ("test/unit/\\1_test.ex#test_\\2$"        . "web/views/\\1_view.ex#\\2")
     ("test/fixtures/\\1.yml"                  . "web/views/\\1_view.ex")
     (t                                        . "web/views/.*"))
    t)
   (template
    "V"
    (("web/models/\\1.ex"                      . "web/templates/\\1/.*")
     ((lambda () ;; find the controller/template
        (let* ((raw-file (and (buffer-file-name)
                              (file-name-nondirectory (buffer-file-name))))
               (file (and raw-file
                          (string-match "^\\(.*\\)_controller.ex" raw-file)
                          (match-string 1 raw-file))) ;; controller
               (raw-method (ruby-add-log-current-method))
               (method (and file raw-method ;; action
                            (string-match "#\\(.*\\)" raw-method)
                            (match-string 1 raw-method))))
          (when (and file method) (xinari-follow-controller-and-action file method))))
      . "web/templates/\\1/\\2.*")
     ("web/controllers/\\1_controller.ex"      . "web/templates/\\1/.*")
     ("web/helpers/\\1_helper.ex"              . "web/templates/\\1/.*")
     ("db/migrate/.*create_\\1.ex"             . "web/templates/\\1/.*")
     ("spec/models/\\1_spec.ex"                . "web/templates/\\1/.*")
     ("spec/controllers/\\1_spec.ex"           . "web/templates/\\1/.*")
     ("spec/views/\\1_spec.ex"                 . "web/templates/\\1/.*")
     ("spec/templates/\\1/\\2_spec.ex"         . "web/templates/\\1/\\2.*")
     ("spec/fixtures/\\1.yml"                  . "web/templates/\\1/.*")
     ("test/functional/\\1_controller_test.ex" . "web/templates/\\1/.*")
     ("test/unit/\\1_test.ex#test_\\2$"        . "web/templates/\\1/_?\\2.*")
     ("test/fixtures/\\1.yml"                  . "web/templates/\\1/.*")
     (t                                        . "web/templates/.*"))
    t)
   (test
    "t"
    (("web/models/\\1.ex#\\2$"                 . "test/unit/\\1_test.ex#test_\\2")
     ("web/controllers/\\1.ex#\\2$"            . "test/functional/\\1_test.ex#test_\\2")
     ("web/views/\\1/_?\\2\\..*"               . "test/functional/\\1_controller_test.ex#test_\\2")
     ("web/helpers/\\1_helper.ex"              . "test/functional/\\1_controller_test.ex")
     ("db/migrate/.*create_\\1.ex"             . "test/unit/\\1_test.ex")
     ("test/functional/\\1_controller_test.ex" . "test/unit/\\1_test.ex")
     ("test/unit/\\1_test.ex"                  . "test/functional/\\1_controller_test.ex")
     (t                                        . "test/.*"))
    t)
   (rspec
    "r"
    (("web/\\1\\.ex"                           . "spec/\\1_spec.ex")
     ("web/\\1$"                               . "spec/\\1_spec.ex")
     ("spec/views/\\1_spec.ex"                 . "web/views/\\1")
     ("spec/\\1_spec.ex"                       . "web/\\1.ex")
     (t                                        . "spec/.*"))
    t)
   (fixture
    "x"
    (("web/models/\\1.ex"                      . "test/fixtures/\\1.yml")
     ("web/controllers/\\1_controller.ex"      . "test/fixtures/\\1.yml")
     ("web/views/\\1/.*"                       . "test/fixtures/\\1.yml")
     ("web/helpers/\\1_helper.ex"              . "test/fixtures/\\1.yml")
     ("db/migrate/.*create_\\1.ex"             . "test/fixtures/\\1.yml")
     ("spec/models/\\1_spec.ex"                . "test/fixtures/\\1.yml")
     ("spec/controllers/\\1_controller_spec.ex". "test/fixtures/\\1.yml")
     ("spec/views/\\1/.*"                      . "test/fixtures/\\1.yml")
     ("test/functional/\\1_controller_test.ex" . "test/fixtures/\\1.yml")
     ("test/unit/\\1_test.ex"                  . "test/fixtures/\\1.yml")
     (t                                        . "test/fixtures/"))
    t)
   (rspec-fixture
    "z"
    (("web/models/\\1.ex"                      . "spec/fixtures/\\1.yml")
     ("web/controllers/\\1_controller.ex"      . "spec/fixtures/\\1.yml")
     ("web/views/\\1/.*"                       . "spec/fixtures/\\1.yml")
     ("web/helpers/\\1_helper.ex"              . "spec/fixtures/\\1.yml")
     ("db/migrate/.*create_\\1.ex"             . "spec/fixtures/\\1.yml")
     ("spec/models/\\1_spec.ex"                . "spec/fixtures/\\1.yml")
     ("spec/controllers/\\1_controller_spec.ex". "spec/fixtures/\\1.yml")
     ("spec/views/\\1/.*"                      . "spec/fixtures/\\1.yml")
     ("test/functional/\\1_controller_test.ex" . "spec/fixtures/\\1.yml")
     ("test/unit/\\1_test.ex"                  . "spec/fixtures/\\1.yml")
     (t                                        . "spec/fixtures/"))
    t)
   (helper
    "h"
    (("web/models/\\1.ex"                      . "web/helpers/\\1_helper.ex")
     ("web/controllers/\\1_controller.ex"      . "web/helpers/\\1_helper.ex")
     ("web/views/\\1/.*"                       . "web/helpers/\\1_helper.ex")
     ("web/helpers/\\1_helper.ex"              . "web/helpers/\\1_helper.ex")
     ("db/migrate/.*create_\\1.ex"             . "web/helpers/\\1_helper.ex")
     ("spec/models/\\1_spec.ex"                . "web/helpers/\\1_helper.ex")
     ("spec/controllers/\\1_spec.ex"           . "web/helpers/\\1_helper.ex")
     ("spec/views/\\1/.*"                      . "web/helpers/\\1_helper.ex")
     ("test/functional/\\1_controller_test.ex" . "web/helpers/\\1_helper.ex")
     ("test/unit/\\1_test.ex#test_\\2$"        . "web/helpers/\\1_helper.ex#\\2")
     ("test/unit/\\1_test.ex"                  . "web/helpers/\\1_helper.ex")
     (t                                        . "web/helpers/"))
    t)
   (migration
    "i"
    (("web/controllers/\\1_controller.ex"      . "db/migrate/.*create_\\1.ex")
     ("web/views/\\1/.*"                       . "db/migrate/.*create_\\1.ex")
     ("web/helpers/\\1_helper.ex"              . "db/migrate/.*create_\\1.ex")
     ("web/models/\\1.ex"                      . "db/migrate/.*create_\\1.ex")
     ("spec/models/\\1_spec.ex"                . "db/migrate/.*create_\\1.ex")
     ("spec/controllers/\\1_spec.ex"           . "db/migrate/.*create_\\1.ex")
     ("spec/views/\\1/.*"                      . "db/migrate/.*create_\\1.ex")
     ("test/functional/\\1_controller_test.ex" . "db/migrate/.*create_\\1.ex")
     ("test/unit/\\1_test.ex#test_\\2$"        . "db/migrate/.*create_\\1.ex#\\2")
     ("test/unit/\\1_test.ex"                  . "db/migrate/.*create_\\1.ex")
     (t                                        . "db/migrate/"))
    (lambda (path)
      (xinari-generate "migration"
                       (and (string-match ".*create_\\(.+?\\)\.ex" path)
                            (match-string 1 path)))))
   (cells
    "C"
    (("web/cells/\\1_cell.ex"                  . "web/cells/\\1/.*")
     ("web/cells/\\1/\\2.*"                    . "web/cells/\\1_cell.ex#\\2")
     (t                                        . "web/cells/"))
    (lambda (path)
      (xinari-generate "cells"
                       (and (string-match ".*/\\(.+?\\)_cell\.ex" path)
                            (match-string 1 path)))))
   (features        "F" ((t . "features/.*feature")) nil)
   (steps           "S" ((t . "features/step_definitions/.*")) nil)
   (environment     "e" ((t . "config/environments/")) nil)
   (application     "a" ((t . "lib/")) nil)
   (routes          "R" ((t . "web/router.ex")) nil)
   (configuration   "n" ((t . "config/")) nil)
   (script          "s" ((t . "script/")) nil)
   (lib             "l" ((t . "lib/")) nil)
   (log             "o" ((t . "log/")) nil)
   (worker          "w" ((t . "lib/workers/")) nil)
   (public          "p" ((t . "priv/")) nil)
   (stylesheet      "y" ((t . "web/static/css/.*")) nil)
   (sass            "Y" ((t . "web/css/.*")) nil)
   (javascript      "j" ((t . "web/static/js/.*")) nil)
   (plugin          "u" ((t . "web/static/vendor/")) nil)
   (mailer          "M" ((t . "web/mailers/")) nil)
   (file-in-project "f" ((t . ".*")) nil)
   (by-context
    ";"
    (((lambda () ;; Find-by-Context
        (let ((path (buffer-file-name)))
          (when (string-match ".*/\\(.+?\\)/\\(.+?\\)\\..*" path)
            (let ((cv (cons (match-string 1 path) (match-string 2 path))))
              (when (re-search-forward "<%=[ \n\r]*render(? *" nil t)
                (setf cv (xinari-ruby-values-from-render (car cv) (cdr cv)))
                (list (car cv) (cdr cv)))))))
      . "web/views/\\1/\\2.*"))))
 "Jump schema for xinari.")

(defun xinari-apply-jump-schema (schema)
  "Define the xinari-find-* functions by passing each element SCHEMA to `defjump'."
  (mapcar
   (lambda (type)
     (let ((name (first type))
           (specs (third type))
           (make (fourth type)))
       (eval `(defjump
                ,(intern (format "xinari-find-%S" name))
                ,specs
                xinari-root
                ,(format "Go to the most logical %S given the current location" name)
                ,(when make `(quote ,make))
                'ruby-add-log-current-method))))
   schema))
(xinari-apply-jump-schema xinari-jump-schema)

;;--------------------------------------------------------------------
;; minor mode and keymaps

(defvar xinari-minor-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Key map for Xinari minor mode.")

(defun xinari-bind-key-to-func (key func)
  "Bind KEY to FUNC with each of the `xinari-minor-mode-prefixes'."
  (dolist (prefix xinari-minor-mode-prefixes)
    (eval `(define-key xinari-minor-mode-map
             ,(format "\C-c%s%s" prefix key) ,func))))

(defvar xinari-minor-mode-keybindings
  '(("s" . 'xinari-script)              ("q" . 'xinari-sql)
    ("e" . 'xinari-insert-erb-skeleton) ("t" . 'xinari-test)
    ("r" . 'xinari-rake)                ("c" . 'xinari-console)
    ("w" . 'xinari-web-server)          ("g" . 'xinari-rgrep)
    ("x" . 'xinari-extract-partial)     ("p" . 'xinari-goto-partial)
    (";" . 'xinari-find-by-context)     ("'" . 'xinari-find-by-context)
    ("d" . 'xinari-cap))
  "Alist mapping of keys to functions in `xinari-minor-mode-map'.")

(dolist (el (append (mapcar (lambda (el)
                              (cons (concat "f" (second el))
                                    (read (format "'xinari-find-%S" (first el)))))
                            xinari-jump-schema)
                    xinari-minor-mode-keybindings))
  (xinari-bind-key-to-func (car el) (cdr el)))

(easy-menu-define xinari-minor-mode-menu xinari-minor-mode-map
  "Xinari menu"
  '("Xinari"
    ["Search" xinari-rgrep t]
    "---"
    ["Find file in project" xinari-find-file-in-project t]
    ["Find file by context" xinari-find-by-context t]
    ("Jump to..."
     ["Model" xinari-find-model t]
     ["Controller" xinari-find-controller t]
     ["View" xinari-find-view t]
     ["Helper" xinari-find-helper t]
     ["Worker" xinari-find-worker t]
     ["Mailer" xinari-find-mailer t]
     "---"
     ["Javascript" xinari-find-javascript t]
     ["Stylesheet" xinari-find-stylesheet t]
     ["Sass" xinari-find-sass t]
     ["public/" xinari-find-public t]
     "---"
     ["Test" xinari-find-test t]
     ["Rspec" xinari-find-rspec t]
     ["Fixture" xinari-find-fixture t]
     ["Rspec fixture" xinari-find-rspec-fixture t]
     ["Feature" xinari-find-features t]
     ["Step" xinari-find-steps t]
     "---"
     ["application.rb" xinari-find-application t]
     ["config/" xinari-find-configuration t]
     ["environments/" xinari-find-environment t]
     ["migrate/" xinari-find-migration t]
     ["lib/" xinari-find-lib t]
     ["script/" xinari-find-script t]
     ["log/" xinari-find-log t])
    "---"
    ("Web server"
     ["Start" xinari-web-server t]
     ["Restart" xinari-web-server-restart t])
    ["Console" xinari-console t]
    ["SQL prompt" xinari-sql t]
    "---"
    ["Script" xinari-script t]
    ["Rake" xinari-rake t]
    ["Cap" xinari-cap t]))

;;;###autoload
(defun xinari-launch ()
  "Call function `xinari-minor-mode' if inside a rails project.
Otherwise, disable that minor mode if currently enabled."
  (interactive)
  (let ((root (xinari-root)))
    (if root
        (let ((r-tags-path (concat root xinari-tags-file-name)))
          (set (make-local-variable 'tags-file-name)
               (and (file-exists-p r-tags-path) r-tags-path))
          (xinari-minor-mode t))
      (when xinari-minor-mode
        (xinari-minor-mode -1)))))

(defun xinari-launch-maybe ()
  "Call `xinari-launch' if customized to do so.
Both `xinari-major-modes' and `xinari-exclude-major-modes' will
be used to make the decision.  When the global xinari mode is
active, the default is to try to launch xinari in any major
mode.  If `xinari-major-modes' is non-nil, then launching will
happen only in the listed modes.  Major modes listed in
`xinari-exclude-major-modes' will never have xinari
auto-launched, but `xinari-launch' can still be used to manually
enable xinari in buffers using those modes."
  (when (and (not (minibufferp))
             (or (null xinari-major-modes)
                 (memq major-mode xinari-major-modes))
             (or (null xinari-exclude-major-modes)
                 (not (memq major-mode xinari-exclude-major-modes))))
    (xinari-launch)))

(add-hook 'mumamo-after-change-major-mode-hook 'xinari-launch)

(defadvice cd (after xinari-on-cd activate)
  "Call `xinari-launch' when changing directories.
This will activate/deactivate xinari as necessary when changing
into and out of rails project directories."
  (xinari-launch))

;;;###autoload
(define-minor-mode xinari-minor-mode
  "Enable Xinari minor mode to support working with the Ruby on Rails framework."
  nil
  " Xinari"
  xinari-minor-mode-map)

;;;###autoload
(define-global-minor-mode global-xinari-mode
  xinari-minor-mode xinari-launch-maybe)

(provide 'xinari)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; byte-compile-warnings: (not cl-functions)
;; eval: (checkdoc-minor-mode 1)
;; End:

;;; xinari.el ends here
