# 1. Introduction to Blockchain

In this chapter, we will get ourselves introduced to some definitions and examples for blockchain. We will see what properties a blockchain has, what it allows us to do and what it is good for.

I> ### Definition 1
I>
I> Cryptocurrency is a digital currency in which encryption techniques are used to regulate the generation of units of currency and verify the transfer of funds, operating independently of a central bank.

I> ### Definition 2
I>
I> Blockchain is a system in which a record of transactions is maintained across several computers that are linked in a peer-to-peer network.

We will give an example that will serve as a motivation, as well as define what encryption and hashing techniques are and how will they help us with our system.

## 1.1. Motivation

Let's assume that you and your friends exchange money often, for example, paying for dinner or drinks. It can be inconvenient to exchange cash all the time.

One possible solution is to keep records of all the bills that you and your friends have. This is called a ledger.

![A ledger and a set of connected friends (peers)](images/ledger.png)

I> ### Definition 3
I>
I> A ledger is a book that contains a record of transactions.

Further, at the end of every day, you all sit together and refer to the ledger to do the calculations to settle up. If you spent more than you received, you put that money in the pot, otherwise, you take that money out.

Every peer in the system has a *wallet* of a kind, that resembles the balance for them. Note that we have to go through all existing records to determine the balance of a wallet[^ch1n1].

A problem that might appear with this kind of system is that anyone can add a transaction. For example, Bob can add a transaction where Alice pays him a few dollars without Alice approving. We need to re-think our system such that all transactions will be verified/signed.

I> ### Definition 4
I>
I> A digital signature is a way to verify the authenticity of digital messages or documents.

For signing and verifying transactions we will rely on digital signatures. For now, let's assume that anyone who adds information to the ledger also adds a signature with each record, and others have no way to modify the signature, but only to verify it. We will cover the technical details in section 1.2.

![Our ledger now contains signatures](images/signatures.png)

However, now let's assume that Bob is keeping the ledger to himself, and everybody agreed to this. The ledger is now stored in what is called a *centralized authority*. But, if at the end of the day, say Bob has some errands to run, nobody will be able to refer to the ledger.

We need a way to decentralize the ledger, such that at any given time any of the peers can do a transaction. For this, every peer involved will keep a copy of the ledger to themselves, and when they meet at the end of the day they will sync their ledgers.

You are connected to your friends, and so are they to you. Informally, this makes a peer-to-peer network.

I> ### Definition 5
I>
I> A peer-to-peer network is formed when two or more computers are connected to each other.

For example, when you are accessing a web page on the Internet using a browser, your browser is the "client" and the web page you're accessing is hosted by a "server". This is a centralized system since every user is getting the information from a single place - the "server".

In contrast, in a peer-to-peer network - which represents a decentralized system - the distinction between a "client" and a "server" is blurred. Every peer is both a "client" and a "server" at the same time.

![A decentralized ledger](images/decentralized-ledger.png)

With this system, as the list of peers grows we might run into a problem of *trust*. When everybody meets at the end of the day to sync their ledgers, how can they believe the others that the transactions listed in their ledgers are true? Even if everybody trusts everybody else in the ledger, what if a new person wants to join this network? It's natural for existing users to ask the newcomer to prove that they can be trusted. We need to modify our system to support a kind of trust.

I> ### Definition 6
I>
I> A proof of work is data that is time-consuming to calculate, and easy for others to verify.

For each record we will also include a special number (or a hash) that will represent *proof of work*, in that it will provide proof that the transaction is valid. We will cover the technical details in section 1.3.

At the end of the day, we agree that we will trust the ledger who has put most of the work in it. If Bob has some errands to run, he can catch up the next day by trusting the rest of the peers in the network.

In addition to all this, we want the transactions to have an order, so every record will also contain a link to the previous record.

![A chain of blocks - blockchain](images/blockchain.png)

If everybody agreed to use this ledger as a source of truth, there would be no need to exchange physical money at all. Everybody can just use the ledger to put or retrieve money to it. After all, currency doesn't have to have any intrinsic value - it only has value because we, as a society, decide that it does.

To understand digital signatures and proof of work, we will be looking at encryption and hashing respectively. Fortunately for us, the programming language that we will be using has built-in functions for encryption and hashing. We don't have to dig too deep into how hashing and encryption and decryption works but a basic understanding of it will be sufficient.

X> ### Exercise 1
X>
X> Observe how we started with a simple definition of a ledger and gradually built up to a complex system. We will use the same approach in programming.

X> ### Exercise 2
X>
X> Think about why do people think that gold is valuable, or that money is valuable, or that currencies in online games are valuable?

## 1.2. Encryption

Before we talk about encryption, we first have to recall what functions are.

![A function](images/function.png)

I> ### Definition 7
I>
I> Functions are mathematical entities that assign unique outputs to given inputs.

