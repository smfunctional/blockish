#lang racket
(require "utils.rkt")
(require (only-in sha sha256))
(require (only-in sha bytes->hex-string))
(require racket/serialize)

; A Block should contain the current hash, the previous hash, data, and timestamp when it was generated:
; 
(struct block (hash previous-hash transaction timestamp nonce) #:prefab)

; calculate block hash
(define (calc-block-hash previous-hash transaction timestamp nonce)
  (bytes->hex-string (sha256 (bytes-append
                              (string->bytes/utf-8 previous-hash)
                              (string->bytes/utf-8 (number->string timestamp))
                              (string->bytes/utf-8 (~a (serialize transaction)))
                              (string->bytes/utf-8 (number->string nonce))))))

; Check to see if the given block is a valid block and is a memeber of the chain
(define (is-valid-block? blck)
  ; check to see of the hash is the same as this block
  (equal? (block-hash blck)
          (calc-block-hash (block-previous-hash blck)
                           (block-transaction blck)
                           (block-timestamp blck)
                           (block-nonce blck))))

; A block is mined if the hash matches the target, given the difficulty.
(define difficulty 2)
(define target (bytes->hex-string (make-bytes difficulty 32)))

(define (mined-block? bl-hash)
  (equal? (subbytes (hex-string->bytes bl-hash) 1 difficulty)
          (subbytes (hex-string->bytes target) 1 difficulty)))

(define (build-and-mine target previous-hash timestamp transaction nonce)
  (let ([hash (calc-block-hash previous-hash timestamp transaction nonce)])
    (if (mined-block? hash)
        (block hash previous-hash transaction timestamp nonce)
        (build-and-mine target previous-hash transaction timestamp (+ nonce 1)))))

(define (mine-block transaction previous-hash)
  (build-and-mine target previous-hash transaction (current-milliseconds) 1))

(provide (struct-out block) is-valid-block? mine-block)