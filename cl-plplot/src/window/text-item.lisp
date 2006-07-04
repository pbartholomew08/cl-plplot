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
;;;; Functions that are most closely related to the text-item class.
;;;;
;;;; hazen 6/06
;;;;


(in-package #:cl-plplot)

(new-object-defun text-item (the-text &key (text-color *foreground-color*) (text-justification 0.5) (font-size *font-size*))
  "new-text-item, Creates and returns a new text item.
    text is a string specifying the text.
    text-color is a symbol or RGB triple specifying the text color.
    text-justification specifies how to center the string relative to its reference
       point. 0.0 - 1.0, where 0.5 means the string is centered.
    font-size sets the fontsize relative to the default font size.")

(def-edit-method text-item (the-text text-color text-justification font-size)
  "edit-text-item, Edits a text-item object.
    Set the text with :text.
    Set the color of the text with :text-color (symbol or RGB triple).
    Set the justification with :text-justification (0.0 = left justified, 1.0 = right justified).
    Set the font-size with :font-size (relative to the default size).")

(defmacro create-esc-function (function-name esc-string-start &optional esc-string-end)
  "creates functions that handle escaping strings for plplot."
  `(defun ,function-name (&rest strings)
     (let ((new-string ,esc-string-start))
       (dolist (string strings)
	 (setf new-string (concatenate 'string new-string string))
	 ,(unless esc-string-end `(setf new-string (concatenate 'string new-string ,esc-string-start))))
       ,(when esc-string-end `(setf new-string (concatenate 'string new-string ,esc-string-end)))
       new-string)))

; these functions follow page 33 in the plplot manual.

(create-esc-function superscript "#u" "#d")

(create-esc-function subscript "#d" "#u")

(defun backspace () "#b")

(defun number-symbol () "##")

(create-esc-function overline "#+" "#+")

(create-esc-function underline "#-" "#-")

(defun greek-char (roman-character)
  (concatenate 'string "#g" (string roman-character)))

(create-esc-function normal-font "#fn")

(create-esc-function roman-font "#fr")

(create-esc-function italic-font "#fi")

(create-esc-function script-font "#fs")

(create-esc-function hershey-char "#(" ")")

(create-esc-function unicode-char "#[" "]")

(defgeneric render-text (text-item))

(defmethod render-text ((a-text-item text-item))
  "Sets the current color and font size to those specified by the
   text item. Returns a string contained in the text item."
  (set-foreground-color (text-color a-text-item))
  (plschr 0 (font-size a-text-item))
  (the-text a-text-item))
