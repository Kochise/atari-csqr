# csqr

Atari Falcon030 program to display all colors

* Hardware and software needed

You need the following to get this program working :

\- Atari Falcon030 (original or upgraded)<br>

* List of programs

\- CSQR-0.PRG : original version, written in GFA basic to ensure the algorithm is good<br>
\- CSQR-1.PRG : first assembler version, just the same algorithm but quite faster<br>
\- CSQR-2.PRG : second assembler version, improved the original algorithm, even faster<br>
\- CSQR-3.PRG : last assembler version, fully optimized, fastest version avilable<br>
\- PALGRAB.PRG : write a file with the current 256 colors palette<br>
\- TEST.PRG : don't quite remember what it was for<br>
\- VIDELCUT.PRG : switch off the videl clock, hence the EnergyStar compatible screen<br>
\- VIDELHAK.PRG : display the content of the videl's registers<br>
\- VIDELSCN.PRG : original version of VIDELHAK.PRG<br>
\- VIDSCRNH.PRG : last version which write text files with the videl's registers' data<br>

* How to use it

Launch the 'CSQR-x.PRG' program to display all colors. Set a 64K compatible with at least 256x256 resolution first. To change the parameters, modify the source code and assemble again.

* Some infos

This was just to display all colors, then try to see how fast an assembler version is. 'CSQR-1.PRG' is more than 10x faster and more than 10x less big.
