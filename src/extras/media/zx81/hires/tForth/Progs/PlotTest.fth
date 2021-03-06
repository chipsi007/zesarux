\ -----------------------------------------------------------------------
\  Test the PLOT word with the Bresenham's_line_algorithm
\  http://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm#Forth
\ -----------------------------------------------------------------------

: TASK ;

CODE 2SWAP HEX
  E1 C,          \ pop hl          ; bc=x4, hl=x3
  D9 C,          \ exx
  C1 C,          \ pop  bc
  E1 C,          \ pop  hl         ; bc'=x2, hl'=x1
  D9 C,          \ exx
  E5 C,          \ push hl
  C5 C,          \ push bc
  D9 C,          \ exx
  E5 C,          \ push hl
  C5 C,          \ push bc
  D9 C,          \ exx
  C1 C,          \ pop  bc
  NEXT           \ jp NEXT

CODE 2OVER
  D9 C,          \ exx
  E1 C,          \ pop hl
  D1 C,          \ pop de
  C1 C,          \ pop bc
  C5 C,          \ push bc
  D5 C,          \ push de
  E5 C,          \ push hl
  D9 C,          \ exx
  C5 C,          \ push bc
  D9 C,          \ exx
  C5 C,          \ push bc
  D5 C,          \ push de
  D9 C,          \ exx
  C1 C,          \ pop  bc
  NEXT           \ jp NEXT
DECIMAL

: [COMPILE]  ( -- )
   ' ,
; IMMEDIATE

\ Create value
: VALUE ( x "<spaces>name" -- )
   CONSTANT
;

: TO  ( x "<spaces>name" -- )
   '              ( get the name of the value )
   3 +            ( increment to point at the value )
   STATE @        ( compiling? )
   IF
      COMPILE LIT ( compile LIT )
      ,           ( compile the address of the value )
      COMPILE !   ( compile ! )
   ELSE           ( immediate mode )
      !           ( update it straightaway )
   THEN
; IMMEDIATE

\ Find word & compile as literal
: [']  ( -- )
   ' LIT LIT , ,
; IMMEDIATE

\ define deferred word
: DEFER  ( "name" -- )
   CREATE ['] ABORT ,
DOES>
   @ EXECUTE
;

\ set a deferred word
: IS ( xt "<spaces>name" -- )
   [COMPILE] TO
; IMMEDIATE

\ ACE PLOT routine
\ Plots pixel (x, y) with plot mode n.
\ n = 0       unplot
\     1       plot
\     2       move
\     3       change

HEX
CODE SETGR   \ moves graphics chars from ROM to UDG memory
  D5 C,              \ push de        ; save IP
  21 C, 1E08 ,       \ ld hl,$1e08
  11 C, 3008 ,       \ ld de,$3008
  01 C, 38 ,         \ ld bc,$0038
  ED C, B0 C,        \ ldir
  D1 C,              \ pop de         ; restore IP
  NEXT               \ jp NEXT

SETGR

CODE PLOT  ( x y n -- )
  C5 C,              \ push bc
  D9 C,              \ exx
  C1 C,              \ pop bc         ; n
  D1 C,              \ pop de         ; y
  FD C, 73 C, 36 C,  \ ld (iy+$36),e  ; YCOORD
  3E C, 2F C,        \ ld a,$2F       ; 47-y
  93 C,              \ sub e          ;
  1F C,              \ rra            ; (47-y)/2
  CB C, 11 C,        \ rl c           ; n*2+cy
  D1 C,              \ pop de         ; x
  FD C, 73 C, 37 C,  \ ld (iy+$37),e  ; XCOORD
  CB C, 3B C,        \ srl e          ; x/2
  CB C, 11 C,        \ rl c           ; (n*2)*2
  47 C,              \ ld b,a
  7B C,              \ ld a,e
  04 C,              \ inc b          ; range 1 to 24
  21 C, 4071 ,       \ ld hl,$4071    ; Dfile-33
  11 C, 21 ,         \ ld de,$21      ; (y/2)*33
  19 C,              \ add hl,de      ; 
  10 C, FD C,        \ djnz -3        ; 
  5F C,              \ ld e,a         ; (y/2)*33+x/2
  19 C,              \ add hl,de      ; 
  7E C,              \ ld a,(hl)
  07 C,              \ rlca
  FE C, 10 C,        \ cp $10
  7E C,              \ ld a,(hl)
  38 C, 01 C,        \ jr c,+1
  AF C,              \ xor a
  5F C,              \ ld e,a
  16 C, 87 C,        \ ld d,$87
  79 C,              \ ld a,c
  2F C,              \ cpl
  E6 C, 03 C,        \ and $03
  47 C,              \ ld b,a
  28 C, 07 C,        \ jr z,+7
  2F C,              \ cpl
  C6 C, 02 C,        \ add a,$02
  CE C, 03 C,        \ adc a,$03
  57 C,              \ ld d,a
  43 C,              \ ld b,e
  79 C,              \ ld a,c
  0F C,              \ rrca
  0F C,              \ rrca
  0F C,              \ rrca
  9F C,              \ sbc a,a
  CB C, 59 C,        \ bit 3,c
  20 C, 04 C,        \ jr nz,+4
  AB C,              \ xor e
  07 C,              \ rlca
  9F C,              \ sbc a,a
  A8 C,              \ xor b
  A2 C,              \ and d
  AB C,              \ xor e
  77 C,              \ ld (hl),a
  D9 C,              \ exx
  C1 C,              \ pop bc
  NEXT               \ jp NEXT
DECIMAL

DEFER STEEP         \ NOOP or SWAP
DEFER YSTEP         \ 1+ or 1-

0 VALUE Y  0 VALUE DELTAY  0 VALUE DELTAX  0 VALUE COLOR
 
: NOOP ;

: LINE ( x0 y0 x1 y1 color -- )
  TO COLOR
  ROT SWAP
  ( x0 x1 y0 y1 )
  2DUP  - ABS >R
  2OVER - ABS R> <
  IF         ['] SWAP   \ swap use of x and y
  ELSE 2SWAP ['] NOOP
  THEN       IS STEEP
  ( y0 y1 x0 x1 )
  2DUP >
  IF SWAP 2SWAP SWAP    \ ensure x1 > x0
  ELSE    2SWAP
  THEN
  ( x0 x1 y0 y1 )
  2DUP >
  IF   ['] 1-
  ELSE ['] 1+
  THEN IS YSTEP
  OVER - ABS    TO DELTAY TO Y
  SWAP 2DUP - DUP TO DELTAX
  2/ ROT 1+ ROT
  ( error x1+1 x0 )
  DO  I Y STEEP COLOR PLOT
      DELTAY -
      DUP 0<
      IF   Y YSTEP TO Y
           DELTAX +
      THEN
  LOOP
  DROP ;

: MOIRE  ( -- )
   64 0
   DO
    0 0 I 47 3 LINE
    63 47 63 I - 0 3 LINE
   LOOP
;

MOIRE KEY DROP
 