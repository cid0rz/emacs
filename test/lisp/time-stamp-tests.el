;;; time-stamp-tests.el --- tests for time-stamp.el -*- lexical-binding: t -*-

;; Copyright (C) 2019 Free Software Foundation, Inc.

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Code:

(require 'ert)
(eval-when-compile (require 'cl-lib))
(require 'time-stamp)

(defmacro with-time-stamp-test-env (&rest body)
  "Evaluates BODY with some standard time-stamp test variables bound."
  `(let ((user-login-name "test-logname")
         (user-full-name "Time Stamp Tester")
         (buffer-file-name "/emacs/test/time-stamped-file")
         (mail-host-address "test-mail-host-name")
         (ref-time '(17337 16613))     ;Monday, Jan 2, 2006, 3:04:05 PM
         (ref-time2 '(22574 61591))    ;Friday, Nov 18, 2016, 12:14:15 PM
         (ref-time3 '(21377 23973 123456)) ;Sun, May 25, 2014, 03:04:05.123456am
         (time-stamp-time-zone t))     ;use UTC
     (cl-letf (((symbol-function 'time-stamp-conv-warn)
                (lambda (old-format _new)
                  (ert-fail
                   (format "Unexpected format warning for '%s'" old-format))))
               ((symbol-function 'system-name)
                (lambda () "test-system-name.example.org")))
       ;; Not all reference times are used in all tests;
       ;; suppress the byte compiler's "unused" warning.
       (list ref-time ref-time2 ref-time3)
       ,@body)))
(put 'with-time-stamp-test-env 'lisp-indent-hook 'defun)

(defmacro time-stamp-should-warn (form)
  "Similar to `should' but verifies that a format warning is generated."
  `(let ((warning-count 0))
     (cl-letf (((symbol-function 'time-stamp-conv-warn)
                (lambda (_old _new)
                  (setq warning-count (1+ warning-count)))))
       (should ,form)
       (if (not (= warning-count 1))
           (ert-fail (format "Should have warned about format: %S" ',form))))))

;;; Tests:

(ert-deftest time-stamp-test-day-of-week-documented ()
  "Test documented time-stamp formats for day of week."
  (with-time-stamp-test-env
    (should (equal (time-stamp-string "%3a" ref-time) "Mon"))
    (should (equal (time-stamp-string "%3A" ref-time) "MON"))
    (should (equal (time-stamp-string "%:a" ref-time) "Monday"))
    (should (equal (time-stamp-string "%#A" ref-time) "MONDAY"))
    (should (equal (time-stamp-string "%3a" ref-time2) "Fri"))
    (should (equal (time-stamp-string "%3A" ref-time2) "FRI"))
    (should (equal (time-stamp-string "%:a" ref-time2) "Friday"))
    (should (equal (time-stamp-string "%#A" ref-time2) "FRIDAY"))))

(ert-deftest time-stamp-test-day-of-week-future ()
  "Test implemented but as yet undocumented time-stamp formats for day of week."
  (with-time-stamp-test-env
    (should (equal (time-stamp-string "%#a" ref-time) "MON"))
    (should (equal (time-stamp-string "%:A" ref-time) "Monday"))
    (should (equal (time-stamp-string "%#a" ref-time2) "FRI"))
    (should (equal (time-stamp-string "%:A" ref-time2) "Friday"))))

(ert-deftest time-stamp-test-day-of-week-volatile-warns ()
  "Test time-stamp formats for day of week that will change.
Test that each generates a warning."
  (with-time-stamp-test-env
    (time-stamp-should-warn (equal
                            (time-stamp-string "%a" ref-time) "Monday"))
    (time-stamp-should-warn (equal
                             (time-stamp-string "%A" ref-time) "MONDAY"))))

(ert-deftest time-stamp-test-month-name-documented ()
  "Test documented time-stamp formats for month name."
  (with-time-stamp-test-env
    (should (equal (time-stamp-string "%3b" ref-time) "Jan"))
    (should (equal (time-stamp-string "%3B" ref-time) "JAN"))
    (should (equal (time-stamp-string "%:b" ref-time) "January"))
    (should (equal (time-stamp-string "%#B" ref-time) "JANUARY"))))

(ert-deftest time-stamp-test-month-name-future ()
  "Test implemented but as yet undocumented time-stamp formats for month name."
  (with-time-stamp-test-env
    (should (equal (time-stamp-string "%#b" ref-time) "JAN"))
    (should (equal (time-stamp-string "%:B" ref-time) "January"))))

(ert-deftest time-stamp-test-month-name-volatile-warns ()
  "Test time-stamp formats for month name that will change.
Test that each generates a warning."
  (with-time-stamp-test-env
    (time-stamp-should-warn (equal
                             (time-stamp-string "%b" ref-time) "January"))
    (time-stamp-should-warn (equal
                             (time-stamp-string "%B" ref-time) "JANUARY"))))

(ert-deftest time-stamp-test-day-of-month ()
  "Test time-stamp formats for day of month."
  (with-time-stamp-test-env
    ;; documented 1-digit
    (should (equal (time-stamp-string "%:d" ref-time) "2"))
    (should (equal (time-stamp-string "%2d" ref-time) " 2"))
    (should (equal (time-stamp-string "%02d" ref-time) "02"))
    ;; documented 2-digit
    (should (equal (time-stamp-string "%:d" ref-time2) "18"))
    (should (equal (time-stamp-string "%2d" ref-time2) "18"))
    (should (equal (time-stamp-string "%02d" ref-time2) "18"))
    ;; undocumented future formats
    (should (equal (time-stamp-string "%1d" ref-time) "2"))
    (should (equal (time-stamp-string "%1d" ref-time2) "18"))
    ;; changing formats
    (time-stamp-should-warn (equal (time-stamp-string "%d" ref-time) "2"))
    (time-stamp-should-warn (equal (time-stamp-string "%_d" ref-time) "2"))))

(ert-deftest time-stamp-test-hours-24 ()
  "Test time-stamp formats for hour on a 24-hour clock."
  (with-time-stamp-test-env
    ;; documented PM
    (should (equal (time-stamp-string "%:H" ref-time) "15"))
    (should (equal (time-stamp-string "%2H" ref-time) "15"))
    (should (equal (time-stamp-string "%02H" ref-time) "15"))
    ;; documented AM
    (should (equal (time-stamp-string "%:H" ref-time2) "12"))
    (should (equal (time-stamp-string "%2H" ref-time2) "12"))
    (should (equal (time-stamp-string "%02H" ref-time2) "12"))
    ;; documented 1-digit
    (should (equal (time-stamp-string "%:H" ref-time3) "3"))
    (should (equal (time-stamp-string "%2H" ref-time3) " 3"))
    (should (equal (time-stamp-string "%02H" ref-time3) "03"))
    ;; undocumented future formats
    (should (equal (time-stamp-string "%1H" ref-time) "15"))
    (should (equal (time-stamp-string "%1H" ref-time2) "12"))
    (should (equal (time-stamp-string "%1H" ref-time3) "3"))
    ;; changing formats
    (time-stamp-should-warn (equal (time-stamp-string "%H" ref-time) "15"))
    (time-stamp-should-warn (equal (time-stamp-string "%_H" ref-time) "15"))))

(ert-deftest time-stamp-test-hours-12 ()
  "Test time-stamp formats for hour on a 12-hour clock."
  (with-time-stamp-test-env
    ;; documented 1-digit, PM
    (should (equal (time-stamp-string "%:I" ref-time) "3"))
    (should (equal (time-stamp-string "%2I" ref-time) " 3"))
    (should (equal (time-stamp-string "%02I" ref-time) "03"))
    ;; documented 2-digit
    (should (equal (time-stamp-string "%:I" ref-time2) "12"))
    (should (equal (time-stamp-string "%2I" ref-time2) "12"))
    (should (equal (time-stamp-string "%02I" ref-time2) "12"))
    ;; undocumented future formats
    (should (equal (time-stamp-string "%1I" ref-time) "3"))
    (should (equal (time-stamp-string "%1I" ref-time2) "12"))
    ;; changing formats
    (time-stamp-should-warn (equal (time-stamp-string "%I" ref-time) "3"))
    (time-stamp-should-warn (equal (time-stamp-string "%_I" ref-time) "3"))))

(ert-deftest time-stamp-test-month-number ()
  "Test time-stamp formats for month number."
  (with-time-stamp-test-env
    ;; documented 1-digit
    (should (equal (time-stamp-string "%:m" ref-time) "1"))
    (should (equal (time-stamp-string "%2m" ref-time) " 1"))
    (should (equal (time-stamp-string "%02m" ref-time) "01"))
    ;; documented 2-digit
    (should (equal (time-stamp-string "%:m" ref-time2) "11"))
    (should (equal (time-stamp-string "%2m" ref-time2) "11"))
    (should (equal (time-stamp-string "%02m" ref-time2) "11"))
    ;; undocumented future formats
    (should (equal (time-stamp-string "%1m" ref-time) "1"))
    (should (equal (time-stamp-string "%1m" ref-time2) "11"))
    ;; changing formats
    (time-stamp-should-warn (equal (time-stamp-string "%m" ref-time) "1"))
    (time-stamp-should-warn (equal (time-stamp-string "%_m" ref-time) "1"))))

(ert-deftest time-stamp-test-minute ()
  "Test time-stamp formats for minute."
  (with-time-stamp-test-env
    ;; documented 1-digit
    (should (equal (time-stamp-string "%:M" ref-time) "4"))
    (should (equal (time-stamp-string "%2M" ref-time) " 4"))
    (should (equal (time-stamp-string "%02M" ref-time) "04"))
    ;; documented 2-digit
    (should (equal (time-stamp-string "%:M" ref-time2) "14"))
    (should (equal (time-stamp-string "%2M" ref-time2) "14"))
    (should (equal (time-stamp-string "%02M" ref-time2) "14"))
    ;; undocumented future formats
    (should (equal (time-stamp-string "%1M" ref-time) "4"))
    (should (equal (time-stamp-string "%1M" ref-time2) "14"))
    ;; changing formats
    (time-stamp-should-warn (equal (time-stamp-string "%M" ref-time) "4"))
    (time-stamp-should-warn (equal (time-stamp-string "%_M" ref-time) "4"))))

(ert-deftest time-stamp-test-second ()
  "Test time-stamp formats for second."
  (with-time-stamp-test-env
    ;; documented 1-digit
    (should (equal (time-stamp-string "%:S" ref-time) "5"))
    (should (equal (time-stamp-string "%2S" ref-time) " 5"))
    (should (equal (time-stamp-string "%02S" ref-time) "05"))
    ;; documented 2-digit
    (should (equal (time-stamp-string "%:S" ref-time2) "15"))
    (should (equal (time-stamp-string "%2S" ref-time2) "15"))
    (should (equal (time-stamp-string "%02S" ref-time2) "15"))
    ;; undocumented future formats
    (should (equal (time-stamp-string "%1S" ref-time) "5"))
    (should (equal (time-stamp-string "%1S" ref-time2) "15"))
    ;; changing formats
    (time-stamp-should-warn (equal (time-stamp-string "%S" ref-time) "5"))
    (time-stamp-should-warn (equal (time-stamp-string "%_S" ref-time) "5"))))

(ert-deftest time-stamp-test-am-pm ()
  "Test time-stamp formats for AM and PM strings."
  (with-time-stamp-test-env
    ;; documented
    (should (equal (time-stamp-string "%#p" ref-time) "pm"))
    (should (equal (time-stamp-string "%P" ref-time) "PM"))
    (should (equal (time-stamp-string "%#p" ref-time3) "am"))
    (should (equal (time-stamp-string "%P" ref-time3) "AM"))
    ;; changing
    (time-stamp-should-warn (equal (time-stamp-string "%p" ref-time) "pm"))))

(ert-deftest time-stamp-test-day-number-in-week ()
  "Test time-stamp formats for day number in week."
  (with-time-stamp-test-env
    (should (equal (time-stamp-string "%w" ref-time) "1"))
    (should (equal (time-stamp-string "%w" ref-time2) "5"))
    (should (equal (time-stamp-string "%w" ref-time3) "0"))))

(ert-deftest time-stamp-test-year ()
  "Test time-stamp formats for year."
  (with-time-stamp-test-env
    ;; documented
    (should (equal (time-stamp-string "%02y" ref-time) "06"))
    (should (equal (time-stamp-string "%:y" ref-time) "2006"))
    ;; undocumented future formats
    (should (equal (time-stamp-string "%Y" ref-time) "2006"))
    ;; changing
    (time-stamp-should-warn (equal (time-stamp-string "%y" ref-time) "2006"))))

(ert-deftest time-stamp-test-time-zone ()
  "Test time-stamp formats for time zone."
  (with-time-stamp-test-env
    ;; documented
    (should (equal (time-stamp-string "%z" ref-time) "gmt"))
    (should (equal (time-stamp-string "%Z" ref-time) "GMT"))
    ;; undocumented future formats
    (should (equal (time-stamp-string "%#Z" ref-time) "gmt"))))

(ert-deftest time-stamp-test-non-date-conversions ()
  "Test time-stamp formats for non-date items."
  (with-time-stamp-test-env
    ;; documented
    (should (equal (time-stamp-string "%%" ref-time) "%")) ;% last char
    (should (equal (time-stamp-string "%%P" ref-time) "%P")) ;% not last char
    (should (equal (time-stamp-string "%f" ref-time) "time-stamped-file"))
    (should (equal
             (time-stamp-string "%F" ref-time) "/emacs/test/time-stamped-file"))
    (should
     (equal (time-stamp-string "%s" ref-time) "test-system-name.example.org"))
    (should (equal (time-stamp-string "%u" ref-time) "test-logname"))
    (should (equal (time-stamp-string "%U" ref-time) "Time Stamp Tester"))
    (should (equal (time-stamp-string "%h" ref-time) "test-mail-host-name"))
    ;; undocumented
    (should (equal (time-stamp-string "%L" ref-time) "Time Stamp Tester"))
    (should (equal (time-stamp-string "%l" ref-time) "test-logname"))
    (should (equal
             (time-stamp-string "%Q" ref-time) "test-system-name.example.org"))
    (should (equal
             (time-stamp-string "%q" ref-time) "test-system-name"))))

(ert-deftest time-stamp-test-ignored-modifiers ()
  "Test additional args allowed (but ignored) to allow for future expansion."
  (with-time-stamp-test-env
    ;; allowed modifiers
    (should (equal (time-stamp-string "%.,@-+_ ^(stuff)P" ref-time3) "AM"))
    ;; not all punctuation is allowed
    (should-not (equal (time-stamp-string "%&P" ref-time3) "AM"))))

(ert-deftest time-stamp-test-non-conversions ()
  "Test that without a %, the text is copied literally."
  (with-time-stamp-test-env
    (should (equal (time-stamp-string "No percent" ref-time) "No percent"))))

(ert-deftest time-stamp-test-string-width ()
  "Test time-stamp string width modifiers."
  (with-time-stamp-test-env
    ;; strings truncate on the right or are blank-padded on the left
    (should (equal (time-stamp-string "%0P" ref-time3) ""))
    (should (equal (time-stamp-string "%1P" ref-time3) "A"))
    (should (equal (time-stamp-string "%2P" ref-time3) "AM"))
    (should (equal (time-stamp-string "%3P" ref-time3) " AM"))
    (should (equal (time-stamp-string "%0%" ref-time3) ""))
    (should (equal (time-stamp-string "%1%" ref-time3) "%"))
    (should (equal (time-stamp-string "%2%" ref-time3) " %"))
    (should (equal (time-stamp-string "%#3a" ref-time3) "SUN"))))

;;; time-stamp-tests.el ends here
