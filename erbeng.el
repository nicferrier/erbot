;;; erbeng.el --- 
;; Time-stamp: <2003-02-27 10:01:12 deego>
;; Copyright (C) 2002 D. Goel
;; Emacs Lisp Archive entry
;; Filename: erbeng.el
;; Package: erbeng
;; Author: D. Goel <deego@glue.umd.edu>
;; Version: 99.99
;; Author's homepage: http://deego.gnufans.org/~deego
;; For latest version: 

(defvar erbeng-home-page
  "http://deego.gnufans.org/~deego")


 
;; This file is NOT (yet) part of GNU Emacs.
 
;; This is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
 
;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.
 

;; See also:


;; Quick start:
(defvar erbeng-quick-start
  "Help..."
)

(defun erbeng-quick-start ()
  "Provides electric help regarding variable `erbeng-quick-start'."
  (interactive)
  (with-electric-help
   '(lambda () (insert erbeng-quick-start) nil) "*doc*"))

;;; Introduction:
;; Stuff that gets posted to gnu.emacs.sources
;; as introduction
(defvar erbeng-introduction
  "Help..."
)

;;;###autoload
(defun erbeng-introduction ()
  "Provides electric help regarding variable `erbeng-introduction'."
  (interactive)
  (with-electric-help
   '(lambda () (insert erbeng-introduction) nil) "*doc*"))

;;; Commentary:
(defvar erbeng-commentary
  "Help..."
)

(defun erbeng-commentary ()
  "Provides electric help regarding variable `erbeng-commentary'."
  (interactive)
  (with-electric-help
   '(lambda () (insert erbeng-commentary) nil) "*doc*"))

;;; History:

;;; Bugs:

;;; New features:
(defvar erbeng-new-features
  "Help..."
)

(defun erbeng-new-features ()
  "Provides electric help regarding variable `erbeng-new-features'."
  (interactive)
  (with-electric-help
   '(lambda () (insert erbeng-new-features) nil) "*doc*"))

;;; TO DO:
(defvar erbeng-todo
  "Help..."
)

(defun erbeng-todo ()
  "Provides electric help regarding variable `erbeng-todo'."
  (interactive)
  (with-electric-help
   '(lambda () (insert erbeng-todo) nil) "*doc*"))

(defvar erbeng-version "99.99")

;;==========================================
;;; Code:

(require 'cl)
(defgroup erbeng nil 
  "The group erbeng"
   :group 'applications)
(defcustom erbeng-before-load-hooks nil "" :group 'erbeng)
(defcustom erbeng-after-load-hooks nil "" :group 'erbeng)

(defcustom erbeng-reply-timeout 20
  "Time after which the bot times out...")

(run-hooks 'erbeng-before-load-hooks)





(defvar erbeng-msg )
(defvar erbeng-proc)
(defvar erbeng-nick)
(defvar erbeng-tgt)
(defvar erbeng-localp)
(defvar erbeng-userinfo)

;;;###autoload
(defun erbeng-main (msg proc nick tgt localp userinfo)
  " The main function: Takes a line of message and generates a reply to it. 
The result is a string.  If the result is nil, that means: Do NOT reply...
The last field localp is here for historical reasons, and shall be
ignored...

One very important criterion here should be:

erbot should learn to avoid runaway talks with other bots.  For this
reason: 

 [a] it should take a break every now and then, say: a 1-minute break
after every 1000 commands.  It should probably announce its break.
AND/OR 
 [b] It should learn to reply only 99 out of 100 times.  Moreover,
before it shuts up, it should let any humans know what it is doing.
tgt, nick and sspec will probably mostly remain unused...  

proc == name of the process in the channel
tgt == channel
nick == who from
userninfo looks like (\"deego\" \"user\" \"24-197......\")
sspec looks like: [\"PRIVMSG\"
\"deego!~user@24-197-159-102.charterga.net\" \"#testopn\" \"hi erbot\" \nil
nil nil nil nil nil nil nil nil nil nil nil nil nil nil nil nil nil
nil nil\ nil nil nil nil nil nil nil nil]

"
  (let* (
	 (erbeng-nick nick)
	 (erbeng-msg msg)
	 (erbeng-proc proc)
	 (erbeng-tgt tgt)
	 (erbeng-localp localp)
	 (erbeng-userinfo userinfo)
	 (erbc-found-query-p nil)
	 (erbc-addressedatlast nil)
	 (erbc-message-sans-bot-name erbc-message-sans-bot-name)
	 (erbc-prestring erbc-prestring)
	 tmpvar
	 parsed-msg rep
	 )
    ;;(concat nick ": " "/leave Test.. one big big test...")
    ;;(erbutils-ignore-errors
     
     ;; this can also modify erbc-found-query
    (setq parsed-msg 
	  (condition-case tmpvar
	      (erbc-parse msg proc nick tgt localp userinfo)
	    (error 
	     ;;"(error \"Please supply a completed lisp form\")"
	     ;; Note that this could be bad: 
	     ;; someone may not even be referring to the bot here:
	     (format "(erbc-english-only %S)" msg)
	     
	     )))

    ;;(if (and (first parsed-msg) erbot-nick
    ;;	      (string= (first parsed-msg)
    ;;		       erbot-nick))
    ;; parsed-msg will never be null if the msg was addressed to fsbot..
    (cond
     (parsed-msg
      (setq rep 
	    ;;(erbutils-ignore-errors
	     (with-timeout 
		 (erbeng-reply-timeout
		  "overall timeout")
	       (erbutils-ignore-errors
		(erbeng-get-reply parsed-msg proc nick tgt )))
	     )
      
      (when rep
	(if (erbeng-lisp-object-p parsed-msg)
	    (setq rep (format "%S" rep)))
	
	(progn (setq rep 
		     (format 
		      (if (stringp rep) "%s%s" 
			"%s%S")
		      erbc-prestring rep))

	       (if (null (split-string rep))
		   (if 
		       erbc-found-query-p ""
		     "EMPTY STRING RETURNED.." )
		 
		 rep))))
     (t 'noreply))))


(defun erbeng-lisp-object-p (msg) 
  (setq msg (ignore-errors (read msg)))
  (and (listp msg)
       (let ((fir (format "%s" (first msg))))
	 (or
	  (string-match "concat" fir)
	  (string-match "regexp-quote" fir)
	 ;; want to allow erbc-rq to show the regexp without quoting..
	 ;;(string-match "erbc-rq" fir)
	  ))))



;(defun erbeng-init-parse (msg)
;  (if (equal 0 (string-match "," msg))
;      (setq msg (concat "erbot " 
;			(substring msg 1 (length msg)))))
;  (let ((spl (split-string msg)))
;    (if (> (length spl) 0)
;	(erbeng-init-frob-split-string spl)
;      nil)));;;

;;; ;(defun erbeng-init-frob-split-string (spl)
;;; ;  "spl is the split string ..;;;;

;;; ;now, we do not need to split wrt commas... in fact, that will be
;;; ;dangerous, and can spoil the meanings of commas inside parse
;;; ;commands...;;

;;; ;converts all accepted formats to look like this:
  

;;; ; \(\"erbot\" \"foo\" \"bar\"\)

;;; ;"
;;;  ; (let* ((do-again t)
;;; 	; (new-spl
;;; 	 ; (cond
;;; 	  ; ;; , foo bar
;;; 	   ;((string= (first spl) ",")
;;; 	    (cons erbot-nick (cdr spl)))
;;; 	   ((equal 
;;; 	     (string-match "," (first spl)) 0)
;;; 	    (cons erbot-nick
;;; 		  (append (split-string (first spl) ",")
;;; 			  (cdr spl))))
;;; 	   ((equal
;;; 	     ;; erbot:
;;; 	     (string-match (concat erbot-nick ":") (first spl)) 0)
;;; 	    (append (split-string (first spl) ":")
;;; 		    (cdr spl)))
;;; 	   ((equal 
;;; 	     ;; fdbot,
;;; 	     (string-match (concat erbot-nick ",") (first spl)) 0)
;;; 	    (append (split-string (first spl) ",")
;;; 		    (cdr spl)))
;;; 	   (t (progn (setq do-again nil) spl)))))
;;;     (if do-again
;;; 	(erbeng-init-frob-split-string new-spl)
;;;       ;; removed the extra ""  etc. and all , ; erc. etc. 
;;;       (split-string
;;;        (mapconcat 'identity
;;; 		  new-spl " ")
;;;        "[ \f\t\n\r\v,;]+"))))




(defun erbeng-get-reply (msg &optional proc nick tgt &rest foo)
  "  ;; now assumes that the msg is (a string) in lisp format... and this just
  ;; evals it.."
  (eval (read msg)))
;  (let* (
;	 (lispmsg 
;	  (erbeng-read (erbutils-stringify msg))))
;    (if (and lispmsg (listp lispmsg))
;	(erblisp-process-msg proc nick tgt 
;			     lispmsg)
;      (let ((englispmsg (erbc-parse-english msg proc nick)))
;	(erblisp-process-msg proc nick tgt englispmsg)))))



(defun erbeng-read (msg)
  (ignore-errors (read msg)))









(provide 'erbeng)
(run-hooks 'erbeng-after-load-hooks)



;;; erbeng.el ends here
