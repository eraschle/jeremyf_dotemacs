;;; jf-project --- Connective Tissue for Projects -*- lexical-binding: t -*-

;; Copyright (C) 2022 Jeremy Friesen
;; Author: Jeremy Friesen <jeremy@jeremyfriesen.com>

;; This file is NOT part of GNU Emacs.

;;; Commentary

;; There are three interactive functions:
;;
;; - `jf/project/jump-to/notes'
;; - `jf/project/jump-to/project-work-space'
;; - `jf/project/jump-to/timesheet'
;;
;; Let's talk of the three targets for jumping.
;;
;; Notes: Each project has an index.  The index is a place for high-level notes
;; and links to related concepts:
;;
;; Project Space: Each project has different spaces where I do work, examples
;; include the following:
;;
;; - Agenda :: Where I track time.
;; - Code :: Where I write code.
;; - Discussion :: Where I discuss the project with collaborators.
;; - Notes :: Where I take larger conceptual notes.
;; - Project board :: Where I see what's in flight.
;; - Remote :: Where I read/write issues and pull requests.
;;
;; Timesheet: For many projects, I track time.  This lets me jump to today's
;; headline for the given project.  The headline is where I record tasks to
;; which I then track time.
;;
;; Each project's index is assumed to be an `org-mode' file with two top-level
;; keywords:
;;
;; `#+PROJECT_NAME:'
;; `#+PROJECT_PATHS:'
;;
;; There should be one `#+PROJECT_NAME:' keyword and there can be many
;; `#+PROJECT_PATHS:'.  Each `#+PROJECT_PATHS:' is a `cons' cell.  The `car' is
;; the label and the `cdr' is the path.  The path can be a filename or a URL.
;;
;; The `jf/project/jump-to/project-work-space' will prompt for a project then a
;; workspace.  From there, it will jump to the corresponding location.

;;; Code

