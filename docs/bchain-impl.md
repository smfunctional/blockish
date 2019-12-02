# 3. Blockchain implementation

Now that we have equipped ourselves with the ability to write computer programs, we will implement the components (data structures) of the blockchain. Throughout this chapter we will be using some new procedures. For some of them we will give a brief explanation. For others, if you are curious, you can get additional details from Racket's manuals.

Before we start, recall that at the top of every file you have to put `#lang racket` as we mentioned in the previous chapter.

I> ### Definition 1
I>
I> Serialization is the process of converting an object into a stream of bytes to store the object or transmit it to memory, a database, or a file. Deserialization is the opposite process - converting a stream of bytes into an object.

## 3.1. `wallet.rkt`

We will start with the most basic data structure - a wallet. As we discussed earlier, it is a structure that contains a public and a private key. It will have the form of:

```racket
(struct wallet
  (private-key public-key)
  #:prefab)
```

The `#:prefab` part is new. A prefab ("previously fabricated") structure type is a built-in type that is known to the Racket printer - we can print the structure and all of its contents. Also, we can serialize/deserialize these kinds of structures.

I> ### Definition 2
I>
I> RSA is an asymmetric-key algorithm used to encrypt and decrypt messages.

We will make a procedure that generates a wallet by generating random public and private keys. It will rely on the RSA algorithm.

```racket
(define (make-wallet)
  (letrec ([rsa-impl (get-pk 'rsa libcrypto-factory)]
           [privkey (generate-private-key rsa-impl '((nbits 512)))]
           [pubkey (pk-key->public-only-key privkey)])
    (wallet (bytes->hex-string
             (pk-key->datum privkey 'PrivateKeyInfo))
            (bytes->hex-string
             (pk-key->datum pubkey 'SubjectPublicKeyInfo)))))
```

All of these procedures come from the `crypto` package:

1. `get-pk` - returns the RSA implementation algorithm
1. `generate-private-key` - generates a private key given algorithm (in this case RSA)
1. `pk-key->public-only-key` - returns a public key given public/private key
1. `pk-key->datum` - returns a public/private key such that it is easily serializable by the next procedure in this list
1. `bytes->hex-string` - converts a hex string (think numbers for example) to bytes, e.g. `"0102030304" -> "Hello"`

We need to make sure to require the necessary packages:

```racket
(require crypto)
(require crypto/all)
```

We export everything:

```racket
(provide (struct-out wallet) make-wallet)
```

The `struct-out` syntax is just exporting the struct together with the procedures it generates.

Here's an example of a generated wallet:

```racket
> (make-wallet)
'#s(wallet
    "3082015502010030..."
    "305c300d06092a86...")
```

X> ### Exercise 1
X>
X> Extract the private and the public key of a wallet. The code should look something like `(wallet-?? (make-wallet))`.

## 3.2. `block.rkt`

A block should contain the current hash, the previous hash, data, and timestamp when it was generated:

```racket
(struct block
  (hash previous-hash data timestamp))
  #:prefab
```

The usage of a hashing algorithm will allow us to confirm that the block is really what it claims to be. In general, blocks can contain any data, not just transactions, but we are limiting it to transactions for now. We will also add a `nonce` field for the Hashcash algorithm - we will see the purpose of this field in a moment:

```racket
(struct block
  (hash previous-hash transaction timestamp nonce)
  #:prefab)
```

Our block also contains a transaction which is roughly of the following form:

```racket
(struct transaction
  (signature from to value)
  #:prefab)
```

We will discuss transactions in details later. Here's one way to generate a block, manually:

```racket
> (block "123456" "234" (transaction "BoroS" "Boro" "You" "a book") 1 1)
'#s(block "123456" "234" #s(transaction "BoroS" "Boro" "You" "a book")
1 1)
```

For example, this block makes a transaction from `"Boro"` to `"You"` with the value of `"a book"`, with a timestamp `1`.

I> ### Definition 3
I>
I> SHA is a hashing algorithm that takes an input and produces a hash value.

Next, we will implement a procedure that calculates a block's hash. We will use the SHA hashing algorithm. Here's how we can do that:

