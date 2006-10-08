;;;;
;;;; Functions that are most closely related to the contour-plot class.
;;;;
;;;; hazen 10/06
;;;;

; :none - straight plcont.
; :block - multiple cycles of plshade w/ defined color map.
; :smooth - plshades w/ 128 contours, then plcont.
;
; color map 1 handling
; contour line text?

(in-package #:cl-plplot)

(defun check-contour-levels (data contour-levels)
  "Creates default contour levels based on data in the event that the contour
   levels have not already been specified."
  (if (and contour-levels
	   (vectorp contour-levels))
      contour-levels
      (progn
	(when contour-levels
	  (format t "Contour-levels must be a vector of contour values."))
	(let ((min (aref data 0 0))
	      (max (aref data 0 0))
	      (default-levels (make-float-vector 10)))
	  (dotimes (i (array-dimension data 0))
	    (dotimes (j (array-dimension data 1))
	      (when (> (aref data i j) max)
		(setf max (aref data i j)))
	      (when (< (aref data i j) min)
		(setf min (aref data i j)))))
	  (let* ((range (- max min))
		 (increment (/ range 8)))
	    (dotimes (i 10)
	      (setf (aref default-levels i) min)
	      (incf min increment)))
	  default-levels))))

(defun check-mapping (data x-mapping y-mapping x-min x-max y-min y-max)
  "If x-mapping and y-mapping are defined, they are checked to make sure they are the right size.
   If they are not defined then default created based on x-min, x-max, y-min & y-max, or the
     dimensions of data in the event that these variables are also not defined."
  (if (and x-mapping y-mapping)
      (cond
	((and (= 1 (array-rank x-mapping))
	      (= 1 (array-rank y-mapping)))
	 (if (and (= (array-dimension data 0) (length x-mapping))
		  (= (array-dimension data 1) (length y-mapping)))
	     (values t x-mapping y-mapping)
	     (progn
	       (format t "x-mapping (~A) & y-mapping (~A) dimensions must match data (~A, ~A).~%"
		       (length x-mapping) (length y-mapping) (array-dimension data 0) (array-dimension data 1))
	       (values nil nil nil))))
	((and (= 2 (array-rank x-mapping))
	      (= 2 (array-rank y-mapping)))
	 (if (and (= (array-dimension data 0) (array-dimension x-mapping 0))
		  (= (array-dimension data 1) (array-dimension x-mapping 1))
		  (= (array-dimension data 0) (array-dimension y-mapping 0))
		  (= (array-dimension data 1) (array-dimension y-mapping 1)))
	     (values t x-mapping y-mapping)
	     (progn
	       (format t "x-mapping (~A, ~A) & y-mapping (~A, ~A) dimensions must match data (~A, ~A).~%"
		       (array-dimension x-mapping 0) (array-dimension x-mapping 1)
		       (array-dimension y-mapping 0) (array-dimension y-mapping 1)
		       (array-dimension data 0) (array-dimension data 1))
	       (values nil nil nil))))
	(t
	 (progn
	   (format t "x-mapping and y-mapping must either both be 1D or both be 2D matrices~%")
	   (values nil nil nil))))
      (progn
	(when (or x-mapping y-mapping)
	  (format t "You must specify both x-mapping & y-mapping~%")
	  (return-from check-mapping (values nil nil nil)))
	(let* ((default-x-mapping (make-float-vector (array-dimension data 0)))
	       (default-y-mapping (make-float-vector (array-dimension data 1)))
	       (checked-x-min (if x-min x-min 0))
	       (checked-x-max (if x-max x-max (1- (array-dimension data 0))))
	       (checked-y-min (if y-min y-min 0))
	       (checked-y-max (if y-max y-max (1- (array-dimension data 1))))
	       (dx (/ (- checked-x-max checked-x-min) (1- (array-dimension data 0))))
	       (dy (/ (- checked-y-max checked-y-min) (1- (array-dimension data 1)))))
	  (dotimes (i (array-dimension data 0))
	    (setf (aref default-x-mapping i) (+ checked-x-min (* i dx))))
	  (dotimes (i (array-dimension data 1))
	    (setf (aref default-y-mapping i) (+ checked-y-min (* i dy))))
	  (values t default-x-mapping default-y-mapping)))))

(defun new-contour-plot (data &key contour-levels (line-color *foreground-color*) (line-width 1) (fill-type :none) 
			 fill-colors x-min x-max x-mapping y-min y-max y-mapping (copy t))
   "Creates a new contour plot.
    data is a 2D array of z values.
    contour-levels is a 1D vector of floats specifying the levels at which the contours
       should appear. If this is nil, then default contours are created based on the
       minimum and maximum values in data.
    line-color is a symbol specifying which color to use in the current color table
       for the contour lines.
    line-width is an integer specifying what size line to use for the contours (or
       zero for no line).
    fill-type is one of :none (contours only), :block (a single color between each contour)
       or :smooth (color varies continously between contours).
    fill-colors is a (optional) vector of colors from the current color table to use when 
       fill-type is :block.
    x-min & y-min specify the location of data(0, 0) in plot coordinates.
    x-max & y-max specify the location of data(max, max) in plot coordinates.
    x-mapping & y-mapping are either 1 1D vectors or 2D matrices specifying how to map points 
       in data into plot coordinates. If they are 1D vector, then data(i,j) is mapped to
       [x-mapping(i), y-mapping(j)]. If they are 2D vectors then data(i,j) is mapped to 
       [x-mapping(i,j), y-mapping(i,j)]. They must be used together and both must be the same
       type & also match the dimensions of data. They will override x-min, y-min, x-max and
       y-max if they are specified."
   (multiple-value-bind (good? checked-x-mapping checked-y-mapping)
       (check-mapping data x-mapping y-mapping x-min x-max y-min y-max)
     (when good?
       (make-instance 'contour-plot
		      :data (copy-matrix data copy)
		      :line-width line-width
		      :line-color line-color
		      :fill-type fill-type
		      :fill-colors fill-colors
		      :contour-levels (check-contour-levels data (copy-vector contour-levels copy))
		      :x-mapping (copy-matrix checked-x-mapping copy)
		      :y-mapping (copy-matrix checked-y-mapping copy)))))

(def-edit-method contour-plot (line-color line-width fill-type contour-labels)
  "edit-contour-plot, Edits the visual properties of a plot
    Set the line color with :line-color (this should be a color symbol in the current color table).
    Set the line width with :line-width (integer, 0 means no line).
    Set the fill-type with :fill-type (:none :block :smooth).
    Set the contour-labels...")

(defmethod plot-min-max ((a-plot contour-plot))
  "Returns the minimum and maximum values in a contour plot as a 4 element vector."
  (if (= 1 (array-rank (x-mapping a-plot)))
      (vector (aref (x-mapping a-plot) 0) (aref (x-mapping a-plot) (1- (length (x-mapping a-plot))))
	      (aref (y-mapping a-plot) 0) (aref (y-mapping a-plot) (1- (length (y-mapping a-plot)))))
      (let ((x-min (aref (x-mapping a-plot) 0 0))
	    (x-max (aref (x-mapping a-plot) 0 0))
	    (y-min (aref (y-mapping a-plot) 0 0))
	    (y-max (aref (y-mapping a-plot) 0 0))
	    (dim-0 (1- (array-dimension (x-mapping a-plot) 0)))
	    (dim-1 (1- (array-dimension (x-mapping a-plot) 1))))
	(dotimes (i (1+ dim-1))
	  (when (< (aref (x-mapping a-plot) 0 i) x-min)
	    (setf x-min (aref (x-mapping a-plot) 0 i)))
	  (when (> (aref (x-mapping a-plot) dim-0 i) x-max)
	    (setf x-max (aref (x-mapping a-plot) dim-0 i))))
	(dotimes (i (1+ dim-0))
	  (when (< (aref (y-mapping a-plot) i 0) y-min)
	    (setf y-min (aref (y-mapping a-plot) i 0)))
	  (when (> (aref (y-mapping a-plot) i dim-1) y-max)
	    (setf y-max (aref (y-mapping a-plot) i dim-1))))
	(vector x-min x-max y-min y-max))))

;; Draw the contour plot

(defun make-smooth-contour-levels (contour-levels)
  "Given the contour levels, makes a version of them with 128 different
   levels, so that shading will hopefully appear smooth."
  ; FIXME: This assumes that the levels are equally spaced.
  (let* ((start (aref contour-levels 0))
	 (end (aref contour-levels (1- (length contour-levels))))
	 (increment (/ (- end start) 127))
	 (smooth-levels (make-float-vector 128)))
    (dotimes (i (length smooth-levels))
      (setf (aref smooth-levels i) (+ start (* increment i))))
    smooth-levels))

(defmethod render-plot ((a-plot contour-plot) &optional ignored)
  "Renders a x-y plot in the current window."
  (declare (ignore ignored))
  ; Set the coordinate mapping callback function appropriately. The value
  ; is saved and reset for the benefit of other functions that might
  ; expect it to be something else.
  (let ((callback-fn (pl-get-pltr-fn)))
    (cond
      ((= 1 (array-rank (x-mapping a-plot)))
       (unless (equal (pl-get-pltr-fn) #'pltr1)
	 (pl-set-pltr-fn #'pltr1)))
      ((= 2 (array-rank (x-mapping a-plot)))
       (unless (equal (pl-get-pltr-fn) #'pltr2)
	 (pl-set-pltr-fn #'pltr2))))
    ; draw the plot
    (cond
      ((equal (fill-type a-plot) :none))
      ((equal (fill-type a-plot) :smooth)
       (plshades (data a-plot) 1 (array-dimension (data a-plot) 0) 1 (array-dimension (data a-plot) 1)
		 (make-smooth-contour-levels (contour-levels a-plot)) 
		 2 1 0 nil (x-mapping a-plot) (y-mapping a-plot)))
      ((equal (fill-type a-plot) :block)
	 (dotimes (i (1- (length (contour-levels a-plot))))
	   (let ((current-color-index (if (fill-colors a-plot)
					  (find-a-color *current-color-table* 
							(aref (fill-colors a-plot) 
							      (mod i (length (fill-colors a-plot)))))
					  (mod i (length (color-map *current-color-table*))))))
	     (plshade (data a-plot) 1 (array-dimension (data a-plot) 0) 1 (array-dimension (data a-plot) 1)
		      (aref (contour-levels a-plot) i) (aref (contour-levels a-plot) (1+ i))
		      0 current-color-index 2 current-color-index 0 current-color-index 0 nil
		      (x-mapping a-plot) (y-mapping a-plot)))))
      (t
       (format t "Sorry I don't know how to draw contour plots of type ~A~%" (fill-type a-plot))))
    (set-foreground-color (line-color a-plot))
    (when (> (line-width a-plot) 0)
      (plwid (line-width a-plot))
      (plcont (data a-plot) 1 (array-dimension (data a-plot) 0) 1 (array-dimension (data a-plot) 1)
	      (contour-levels a-plot) (x-mapping a-plot) (y-mapping a-plot)))
    (pl-set-pltr-fn callback-fn)))


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