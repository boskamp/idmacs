;; Copyright 2013 Lambert Boskamp
;;
;; Author: Lambert Boskamp <lambert@boskamp-consulting.com.nospam>
;;
;; This file is part of IDMacs.
;;
;; IDMacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; IDMacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with IDMacs.  If not, see <http://www.gnu.org/licenses/>.

;; First of all, start the server
(server-start)

;; Put Emacs installation directory from environment into global variable
(setq idmacs-emacs-dir (getenv "emacs_dir"))

;; Don't show Emacs startup screen
(setq inhibit-startup-screen t)

(defun idmacs-activate ()
  "Save current buffer and return to MMC"
  (interactive)
  (save-buffer)
  (idmacs-quit)
  )
(defun idmacs-quit ()
  "Quit IDMacs and return to MMC"
  (interactive)
  (server-edit)
  (suspend-frame)
  )
;; Credits to Rob Christie
;; http://emacsblog.org/2007/01/17/indent-whole-buffer/
(defun idmacs-pretty-print ()
  "Pretty print current buffer"
  (interactive)
  (delete-trailing-whitespace)
  (indent-region (point-min) (point-max) nil)
  (untabify (point-min) (point-max))
  )
;; Credits to stackoverflow.com user ExplodingRat
;; http://stackoverflow.com/questions/9688748/emacs-comment-uncomment-current-line
(defun idmacs-toggle-line-comment ()
  "Comments or uncomments the region or the current line if there's no active region."
  (interactive)
  (let (beg end)
    (if (region-active-p)
        (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (comment-or-uncomment-region beg end)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Add all IDM internal functions to js2-additional-externs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun idmacs-js2-declare-builtins ()
  "Make all IDM built-in function names declared in js2-mode"
  (interactive)
  (setq js2-global-externs nil)
  (let ((builtins-dict-file
         (concat idmacs-emacs-dir "/etc/idmacs/dict/builtins.dic")))
    (if (file-exists-p builtins-dict-file)
        (save-excursion
          (with-temp-buffer
            (goto-char (point-min))
            (insert-file-contents builtins-dict-file)
            ;; Using "^.*$" instead of "^.+$" results in endless loop,
            ;; so search for non-empty lines only
            (while (re-search-forward "^.+$" (point-max) t)
              (let ((func-name (match-string 0)))
                (push func-name js2-global-externs)
                (message "Declared %s" func-name)
                );;let
              );;while
            );;with-temp-buffer
          );;save-excursion
      );;if
    );;let
  );;defun

;; Always show file name in frame title
(setq frame-title-format "%b")

;; Never require yes or no style answers
(defalias 'yes-or-no-p 'y-or-n-p)

;; Always show line numbers in the left margin
(global-linum-mode t)

;; Always show column numbers
(setq column-number-mode t)

;; Use Windows-like keybindings for copy&paste, undo and select
(cua-mode t)

;; Line comment also empty lines
(setq comment-empty-lines t)

;; Load IDM symbols from file and add them to global list of externs
(idmacs-js2-declare-builtins)

;; Always highlight matching parens
(show-paren-mode t)

;; TODO: Electric layout mode needs more exploration on my behalf
;; until it can be enabled for production.
;; (electric-layout-mode)
;; (setq electric-layout-rules '(?\{ . after))

;; Globally enable electric-indent and electric-pair
(electric-indent-mode t)
(electric-pair-mode t)
(setq electric-pair-skip-self t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Global keybindings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Must rebind set-mark-command because it conflits with
;; completion in js2-mode
(global-set-key
 (kbd "C-M-SPC")
 'set-mark-command)

;; Poor man's Pretty Print: indent whole buffer
(global-set-key
 (kbd "<S-f1>")
 'idmacs-pretty-print)

;; Poor man's Compile: move to next error/warning
(global-set-key
 (kbd "<C-f2>")
 'next-error)

;; Poor main's Activate: save buffer, then quit
(global-set-key
 (kbd "<C-f3>")
 'idmacs-activate)

;; Poor main's Activate: save buffer, then quit
(global-set-key
 (kbd "<C-f12>")
 'idmacs-quit)

;; Toggle line comment
(global-set-key
 (kbd "C-/")
 'idmacs-toggle-line-comment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; js2-mode (mooz fork)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(autoload 'js2-mode "js2-mode" nil t)

(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
                                        ; SAP IDM always uses .vbs as a script file extension,
                                        ; even for JavaScript. Load js2-mode also for .vbs files.
(add-to-list 'auto-mode-alist '("\\.vbs$" . js2-mode))

(add-hook
 'js2-mode-hook
 (lambda()
   ;; Create concatenated multiline strings on RET
   (local-set-key
    (kbd "RET")
    'js2-line-break)
   ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; auto-complete-mode
;; See http://cx4a.org/software/auto-complete/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'auto-complete-config)

(let ((idmacs-dir-dict (concat idmacs-emacs-dir "/etc/idmacs/dict/")))
  (add-to-list
   'ac-user-dictionary-files
   (concat idmacs-dir-dict "tables.dic"))

  (add-to-list
   'ac-user-dictionary-files
   (concat idmacs-dir-dict "views.dic"))

  (add-to-list
   'ac-user-dictionary-files
   (concat idmacs-dir-dict "attributes.dic"))

  ;; Never add below file; it's not be processed by auto-complete
  ;; directly, but instead used to populate js2-global-externs.
  ;; See function idm-js2-declare-builtins
  ;; (add-to-list
  ;;  'ac-user-dictionary-files
  ;;  (concat idmacs-dir-dict "builtins.dic"))

  );;let

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
                    ;; Words in buffer must come after yasnippet,
                    ;; otherwise same snippet cannot be expanded twice
                    ac-source-words-in-buffer
                    ))
            (setq ac-ignore-case t)
            );;lambda
          );;add-hook

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; yasnippet
;; See https://github.com/capitaomorte/yasnippet
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'yasnippet)
(setq yas/root-directory (concat idmacs-emacs-dir "/etc/idmacs/snippets"))
(yas-reload-all)
(setq yas-triggers-in-field t)
(add-hook 'js2-mode-hook
          (lambda ()
	    ;;Enable yasnippet only in js2-mode
            (yas-minor-mode)
            );;lambda
          );;add-hook