```racket
(define (calculate-block-hash previous-hash timestamp transaction nonce)
  (bytes->hex-string (sha256 (bytes-append
           (string->bytes/utf-8 previous-hash)
           (string->bytes/utf-8 (number->string timestamp))
           (string->bytes/utf-8 (~a (serialize transaction)))
           (string->bytes/utf-8 (number->string nonce))))))
```

There are a few things to note here:

1. We expect every field in the structure to be a string. This will make things much easier later, e.g. when we want to store our blockchain to a data file
1. If you check the manuals for `sha256` you will notice it accepts bytes, so we have to convert every field to bytes using `string->bytes/utf-8` and then append all these bytes together before hashing them
1. `number->string` converts a number to a string, so for example `3 -> "3"` and `~a` does the opposite
1. We use `serialize` on a transaction. This procedure accepts an object and returns an S-expression containing the same contents. Not all objects can be serialized, however, we use `#:prefab` so our structure can be serialized.
1. Finally, we store the hash as a hex string. Think of hex as a way to store a string from readable characters to numbers, e.g. `"Hello" -> "0102030304"`.

As an example, this is how we calculate the hash of our earlier example block:

```racket
> (calculate-block-hash "234" 1 (transaction "BoroS" "Boro" "You"
  "a book") 1)
"5e2889a76a464ea19a493a74d2da991a78626fc1fa9070340c2284ad92f4dd17"
```

Now that we have a way to calculate a block's hash, we also need a way to verify one. To do that we just hash the block's contents again and compare this hash to the one stored in the block:

```racket
(define (valid-block? bl)
  (equal? (block-hash bl)
          (calculate-block-hash (block-previous-hash bl)
                                (block-timestamp bl)
                                (block-transaction bl)
                                (block-nonce bl))))
```

At this point we will start implementing the Hashcash algorithm.

```racket
(define difficulty 2)
(define target (bytes->hex-string (make-bytes difficulty 32)))
```

We set the `difficulty` to 2, and thus the `target` will contain `difficulty` number of bytes using `make-bytes`. A block will be considered mined if the hash matches the target, given the difficulty:

```racket
(define (mined-block? hash)
  (equal? (subbytes (hex-string->bytes hash) 1 difficulty)
          (subbytes (hex-string->bytes target) 1 difficulty)))
```

A couple of things to note here:

1. `hex-string->bytes` is just a way to convert a hex string, e.g. `"0102030304" -> #"\1\2\3\3\4"`
1. `subbytes` takes a list of bytes, a start, and an end point and returns that sublist
1. Thus, given a random hash we consider it to be valid if its first two (in this case, per `difficulty`) bytes match the `target`

The actual Hashcash procedure:

```racket
(define (make-and-mine-block
         previous-hash timestamp transaction nonce)
  (let ([hash (calculate-block-hash
               previous-hash timestamp transaction nonce)])
    (if (mined-block? hash)
        (block hash previous-hash transaction timestamp nonce)
        (make-and-mine-block
         previous-hash timestamp transaction (+ nonce 1)))))
```

This procedure keeps increasing the `nonce` until the block is valid. Once the block is valid, we return that block. We change the `nonce` so that `sha256` produces a different hash. This defines the foundations of mining.

For example, here's how we can mine the earlier block we gave as an example:

```racket
> (define mined-block (make-and-mine-block "234" 1 (transaction "BoroS"
  "Boro" "You" "a book") 1))
> (block-nonce mined-block)
337
> (block-previous-hash mined-block)
"234"
> (block-hash mined-block)
"e920d627196658b64e349c1d3d6f2de1ab308d98d1c48130ee36df47ef25ee9a"
```

Note that `nonce` had to go up to 337 so that the mining conditionals were fulfilled.

Lastly, we have a small helper procedure:

```racket
(define (mine-block transaction previous-hash)
  (make-and-mine-block
   previous-hash (current-milliseconds) transaction 1))
```

`current-milliseconds` is a procedure that returns the current time in milliseconds since midnight UTC, January 1, 1970.

We provide these structures and procedures:

```racket
(provide (struct-out block) mine-block valid-block? mined-block?)
```

And make sure we require all the necessary packages:

```racket
(require (only-in file/sha1 hex-string->bytes))
(require (only-in sha sha256))
(require (only-in sha bytes->hex-string))
(require racket/serialize)
```

The `only-in` syntax imports only specific objects from a package, that we specify, instead of importing everything.

X> ### Exercise 2
X>
X> Use `make-and-mine-block` on a block you generated. What's the `nonce` count - i.e. how much "processing" did it take to mine that block?

X> ### Exercise 3
X>
X> Use `valid-block?` on the block in the previous exercise. Now use `valid-block?` on that block where its nonce is 1.
X>
X> Hint: To generate a "new" block out of existing one `bl` you can use:
X>
X> ```racket
X> (block (block-hash bl)
X>        (block-previous-hash bl)
X>        (block-transaction bl)
X>        (block-timestamp bl)
X>        (block-nonce bl))
X> ```

## 3.3. `utils.rkt`

This file will contain common procedures that will be used by other components.

A procedure that we will use often is `true-for-all?` that returns true if a predicate satisfies all members of the list, and false otherwise:

```racket
(define (true-for-all? pred list)
  (cond
    [(empty? list) #t]
    [(pred (car list)) (true-for-all? pred (cdr list))]
    [else #f]))
```

Here's an example how we can use it:

```racket
> (true-for-all? (lambda (x) (> x 3)) '(1 2 3))
#f
> (true-for-all? (lambda (x) (> x 3)) '(4 5 6))
#t
```

Now we have this procedure for exporting a struct to a file:

```racket
(define (struct->file object file)
  (let ([out (open-output-file file #:exists 'replace)])
    (write (serialize object) out)
    (close-output-port out)))
```

`open-output-file` returns an object in memory which then we can write to using `write`. When we do that, it will write to the opened file. `close-output-port` closes this object in memory. Thus, this procedure will serialize a struct and then write the serialized contents to a file.

The following procedure is exactly the opposite of `struct->file`, given a file it will return a struct by opening the file, reading its contents and deserializing its contents.

```racket
(define (file->struct file)
  (letrec ([in (open-input-file file)]
           [result (read in)])
    (close-input-port in)
    (deserialize result)))
```

Few notes here:

1. `deserialize` is the opposite of `serialize`.
1. `open-input-file` is similar to `open-output-file`, except that it is used to read from a file using `read`.

We provide these procedures:

```racket
(provide hex-string->bytes true-for-all? struct->file file->struct)
```

And make sure we require all the necessary packages:

```racket
(require racket/serialize)
```

## 3.4. Transactions

In this section we will implement the procedures for signing and verifying signatures.

### 3.4.1. `transaction-io.rkt`

A `transaction-io` structure (transaction input/output) will be a part of our `transaction` structure. The transaction input will be the blockchain address from which the money was sent, and the transaction output will be the blockchain address to which the money was sent.

This structure contains a hash so that we're able to verify its validity. It also has a value, an owner and a timestamp.

```racket
(struct transaction-io
  (hash value owner timestamp)
  #:prefab)
```

Similarly to a block, we will use the same algorithm for creating a hash, and also rely on serialization:

```racket
(require (only-in sha sha256))
(require (only-in sha bytes->hex-string))
(require racket/serialize)

(define (calculate-transaction-io-hash value owner timestamp)
  (bytes->hex-string (sha256 (bytes-append
           (string->bytes/utf-8 (number->string value))
           (string->bytes/utf-8 (~a (serialize owner)))
           (string->bytes/utf-8 (number->string timestamp))))))
```

`make-transaction-io` is a helper procedure that will initialize `timestamp` as well:

```racket
(define (make-transaction-io value owner)
  (let ([timestamp (current-milliseconds)])
    (transaction-io
     (calculate-transaction-io-hash value owner timestamp)
     value
     owner
     timestamp)))
```

A `transaction-io` structure is valid if its hash is equal to the hash of the value, owner and the timestamp:

```racket
(define (valid-transaction-io? t-in)
  (equal? (transaction-io-hash t-in)
          (calculate-transaction-io-hash
            (transaction-io-value t-in)
            (transaction-io-owner t-in)
            (transaction-io-timestamp t-in))))
```

Here's an example usage:

