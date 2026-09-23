(defconst mine/org-roam-writing-dir (expand-file-name "~/Private/org-roam/Writing/.dictionary"))
(defconst work-computer				(string= (getenv "WORK_COMPUTER") "true")
  "When true, the computer this instance of Emacs is running on is our work laptop.")
(defconst documents-dir				"~/Documents/")
(defconst generic-server-dir		"~/generic-cache-server/")
(defconst cease-language-dir		"~/cease/")
(defconst PRIVATE-DIR (expand-file-name "~/Private/"))
(defconst documents-dir "~/Private/Documents/")

(defvar evil-point-before nil)
(defvar cw-pre-yank-point)
(defvar cw-pre-yank-length)
(defvar quick-open-vaion "~/go/src/repo.jazznetworks.com/vaion/vaion/")
(defvar quick-open-vaion-go (concat quick-open-vaion "go/"))
(defvar quick-open-vaion-vms (concat quick-open-vaion-go "vms/"))
(defvar quick-open-shell (concat PRIVATE-DIR "shell/"))
(defvar kill-other-buffers-exceptions '("*dashboard*" "*scratch*"))
(defvar cw-origin nil
  "Place from which we will count words. When set automatically becomes buffer local.")
(defvar git-message-mode nil
  "True if this emacs instance was called with the --git option. In this case, do a sparse load, which makes it faster.")
(defvar debug-flag nil
  "When true, many functions written by me will print debug information as they execute")
(defvar mine--org-roam-node-tags nil
  "A directory-local variable which defines the tag that is to be used by
`mine--org-roam-node-insert' and `mine--org-roam-node-find'.")
(defvar skeleton-custom-alist '(("(" . ")")
				("{" . "}")
				("<" . ">")
								("[" . "]")
								("\"" . "\""))
  "Alist of all skeleton pairs I use")

(defvar default-font-size 120
  "Size of text depending on the screen I use. Will change standard font size, minibuffer prompt, and mod line.")

(defvar macro-details nil
  "Maps macros and their details - how many arguments they have, and
whether they allow duplicated values for each of the arguments.

It's an alist with the form (MACRO-NAME HINT ARGS...) in which each hint
and arg come as pairs which correspond to the macro's arguments. Hint is
displayed to the user for each argument when inserting the macro, and
args is one of the following:

  - :unique: This must only appear once. This means once IN ANY MACRO.
	Not just this one marco type. Serves as a definition.
  - :match: Must match any :unique argument of another macro. Serves as
	a reference to a :unique definition.
  - :ignore: Isn't checked for matching or uniqueness.

The number of arguments corresponds to how many arguments the macro
expects. The user will be required to fill in all of them.

Example:

	setq-local macro-details
		'((\"name1\" \"arg 1 hint\" :unique)
		  (\"name2\" \"arg 2 hint\" :ignore))
")

(defvar org-move-headings-alist nil
  "Used by `org-todo--advice-heading-movement' to determine which todo state maps onto which heading.

It maps a filename to an alist which maps todo states to headings:

	 '(FILENAME . ((TODO . TODOs)
					(DONE . DONEs)))

By default, after moving the heading,
`org-todo--advice-heading-movement' moves point to the new
location. If you want to disable that behaviour for a particular
TODO state, you can add a flag like this:

	  '(FILENAME . ((DONE  . DONEs :stay))")


(defcustom mermaid--indent-width 2
  "How many spaces a mermaid block should be indented by")
(defcustom quick-open-last-project-dir ""
  "The subdirectory of `quick-open-vaion' (beginning without and ending with \"/\") that we want to open even more quickly.")


(defface writing-face '((t :family "Verdana" :inherit default))
  "The face for writing books.")

(set-face-attribute 'default nil :height default-font-size)
(set-face-attribute 'minibuffer-prompt nil :height (if work-computer 90 130))
(set-face-attribute 'mode-line nil :height 100)
(set-face-attribute 'mode-line-inactive nil :height 100)
(set-face-attribute 'minibuffer-prompt nil :height 100)


(unless (and (boundp 'pos-bol) (functionp 'pos-bol))
  (defalias 'pos-bol #'point-at-bol)
  (defalias 'pos-eol #'point-at-eol))


(make-variable-buffer-local 'evil-point-before)
(make-variable-buffer-local 'debug-flag)
(make-variable-buffer-local 'cw-origin)
(make-variable-buffer-local 'cw-pre-yank-length)
(make-variable-buffer-local 'cw-pre-yank-point)

(defun safe-indent (&rest a)
  (interactive (list ""))
  (when (member major-mode '(go-mode emacs-lisp-mode))
    (let ((tab-always-indent t))
      (indent-for-tab-command))))

(defun delete-space-lines (argument1)
  (safe-indent)
  (when (= (point) (save-excursion (back-to-indentation) (point)))
    (delete-region (point) (pos-bol))))

(defun toggle-selective-display (column)
  (interactive "P")
  (set-selective-display
   (or column
       (unless selective-display
         (1+ (current-column))))))

(defun toggle-hiding (column)
  (interactive "P")
  (if hs-minor-mode
      (if (condition-case nil
              (hs-toggle-hiding)
            (error t))
          (hs-show-all))
    (toggle-selective-display column)))

(defun inside-string-p ()
  "Returns non-nil if inside string, else nil.
This depends on major mode having setup syntax table properly."
  (interactive)
  (let ((result (nth 3 (syntax-ppss))))
    (message "%s" result)
    result))

(defun inside-open-string-p ()
  "Returns non-nil if inside a string which is opened but not
 closed in the buffer."
  (when (inside-string-p)
    (print-debug "inside string")
    (let ((count 0))
      (save-excursion
        (while (or (when (looking-at "\"")
                     (forward-char 1)
                     (print-debug "Found empty string")
                     1)
                   (re-search-forward "\[^\\]\"" nil t))
          (cl-incf count)))
      ;; \"
      (print-debug "%d quotes" count)
      (= 0 (% count 2)))))

(defun skeleton-insert-end (arg)
  "Insert the ending of a skeleton pair, but only if we aren't looking right at it ( {....|} + '}' -> {....}| ).

For the double quote, this means call `skeleton-pair-insert-maybe' if we aren't looking at a double quotation mark, and skip it if we are.

ARG says how many times to insert the character."
  (interactive "*P")
  (let ((letter last-command-event)
        (pos (point))
        quote-follows)
    (if (looking-at (format "%c" letter))
        (forward-char 1)
      (if (equal letter ?\")
          ;; Only insert "" if we aren't inside an open string.
          ;; Insert one " if we are
          (if (inside-open-string-p)
              (progn 
                (print-debug "Insie open string")
                (insert "\""))
            ;; Not inside an open string -> do normal skeleton pair insert
            (print-debug "Outside open string")
            (skeleton-pair-insert-maybe arg))
        (print-debug "Not inserting double quotes")
        (self-insert-command (prefix-numeric-value arg))))))

(defun skeleton-delete--advice (arg)
  "Delete backwards with `evil-delete-backward-char-and-join', but with the change that if we are deleting from within an immediate skeleton pair ( {|} or [|],... ), we delete both: {|} -> |."
  (let ((pos (point))
        (last-letter (buffer-substring-no-properties (1- (point)) (point)))
        matched-pair)
    (setq matched-pair (cdr (assoc last-letter skeleton-custom-alist)))
    (when (and matched-pair
               (looking-at matched-pair))
      (delete-forward-char 1))))

;; This will be used in the mode below
(defun insert-specific-string (arg)
  "Inserts a string given by a local variable `insertion-string'. If string contains \"^^\", ends with the cursor in that place, and deletes the ^^.

When ARG is given, do NOT go to the ^^ place, but delete the ^^ nonetheless."
  (interactive "P")
  (unless (boundp 'insertion-string)
    (error "you did not declare the variable \"insertion-string\"."))
  (let* ((place (cl-search "^^" insertion-string))
         (start (point))
         (respect-indent (save-excursion (beginning-of-line)
                                         (string-match-p
                                          "^[ \n]*$"
                                          (buffer-substring-no-properties (point) start))))
         end indent)

    (when respect-indent
      (setq indent (current-column)))

    (insert insertion-string)
    (setq end (point))

    ;; Do indentation
    (when respect-indent
      (goto-char start)
      (forward-line)
      (while (< (pos-bol) end)
        (indent-to indent)
        (forward-line)
        (cl-incf end indent))
      (goto-char end))

    ;; Handle ^^
    (when place
      (cl-incf end -2)
      (goto-char start)
      (forward-char place)
      (delete-forward-char 2))

    (when arg
      (goto-char end))))

(defun insert-specific-next-mark (arg)
  "Jumpst to the next point in the text that has '^^', deletes them, and stays in place. This only works if `specific-string-insertion-mode' is enabled.

Argument ARG (prefix argument) jumps that many marks."
  (interactive "p")
  (re-search-forward "\\^\\^" (buffer-end 1) t arg)
  (backward-delete-char 2)
  (indent-for-tab-command)
  (when evil-local-mode (evil-insert 1)))

(defun olivetti-80 (arg)
  "Sets olivetti mode in current buffer and gives it either width 80 or value of prefix argument."
  (interactive (list current-prefix-arg))
  (olivetti-mode 1)
  (olivetti-set-width (cond ((null arg)
                             80)
                            ((< arg 10)
                             (string-to-number (format "0.%d" arg)))
                            (t arg))))

(defun markdown-html (buffer)
  "Custom function which helps us render markdown in the browser"
  (princ (with-current-buffer buffer
		   (format "<!DOCTYPE html><html><title>Impatient Markdown</title><xmp theme=\"united\" style=\"display:none;\"> %s  </xmp><script src=\"http://ndossougbe.github.io/strapdown/dist/strapdown.js\"></script></html>" (buffer-substring-no-properties (point-min) (point-max))))
		 (current-buffer)))

(defun get-proper-newline (func &rest arg)
	"If inside a () or {} or [], and want to get newline make it into:

				  blabla {
					  |
				  }

			  This is meant as advice, so don't use it alone. FUNC is most likely `newline'. For that reason, ARG and INTERACTIVE are here - to be passed to `newline'"
	(interactive (list nil nil))
	(if (save-excursion
		  (if (bobp)
			  nil
			(backward-char 1)
			(or (looking-at "{}")
				(looking-at "()")
				(looking-at "\\[\\]"))))
		(progn (insert "\n")
			   (open-line-and-indent))
	  (newline-and-indent)))

(defun mine/git-commit-hooks ()
  (auto-fill-mode -1))

(defun mine/set-single-quotes-as-primary ()
  "Emacs treats double-quotes as 'primary quotes.' During exports, the
smart quote feature treats a 'primary quote' as the outer-most quote in
direct speech. So even if you're exporting into single-quote direct
speech (surrounded by single quotes), you need to use \" in Emacs,
otherwise the exporter will think that ' is an apostrophe no matter
where it appears.

This function will tell the latex exporter that \" is actually to be
translated into the (smart) single-quoted variant. Accordingly, it sets
' to be transated into \"."
  (let ((en-cell (assoc "en" org-export-smart-quotes-alist)))
    (when en-cell
	  (setf (cdr (assoc "en" org-export-smart-quotes-alist))
        '((primary-opening   :utf-8 "‘" :html "&ldquo;" :latex "‘" :texinfo "``")
          (primary-closing   :utf-8 "’" :html "&rdquo;" :latex "’" :texinfo "''")
          (secondary-opening :utf-8 "“" :html "&lsquo;" :latex "``"  :texinfo "`")
          (secondary-closing :utf-8 "”" :html "&rsquo;" :latex "''"  :texinfo "'")
          (apostrophe        :utf-8 "’" :html "&rsquo;"))))))

(defun mine/do-not-use-parts-in-books ()
  "Org mode export treats whatever is the highest heading in the file as a
latex \\part. Parts are weird, with extra blank pages etc. This function
makes the top heading be a \\chapter instead, which is generally what
you want."
  (setf (alist-get "book" org-latex-classes nil nil #'equal)
      '("\\documentclass[oneside]{book}"
        ("\\chapter{%s}" . "\\chapter*{%s}")
        ("\\section{%s}" . "\\section*{%s}")
        ("\\subsection{%s}" . "\\subsection*{%s}")
        ("\\subsubsection{%s}" . "\\subsubsection*{%s}"))))

(defun mine/make-buffer-typewriter (use-parts)
  "Turns the current buffer into a novel-writing environment, adjusting the
font, colours, styles, etc. accordingly.

Call this function in an eval block at the top of the file.

USE-PARTS controls whether the top-level headings (i.e., the highest
heading level in the file) should be treated as a book section or a book
chapter. Sections are surrounded by blank pages, whereas chapters are
preceded by a page break, but aren't followed by one.

There is an export setup file that you should use in a book document.
Check out the org-roam/Writing/Stories directory."
  (interactive)
  (buffer-face-set 'writing-face)
  (org-num-mode 1)
  (setq-local line-spacing 0.3)
  (face-remap-add-relative 'default :background "black")
  (face-remap-add-relative 'region :background "#84aa55" :foreground "#810c76")
  (setq-local org-adapt-indentation nil)
  (setq-local org-yank-adjusted-subtrees nil)
  (auto-fill-mode -1)
  (olivetti-80 80)
  (mine/set-single-quotes-as-primary)
  (centred-cursor-double-mode 1)
  (unless use-parts (mine/do-not-use-parts-in-books))
  (highlight-phrase "\"[^\"]+\"" 'diary-time)
  (setq-local global-hl-line-mode nil)
  (display-line-numbers-mode -1))

(defun mine/backwards-delete-directory-name (arg)
  "Deletes the whole directory name at once while in the minibuffer prompt.
With a prefix argument, delete that many directories instead."
  (interactive "P")

  (let ((num-dirs (prefix-numeric-value arg))
		(start-position (point)))
	(skip-syntax-backward "-")
	(unless (= (point) start-position)
	  (delete-region (point) start-position))
	
	(zap-up-to-char (- num-dirs) ?/ nil)))

(defun my-minibuffer-setup ()
  (unless work-computer
    (set (make-local-variable 'face-remapping-alist)
         '((default :height 100)))))

(defun find-file-only-window (filename &optional wildcards)
  (interactive (find-file-read-args "Find file in lonely window: "
                                    (confirm-nonexistent-file-or-buffer)))
  (delete-other-windows)
  (find-file filename wildcards))

;; kill buffer in other window and it's window
(defun kill-other-buffer-and-window ()
  "Kills the other window and it's windown with it."
  (interactive)
  (other-window 1)
  (kill-buffer-and-window))

(defun for-all-occurrences (regex operation &optional limit)
  "Perform OPERATION (function without arguments) on all occurances of
REGEX in the buffer, or LIMIT number of times, starting from the first
occurrence.

The occurrences are found in a loop with `re-search-forward'."
  (save-excursion
    (beginning-of-buffer)
    (while (re-search-forward regex nil t (or limit nil))
      (funcall operation))))

(defun remove-elements (ELEMENTS LIST)
  "Remove all elements of list ELEMENTS from list LIST and return the new
list."
  (dolist (element ELEMENTS LIST)
    (setq LIST (delete element LIST))))

(defun kill-other-buffers-and-windows (&optional arg)
  "If no prefix is given, closes all other buffers and windows (windows
only with no prefix) except for GNU Emacs. With the prefix C-u, also
kills GNU Emacs. With C-u C-u kills only the \"useless\" buffers, i.e.
all starting with *, except *shell*."
  (interactive "p")
  ;; as 'arg' is 'p', the default value is '1'.
  ;; the version for killing just the "useful" buffers has the default.
  (if (y-or-n-p "Are you sure you want to kill other buffers? ")
      (progn
        (delete-other-windows)
        (cond ((equal arg 16) (progn
                                (mapc 'kill-buffer
                                      (delq (current-buffer) (buffer-list)))
                                (message "Killed all other buffers.")))
              ((equal arg 4) (progn
                               (mapc (lambda (buffer) (if (not (buffer-file-name buffer))
                                                          (kill-buffer buffer)))
                                     (delq (get-buffer "*terminal*")
                                           (delq (current-buffer)
                                                 (delq (get-buffer "*scratch*") (buffer-list)))))
                               (message "Killed all \"useless\" buffers except shell and scratch.")))
              (t (progn (mapc 'kill-buffer
                              (let (buffers)
                                (remove-elements (cons (buffer-name (current-buffer)) kill-other-buffers-exceptions)
                                                 (progn (mapc (lambda (buffer)
                                                                (setq buffers (cons (buffer-name buffer) buffers)))
                                                              (buffer-list))
                                                        buffers))))
                        (message "Killed all other buffers except shell and scratch.")))))))

(defun kill-other-buffers-add-buffer (&optional BUFFER)
  "Add a buffer (or a list of buffers) which is/are not to be closed upon calling `kill-other-buffers-and-windows'."
  (interactive "p")
  (if (or (= BUFFER 4) (listp BUFFER))
      ;; Called with a prefix argument - will ask for a buffer name to add
      ;; Or called from code, and received a list
      (if (number-or-marker-p BUFFER)
          (let ((buffer (read-buffer "Buffer to add: ")))
            (setq kill-other-buffers-exceptions (cons buffer kill-other-buffers-exceptions)))
        (unless (listp BUFFER)
          (error "You must provide a list of buffer names"))
        (setq kill-other-buffers-exceptions (append kill-other-buffers-exceptions BUFFER)))
    ;; Not called from code and not called with prefix -> use current buffer
    (setq kill-other-buffers-exceptions (cons (buffer-name (current-buffer)) kill-other-buffers-exceptions)))
  (message "Buffers added."))

(defun kill-other-buffers-reset-exceptions ()
  (interactive)
  (setq kill-other-buffers-exception '("*terminal*" "*scratch*")))

(defun kill-other-buffers-remove-buffer (&optional BUFFER)
  (interactive "p")
  (if (or (= BUFFER 4) (listp BUFFER))
      ;; Called with a prefix argument - will ask for a buffer name to remove
      ;; Or called from code, and received a list
      (if (number-or-marker-p BUFFER)
          (let ((buffer (read-buffer "Buffer to remove: ")))
            (setq kill-other-buffers-exceptions (remove buffer kill-other-buffers-exceptions)))
        (unless (listp BUFFER)
          (error "You must provide a list of buffer names"))
        (setq kill-other-buffers-exceptions (remove-elements BUFFER kill-other-buffers-exceptions)))
    ;; Not called from code and not called with prefix -> use current buffer
    (setq kill-other-buffers-exceptions (remove (buffer-name (current-buffer)) kill-other-buffers-exceptions)))
  (message "Buffers removed."))

(defun open-line-and-indent ()
  (interactive)
  (save-excursion
    (newline-and-indent))
  (indent-for-tab-command))

(defun open-line-at-end-of-line ()
  (interactive)
  (save-excursion
    (end-of-line)
    (open-line 1)))

(defun copy-from-bellow-command (&optional arg)
  "Copy characters from previous nonblank line, starting just above point.
Copy ARG characters, but not past the end of that line.
If no argument given, copy the entire rest of the line.
The characters copied are inserted in the buffer before point."
  (interactive "P")
  (let ((cc (current-column))
        n
        (string ""))
    (save-excursion
      (end-of-line)
      (forward-char 1)
      (skip-chars-forward "\ \t\n")
      (move-to-column cc)
      ;; Default is enough to copy the whole rest of the line.
      (setq n (if arg (prefix-numeric-value arg) (point-max)))
      ;; If current column winds up in middle of a tab,
      ;; copy appropriate number of "virtual" space chars.
      (if (< cc (current-column))
          (if (= (preceding-char) ?\t)
              (progn
                (setq string (make-string (min n (- (current-column) cc)) ?\s))
                (setq n (- n (min n (- (current-column) cc)))))
            ;; In middle of ctl char => copy that whole char.
            (backward-char 1)))
      (setq string (concat string
                           (buffer-substring
                            (point)
                            (min (line-end-position)
                                 (+ n (point)))))))
    (insert string)))

(defun forward-word-beginning (&optional ARG)
  (interactive "p")
  (forward-char)
  (if (re-search-forward "\\<\\w" nil t ARG)
      (backward-char)
    (end-of-buffer)))

(defun backward-word-end (&optional ARG)
  (interactive "p")
  (backward-char)
  (if (re-search-backward "\\w\\>" nil t ARG)
      (forward-char)
    (beginning-of-buffer)))

(defun upcase-prev-word ()
  "Makes all the letters in the previous word upper case. Like `upcase-word', but backwards."
  (interactive)
  (upcase-word -1))

(defun downcase-prev-word ()
  "Downcases the previous word, like `downcase-word', but backwards."
  (interactive)
  (downcase-word -1))

(defun capitalize-prev-word ()
  "Capitalizes the previous word, like `capitalize-word', but backwards."
  (interactive)
  (capitalize-word -1))

(defun kill-backward-paragraph ()
  (interactive)
  (let ((sentence-end-double-space t))
    (backward-kill-sentence)))

(defun kill-forward-paragraph ()
  (interactive)
  (let ((sentence-end-double-space t))
    (kill-sentence)))

(defun backward-sentence-double-space ()
  "Acts like `backward-sentese', but treats a single space to be the end of a sentence, rather that two or newline."
  (interactive)
  (let ((sentence-end-double-space t))
    (backward-sentence)))

;; change appropriate spaces into non-breaking spaces for Czech
(defun text-set-spaces-to-non-breaking ()
  (interactive)
  (save-excursion
    (let ((letters '("z" "s" "v" "u" "o" "k"))
          end)
      (beginning-of-buffer)
      (mapcar (lambda (STRING)
                (while (search-forward-regexp (format "\\<%s\\( +\\|\n\\)" STRING) nil t)
                  (setq end (point))
                  (skip-chars-backward " \n\t")
                  (delete-region (point) end)
                  (insert " "))
                (beginning-of-buffer))
              letters))))

;; Going forward and backward a sentence, rather than a paragraph
(defun forward-sentence-double-space ()
  "Acts like `forward-sentese', but treats a single space to be the end of a sentence, rather that two or newline."
  (interactive)
  (let ((sentence-end-double-space t))
    (forward-sentence)))

(defun wc-set-mark ()
  (interactive)
  (wc-mode 1)
  (setq wc-orig-words (count-words (buffer-end -1)
                                   (point)))
  (force-mode-line-update))

(defun Im-at-home ()
  "Changes the font size to `home-font-size'."
  (interactive)
  (set-face-attribute 'default nil :height home-font-size))

(defun Im-at-work ()
  "Changes the font size to `work-font-size'."
  (interactive)
  (set-face-attribute 'default nil :height work-font-size))

(defun find-file-and-line (filename)
  (interactive "sFile with line: ")
  (setq filename (replace-regexp-in-string "//" "/" filename))
  (setq filename (string-clean-whitespace filename))
  (let* ((matched	  (string-match-p ".*:[0-9]+" filename))
         (file-simple (if matched (car (split-string filename ":" t)) filename))
         (line-num    (if matched (string-to-number (cadr (split-string filename ":" t))) 0))

         (projectile-root (projectile-acquire-root))
         (all-choices     (projectile-dir-files-alien projectile-root))
         (valid-choices   (remove-if-not
                           (lambda (file)
                             (and (string-match-p file-simple file)
                                  (file-exists-p (concat projectile-root file))))
                           all-choices)))

    (print-debug (format
                  "file %s:%s; root %s; choices %s"
                  file-simple line-num projectile-root valid-choices))

    (cond ((length< valid-choices 1) (error "No such files %s" file-simple))
          ((length= valid-choices 1) (find-file (expand-file-name (concat projectile-root (car valid-choices)))))
          (t						 (find-file (expand-file-name
                                                 (concat projectile-root
                                                         (selectrum-completing-read
                                                          "Which file: "
                                                          valid-choices))))))

    (goto-line line-num)))

(defalias 'em #'find-file-and-line)

(defun cw-count (start end &optional arg full)
  "Count the number of words with respect to a given point.

With no prefix argument, counts the number of words from the
first item in `cw-origin' to the end of the buffer.

With one \\[universal-argument], do as above, but use the LAST
item in `cw-origin', that is the one, which was set first with
`cw-set-origin'.

With two \\[universal-argument], pick the index of the item in
`cw-origin' to use. In the future should be made more intuitive,
interactive and simple to use."
  (interactive (if (region-active-p)
                   (list (region-beginning) (region-end) (car current-prefix-arg))
                 (list (car cw-origin) (buffer-end 1) (car current-prefix-arg))))
  (when (and
         (if (null current-prefix-arg)
             t
           (not (= 64 arg)))
         (not (region-active-p))
         (null cw-origin)
         (not full))
    (error "Mark is not set in the current buffer. Set it with \"C-`\" or use \"count-words-region\" (M-=)."))

  (when (not (null current-prefix-arg))
    (cond ((= 4 arg) (setq start (car (last cw-origin))))
          ((= 16 arg) (setq start (nth (read-number
                                        (format "Pick number in range 0-%d " (1- (length cw-origin))))
                                       cw-origin)))
          ((<= 64 arg) (setq start (point)))))
  (let ((words (count-words-region start end)))
    (cond ((region-active-p)
           (message (format "The region's words: %s" words)))
          ((<= 64 (if (null arg)
                      1
                    arg))
           (message (format "Words until end of buffer: %s" words)))
          (t (message (format "Words since mark: %s" words))))))

(defun cw-special-count (&optional arg)
  "Counts the number of words in a special region.

With no prefix argument, give number of words in whole buffer.
With single \\[universal-argument], limit region between the point and the first in `cw-origin'.
With double \\[universal-argument], ask which item in `cw-origin' to use, and continue as above.

This function calls `cw-count'."
  (interactive "p")
  (when (and (null cw-origin) (not (= arg 4)))
    (error "Mark is not set in the current buffer. Set it with \"C-`\" or use \"count-words-region\" (M-=)."))
  (cond ((= arg 4) (message (format "Words in buffer: %d" (count-words-region (point-min) (point-max)))))
        ((= arg 1) (message (format "Words between point and mark: %d" (count-words-region (point) (car cw-origin)))))
        ((= arg 64) (goto-char (nth (read-number
                                     (format "Pick number in range 0-%d to go to " (1- (length cw-origin))))
                                    cw-origin)))
        (t (cw-count (point) (nth (read-number
                                   (format "Pick number in range 0-%d " (1- (length cw-origin))))
                                  cw-origin)
                     1))))

(defun cw-set-origin (POINT)
  "Sets `cw-origin' by pushing the new value on the list, so no
value in a buffer is ever lost."
  (interactive "d")
  (cond ((null cw-origin) (progn (unless (member POINT cw-origin)
                                   (push POINT cw-origin))
                                 (message "cw-origin set")))
        ((member POINT (cdr cw-origin)) (if (y-or-n-p "This point is already set. Do you wish to move it forward? ")
                                            (progn (setq cw-origin (remove POINT cw-origin))
                                                   (push POINT cw-origin)
                                                   (message "Point pushed on top of cw-origin"))
                                          (message "Nothing changed")))
        ((not (equal POINT (car cw-origin))) (if (y-or-n-p "cw-origin is set already in this buffer. Do you want to reset it? ")
                                                 (progn (push POINT cw-origin)
                                                        (message "cw-origin set"))
                                               (message "Nothing changed")))))

(defun find-file-below (filename &optional wildcards)
  "Find file in window below (if only one window open)."
  (interactive
   (find-file-read-args "Find file in other window: "
                        (confirm-nonexistent-file-or-buffer)))
  (let ((split-width-threshold 999))
    (find-file-other-window filename wildcards)))

(defun switch-to-buffer-below (buffer-or-name &optional norecord)
  "Switch to a new buffer which will open in a window below, regardless of `split-width-threshold' and `split-height-threshold'."
  (interactive
   (list (read-buffer-to-switch "Switch to buffer in other window: ")))
  (let ((split-width-threshold 999))
    (switch-to-buffer-other-window buffer-or-name norecord)))

(defun clone-indirect-buffer-below (newname display-flag &optional norecord)
  "When a single window is open, clone it into a new window, which appears below regardless of the system-wide `split-width-threshold' and `split-height-threshold' values."
  (interactive
   (progn
     (if (get major-mode 'no-clone-indirect)
         (error "Cannot indirectly clone a buffer in %s mode" mode-name))
     (list (if current-prefix-arg
               (read-buffer "Name of indirect buffer: " (current-buffer)))
           t)))
  (let ((split-width-threshold 9999)) 	; Set it too high to always split vertically
    (clone-indirect-buffer-other-window newname display-flag norecord)))

(defun split-n-ways (N)
  "Split window into NxN windows of equal size"
  (interactive "p")
  (delete-other-windows)
  (dotimes (a N)
    (split-window-below)
    (dotimes (b (1- N))
      (split-window-right)
      (other-window 1))
    (other-window 1))
  (delete-window)
  (balance-windows))

(defun clone-indirect-buffer-other-window-new-name ()
  "Clone the buffer using `clone-indirect-buffer-other-window', but ask for the name of the new buffer."
  (interactive)
  (let ((new-name (read-string "New buffer's name: ")))
    (clone-indirect-buffer-other-window new-name t)))

(defun print-debug (msg &rest args)
  "If `debug-flag' is true, prints debug message MSG. If ARGS are
non-nil, MSG is treated as a format string."
  (when debug-flag
    (if args
        (eval (list 'y-or-n-p (cons 'format (cons msg (if (listp (car args)) (list `(quote ,args)) args)))))
      ;; (eval (list 'y-or-n-p (flatten-tree (list 'format msg args))))
      (y-or-n-p msg))))

(defun toggle-print-debug (&optional arg)
  "Toggle `debug-flag'. If called with a negative argument, set
`debug-flag' to nil. If called with a positive argument, set it
to t."
  (interactive "P")
  (cond ((not arg) (progn (setq debug-flag (null debug-flag))
                          (message "Debug toggled to %s" debug-flag)))
        ((> (car arg) 0) (progn (setq debug-flag t)
                                (message "Debug toggled to %s" debug-flag)))
        ((< (car arg) 0) (progn (setq debug-flag nil)
                                (message "Debug toggled to %s" debug-flag)))))

(defun backward-kill-word-and-some (ARG POINT)
  "Kills word backwards using `backward-kill-word' and then kills further, until a non-whitespace character is hit. If the character immediately before the word is not-whitespace, kill until the end of the last word, unless there is a whitespace in-between, in which case kill those characters after the whitespace, and then stop as before. If the character immediatelly before point is not a word, kill until you get to it."
  (interactive "p\nd")
  (if (looking-at "\\>")
      (progn
        (re-search-backward "\\<" nil t)
        ;; (search-forward "\n" (- POINT 1) t)
        (delete-region (point) POINT)
        (setq POINT (point))
        (unless (= (point) (pos-bol))
          (re-search-backward "\\>" nil t)
          (let ((subs (buffer-substring-no-properties (point) POINT)))
            (if (or (cl-search " " subs) (cl-search "\n" subs) (cl-search "\t" subs))
                (progn (re-search-forward "[ \t\n]")
                       (skip-chars-backward " \t\n")))
            (delete-region (point) POINT))))
    (re-search-backward "\\>" nil t)
    (delete-region (point) POINT)))

(defun forward-kill-word-and-some (ARG POINT)
  (interactive "p\nd")
  (if (looking-at "\\<")
      (progn (kill-word 1)
             (setq POINT (point))
             (when (looking-at "[ \t\n]+")
               (skip-chars-forward " \t\n")
               (delete-region POINT (point))))	
    (re-search-forward "\\<" nil t)
    (delete-region POINT (point))))

(defun backward-delete-last-char (ARG)
  "Delete ARG characters from the end of the previous word."
  (interactive "p")
  (backward-word-end)
  (backward-delete-char-untabify ARG))

(defun unfill-paragraph (&optional region)
  "Takes a multi-line paragraph and makes it into a single line of text."
  (interactive (progn (barf-if-buffer-read-only) '(t)))
  (let ((fill-column (point-max))
        ;; This would override `fill-column' if it's an integer.
        (emacs-lisp-docstring-fill-column t))
    (fill-paragraph nil region)))

(defun my--print-all-macros (&optional macro-name)
  "Print macros matching MACRO-NAME into an indirect buffer. If no
MACRO-NAME is given, we print all macros.

Only the first argument is printed, as that is usually the name of the
link. The output is also de-duplicated."
  (interactive)
  (let* ((all-macros (get-all-macros (buffer-file-name)))
		 (wanted-macros (if (null macro-name) all-macros
						  (-filter (lambda (mac) (equal macro-name (car mac)))
								   all-macros)))
		 (all-terms (-uniq (mapcar (lambda (mac) (car (cadr mac))) wanted-macros))))

	(with-help-window "macros"
	  (erase-buffer)
	  (mapc (lambda (term) (insert (format "- %s\n" term)))
			all-terms))))

(defun assoc-with-file-wildcards (key alist)
  "Works like `assoc' but ONLY on alists where keys are filenames,
 and allows the keys to contain wildcards."
  (catch 'result
    (let ((res (assoc key alist)))
      (when res (throw 'result res))
      (dolist (association alist)
        (when (member (expand-file-name key) (file-expand-wildcards (car association) t))
          (print-debug "Found %s in wildcarded assoc %s" key (quote association))
          (throw 'result association))))
    nil))

(defun change-input-method-to-czech ()
  "Changes the input method to \"czech-qwerty\"."
  (interactive)
  (set-input-method "czech-qwerty")
  (message "Changed input method to \"czech-qwerty\"."))

(defun my--org-table-add-overlay (table-name face coordinates &optional clean)
  "Add overlay FACE to the cells in COORDINATES in table TABLE-NAME (given
by the '#+name: ...' line above the
table). The table must be in the same file.

COORDINATES is a list of (ROW . COLUMN)... entries, each uniquelly
identifying an existing cell.

Optional argument CLEAN will wipe all previously applied overlays."
  (require 'org-table) 					; TODO Test if this is necessary

  ;; Wipe all currently applied overlayes. Keep them in
  ;; `my--table-cell-colour-overlays' and remove them whenever this function is
  ;; called. Then wipe the list. Then push to the list new overlays. It's
  ;; beautiful.
  (when clean
	(when (boundp 'my--table-cell-colour-overlays)
	  (mapc #'delete-overlay my--table-cell-colour-overlays))
	(setq-local my--table-cell-colour-overlays nil))

  (save-excursion
	(org-table-map-tables				; Iterate over all tables in the file
	 (lambda ()
	   (catch :wrong-table
		 (unless (equal table-name
						(plist-get (cadr (org-element-at-point)) :name))
		   (print-debug (format "Table is not the desired table %s" table-name))
		   (throw :wrong-table ""))

		 (org-table-analyze)
		 (dolist (coordinate coordinates)
			 (org-table-goto-field (format "@%d$%d" (car coordinate) (cadr coordinate)))

			 (let ((overlay (make-overlay (progn (print-debug "Adding overlay from here...")
												 (point))
										  (progn (re-search-forward "|")
												 (backward-char 2)
												 (print-debug "... to here")
												 (point)))))
			   (push overlay my--table-cell-colour-overlays)
			   (overlay-put overlay 'face face))))))))

(defun find-macro (macro-name file)
  "Returns a list of items in an org macro matching MACRO-NAME regex in
FILE. When called interactively, FILE is the current file."
  (interactive (list (read-string "Macro regex: ") (buffer-file-name)))
  
  (let* ((new-buffer (find-file-noselect file))
		 (macro-name (format "{{{%s(" macro-name))
		 found-terms)

	(with-current-buffer new-buffer
	  (save-excursion
		(beginning-of-buffer)

		(while (re-search-forward macro-name nil t)
		  (push (replace-regexp-in-string
				 "\n[[:blank:]]*"
				 " "
				 (buffer-substring-no-properties
				  (point)
				  (1- (re-search-forward ")"
										 (save-excursion
										   (forward-sentence-double-space)
										   (point))))))
				found-terms))))

	found-terms))

(defun get-all-macros (file)
  "Returns an alist of the form

  (MACRO-NAME ARGS...)

Where every element is a string. Considers only macros defined in
`macro-details'."
  (let (result macro-name macro-args macro-content)
	(dolist (macro-detail macro-details result)
	  (print-debug "Handling macro spec %s" macro-detail)
	  (setq macro-name (car macro-detail)
			macro-args (cdr macro-detail))

	  (print-debug "Searching for macro name %s with args %s" macro-name (quote macro-args))
	  (dolist (macro-entry (find-macro macro-name file))
		(setq macro-content (split-string macro-entry ", "))

		(unless (= (length macro-content)
				   (/ (length macro-args) 2))
		  (error "Macro %s with content %s doesn't match expected arguments %s"
				 macro-name macro-content macro-args))

		(push (list macro-name macro-content) result)))))

(defun insert-macro (macro-name macro-content)
  "Inserts MACRO-CONTENT as a macro MACRO-NAME. Makes sure that the macro
corresponds to expected syntax - see `macro-details'."
  (interactive (list nil nil)) 			; If reading interactively, there's some logic we need.

  (let* ((current-selection				; Currently highlighted text - will be the default of the last argument.
		  (when (region-active-p) (buffer-substring-no-properties (region-beginning)
																  (region-end))))
		 (file (buffer-file-name))		; File where the macro is to be added
		 (all-macro-contents (get-all-macros file)) ; All macros in `file' loaded into memory
		 macro-content			        ; A list of the arguments you've given
		 macro-name 					; Name of the macro you're inserting
		 expected-content				; The argument specs from `macro-details'
		 hints							; List of hints for arguments of `macro-name'
		 arg-spec						; The spec corresponding to `actual-arg' when iterating
		 all-unique)					; List of all arguments marked as `:unique' in their specs.

	(setq macro-name (if macro-name macro-name
					   (completing-read "Macro name: " (mapcar 'car macro-details) nil t))
		  expected-content (cdr (assoc macro-name macro-details))
		  hints (seq-filter 'stringp expected-content)
		  arg-spec (seq-filter (lambda (spec) (not (stringp spec))) expected-content))

	(print-debug "Building a list of all unique keys in the file")

	;; This paragraph loads the `all-unique' list. It iterates over all
	;; `macro-details'. For each detail (or "spec") we iterate over the argument
	;; specifications. For each argument, we find the matching actual argument
	;; in the text of the file. In particular, we're looking for the arguments
	;; marked as `:unique' in the spec, and we push them into `all-unique'.
	(dolist (details macro-details)
	  (let ((name (car details))
			(spec (seq-filter (lambda (s) (not (stringp s))) (cdr details))))

		(print-debug "Looking for unique keys of macro %s with argument specs %s"
					 name `(quote ,spec))
		
		(dolist (arg-index (number-sequence 0 (1- (length spec))))
		  (mapc (lambda (macro-entry) (let ((arg-spec (nth arg-index spec))
											(arg (nth arg-index (cadr macro-entry))))
										(print-debug "Maybe adding unique key %s (%s)" arg arg-spec)
										(when (equal :unique arg-spec) (push arg all-unique))))
				(seq-filter (lambda (macro-entry) (equal (car macro-entry) name))
							all-macro-contents)))))

	(print-debug "Found these unique keys: %s" `',all-unique)

	;; Read arguments one by one and validate them
	(dolist (arg-index (number-sequence 0 (1- (length hints))))
	  (let ((hint (nth arg-index hints))
			(spec (nth arg-index arg-spec))
			actual-arg)				; Used to iterate over `split-macro-content'

		(setq actual-arg
			  (if (equal :match spec)
				  (completing-read (format "Argument %s (%s): " (1+ arg-index) hint)
								   all-unique
								   nil t nil nil
								   (when (= arg-index (1- (length hints)))
									 current-selection))
				(read-string (format "Argument %s (%s): " (1+ arg-index) hint)
							 nil nil
							 (when (= arg-index (1- (length hints)))
							   current-selection))))

		;; Validate the unique requirement
		(when (and (equal :unique spec) (member actual-arg all-unique))
		  (error "Cannot redefine a unique argument '%s'" actual-arg))

		(setq macro-content (cons actual-arg macro-content))))

	(when (region-active-p)
	  (print-debug "Deleting region")
	  (delete-region (region-beginning) (region-end)))

	(insert (format "{{{%s(%s)}}}"
					macro-name
					(mapconcat 'identity (reverse macro-content) ",")))

	(when (bound-and-true-p auto-fill-function)
	  (org-fill-paragraph))))

(defun make-todo-items-postponed-and-move-them ()
  (interactive)
  (save-excursion
    (let ((original-value "Probrat")
          (new-value "ODLOŽENO")
          last-connection old-time new-time level ending-check line film)
      (setq last-connection (progn (while (not (= (org-current-level) 2))
                                     (outline-up-heading 1 t))
                                   (point)))
      (end-of-buffer)
      (while (> (point) last-connection)
        (outline-up-heading 1 t))
      (message (format "%d" (point)))
      (if (= (point) last-connection)
          (progn (end-of-buffer)
                 (insert insertion-string)
                 (org-align-all-tags))
        (goto-char last-connection)

        (setq
         ;; old-time is the day you talked, but didn't finish
         old-time (progn (search-forward " ")
                         (buffer-substring (1+ (point))
                                           (1- (progn (search-forward ">")
                                                      (point)))))
         ;; new-time is the day you postpone the topics to.
         new-time (progn (org-forward-heading-same-level 1 t)
                         (search-forward " ")
                         (buffer-substring-no-properties (1+ (point))
                                                         (1- (progn
                                                               (search-forward ">")
                                                               (point))))))
        (while (re-search-backward (format "^\\*+ %s" original-value) last-connection t)
          (setq level (org-current-level) ; will be used later to search for same-level heading
                ;; Only exchange stuff if ending-check is not "Příště" or "Conversation street"
                ending-check (progn (search-forward " " (pos-eol) nil 2)
                                    (buffer-substring (point) (pos-eol)))
                ;; Copy the whole subtree, so it can be later inserted in the appropriate place
                line (progn (org-mark-subtree)
                            (buffer-substring (region-beginning) (- (region-end) 1))))

          (search-forward original-value)
          (backward-kill-word 1)
          (if (string= ending-check "Příště")
              (insert "Hotovo")
            (insert new-value)
            (end-of-line)
            (newline)
            (insert (format "Moved to: [%s]" new-time))
            (if (= level 5)
                ;; DO give an error, if forward search fails. It should not!!
                (progn (re-search-forward (format "^\\*\\*\\*\\*\\* %s " original-value) (buffer-end 1))
                       (beginning-of-line)
                       (open-line 1)
                       (save-excursion ; After the insertion, if we do not return, we'll never get out of the loop.

                         ;; We must write the moved entry, then return,
                         ;;then write time, then return and only then
                         ;;start searching again.
                         (save-excursion
                           (insert line))
                         (end-of-line)
                         (newline)
                         (insert (format "Moved from: [%s]" new-time))))

              (save-excursion
                (re-search-forward "^\\*+ .+ Film týdne +:Filmy:" (buffer-end 1))
                                        ;(outline-show-entry)
                                        ;(newline)
                (org-forward-heading-same-level 1)
                (open-line 1)
                (save-excursion
                  (insert line))
                (end-of-line)
                (newline)
                (insert (format "Moved from: [%s]" old-time))))))
        (deactivate-mark)

        ;; insert previous film
        (goto-char last-connection)
        (org-forward-heading-same-level 1)
        (re-search-backward "^\\*+ .+ Film týdne +:Filmy:" (buffer-end -1))
        (outline-show-entry)
        (org-forward-heading-same-level 1)
        (previous-line)
        (beginning-of-line)
        (setq film (buffer-substring (point) (pos-eol)))
        (re-search-forward "^\\*+ .+ Film týdne +:Filmy:" (buffer-end 1))
        (outline-show-entry)
        (newline)
        (insert (format "%s" film))

        (goto-char last-connection)
        (while (search-forward "<" (pos-eol) t)
          (org-delete-backward-char 1)
          (insert "[")
          (search-forward ">")
          (org-delete-backward-char 1)
          (insert "]"))
        (deactivate-mark)

        ;; insert all the new NEXT_TIME deadlines
        (org-forward-heading-same-level 1)
        (while (re-search-forward "^\\*+ NEXT_TIME .+" (buffer-end 1) t)
          (newline)
          (insert (format "DEADLINE: <%s>" new-time)))))))

(defun mine/inc-font-size (inc-by)
  "Increment the `default' face's height by 10*INC-BY (1, AKA 10, by default)."
  (interactive "p")
  (set-face-attribute 'default nil
					  :height (+ (* 10 inc-by)
								 (face-attribute 'default :height))))

(defun mine/dec-font-size (dec-by)
  "Like `mine/inc-font-size' but making the font smaller"
  (interactive "p")
  (mine/inc-font-size (- dec-by)))

(defun work-or-home (a b)
  "Return A if `work-computer' is t, and B otherwise"
  (if work-computer a b))

(defun find-quick-files-src-block ()
	(find-file (expand-file-name "emacs/settings.org" PRIVATE-DIR))
	(beginning-of-buffer)
	(print-debug "In settings file")
	(search-forward "<<quick-actions>>")
	(search-forward "#+BEGIN_SRC emacs-lisp")
	(print-debug "Found src block. Editing...")
	(org-edit-special))

(defun quick-action-parse-arg (action-list &optional directory-prefix debug-arg)
	"Parses action-list for the use by `quick-action'. It unpacks all
flags, validates them, and constructs a similar list with no
flags where every action is a function or a list of more
actions.

DIRECTORY-PREFIX and DEBUG-ARG are used recursively only.
`quick-action' should never need then."
	(let (proper-action-list
		  ;; These will be reused on each iteration through the list
		  char-option
		  action-name
		  directory-flag
		  file-flag
		  var-flag
		  concat-flag
		  flag-counter ; Incremented whenever we find a flag.
		  action
		  dir-prefix   ; We can overwrite this for any action, so we keep an iteration-specific value

		  (debug-arg debug-arg))

	  (dolist (action-specification action-list)
		(catch 'no-file-or-dir
		  (setq char-option nil
				action-name nil
				directory-flag nil
				file-flag nil
				var-flag nil
				concat-flag nil
				flag-counter 1
				debug debug-arg
				dir-prefix directory-prefix
				action nil)

		  (unless (listp action-specification) (error "Action %s is not an action as defined by quick-acion" action-specification))

		  ;; Handle the character choice
		  (setq char-option (car action-specification))
		  (unless (characterp char-option) (error "First element of action %s has to be a character, like ?a" action-specification))

		  ;; Handle the option name
		  (setq action-name (cadr action-specification))
		  (unless (stringp action-name) (error "Second element of action %s has to be a string" action-specification))

		  (let ((debug-flag (or debug-flag debug)))

			;; Handle flags if they exist
			(dolist (flag (cdr (cdr action-specification)))
			  (print-debug "Handling flag, option, or action %s" flag)
			  (cond ((eq flag :file) (progn (cl-incf flag-counter)
											(setq file-flag t)))
					((eq flag :directory) (progn (cl-incf flag-counter 2)
												 (setq directory-flag (eval (nth flag-counter action-specification)))
												 (print-debug (format ":directory flag with %s directory and %d index" directory-flag flag-counter))
												 (unless (stringp directory-flag) (error "A :directory flag must be followed by a string in %s, is %s"
																						 action-specification directory-flag))))
					((eq flag :var) (progn (cl-incf flag-counter)
										   (setq var-flag t)))
					((eq flag :no-prefix) (progn (cl-incf flag-counter)
												 (print-debug "Ignoring :directory flags of parent actions (AKA %s)" dir-prefix)
												 (setq dir-prefix nil)))
					((eq flag :debug) (progn (cl-incf flag-counter 2)
											 (setq debug-flag (let ((var (nth flag-counter action-specification)))
																(or debug-flag (and (boundp var) (eval var)))))
											 (print-debug "Printing debug info for this action")))
					((eq flag :concat) (progn (cl-incf flag-counter)
											  (setq concat-flag t)))
					((and (symbolp flag)
						  (string-match-p ":.*" (symbol-name flag)))
					 (progn (print-debug "Invalid flag %s" flag)
							(cl-incf flag-counter)))))

			;; Define helper function
			(defun make-path-action (partial-path)
			  ;; Prepend directory if ':directory' flag was given or if 'directory-prefix' is set.
			  (when (or dir-prefix directory-flag) (setq partial-path (file-name-concat dir-prefix directory-flag partial-path)))

			  (setq partial-path (expand-file-name partial-path))

			  (cond ((file-directory-p partial-path) (setq partial-path (list 'find-file (list 'read-file-name "Find file: " partial-path))))
					((file-exists-p partial-path) (setq partial-path (list 'find-file partial-path)))
					;; TODO Should it really be so penalised to include a non-existent directory?
					(t (progn (print-debug "No such file or directory: %s. Skipping this action" partial-path) (throw 'no-file-or-dir 0)))))

			(if concat-flag
				(setq action (nthcdr (1+ flag-counter) action-specification))
			  (setq action (car (last action-specification))))
			(when (and (stringp action)
					   (null (and file-flag directory-flag)))
			  ;; ':file' is the default flag.
			  (setq file-flag t))
			(print-debug (format "char %c; name %s; file flag %s; dir flag %s; var flag %s; concat flag %s; debug %s; spec %s; action %s"
								 char-option action-name file-flag directory-flag var-flag concat-flag debug action-specification action))

			;; 
			;; Handle the action. It can be a string (AKA a path), a function which evaluates to a string (if ':file'
			;; flag is given) (which is treated as a path), or a nested alist which calls this function recursively.
			;; 
			(cond
			 ;; Invalid case. If it's not a string, it is a list of some sort, or a variable (and ':var' flag must be given).
			 ((not (or (listp action)
					   (stringp action)
					   (and var-flag (symbolp (quote action)) (boundp (quote action)))))
			  (progn
				(print-debug "list: %s, string: %s, var-flag: %s, symbol: %s, bound: %s" (listp action) (stringp action) var-flag (symbolp action) (boundp action))
				(error "Last argument of %s must be a string, a function, a variable if :var was given, or a nested list of actions" action-specification)))

			 ;; File or directory
			 ((stringp action) (progn
								 (print-debug "Action is a string")
								 ;; Check flag
								 (unless (or file-flag directory-flag)
								   (error "When action is a string, flag must be :file or :directory (or nothing) - %s" action-specification))
								 (setq action (make-path-action action))))

			 ;; Variable
			 (var-flag (progn (print-debug "Action is a variable and file flag is set %s" file-flag)
							  (if file-flag
								  (setq action (make-path-action (eval action)))
								(setq action (list 'funcall `(quote ,action))))))

			 ;; Nested lists of more options and actions
			 ((listp (car action)) (progn
									 (print-debug "Nested action")
									 (setq action (quick-action-parse-arg action
																		  (when (or dir-prefix directory-flag)
																			(print-debug "Adding prefix %s" (file-name-concat dir-prefix directory-flag))
																			(file-name-concat dir-prefix directory-flag))
																		  debug))))

			 ;; Concat
			 (concat-flag (progn (print-debug "Action is concat of %s" action)
								 (setq action (make-path-action (eval (cons 'concat action))))))

			 ;; Function. If it evaluates to a path and ':file' or ':directory' flags were given, use the path.
			 ;; Otherwise treat it as just a function.
			 (t (when (or file-flag directory-flag) (setq action (eval action)
														  action (make-path-action action)))))

			(setq new-el (list (list char-option action-name action)))
			(print-debug (format "Adding new element to the list: %s" new-el))
			(setq proper-action-list (append proper-action-list new-el)))))

		proper-action-list))

(defun quick-action-select-and-do (action-list)
	"Prompt the user to select an action from the action list. Use only when called by `quick-aciton'."
	(let* ((case-fold-search nil)
		   (options (mapcar #'car action-list))
		   (char (read-char-choice (mapconcat (lambda (item)
												(format "%c: %s" (car item) (cadr item)))
											  action-list "; ")
								   options))
		   (action (car (last (assoc char action-list)))))

	  (unless (listp action)
		(error "Quick open alist is malformed: %s" action))

	  (print-debug "Action is %s" action)
	  (if (listp (car action))
		  ;; Nested entry
		  (quick-action-select-and-do action)
		(eval action))))

(defun quick-action (action-list)
	"Query user for a character which corresponds to a given action
in the ACTION-LIST. Then perform the action.

ACTION-LIST is an alist whose elements ELs can have these forms:

	- (char \"name\" [:flag [flag-value]] action)
	- (char \"name\" [:flag [flag-value]] ELs)

CHAR must be a single unique character, such as '?a'. It maps
onto an action, or onto another list of ELs, each of which can
have the same formats.

NAME must always be a string. This is used when prompting the
user for input, and should unambiguously identify the actions.

ACTION can be a function, in which case it is evaluated.
Alternatively it can be a string, which is interpreted according
FLAGs. If we cannot resolve the action according to the passed
FLAGs, we panic. Lastly, ACTION can be a list of ELs, e.i., a
list of more action specifications of the same form. ACTION-LIST
can be infinitely nested, which allows for reusing the same CHARs
under different sub-action lists.

FLAGs give context to the action. Some of them are followed by a
value. FLAGs must be one of these predefined values:

	- ':file' - treat the action as a path. If it identifies an
	  existing file, visit it using `find-file'. No value needed.
	  If action is a function instead of a string, the function is
	  evaluated. The returned value must then be a string path. If
	  action is a variable, you must add a ':var' flag as well.

	- ':directory' DIR - like ':file', but use DIR (string) as the
	  prefix for all following actions. This applies even if the
	  action is another list of character-action pairs - every
	  child action which has the ':file' type uses the DIR prefix
	  unless it also specifies a ':no-prefix' flag. Like with
	  ':file', DIR can be a function which evaluates to a string.

	- ':var' - treat the action as a variable or function name. If
	  ':file' is also specified, execute action and treat the
	  result as a path. If neither ':file' nor ':directory' is
	  given, treat action as an interactive function to be
	  evaluated only if the user selects that option. Action CANNOT
	  be a nested ACTION-LIST.

	- ':concat' - like ':file', but action can be any number of
	  arguments (not a list, but arguments) which are concatinated
	  to form the file or directory path. Every element of action
	  is evaluated, so you can pass variables without adding a
	  ':var' flag. Action CANNOT be a nested ACTION-LIST.

	- ':no-prefix' - cancels any ':directory' prefixes defined in
	  higher levels of the action-list. This way you can have a
	  ':directory' value applied to every sub-action except those
	  which have a ':no-prefix' flag.

	- ':debug' VAR - Print debugging information for this action
	  only as long as VAR is a bound variable with a non-nil value.

The default FLAG is ':file'. More than one flag is allowed (and
sometimes required) per action.

This function validates that ACTION-LIST has the right form,
e.i., that all flags are valid, that all elements of ACTION-LIST
have a name, and that actions do not conflict with their
flags (you cannot use a :file flag for a function action, for
example)."
	;; Simple validation first
	(unless action-list (error "No action-list was given"))
	(unless (listp action-list) (error "Argument is not a list"))

	;; We'll construct a new action list which eliminates the flags and turns all actions into functions
	(let ((proper-action-list (quick-action-parse-arg action-list)))
	  (quick-action-select-and-do proper-action-list)))

(defun quickly-open-file (arg &optional alist)
	"Open file by quick selection. Asks for a character to be typed,
then runs the function mapped to that character from
`quick-open-file-alist'.

With prefix argument, runs the function in other window much like
`find-file-other-window' would.

Optional argument ALIST is `quick-open-file-alist' when left
empty, and an alist of the same format otherwise. This is done to
recursively offer more options."

	(interactive "P")
	(when arg
	  ;; Split window first, then focus on it, then run the rest
	  (switch-to-buffer-other-window (buffer-name)))

	(unless alist
	  (setq alist (if work-computer
					  quick-open-file-alist-work
					quick-open-file-alist-home)))

	(quick-action alist))

(setq dired-listing-switches "-lv"
	  use-package-always-ensure t
	  tool-bar-mode nil
	  display-line-numbers-type 'relative
	  server-port 7439
	  sentence-end-double-space nil
	  case-fold-search nil
	  sentence-end-base "[.?!…‽][]\"/'”’‘)}]*"
	  skeleton-pair t
	  org-agenda-include-diary t
	  org-startup-align-all-tables t
	  org-startup-shrink-all-tables t
	  org-startup-indented nil
	  org-footnote-auto-adjust t
	  make-backup-files t
	  backup-directory-alist '((".*" . "~/.emacs.d/save"))
	  inhibit-startup-screen t
	  ns-pop-up-frames nil
	  org-goto-interface 'outline
	  org-agenda-skip-deadline-if-done t
	  flycheck-check-syntax-automatically '(save mode-enabled)
	  org-startup-folded t
	  tab-always-indent 'complete
	  ac-delay 0
	  read-file-name-completion-ignore-case t
	  read-buffer-completion-ignore-case t
	  completion-ignore-case t
	  org-fontify-quote-and-verse-blocks t
	  mode-require-final-newline nil
	  enable-local-eval t
	  split-height-threshold 130 ; Set this ridiculously high so that we prefer the vertical split 
	  org-enforce-todo-dependencies t
	  org-enforce-todo-checkbox-dependencies t
	  org-agenda-dim-blocked-tasks nil
	  mouse-wheel-scroll-amount '(1 ((shift) . 1)) ; one line at a time
	  mouse-wheel-progressive-speed nil			   ; don't accelerate scrolling
	  mouse-wheel-follow-mouse 't				   ; scroll window under mouse
	  undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo-tree-backup"))
	  diary-file (concat PRIVATE-DIR "emacs/diary")
	  warning-minimum-level :emergency
	  scroll-conservatively 10000
	  org-agenda-skip-scheduled-if-done t
	  org-tags-column (work-or-home -90 -68)
	  scroll-preserve-screen-position t ;; Keep corsor position when scrolling
	  mode-require-final-newline nil
	  fountain-dwim-insert-next-character t
	  mouse-autoselect-window t
	  scroll-step 1
	  org-tags-column (work-or-home -90 -68)
	  calendar-week-start-day 1
	  scroll-conservatively 10000
	  mac-command-modifier 'meta
	  mac-right-option-modifier 'control
	  custom-theme-directory "~/pc-config/emacs/themes/"
	  highlight-indent-guides-responsive 'top
	  highlight-indent-guides-method 'character)

(setq quick-action-go-debugging
	  '((?u "insert useless"        :var go-insert-useless)
		(?\' "log"                  :var go-log-debug)
		(?~ "revertable comment"    :var go-comment-revertable)
		(?{ "test region"           :var go-testing-region)
		(?_ "copy line"             :var go-amend-line-while-debugging)
		(?l "no log filter"         :var go-no-log-filters-please)))

(setq quick-open-file-alist-common
	  '(
		;; Directories
		(?p "private" :directory PRIVATE-DIR
			((?p "Private" "")
			 (?b "bugs"  "bugs.org")
			 (?c "cache" "cache/")
			 (?C "config" "configs/")
			 (?d "documents" :directory "Documents/"
				 ((?h "home" "home/")
				  (?w "work" "work/")))
			 (?D "desktop" :directory "Desktops/"
				 ((?h "home" "home/")
				  (?w "work" "work/")))
			 (?e "emacs" "emacs/")
			 (?o "org-roam" "org-roam/")
			 (?P "code" :directory "code/"
				 ((?P "code" "")
				  (?p "python" "python/")
				  (?e "elisp" "elisp/")
				  (?g "go" "go/")
				  (?n "nu" "nushell/")
				  (?r "rust" "rust/")))
			 (?s "shell" :directory "shell/"
				 ((?s "shell"    "")
				  (?c "common"   "common/")
				  (?i "i3"       "i3/")
				  (?h "home"     "home/")
				  (?e "external" "external/")
				  (?w "work"     "work/")
				  (?a "actions"  "work/actions/")
				  (?C "cookies"  "work/cookies/")
				  (?g "git"      "work/git/")
				  (?l "logging"  "work/logging/")
				  (?u "utils"    "work/utils/")))))

		(?d "Directories"
			((?h "home"         "~/")
			 (?g "generic-server" :var :file generic-server-dir)
			 (?c "cease"          :var :file cease-language-dir)
			 (?D "downloads"               "~/Downloads/")))

		;; Other files
		(?F "Files"
			((?B "bashRC"                          "~/.bashrc")
			 (?i "i3 config"                       "~/.config/i3/config")
			 (?f "settings"             :concat    PRIVATE-DIR "/emacs/settings.org")
			 (?e "emacs"                :concat    PRIVATE-DIR "emacs/.emacs")
			 (?c "completion"           :concat    quick-open-shell "common/completion.bash")
			 (?q "quick open settings"  :var       find-quick-files-src-block)))))

(setq quick-open-file-alist-home
	  (append
	   '((?h "Harmonogram"   :concat documents-dir "Martinismus/Harmonogram.org")
		 (?f "settings"      :concat PRIVATE-DIR   "emacs/settings.org")

		 (?D "Documents" :directory "~/Private/Documents/home/"
			 ((?d "Documents"    "")
			  (?f "finance"      "Finance/")
			  (?m "martinism"    "Martinismus/")
			  (?w "writing"      "non-fiction writing/"))))

	   quick-open-file-alist-common))

(setq quick-open-file-alist-work
	  (append 
	   '(
		 ;; Work directories
		 (?w "Work directories" :directory "~/go/src/repo.jazznetworks.com/vaion/vaion/"
			 ((?v "vaion file"  :var :file    "")
			  (?V "vaion dir"                 (dired quick-open-vaion))
			  (?g "go"          :var :file    "go/")
			  (?d "dataservice"               "go/vms/mgmt/common/dataservice/")
			  (?a "apps"                      "go/apps/")
			  (?G "codegen"                   "go/codegen/")
			  (?s "scripts"                   "scripts/")
			  (?m "mgmt"                      "go/vms/mgmt/common/mgmt/")
			  (?p "proto"                     "protobuf/")
			  (?n "Northland"   :no-prefix    "~/go/src/gitlab.com_ava-security_northland-private_ava/")
			  (?l "lib"                       "go/lib/")))

		 ;; Cloud
		 (?c "Cloud"
			 ((?c "cloud"    :concat quick-open-vaion-go "cloud/")
			  (?C "cloudapi" :concat quick-open-vaion-go "cloud/services/cloudapi/")))

		 ;; API
		 (?A "API" :directory "~/go/src/repo.jazznetworks.com/vaion/vaion/go/"
			 ((?v "vms"
				  ((?A  "definitions"      "api/api_aware/api_aware.go")
				   (?a  "api dir"         "vms/mgmt/common/api/")
				   (?l  "local codegen"        "lib/api_mgmt_local/api_mgmt_local.apigen.go")
				   (?p  "primary codegen"  "lib/api_mgmt_primary/api_mgmt_primary.apigen.go")))

			  (?c "cloud"
				  ((?c "cloud definitions"  "api/api_cloud/api_cloud.go")
				   (?v "VMS definitions"	"api/api_cloud_connected_vms/api_cloud_connected_vms.go")
				   (?s "handlers"			"cloud/services/cloudapi/")
				   (?C "cloud codegen"      "lib/api_cloud/api_cloud.apigen.go")
				   (?V "vms codegen"		"lib/api_cloud_connected_vms/api_cloud_connected_vms.apigen.go")))

			  (?C "camera API"           "api/api_camera/api_camera.go")
			  (?a "api"                  "vms/mgmt/common/api/")))

		 ;; Access
		 (? "Access" :directory "~/go/src/repo.jazznetworks.com/vaion/vaion/go/"
			  ((?a "service"     "vms/mgmt/common/accesscontrolservice/")
			   (?c "client"      "lib/access_control/client/")
			   (?p "points api"  "vms/mgmt/common/api/access_control_points.go")
			   (?s "servers api" "vms/mgmt/common/api/access_control_servers.go")
			   (?A "server"      "vms/access/access_control_norm_server/server.go")
			   (? "model"      "vms/mgmt/common/model/access_control.go")))

		 ;; Work files
		 (?f "Work files"
			 ((?y "querygen yaml"        :concat quick-open-vaion "mgmt_querygen.yaml")
			  (?m "mgmt.go"              :concat quick-open-vaion-vms "mgmt/common/mgmt/mgmt.go")
			  (?c "cluster aggregator"   :concat quick-open-vaion-vms "mgmt/common/mgmt/cluster_aggregator.go")
			  (?w "WORKSPACE"            :concat quick-open-vaion "WORKSPACE")
			  (?u "upgrade orchestrator" :concat quick-open-vaion-vms "mgmt/common/upgrade_orchestrator/upgrade_orchestrator.go")
			  (?d "db"                   :concat quick-open-vaion-vms "mgmt/common/db/db.go")
			  (?r "run cluster"          :concat quick-open-vaion "scripts/run_cluster")
			  (?R "resiliency"           :concat quick-open-vaion-vms "mgmt/cloud_connector/db_resiliency_service/db_resiliency_service.go")
			  (?L "parse-logs"           :concat quick-open-vaion-go "apps/vms_log_parser/vms_log_parser.go")
			  (?a "about"                :concat quick-open-vaion-go "lib/about/about.go")
			  (?l "db listener"          :concat quick-open-vaion-vms "mgmt/common/db/mgmt_dblistener.go")))

		 (?D "Documents" :directory documents-dir
			 ((?d "Documents" "work/")
			  (?m "MASterMind" "work/Mastermind/")
			  (?r "rolling upgrades" "work/rolling upgrades/")
			  (?s "starter notes"    "work/new starters/starter notes.org")
			  (?S "new starters dir" "work/new starters/")
			  (?h "ha"               "work/ha/")
			  (? "documentation"    "work/Documentation/")))

		 ;; Quick access
		 (?v "vms" :directory "~/go/src/repo.jazznetworks.com/vaion/vaion/go/vms/"
			 ((?v "vms"          "")
			  (?c "cloud"        "mgmt/cloud/")
			  (?C "cc"           "mgmt/cloud_connector/")
			  (?o "common"       "mgmt/common/")
			  (?M "model"        "mgmt/common/model/")
			  (?m "mgmt"         "mgmt/")
			  (? "mgmt/mgmt"   "mgmt/common/mgmt/")
			  (?d "dataservice"  "mgmt/common/dataservice/")
			  (?D "mgmt/db"      "mgmt/common/db/")
			  (? "db"          "db/")
			  (?s "system rules" "mgmt/common/systemruleservice/")
			  (?S "mastermind"   "mgmt/cloud/mastermind_service/mastermind_service.go")
			  (?r "resiliency"   "mgmt/cloud_connector/db_resiliency_service/")
			  (?a "api"          "mgmt/common/api/")
			  (?A "AC service"   "mgmt/common/accesscontrolservice/")
			  (?b "backup"       "mgmt/cloud/cloudbackupservice/")))
		 )
	   quick-open-file-alist-common))

(setq treesit-language-source-alist
	  '((bash "https://github.com/tree-sitter/tree-sitter-bash")
		(cmake "https://github.com/uyha/tree-sitter-cmake")
		(css "https://github.com/tree-sitter/tree-sitter-css")
		(elisp "https://github.com/Wilfred/tree-sitter-elisp")
		(go "https://github.com/tree-sitter/tree-sitter-go")
		(tlaplus "https://github.com/tlaplus-community/tree-sitter-tlaplus")
		(html "https://github.com/tree-sitter/tree-sitter-html")
		(javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
		(json "https://github.com/tree-sitter/tree-sitter-json")
		(make "https://github.com/alemuller/tree-sitter-make")
		(markdown "https://github.com/ikatyang/tree-sitter-markdown")
		(c++ "https://github.com/tree-sitter/tree-sitter-cpp")
		(c "https://github.com/tree-sitter/tree-sitter-c")
		(python "https://github.com/tree-sitter/tree-sitter-python")
		(toml "https://github.com/tree-sitter/tree-sitter-toml")
		(tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
		(typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
		(yaml "https://github.com/ikatyang/tree-sitter-yaml")
		(cpp "https://github.com/ikatyang/tree-sitter-cpp")
		(nix "https://github.com/nix-community/tree-sitter-nix")
		(rust "https://github.com/tree-sitter/tree-sitter-rust")))

(setq org-move-headings-alist
	  (list
	   (list (file-name-concat PRIVATE-DIR "bugs.org") '(("TASK" . "TODOs")
														 ("BUG" . "TODOs")
														 ("TODO" . "TODOs")
														 ("TASK_DOING" . "DOINGs")
														 ("DOING" . "DOINGs")
														 ("BUG_DOING" . "DOINGs")
														 ("TASK_WAITING" . "WAITINGs")
														 ("WAITING" . "WAITINGs")
														 ("BUG_WAITING" . "WAITINGs")
														 ("REVIEW" . "WAITINGs")
														 ("CANCELLED" "DONEs" :stay)
														 ("DONE" "DONEs" :stay)))
	   (list (file-name-concat documents-dir "writing/**/*.org") '(("DONE" "DONEs" :stay)))
	   '("/tmp/*.org" (("TODO" . "TODOs")
					   ("DOING" . "DOINGs")
					   ("DONE" . "DONEs")))
	   '("~/server/todo.org" (("ONGOING" . "Ongoing tasks")
							  ("TASK" . "Ongoing tasks")
							  ("TODO" . "Bugs")
							  ("BUG" . "Bugs")
							  ("DONE" . "DONEs")))
	   (list (expand-file-name "~/Private/Documents/ha/state implementations.org")
			 '(("DONE" "DONEs" :stay)))))

(setq org-todo-keyword-faces
	  '(("TASK" . "#c4423b") ("TASK_DOING" . "yellow") ("TASK_WAITING" . "#b0be41") ("REVIEW" . "#6fc03f")
		("BUG" . "light blue") ("BUG_DOING" . "#22c8dd") ("BUG_WAITING" . "#2b72d4")
		("DOING" . "yellow")
		("PutOff" . "brown") ("Martin" . "purple") ("ODLOŽENO" . "dark green") ("Hotovo" . "orange")
		("CANCELLED" . (:foreground "red" :weight bold)) ("Probrat" . (:foreground "white" :weight bold))))

(setq-default company-tooltip-limit 20
			  company-show-numbers t
			  company-echo-delay 0
			  company-minimum-prefix-length 1
			  tab-width 4
			  company-idle-delay 0.5
			  require-final-newline nil
			  cursor-type 'box
			  org-adapt-indentation t)

(setopt treesit-font-lock-level 4)

(put 'narrow-to-page 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(put 'scroll-left 'disabled nil)
(put 'dired-find-alternate-file 'disabled nil)
(put 'set-goal-column 'disabled nil)

(add-to-list 'exec-path (expand-file-name "~/go/bin"))
(add-to-list 'exec-path (expand-file-name "~/go/bin/goflymake"))

(add-to-list 'custom-theme-load-path custom-theme-directory)

(package-initialize)

(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(add-to-list 'package-archives '("ox-odt" . "https://kjambunathan.github.io/elpa/") t)

;; MELPA uses a versioning scheme based on dates, which means that packages from
;; that archive are always preferred if `:ensure' is present in the
;; `use-package' block. This guarantees that you are using a version of that
;; package that has been specifically marked for release by its developer, and
;; not a development snapshot.
;;(setq use-package-always-pin "gnu")

(require 'use-package)

(use-package all
  :ensure t)

(use-package bash-completion
  :ensure t
  :defer t)

(use-package diff-hl
  :ensure t
  :defer t)

(use-package highlight-indent-guides
  :ensure t
  :defer t)

(use-package hl-todo
  :ensure t)

(use-package impatient-mode
  :ensure t
  :defer t)

(use-package minions
  :ensure t
  :defer t)

(use-package multiple-cursors
  :ensure t)

(use-package olivetti
  :ensure t
  :defer t)

(use-package rotate
  :ensure t)

(use-package selectrum-prescient
  :ensure t)

(use-package swiper
  :ensure t)

(use-package transpose-frame
  :ensure t
  :defer t)

(use-package auto-complete
  :custom (ac-delay 0.2)
  :ensure t)

(use-package company
  :ensure t)

(use-package compat
  :ensure t
  :defer t)

(use-package expand-region
  :ensure t)

(use-package flymake
  :ensure t
  :defer t)

(use-package go-eldoc
  :ensure t
  :defer t)

(use-package ivy
  :ensure t)

(use-package paredit
  :ensure t)

(use-package typescript-ts-mode
  :ensure t
  :defer t)

(use-package undo-tree
  :custom (undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo-tree-backup")))
  :ensure t)

(use-package yaml-ts-mode
  :ensure t
  :defer t)

(use-package xref
  :ensure t)

(defun mine/org-add-ids-to-headings-in-file (force)
  "Add a CUSTOM_ID property to all headings in the current file using their
titles. This will stop markdown export from using random IDs.

If an CUSTOM_ID property already exists and FORCE is nil, we'll keep the
existing value.

The IDs are markdown friendly."
  (interactive "P")
  (org-map-entries (lambda ()
					 (let* ((id (org-entry-get nil "CUSTOM_ID"))
						   (heading (org-get-heading t t t t))
						   (lower-heading (downcase heading)))
					   (unless (and (not force) id)
						 (org-entry-put nil
										"CUSTOM_ID"
										(string-replace " " "-" lower-heading)))))
				   nil 'file nil))

(defun org--hook ()
  (setq org-indent-indentation-per-level 1)
  (hide-lines-matching "# -\\*-.*")
  (org-indent-mode -1)
  (turn-on-evil-mode))

(defun mine/writing-org-roam-file ()
  (auto-fill-mode 1)
  (flyspell-mode 1)
  (setq-local ispell-personal-dictionary mine/org-roam-writing-dir))

(defun mine--org-roam-node-read-advice (orig-read &rest orig-args)
  "Advice around `org-roam-node-read' (which is called by
`org-roam-node-find' and `org-roam-node-insert') which adds a filter for
nodes by specified tags. The file- or directory-local variable
`mine--org-roam-node-tags' is used to get the tags.

The target node must have at least one of the tags in the variable. With
a C-u prefix, no tag filter is specified, and all nodes are searchable.
With two C-u C-u prefix, prompt user for the ONE tag that the target
node must have. The user is given a choice from tags defined by
`mine--org-roam-node-tags', but any string is accepted."
  (let* ((desired-tags (cond ((equal 16 (car current-prefix-arg))
                              (list (completing-read
                                     "Which node tag do you want to filter on? "
                                     mine--org-roam-node-tags)))
                             ((and (boundp 'mine--org-roam-node-tags)
                                   (null current-prefix-arg))
                              mine--org-roam-node-tags)
                             (t nil)))
         (new-filter (lambda (node)
                       (seq-some (lambda (tag) (or (null desired-tags)
                                                   (member tag desired-tags)))
                                 (org-roam-node-tags node))))
         (orig-args-valid-count (cl-count-if (lambda (arg) (not (null arg))) orig-args))
         (initial-input (car orig-args))
         (final-args (list initial-input new-filter)))

    ;; Don't override the original filter if one was supplied.
    (when (and orig-args (>  orig-args-valid-count 0))
      (setq final-args orig-args))

    ;; Call the original function with the correct (maybe new) filter.
    (apply orig-read final-args)))

(defun fill-paragraph-before-org-meta-return (&rest args)
  "Meant as advice for `org-meta-return'."
  (interactive)
  (when auto-fill-function
    (if (string= major-mode "org-mode")
        (org-fill-paragraph)
      (fill-paragraph))))

(defun org--align-table-hook (&rest IGNORE)
  "Hook to be run after moving around an org table or aligning it in the way which ignores the width token."
  (when (org-table-p)
    (org-table-toggle-column-width '(4))))

(defun mine--org-insert-todo-heading-respect-content (&optional _)
  "Replacing `org-insert-todo-heading-respect-content' because that has a bug in it I think."
  (let ((org-insert-heading-respect-content t))
	(org-insert-todo-heading nil t)))

(defun org-tree-to-indirect-buffer-hide ()
  "When `org-tree-to-indirect-buffer' is called, this hides that buffers name, as it is way too long."
  (interactive)
  (org-tree-to-indirect-buffer)
  (other-window 1)
  (setq mode-line-format (remove 'mode-line-buffer-identification mode-line-format)))

(defun mine--org-move-heading-to-heading (target-heading-string target-level &optional region-start region-end no-move)
  "Moves the heading at point to the heading specified by
TARGET-HEADING-STRING using `org-refile'. Unless NO-MOVE is non-nil,
move to the new location. The target heading must be in the same file.
Panics if no such heading exists.

TARGET-LEVEL is the org heading level of the target heading.

REGION-START and REGION-END denote a region to search for
TARGET-HEADING-STRING. If they are not set, they take the values of
`buffer-end's."

  (unless region-start (setq region-start (buffer-end -1)))
  (unless region-end (setq region-end (buffer-end 1)))

  (let* ((target-pos (save-excursion
					   (goto-char region-start)
					   (re-search-forward (format "^\\*\\{%s\\} \\(\\[.*\\] \\)?%s$"
												  target-level target-heading-string)
										  region-end)
					   (print-debug "This is the target heading's location")
					   (point)))
		 (current-heading (substring-no-properties (cdar (org-entry-properties (point) "ITEM"))))
		 (column-num (progn (print-debug (format "current column is %s" (current-column)))
							(current-column))))

	(org-refile nil (current-buffer) (list target-heading-string buffer-file-name nil target-pos))
	(print-debug "Heading moved. Prefix arg: %s" current-prefix-arg)
	(if no-move
		(print-debug "Been told not to move. Staying in place.")
	  (print-debug "Now going to the new location")
	  (beginning-of-buffer)
	  (search-forward current-heading)
	  (print-debug (format "Moving to recorded column %s" column-num))
	  (move-to-column column-num))))

(defun outline-list-siblings (&optional parent)
  "List all headings of the current level including this heading.
With optional argument PARENT, move that many levels up."
  (unless parent (setq parent 0))
  (save-excursion
	(unless (= (org-outline-level) 1)
	  (outline-up-heading parent)
	  (print-debug "Moved up %d headings" parent))

	(let* ((level (org-outline-level))
		   (scope (if (= level 1) 'file
					(outline-up-heading 1)
					'tree)))

	  (print-debug "Searching in scope %s" (quote scope))
	  (org-map-entries '(replace-regexp-in-string
						 "\\[.*\\] " ""
						 (substring-no-properties (cdar (org-entry-properties (point) "ITEM"))))
					   (format "LEVEL=%s" level)
					   scope 'comment))))

(defun org-get-subtree-bounds (&optional parents)
  "Return a list with two elements: the start point and end point of the current org subtree.

If the current org heading is a level 1 heading, return `point-min' and `point-max'

Optional PARENTS moves up that many levels first."
  (save-excursion
	(when parents (outline-up-heading parents))
	(if (= (org-outline-level) 1) (progn (print-debug "Subtree is the whole buffer") (list (point-min) (point-max)))
	  (outline-up-heading 1 t)
	  (let (end)
		(org-mark-subtree)
		(print-debug "This is the subtree")
		(setq end (region-end))
		(deactivate-mark)
		(list (pos-eol) end)))))

(defun org-todo--advice-heading-movement (&optional arg)
  "Advice after `org-todo' which moves the current heading to the
appropriate target heading using `mine--org-move-heading-to-heading'.

The 'appropriate' heading is found by examining the current todo
state. Headings are moved only among the siblings of the
heading, or silbings of the immediate parent. That is to say a
heading is NOT going to be moved if either of these is true:

	- Any of the parents of the heading are an unfinished todo item.

	- None of the heading's siblings and the immediate parent's
	  siblings are equal to the required string as dictated by
	  `mine--org-move-heading-to-heading'.

This allows us to have e.g. multiple \"Done\" headings in the
same file.

With prefix argument ARG being non-nil, point will not move to
the new place after the heading is moved there."

  (interactive "P")
  (catch 'a
	;; Stop if we're in the wrong file
	(unless (assoc-with-file-wildcards buffer-file-name org-move-headings-alist)
	  (print-debug "Wrong file")
	  (throw 'a 0))

	;; Only move this heading if it is a todo heading of any level.
	(unless (or (org-entry-is-todo-p) (org-entry-is-done-p))
	  (print-debug "Heading isn't a TODO heading")
	  (throw 'a 0))

	(let (region-bounds ; Region in which the target heading must live
		  todo-state file-headings target-heading
		  target-level
		  ;; 1 if target heading is a sibling of the immediate parent, nil if
		  ;; it's a sibling of the current heading, or no subling at all.
		  parent-siblings
		  (my-siblings (outline-list-siblings 0))
		  (parents-siblings (outline-list-siblings 1)))

	  ;; Find the target heading's name
	  (setq todo-state (save-excursion (outline-back-to-heading)
									   (beginning-of-line)
									   (cdar (org-entry-properties (point) "TODO")))
			file-headings (cadr (assoc-with-file-wildcards buffer-file-name org-move-headings-alist))
			target-heading (cdr (assoc todo-state file-headings)))

	  (when (listp target-heading)
		(setq arg (or arg (eq (cadr target-heading) :stay)))
		(print-debug "TODO state is tagged with flag %s." (cadr target-heading))
		(setq target-heading (car target-heading)))

	  (print-debug "todo state: %s; file headings: %s; target heading is %s" todo-state (quote file-headings) target-heading)
	  (unless target-heading
		(print-debug "No target heading - skipping move")
		(throw 'a 0))

	  ;; Check that this heading should be moved. Move headings if they are at any
	  ;; todo level, but only if their parents are not todo entries. Such parents
	  ;; should be moved instead once all their children are resolved.
	  ;;
	  ;; We also do not move the heading if the immediate parent's siblings do not
	  ;; contain the expected target heading.

	  (save-excursion
		(unless (= (org-outline-level) 1)
		  (outline-up-heading 1)
		  (when (and (org-entry-is-todo-p) (not (member target-heading my-siblings)))
			(print-debug "parent is a TODO heading")
			(throw 'a 0))))
	  (when (string= (car (last (org-get-outline-path))) target-heading)
		(print-debug "Already at the target heading")
		(throw 'a 0))

	  ;; Is the heading in a suitable location?
	  (cond ((member target-heading my-siblings)      (progn (print-debug "target heading found among my siblings")
															 (setq parent-siblings nil
																   target-level (org-outline-level))))
			((member target-heading parents-siblings) (progn (print-debug "target heading found among parent's siblings")
															 (setq parent-siblings 1
																   target-level (1- (org-outline-level)))))
			(t (progn (print-debug "target heading not found in scope")
					  (throw 'a 0))))

	  (setq region-bounds (org-get-subtree-bounds parent-siblings))
	  (print-debug "Moving to target heading with target heading level, then moving cursor there %s" target-level (not arg))
	  (mine--org-move-heading-to-heading target-heading target-level (car region-bounds) (cadr region-bounds) arg))))

(use-package org-contrib
  :defer t
  :after org
  :ensure t)

(use-package orgalist
  :ensure t
  :after org
  :defer t)

(use-package org-transclusion
  :ensure t
  :after (org org-roam))

(use-package ox-gfm
  :ensure t
  :after org
  :defer t)

(use-package ox-typst
  :ensure t
  :after org
  :defer t)

(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory (file-truename "~/Private/org-roam"))
  (org-roam-db-location (file-truename (concat org-roam-directory "/org-roam.db")))
  (org-roam-completion-everywhere t)
  (org-roam-capture-templates '(("d" "default" plain "%?" :target
								 (file+head
								  "${slug}-%<%Y%m%d%H%M%S>.org"
								  "# -*- eval: (mine/writing-org-roam-file) -*-\n#+title: ${title}\n#+filetags: ")
								 :unnarrowed t)
								("w" "writing" plain "%?" :target
								 (file+head
								  "Writing/${slug}.org"
								  "# -*- eval: (mine/writing-org-roam-file) -*-\n#+title: ${title}\n#+filetags: writing")
								 :unnarrowed t)
								("C" "characters" plain "%?" :target
								 (file+head
								  "Writing/Recurring Characters/${slug}.org"
								  "# -*- eval: (mine/writing-org-roam-file) -*-\n#+title: ${title}\n#+filetags: writing \"recurring characters\"")
								 :unnarrowed t)
								("g" "good men" plain "%?" :target
								 (file+head
								  "Writing/Stories/Good Men/${slug}.org"
								  "# -*- eval: (mine/writing-org-roam-file) -*-\n#+title: ${title}\n#+filetags: story good-men writing")
								 :unnarrowed t)
								("W" "worldbuilding" plain "%?" :target
								 (file+head
								  "Writing/World/${slug}.org"
								  "# -*- eval: (mine/writing-org-roam-file) -*-\n#+title: ${title}\n#+filetags: writing worldbuilding")
								 :unnarrowed t)
								("t" "timeline" plain "%?" :target
								 (file+head
								  "Writing/Timeline/${slug}.org"
								  "# -*- eval: (mine/writing-org-roam-file) -*-\n#+title: ${title}\n#+filetags: writing timeline")
								 :unnarrowed t)
								("G" "card game" plain "%?" :target
								 (file+head
								  "Card Game/${slug}.org"
								  "# -*- eval: (mine/writing-org-roam-file) -*-\n#+title: ${title}\n#+filetags: card-game")
								 :unnarrowed t)))
  :bind (("C-c o b" . org-roam-buffer-toggle)
		 ("C-c o f" . org-roam-node-find)
		 ("C-c o i" . org-roam-node-insert)
		 ("C-c o a" . org-roam-alias-add)
		 ("C-c o s" . org-roam-db-sync)
		 ("C-c o I" . org-id-get-create)
		 ("C-c o A" . org-transclusion-add))
  :config
  (org-roam-setup)
  (org-roam-db-autosync-mode))

(use-package org
  :hook (org-mode . org--hook)
  
  :custom
  (org-agenda-include-diary t)
  (org-agenda-start-on-weekday 1)
  (org-agenda-skip-deadline-if-done t)
  (org-agenda-dim-blocked-tasks nil)
  (org-agenda-skip-scheduled-if-done t)
  (org-adapt-indentation t)
  (org-agenda-start-on-weekday 1)
  (org-tags-column -90)
  (org-indent-indentation-per-level 1)
  (org-enforce-todo-dependencies t)
  (org-enforce-todo-checkbox-dependencies t)
  (org-transclusion-exclude-elements '(keyword property-drawer comment))
  (org-goto-interface 'outline)
  (org-startup-align-all-tables t)
  (org-startup-shrink-all-tables t)
  (org-startup-indented nil)
  (org-startup-folded t)
  (org-footnote-auto-adjust t)
  (org-fontify-quote-and-verse-blocks t)
  (org-tags-column (work-or-home -90 -68))
  (org-transclusion-exclude-elements '(keyword property-drawer comment))
  
  (org-move-headings-alist (list
							(list
							 (file-name-concat PRIVATE-DIR "bugs.org")
							 '(("TASK" . "TODOs")
							   ("BUG" . "TODOs")
							   ("TODO" . "TODOs")
							   ("TASK_DOING" . "DOINGs")
							   ("DOING" . "DOINGs")
							   ("BUG_DOING" . "DOINGs")
							   ("TASK_WAITING" . "WAITINGs")
							   ("WAITING" . "WAITINGs")
							   ("BUG_WAITING" . "WAITINGs")
							   ("REVIEW" . "WAITINGs")
							   ("CANCELLED" "DONEs" :stay)
							   ("DONE" "DONEs" :stay)))
							(list
							 (file-name-concat documents-dir "writing/**/*.org")
							 '(("DONE" "DONEs" :stay)))
							'("/tmp/*.org"
							  (("TODO" . "TODOs")
							   ("DOING" . "DOINGs")
							   ("DONE" . "DONEs")))
							'("~/server/todo.org"
							  (("ONGOING" . "Ongoing tasks")
							   ("TASK" . "Ongoing tasks")
							   ("TODO" . "Bugs")
							   ("BUG" . "Bugs")
							   ("DONE" . "DONEs")))
							(list
							 (expand-file-name "~/Private/Documents/ha/state implementations.org")
							 '(("DONE" "DONEs" :stay)))))

  :config
  (add-to-list 'org-agenda-files
			   (file-name-concat documents-dir "Martinismmus/Harmonogram.org")
			   t)
  (add-to-list 'org-agenda-files
			   (file-name-concat PRIVATE-DIR "bugs.org")
			   t)
  (add-to-list 'org-agenda-files
			   "~/Desktop/on-call notes.org"
			   t)
  (add-to-list 'org-agenda-custom-commands
			   '("N" "Like 'n' but sensible" ((agenda "+LEVEL<=2") (tags-todo "+LEVEL<=2"))))

  (advice-add 'org-todo :after (lambda () (org-todo--advice-heading-movement current-prefix-arg)))
  (advice-add 'org-insert-todo-heading-respect-content :override #'mine--org-insert-todo-heading-respect-content)
  (advice-add 'org-table-next-field :after #'org--align-table-hook)
  (advice-add 'org-table-previous-field :after #'org--align-table-hook)
  (advice-add 'org-table-next-row :after #'org--align-table-hook)
  (advice-add 'org-table-align :after #'org--align-table-hook)
  (advice-add 'org-footnote-create-definition :before #'org--align-table-hook)
  (advice-add 'org-meta-return :before #'fill-paragraph-before-org-meta-return)
  (advice-add 'org-insert-heading-respect-content :before #'fill-paragraph-before-org-meta-return)
  (advice-add 'org-roam-node-read :around 'mine--org-roam-node-read-advice)
  (advice-add 'org-edit-special :after #'turn-on-evil-mode)

  :bind  (:map org-mode-map
			   ("C-c C-x b" . org-tree-to-indirect-buffer-hide)
			   ("C-c p"		. org-previous-visible-heading)
			   ("C-c n"		. org-next-visible-heading)
			   ("C-c b"		. org-backward-heading-same-level)
			   ("C-c f"		. org-forward-heading-same-level)
			   ("C-c u"		. outline-up-heading)
			   ("C-c l"		. org-store-link)
			   ("C-c &"		. org-mark-ring-goto)
			   ("C-c m"     . #'insert-macro)
			   ("C-3"       . 'display-local-help)
			   ("C-c C-x b" . 'org-tree-to-indirect-buffer-hide)
			   ("C-c p"     . 'org-previous-visible-heading)
			   ("C-c n"     . 'org-next-visible-heading)
			   ("C-c b"     . 'org-backward-heading-same-level)
			   ("C-c f"     . 'org-forward-heading-same-level)
			   ("C-c u"     . 'outline-up-heading)
			   ("C-c 8"     . (lambda () (interactive) (org-table-recalculate 'iterate)))
			   ("C-c &"     . #'org-mark-ring-goto)
			   ("C-c 8"		. (lambda () (interactive) (org-table-recalculate 'iterate))))
  :ensure t)

;; Install all needed treesitter grammars
(defun mine/install-treesitter-grammar (language)
  "Installs the LANGUAGE's grammar if it isn't installed already. LANGUAGE
must be a symbol."
  (unless (treesit-language-available-p language)
	(message "Installing language %s" language)
	(treesit-install-language-grammar language)))

(mapc #'mine/install-treesitter-grammar
	  '(nix
		go
		c
		rust
		typescript))

(defun fountain-insert-two-newlines () (interactive) (insert "\n\n"))

(defun mine/fountain-mode-hooks ()
  (centred-cursor-mode 1)
  (flyspell-mode 1)
  (olivetti-80 90)
  (customize-set-variable 'fountain-hide-emphasis-markup t))

(defun mine/fountain-next-character-dialog ()
  "When on a dialog line, do newline (two, actually), select the next character, and go to their dialog immediately, without needing to confirm."
  (interactive)
  (fountain-dwim)
  (mine/fountain-return))

(defun mine/fountain-return ()
  "If on dialogue, insert two newlines and start action.
  If on action, insert two newlines and continue action.
  If on character name, insert one newline and continue dialogue.
  If on scene heading, insert one newline and continue action."
  (interactive)
  (let ((full-line (buffer-substring-no-properties (point-at-bol) (point-at-eol))))
	(cond ((and (eolp) (bolp)) (newline))
		  ((fountain-match-character t) (progn (end-of-line) (newline)))
		  ((fountain-match-paren) (newline))
		  ((fountain-match-synopsis) (newline))
		  ((fountain-match-metadata) (newline))
		  ((string-match-p fountain-lyrics-regexp full-line) (newline))
		  (t (newline 2)))))

(defun mine/fountain-insert-parent ()
  "When anywhere within a dialogue or character line, goes one line below
and inserts a parenthetical there."
  (interactive)
  (when (or (fountain-in-dialog-maybe)
			(fountain-match-character))
	(end-of-line)
	(newline)
	(insert-parentheses)
	(unless evil-insert-state-minor-mode
	  (evil-insert 0))))

(defun fountain-upcase-colon-line--advice-after (arg)
  (interactive "P")
  (when (string= ":"
                 (buffer-substring-no-properties
                  (- (point) 2)
                  (- (point) 1)))
    (newline)))

(defun cw-fountain-count (start end &optional arg full)
  "Count the number of words with respect to a given point when in fountain mode. This excludes: character headers, transitions, parantheticals, and scene headings - only dialogue and action.

With no prefix argument, counts the number of words from the
first item in `cw-origin' to the end of the buffer.

With one \\[universal-argument], do as above, but use the LAST
item in `cw-origin', that is the one, which was set first with
`cw-set-origin'.

With two \\[universal-argument], pick the index of the item in
`cw-origin' to use. In the future should be made more intuitive,
interactive and simple to use."
  (interactive (if (region-active-p)
                   (list (region-beginning) (region-end) (car current-prefix-arg))
                 (list (car cw-origin) (buffer-end 1) (car current-prefix-arg))))
  (when (and
         (if (null current-prefix-arg)
             t
           (not (= 64 arg)))
         (not (region-active-p))
         (null cw-origin)
         (not full))
    (error "Mark is not set in the current buffer. Set it with \"C-`\" or use \"count-words-region\" (M-=)."))
  (when (not (null current-prefix-arg))
    (cond ((= 4 arg) (setq start (car (last cw-origin))))
          ((= 16 arg) (setq start (nth (read-number
                                        (format "Pick number in range 0-%d " (1- (length cw-origin))))
                                       cw-origin)))
          ((<= 64 arg) (setq start (point)))))
  (let ((words 0))
    (save-excursion
      (goto-char start)
      (while (< (pos-eol) end)
        (when (or (fountain-match-dialog)
                  (fountain-match-action))
          (cl-incf words (count-words-region (point) (pos-eol))))
        (forward-line))
      (when (or (fountain-match-dialog)
                (fountain-match-action))
        (cl-incf words (count-words-region (point) end))))
    (cond ((region-active-p)
           (message (format "The region's words: %s" words)))
          ((<= 64 (if (null arg)
                      1
                    arg))
           (message (format "Words until end of buffer: %s" words)))
          (t (message (format "Words since mark: %s" words))))))

(use-package fountain-mode
  :custom
  (fountain-dwim-insert-next-character t)
  (fountain-align-character '(("screenplay" . 25) ("stageplay" . 35)))
  (fountain-align-dialog '(("screenplay" . 15) ("stageplay" . 10)))
  (fountain-align-paren 20)
  (fountain-align-trans '(("screenplay" . 55) ("stageplay" . 60)))
  (fountain-align-center '(("screenplay" . 20) ("stageplay" . 30)))
  (fountain-scene-numbers-display-in-margin t)

  :config
  (mapc (lambda (suffix) (add-to-list 'fountain-scene-heading-suffix-list suffix))
		'("MORNING" "DAWN" "EVENING" "NOON" "DUSK" "VARIOUS"))
  (advice-add #'fountain-upcase-line-and-newline :after 'fountain-upcase-colon-line--advice-after)
  
  :hook (fountain-mode . mine/fountain-mode-hooks)
  :ensure t
  :bind (:map fountain-mode-map
			  ("C-`"		. #'cw-fountain-count)
			  ("M-p"		. #'ace-window)
			  ("C-c u"		. #'fountain-outline-up)
			  ("C-c p"		. #'fountain-outline-previous)
			  ("C-c n"		. #'fountain-outline-next)
			  ("C-c b"		. #'outline-backward-same-level)
			  ("C-c f"		. #'outline-forward-same-level)
			  ("C-c C-b"	. #'outline-backward-same-level)
			  ("C-c C-f"	. #'outline-forward-same-level)
			  ("<C-return>" . #'mine/fountain-next-character-dialog)
			  ("RET"		. #'mine/fountain-return)
			  ("C-9"		. #'mine/fountain-insert-parent))

  :defer t)

(defun mermaid--make-declaration-regex (str indent-allowed no-word-end)
  "Construct a regular expression from STR which defines a keyword.

If INDENT-ALLOWED is non-nil, the keyword can have leading
spaces.

If NO-WORD-END is nil, the keyword must be a word-end, so it'll
end with the \\> symbol. This doesn't apply for special
characters like ':' or '-'."
  (let ((word-end (if no-word-end "" "\\\>")))
	 (if indent-allowed
		 (format "^\\s-*%s%s" str word-end)
	   (format "^%s%s" str word-end))))

(defun mermaid--concat-declarations (&rest declarations)
  "Creates a regular expression which matches against any keyword in
declarations.

Declarations must be:

	 - string which allows indentation appends the \\> symbol.
	 - alist

		 (\"keyword\" indent-allowed no-word-end)

	   which specifies if indentation is allowed, and whether the
	   regular expressions should end with the \\> word-end symbol.
	   It can be shortened to

		 (\"keyword\")

	   for no indentation and included word-end."

  (let (temp-result decs)
	 (setq decs (mapcar (lambda (expr)
						  (print-debug "Handling declaration %s" expr)
						  (setq temp-result (cond
											 ((stringp expr) (list expr t nil))
											 ((listp expr) expr)
											 (t (error "Infalid declaration format '%s'" expr))))

						  (print-debug "temp result: %s" temp-result)
						  (setq temp-result (mermaid--make-declaration-regex
											 (car temp-result)
											 (cadr temp-result)
											 (nth 2 temp-result)))

						  (print-debug "Adding %s to list of declarations" temp-result)
						  temp-result)
						declarations))

	 (print-debug "Declarations: %s" decs)
	 (string-join decs "\\|")))

(defun mermaid--align-diagram ()
  (interactive)
  (let ((beg (if (region-active-p) (region-beginning) (buffer-end -1)))
		 (end (if (region-active-p) (region-end) (buffer-end 1))))
	 (mapcar (lambda (str) (align-regexp beg end (format "\\(\\s-*\\)%s" str)))
			 '("-->" ":" "=>"))))

(defun mermaid-hook-funcs ()
  "List of mermaid mode hooks"
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width 2))

(require 'ox-extra)
;; This means that in an org file I can have this (the :ignore: tag is
;; important):
;;
;;   * Some top heading :ignore:
;;   ** Child
;;
;; When this file is exported, "Some top heading" will not appear in it, and
;; "Child" will be of level 1.
(ox-extras-activate '(latex-header-blocks ignore-headlines))

(with-eval-after-load 'ox-gfm
  (advice-add
	'mermaid--calculate-desired-indentation
	:override
	(lambda ()
	  (save-excursion
		(end-of-line)

		;; `mermaid--locate-declaration' returns a tuple:
		;;
		;;   (line-difference . indentation).
		;;
		;; It basically tells you:
		;;
		;;   - Are we currently on a given line, like "sequenceDiagram"?
		;;   - What is the indentation of the given line?
		;;
		;; From this we calculate what the indentation of the current line should
		;; be. The function searches backwards only, so if the string isn't found,
		;; you'll get (-1 . -1).

		(let* ((diagram-start (mermaid--concat-declarations
							   '("graph")
							   '("sequenceDiagram")
							   '("gantt")
							   '("flowchart")
							   '("errDiagram")
							   '("stateDiagram")
							   '("---" nil t)
							   '("config:" nil t)))
			   (block-start (mermaid--concat-declarations "subgraph" "loop" "alt" "opt" "critical" "option" "break" "par" '("state.*{" t t)))
			   (block-middle (mermaid--concat-declarations "else" "and"))
			   (block-end (mermaid--concat-declarations "end" '("}" t t)))

			   ;; Indentation of the graph declaration
			   (graph (mermaid--locate-declaration diagram-start))
			   ;; Indentation of the last subgraph (block) declaration if it exists
			   (subgraph (mermaid--locate-declaration block-start))
			   ;; Indentation of the graph or last subgraph, whichever is the most recent
			   (both (mermaid--locate-declaration (string-join (list diagram-start block-start) "\\|")))
			   ;; Indentation of a block separator if it exists
			   (else (mermaid--locate-declaration block-middle))
			   ;; Indentation of the last block end if it exist
			   (end (mermaid--locate-declaration block-end)))

		  (print-debug "graph: %s" graph)
		  (print-debug "subgraph: %s" subgraph)
		  (print-debug "both: %s" both)
		  (print-debug "else: %s" else)
		  (print-debug "end: %s" end)

		  (cond
		   ;; First handle when the cursor is on a keyword:

		   ;; Cursor is at the line which declares a
		   ;; graph. No indentation.
		   ((equal (car graph) 0) 0) 
		   ;; Cursor is at the "end" keyword. Indent to the subgraph's
		   ;; indentation.
		   ((equal (car end) 0) (cdr subgraph)) 
		   ;; Cursor is at the subgraph declaration. Add indentation to
		   ;; graph's indentation.
		   ((equal (car subgraph) 0) (+ mermaid--indent-width (cdr graph)))
		   ;; this is "else" or other block separator, indent to the
		   ;; current subgraph's indetation.
		   ((equal (car else) 0) (cdr subgraph))

		   ;; How handle when the cursor is on a normal line, either inside or
		   ;; outside a block:

		   ;; Inside or before a block, add indentaion to the block's or
		   ;; graph's indentation.
		   ((< (car end) 0) (+ mermaid--indent-width (cdr both))) 
		   ;; Special case for a block after another block ended. Add
		   ;; indentation to the block.
		   ((< (car both) (car end)) (+ mermaid--indent-width (cdr both))) 
		   ;; After some "end" line and not inside a block. Match the
		   ;; "end" indentation.
		   (t (cdr end))))))))

(use-package mermaid-ts-mode
  :ensure t
  :hook ((mermaid-ts-mode . turn-on-evil-mode)
		 (mermaid-ts-mode . mermaid-hook-funcs))
  :defer t)

(use-package nushell-ts-mode
  :ensure t
  :mode "\\.nu\\'"
  :defer t)

(defun lsp-show-docs-with-cursor (arg)
  "No prefix argument -> toggle show docs when cursor is over something

Prefix argument -> turn it off if negative, on if positive"
  (interactive "P")
  (let ((state (null lsp-ui-doc-show-with-cursor)))
	(setq lsp-ui-doc-show-with-cursor state)
	(if state
		(message "Docs on cursor hover enabled")
	  (message "Docs on cursor hover disabled"))))

(defun mine/lsp-hook ()
  (lsp-dired-mode 1))

(defun lsp--progress-status ()
  "Returns the status of the progress for the current workspaces.

This function was changed by YOU. Now it's nil because every time
there was an `lsp' call, it gave a huge amount or errors, which
were then displayed in the mode line. Very cluttered."
  nil)

(defun lsp-rid-me-of-my-misery (&optional company-p)
  "For all open buffers, disable `company-mode' and `lsp-ui-mode'.

  If optional COPMANY-P is non-nil, don't turn off company mode."
  (interactive "P")
  (mapcar (lambda (b) (set-buffer b) (unless company-p (company-mode -1)) (lsp-ui-mode -1) (lsp-ui-doc-mode 1)) (buffer-list)))

(defun lsp-workspace-restart--really ()
  (interactive)
  (when (y-or-n-p "Really restart? ")
    (call-interactively #'lsp-workspace-restart)))

(use-package lsp-ui
  :ensure t
  :after lsp-mode
  :defer t)

(use-package lsp-mode
  :ensure t
  :custom
  (lsp-rust-analyzer-display-chaining-hints t)
  (lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial")
  (lsp-rust-analyzer-display-parameter-hints t)
  (lsp-rust-analyzer-server-display-inlay-hints t)
  (lsp-rust-analyzer-proc-macro-enable t)
  (lsp-rust-analyzer-imports-granularity-group "crate")
  (lsp-rust-analyzer-files-watcher "client")  ;; or "server"
  (lsp-ui-doc-max-height 50)
  (lsp-file-watch-threshold 7000)

  :config
  (advice-add 'lsp-find-references :after 'hs--show-on-jump)
  (lsp-register-client (make-lsp-client
						:new-connection (lsp-stdio-connection "gopls")
						:activation-fn (lsp-activate-on "go")
						:server-id 'gopls))
  (lsp-register-client (make-lsp-client
						:new-connection (lsp-stdio-connection "rust-analyzer")
						:activation-fn (lsp-activate-on "rust")
						:server-id 'rust-analyzer))

  :bind (:map lsp-mode-map
			  ("C-c r"		. #'lsp-find-references)
			  ("C-c R"		. #'lsp-rename)
			  ("C-c i"		. #'lsp-goto-implementation)
			  ("C-c T"		. #'lsp-goto-type-definition)
			  ("C-c d"		. #'lsp-find-definition)
			  ("C-c M-r"	. #'lsp-rid-me-of-my-misery)
			  ("C-c C-r"	. #'lsp-workspace-restart--really)
			  ("C-5"		. #'lsp-show-docs-with-cursor))

  :hook (lsp-mode . mine/lsp-hook)
  :defer t)

(defun go-mode-hooks-func()
    (lsp-deferred)
    (yas-minor-mode 1)
    (vc-mode 1)
    (hs-minor-mode 1)
    (set-fill-column 80)
    (highlight-indent-guides-mode 1)
    (toggle-truncate-lines -1)
    (visual-line-mode 1)
    (unless (bound-and-true-p company-p) (company-mode -1))
    (lsp-ui-mode -1)
    (lsp-ui-doc-mode 1)
    ;; (font-lock-mode 1)
    (font-lock-fontify-buffer))

(defun go-no-log-filters-please ()
    "Adds a pointer at the end of all ___ logs which don't have it already. The variable will always be called 'useless'.

          EXAMPLE

          logger.Errorf(\"___ bla bla bla: %s\", err)

          --->

          logger.Errorf(\"___ bla bla bla: %s (%p)\", err, &useless)"
    (interactive)
    (for-all-occurrences "___"
                         (lambda()
                           (print-debug "Found occurance of ___")
                           (if (save-excursion
                                 (and (progn (end-of-line) (backward-word) (not (looking-at-p "useless")))
                                      (let ((line (buffer-substring-no-properties (pos-bol) (pos-eol))))
                                        (not (or (string-match-p "___$" line)
                                                 (string-match-p "___{{" line)
                                                 (string-match-p "___}}" line))))))
                               (progn
                                 (print-debug "on matching line")
                                 (evil-find-char 1 ?\")
                                 (print-debug "inserting %p here")
                                 (insert " (%p)")
                                 (end-of-line)
                                 (backward-char 1)
                                 (print-debug "Inserting &useless here")
                                 (insert ", &useless"))
                             (print-debug "not a matching line")
                             (end-of-line)))))

(defun go-insert-useless (&optional arg)
    "Inserts 'useless := false // ___' on next line. With prefix argument ARG also run `go-no-log-filters-please' afterwards."
    (interactive "P")
    (evil-open-below 1)
    (insert "useless := false // ___")
    (when arg
      (go-no-log-filters-please)))

(defun go-amend-line-while-debugging ()
    "Turns current line into a copy of itself, but marked for deletion using the \"// ___\" scheme.
The old line is commented out, appended with \"~~~\", and thus marked for re-use when debugging is finished."
    (interactive)

    (let ((point-at-line (- (point) (pos-bol))) ; Used to place the cursor where it started on the new line
          (current-line (buffer-substring-no-properties (progn (back-to-indentation)
                                                               (point))
                                                        (pos-eol))))

      (comment-line 1)
      (previous-line 1)

      (end-of-line)
      (insert " ~~~") ; This marks it as the original line
      (evil-open-below 1)
      (insert (concat current-line " // ___"))

      (beginning-of-line)
      (forward-char point-at-line)))

(defun go-log-debug (&optional arg)
    "Marks current logger line using `go-amend-line-while-debugging', and prepends \"___ \" to the log so it shows in filtering. With prefix argument it enters insert mode so you can edit the prited string."
    (interactive "P")

    ;; Check we're on a correct line
    (back-to-indentation)
    (unless (looking-at ".*\"")
      (error "Not on a logger line."))

    (go-amend-line-while-debugging) ; We are at the beginning of the line
    (evil-find-char 1 ?\")
    (forward-char 1)
    (insert "___ ")
    (when (not arg)
      (evil-normal-state)))

(defun go-comment-revertable ()
    "Comments out the line/region, and appends ~~~ to show this is to be reverted to the original, uncommented version"
    (interactive "P")

    (save-excursion
      (if (region-active-p)
          (let* ((start (region-beginning))
                 (end (region-end))
                 (first-line (progn (goto-char start)
                                    (line-number-at-pos)))
                 (last-line (progn (goto-char end)
                                   (line-number-at-pos))))

            (print-debug "lines commented")
            (deactivate-mark)
            (print-debug "mark deactivated")
            (goto-char start)
            (print-debug "at start: last line: %d, fist line: %d" last-line first-line)
            (dotimes (line (- last-line first-line)) ; Do it 1-<number of lines in the region>
              (unless (= (pos-bol) (pos-eol)) ; Empty line
                ;; Cannot comment the block, because that only works if point is at the end of the region.
                (back-to-indentation)
                (insert "// ")
                (end-of-line)
                (insert " ~~~"))
              (forward-line)))

        ;; Not in region
        (end-of-line)
        (insert " ~~~")
        (comment-line 1))))

(defun go-testing-region ()
    "Turns the current region into one that will be removed by rem_."
    (interactive)
    (unless (region-active-p)
      (error "No active region"))

    (let ((start (region-beginning))
          (end (region-end)))

      (deactivate-mark)

      (evil-save-state
        (save-excursion
          ;; Must start from the end
          (goto-char end)
          (if (= (point) (pos-bol))
              (evil-open-above 1)
            (evil-open-below 1))
          (insert "// ___}}")

          (goto-char start)
          (evil-open-above 1)
          (insert "// ___{{")))))

(defun quick-action-go-debug ()
    "Do a ___ based Go action using `quick-action'."
    (interactive)
    (quick-action quick-action-go-debugging))

(defun go--remove-unwatched-files ()
    (when (string= major-mode "go")
      (mapcar (lambda (pattern) (add-to-list 'lsp-file-watch-ignored-directories pattern))
              '("/bazel-bin"
                "/bazel-code"
                "/bazel-genfiles"
                "/bazel-out"
                "/bazel-testlogs"
                "/go/lib/embedding"
                "/ui"
                "/audio_matlab"
                "/codestyle"
                "/\\<ci\\>"
                "/docker"
                "/new_starter_scripts"
                "/scripts"
                "/vaion_c\\'"
                "/vendor"
                "/third_party"
                "/samples"
                "[/\\\\]embedding\\'"
                "/lib/metadata"
                "/\\.licenses"))))

(use-package go-ts-mode
  :ensure t
  :config
  (add-hook 'before-save-hook #'gofmt-before-save)
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t)

  :custom
  (go-ts-mode-indent-offset 4)
  (gofmt-command "goimports -w")

  :config
  (go-eldoc-setup)
  (add-to-list 'lsp-file-watch-ignored-files ".*bazel-.*")
  (add-to-list 'load-path "~/.emacs.d/bazel/")
  (mapcar (lambda (letter) (define-key go-ts-mode-map letter 'skeleton-pair-insert-maybe))
          (mapcar #'car skeleton-custom-alist))
  (mapcar (lambda (letter) (define-key go-ts-mode-map letter 'skeleton-insert-end))
          (mapcar #'cdr skeleton-custom-alist))
  (with-eval-after-load 'lsp-mode #'go--remove-unwatched-files)

  :bind (:map go-mode-map
              ("C-c t"      . #'lsp-find-type-definition-other-window)
              ("C-3"        . #'lsp-ui-doc-glance)
              ("C-c _"      . #'quick-action-go-debug)
              ("C-c C-f n"  . #'go-goto-function-name)
              ("C-c C-f d"  . #'go-goto-docstring)
              ("C-c C-f a"  . #'go-goto-arguments)
              ("C-c C-f r"  . #'go-goto-return-values)
              ("C-c C-f m"  . #'go-goto-method-receiver)
              ("C-c t"      . #'lsp-find-type-definition-other-window)
              ("RET"        . #'get-proper-newline)
              ("C-3"        . #'lsp-ui-doc-glance)
              ("C-c _"      . #'quick-action-go-debug)
              ("C-3"        . #'lsp-ui-doc-glance)
              ("C-3"        . #'lsp-ui-doc-glance)
              ("C-3"        . #'lsp-ui-doc-glance)
              ("C-3"        . #'lsp-ui-doc-glance))

  :defer t)

(defun hook/text-mode ()
  (turn-on-evil-mode)
  (visual-line-mode 1))

(add-hook 'text-mode-hook #'hook/text-mode)

(defun hook/markdown-ts-mode ()
  (olivetti-mode)
  (olivetti-set-width 150))

(use-package markdown-ts-mode
  :ensure t
  :hook (markdown-ts-mode . hook/markdown-ts-mode)
  :defer t)

(use-package magit
  :custom
  (magit-diff-refine-hunk 'all)
  :ensure t)

(use-package yasnippet
  :config
  (add-to-list 'yas-snippet-dirs "~/pc-config/emacs/snippets/" t)
  (yas-reload-all)
  :bind (:map yas-keymap
			  ("C-<tab>" . 'indent-for-tab-command))
  :ensure t)

(defun hs--show-on-jump (&rest arg)
  "After we jump to a line, show the block it's in."
  (when hs-minor-mode
    (hs-show-block)))

(defun hs--hide-on-method (func &optional end)
  (save-excursion
    (end-of-line)
    (funcall func end)))

(defun hs-hide-leaves ()
  "Hide all blocks nested in the current one."
  (interactive)
  (save-excursion
    (hs-show-block)
    (hs-life-goes-on
     (end-of-line)
     (hs-find-block-beginning)
     (print-debug "1")
     (let ((block-end (save-excursion (forward-sexp)
                                      (point)))
           (lines-num-to-jump 1))
       (while (< (pos-eol) block-end)
         (next-line lines-num-to-jump)
         (end-of-line)
         (print-debug "2")
         (unless (bolp)
           (backward-char 1)
           (print-debug "3")
           (if (car-safe (hs-inside-comment-p))
               ;; Hide comments
               (progn (hs-hide-block)
                      (print-debug "3.5")
                      (setq lines-num-to-jump 1))

             ;; Hide standard blocks
             (if (hs-looking-at-block-start-p)
                 (progn
                   (hs-hide-block)
                   (forward-sexp)
                   (print-debug "4")

                   ;; Hide more blocks on the same line (like if {...} else { ... )
                   (unless (eolp)
                     (forward-char)
                     (print-debug "4.5"))
                   (if (or (eolp)
                           (= 1 (- (pos-eol) (point))))
                       (setq lines-num-to-jump 1)
                     (setq lines-num-to-jump 0)))
               (print-debug "5")
               (setq lines-num-to-jump 1)))))))))

(use-package hide-lines
  )

(use-package hideshow
  :custom
  (hs-special-modes-alist (mapcar 'purecopy
								  '((c-mode "{" "}" "/[*/]" nil nil)
									(go-mode "[{\\|\(]" "}\\|\)" "/[*/]" nil nil)
									(c++-mode "{" "}" "/[*/]" nil nil)
									(bibtex-mode ("@\\S(*\\(\\s(\\)" 1))
									(java-mode "{" "}" "/[*/]" nil nil)
									(js-mode "{" "}" "/[*/]" nil))))

  :config
  (advice-add 'hs-hide-block :around 'hs--hide-on-method)
  (advice-add 'hs-show-block :around 'hs--hide-on-method)

  :bind (:map hs-minor-mode-map 
			  ("C-9" . 'hs-show-block)
			  ("C-7" . 'hs-hide-block)
			  ("C-8" . 'hs-hide-leaves)
			  ("C-*" . 'hs-hide-all)
			  ("C-(" . 'hs-show-all))
  :ensure t)

(define-minor-mode specific-string-insertion
  "if the local variable \"insertion-string\" has been defined, inserts that variable with the \"c-x r ret\" binding."
  :init-value nil
  :lighter " Ins"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-x r RET") 'insert-specific-string)
            (define-key map (kbd "C-c n") 'insert-specific-next-mark)
            map)

  (font-lock-add-keywords nil
                          '(("\\^\\^" . font-lock-warning-face)))

  (font-lock-mode 1)
  (if (fboundp 'font-lock-flush)
      (font-lock-flush)
    (when font-lock-mode
      (with-no-warnings (font-lock-fontify-buffer)))))

(defun cc-ret-and-recentre (&optional a b)
  "Inserts a newline and recentres the line. The arguments are there
because of the weird way advice-add works. This must be used by the
wc-mode, so there they are, even though they have no meaning."
  (interactive)
  (cond ((string= major-mode "fountain-mode")
         (fountain-return))
        ((string= major-mode "org-mode")
         (org-return))
        (t
         (newline 1 t)))
  (recenter))

(defun cc-double-ret-and-recentre ()
  "Insert two newlines and recentre the second one."
  (interactive)
  (unless (or (outline-on-heading-p) (string= major-mode "fountain-mode"))
    (newline))
  (cc-ret-and-recentre))

(define-minor-mode centred-cursor-double-mode
  "Same as `centred-cursor-mode', except newline inserts two newlines when called with RET."
  :init-value nil
  :lighter " B"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "RET") 'cc-double-ret-and-recentre)
            map))

(define-minor-mode centred-cursor-mode
  "When moving about, keep the line where it is, but when inserting newlines, recentre the current line."
  :init-value nil
  :lighter " CL")

(defadvice self-insert-command (after recentering activate)
  (when centred-cursor-mode (recenter)))

(defadvice newline (after recentering activate)
  (when centred-cursor-mode (recenter)))

;; DOESN'T WORK!!!
(defadvice backward-delete-char (before recentering activate)
  "Deletes two characters if at beginning of line and previous line is empty."
  (when (and centred-cursor-mode
             (= (point) (pos-bol))
             (save-excursion
               (backward-char)
               (= (point) (pos-bol))))
    (backward-char 1)
    (kill-line 1)))

(add-hook 'centred-cursor-double-mode-hook
		  (lambda () (centred-cursor-mode (null centred-cursor-double-mode))))

(defun rust--mode-hooks-func()
  (lsp-deferred)
  (yas-minor-mode 1)
  (vc-mode 1)
  (hs-minor-mode 1)
  (highlight-indent-guides-mode 1)
  (toggle-truncate-lines -1)
  (visual-line-mode 1)
  (unless (bound-and-true-p company-p) (company-mode -1))
  (lsp-ui-mode -1)
  (lsp-ui-doc-mode 1)
  (font-lock-fontify-buffer))

(use-package rust-ts-mode
  :ensure t
  :hook (rust-ts-mode . rust--mode-hooks-func)
  :config
  (add-hook before-save-hook #'lsp-format-buffer t t)
  (add-hook before-save-hook #'lsp-organize-imports t t)
  :bind (:map rust-ts-mode-map
			  ("C-3" . 'lsp-ui-doc-glance))
  :defer t)

(use-package evil-visual-mark-mode
  :ensure t
  :after evil)

(use-package evil
  :init
  (defvar evil-mode-buffers '()) ; Because of some bug that requires this var but doesn't init it.
  
  :custom
  (evil-visual-state-cursor 'hollow)
  (evil-insert-state-cursor "#ECBC42")
  (evil-emacs-state-cursor '(hbar "green"))
  (evil-normal-state-cursor '(box "#8cc4ff"))

  :config
  (advice-add 'evil-normal-state :before (lambda (&rest r) (setq evil-point-before (point))))
  (advice-add 'evil-normal-state :after (lambda (&rest r) (unless (= (point) evil-point-before) (forward-char))))
  (advice-add 'evil-goto-line :after 'hs--show-on-jump)
  (advice-add 'evil-delete-backward-char-and-join :before #'skeleton-delete--advice)
  (advice-add 'evil-delete-backward-char-and-join :before #'delete-space-lines)
  (advice-add 'evil-delete-backward-char-and-join :after  #'safe-indent)

  :bind (:map evil-motion-state-map
			  ("k" . 'previous-line)
			  ("l" . 'next-line)
			  ("j" . 'evil-backward-char)
			  ("'" . 'evil-forward-char)
			  ("h" . 'evil-goto-mark-line))
  :ensure t)

(evil-define-command evil-scroll-line-to-top (count)
  "Scrolls line number COUNT (or the cursor line) to the top of the window."
  :repeat nil
  :keep-visual t
  (interactive "<c>")
  (evil-save-column
	(let ((line (or count (line-number-at-pos (point)))))
	  (goto-char (point-min))
	  (forward-line (1- line)))
	(recenter (1- (max 3 scroll-margin)))))

(evil-define-command evil-scroll-line-to-bottom (count)
  "Scrolls line number COUNT (or the cursor line) to the bottom of the
window."
  :repeat nil
  :keep-visual t
  (interactive "<c>")
  (evil-save-column
	(let ((line (or count (line-number-at-pos (point)))))
	  (goto-char (point-min))
	  (forward-line (1- line)))
	(recenter (- (max 3 scroll-margin)))))

(evil-define-command evil-org-meta (&optional ARG)
  "Performs the meta action for org mode, but takes into account the weird
positioning of the evil cursor, and switches to insert mode."
  (interactive "<c>")
  (when (= (point) (- (pos-eol) 1))
	(evil-append 1))
  (org-meta-return ARG)
  (evil-append 1))

(evil-define-command evil-org-insert-todo-heading (ARG &optional FORCE-HEADING)
  "Performs the shift-mata action for org mode, but takes into account the
weird positioning of the evil cursor, and switches to insert mode."
  (interactive "<c>\n<c>")
  (when (= (point) (- (pos-eol) 1))
	(evil-append 1))
  (org-insert-todo-heading ARG FORCE-HEADING)
  (evil-append 1))

(evil-define-command evil-insert-heading-respect-content (&optional INVISIBLE-OK)
  "Performs the ctrl action for org mode, but switches to insert mode."
  (interactive "<c>")
  (org-insert-heading-respect-content INVISIBLE-OK)
  (evil-append 1))

(evil-define-command evil-insert-todo-heading-respect-content (&optional FORCE-STATE)
  "Performs the shift-ctrl action for org move, and switches to insert
mode."
  (interactive "<c>")
  (org-insert-todo-heading-respect-content FORCE-STATE)
  (evil-append 1))

(evil-define-command evil-append-to-eof ()
  "Go to end of file and enter insert mode."
  (interactive)
  (end-of-buffer)
  (evil-append 1))

(evil-define-key 'motion 'global
  "\C-v" 'scroll-up-command
  "\C-f" 'forward-char
  "\C-b" 'backward-char
  "\C-y" 'yank
  "\C-w" 'kill-region
  (kbd "M-d") 'evil-scroll-up
  (kbd "C-<down>") 'evil-scroll-line-down
  (kbd "C-<up>") 'evil-scroll-line-up)

(evil-define-key 'insert 'global
  "\M-O" 'evil-execute-in-normal-state
  "\C-v" 'scroll-up-command
  "\C-o" 'open-line
  "\C-d" 'delete-char
  "\C-r" 'swiper-backward
  "\C-y" 'yank
  "\C-w" 'kill-region
  "\C-k" 'kill-line
  "\C-a" 'beginning-of-line
  "\C-e" 'end-of-line
  "\C-n" 'next-line
  "\C-t" 'transpose-chars
  "\C-p" 'previous-line)

(evil-define-key 'normal 'global
  " " 'evil-visual-block
  "\C-t" 'transpose-chars
  (kbd "C-S-a") 'evil-append-to-eof
  "\C-r" 'swiper-backward
  "\C-^" 'switch-to-buffer
  "\C-o" 'open-line)

(evil-define-key 'motion org-mode-map
  "\C-e" 'org-end-of-line
  (kbd "<M-return>") 'evil-org-meta
  (kbd "<M-S-return>") 'evil-org-insert-todo-heading
  (kbd "<C-return>") 'evil-insert-heading-respect-content
  (kbd "<C-S-return>") 'evil-insert-todo-heading-respect-content
  (kbd "TAB") 'org-cycle
  (kbd "C-c SPC") 'org-table-blank-field
  "\C-a" 'org-beginning-of-line)

(evil-define-key 'insert org-mode-map
  "\C-a" 'org-beginning-of-line
  (kbd "C-c SPC") 'org-table-blank-field
  (kbd "DEL") 'org-delete-backward-char)

(evil-define-key 'insert org-mode-map "\C-e" 'org-end-of-line)
(evil-define-key 'motion help-mode-map "\t" 'forward-button)
(evil-define-key 'motion markdown-mode-map "\t" 'markdown-cycle)
;; So this is sometimes \t and sometimes <tab> and it isn't consistent
(evil-define-key 'motion fountain-mode-map "\t" 'fountain-dwim)

(defun mine/nix-hook ()
  (highlight-indent-guides-mode 1)
  (hs-minor-mode 1))

(use-package nix-ts-mode
  :ensure t
  :mode "\\.nix$"
  :hook (nix-ts-mode . mine/nix-hook)
  :defer t)

(defun flycheck-list-errors-and-select ()
	(interactive)
	(flycheck-list-errors)
	(pop-to-buffer "*Flycheck errors*"))

(defun flycheck-list-errors-and-select ()
	(interactive)
	(flycheck-list-errors)
	(pop-to-buffer "*Flycheck errors*"))

(defun flycheck-list-errors-and-select ()
  (interactive)
  (flycheck-list-errors)
  (pop-to-buffer "*Flycheck errors*"))


(use-package flycheck-mode
  :custom (flycheck-check-syntax-automatically '(save mode-enabled))
  :bind (:map flycheck-mode-map
			  ("C-4" . 'flycheck-list-errors-and-select)
			  ("C-4" . 'flycheck-list-errors-and-select))
  :ensure t
  :defer t)

(defun hook/protobuffer-ts-mode ()
  (c-add-style "my-protobuf" my-protobuf-style t))

(use-package protobuf-ts-mode
  :ensure t
  :hook (protobuf-ts-mode . hook/protobuffer-ts-mode)
  :custom
  (my-protobuf-style '((c-basic-offset . 4)
					   (indent-tabs-mode . nil)))
  :defer t)

(use-package ace-isearch
  :defer t
  :ensure t)

(use-package ace-jump-mode
  :defer t
  :bind (("M-P" . ace-jump-mode)
		 ("M-p" . ace-window))
  :custom (ace-jump-mode-scope 'frame)
  :ensure t)

(defun hook/dired-load ()
  (load "dired-x"))

(defun hook/dired-mode ()
  (dired-hide-details-mode 1))

(add-hook 'dired-load-hook #'hook/dired-load)
(add-hook 'dired-mode-hook #'hook/dired-mode)

(add-to-list 'auto-mode-alist '("Makefile.*" . makefile-mode))

(use-package json-ts-mode
  :hook (json-ts-mode . hs-minor-mode)
  :bind (:map json-ts-mode-map
			  ("M-." . 'end-of-buffer))
  :ensure t
  :defer t)



(add-hook 'emacs-lisp-mode-hook
		  (lambda ()
			(define-key emacs-lisp-mode-map
						"\r" 'reindent-then-newline-and-indent)
			(define-key lisp-interaction-mode-map
						"\r" 'reindent-then-newline-and-indent)))

(defun hook/vc-annotate-mode ()
  (evil-local-mode -1))

(add-hook 'vc-annotate-mode-hook #'hook/vc-annotate-mode)

(defun hook/help-mode ()
  (turn-on-evil-mode))

(add-hook 'help-mode-hook #'hook/help-mode)

(add-hook 'calendar-initial-window-hook #'diary-mark-entries)

(add-to-list 'completion-styles 'initials t)
(add-to-list 'completion-styles 'initials t)

(keymap-set ac-mode-map "M-/" #'auto-complete)

;;; Turning on modes
(keymap-global-set "C-c C-S-c"		#'auto-complete-mode)
(keymap-global-set "C-c c"			#'centred-cursor-mode)
(keymap-global-set "C-c F"			#'flyspell-mode)
(keymap-global-set "C-c C-S-w"		#'wc-mode)
(keymap-global-set "C-c A"			#'evil-local-mode)
(keymap-global-set "C-x 7"			#'calendar)
(keymap-global-set "C-c V"			#'visual-line-mode)
(keymap-global-set "M-P"			#'ace-jump-mode)

;;; Global key bindings
(keymap-global-set "C-S-x C-S-f"	#'find-file-only-window)
(keymap-global-set "C-{"			#'rotate-frame-anticlockwise)
(keymap-global-set "C-}"			#'rotate-frame-clockwise)
(keymap-global-set "M-^"			#'flip-frame)
(keymap-global-set "M->"			#'flop-frame)
(keymap-global-set "C-S-c C-S-c"	#'mc/edit-lines)
(keymap-global-set "C-S-c c"		#'mc/mark-all-like-this)
(keymap-global-set "C-<"			#'mc/mark-previous-like-this)
(keymap-global-set "C->"			#'mc/mark-next-like-this)
(keymap-global-set "M-p"			#'ace-window)
(keymap-global-set "C-c l"			#'org-store-link)
(keymap-global-set "C-S-x C-f"		#'find-alternate-file-other-window)
(keymap-global-set "C-S-x M-f"		#'find-alternate-file)
(keymap-global-set "C-S-z"			#'suspend-frame)
(keymap-global-set "C-h M-f"		#'find-function)
(keymap-global-set "C-2"			#'er/expand-region)
(keymap-global-set "M-,"			#'beginning-of-buffer)
(keymap-global-set "M-."			#'end-of-buffer)
(keymap-global-set "M-<"			#'xref-pop-marker-stack)
(keymap-global-set "C-x C-b"		#'ibuffer)
(keymap-global-set "M-]"			#'other-window)
(keymap-global-set "C-x F"			#'find-name-dired)
(keymap-global-set "M-g l"			#'rgrep)
(keymap-global-set "C-c f"  		#'projectile-find-file)
(keymap-global-set "<backtab>"		#'indent-relative)
(keymap-global-set "S-<backspace>"	#'backward-delete-char-untabify)
(keymap-global-set "C-6"  			#'evil-switch-to-windows-last-buffer)
(keymap-global-set "C-^"  			#'switch-to-buffer)
(keymap-global-set "C-s"			#'swiper)
(keymap-global-set "C-x M-f"		#'quickly-open-file)
(keymap-global-set "C-3"  			#'mine/inc-font-size)
(keymap-global-set "C-1"  			#'mine/dec-font-size)
(keymap-global-set "M-+"  			#'mine/inc-font-size)
(keymap-global-set "C-c DEL"		#'backward-delete-last-char)
(keymap-global-set "M-D"			#'forward-kill-word-and-some)
(keymap-global-set "M-<backspace>"	#'backward-kill-word-and-some)
(keymap-global-set "C-c C-`"		#'cw-set-origin)
(keymap-global-set "C-`"			#'cw-count)
(keymap-global-set "C-~"			#'cw-special-count)
(keymap-global-set "M-E"			#'forward-sentence-double-space)
(keymap-global-set "C-x M-k"		#'kill-forward-paragraph)
(keymap-global-set "C-S-x DEL"		#'backward-kill-paragraph)
(keymap-global-set "M-e"			#'forward-sentence)
(keymap-global-set "M-a"			#'backward-sentence)
(keymap-global-set "M-C"			#'capitalize-prev-word)
(keymap-global-set "M-L"			#'downcase-prev-word)
(keymap-global-set "M-U"			#'upcase-prev-word)
(keymap-global-set "M-F"			#'forward-word-beginning)
(keymap-global-set "M-B"			#'backward-word-end)
(keymap-global-set "C-<up>"			#'copy-from-above-command)
(keymap-global-set "C-0"			#'open-line-at-end-of-line)
(keymap-global-set "C-S-o"			#'open-line-and-indent)
(keymap-global-set "M-S-k"			#'kill-other-buffers-and-windows)
(keymap-global-set "C-x M-o"		#'kill-other-buffer-and-window)
(keymap-global-set "C-c a"			#'org-agenda)
(keymap-global-set "C-c M-c"		#'change-input-method-to-czech)
(keymap-global-set "M-Q"			#'unfill-paragraph)
(keymap-global-set "C-x 4 2"		#'clone-indirect-buffer-other-window-new-name)
(keymap-global-set "C-x 4 C"		#'clone-indirect-buffer-below)
(keymap-global-set "C-x 4 B"		#'switch-to-buffer-below)
(keymap-global-set "C-x 4 F"		#'find-file-below)
(keymap-global-set "M-A"			#'backward-sentence-double-space)
(keymap-global-set "C-<down>"       (lambda () (interactive) (copy-from-bellow-command 1)))
(keymap-global-set "C-<right>"      (lambda () (interactive) (copy-from-above-command 1)))
(keymap-global-set "C-<left>"       (lambda () (interactive) (copy-from-above-command -1)))

(keymap-set xref--xref-buffer-mode-map "M-," #'beginning-of-buffer)
(keymap-set key-translation-map "M-S-SPC" (kbd "​"))
(keymap-set key-translation-map "C-S-SPC" (kbd " "))
(keymap-set minibuffer-mode-map "S-<backspace>" #'mine/backwards-delete-directory-name)

(defadvice self-insert-command (before count-words activate)
  (when (and cw-origin
			 (not (= (point) (point-max))))
	(let (lis)
	  (dolist (place cw-origin)
		(if (<= (point) place)
			(push (1+ place) lis)
		  (push place lis)))
	  (setq cw-origin (reverse lis)))))

(advice-add 'ispell-add-per-file-word-list :before
            (lambda (word)
              (when cw-origin
                (let ((len (1+ (length word)))
                      lis)
                  (dolist (place cw-origin)
                    (push (+ len place) lis))
                  (setq cw-origin (reverse lis))))))

(advice-add 'yank :before (lambda (&optional ARG)
                            (when (and cw-origin
                                       (not (= (point) (point-max))))
                              (setq cw-pre-yank-length (length (buffer-string)))
                              (setq cw-pre-yank-point (point)))))

(advice-add 'yank :after
            (lambda (&optional ARG)
              (when (and cw-origin
                         (not (= (point) (point-max))))
                (let ((string-length (- (length (buffer-string)) cw-pre-yank-length))
                      lis)
                  (dolist (place cw-origin)
                    (if (<= cw-pre-yank-point place)
                        (progn
                          (push (+ string-length place) lis)
                          (message "num: %d" (+ string-length place)))
                      (push place lis)))
                  (setq cw-origin (reverse lis))))))

(advice-add 'insert :before (lambda (&rest string)
                              (when (and cw-origin
                                         (not (= (point) (point-max))))
                                (let (lis)
                                  (dolist (place cw-origin)
                                    (if (<= (point) place)
                                        (push (+ (length (apply #'append string)) place) lis)
                                      (push place lis)))
                                  (setq cw-origin (reverse lis))))))

(advice-add 'xref-goto-xref :after 'hs--show-on-jump)
(advice-add 'goto-line :after 'hs--show-on-jump)
(advice-add 'backward-delete-char :before 'delete-space-lines)
(advice-add 'backward-delete-char :after 'safe-indent)

(mapc (lambda (elisp-file)
		(when (file-exists-p elisp-file)
		  (load-file elisp-file)))
	  (list (concat PRIVATE-DIR "code/elisp/story mode.el")
			(concat PRIVATE-DIR "code/elisp/pronunciation.el")
			"~/cease/emacs-lisp/cease-ts-mode.el"))

(load-theme 'my-pastels t)

(add-hook 'git-commit-mode-hook #'mine/git-commit-hooks)
(add-hook 'minibuffer-setup-hook 'my-minibuffer-setup)
(add-hook 'doc-view-mode-hook #'turn-off-evil-mode)
(add-hook 'image-mode-hook (lambda () (evil-local-mode -1)))
(add-hook 'window-configuration-change-hook #'balance-windows)
(add-hook 'before-save-hook 'font-lock-fontify-buffer)
(add-hook 'find-file-hook (lambda ()
                            (if (or (string= "image-mode" major-mode)
                                    (string= "doc-view-mode" major-mode))
                                (evil-local-mode -1)
                              (turn-on-evil-mode))))

(display-battery-mode 1)
(show-paren-mode)
(global-hl-todo-mode 1)
(tool-bar-mode -1)
(menu-bar-mode -1)
(appt-activate 1)
(display-time-mode (work-or-home -1 1))
(pending-delete-mode)
(column-number-mode)
(global-undo-tree-mode 1)
(selectrum-mode 1)
(selectrum-prescient-mode 1)
(save-place-mode 1)
(global-hl-line-mode)
(global-hl-line-highlight-all)
(global-auto-revert-mode 1)
(global-diff-hl-mode 1)
(winner-mode 1)
(global-display-line-numbers-mode)

(defmacro map-to-treesit-mode (old-mode new-mode)
  "What a mess this thing is.

So... To enable Emacs native tree-sitter (called treesit), we actually
need to change which major mode we run. For example, instead of enabling
some minor mode tree-sitter, we change go-mode into go-ts-mode, and
c-mode into c-ts-mode. This is done for compatibility, and is out of our
hands.

To do this, we push a new entry into `major-mode-remap-alist', which
will run `go-ts-mode' whenever a file would want to enter into
`go-mode'. So far so good.

See the function for why this turns nasty quite quickly."

  ;; First off, we need to remap the hooks from `old-mode' to `new-mode'. This
  ;; isn't easy because we need the name of the hooks of both modes, and that
  ;; doesn't come as an argument.
  ;;
  ;; We use the `intern' to create symbols with the supplied name.
  (let* ((old-hook (intern (format "%s-hook" old-mode)))
		 (new-hook (intern (format "%s-hook" new-mode))))

	;; This is just how macros work. They shouldn't evaluate anything, they
	;; should return a list which will be evaluated by the caller. The `()
	;; notation will return such a list.
    `(progn

	   ;; Just to be sure, we need to load `new-mode' before using it.
       (require ',new-mode)

	   ;; Now we add the hooks. To run `old-mode-hook', we add to
	   ;; `new-mode-hook' this lambda function that calls `old-mode-hook'
	   ;; directly. It isn't pretty, but it's recommended.
       (add-hook ',new-hook
				 (lambda () (run-hooks ',old-hook)))

	   ;; `go-mode' may not be loaded yet. Apprently it doesn't matter if I
	   ;; `require' it first, it just ain't loaded yet. So we need to execute
	   ;; this after-load bullshit which waits for `go-mode' to be up, and then
	   ;; executes the following function.
	   ;;
	   ;; HOWEVER, said following function must be wrapped in the `() block
	   ;; because that's what `eval-after-load' expects. This causes the need
	   ;; for additional ', to get the mode names.
       (eval-after-load (symbol-name ',old-mode)
		 `(progn (when (featurep ',',old-mode)
				   ;; `old-mode' can be something like 'go-mode, but we're now
				   ;; two `() deep, so we need to retrieve it by `,`,old-mode.
				   ;; Isn't that fun? I experimented. I'm sure there's a better
				   ;; way, but I don't have it.
				  (push (list ',',old-mode ',',new-mode)
						major-mode-remap-alist)))))))

(mapc (lambda (mode-map) (let* ((old-mode (car mode-map))
								(treesit-mode (cadr mode-map)))
						   ;; This eval is here because `old-mode' would otherwise be passed as a
						   ;; symbol (so 'old-mode) rather than the value which it holds (such as
						   ;; `go-mode`). Using `eval' and `() will let us evaluate `old-mode'
						   ;; first (into "go-mode"), then we'll execute the macro with the
						   ;; result:
						   ;; 
						   ;; "(map-to-treesit-mode 'go-mode ...)"
						   ;;
						   ;; It's painful, but necessary.
						   (eval `(map-to-treesit-mode ,old-mode ,treesit-mode))))
	  '((go-mode go-ts-mode)
		(rust-mode rust-ts-mode)))
