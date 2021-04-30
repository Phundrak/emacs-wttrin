;;; wttrin.el --- Emacs frontend for weather web service wttr.in
;; Copyright (C) 2016 Carl X. Su

;; Author: Carl X. Su <bcbcarl@gmail.com>
;;         ono hiroko (kuanyui) <azazabc123@gmail.com>
;; Maintainer: Lucien Cartier-Tilet <lucien@phundrak.com>
;; Version: 0.3.0
;; Package-Requires: ((emacs "24.4") (xterm-color "1.0"))
;; Keywords: comm, weather, wttrin
;; URL: https://github.com/bcbcarl/emacs-wttrin

;;; Commentary:

;; Provides the weather information from wttr.in based on your query condition.

;;; Code:

(require 'url)
(require 'xterm-color)

(defgroup wttrin nil
  "Emacs frontend for weather web service wttr.in."
  :prefix "wttrin-"
  :group 'comm)

(defcustom wttrin-default-cities '("Taipei" "Keelung" "Taichung" "Tainan")
  "Specify default cities list for quick completion."
  :group 'wttrin
  :type 'list)

(defcustom wttrin-language "en-US"
  "Requested language for wttrin."
  :group 'wttrin
  :type 'string)

(defun wttrin-fetch-raw-string (query)
  "Get the weather information based on your `QUERY'."
  (let ((url-user-agent "curl"))
    (add-to-list 'url-request-extra-headers `("Accept-Language" . ,wttrin-language))
    (with-current-buffer
        (url-retrieve-synchronously
         (format "http%s://wttr.in/%s?A"
                 (if (gnutls-available-p) "s" "")
                 query)
         (lambda (status)
           (switch-to-buffer (current-buffer))))
      (decode-coding-string (buffer-string)
                            'utf-8))))

(defun wttrin-exit ()
  "Quit wttrin."
  (interactive)
  (quit-window t))

(defun wttrin-query (city-name)
  "Query weather of `CITY-NAME' via wttrin, and display the result in new buffer."
  (let ((raw-string (wttrin-fetch-raw-string city-name)))
    (if (string-match "ERROR" raw-string)
        (message "Cannot get weather data. Maybe you inputed a wrong city name?")
      (let ((buffer (get-buffer-create (format "*wttr.in - %s*" city-name))))
        (switch-to-buffer buffer)
        (setq buffer-read-only nil)
        (erase-buffer)
        (insert (xterm-color-filter raw-string))
        (goto-char (point-min))
        (re-search-forward "^$")
        (delete-region (point-min) (1+ (point)))
        (use-local-map (make-sparse-keymap))
        (local-set-key "q" 'wttrin-exit)
        (local-set-key "g" 'wttrin)
        (setq buffer-read-only t)))))

;;;###autoload
(defun wttrin (city)
  "Display weather information for `CITY'."
  (interactive
   (list
    (completing-read "City name: " wttrin-default-cities nil nil
                     (when (= (length wttrin-default-cities) 1)
                       (car wttrin-default-cities)))))
  (wttrin-query city))

(provide 'wttrin)

;;; wttrin.el ends here
