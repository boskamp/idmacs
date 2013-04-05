(setq idm-dir-home (getenv "emacs_dir"))
;; Get path of site-lisp directory in a win32 emacs install
(setq idm-dir-site-lisp (expand-file-name "site-lisp" idm-dir-home))
;; Credits to Rob Christie
;; http://emacsblog.org/2007/01/17/indent-whole-buffer/
(defun iwb ()
  "indent whole buffer"
  (interactive)
  (delete-trailing-whitespace)
  (indent-region (point-min) (point-max) nil)
  (untabify (point-min) (point-max))
  )
;; Credits to stackoverflow.com user ExplodingRat
;; http://stackoverflow.com/questions/9688748/emacs-comment-uncomment-current-line
(defun comment-or-uncomment-region-or-line ()
    "Comments or uncomments the region or the current line if there's no active region."
    (interactive)
    (let (beg end)
        (if (region-active-p)
            (setq beg (region-beginning) end (region-end))
	  (setq beg (line-beginning-position) end (line-end-position)))
        (comment-or-uncomment-region beg end)))
;; Enable electric-indent in js2-mode
(add-hook
 'js2-mode-hook
 (lambda()
   (electric-indent-mode t)
   (electric-pair-mode t)
   (setq electric-pair-skip-self t)
   ;; create concatenated multiline strings on RET
   (local-set-key
    (kbd "RET")
    'js2-line-break)
   ;; indent whole buffer on Ctrl+Shift+f
   (local-set-key
    (kbd "C-S-f")
    'iwb)
   ;; Uncomment line or region on Ctrl+Shift+7
   (local-set-key
    (kbd "C-/")
    'comment-or-uncomment-region-or-line)
   ;; Line comment also empty lines
   (setq comment-empty-lines t)
   ;; TODO: load IDM symbols from file and add them to js2-additional-externs
   ;; (add-to-list 'js2-additional-externs "uError")
   ;; (add-to-list 'js2-additional-externs "uInfo")
   ))
;; Always show file name in frame title
(setq frame-title-format "%b")
;; Never require yes or no style answers
(defalias 'yes-or-no-p 'y-or-n-p)
;; Always show line numbers in the left margin
(global-linum-mode t)
;; Always show column numbers
(setq column-number-mode t)
;; Don't show the startup screen
;;(setq inhibit-startup-screen t)
;; Use Windows-like keybindings for copy&paste, undo and select
(cua-mode t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; js2-mode (mooz fork)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(autoload 'js2-mode "js2-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
; SAP IDM always uses .vbs as a script file extension,
; even for JavaScript. Load js2-mode also for .vbs files.
(add-to-list 'auto-mode-alist '("\\.vbs$" . js2-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; auto-complete-mode
;; See http://cx4a.org/software/auto-complete/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories 
	     (expand-file-name "ac-dict" idm-dir-site-lisp))

(let ((idm-dir-dict (expand-file-name "idmacs-dict" idm-dir-home)))
  (let ((idm-dir-dict-tables     (expand-file-name "tables"     idm-dir-dict))
	(idm-dir-dict-views      (expand-file-name "views"      idm-dir-dict))
	(idm-dir-dict-attributes (expand-file-name "attributes" idm-dir-dict))
	)
  
    (add-to-list 'ac-dictionary-directories idm-dir-dict-tables)
    (add-to-list 'ac-dictionary-directories idm-dir-dict-views)
    (add-to-list 'ac-dictionary-directories idm-dir-dict-attributes)
    )
  )

(global-auto-complete-mode t)
(setq ac-modes '(js2-mode))
(setq ac-auto-start 6)

(add-hook 'js2-mode-hook
	   (lambda ()
	     (local-set-key (kbd "C-SPC") 'auto-complete)
	     (setq ac-user-dictionary ())
	     (dolist (x js2-default-externs)
	       (push x ac-user-dictionary))
	     (setq ac-sources
		   '(ac-source-yasnippet
		     ac-source-dictionary
		     ;; words in buffer must come after yasnippet,
		     ;; otherwise same snippet cannot be expanded twice
		     ac-source-words-in-buffer
		     ))
	     (setq ac-ignore-case t)
	     ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; yasnippet
;; See https://github.com/capitaomorte/yasnippet
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'yasnippet)
(yas-reload-all)
(add-hook 'js2-mode-hook
	   (lambda ()
	     (yas-minor-mode)
	     (local-set-key (kbd "C-M-SPC") 'yas-exit-snippet)
	     ))
(setq yas-triggers-in-field t)

