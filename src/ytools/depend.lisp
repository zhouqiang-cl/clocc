;-*- Mode: Common-lisp; Package: ytools; Readtable: ytools; -*-
(in-package :ytools)
;;;$Id: depend.lisp,v 1.7.2.12 2005/02/06 05:46:32 airfoyle Exp $

;;; Copyright (C) 1976-2005 
;;;     Drew McDermott and Yale University.  All rights reserved
;;; This software is released under the terms of the Modified BSD
;;; License.  See file COPYING for details.

(eval-when (:compile-toplevel :load-toplevel)
   (export '(depends-on module funktion)))

(eval-when (:compile-toplevel :load-toplevel)

(defstruct (Scan-depends-on-state (:conc-name Sds-))
   file-chunk  ; or the symbol *, meaning the whose basis is being found
   sub-file-types)
;; -- A list of sub-file types L such that all supportive children found
;; after this will be slurped with respect to every element of L.

;;;;   slurp-trawlers
;;;; -- trawlers are objects (functions?) that interact with file
;;;; dependencies to produce slurp tasks for files this one depends on

;;; State for task is a file chunk, whose basis (and callees)
;;; we are computing.
(def-slurp-task scan-depends-on
   :default (\\ (_ _) true)
;;; -- The idea is that anything we didn't anticipate takes us
;;; out of the header.
   :file->state-fcn     ;;;; #'place-file-chunk
		    (\\ (pn)
		       (make-Scan-depends-on-state
			  :file-chunk (place-File-chunk pn)
			  :sub-file-types (list macros-sub-file-type*)
;;;;			  :slurp-trawlers !())
		        )))
 )
   
(setq hidden-slurp-tasks* (adjoin 'scan-depends-on hidden-slurp-tasks*))

(defclass Loadable-file-chunk-from-scan (Loadable-chunk) ())

(defmethod derive ((fb Loadable-file-chunk-from-scan))
   (cond ((= (Chunk-date fb) file-op-count*)
	  false)
	 (t
	  (let* ((loaded-ch (Loadable-chunk-controllee fb))
		 (file-ch (Loaded-chunk-loadee loaded-ch))
;;;;		 (comp-ch (place-compiled-chunk file-ch))
		 )
	     (setf (File-chunk-callees file-ch) !())
;;;;	     (setf (File-chunk-self-compile-dep file-ch)
;;;;		   false)
	     (file-slurp (File-chunk-pathname file-ch)
			 (list scan-depends-on*)
			 (\\ (srm)
			    (let ((readtab
				     (modeline-extract-readtab srm)))
			       (cond (readtab
				      (setf (File-chunk-readtable
					       file-ch)
					    readtab))))))
	     file-op-count*))))

;;; 'srm' is stream of freshly opened file.  Try to get readtable name
;;; from first line, returning false if it can't be found.
(defun modeline-extract-readtab (srm)
   (let ((c (peek-char false srm false eof*)))
      (cond ((and (not (eq c eof*))
		  (char= #\;))
	     ;; Got comment.  Try to parse as
	     ;; mode line with readtable spec
	     (string-extract-readtab (read-line srm)))
	    (t false))))

(defun string-extract-readtab (str)
   (let ((rpos (search "Readtable: " str))
	 (strlen (length str)))
      (cond (rpos
	     (let ((pos (+ rpos (length "Readtable: "))))
		(loop (cond ((and (< pos strlen)
				  (is-whitespace (elt str pos)))
			     (setq pos (+ pos 1)))
			    (t (return))))
		(cond ((< pos strlen)
		       (let ((end (position #\; str :start pos)))
			  (cond (end
				 ;; Finally!  A readtable name
				 (let* ((readtab-name
					     (intern (subseq str pos end)
						     keyword-package*))
					(readtab (named-readtable
						     readtab-name)))
				    (or readtab
					(progn
					   (format *error-output*
					      "Undefined readtable ~s~%"
					      readtab-name)
					   false))))
				(t
				 (format *error-output*
				    !"Can't find end of readtable name in ~
                                      mode line~
                                      ~%   \"...~a\"~%"
				    (subseq str rpos))))))
		      (t
		       (format *error-output*
			  "Can't find readtable name in mode line ~
                           ~%   \"...~a\"~%"
			  (subseq str rpos))))))
	    (t false))))

(defmethod create-loaded-controller ((file-ch File-chunk)
				     (loaded-ch Loaded-file-chunk))
   (chunk-with-name
       `(:loadable ,(Chunk-name file-ch))
       (\\ (name)
	  (make-instance 'Loadable-file-chunk-from-scan
	     :name name
	     :controllee loaded-ch))))

(defvar depends-on-enabled* true)

(defun cl-user::depends-on-disable () (setq depends-on-enabled* false))

;;; Syntax (depends-on <filegroup>*)
;;; where <filegroup> is [<times>] --floadable-filespecs--
;;; <times> is (:at <time>*)
;;; where each <time> is either :run-time, :compile-time, :slurp-time
;;; (:at :run-time) may be abbreviated :at-run-time; similarly for 
;;; :at-compile-time and :at-slurp-time
;;; (:at :run-time :compile-time :slurp-time) may be abbreviated
;;; :always.
;;; Let C be the file containing the 'depends-on' form, F be a file
;;; mentioned in the 'depends-on'.
;;; 
;;; Note that :read-time (= :slurp-time) means that F will be loaded as soon
;;; as the 'depends-on' form is seen.  :run-time means that F will be
;;; loaded when C or its compiled form is loaded.
;;; :compile-time means that F will be loaded when C is compiled.

(defmacro depends-on (&rest stuff)
   (let ((dgroups (depends-on-args-group stuff)))
      (let ((read-time-deps
	       (mapcan (\\ (g)
			  (cond ((memq ':read-time (first g))
				 (list-copy (rest g)))
				(t !())))
		       dgroups))
	    (run-time-deps
	       (mapcan (\\ (g)
			  (cond ((memq ':run-time (first g))
				 (list-copy (rest g)))
				(t !())))
		       dgroups)))
	 `(progn
	      ,@(include-if (not (null read-time-deps))
		   `(eval-when (:compile-toplevel :execute)
		       (cond (depends-on-enabled*
			      (fload ,@read-time-deps)))))
	      ,@(include-if (not (null run-time-deps))
		   `(eval-when (:load-toplevel :execute)
		       (cond (depends-on-enabled*
			      (fload ,@run-time-deps)))))))))

(defvar end-header-dbg* false)

(datafun scan-depends-on in-readtable
   (defun :^ (form sdo-state)
      (let* ((readtab (name->readtable (cadr form)))
	     (file-ch (Sds-file-chunk sdo-state))
	     (prev-readtab (File-chunk-readtable file-ch)))
	 (cond ((not (eq readtab prev-readtab))
		(format *error-output*
		   "Changing readtable of ~s from ~s to ~s = ~s~%"
		   file-ch prev-readtab (cadr form) readtab)
		(setf (File-chunk-readtable file-ch)
		      readtab)))
	 ;; for the duration of the slurp --
	 (setq *readtable* readtab)
	 false)))

(datafun scan-depends-on in-package
   (defun :^ (e _)
      (let ((pkg (find-package (cadr e))))
	 (cond (pkg
		(setq *package* pkg))
	       (t
		(format *error-output*
		   "Ignoring declaration ~s -- undefined package"
		   e)))
	 false)))

(datafun scan-depends-on depends-on
  (defun :^ (e sdo-state)
     (cond (depends-on-enabled*
	    (let* ((file-ch (Sds-file-chunk sdo-state))
		   (groups (depends-on-args-group (cdr e)))
		   (compiled-ch (place-compiled-chunk file-ch))
		   (loaded-file-ch (place-Loaded-chunk file-ch false))
		   )
	       (labels ()
		  (dolist (g groups)
		     (let* ((pnl (filespecs->ytools-pathnames (cdr g))))
			(cond ((memq ':compile-time (first g))
			       (pathnames-note-compile-support
				  pnl compiled-ch)))
			(cond ((memq ':run-time (first g))
			       (pathnames-note-run-support
				  pnl file-ch
				  loaded-file-ch)
			       (pathnames-note-sub-file-deps
				  pnl compiled-ch
				  (Sds-sub-file-types sdo-state))))
			(cond ((or (memq ':read-time (first g))
				   (memq ':slurp-time (first g)))
			       (setf (File-chunk-read-basis file-ch)
				     (union (mapcar #'pathname-denotation-chunk
						    pnl)
					    (File-chunk-read-basis
						file-ch)))))
			(dolist (pn pnl)
			   (let* ((pchunk (pathname-denotation-chunk pn))
				  (lpchunk (place-Loaded-chunk pchunk false)))
			      (monitor-filoid-basis lpchunk)
			      (loaded-chunk-set-basis lpchunk)))))))))
    false))

;;; Return a list of groups, each of the form
;;; ((<time>*)
;;;  --filespecs--)
;;; where each <time> is either :run-time, :compile-time, :read-time
(defun depends-on-args-group (args)
   (cond ((and (= (len args) 1)
	       (is-Symbol (car args)))
	  ;;; Compatibility with old Nisp
	  (list `((:run-time :compile-time) %module/ ,(car args))))
	 (t
	  (let ((this-mode '(:run-time :compile-time :read-time :slurp-time))
		(this-group '())
		(groups '()))
	     (labels ((end-group ()
			 (cond ((not (null this-group))
				(setq groups
				      (cons (cons this-mode
						  (reverse this-group))
					    groups))))))
		(dolist (arg args)
		   (let ((next-mode
			    (cond ((memq arg '(:at-run-time at-run-time
					       :at-compile-time at-compile-time
					       :at-read-time :at-slurp-time
					       :always :at-run-and-compile-time))
				   (case arg
				      ((:at-run-time at-run-time)
				       '(:run-time))
				      ((:at-compile-time at-compile-time)
				       '(:compile-time))
				      ((:at-read-time :at-slurp-time)
				       '(:read-time))
				      (t
				       '(:compile-time :run-time :read-time))))
				  ((car-eq arg ':at)
				   (cond ((null (cdr arg))
					  (cerror !"The next block ~
                                                    will be ignored"
						  "depends-on with (:at): ~s"
						  `(depends-on ,@args))))
				   (cdr arg))
				  (t ':no-next-group))))
		      (cond ((eq next-mode ':no-next-group)
			     (setq this-group (cons arg this-group)))
			    (t
			     (end-group)
			     (setq this-mode next-mode)
			     (setq this-group '())))))
	     (end-group)
	     (reverse groups))))))

(defun pathnames-note-compile-support (pnl compiled-ch)
   (dolist (pn pnl)
      (multiple-value-bind (bl ubl)
			   (pathname-compile-support pn)
	 (setf (Chunk-basis compiled-ch)
	       (union bl (Chunk-basis compiled-ch)))
	 (setf (Chunk-update-basis compiled-ch)
	       (union ubl (Chunk-update-basis compiled-ch))))))

(defun pathnames-note-run-support (pnl filoid-ch loaded-filoid-ch)
   (dolist (pn pnl)
      (multiple-value-bind (bl lbl)
			   (pathname-run-support pn)
	 (cond (filoid-ch
		(let ((fbl (retain-if (\\ (b) (typep b 'File-chunk))
				      bl)))
		   (setf (File-chunk-callees filoid-ch)
			 (union fbl
				(File-chunk-callees filoid-ch))))))
	 (loaded-chunk-augment-basis loaded-filoid-ch lbl))))

(defun pathnames-note-sub-file-deps (pnl compiled-ch sub-file-types)
   (dolist (pn pnl)
      (multiple-value-bind (bl lbl)
			   (pathname-run-support pn)
			   (declare (ignore lbl))
	 (dolist (callee-ch bl)
	    (cond ((typep callee-ch 'File-chunk)
		   (dolist (sfty sub-file-types)
		      (compiled-ch-sub-file-link
			 compiled-ch callee-ch sfty true))))))))

;;; Returns two lists of chunks that should be part of the 
;;; basis and update-basis [respectively] for (:compiled ...).
(defgeneric pathname-compile-support (xpn))

;;; Analogously, returns two lists of chunks that should be part of the 
;;; basis for the filoid denoted by xpn, and of the basis for
;;; (:loaded <filoid>).	   
(defgeneric pathname-run-support (xpn))

(defmethod pathname-compile-support ((ytp YTools-pathname))
   (pathname-compile-support (pathname-resolve ytp false)))

(defmethod pathname-run-support  ((ytp YTools-pathname))
   (pathname-run-support (pathname-resolve ytp false)))

;;; For files, you get the same two lists for compile-support as
;;; for run-support, although with slightly different meanings.--
(defmethod pathname-compile-support ((pn pathname))
   (pathname-run-support pn))

(defmethod pathname-run-support ((pn pathname))
   (let ((file-ch (pathname-denotation-chunk pn)))
      (values (list file-ch)
	      (list (place-Loaded-chunk file-ch false)))))

(defmacro self-compile-dep (&rest sorts)
   `'("self-dependency for compilation " ',sorts))

(datafun scan-depends-on self-compile-dep
   (defun :^ (e sdo-state)
      (let* ((file-ch (Sds-file-chunk sdo-state))
	     (compiled-ch (place-compiled-chunk file-ch)))
	 (cond ((eq (cadr e) ':load-source)
		(pushnew (place-Loaded-source-chunk file-ch)
			 (Chunk-update-basis compiled-ch)))
	       (t
		(dolist (sub-file-type-name (cdr e))
		   (let ((sftype (lookup-sub-file-type sub-file-type-name)))
		      (compiled-ch-sub-file-link
		         compiled-ch file-ch sftype false))))))
     false))

(datafun scan-depends-on end-header
   (defun :^ (form sdo-state) 
      (cond ((memq ':no-compile (cdr form))
	     (place-Loaded-chunk (Sds-file-chunk sdo-state)
				 ':source)))
      (cond (end-header-dbg*
	     (format *error-output*
		     "Executing ~s~% "
		     form)))
      (cond ((memq ':continue-slurping (cdr form))
	     (self-compile-dep-scan-depends-on form sdo-state)
;;;;	     (format *error-output*
;;;;		!"Warning -- ':continue-slurping' encountered in file ~
;;;;                  ~s; this declaration is~
;;;;                  ~%  no longer needed~%"
;;;;		(Sds-file-chunk sdo-state))
	     ))
      true))

(def-excl-dispatch #\' (srm _)
   (list 'funktion (read srm true nil true)))

;;;;  (let ((f (read srm)))
;;;;     (cond ((atom f) (list 'funktion f))
;;;;	   (t f))))

(defmacro funktion (f)
   (cond ((and (atom f) (> debuggability* 0))
	  `',f)
	 (t `#',f)))