```racket
> (make-transaction-io 123 "Some person")
'#s(transaction-io "df652a3c15feba2eb9071cfdd810130c971f7fe7494a4710ee62
2fca11f0d83e" 123 "Some person" 1573765357289)
> (valid-transaction-io? (transaction-io "df652a3c15feba2eb9071cfdd81013
0c971f7fe7494a4710ee622fca11f0d83e" 123 "Some person" 1573765357289))
#t
> (valid-transaction-io? (transaction-io "badhash" 123 "Some person"
1573765357289))
#f
```

Finally, we export the procedures:

```racket
(provide (struct-out transaction-io)
         make-transaction-io valid-transaction-io?)
```

### 3.4.2. `transaction.rkt`

This file will contain procedures for signing and verifying transactions. It will also use transaction inputs and outputs and store them in a single transaction.

Here's everything that we will need to `require`:

```racket
(require "transaction-io.rkt")
(require "utils.rkt")
(require (only-in file/sha1 hex-string->bytes))
(require "wallet.rkt")
(require crypto)
(require crypto/all)
(require racket/serialize)
```

A transaction contains a signature, sender, receiver, value and a list of inputs and outputs (`transaction-io` objects).

```racket
(struct transaction
  (signature from to value inputs outputs)
  #:prefab)
```

I> ### Definition 4
I>
I> In Racket, a crypto factory is consisted of specific implementations of cryptographic algorithms.

In addition to the code above, we need to use all crypto factories. It will allow us to use some procedures, for example `hex<->pk-key`:

```racket
(use-all-factories!)
```

We will need a procedure that makes an empty, unsigned and unprocessed (no input outputs) transaction:

```racket
(define (make-transaction from to value inputs)
  (transaction
   ""
   from
   to
   value
   inputs
   '()))
```

Next, we have a procedure for signing a transaction. It is similar to one of the procedures we wrote earlier where we used hashing, in that we get all bytes from the structure and merge them. However, in this case we will be using digital signatures.

To create a digital signature, we use a hashing function (in this case, it is using the SHA algorithm). The private key is then used to encrypt the produced hash. The encrypted hash will represent our digital signature.

```racket
(define (sign-transaction from to value)
  (let ([privkey (wallet-private-key from)]
        [pubkey (wallet-public-key from)])
    (bytes->hex-string
     (digest/sign
      (datum->pk-key (hex-string->bytes privkey) 'PrivateKeyInfo)
      'sha1
      (bytes-append
       (string->bytes/utf-8 (~a (serialize from)))
       (string->bytes/utf-8 (~a (serialize to)))
       (string->bytes/utf-8 (number->string value)))))))
```

`digest/sign` is the procedure that does the hashing and encryption. It accepts a private key, an algorithm[^ch4n1] and bytes, and it returns encrypted data.

Next, we implement a procedure for processing transactions which will:

1. Sum all the inputs with `inputs-sum`
1. Calculate the `leftover` 
1. Generate new outputs to be used in the new signed and processed transaction `new-outputs`

In other words, based on our inputs it will create outputs that contain the leftover money:

```racket
(define (process-transaction t)
  (letrec
      ([inputs (transaction-inputs t)]
       [outputs (transaction-outputs t)]
       [value (transaction-value t)]
       [inputs-sum
        (foldr + 0 (map (lambda (i) (transaction-io-value i)) inputs))]
       [leftover (- inputs-sum value)]
       [new-outputs
        (list
         (make-transaction-io value (transaction-to t))
         (make-transaction-io leftover (transaction-from t)))])
    (transaction
     (sign-transaction (transaction-from t)
                       (transaction-to t)
                       (transaction-value t))
     (transaction-from t)
     (transaction-to t)
     value
     inputs
     (append new-outputs outputs))))
```

We have a procedure that checks a transaction's signature:

```racket
(define (valid-transaction-signature? t)
  (let ([pubkey (wallet-public-key (transaction-from t))])
    (digest/verify
     (datum->pk-key (hex-string->bytes pubkey) 'SubjectPublicKeyInfo)
     'sha1
     (bytes-append
      (string->bytes/utf-8 (~a (serialize (transaction-from t))))
      (string->bytes/utf-8 (~a (serialize (transaction-to t))))
      (string->bytes/utf-8 (number->string (transaction-value t))))
     (hex-string->bytes (transaction-signature t)))))
```

