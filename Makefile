all:
	raco exe src/blockish.rkt

clean:
	rm -rf src/blockish src/*.rkt~ src/components/*.rkt~ src/components/compiled

deps:
	raco pkg install sha crypto-lib

run:
	racket src/blockish.rkt
