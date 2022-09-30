;;; sysfs.el --- control sysfs from Emacs  -*- lexical-binding:t -*-

;; Author: Will Dey
;; Maintainer: Will Dey
;; Version: 1
;; Package-Requires: ()
;; Keywords: hardware

;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; commentary

;;; Code:

(defgroup sysfs ()
  "Control Linux sysfs(5) from Emacs."
  :group 'hardware)

(defun sysfs--read (filename)
  (with-temp-buffer
    (insert-file-contents-literally filename)
    (buffer-string)))

;;;###autoload
(defun sysfs-sleep ()
  (interactive)
  (write-region "mem" nil "/sys/power/state" nil :no-message)
  (message "Going to sleep..."))

(defcustom sysfs-backlight nil
  "Device under /sys/class/backlight/ to use for brightness control.

If nil on first access, it is set to the first device found alphabetically.")

(defun sysfs--get-backlight ()
  (interactive)
  (or sysfs-backlight
      (setq sysfs-backlight (car (directory-files
				  "/sys/class/backlight/"
				  nil
				  directory-files-no-dot-files-regexp)))))

(defun sysfs--read-backlight (parameter)
  (string-to-number
   (sysfs--read
    (file-name-concat "/sys/class/backlight/"
		      (sysfs--get-backlight)
		      parameter))))

(defcustom sysfs-brightness-message-format "%.0f%% brightness"
  "Format of the message to echo when getting or setting the screen brightness.")

;;;###autoload
(defun sysfs-brightness-get ()
  (interactive)
  (let ((brightness (* 100 (/ (float (sysfs--read-backlight "brightness"))
			      (sysfs--read-backlight "max_brightness")))))
    (when (called-interactively-p 'interactive)
      (message sysfs-brightness-message-format brightness))
    brightness))

;;;###autoload
(defun sysfs-brightness-set (percent)
  (interactive "nBrightness: ")
  (let ((clamped (max 1 (min 100 percent))))
    (write-region (number-to-string (floor (* clamped 0.01 (sysfs--read-backlight "max_brightness"))))
		  nil
		  (file-name-concat "/sys/class/backlight/"
				    (sysfs--get-backlight)
				    "brightness")
		  nil
		  :no-message)
    (message sysfs-brightness-message-format clamped)))

(defcustom sysfs-brightness-increment 5
  "Amount that `sysfs-brightness-up' and `sysfs-brightness-down' change brightness by.")

;;;###autoload
(defun sysfs-brightness-up (&optional multiplier)
  (interactive "p")
  (sysfs-brightness-set (+ (sysfs-brightness-get)
			   (* sysfs-brightness-increment multiplier))))

;;;###autoload
(defun sysfs-brightness-down (&optional multiplier)
  (interactive "p")
  (sysfs-brightness-up (- multiplier)))

;;; sysfs.el ends here