For example, you might have a function that accepts as input a person, and as output returns the person's age or name. Another example is the function {$$}f(x) = x + 1{/$$}. There are many inputs this function can accept: 1, 2, 3.14. For example, when we input 2 it gives us an output of 3, since {$$}f(2) = 2 + 1 = 3{/$$}.

I> ### Definition 8
I>
I> Encryption is a method of encoding values such that only authorized persons can view the original content. Decryption is a method of decoding encrypted values.

### 1.2.1. Symmetric-key algorithm

We can assume that there exist functions {$$}E(x){/$$} and {$$}D(x){/$$} for encryption and decryption respectively. We want these functions to have the following properties:

1. {$$}E(x) \neq x{/$$}, meaning that the encrypted value should not be the same as the original value
1. {$$}E(x) \neq D(x){/$$}, meaning that the encrypted value should not be the same as the decrypted value
1. {$$}D(E(x)) = x{/$$}, meaning that the decryption of an encrypted value should return the original value

For example, let's assume there's some kind of an encryption scheme, say {$$}E(\text{"Boro"}) = \text{426f726f}{/$$}. We can "safely" communicate the value {$$}\text{426f726f}{/$$} without actually exposing our original value, and only those who know the decryption scheme {$$}D(x){/$$} will be able to see that {$$}D(\text{426f726f}) = \text{"Boro"}{/$$}.

Another example of encryption scheme is for {$$}E(x){/$$} to shift every character in {$$}x{/$$} forward, and for {$$}D(x){/$$} to shift every character in {$$}x{/$$} backwards[^ch1n2]. To encrypt the text "abc" we have {$$}E(\text{"abc"}) = \text{"bcd"}{/$$}, and to decrypt it we have {$$}D(\text{"bcd"}) = \text{"abc"}{/$$}.

However, the scheme described above makes a symmetric algorithm, meaning that we have to share the functions {$$}E{/$$} and {$$}D{/$$} with the parties involved, and as such, may be open to attacks.

![Symmetric-key algorithm](images/symmetric-algo.png)

X> ### Exercise 3
X>
X> Check the three properties one by one to ensure Caesar cipher is compatible with them.

X> ### Exercise 4
X>
X> Come up with an encryption scheme, based on substitution.

### 1.2.2. Asymmetric-key algorithm

To solve the problems that arise with symmetric-key algorithms, we will use what is called an asymmetric algorithm or public-key cryptography. In this scheme, we have two kinds of keys: public and private. We share the public key with the world and keep the private one to ourselves.

This algorithm scheme has a neat property where only the private key can decode a message, and the public key can encode a message.

We have two functions:

1. {$$}E(x, k){/$$}, that encrypts a message {$$}x{/$$} given a public key {$$}k{/$$}
1. {$$}D(x, k){/$$}, that decrypts a message {$$}x{/$$} given a private key {$$}k{/$$}

![Asymmetric-key algorithm](images/asymmetric-algo.png)

Recall the modulo operation - {$$}a \bmod b{/$$} represents the remainder when {$$}a{/$$} is divided by {$$}b{/$$}. Here's one example of a basic algorithm based on addition and modulo operations:

1. Pick one random number, for example 100. This will represent a common, publicly available key
1. We generate a random private key in the range {$$}(1, 100){/$$}, for example 97
1. We generate a public key by subtracting the common key from the private: {$$}100 - 97 = 3{/$$}
1. To encrypt data, add it to the public key and take modulo 100. {$$}E(x, k) = (x + k) \bmod 100{/$$}
1. To decrypt data, we use the same logic but with our private key, so {$$}D(x, k) = (x + k) \bmod 100{/$$}

For example, suppose we want to encrypt 5. Then {$$}E(x, 3) = (5 + 3) \bmod 100 = 8{/$$}. To decrypt 8, we have {$$}D(8, 97) = (8 + 97) \bmod 100 = 105 \bmod 100 = 5{/$$}.

This example uses a very simple generation pair {$$}(x + k) \bmod c{/$$}. But, in practice the pair generation algorithm is much more complex and harder to break by attackers.

We can use similar algorithm for digital signatures:

1. {$$}S(x, k){/$$}, that signs a message {$$}x{/$$} given a private key {$$}k{/$$}
1. {$$}V(x, s, k){/$$}, that verifies a message {$$}x{/$$}, given signature {$$}s{/$$} and public key {$$}k{/$$}

As we said earlier, each record will also include a special number (or a hash). This hash will be what is produced by {$$}S(x, k){/$$}. We will use the verify function to confirm a record's ownership.

In the wallet, we will store the public and the private keys. These keys will be used to receive or spend money. With the private key, it is possible to write new blocks (or transactions) to the blockchain, effectively spending money. With the public key, others can send currency to the wallet and verify signatures.

X> ### Exercise 5
X>
X> Use the algorithm we defined to sign a message and verify it.