`digest/verify` is the opposite of `digest/sign` - in that instead of signing, it checks if a signature is valid.

Lastly, we will need a procedure that determines transaction validity under the following conditions:

1. Its signature is valid `valid-transaction-signature?`
1. All outputs are valid `valid-transaction-io?`
1. The sum of the inputs is greater than or equal to the sum of the outputs `>= sum-inputs sum-outputs`

```racket
(define (valid-transaction? t)
  (let ([sum-inputs
         (foldr + 0 (map (lambda (t) (transaction-io-value t))
                         (transaction-inputs t)))]
        [sum-outputs
         (foldr + 0 (map (lambda (t) (transaction-io-value t))
                         (transaction-outputs t)))])
    (and
     (valid-transaction-signature? t)
     (true-for-all? valid-transaction-io? (transaction-outputs t))
     (>= sum-inputs sum-outputs))))
```

Finally, we export:

```racket
(provide (all-from-out "transaction-io.rkt")
         (struct-out transaction)
         make-transaction process-transaction valid-transaction?)
```

The `all-from-out` syntax specifies all objects that we import (and that are exported) from the target. In this case, besides the file exporting the `transaction` structure with a couple of procedures, it also exports everything from `transaction-io.rkt`.

X> ### Exercise 4
X>
X> Create a transaction, sign it, and verify it using the procedures above.

## 3.5. `blockchain.rkt`

We'll need to `require` a bunch of stuff:

```racket
(require "block.rkt")
(require "transaction.rkt")
(require "utils.rkt")
(require "wallet.rkt")
```

Recall that utxo is just a list of `transaction-io` objects, where it represents unspent transaction outputs. In a way it resembles the initial balance of wallets. Thus, our structure will contain a list of blocks and utxo:

```racket
(struct blockchain
  (blocks utxo)
  #:prefab)
```

We will need a procedure for initialization of the blockchain. It accepts the genesis (first, ever) transaction, genesis hash, and utxo:

```racket
(define (init-blockchain t seed-hash utxo)
  (blockchain (cons (mine-block (process-transaction t) seed-hash) '())
              utxo))
```

One way to initialize a blockchain is as follows:

```racket
> (define coin-base (make-wallet))
> (define wallet-a (make-wallet))
> (define genesis-t (make-transaction coin-base wallet-a 100 '()))
> (define utxo (list
>              (make-transaction-io 100 wallet-a)))
> (define blockchain (init-blockchain genesis-t "1337cafe" utxo))
```

In the original Bitcoin implementation the block reward started at 50 coins for the first block and halves every on every 210000 blocks. This means every block up until block 210000 rewards 50 coins, while block 210001 rewards 25. In other words, the reward is {$$}\frac{2^{\lfloor\frac{b}{210000}\rfloor}}{50}{/$$} where {$$}b{/$$} is the number of blocks.

We follow the same algorithm - we start with 50 coins initially, and halve them on every 210000 blocks.

```racket
(define (mining-reward-factor blocks)
  (/ 50 (expt 2 (floor (/ (length blocks) 210000)))))
```

Before implementing the next procedure, we will introduce the notion of a set. In a list there can be repeated elements, but in a set all elements are unique. For example, consider the following code:

```racket
> (list->set '(1 2 3 4 4))
(set 1 3 2 4)
> '(1 2 3 4 4)
'(1 2 3 4 4)
```

Using a set over a list will allow us to use operations such as union, subtraction, etc. This is why we will treat `utxo` as a set. 

The next procedure will insert a transaction into the blockchain. It should:

1. Mine a block
1. Create a new utxo based on the processed transaction outputs, inputs and the current utxo
1. Generate a new list of blocks by `cons`-ing the mined block
1. Calculate the rewards based on the current utxo

