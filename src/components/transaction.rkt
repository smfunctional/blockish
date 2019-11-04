#lang racket
(require "utils.rkt")
(require "wallet.rkt")
(require "transaction-io.rkt")
(require crypto)
(require crypto/all)
(require racket/serialize)

(struct transaction (signature from to value inputs outputs) #:prefab)
(use-all-factories!)

(define (sign-transaction from to value)
  (let ([privkey (wallet-private-key from)]
        [pubkey