## 1.3. Hashing

I> ### Definition 9
I>
I> Hashing is a one-way function that encodes text without a way to retrieve the original value back.

Hashing, however, is simpler than the encryption schemes described above. One example of a hashing function is to return the length of characters - {$$}H(\text{"abc"}) = 3{/$$}, but also {$$}H(\text{"bcd"}) = 3{/$$}. This means that we don't have a way to retrieve the original value just by using the return value 3.

As we mentioned earlier, the reason to use such a technique is that they have some interesting properties, such as providing us with the so-called notion proof-of-work.

I> ### Definition 10
I>
I> Mining is the process of validating transactions. For this effort, successful miners obtain money as a reward.

Hashcash is one kind of a proof-of-work system[^ch1n3]. We will use it to implement mining. We will see how this algorithm works in detail in the later chapters where we will implement it.

Hashing functions have another useful property that allows connecting two or more distinct blocks by having the information `current-hash` and `previous-hash` in each block. For example, `block-1` may have a hash such as `123456` and `block-2` may have a hash such as `345678`. Now, `block-2`'s `previous-hash` will be `block-1`'s `current-hash`, that is, `123456` - thus we've linked these two blocks.

The hash of the block is based on the block's data itself, so to verify a hash we can just hash the block's data and compare it to `current-hash`.

Two or more blocks (or transactions) that are connected form a blockchain. The validity of each transaction will depend on the validity of the blockchain.

X> ### Exercise 6
X>
X> Come up with your own hashing function.

## 1.4. Smart contracts

I> ### Definition 11
I>
I> A smart contract is a self-executing contract with the conditions of an agreement between a buyer and a seller being directly written into lines of code.

A blockchain is programmable if the transactions themselves can be programmed by users. For example, users (not necessarily programmers) can write a script to add additional requirements that must be satisfied before sending money. It could look something like this:

```text
if (user has more than 10 money)
   then approve transaction
   else reject transaction
```

Smart contracts are implemented as a computation that takes place on the blockchain. We will implement a very basic functionality of smart contracts.

## 1.5. Bitcoin

Bitcoin is the world's first cryptocurrency. In November 2008, a link to a paper authored by Satoshi Nakamoto titled "Bitcoin: A Peer-to-Peer Electronic Cash System" was published on a cryptography mailing list. Bitcoin's white paper consists of 9 pages, however, it is a mostly theoretical explanation of the design, and as such may be a bit overwhelming to newcomers.

The Bitcoin software is open source code and was released in January 2009 on SourceForge. As a result of that, anyone can clone the source code and make their blockchain, thus implementing a separate cryptocurrency. Such cryptocurrencies are usually called altcoins. The design of a Bitcoin includes a decentralized network (peer-to-peer network), block (mining), blockchain, transactions, and wallets, each of which we will look in detail in this book.

Although there are many cryptocurrency models and each one of them differs slightly in implementation details, the cryptocurrency we will be building upon in this book will look pretty similar to Bitcoin - with some parts simplified.

## 1.6. Example workflows

We will list a few important workflows that our system will use, among others.

**Mining a block** creates a new block, using Hashcash to calculate `current-hash` of the block. It also contains `previous-hash` that is a link to the previous block in the blockchain.

**Checking a wallet balance** for a person A will first filter all blocks in the blockchain (sender = A or receiver = A), and then sum them to calculate the balance. The more our blockchain grows the longer this operation will take. For that purpose we will use unspent transaction outputs or the UTXO model. This model is a list of transactions containing information about the owner and the amount of money. Thus, every transaction will consume elements from this list.

**Adding a block to a blockchain** consists of sending money from A to B. One pre-requisite is that A has enough money - we check this using the wallet balance workflow. We proceed by creating a transaction (sender = A, receiver = B) and signing it. Then we mine a block using this transaction and update the UTXO with the rewards.

## Summary

The point of this chapter was to give a vague idea of how the system that we will design looks like. Things will become much clearer in the implementation chapter where we will have to be explicit about the definitions of every entity.

Here's what we learned in this chapter, briefly:

1. The core entity of the system is a block
1. A block contains (among other data) transactions
1. We have a ledger that is an ordered list of all valid blocks (blockchain)
1. Every peer involved with the ledger has a wallet
1. Every record in the ledger is signed by the owner and can be verified by the public (digital signatures)
1. The ledger is in a decentralized location, that is, everybody has their copy of the ledger
1. Trust is based upon proof of work (mining)

[^ch1n1]: There is a way we can optimize this with so-called *unspent transaction outputs* (UTXOs).

[^ch1n2]: This is known as Caesar cipher.

[^ch1n3]: Hashcash was initially targeted for limiting email spam and other attacks. However, recently it's also become known for its usage in cryptocurrencies as part of the mining process. Hashcash was proposed in 1997 by Adam Backa.

