# Programs Make Waves

## Description

This is a simple implementation of "turning code execution into audio". With a history back into the mid 20th century, programmers and operators historically would use these type of sounds coming from a computer to detect (via sound!) a program hang (i.e. a runinning program would have constantly changing sounds, but a hung program gets stuck on one tone indefinitely).

An example of a computer system doing this "code to tones" trick can be viewed [here](https://www.youtube.com/watch?v=6vfa_RC_y1M&t=11s).

NOTE that `make-waves.sh` was developed under Ubuntu 20.04 x64, but should work on any system with `syscall` and a modern bash interpreter.  I probably shouldn't have done this as a bash script, but, well, here we are...  :)

This project currently contains 8 versions of "Hello, World!" to showcase the `make-waves.sh` script ability (but you can absolutely use `make-waves.sh` to create tones from YOUR progams, too!):

* C
* go
* rust
* java
* python
* ruby
* perl
* bash

You can use `make` to build the compiled versions, and `make clean` to remove compiled artifacts.  NOTE that you'll need to have installed the required build tools and script interpreters to run each version of these.

You can create the associated WAV file for a program (or several) easily:

`./make_waves <program name> [<program name> ...]`

Examples:

WAV file for C's "Hello, World!" (results in `hellow-c.wav`):

`./make-waves.sh ./hellow-c`

WAV file for go's "Hello, World!" (results in `hellow-go.wav`):

`./make-waves.sh ./hellow-go`

WAV file for rust's "Hello, World!" (results in `hellow-rust.wav`):

`./make-waves.sh ./hellow-rs`

WAV file for java's "Hello, World!" (results in `hellow-java.wav`):

`./make-waves.sh ./hellow-java`

WAV file for python's "Hello, World!" (results in `hellow.py.wav`):

`./make-waves.sh ./hellow.py`

WAV file for ruby's "Hello, World!" (results in `hellow.rb.wav`):

`./make-waves.sh ./hellow.rb`

WAV file for perl's "Hello, World!" (results in `hellow.pl.wav`):

`./make-waves.sh ./hellow.pl`

WAV file for bash's "Hello, World!" (results in `hellow.sh.wav`):

`./make-waves.sh ./hellow.sh`

You can use `make waves` to create ALL of the WAV files (might take a minute), and you can use `make clobber` to remove compiled artifacts AND all WAV files.

## Potential improvements

* make computation algorithms and WAV file specifics more easily "tweakable" in `make-waves.sh` 
* base tones on actual instruction execution (although, using SYSCALLs makes this software eaiser for more folks to use)
