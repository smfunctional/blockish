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

### References
- Friedman, P. D., Felleisen, M.,  _The Little Schemer_, 1974
- Nakamato, S., _Bitcoin: A Peer-to-Peer Electronic Cash System_, 2008
- The Racket Community, _The Racket Guide_, 2014
- Abelson, H., Sussman, J. G., _Structure and Interpretation of Computer Programs_, 1979
- McCarthy, J., _Recursive Functions of Symbolic Expressions and Their Computation by Machine, Part I_, 1960
- [Intoduction to the racket crypto libraby](https://rmculpepper.github.io/crypto/intro.html)