```racket
(define (add-transaction-to-blockchain b t)
  (letrec ([hashed-blockchain
            (mine-block t (block-hash (car (blockchain-blocks b))))]
           [processed-inputs (transaction-inputs t)]
           [processed-outputs (transaction-outputs t)]
           [utxo (set-union processed-outputs
                            (set-subtract (blockchain-utxo b)
                                          processed-inputs))]
           [new-blocks (cons hashed-blockchain (blockchain-blocks b))]
           [utxo-rewarded (cons
                           (make-transaction-io
                            (mining-reward-factor new-blocks)
                            (transaction-from t))
                           utxo)])
    (blockchain
     new-blocks
     utxo-rewarded)))
```

We are using `set-union` which will produce elements that are found in two sets, and `set-subtract` which will produce elements that are found in the first set but not in the second set.

There is another special thing about `add-transaction-to-blockchain`. Given a blockchain and a transaction, it returns a new - updated blockchain. This newly returned blockchain will be our latest blockchain since the previous one does not contain the transaction.

This procedure will determine the balance of a wallet - the sum of all unspent transactions for the matching owner:

```racket
(define (balance-wallet-blockchain b w)
  (letrec ([utxo (blockchain-utxo b)]
           [my-ts (filter
                   (lambda (t) (equal? w (transaction-io-owner t)))
                   utxo)])
    (foldr + 0 (map (lambda (t) (transaction-io-value t)) my-ts))))
```

The next procedure will send money from one wallet to another by initiating a transaction and then adding it to the blockchain for processing. `my-ts` will contain the current receiver's transaction inputs. Finally, we add the transaction to the blockchain only if it is valid.

```racket
(define (send-money-blockchain b from to value)
  (letrec ([my-ts
            (filter (lambda (t) (equal? from (transaction-io-owner t)))
                    (blockchain-utxo b))]
           [t (make-transaction from to value my-ts)])
    (if (transaction? t)
        (let ([processed-transaction (process-transaction t)])
          (if (and (>= (balance-wallet-blockchain b from) value)
                   (valid-transaction? processed-transaction))
              (add-transaction-to-blockchain b processed-transaction)
              b))
        (add-transaction-to-blockchain b '()))))
```

Now we have this procedure that determines blockchain validity:

1. All blocks are valid `valid-block?`
1. Previous hashes are matching `equal?` check
1. All transactions are valid `valid-transaction?`
1. All blocks are mined `mined-block?`

```racket
(define (valid-blockchain? b)
  (let ([blocks (blockchain-blocks b)])
    (and
     (true-for-all? valid-block? blocks)
     (equal? (drop-right (map block-previous-hash blocks) 1)
             (cdr (map block-hash blocks)))
     (true-for-all?
      valid-transaction? (map
                          (lambda (block) (block-transaction block))
                          blocks))
     (true-for-all?
      mined-block? (map block-hash blocks)))))
```

Finally:

```racket
(provide (all-from-out "block.rkt")
         (all-from-out "transaction.rkt")
         (all-from-out "wallet.rkt")
         (struct-out blockchain)
         init-blockchain send-money-blockchain
         balance-wallet-blockchain valid-blockchain?)
```

X> ### Exercise 5
X>
X> Create two sets and use `set-subtract`, `set-union` and `set-intersect` on them. Observe the results.

X> ### Exercise 6
X>
X> Initialize a blockchain and add a transaction to it using `add-transaction-to-blockchain`.

X> ### Exercise 7
X>
X> Use `valid-blockchain?` on the blockchain in the previous exercise (before adding the new transaction, and after adding the new transaction).

## 3.6. Integrating components

### 3.6.1. `main-helper.rkt`

This file will export everything from `blockchain.rkt`, `utils.rkt` and also provide some printer procedures.

```racket
(require "blockchain.rkt")
(require "utils.rkt")
```

This procedure will convert a transaction object to a printable string. It will use `substring` to only print a subset of the hash (since it may be too big), and it will also use `format`, which is a string formatting procedure.

```racket
(define (format-transaction t)
  (format "...~a... sends ...~a... an amount of ~a."
          (substring (wallet-public-key (transaction-from t)) 64 80)
          (substring (wallet-public-key (transaction-to t)) 64 80)
          (transaction-value t)))
```

The next procedure will print the details of a block. `printf` is similar to `print`, except that it can be used like `format`:

