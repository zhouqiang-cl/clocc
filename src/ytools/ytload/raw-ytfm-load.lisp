;-*- Mode: Common-lisp; Package: ytools; -*-
(in-package :ytools)
;;;$Id: raw-ytfm-load.lisp,v 1.3.2.5 2005/07/16 15:20:37 airfoyle Exp $

;;; This file is for recompiling a subset of ytools-core-files* 
;;; (in the proper order) when debugging YTFM.
;;; It assumes that ytload/ytload.lisp has already been loaded.
;;; The working directory should be set to the ytools directory.

(load-yt-config-file)

(setq *default-pathname-defaults*
      (pathname "~/CVSified/dev/clocc/src/ytools/"))

(load "ytload/ytfm.lmd")

(load "ytools.lsy")

(setq *readtable* ytools-readtable*)

(defvar last-yt-comp* nil)

(defun yt-comp (&optional fname)
   (setq *readtable* ytools-readtable*)
   (cond (fname
	  (setq last-yt-comp* fname))
	 (last-yt-comp*
	  (setq fname last-yt-comp*))
	 (t
	  (error "No default yt-comp argument set yet")))
   (compile-file fname
		 :output-file (merge-pathnames
			         (make-pathname :name fname :type lisp-object-extn*)
				 ytools-bin-dir-pathname*)))

(defun yt-bload (&optional fname)
   (cond ((not fname)
	  (cond (last-yt-comp*
		 (setq fname last-yt-comp*))
		(t
		 (error "No default yt-comp argument set yet")))))
   (load (merge-pathnames
	    (make-pathname :name fname :type lisp-object-extn*)
	    ytools-bin-dir-pathname*)))

;;; Load ytfm (ytools-core-files*).  Compile the ones in the 'new-files'
;;; alist (each entry is (old-file-name temp-new-file-name)).
;;; If 'cautious', then after a replacement like that recompile all
;;; the remaining files.
(defun yt-recompile (new-files cautious
		     &key (start-with nil) (stop-after nil))
   (let ((compiling nil)
	 (files (cond (start-with
		       (member start-with ytools-core-files*
			       :test #'string=))
		      (t ytools-core-files*))))
      (dolist (fname files)
	 (let ((e (assoc fname new-files :test #'string=)))
	    (cond (e
		   (setq compiling t)
		   (yt-comp (second e))
		   (yt-bload))
		  ((and compiling cautious)
		   (yt-comp fname)
		   (yt-bload))
		  (t
		   (yt-bload fname)))
	    (cond ((and stop-after
			(string= fname stop-after))
		   (return)))))))

;;; More variations on the same theme.
;;; This is all ad-hoc, and contains various directory names hard-wired. --

(defun co (s &optional no-lo)
   (compile-file
      (concatenate 'string "~/CVSified/dev/clocc/src/ytools/" s ".lisp")
      :output-file
      (concatenate 'string "~/CVSified/dev/clocc/bin/acl62/ytools/" s ".fasl"))
  (cond ((not no-lo) (lo s))))

(defun lo (s)
   (load (concatenate 'string "~/CVSified/dev/clocc/bin/acl62/ytools/"
		      s ".fasl")))
