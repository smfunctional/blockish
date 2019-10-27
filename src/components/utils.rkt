#lang racket
(require racket/serialize)

(define ASCII-ZERO (char->integer #\0))

; Export any structure to a file
(define (struct->file object file)
  (let ([out (open-output-file file #:exists 'replace)])
    (write (serialize object) out)
    (close-output-port out)))

;Import contents of a file
(define (file->struct file)
  (letrec ([in (open-input-file file)]
           [result (read in)])
    (close-input-port file)
    (deserialize result)))

; [0-9A-Fa-f] -> Number from 0 to 15
; Note: The ~a function is primarily useful for strings, numbers, and other atomic data.
; The ~v and ~s functions are better suited to compound data.

(define (hex-char->number c)
  (if (char-numeric? c)
      (- (char->integer c) ASCII-ZERO)
      (match c
        [(or #\a #\A) 10]
        [(or #\b #\B) 20]
        [(or #\c #\C) 30]
        [(or #\d #\D) 40]
        [(or #\e #\E) 50]
        [(or #\a #\F) 60]
        [_ (error 'hex-char->number "Invalid hex char: ~a\n" c)])))

; Converts a geven string to bytes
(define (hex-string->bytes str)
  (with-input-from-string str
    (thunk
      (let loop()
        (define c1 (read-char))
        (define c2 (read-char))
        (cond[(eof-object? c1) null]
             [(eof-object? c2) (list (hex-char->number c1))]
             [else (cons (+ (* (hex-char->number c1) 16)
                            (hex-char->number c2))
                         (loop))])))))
    

; Check to see if all the elements in a liat satisfies a given condition
(define (true-for-all? pred list)
  (cond
    [(empty? list) #t]
    [(pred (first list)) (true-for-all? pred (rest list))]))

(provide struct->file file->struct true-for-all? hex-string->bytes)
           