```racket
(define (print-block bl)
  (printf "Block information\n=================
Hash:\t~a\nHash_p:\t~a\nStamp:\t~a\nNonce:\t~a\nData:\t~a\n"
          (block-hash bl)
          (block-previous-hash bl)
          (block-timestamp bl)
          (block-nonce bl)
          (format-transaction (block-transaction bl))))
```

Besides using recursion explicitly, there is a built-in `for` syntax that also allows repetitive computations. To print a blockchain, we will use the `for` syntax to go through all blocks, print them to the standard output, and then use `newline` to add a newline character to make the separation of every block obvious:

```racket
(define (print-blockchain b)
  (for ([block (blockchain-blocks b)])
    (print-block block)
    (newline)))
```

We print wallets similarly:

```racket
(define (print-wallets b wallet-a wallet-b)
  (printf "\nWallet A balance: ~a\nWallet B balance: ~a\n\n"
          (balance-wallet-blockchain b wallet-a)
          (balance-wallet-blockchain b wallet-b)))
```

And export the procedures:

```racket
(provide (all-from-out "blockchain.rkt")
         (all-from-out "utils.rkt")
         format-transaction print-block print-blockchain print-wallets)
```

X> ### Exercise 8
X>
X> Create a transaction and use `format-transaction` to see what it outputs. Do the same for block, blockchain, and wallets.

### 3.6.2. `main.rkt`

This is where we will put all the components together and use them. We start by checking if the file `blockchain.data` exists using `file-exists?`. This file will contain contents from a previous blockchain if it exists. If it doesn't, it will just proceed to create one.

```racket
(require "./main-helper.rkt")

(when (file-exists? "blockchain.data")
  (begin
    (printf "Found 'blockchain.data', reading...\n")
    (print-blockchain (file->struct "blockchain.data"))
    (exit)))
```

We initialize wallets:

```racket
(define coin-base (make-wallet))
(define wallet-a (make-wallet))
(define wallet-b (make-wallet))
```

We initialize transactions by creating the first (genesis) transaction:

```racket
(printf "Making genesis transaction...\n")
(define genesis-t (make-transaction coin-base wallet-a 100 '()))
```

We initialize the unspent transactions - our genesis transaction:

```racket
(define utxo (list
              (make-transaction-io 100 wallet-a)))
```

Finally, we initiate the blockchain by mining the genesis transaction:

```racket
(printf "Mining genesis block...\n")
(define blockchain (init-blockchain genesis-t "1337cafe" utxo))
(print-wallets blockchain wallet-a wallet-b)
```

Making a second transaction:

```racket
(printf "Mining second transaction...\n")
(set! blockchain (send-money-blockchain blockchain wallet-a wallet-b 2))
(print-wallets blockchain wallet-a wallet-b)
```

`set!` is just like a `define`, except that when something is already defined we cannot use `define` to change its value.

Making a third transaction:

```racket
(printf "Mining third transaction...\n")
(set! blockchain (send-money-blockchain blockchain wallet-b wallet-a 1))
(print-wallets blockchain wallet-a wallet-b)
```

Attempting to make a fourth transaction:

```racket
(printf "Attempting to mine fourth (not-valid) transaction...\n")
(set! blockchain (send-money-blockchain blockchain wallet-b wallet-a 3))
(print-wallets blockchain wallet-a wallet-b)
```

Checking blockchain validity:

```racket
(printf "Blockchain is valid: ~a\n\n" (valid-blockchain? blockchain))
```

Print every block from the blockchain:

```racket
(for ([block (blockchain-blocks blockchain)])
  (print-block block)
  (newline))
```

And export the blockchain to `blockchain.data` which can be re-used later.

```racket
(struct->file blockchain "blockchain.data")
(printf "Exported blockchain to 'blockchain.data'...\n")
```

## Summary

We built every component one by one, gradually. Some components are orthogonal - they are independent of one another. For example, `wallet` implementation does not call any procedures from `block`, and a `block` can be used independently of `wallet`. When we combine all of the components we get a nicely designed blockchain system.

This design allows extending our system easily. In the next chapter we will extend it with peer-to-peer and smart contracts functionalities without changing the basic components.

[^ch4n1]: In this case, this is a quoted expression but the algorithm itself is implemented in the crypto factories.