;;;; Dependencies
(require 's)
(require 'f)
(require 'pulsar)
(require 'jf-org-mode)

;;;; Interactive Commands
(cl-defun jf/project/jump-to/notes (&key project)
  "Jump to the given PROJECT's notes file.

Determine the PROJECT by querying `jf/project/list-projects'."
  (interactive)
  (let* ((project (or (s-presence project)
                    (jf/project/find-dwim)))
          (filename (cdar (jf/project/list-projects :project project))))
    (find-file filename)))

;; I work on several different projects each day; helping folks get unstuck.  I
;; also need to track and record my time.
(bind-key "C-c C-j" 'jf/project/jump-to-task)
(cl-defun jf/project/jump-to-task (&optional prefix)
  "Jump to task.

With one PREFIX go to place where we would jump on capture."
  (interactive "p")
  (require 'org-capture)
  (require 'pulsar)
  (cond
    ;; ((>= prefix 16)
    ;;   (if-let ((filename (f-join denote-journal-extras-directory "20240131T000000--time-reporting.org")))
    ;;     (progn
    ;;       (org-link-open-as-file (concat filename "::*Timeblock") nil)
    ;;       (org-next-visible-heading 1)
    ;;       (search-forward "#+BEGIN:")
    ;;       (org-dblock-update))
    ;;     (org-capture-goto-target "t")))
    ((>= prefix 4)
      (org-capture-goto-target "t"))
    (t (progn
         (call-interactively #'set-mark-command)
         (if (when (and (fboundp 'org-clocking-p) (org-clocking-p)) t)
           (progn
             (org-clock-goto)
             (goto-char (org-element-property :contents-begin (org-element-at-point))))
           ;; Jump to where we would put a project were we to capture it.
           (org-capture-goto-target "t")))))
  (pulsar-pulse-line))

(bind-key "s-2" 'jf/project/jump-to/project-work-space)
(defun jf/project/jump-to/project-work-space (project)
  "Prompt for PROJECT then workspace and open that workspace."
  (interactive (list (jf/project/find-dwim)))
  (let*
    ;; Get the project's file name
    ((filename (cdar (jf/project/list-projects :project project)))
      (paths-cons-list (jf/project/project-paths-for filename))
      (path-name (completing-read (format "Links for %s: " project) paths-cons-list nil t))
      (path (alist-get path-name paths-cons-list nil nil #'string=)))
    (cond
      ((s-starts-with? "http" path)
        (eww-browse-with-external-browser path))
      ((f-dir-p path)
        (dired path))
      ((f-file-p path)
        (if (string= "pdf" (f-ext path))
          (shell-command (concat "open " path))
          (find-file path)))
      ;; Try the path as an org-link (e.g. path == "denote:20230328T093100")
      (t (when-let* ((type-target (s-split ":" path))
                      ;; There's a registered handler for the protocol
                      ;; (e.g. "denote")
                      (follow-func (org-link-get-parameter
                                     (car type-target) :follow)))
           (funcall follow-func (cadr type-target))
           ;; We tried...and don't know how to handle this.
           (progn
             (message "WARNING: Project %s missing path name \"%s\" (with path %s)"
               project path-name path)
             (jf/project/jump-to/notes :project project)))))))

(defun jf/project/project-paths-for (filename)
  "Find the project paths for the given FILENAME.

Added in cases where we want to inject the actual file."
  (with-current-buffer (find-file-noselect filename)
    (let ((paths (cl-maplist #'read (cdar (org-collect-keywords '("PROJECT_PATHS"))))))
      (setq paths (cons (cons "Notes" filename) paths)))))

;;;; Support Functions
(cl-defun jf/project/list-projects (&key (project ".+")
                                     (directory org-directory))
  "Return a list of `cons' that match the given PROJECT.

The `car' of the `cons' is the project (e.g. \"Take on Rules\").
The `cdr' is the fully qualified path to that projects notes file.

The DIRECTORY defaults to `org-directory' but you can specify otherwise."
  (mapcar (lambda (line)
            (let* ((slugs (s-split ":" line))
                    (proj (s-trim (car (cdr slugs))))
                    (filename (s-trim (car slugs))))
              (cons proj filename)))
    (split-string-and-unquote
      (shell-command-to-string
        (concat
          "rg \"^#\\+PROJECT_NAME: +(" project ") *$\" " directory
          " --follow --only-matching --no-ignore-vcs --with-filename -r '$1' "
          "| tr '\n' '@'"))
      "@")))

(cl-defun jf/project/get-project-from/project-source-code (&key (directory org-directory))
  "Return the current \"noted\" project name.

Return nil if the current buffer is not part of a noted project.

Noted projects would be found within the given DIRECTORY."
  (when-let ((project_path_to_code_truename (cdr (project-current))))
    (let ((project_path_to_code (jf/filename/tilde-based
                                  project_path_to_code_truename)))
      ;; How to handle multiple projects?  Prompt to pick one
      (let ((filename (s-trim (shell-command-to-string
                                (concat
                                  "rg \"^#\\+PROJECT_PATHS: .*"
                                  project_path_to_code " *\\\"\" "
                                  directory " --files-with-matches "
                                  " --no-ignore-vcs --ignore-case")))))
        (unless (string-equal "" filename)
          (with-current-buffer (find-file-noselect (file-truename filename))
            (jf/project/get-project-from/current-buffer-is-project)))))))

(defun jf/project/get-project-from/current-clock ()
  "Return the current clocked project's name or nil."
  ;; This is a naive implementation that assumes a :task: has the clock.  A
  ;; :task:'s immediate ancestor is a :projects:.
  (when-let ((m (and
                  (fboundp 'org-clocking-p) ;; If this isn't set, we ain't
                  ;; clocking.
                  (org-clocking-p)
                  org-clock-marker)))
    (with-current-buffer (marker-buffer m)
      (goto-char m)
      (jf/project/get-project-from/current-buffer-is-project))))

(defun jf/project/get-project-from/current-buffer-is-project ()
  "Return the PROJECT_NAME keyword of current buffer."
  (cadar (org-collect-keywords (list "PROJECT_NAME"))))

(defun jf/project/find-dwim ()
  "Find the current project based on context.

When the `current-prefix-arg' is set always prompt for the project."
  ;; `jf/project/get-project-from/current-agenda-buffer'
  (or
    (and (not current-prefix-arg)
      (or
        (jf/project/get-project-from/current-buffer-is-project)
        (jf/project/get-project-from/current-clock)
        (jf/project/get-project-from/project-source-code)))
    (completing-read "Project: " (jf/project/list-projects))))

(defun jf/org-mode/agenda-files ()
  "Return a list of note files containing 'agenda' tag.

Uses the fd command (see https://github.com/sharkdp/fd)

We want files to have the 'projects' `denote' keyword."
  (let ((projects (mapcar (lambda (el) (cdr el)) (jf/project/list-projects))))
    ;; (dolist (file (jf/journal/list-current-journals))
    ;;   (setq projects (cons file projects)))
    ;; (when (file-exists-p jf/agenda-filename/scientist)
    ;;   (setq projects (cons jf/agenda-filename/scientist projects)))
    (when (file-exists-p jf/agenda-filename/local)
      (setq projects (cons jf/agenda-filename/local projects)))
    projects))

(transient-define-suffix jf/org-mode/agenda-files-update (&rest _)
  "Update the value of `org-agenda-files'."
  :description "Update agenda files…"
  (interactive)
  (message "Updating `org-agenda-files'")
  (setq org-agenda-files (jf/org-mode/agenda-files)))

(add-hook 'after-init-hook #'jf/org-mode/agenda-files-update)

;; (defun jf/journal/list-current-journals ()
;;   "Return the last 14 daily journal entries."
;;   (split-string-and-unquote
;;     (shell-command-to-string
;;       (concat
;;         "fd _journal --absolute-path "
;;         denote-journal-extras-directory " | sort | tail -14"))
;;   "\n"))

(cl-defun jf/alist-prompt (prompt collection &rest args)
  (let ((string (completing-read prompt collection args)))
    (cons string (alist-get string collection nil nil #'string=))))

(defun jf/org-mode/capture/project-task/find ()
  "Find the project file and position to the selected task."
  (let* ((project (completing-read "Project: " (jf/project/list-projects)))
          (filename (cdar (jf/project/list-projects :project project)))
          (name-and-task (jf/alist-prompt
                           (format "Task for %s: " project)
                           (jf/org-mode/existing-tasks filename)))
          (task-name (car name-and-task)))
    ;; Defer finding this file as long as possible.
    (find-file filename)

    (if-let ((task (cdr name-and-task)))
      ;; I like having the most recent writing close to the headline; showing a
      ;; reverse order.  This also allows me to have sub-headings within a task
      ;; and not insert content and clocks there.
      ;; (if-let ((drawer (car (org-element-map task 'drawer #'identity))))
      ;; (goto-char (org-element-property :contents-end drawer))
      ;; (goto-char (org-element-property :contents-begin task)))
      (let* ((name-and-subtask (jf/alist-prompt
                                 (format "Sub-Task for %s: " task-name)
                                 (jf/org-mode/existing-sub-tasks :task task)))
              (subtask-name (car name-and-subtask)))
        (if-let ((subtask (cdr name-and-subtask)))
          (goto-char (org-element-property :contents-end subtask))
          (if current-prefix-arg
            ;; We don't want to edit this thing
            (goto-char (org-element-property :begin task))
            (progn
              (goto-char (org-element-property :contents-end task))
              (insert "** " subtask-name "\n\n")))))
      (progn
        (goto-char (point-max))
        ;; Yes make this a top-level element.  It is easy to demote and move
        ;; around.
        (insert "* TODO " task-name " :tasks:\n\n")))))

(defun jf/org-mode/existing-tasks (&optional filename)
  "Return an alist of existing tasks in given FILENAME.

Each member's `car' is title and `cdr' is `org-mode' element.

Members of the sequence either have a tag 'tasks' or are in a todo state."
  (with-current-buffer (or (and filename (find-file-noselect filename))
                         (current-buffer))
    (mapcar (lambda (headline)
              (cons (org-element-property :title headline) headline))
      (org-element-map
        (org-element-parse-buffer 'headline)
        'headline
        (lambda (headline)
          (and
            (or (eq (org-element-property :todo-type headline) 'todo)
              (member "tasks" (org-element-property :tags headline)))
            headline))))))

(cl-defun jf/org-mode/existing-sub-tasks (&key task)
  "Return an alist of existing sub-tasks for the given TASK element.

Each member's `car' is title and `cdr' is `org-mode' element."
  (let ((subtask-level (+ 1 (org-element-property :level task))))
    (mapcar (lambda (headline)
              (cons (org-element-property :title headline) headline))
      (org-element-map
        task
        'headline
        (lambda (headline)
          (and
            (eq (org-element-property :level headline) subtask-level)
            headline))))))

(defun jf/org-mode/blog-entry? (&optional buffer)
  (when-let* ((buffer (or buffer (current-buffer)))
               (file (buffer-file-name buffer)))
    (and (denote-file-is-note-p file)
      (string-match-p "\\/blog-posts\\/" file))))

(cl-defun jf/denote? (&key (buffer (current-buffer)))
  (when-let* ((file (buffer-file-name buffer)))
    (denote-file-is-note-p file)))

(transient-define-suffix jf/project/convert-document-to-project (&optional buffer)
  "Conditionally convert the current BUFFER to a project.

This encodes the logic for creating a project."
  :description "Convert to project…"
  (interactive)
  (let ((buffer (or buffer (current-buffer))))
    (with-current-buffer buffer
      (if-let* ((file (buffer-file-name buffer))
                 (_proceed (and
                             (denote-file-is-note-p file)
                             (derived-mode-p 'org-mode)
                             (not (jf/project/get-project-from/current-buffer-is-project))))
                 (existing-title (org-get-title))
                 (file-type (denote-filetype-heuristics file)))
        (let ((keywords
                (denote-retrieve-keywords-value file file-type)))
          ;; The 5th line is after the `denote' file metadata
          (goto-line 5)
          (insert "\n#+PROJECT_NAME: " existing-title
            "\n#+CATEGORY: " existing-title)
          (setq keywords (cons "projects" keywords))
          (denote-rewrite-keywords file keywords file-type)
          (call-interactively #'denote-rename-file-using-front-matter))
        (user-error "Unable to convert buffer to project")))))

(transient-define-suffix jf/project/add-project-path (label path)
  "Add a PROJECT_PATH `org-mode' keyword to buffer.

This encodes the logic for creating a project."
  :description "Add project path…"
  (interactive (list
                 (read-string "Label: ")
                 (read-string "Path: ")))
  (save-excursion
    (goto-char (point-min))
    (let ((case-fold-search t))
      (if (or
            (re-search-forward "^#\\+PROJECT_PATHS:" nil t)
            (re-search-forward "^#\\+PROJECT_NAME:" nil t))
        (end-of-line)
        (progn (goto-line 6) (re-search-forward "^$" nil t)))
      (insert "\n#+PROJECT_PATHS: (\"" (s-trim label) "\" . \"" (s-trim path) "\")"))))


(provide 'jf-project)
;;; jf-project.el ends here
