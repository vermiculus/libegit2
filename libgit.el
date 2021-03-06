;;; libgit.el --- Thin bindings to libgit2. -*- lexical-binding: t; -*-

;; Copyright (C) 2018 TheBB
;;
;; Author: Eivind Fonn <evfonn@gmail.com>
;; URL: https://github.com/TheBB/libegit2
;; Version: 0.0.1
;; Keywords: git vcs
;; Package-Requires: ((emacs "25.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides thin bindings to libgit2. To use these bindings,
;; issue a call to (require 'libgit). This will load the dynamic module,
;; or prompt the user to build it.

;;; Code:

(unless module-file-suffix
  (error "Module support not detected, libgit can't work"))

(defvar libgit--root
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory where libgit is installed.")

(defvar libgit--build-dir
  (expand-file-name "build" libgit--root)
  "Directory where the libegit2 dynamic module file should be built.")

(defvar libgit--module-file
  (expand-file-name (concat "libegit2" module-file-suffix) libgit--build-dir)
  "Path to the libegit2 dynamic module file.")

(defun libgit--configure ()
  "Run the configure step of libegit2 asynchronously.

On successful exit, pass control on to the build step."
  (make-directory libgit--build-dir 'parents)
  (let ((default-directory libgit--build-dir))
    (set-process-sentinel
     (start-process "libgit-cmake" "*libgit build*" "cmake" "..")
     (lambda (proc chg)
       (when (eq 'exit (process-status proc))
         (if (= 0 (process-exit-status proc))
             (libgit--build)
           (pop-to-buffer "*libgit build*")
           (error "libgit: configuring failed with exit code %d" (process-exit-status proc))))))))

(defun libgit--build ()
  "Run the build step of libegit2 asynchronously.

On successful exit, pass control on to the load step."
  (let ((default-directory libgit--build-dir))
    (set-process-sentinel
     (start-process "libgit-cmake" "*libgit build*" "make")
     (lambda (proc chg)
       (when (eq 'exit (process-status proc))
         (if (= 0 (process-exit-status proc))
             (libgit--load)
           (pop-to-buffer "*libgit build*")
           (error "libgit: building failed with exit code %d" (process-exit-status proc))))))))

(defun libgit--load ()
  "Load libegit2."
  (unless (featurep 'libegit2)
    (load-file libgit--module-file))
  (unless (featurep 'libegit2)
    (error "libgit: unable to load the libegit2 dynamic module")))

;;;###autoload
(defun libgit-load ()
  (interactive)
  (cond
   ((file-exists-p libgit--module-file) (libgit--load))
   ((y-or-n-p "libgit must be built, do so now?") (libgit--configure))
   (error "libgit was not loaded!")))

(libgit-load)

(provide 'libgit)

;;; libgit.el ends here
