decimal
17 constant w
: w* dup 2* 2* 2* 2* + ;
w dup * constant mapsize
here mapsize allot constant m \ map

256 value r \ range
16 value s \ step size

: crnd rnd r / ;
code c>d lsb lda,x $80 and,# 1 @@ beq,
$ff lda,# msb sta,x 1 @: ;code

0 value x
0 value y
: coord ( y x -- y x )
to x to y
x 15 * 64 + y -3 * +
y 2* 2* 2* 50 +
m y w* x + + c@ c>d 2/ 2/ + ;

: diamond  ( x y -- )
w* + m + dup \ nw nw
dup s + \ nw nw ne
dup s w* + \ nw nw ne se
dup s - \ nw nw ne se sw
c@ c>d swap c@ c>d + swap
c@ c>d + swap c@ c>d + 4 / \ nw avg
crnd + swap \ val nw
s 2/ + s 2/ w* + c! ;
: diamonds
w 1- 0 do w 1- 0 do
i j diamond s +loop s +loop ;

: get x y w* m + + + c@ c>d +
swap 1+ swap ;
: square ( x y -- )
to y to x 0 0 \ n sum
\ sample up
y s 2/ - -1 > if
s 2/ w* negate get then
\ sample down
y s 2/ + w < if s 2/ w* get then
\ sample left
x s 2/ - -1 > if s 2/ negate get then
\ sample right
x s 2/ + w < if s 2/ get then
swap / crnd +
m x + y w* + c! ;

: squares
w 0 do w s 2/ do
i j square s +loop s +loop
w s 2/ do w 0 do
i j square s +loop s +loop ;

: init-corners
crnd m c! \ nw
crnd m w 1- + c! \ ne
crnd m w dup * + 1- c! \ se
crnd m w dup 1- * + c! ; \ sw

: diamond-square
init-corners begin
s 1 > while s . diamonds squares
r 2* to r s 2/ to s repeat ;

: tri-nw ( y x -- )
2dup coord plot 2dup 1+ coord line 2dup
swap 1+ swap coord line coord line ;
: tri-sw ( y x -- )
2dup 1+ coord plot
2dup 1+ swap 1+ swap coord line
2dup swap 1+ swap coord line 1+
coord line ;
: wireframe w 1- 0 do w 1- 0 do
i j 2dup tri-nw tri-sw loop loop ;

: create-map
s" map" m loadb if
diamond-square
m m mapsize + s" map" saveb then ;

create-map
hex 52 clrcol hires
wireframe
key drop lores
