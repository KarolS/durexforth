

:asm (do)
2 lda,x pha, 3 lda,x pha,
0 lda,x pha, 1 lda,x pha,
inx, inx, inx, inx, ;asm

: do ( limit first -- ) immed
' (do) , here ;

: loop immed
' r> , ' 1+ , ' r> , ' 2dup , ' < ,
[compile] while ' >r , ' >r ,
[compile] repeat ' 2drop , ;

: +loop immed
' r> , ' + , ' r> , ' 2dup , ' < ,
[compile] while ' >r , ' >r ,
[compile] repeat ' 2drop , ;

: i immed ' r@ , ;
:asm j txa, tsx,
106 ldy,x zptmp sty, 105 ldy,x
tax, dex, dex,
1 sty,x zptmp lda, 0 sta,x ;asm

( : test
sp@
2 0 do 2 0 do loop loop
sp@ 2+ = if exit then
begin 1 d020 +! again ; test )
