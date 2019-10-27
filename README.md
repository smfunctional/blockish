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

