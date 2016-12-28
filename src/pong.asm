
    ; The PONG GAME

    *=$0801
    
    player_pos1	= $0334		; var char
    player_pos2 = $0335		; var char
    
    ball_posx	= $0336		; var float
    ball_posy	= $033b		; var float
    
    ball_dx		= $0340		; var float
    ball_dy		= $0345		; var float
    
    ball_posrx  = $034a		; var int
    ball_posry  = $034c		; var int
    
    ball_angle	= $034e		; var char	x15deg
    
    flag_goal1	= $034f		; var char
    flag_goal2	= $0350		; var char
    
    joy1		= $dc01
    joy2		= $dc00
    
    FACINX		= $b1aa
    MOVFM		= $ba8c
    MOVMF		= $bbd4
    FADD		= $b867
	INT			= $bccc
    
    var1		= $0351		; var char
    var2		= $0352		; var char
    
    ; basic loader "10 sys 2062"
    
    .byte $0c,$08,$0a,$00,$9e,$20,$32,$30,$36,$32,$00,$00,$00
    
    ; copy routine
    
    copy	.macro
			lda #<\1
			sta $5f
			lda #>\1
			sta $60
			lda #<\2
			sta $5a
			lda #>\2
			sta $5b
			lda #<\3
			sta $58
			lda #>\3
			sta $59
			jsr $a3bf
			.endm
			
	; add floats
	; arg1 float
	; arg2 float
	; result to first argument
	
	fladd	.macro
			pha
			tya
			pha
			txa
			pha
			lda #<\1
			ldy #>\1
			jsr MOVFM
			lda #<\2
			ldy #>\2
			jsr FADD
			ldx #<\1
			ldy #>\2
			jsr MOVMF
			pla
			tax
			pla
			tay
			pla
			.endm
			
	; convert float to integer
	; arg1 float
	; arg2 int
	; result to second argument
	
	toint	.macro
			pha
			tya
			pha
			txa
			pha
			lda #<\1
			ldy #>\1
			jsr MOVFM
			jsr INT
			jsr FACINX
			sta <\2
			sty >\2
			pla
			tax
			pla
			tay
			pla
			.endm
			
	; multiply 8-bit numbers
	; by White Flame (aka David Holz)
			
	mult8	.macro
			lda #$00
 			beq enterloop

		doadd
			clc
			adc \1

		loop
			asl \1
		enterloop
			lsr \2
			bcs doadd
			bne loop
			.endm

    ; setup screen

			lda #$00
			sta $d020
			sta $d021

    		ldx #$00

	clear	lda #$20
			sta $0400,x
			sta $0500,x 
			sta $0600,x 
			sta $06e8,x 
			lda #$0f
			sta $d800,x  
        	sta $d900,x
        	sta $da00,x
        	sta $dae8,x
        	inx
        	bne clear

    ; welcome screen

			.block
			ldx #39
			lda #$f9
		l1	sta $0400,x
			dex
			bpl l1

			ldx #39
			lda #$f8
		l2	sta $07c0,x
			dex
			bpl l2

			lda #$3b
			sta $fb
			lda #$04
			sta $fc

			ldy #$00
			
			ldx #12
		l3	lda #$76
			sta ($fb),y
			iny
			lda #$75
			sta ($fb),y
			dey

			lda $fb
			clc
			adc #80

			bcc noinc
			inc $fc
	noinc	sta $fb
			dex
			bne l3
			.bend

	; init sprites
	;
	; currently sprite shapes are stored at the
	; end of bank 1, thus the program has to fit
	; in ~15k
	; TODO: reconfigure vic if program grows
	;
	
			#copy player_left, player_left+192, $3fff

			.block
			lda #$fd		; sprite shapes
			sta $07f8
			lda #$fe
			sta $07f9
			lda #$ff
			sta $07fa
			
			lda #$07		; 3 sprites on
			sta $d015
			
			lda #$03		; players double height
			sta $d017
			
			lda #$00		; monochrome, single width
			sta $d01c
			sta $d01d
			
			lda #$0a		; colors
			sta $d027
			lda #$0e
			sta $d028
			lda #07
			sta $d029
			
			lda #120		; initial positions
			sta player_pos1
			sta player_pos2
			
			ldx #$05
		l1	lda ball_init_x-1,x			
			sta ball_posx-1,x
			lda ball_init_y-1,x
			sta ball_posy-1,x
			dex
			bne l1
						
			lda #$00
			sta $d01b
			
			lda #$02
			sta ball_angle
		
			jsr sprpos
			rts
			.bend

    ; start game
    
    		; clear goals
    		
    		lda #$00
    		
    		sta flag_goal1;
    		sta flag_goal2;
    		
    		; update ball direction
    		jsr update_ball_dir
    
		    ; set raster interrupt

			lda #%01111111
			sta $dc0d
			and $d011
			sta $d011
			lda #$00
			sta $d012
			lda #<gloop
			sta $0314
			lda #>gloop
			sta $0315
			lda #%00000001
			sta $d01a
		
	eloop
			jmp eloop
	
	; game loop
	; get joystick movements
	; set player positions
	; set ball speed vectors

	gloop
			lda #$01		; debug
			sta $d020		; debug

				
			lda #%00000001
			bit joy1
			bne p1down
			lda player_pos1
			cmp #$37
			beq p1down
			dec player_pos1
			jmp p2up
	p1down
			lda #%00000010	
			bit joy1
			bne p2up
			lda player_pos1
			cmp #$cd
			beq p2up
			inc player_pos1
	p2up
			lda #%00000001
			bit joy2
			bne p2down
			lda player_pos2
			cmp #$37
			beq p2down
			dec player_pos2
			jmp plend
	
	p2down
			lda #%00000010	
			bit joy2
			bne plend
			lda player_pos2
			cmp #$cb
			beq plend
			inc player_pos2

	plend
			
			#fladd ball_posx, ball_dx
			#fladd ball_posy, ball_dy
	
			jsr sprpos
			
			lda #$00		; debug
			sta $d020		; debug
			
			asl $d019
			jmp $ea81


	; sprite positioning
	
	sprpos	
			.block
			lda #08
			sta $d000
			lda player_pos1
			sta $d001
			
			lda #72
			sta $d002
			lda player_pos2
			sta $d003
			
			#toint ball_posx, ball_posrx
			#toint ball_posy, ball_posry
			
			lda ball_posrx
			sta $d004
			
			lda ball_posry
			sta $d005

			ldx #$02			
			lda ball_posrx+1
			beq	skip
			ldx #$06

	skip	stx $d010
	
	cont4    lda #%00010000 ; mask joystick button push 
         bit $dc00      ; bitwise AND with address 56320
         bne cont4

			; check for border collision
			lda ball_posy
			sta $d021			
			;cmp #$37
			;bmi border_collision
			;cmp #$cd
			;bne border_collision
			
			; check for goal
			;lda ball_posx
			
			; check for player_collision
	
	end_sprpos
			rts
			
	border_collision
			ldx ball_angle
			lda wall_bounces,x
			sta ball_angle
			jsr update_ball_dir
			jmp end_sprpos
			
			.bend
			
	; take the ball angle and
	; update the ball direction x and y vectors
			
	update_ball_dir
			.block
			ldx #$05
			stx var1
			#mult8 ball_angle, var1
			tax
			
			lda xvectors,x
			sta ball_dx
			lda yvectors,x
			sta ball_dy
			rts		
			.bend
	
	player_collision
			

    ; Sprites
    ; ------------------

    player_left		.repeat 21, $ff,$00,$00
    				.byte $00

    player_right	.repeat 21, $00,$00,$ff
    				.byte $00
    				
    ball			.repeat 8,  $ff,$00,$00
					.repeat 13, $00,$00,$00
					.byte $00
					
	; Constants
	; ------------------

	ball_init_x		.byte $87,$32,$00,$00,$00	
	ball_init_y		.byte $87,$70,$00,$00,$00
	
	bounce_angles1	.byte 7,8,9,10,11,12,13,14,15,16,17
	bounce_angles2	.byte 5,4,3,2,1,0,23,22,21,20,19
	wall_bounces	.byte 12,11,10,9,8,7,6,5,4,3,2,1,0
					.byte 23,22,21,20,19,18,17,16,15,14,13
	
		xvectors	.byte $00,$49,$0f,$da,$a2
					.byte $81,$04,$83,$ee,$0c
					.byte $81,$7f,$ff,$ff,$ff
					.byte $82,$35,$04,$f3,$34
					.byte $82,$5d,$b3,$d7,$42
					.byte $82,$77,$46,$ea,$39
		
		yvectors	.byte $82,$7f,$ff,$ff,$ff
					.byte $82,$77,$46,$ea,$3a
					.byte $82,$5d,$b3,$d7,$44
					.byte $82,$35,$04,$f3,$36
					.byte $82,$00,$00,$00,$02
					.byte $81,$04,$83,$ee,$11
					.byte $00,$49,$0f,$da,$a2 
					.byte $81,$84,$83,$ee,$11
					.byte $81,$ff,$ff,$ff,$fc
					.byte $82,$b5,$04,$f3,$34
					.byte $82,$dd,$b3,$d7,$41
					.byte $82,$f7,$46,$ea,$39
					.byte $82,$ff,$ff,$ff,$fe 
					.byte $82,$f7,$46,$ea,$3b
					.byte $82,$dd,$b3,$d7,$47
					.byte $82,$b5,$04,$f3,$39
					.byte $82,$80,$00,$00,$02
					.byte $81,$84,$83,$ee,$1d
		
		rvectors	.byte $00,$49,$0f,$da,$a2
					.byte $81,$04,$83,$ee,$0c
					.byte $81,$7f,$ff,$ff,$ff
					.byte $82,$35,$04,$f3,$34
					.byte $82,$5d,$b3,$d7,$42
					.byte $82,$77,$46,$ea,$39					


					
