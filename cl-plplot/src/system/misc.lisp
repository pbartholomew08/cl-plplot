;;;;
;;;; Copyright (c) 2006 Hazen P. Babcock
;;;;
;;;; Permission is hereby granted, free of charge, to any person obtaining a copy 
;;;; of this software and associated documentation files (the "Software"), to 
;;;; deal in the Software without restriction, including without limitation the 
;;;; rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
;;;; sell copies of the Software, and to permit persons to whom the Software is 
;;;; furnished to do so, subject to the following conditions:
;;;;
;;;; The above copyright notice and this permission notice shall be included in 
;;;; all copies or substantial portions of the Software.
;;;;
;;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
;;;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
;;;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
;;;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
;;;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
;;;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
;;;; IN THE SOFTWARE.
;;;;
;;;;
;;;; Miscellaneous functions & macros that are used in the cl-plot API
;;;;
;;;; hazen 3/06
;;;;

(in-package #:cl-plplot-system)


;;;
;;; These are for dealing with passing in the plcgrid structure, which is then passed 
;;; to various coordinate transformation functions (i.e. pltr0, pltr1 & pltr2).
;;;

(defcstruct plcgrid
  (x plpointer)
  (y plpointer)
  (z plpointer)
  (nx plint)
  (ny plint)
  (nz plint))

(defun check-size (a mx my)
  "checks that p-d has the right dimensions"
  (and (= (array-dimension a 0) mx)
       (= (array-dimension a 0) my)))

(defun init-plcgrid (pdx pdy mx my)
  "initializes plcgrid given user supplied pdx & pdy, if necessary"
  (cond 
    ((equal (pl-get-pltr-fn) #'pltr0)
     (null-pointer))
    ((equal (pl-get-pltr-fn) #'pltr1)
     (if (and (vectorp pdx)
	      (vectorp pdy)
	      (= (length pdx) mx)
	      (= (length pdy) my))
	 (let ((tmp (foreign-alloc 'plcgrid)))
	   (with-foreign-slots ((x y nx ny) tmp plcgrid)
	     (setf x (make-ptr pdx 'plflt #'(lambda(x) (coerce x 'double-float))))
	     (setf y (make-ptr pdy 'plflt #'(lambda(x) (coerce x 'double-float))))
	     (setf nx (length pdx))
	     (setf ny (length pdy)))
	   tmp)
	 (format t "Array dimensions are wrong for pdx or pdy in init-plcgrid~%")))
    ((equal (pl-get-pltr-fn) #'pltr2)
     (if (and (arrayp pdx)
	      (arrayp pdy)
	      (check-size pdx mx my)
	      (check-size pdy mx my))
	 (let ((tmp (foreign-alloc 'plcgrid)))
	   (with-foreign-slots ((x y nx ny) tmp plcgrid)
	     (setf x (make-matrix pdx))
	     (setf y (make-matrix pdy))
	     (setf nx (array-dimension pdx 0))
	     (setf ny (array-dimension pdy 0)))
	   tmp)
	 (format t "Matrix dimensions are wrong for pdx or pdy in init-plcgrid~%")))
    (t pdx)))  ; if the user has set the ptr-fn to something else we just pass this through
               ; on the assumption that they know what they are doing

(defun free-plcgrid (p-grid)
  "frees the plcgrid structure, if necessary"
  (cond
    ((equal (pl-get-pltr-fn) #'pltr0)
     (foreign-free p-grid))
    ((equal (pl-get-pltr-fn) #'pltr1)
     (progn
       (with-foreign-slots ((x y) p-grid plcgrid)
	 (foreign-free x)
	 (foreign-free y))
       (foreign-free p-grid)))
    ((equal (pl-get-pltr-fn) #'pltr2)
     (progn
       (with-foreign-slots ((x y nx ny) p-grid plcgrid)
	 (let ((dims (list nx ny)))
	   (free-matrix x dims)
	   (free-matrix y dims)))
       (foreign-free p-grid)))))

(defmacro with-plcgrid ((pdx pdy mx my) &body body)
  `(let ((plcgrid (init-plcgrid ,pdx ,pdy ,mx ,my)))
     (when plcgrid
       ,@body
       (free-plcgrid plcgrid))))


;;;
;;; Some plplot functions require callbacks. These callbacks are inside closures so that user 
;;; can more easily provide their own callback functions. This macro is for making the closures.
;;;

(defmacro callback-closure (fname default returns &rest variables)
  "Encloses a callback function in a closure so that the 
   user can substitute the function of their own choosing"
  (let ((var-name (name-cat "my-" fname)))
    `(let ((,var-name ,default))
       (defcallback ,fname ,returns ,variables
	 (funcall ,var-name ,@(mapcar #'(lambda(x) (car x)) variables)))
       (defun ,(name-cat "pl-set-" fname) (new-fn)
	 (setf ,var-name new-fn))
       (defun ,(name-cat "pl-reset-" fname) ()
	 (setf ,var-name ,default))
       (defun ,(name-cat "pl-get-" fname) ()
	 ,var-name)
       (export ',(name-cat "pl-set-" fname) (package-name *package*))
       (export ',(name-cat "pl-reset-" fname) (package-name *package*))
       (export ',(name-cat "pl-get-" fname) (package-name *package*)))))


;;;
;;; Some plplot functions need a pointer even if they aren't going to do anything with it. This 
;;; function wraps CFFI's null-pointer so that user doesn't have to load CFFI just to pass a 
;;; null pointer
;;;

(defun pl-null-pointer ()
  (null-pointer))

(export 'pl-null-pointer (package-name *package*))

;;;
;;; These are the structures for interfacing with the plf... functions
;;; in PLplot. There are also some macros to make things a little
;;; easier.
;;;

(defcstruct plfgrid
  (f :pointer)
  (nx :int)
  (ny :int))

(defcstruct plfgrid2
  (f :pointer)
  (nx :int)
  (ny :int))

(defun create-grid (c-matrix x-points y-points)
  (let ((ptr (foreign-alloc 'plfgrid2)))
    (setf (foreign-slot-value ptr 'plfgrid2 'f) c-matrix
	  (foreign-slot-value ptr 'plfgrid2 'nx) x-points
	  (foreign-slot-value ptr 'plfgrid2 'ny) y-points)
    ptr))
  
(export 'create-grid (package-name *package*))

(defmacro with-grid ((grid lisp-matrix) &body body)
  (let ((c-matrix (gensym)))
    `(let* ((,c-matrix (make-matrix ,lisp-matrix))
	    (,grid (create-grid ,c-matrix
				(array-dimension ,lisp-matrix 0)
				(array-dimension ,lisp-matrix 1))))
       (unwind-protect
	    ,@body
	 (progn
	   (foreign-free ,c-matrix)
	   (foreign-free ,grid))))))

(export 'with-grid (package-name *package*))

(defmacro with-foreign-matrix ((lisp-matrix foreign-matrix) &body body)
  `(let ((,foreign-matrix (make-matrix ,lisp-matrix)))
     (unwind-protect
	  ,@body
       (free-matrix ,foreign-matrix (list (array-dimension ,lisp-matrix 0)
					  (array-dimension ,lisp-matrix 1))))))

(export 'with-foreign-matrix (package-name *package*))
