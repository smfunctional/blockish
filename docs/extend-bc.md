# 4. Extending the blockchain

In the previous chapter we implemented the most basic concepts that form a blockchain. In this chapter we will extend our blockchain with smart contracts and peer-to-peer support.

## 4.1. Smart contracts implementation

Bitcoin's blockchain is programmable - the transactions themselves can be programmed by users. For example, users can write scripts to add additional requirements that must be satisfied before sending money.

In section 2.4 we created an executable that we can send to our friends but they can no longer change the code, because they don't have the original code, and even if they did not all users are programmers.

The point of smart contracts is to allow non-programmers to adjust the logic in the code without changing the original code.

### 4.1.1. `smart-contracts.rkt`

Our implementation will depend on transactions:

```racket
(require "transaction.rkt")
```

We have to extend our original `valid-transaction?` so that it will also consider contracts when calculating validity:

```racket
(define (valid-transaction-contract? t contract)
  (and (eval-contract t contract)
       (valid-transaction? t)))
```

We will now implement a procedure that will accept a transaction, a contract (scripting language) and return some value. This value can either be true, false, a number, or a string.

```racket
(define (eval-contract t c)
  (match c
    [(? number? x) x]
    [(? string? x) x]
    [`() #t]
    [`true #t]
    [`false #f]
    [`(if ,co ,tr ,fa) (if co tr fa)]
    [`(+ ,l ,r) (+ l r)]
    [else #f]))
```

We used a new syntax `match`. It is similar to `cond` except that it can check more complex structures. For example, if `c` matches `true` then it will return `#t`. If `c` matches a structure of the form `(if X Y Z)` then it will return the evaluation of `(if X Y Z)`.

A few example usages:

```racket
> (define test-transaction (transaction "BoroS" "Boro" "You" "a book"
  '() '()))
> (eval-contract test-transaction 123)
123
> (eval-contract test-transaction "Hi")
"Hi"
> (eval-contract test-transaction '())
#t
> (eval-contract test-transaction 'true)
#t
> (eval-contract test-transaction 'false)
#f
> (eval-contract test-transaction '(if #t "Hi" "Hey"))
"Hi"
> (eval-contract test-transaction '(if #f "Hi" "Hey"))
"Hey"
> (eval-contract test-transaction '(+ 1 2))
3
```

However, we still haven't used the transaction values in our procedure. Let's extend our scripting language with a few more commands:

```racket
...
    [`from (transaction-from t)]
    [`to (transaction-to t)]
    [`value (transaction-value t)]
...
```

Now we can do something like:

```racket
> (eval-contract test-transaction 'from)
"Boro"
> (eval-contract test-transaction 'to)
"You"
> (eval-contract test-transaction 'value)
"a book"
```

We will implement a few more operators, so that our scripting language becomes more expressive:

```racket
...
    [`(* ,l ,r) (* l r)]
    [`(- ,l ,r) (- l r)]
    [`(= ,l ,r) (equal? l r)]
    [`(> ,l ,r) (> l r)]
    [`(< ,l ,r) (< l r)]
    [`(and ,l ,r) (and l r)]
    [`(or ,l ,r) (or l r)]
...
```

However, there is a problem in our language implementation. Consider evaluations of `(+ 1 2)` and `(+ (+ 1 2) 3)` in our language:

```racket
> (eval-contract test-transaction '(+ 1 2))
3
> (eval-contract test-transaction '(+ (+ 1 2) 3))
. . +: contract violation
```

The problem happens in the matching clause ``[`(+ ,l ,r) (+ l r)]``. when we match against `'(+ (+ 1 2) 3))` we end up with `(+ '(+ 1 2) 3)`, so Racket cannot sum a quoted list with a number. The solution to this problem is to *recursively* evaluate every sub-expression. So our match turns from ``[`(+ ,l ,r) (+ l r)]`` to ``[`(+ ,l ,r) (+ (eval-contract t l) (eval-contract t r))]``.

In this case, the evaluation will happen as follows:

```racket
(eval-contract t '(+ (+ 1 2) 3))
= (eval-contract t (list '+ (eval-contract t '(+ 1 2))
    (eval-contract t 3)))
= (eval-contract t (list '+ (+ 1 2) 3))
= (eval-contract t (list '+ 3 3))
= (eval-contract t '(+ 3 3))
= (eval-contract t 6)
= 6
```

It is important to recall the distinction between a quoted list and a non-quoted one: the latter will attempt evaluation. In this case we just juggled with the quotation in order to produce the desired results.

We will have to rewrite all of our operators:

```racket
...
    [`(+ ,l ,r) (+ (eval-contract t l) (eval-contract t r))]
    [`(* ,l ,r) (* (eval-contract t l) (eval-contract t r))]
    [`(- ,l ,r) (- (eval-contract t l) (eval-contract t r))]
    [`(= ,l ,r) (= (eval-contract t l) (eval-contract t r))]
    [`(> ,l ,r) (> (eval-contract t l) (eval-contract t r))]
    [`(< ,l ,r) (< (eval-contract t l) (eval-contract t r))]
    [`(and ,l ,r) (and (eval-contract t l) (eval-contract t r))]
    [`(or ,l ,r) (or (eval-contract t l) (eval-contract t r))]
...
```

The `if` implementation in our language has the same problem. So we will also change it:

```racket
...
    [`(if ,co ,tr ,fa) (if (eval-contract t co)
                           (eval-contract t tr)
                           (eval-contract t fa))]
...
```

Thus, our final procedure becomes:

```racket
(define (eval-contract t c)
  (match c
    [(? number? x) x]
    [(? string? x) x]
    [`() #t]
    [`true #t]
    [`false #f]
    [`(if ,co ,tr ,fa) (if (eval-contract t co)
                           (eval-contract t tr)
                           (eval-contract t fa))]
    [`(+ ,l ,r) (+ l r)]
    [`from (transaction-from t)]
    [`to (transaction-to t)]
    [`value (transaction-value t)]
    [`(+ ,l ,r) (+ (eval-contract t l) (eval-contract t r))]
    [`(* ,l ,r) (* (eval-contract t l) (eval-contract t r))]
    [`(- ,l ,r) (- (eval-contract t l) (eval-contract t r))]
    [`(= ,l ,r) (= (eval-contract t l) (eval-contract t r))]
    [`(> ,l ,r) (> (eval-contract t l) (eval-contract t r))]
    [`(< ,l ,r) (< (eval-contract t l) (eval-contract t r))]
    [`(and ,l ,r) (and (eval-contract t l) (eval-contract t r))]
    [`(or ,l ,r) (or (eval-contract t l) (eval-contract t r))]
    [else #f]))
```

Now users can supply scripting code such as `(if (= (+ 1 2) 3) from to)`:

```racket
> (eval-contract test-transaction '(if (= (+ 1 2) 3) from to))
"Boro"
> (eval-contract test-transaction '(if (= (+ 1 2) 4) from to))
"You"
```

Note that a contract in our implementation is just an S-expression.

Finally, we provide the output which is just the transaction validity check:

```racket
(provide valid-transaction-contract?)
```

### 4.1.2. Updating existing code

Now, in `blockchain.rkt` we slightly rewrite the money sending procedure to accept contracts:

```racket
(define (send-money-blockchain b from to value c)
  (letrec ([my-ts
            (filter (lambda (t) (equal? from (transaction-io-owner t)))
                    (blockchain-utxo b))]
           [t (make-transaction from to value my-ts)])
    (if (transaction? t)
        (let ([processed-transaction (process-transaction t)])
          (if (and
               (>= (balance-wallet-blockchain b from) value)
               (valid-transaction-contract? processed-transaction c))
              (add-transaction-to-blockchain b processed-transaction)
              b))
        (add-transaction-to-blockchain b '()))))
```

We update `blockchain.rkt` to also `(require "smart-contracts.rkt")`. Then we update `utils.rkt` to add this helper procedure for reading contracts:

```racket
(define (file->contract file)
  (with-handlers ([exn:fail? (lambda (exn) '())])
    (read (open-input-file file))))
```

Make sure to add `file->contract` to the list of `provide` in `utils.rkt`.

Finally, we need to update every usage of `(send-money-blockchain ...)` to `(send-money-blockchain ... (file->contract "contract.script"))` in `main.rkt`.

TODO: Test

## 4.2. Peer-to-peer implementation

### 4.2.1. `peer-to-peer.rkt`

TODO: Try refactoring some procedures. They are too big and use `define` within `define` (need to use `let`), etc.

```racket
(require "blockchain.rkt")
(require "block.rkt")
(require racket/serialize)
```

The `peer-info` structure contains an ip and a port:

```racket
(struct peer-info
  (ip port)
  #:prefab)
```

`peer-info-io` additionally contains IO ports:

```racket
(struct peer-info-io
  (pi input-port output-port)
  #:prefab)
```

`peer-context-data` contains all information needed for a single peer:

```racket
(struct peer-context-data
  (name
   port
   [valid-peers #:mutable]
   [connected-peers #:mutable]
   [blockchain #:mutable])
  #:prefab)
```

The list of valid peers will be updated depending on info retrieved from connected peers. The list of connected peers will be a (not necessarily strict) subset of `valid-peers`. Blockchain will be updated from data with other peers.

Now we have this procedure for getting the sum of nonces of a blockchain. Highest one has most effort and will win to get updated throughout the peers.

```racket
(define (get-blockchain-effort b)
  (foldl + 0 (map block-nonce (blockchain-blocks b))))
```

Now we have this procedure which will server as a handler for updating latest blockchain:

TODO: Talk about `set-...!`, atomic operations, etc.

```racket
(define (trim-helper x)
  (deserialize (read (open-input-string (string-replace-line x "")))))
```

```racket
(define (maybe-update-blockchain peer-context line)
  (let ([current-blockchain (trim-helper #rx"(latest-blockchain:|[\r\n]+)")]
        [latest-blockchain (peer-context-data-blockchain peer-context)])
    (when (and (valid-blockchain? current-blockchain)
               (> (get-blockchain-effort current-blockchain)
                  (get-blockchain-effort latest-blockchain)))
      (printf "Blockchain updated for peer ~a\n"
              (peer-context-data-name peer-context))
      (set-peer-context-data-blockchain! peer-context
                                         current-blockchain))))
```

Together with this handler for updating valid peers:

```racket
(define (maybe-update-valid-peers peer-context line)
  (let ([valid-peers (list->set (trim-helper #rx"(valid-peers:|[\r\n]+)"))]
        [current-valid-peers (peer-context-data-valid-peers
                              peer-context)])
    (set-peer-context-data-valid-peers!
     peer-context
     (set-union current-valid-peers valid-peers))))
```

Now we have these generic handlers for both client and server: `handler`, `launch-handler-thread` and `peers`.

`handler` is the main handler:

```racket
(define (handler peer-context in out)
  (flush-output out)
  (define line (read-line in))
  (when (string? line) ; it can be eof
    (cond [(string-prefix? line "get-valid-peers")
           (fprintf out "valid-peers:~a\n"
                    (serialize
                     (set->list
                      (peer-context-data-valid-peers peer-context))))
           (handler peer-context in out)]
          [(string-prefix? line "get-latest-blockchain")
           (fprintf out "valid-peers:~a\n"
                    (serialize
                     (peer-context-data-blockchain peer-context)))
           (handler peer-context in out)]
          [(string-prefix? line "latest-blockchain:")
           (begin (maybe-update-blockchain peer-context line)
                  (handler peer-context in out))]
          [(string-prefix? line "valid-peers:")
           (begin (maybe-update-valid-peers peer-context line)
                  (handler peer-context in out))]
          [(string-prefix? line "exit")
           (fprintf out "bye\n")]
          [else (handler peer-context in out)])))
```

Now we have this helper procedure to launch handler thread:

```racket
(define (launch-handler-thread handler peer-context in out cb)
  (define-values (local-ip remote-ip) (tcp-addresses in))
  (define current-peer (peer-info
                        remote-ip
                        (peer-context-data-port peer-context)))
  (define current-peer-io (peer-info-io current-peer in out))
  (thread
   (lambda ()
     (handler peer-context in out)
     (cb)
     (close-input-port in)
     (close-output-port out))))
```

Now we have this procedure that will ping all peers in attempt to sync blockchains and update list of valid peers:

```racket
(define (peers peer-context)
  (define (loop)
    (sleep 10)
    (for [(p (peer-context-data-connected-peers peer-context))]
      (let ([in (peer-info-io-input-port p)]
            [out (peer-info-io-output-port p)])
        (fprintf out "get-latest-blockchain\nget-valid-peers\n")
        (flush-output out)))
    (printf "Peer ~a reports ~a valid peers.\n"
            (peer-context-data-name peer-context)
            (set-count (peer-context-data-valid-peers peer-context)))
    (loop))
  (define t (thread loop))
  (lambda ()
    (kill-thread t)))
```

Now we have these two generic procedures for server: `accept-and-handle` and `serve`.

`accept-and-handle` accepts a new connection:

```racket
(define (accept-and-handle listener handler peer-context)
  (define-values (in out) (tcp-accept listener))
  (launch-handler-thread handler peer-context in out void))
```

`serve` is the main server listener:

```racket
(define (serve peer-context)
  (define main-cust (make-custodian))
  (parameterize ([current-custodian main-cust])
    (define listener
      (tcp-listen (peer-context-data-port peer-context) 5 #t))
    (define (loop)
      (accept-and-handle listener handler peer-context)
      (loop))
    (thread loop))
  (lambda ()
    (custodian-shutdown-all main-cust)))
```

Now we have `peer-loop` that does ...:

```racket
(define (peer-loop peer)
  (begin
    ;(printf "Trying to connect to ~a:~a...\n" (peer-info-ip peer) (peer-info-port peer))
    (define-values (in out) (tcp-connect (peer-info-ip peer) (peer-info-port peer)))
    (printf "'~a' connected to ~a:~a!\n"
            (peer-context-data-name peer-context) (peer-info-ip peer) (peer-info-port peer))
    (define current-peer-io (peer-info-io peer in out))
    ; Add current peer to list of connected peers
    (set-peer-context-data-connected-peers!
     peer-context
     (cons current-peer-io (peer-context-data-connected-peers peer-context)))
    (launch-handler-thread
     handler
     peer-context
     in
     out
     (lambda ()
       ; Remove peer from list of connected peers
       (set-peer-context-data-connected-peers!
        peer-context
        (set-remove
         (peer-context-data-connected-peers peer-context)
         current-peer-io))))))
```

Now we have this generic procedure for client, `connections-loop`, that makes sure we're connected with all known peers. TODO: break this procedure into smaller parts?

```racket
(define (connections-loop)
  (letrec ([current-connected-peers (list->set (map peer-info-io-pi (peer-context-data-connected-peers peer-context)))]
           [all-valid-peers (peer-context-data-valid-peers peer-context)]
           [potential-peers (set-subtract all-valid-peers current-connected-peers)])
    (for ([peer potential-peers])
      (thread (lambda ()
                (with-handlers ([exn:fail? (lambda (exn) #t)])
                  (peer-loop peer)))))
    (sleep 10)
    (connections-loop)))
```

Now we have this helper procedure:

```racket
(define (connections-loop-helper peer-context)
  (define conns-cust (make-custodian))
  (parameterize ([current-custodian conns-cust])
    (thread connections-loop))
  (lambda ()
    (custodian-shutdown-all conns-cust)))
```

Now we have this helper procedure for running a peer-to-peer connection.

```racket
(define (run-peer peer-context)
  (let ([stop-listener (serve peer-context)]
        [stop-peers-loop (peers peer-context)]
        [stop-connections-loop (connections-loop peer-context)])
    (lambda ()
      (begin
        (stop-connections-loop)
        (stop-peers-loop)
        (stop-listener)))))
```

Finally

```racket
(provide (struct-out peer-context-data)
         (struct-out peer-info)
         run-peer)
```

### 4.2.2. Updating existing code

Also need to modify `main-helper.rkt` to include peer-to-peer implementation:

```racket
; ...
(require "peer-to-peer.rkt")
; ...

(provide (all-from-out "blockchain.rkt")
         (all-from-out "utils.rkt")
         (all-from-out "peer-to-peer.rkt")
         format-transaction print-block print-blockchain print-wallets)
```

### 4.2.3. `main-p2p.rkt`

```racket
(require "./main-helper.rkt")
```

This will convert a string of format `ip:port` to `peer-info` structure:

```racket
(define (string-to-peer-info s)
  (let ([s (string-split s ":")])
    (peer-info (car s) (string->number (cadr s)))))
```

This will create a new wallet for us to use:

```racket
(define wallet-a (make-wallet))
```

Finally, the creation of new blockchain that initializes wallets, transactions, unspect transactions and blockchain:

```racket
(define (initialize-new-blockchain)
  (begin
    (define coin-base (make-wallet))

    (printf "Making genesis transaction...\n")
    (define genesis-t
      (make-transaction coin-base wallet-a 100 '()))

    (define utxo (list
                  (make-transaction-io 100 wallet-a)))

    (printf "Mining genesis block...\n")
    (define b (init-blockchain genesis-t "1337cafe" utxo))
    b))
```

Some command line parsing (what's a command line to a newbie?)

```racket
(define args (vector->list (current-command-line-arguments)))

(when (not (= 3 (length args)))
  (begin
    (printf
     "Usage: racket main-p2p.rkt dbfile.data port ip1:port1,...\n")
    (exit)))

(define db-filename (car args))
(define port (string->number (cadr args)))
(define valid-peers
  (map string-to-peer-info (string-split (caddr args) ",")))
```

This will try to read the blockchain from a file (DB), otherwise create a new one:

```racket
(define b
  (if (file-exists? db-filename)
      (file->struct db-filename)
      (initialize-new-blockchain)))
```

Peer initialization:

```racket
(define peer-context
  (peer-context-data "Test peer" port (list->set valid-peers) '() b))
(define (get-blockchain) (peer-context-data-blockchain peer-context))

(run-peer peer-context)
```

We keep exporting the database to have up-to-date info whenever a user quits the app.

```racket
(define (export-loop)
  (begin
    (sleep 10)
    (struct->file (get-blockchain) db-filename)
    (printf "Exported blockchain to '~a'...\n" db-filename)
    (export-loop)))

(thread export-loop)
```

Here's a procedure to keep mining empty blocks, as the p2p runs in threaded mode.

```racket
(define (mine-loop)
  (let ([newer-blockchain
         ; This blockchain includes a new block
         (send-money-blockchain (get-blockchain) wallet-a wallet-a 1)])
    (set-peer-context-data-blockchain! peer-context newer-blockchain)
    (printf "Mined a block!")
    (sleep 5)
    (mine-loop)))

(mine-loop)
```

TODO: Create executable

## Summary

