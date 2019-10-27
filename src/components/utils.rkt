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

(provide struct->file file->struct)
           