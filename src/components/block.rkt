#lang racket
(require "utils.rkt")
(require (only-in sha sha256))
(require (only-in sha bytes->hex-string))
(require racket/serialize)

(struct block (hash previous-hash current-data timestamp nonce) #:prefab)

; calculate block hash
(define (calc-block-hash previous-hash current-data timestamp nounce)
  (bytes->hex-string (sha256 (bytes-append
                              (string->bytes/utf-8 previous-hash)
                              (string->bytes/utf-8 (number->string timestamp))
                              (string->bytes/utf-8 (~a (serialize current-data)))
                              (string->bytes/utf-8 (number->string nounce))))))

; Check to see if the given block is a valid block and is a memeber of the chain
(define (is-valid-block? blck)
  ; check to see of the hash is the same as this block
  (equal? (block-hash blck)
          (calc-block-hash (block-previous-hash blck)
                           (block-current-data blck)
                           (block-timestamp blck)
                           (block-nounce blck))))

(provide (struct-out block) valid-block?)