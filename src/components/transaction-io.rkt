#lang racket
(require (only-in sha sha256))
(require (only-in sha bytes->hex-string))
(require racket/serialize)

(struct transaction-io (hash value owner timestamp) #:prefab)

; Procedure for calculating the hash of a transaction-io object
(define (calc-trans-io-hash value owner timestamp)
  (bytes->hex-string (sha256 (bytes-append
                               (string->bytes/utf-8 (number->string value))
                               (string->bytes/utf-8 (~a (serialize owner)))
                               (string->bytes/utf-8 (number->string timestamp))))))

; Make a transaction-io object with calculated hash
(define (create-trans-io value owner)
  (let ([timestamp (current-milliseconds)])
    (transaction-io
      (calc-trans-io-hash value owner timestamp)
      value owner timestamp)))

; A transaction-io is valid if the hash is corrent
(define (valid-trans-io? txn)
  (equal? (transaction-io-hash txn)
          (calc-trans-io-hash (transaction-io-hash txn)
                              (transaction-io-owner txn)
                              (transaction-io-timestamp txn))))

(provide (struct-out transaction-io) create-trans-io calc-trans-io-hash valid-trans-io?)
  