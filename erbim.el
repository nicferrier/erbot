;;; erbim.el --- input method searching
;; Time-stamp: <2006-08-22 01:16:17 fledermaus>
;; Copyright (C) 2006 V. Dasmohapatra
;; Emacs Lisp Archive entry
;; Filename: erbim.el
;; Package: erbim
;; Author: V. Dasmohapatra <vivek@etla.org>
;; Keywords:  
;; Version:  
;; URL:  http://www.emacswiki.org/cgi-bin/wiki.pl?ErBot
;; For latest version: 

(require 'quail)
(require 'iso-transl)

(defvar erbim-keymaps-map nil
  "Storage for the inverted keymaps for the input methods we have searched.")

(defun erbim-enc (thing)
  "Standard encoding for all strings (many chars don't work in an emacs
running screen, so chars and unencoded strings may not be safe or work)."
  (encode-coding-string thing 'utf-8))

(defun erbim-c2s (thing)
  "map a character to the appropriate string. This is not a straightforward
operation using char-to-string (for some reason)."
  (if (> 256 thing) (single-key-description thing) (char-to-string thing)))

(defun erbim-map (map)
  "Traverse the input method's MAP, invert it, and return that."
  (let ((char-map nil))
    (mapc (lambda (M) (erbim-map-internal M "")) (cdr map)) char-map))

(defun erbim-interpret-target (target)
  "Examine the TARGET of a given input method map entry and turn it
into a list of (unencoded) strings.\n
Destinations can be symbols (keyboard macros) vectors of strings or 
vectors of characters, or a cons of the form (LIST . TARGET)."
  ;;(message "target %S" target)
  (if (vectorp target) 
      (mapcar (lambda (T) (if (integerp T) (erbim-c2s T) T)) target)
    (if (and (listp target) (listp (car target)))
        (progn (message "weird target: %S" target)
          (erbim-interpret-target (cdr target)))
      (if (symbolp target)
          (and (fboundp target) 
               (and (vectorp (symbol-function target)) 
                    (erbim-interpret-target (symbol-function target)) )) 
        (list (if (integerp target) (string target) target)) )) ))

(defun erbim-map-internal (map &optional so-far)
  "Does the actual work of `erbim-map'."  
  (let ((iseq-str
         (format (if (symbolp (car map)) "%s %S " "%s%c") (or so-far "")
                 (car map)))
        (tgt  nil)
        (tail nil))
    ;;(message "%S %S" map so-far)
    (setq tgt (cdr map))
    (if (setq tgt (or (car-safe tgt) 
                      (and (vectorp tgt) tgt) 
                      (and (symbolp tgt) tgt)))
        (progn
          ;;(message "tgt: %S" tgt)
          (setq char-map
                (append char-map
                        (mapcar 
                         (lambda (T) (cons (erbim-enc T) iseq-str))
                         (erbim-interpret-target tgt)) ))
          (when (and (listp (cdr map)) (setq tail (cddr map)))
            (if (listp (cdar tail))
                (erbim-map-internal (car tail) iseq-str)
              ;;(message "path B: %S" tail)
              (mapcar (lambda (M) (erbim-map-internal M iseq-str)) tail)) ))
      (when (listp (cdr map))
        (mapcar
         (lambda (M) (erbim-map-internal M iseq-str)) (cddr map))) ) ))

;; load iso-transl's inverted keymap
(add-to-list 'erbim-keymaps-map 
             (cons "iso-transl" (erbim-map iso-transl-ctl-x-8-map)))

(defun erbim-package-list ()
  "Return the list of input methods that erbim can understand.
iso-transl is not exactly an input method, but it is a special case."
  (cons "iso-transl"
        (mapcar (lambda (I) (if (eq (caddr I) 'quail-use-package) (car I))) 
                input-method-alist) ))

(defun erbim-keymap-map (im)
  "Return the inside-out keymap for input method IM (IM is a string)."
  (or (cdr (assoc im erbim-keymaps-map))
      (let ( (map (erbim-map 
                   (nth 2 (assoc im quail-package-alist)))) )
        (setq erbim-keymaps-map (cons (cons im map) erbim-keymaps-map)) map) ))

(defun where-is-char (c &optional im-list)
  "Given a string C (usually, but not always, one character (but NOT 
necessarily one byte)) in length, search the input methods in either IM-LIST 
or `erbim-package-list' and return a help string describing the key sequences 
\(per input method) that can be used to enter C."
  ;; assume we got a string: char functions are broken in fsbot becuase of
  ;; some screen/emacs/terminal black magic (which I do not understand)
  ;; so we cannot use (aref string 0) or string-to-char reliably.
  (let ((char (erbim-enc c))
        (res   nil)
        (qsec  nil))
    (mapc (lambda (Q)
            ;; exclude chinese-* methods (too big) and misc problematic ones:
            (when (and Q 
                       (not (string-match "^chinese-" Q))
                       (not (member Q '("tibetan-wylie" ;; too big?
                                        ;; "greek-ibycus4" ;; ok actually
                                        )) ))
              ;; load the input method if it's not iso-transl (special case)
              ;; and we haven't already done so:
              (or (equal Q "iso-transl")
                  (with-temp-buffer
                    (or (assoc Q quail-package-alist) 
                        (activate-input-method     Q)) ))
              (message "checking %s" Q)
              ;; check to see if we have a quail package (iso-transl is
              ;; not a quail package, don't check for it here):
              (when (or (equal Q "iso-transl") (assoc Q quail-package-alist))
                ;;(message "%s keymap - %d" Q (length (erbim-keymap-map Q)))
                ;; extract the inverse keymap if there is one, and pull
                ;; out the first entry for the char we are looking for:
                (when (setq qsec (assoc char (erbim-keymap-map Q)))
                  ;;(message "found sequence %s" qsec)
                  (setq res (cons (cons Q (cdr qsec)) res)) )) ))
          (or im-list (erbim-package-list)))
    ;; feed the results to the user (if there are lots of input methods,
    ;; just list the input methods instead):
    (if (> (length res) 10)
        (format "%s is in the following input methods:\n%s"
                c (mapconcat 'car res " "))
      (mapconcat 
       (lambda (R) 
         (if (equal (car R) "iso-transl")
             (mapconcat 'identity 
                        (cons "C-x 8" (split-string (cdr R) "")) " ")
           (format "%s: %s" (car R) (cdr R)) )) res "\n")) ))

(defun fsi-where-is-char (&optional key &rest im-list)
  (let ((imlist nil) 
	(key (if key (if (symbolp key) (symbol-name key) key) nil)))
    (if key (where-is-char key (mapcar 'symbol-name im-list)) 
      "where-is-char <CHAR-OR-SEQUENCE> [ INPUT-METHOD INPUT-METHOD... ]") ))

(provide 'erbim)

;; (where-is-char "Þ")
;; (assoc (erbim-enc "þ") (erbim-keymap-map "iso-transl"))

;; (setq erbim-keymaps-map nil)
;; (insert "\n" (pp (assoc "japanese" erbim-keymaps-map)))
;; (insert "\n" (pp (nth 2 (assoc "greek-babel" quail-package-alist))))
;; (insert "\n" (pp (assoc "greek-babel" erbim-keymaps-map)))

;; (erbim-map iso-transl-ctl-x-8-map)
;; (insert "\n" 
;;   (pp (erbim-map (nth 2 (assoc "greek-babel" quail-package-alist)))))
;; (erbim-map (nth 2 (assoc "greek-babel" quail-package-alist)))
