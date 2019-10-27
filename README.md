#  Blockish 

> A functional implementation of Blockchain in DrRacket

## Main Components

### 1. Block 
> contains the data along with the previous hash of the chain, the current hash of the data, data and  the timestamp.

```racket
(struct block
   (hash previous-link, current-date, nounce, timestamp)
 #:transparent)
```
### 2. Wallet
> It is a structure that contains a public and a private key.
```racket
(struct wallet
  (private-key public-key)
  #:prefab)
```
Wallet contains one method to create a wallet by generating random public and private keys.
