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
;;;; Define the classes that we'll use in cl-plplot
;;;;
;;;; hazen 6/06
;;;;

(in-package #:cl-plplot)

(def-plplot-class text-item ()
  (the-text
   (text-color *foreground-color*)
   (text-justification 0.5)
   (font-size *font-size*)))

(def-plplot-class text-label ()
  (label-text-item
   text-x
   text-y
   text-dx
   text-dy))

(def-plplot-class axis-label ()
  (axis-text-item
   side
   displacement
   (location 0.5)
   (orientation :parallel)))

(def-plplot-class axis ()
  (axis-min
   axis-max
   (major-tick-interval 0)
   (minor-tick-number 0)
   (properties *axis-properties*)
   axis-labels))

(def-plplot-class plot ())

(def-plplot-class x-y-plot (plot)
  (data-x
   data-y
   line-width
   line-style
   symbol-size
   symbol-type
   color
   x-error
   y-error))

(def-plplot-class bar-graph (plot))

(def-plplot-class window ()
  (x-axis
   y-axis
   title
   (window-line-width 1.0)
   (window-font-size *font-size*)
   (foreground-color *foreground-color*)
   (background-color *background-color*)
   (viewport-x-min 0.1)
   (viewport-x-max 0.9)
   (viewport-y-min 0.1)
   (viewport-y-max 0.9)
   plots
   text-labels))

