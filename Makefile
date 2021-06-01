.PHONY: all waves clean clobber

all: hellow-c hellow-rs hellow-go HelloW.class

hellow-c: hellow.c
	gcc $^ -o $@

hellow-rs: hellow.rs
	rustc $^ -o $@

hellow-go: hellow.go
	go build -o $@ $^

HelloW.class: hellow.java
	javac $^

waves: all
	./make-waves.sh ./hellow-c ./hellow-rs ./hellow-go ./hellow-java ./hellow.pl ./hellow.rb ./hellow.sh ./hellow.py

clean:
	rm -f hellow-c hellow-rs hellow-go HelloW.class

clobber: clean
	rm -f *.wav
