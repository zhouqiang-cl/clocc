;;; 6.1.1.7 -*- mode: lisp -*-
(in-package :cl-user)

(proclaim '(special log))

;; Collect values by using FOR constructs.
(my-assert
 (loop for numlist in '((1 2 4.0) (5 6 8.3) (8 9 10.4))
   for a of-type integer = (first numlist)
   and b of-type integer = (second numlist)
   and c of-type float = (third numlist)
   collect (list c b a))
 ((4.0 2 1) (8.3 6 5) (10.4 9 8)))



;; Destructuring simplifies the process.
(my-assert
 (loop for (a b c) of-type (integer integer float) in
   '((1 2 4.0) (5 6 8.3) (8 9 10.4))
   collect (list c b a))
 ((4.0 2 1) (8.3 6 5) (10.4 9 8)))


;; If all the types are the same, this way is even simpler.
(my-assert
 (loop for (a b c) of-type float in
   '((1.0 2.0 4.0) (5.0 6.0 8.3) (8.0 9.0 10.4))
   collect (list c b a))
 ((4.0 2.0 1.0) (8.3 6.0 5.0) (10.4 9.0 8.0)))

;; Initialize and declare variables in parallel by using the AND construct.

(my-assert
 (loop for (a nil b) = '(1 2 3)
   do (return (list a b)))
 (1 3))

(my-assert
 (loop for (x . y) = '(1 . 2)
   do (return y))
 2)


(my-assert
 (loop for ((a . b) (c . d)) of-type ((float . float) (integer . integer)) in
   '(((1.2 . 2.4) (3 . 4)) ((3.4 . 4.6) (5 . 6)))
   collect (list a b c d))
 ((1.2 2.4 3 4) (3.4 4.6 5 6)))

;;; 6.1.2.1.1


(my-assert
 (let ((xo 1)) (loop for i from xo by (incf xo) to 10 collect i))
 (1 3 5 7 9))


;;; 6.1.2.1.2.1

(my-assert
 (loop for (item . x) of-type (t . fixnum) in '((A . 1) (B . 2) (C . 3))
   unless (eq item 'B) sum x)
 4)

;;; 6.1.2.1.3.1

;; Collect successive tails of a list.
(my-assert
 (loop for sublist on '(a b c d)
   collect sublist)
 ((A B C D) (B C D) (C D) (D)))

;;; 6.1.2.1.4.1

;; Collect some numbers.
(my-assert
 (loop for item = 1 then (+ item 10)
   for iteration from 1 to 5
   collect item)
 (1 11 21 31 41))

;;;; 6.1.2.2

(my-assert
 (loop with a = 1
   with b = (+ a 2)
   with c = (+ b 3)
   return (list a b c))
 (1 3 6))

(my-assert
 (loop with a = 1
   and b = 2
   and c = 3
   return (list a b c))
 (1 2 3))

;;; 6.1.2.2.1

;; These bindings occur in sequence.
(my-assert
 (loop with a = 1
   with b = (+ a 2)
   with c = (+ b 3)
   return (list a b c))
 (1 3 6))

;; These bindings occur in parallel.
(my-assert
 (setq a 5 b 10)
 10)


(my-assert
 (loop with a = 1
   and b = (+ a 2)
   and c = (+ b 3)
   return (list a b c))
 (1 7 13))

;; This example shows a shorthand way to declare local variables
;; that are of different types.
(my-assert
 (loop with (a b c) of-type (float integer float)
   return (format nil "~A ~A ~A" a b c))
 "0.0 0 0.0")

;; This example shows a shorthand way to declare local variables
;; that are the same type.
(my-assert
 (loop with (a b c) of-type float
   return (format nil "~A ~A ~A" a b c))
 "0.0 0.0 0.0")

;;; 6.1.3

;; Collect every name and the kids in one list by using
;; COLLECT and APPEND.
(my-assert
 (loop for name in '(fred sue alice joe june)
   for kids in '((bob ken) () () (kris sunshine) ())
   collect name
   append kids)
 (FRED BOB KEN SUE ALICE JOE KRIS SUNSHINE JUNE))

;;; 6.1.3.1

;; Collect all the symbols in a list.
(my-assert
 (loop for i in '(bird 3 4 turtle (1 . 4) horse cat)
   when (symbolp i) collect i)
 (BIRD TURTLE HORSE CAT))

;; Collect and return odd numbers.
(my-assert
 (loop for i from 1 to 10
   if (oddp i) collect i)
 (1 3 5 7 9))

;; Collect items into local variable, but don't return them.
(my-assert
 (loop for i in '(a b c d) by #'cddr
   collect i into my-list
   finally  my-list) ;;; hmm
 nil )

;;; 6.1.3.2

;; Use APPEND to concatenate some sublists.
(my-assert
 (loop for x in '((a) (b) ((c)))
   append x)
 (A B (C)))

;; NCONC some sublists together.  Note that only lists made by the
;; call to LIST are modified.
(my-assert
 (loop for i upfrom 0
   as x in '(a b (c))
   nconc (if (evenp i) (list x) nil))
 (A (C)))

;;; 6.1.3.3

(my-assert
 (loop for i in '(a b nil c nil d e)
   count i)
 5)

;;; 6.1.3.4

(my-assert
 (loop for i in '(2 1 5 3 4)
   maximize i)
 5)

(my-assert
 (loop for i in '(2 1 5 3 4)
   minimize i)
 1)

;; In this example, FIXNUM applies to the internal variable that holds
;; the maximum value.
(my-assert
 (setq series '(1.2 4.3 5.7))
 (1.2 4.3 5.7))

(my-assert
 (loop for v in series
   maximize (round v) of-type fixnum)
 6)

;; In this example, FIXNUM applies to the variable RESULT.
(my-assert
 (loop for v of-type float in series
   minimize (round v) into result of-type fixnum
   finally (return result))
 1)

;;; 6.1.3.5

(my-assert
 (loop for i of-type fixnum in '(1 2 3 4 5)
   sum i)
 15)

(my-assert
 (setq series '(1.2 4.3 5.7))
 (1.2 4.3 5.7))

(my-assert
 (loop for v in series
   sum (* 2.0 v))
 22.4)

;;; 6.1.4.2

;; Make sure I is always less than 11 (two ways).
;; The FOR construct terminates these loops.
(my-assert
 (loop for i from 0 to 10
   always (< i 11))
 T)

(my-assert
 (loop for i from 0 to 10
   never (> i 11))
 T)

;; If I exceeds 10 return I; otherwise, return NIL.
;; The THEREIS construct terminates this loop.
(my-assert
 (loop for i from 0
   thereis (when (> i 10) i) )
 11)

;;; The FINALLY clause is not evaluated in these examples.
(my-assert
 (loop for i from 0 to 10
   always (< i 9)
   finally (format nil "you won't see this"))
 NIL)

(my-assert
 (loop never t
   finally (format nil "you won't see this"))
 NIL)

(my-assert
 (loop thereis "Here is my value"
   finally (format nil "you won't see this"))
 "Here is my value")

;;; 6.1.4.3

;; Collect the length and the items of STACK.
(my-assert
 (let ((stack '(a b c d e f)))
   (loop for item = (length stack) then (pop stack)
     collect item
     while stack))
 (6 A B C D E F))

;; Use WHILE to terminate a loop that otherwise wouldn't terminate.
;; Note that WHILE occurs after the WHEN.
(my-assert
 (loop for i fixnum from 3
   when (oddp i) collect i
   while (< i 5))
 (3 5))

;;; 6.1.6.1

;; Signal an exceptional condition.
(my-assert
 (loop for item in '(1 2 3 a 4 5)
   when (not (numberp item))
   return (cerror "enter new value" "non-numeric value: ~s" item))
 ERROR)

;; The previous example is equivalent to the following one.
(my-assert
 (loop for item in '(1 2 3 a 4 5)
   when (not (numberp item))
   do (return
       (cerror "Enter new value" "non-numeric value: ~s" item)))
 ERROR)

;; This example parses a simple printed string representation from
;; BUFFER (which is itself a string) and returns the index of the
;; closing double-quote character.
(my-assert
 (let ((buffer "\"a\" \"b\""))
   (loop initially (unless (char= (char buffer 0) #\")
		     (loop-finish))
     for i of-type fixnum from 1 below (length (the string buffer))
     when (char= (char buffer i) #\")
     return i))
 2)

;; The collected value is returned.
(my-assert
 (loop for i from 1 to 10
   when (> i 5)
   collect i
   finally (prin1 'got-here))
 (6 7 8 9 10) )

;; Return both the count of collected numbers and the numbers.

(my-assert
 (multiple-value-bind (a b)
     (loop for i from 1 to 10
       when (> i 5)
       collect i into number-list
       and count i into number-count
       finally (return (values number-count number-list)))
   (list a b))
 (5 (6 7 8 9 10)))

;;; 6.1.7.1.1

;; Just name and return.
(my-assert
 (loop named max
   for i from 1 to 10
   do (print i)
   do (return-from max 'done))
 DONE)



;;; 6.1.8

(my-assert
 (let ((i 0))				; no loop keywords are used
   (loop (incf i) (if (= i 3) (return i))))
 3)

(my-assert
 (let ((i 0)(j 0))
   (tagbody
    (loop (incf j 3) (incf i) (if (= i 3) (go exit)))
    exit)
   j)
 9)

(my-assert
 (loop for x from 1 to 10
   for y = nil then x
   collect (list x y))
 ((1 NIL) (2 2) (3 3) (4 4) (5 5) (6 6) (7 7) (8 8) (9 9) (10 10)))

(my-assert
 (loop for x from 1 to 10
   and y = nil then x
   collect (list x y))
 ((1 NIL) (2 1) (3 2) (4 3) (5 4) (6 5) (7 6) (8 7) (9 8) (10 9)))

;;; 6.1.8.1

;; Group conditional clauses.

(my-assert
 (multiple-value-bind (a b)
     (loop for i in '(1 324 2345 323 2 4 235 252)
       when (oddp i)
       do (print i)
       and collect i into odd-numbers
       and do (terpri)
       else				; I is even.
       collect i into even-numbers
       finally
       (return (values odd-numbers even-numbers)))
   (list a b))
 ((1 2345 323 235) (324 2 4 252)))

;; Collect numbers larger than 3.
(my-assert
 (loop for i in '(1 2 3 4 5 6)
   when (and (> i 3) i)
   collect it)				; IT refers to (and (> i 3) i).
 (4 5 6))

;; Find a number in a list.
(my-assert
 (loop for i in '(1 2 3 4 5 6)
   when (and (> i 3) i)
   return it)
 4)

;; The above example is similar to the following one.
(my-assert
 (loop for i in '(1 2 3 4 5 6)
   thereis (and (> i 3) i))
 4)


;; Nest conditional clauses.
(my-assert
 (multiple-value-bind (a b c)
     (let ((list '(0 3.0 apple 4 5 9.8 orange banana)))
       (loop for i in list
	 when (numberp i)
	 when (floatp i)
	 collect i into float-numbers
	 else				; Not (floatp i)
	 collect i into other-numbers
	 else				; Not (numberp i)
	 when (symbolp i)
	 collect i into symbol-list
	 else				; Not (symbolp i)
	 do (error "found a funny value in list ~S, value ~S~%" list i)
	 finally (return (values float-numbers other-numbers symbol-list))))
   (list a b c))
 ((3.0 9.8) (0 4 5) (APPLE ORANGE BANANA)))

;;; do

(my-assert
 (do ((temp-one 1 (1+ temp-one))
      (temp-two 0 (1- temp-two)))
     ((> (- temp-one temp-two) 5) temp-one))
 4)

(my-assert
 (do ((temp-one 1 (1+ temp-one))
      (temp-two 0 (1+ temp-one)))
     ((= 3 temp-two) temp-one))
 3)

(my-assert
 (do* ((temp-one 1 (1+ temp-one))
       (temp-two 0 (1+ temp-one)))
     ((= 3 temp-two) temp-one))
 2                     )

(my-assert
 (setq a-vector (vector 1 nil 3 nil))
 #(1 nil 3 nil))

(my-assert
 (do ((i 0 (+ i 1))			;Sets every null element of a-vector to zero.
      (n (array-dimension a-vector 0)))
     ((= i n))
   (when (null (aref a-vector i))
     (setf (aref a-vector i) 0)))
 NIL)

(my-assert
 a-vector
 #(1 0 3 0))

;;; dotimes

(my-assert
 (dotimes (temp-one 10 temp-one))
 10)

(my-assert
 (setq temp-two 0)
 0)

(my-assert
 (dotimes (temp-one 10 t) (incf temp-two))
 T)

(my-assert
 temp-two
 10)

;;; True if the specified subsequence of the string is a
;;; palindrome (reads the same forwards and backwards).
(my-assert
 (defun palindromep (string &optional
			    (start 0)
			    (end (length string)))
   (dotimes (k (floor (- end start) 2) t)
     (unless (char-equal (char string (+ start k))
			 (char string (- end k 1)))
       (return nil))))
 PALINDROMEP)

(my-assert
 (palindromep "Able was I ere I saw Elba")
 T)

(my-assert
 (palindromep "A man, a plan, a canal--Panama!")
 NIL)

(my-assert
 (remove-if-not #'alpha-char-p          ;Remove punctuation.
		"A man, a plan, a canal--Panama!")
 "AmanaplanacanalPanama")

(my-assert
 (palindromep
  (remove-if-not #'alpha-char-p
		 "A man, a plan, a canal--Panama!"))
 T)

(my-assert
 (palindromep
  (remove-if-not
   #'alpha-char-p
   "Unremarkable was I ere I saw Elba Kramer, nu?"))
 T)

(my-assert
 (palindromep
  (remove-if-not
   #'alpha-char-p
   "A man, a plan, a cat, a ham, a yak,
                  a yam, a hat, a canal--Panama!"))
 T)


;;; dolist

(my-assert
 (setq temp-two '())
 NIL)

(my-assert
 (dolist (temp-one '(1 2 3 4) temp-two) (push temp-one temp-two))
 (4 3 2 1))

(my-assert
 (setq temp-two 0)
 0)

(my-assert
 (dolist (temp-one '(1 2 3 4)) (incf temp-two))
 NIL)

(my-assert
 temp-two
 4)

;;; loop-finish

;; Terminate the loop, but return the accumulated count.
(my-assert
 (loop for i in '(1 2 3 stop-here 4 5 6)
   when (symbolp i) do (loop-finish)
   count i)
 3)

;; The preceding loop is equivalent to:
(my-assert
 (loop for i in '(1 2 3 stop-here 4 5 6)
   until (symbolp i)
   count i)
 3)

;; While LOOP-FINISH can be used can be used in a variety of
;; situations it is really most needed in a situation where a need
;; to exit is detected at other than the loop's `top level'
;; (where UNTIL or WHEN often work just as well), or where some
;; computation must occur between the point where a need to exit is
;; detected and the point where the exit actually occurs.  For example:
(my-assert
 (defun tokenize-sentence (string)
   (macrolet ((add-word (wvar svar)
			`(when ,wvar
			   (push (coerce (nreverse ,wvar) 'string) ,svar)
			   (setq ,wvar nil))))
     (loop with word = '() and sentence = '() and endpos = nil
       for i below (length string)
       do (let ((char (aref string i)))
	    (case char
	      (#\Space (add-word word sentence))
	      (#\. (setq endpos (1+ i)) (loop-finish))
	      (otherwise (push char word))))
       finally (add-word word sentence)
       (return (values (nreverse sentence) endpos)))))
 TOKENIZE-SENTENCE)

(my-assert
 (multiple-value-bind (a b)
     (tokenize-sentence
      "this is a sentence. this is another sentence.")
   (list a b))
 (("this" "is" "a" "sentence")  19))

(my-assert
 (multiple-value-bind (a b)
     (tokenize-sentence "this is a sentence")
   (list a b))
 (("this" "is" "a" "sentence")  NIL))














