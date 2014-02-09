;;;;
;;;; Miscellaneous functions & macros that are used in the cl-plot API
;;;;
;;;; hazen 02/14
;;;;

(in-package #:cl-plplot-system)


(defun pl-length (array-or-null)
  "Deals with legacy code where the user might have used 'null instead of nil."
  (if (symbolp array-or-null)
      0
      (length array-or-null)))

;;;
;;; These are for dealing with pltr-data structures, which are passed to
;;; various coordinate transformation functions (i.e. pltr0, pltr1 & pltr2).
;;;

(defcstruct pltr-data
  (x :pointer)
  (y :pointer)
  (z :pointer)
  (nx plint)
  (ny plint)
  (nz plint))

(defclass pl-pltr-data ()
  ((c-pointer
    :accessor c-pointer)
   (gridx
    :initarg :gridx
    :accessor gridx)
   (gridy
    :initarg :gridy
    :accessor gridy)))

(defun make-pl-pltr-data (gridx gridy &key pltr-fn z-vals)
  (flet ((ndims (x)
	   (length (array-dimensions x))))
    ; check that the grid arguments match the callback functions.
    (when pltr-fn
      (cond
	((equal pltr-fn 'pltr1-callback)
	 (when (or (not (vectorp gridx))
		   (not (vectorp gridy)))
	   (format t "Aborting: expected vectors for gridx and gridy when using pltr1-callback.~%")
	   (return-from make-pl-pltr-data)))
	((equal pltr-fn 'pltr2-callback)
	 (when (or (not (arrayp gridx))
		   (not (arrayp gridy))
		   (not (= (ndims gridx) 2))
		   (not (= (ndims gridy) 2)))
	   (format t "Aborting: expected 2D arrays for gridx and gridy when using pltr2-callback.~%")
	   (return-from make-pl-pltr-data)))))
    ; check that the grid arguments are the right size.
    (when z-vals
      (if (= (ndims gridx) 1)
	  (progn
	    (when (< (length gridx) (array-dimension z-vals 0))
	      (format t "Aborting: gridx is not the expected size.~%")
	      (return-from make-pl-pltr-data))
	    (when (< (length gridy) (array-dimension z-vals 1))
	      (format t "Aborting: gridy is not the expected size.~%")
	      (return-from make-pl-pltr-data)))
	  (progn
	    (when (or (< (array-dimension gridx 0) (array-dimension z-vals 0))
		      (< (array-dimension gridx 1) (array-dimension z-vals 1)))
	      (format t "Aborting: gridx is not the expected size.~%")
	      (return-from make-pl-pltr-data))
	    (when (or (< (array-dimension gridy 0) (array-dimension z-vals 0))
		      (< (array-dimension gridy 1) (array-dimension z-vals 1)))
	      (format t "Aborting: gridy is not the expected size.~%")
	      (return-from make-pl-pltr-data)))))
    (let ((instance
	   (if (= (ndims gridx) 1)
	       (make-instance 'pl-pltr-data
			      :gridx (make-*plflt gridx)
			      :gridy (make-*plflt gridy))
	       (make-instance 'pl-pltr-data
			      :gridx (make-**plflt gridx)
			      :gridy (make-**plflt gridy))))
	  (ptr (foreign-alloc '(:struct pltr-data))))
      (with-foreign-slots ((x y nx ny) ptr (:struct pltr-data))
	(setf x (c-pointer (gridx instance)))
	(setf y (c-pointer (gridy instance)))
	(setf nx (if gridx
		     (if (= (ndims gridx) 1)
			 (length gridx)
			 (array-dimension gridx 0))
		     0))
	(setf ny (if gridy
		     (if (= (ndims gridy) 1)
			 (length gridy)
			 (array-dimension gridy 1)))))
      (setf (c-pointer instance) ptr)
      instance)))
	    
(defmacro with-pltr-data ((the-pltr-data gridx gridy &key pltr-fn z-vals) &body body)
  (let ((instance (gensym)))
    `(let ((,instance (make-pl-pltr-data ,gridx ,gridy :pltr-fn ,pltr-fn :z-vals ,z-vals)))
       (when ,instance
	 (let ((,the-pltr-data (c-pointer ,instance)))
	   ,@body
	   (pl-foreign-free (gridx ,instance))
	   (pl-foreign-free (gridy ,instance))
	   (foreign-free (c-pointer ,instance)))))))
  
(export 'with-pltr-data)


;;;
;;; Creates an additional callback version of a function in the PLplot library.
;;; The name of the callback function is the function name with -callback appended,
;;; i.e. my-fn -> my-fn-callback.
;;;

(defmacro pl-callback (name returns docstring &body args)
  (let ((arg-list (mapcar #'(lambda (x) (car x)) args))
	(function-name (cadr name))
	(callback-name (read-from-string (concatenate 'string (string (cadr name)) "-callback"))))
    `(progn
       (pl-defcfun ,name ,returns ,docstring ,@args)
       (defcallback ,callback-name ,returns ,args
	 (,function-name ,@arg-list))
       (export (quote ,callback-name)))))


;;;
;;; Some plplot functions need a pointer even if they aren't going to do anything with it. This 
;;; function wraps CFFI's null-pointer so that user doesn't have to load CFFI just to pass a 
;;; null pointer
;;;

(defun pl-null-pointer ()
  (null-pointer))

(export 'pl-null-pointer)


;;;
;;; These are the structures for interfacing with the plf... functions
;;; in PLplot. There are also some macros to make things a little easier.
;;;

(defcstruct plfgrid2
  (f :pointer)
  (nx plint)
  (ny plint))

(defun lisp-data-to-foreign (lisp-data)
  (if (= (length (array-dimensions lisp-data)) 2)
      (make-**plflt lisp-data)
      (make-*plflt lisp-data)))

(defun create-grid (c-data size-x size-y)
  (let ((ptr (foreign-alloc '(:struct plfgrid2))))
    (with-foreign-slots ((f nx ny) ptr (:struct plfgrid2))
      (setf f c-data)
      (setf nx size-x)
      (setf ny size-y))
    ptr))
  
(export 'create-grid)

(defmacro with-foreign-grid ((lisp-data grid size-x size-y) &body body)
  (let ((c-data (gensym)))
    `(let* ((,c-data (lisp-data-to-foreign ,lisp-data))
	    (,grid (create-grid (c-pointer ,c-data) ,size-x ,size-y)))
       (unwind-protect
	    ,@body
	 (progn
	   (pl-foreign-free ,c-data)
	   (foreign-free ,grid))))))

(export 'with-foreign-grid)

(defmacro with-foreign-matrix ((lisp-matrix foreign-matrix) &body body)
  (let ((c-data (gensym)))
    `(let* ((,c-data (make-**plflt ,lisp-matrix))
	    (,foreign-matrix (c-pointer ,c-data)))
       (unwind-protect
	    ,@body
	 (pl-foreign-free ,c-data)))))

(export 'with-foreign-matrix)


;;;;
;;;; Copyright (c) 2014 Hazen P. Babcock
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
