;; Get path of site-lisp directory in a win32 emacs install
(setq idm-site-lisp (expand-file-name "site-lisp" (getenv "emacs_dir")))
;; Created by Rob Christie
;; http://emacsblog.org/2007/01/17/indent-whole-buffer/
(defun iwb ()
  "indent whole buffer"
  (interactive)
  (delete-trailing-whitespace)
  (indent-region (point-min) (point-max) nil)
  (untabify (point-min) (point-max))
  )
;; Enable electric-indent in js2-mode
(add-hook 'js2-mode-hook (lambda()
			   (electric-indent-mode t)
			   (electric-pair-mode t)
			   (setq electric-pair-skip-self t)
			   ;; create concatenated multiline strings on RET
			   (local-set-key (kbd "RET") 'js2-line-break)
			   ;; indent whole buffer on Ctrl+Shift+f
			   (local-set-key (kbd "C-S-f") 'iwb)
			   (add-to-list 'js2-additional-externs "uError")
			   (add-to-list 'js2-additional-externs "uInfo")			   ))
;; Always show file name in frame title
(setq frame-title-format "%b")
;; Never require yes or no style answers
(defalias 'yes-or-no-p 'y-or-n-p)
;; Always show line numbers in the left margin
(global-linum-mode)
;; Always show column numbers
(setq column-number-mode t)
;; Don't show the startup screen
;;(setq inhibit-startup-screen t)
(cua-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; js2-mode (mooz fork)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(autoload 'js2-mode "js2-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
; SAP IDM always uses .vbs as a script file extension,
; even for JavaScript. Load js2-mode also for .vbs files.
(add-to-list 'auto-mode-alist '("\\.vbs$" . js2-mode))

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;; auto-complete-mode
;; ;; See http://cx4a.org/software/auto-complete/
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (require 'auto-complete-config)
;; (add-to-list 'ac-dictionary-directories 
;; 	     (expand-file-name "ac-dict" idm-site-lisp))

;; (defun idm-ac-js2-mode ()
;;   (setq ac-sources 
;; 	'(ac-source-words-in-buffer ac-source-dictionary ac-source-yasnippet))
;;   (add-to-list 'js2-additional-externs "uError")
;; )

;; (add-hook 'js2-mode-hook 'idm-ac-js2-mode)
;; (global-auto-complete-mode t)
;; (setq ac-auto-start 2)
;; (setq ac-ignore-case t)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;; yasnippet
;; ;; See https://github.com/capitaomorte/yasnippet
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (require 'yasnippet)
;; (yas-global-mode 1)

