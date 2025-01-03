STACK SEGMENT PARA STACK 				;begin of stack segment definition, para = paragraph
	DB 64 DUP (' ') 					;duplicate empty string to take all the bytes of the stack (64 bytes)
STACK ENDS 								;end of stack segment definition

DATA SEGMENT PARA 'DATA' 				;begin of data segment definition
	
	WINDOW_WIDTH DW 140h				;width of window(320px)
	WINDOW_HEIGHT DW 0C8h				;height of window(200px)
	WINDOW_BOUNDS DW 6					;variable used to check collisions early
	TIME_AUX DB 0						;variable used when checking if the time has changed
	
	BALL_INIT_X DW 0A0h					;initial x (column) value of the ball
	BALL_INIT_Y DW 64h					;initial y (row) value of the ball
	
	BALL_X DW 0A0h 						;x position (column) of ball
	BALL_Y DW 064h						;y position (row) of ball
	BALL_SIZE DW 04h					;size of ball (how many pixels does the ball have on width and height)
	BALL_VELOCITY_X DW 05h				;x velocity of the ball (horizontal)
	BALL_VELOCITY_Y DW 02h				;y velocity of the ball (vertical)
	
	BAR_HEIGHT DW 2Ah					;height of the bars
	BAR_WIDTH DW 03h					;width of the bars
	
	BAR_LEFT_X DW 0Ah					;initial x position of the left bar
	BAR_LEFT_Y DW 0Ah					;initial y position of the left bar
	
	BAR_RIGHT_X DW 130h					;initial x position of the right bar
	BAR_RIGHT_Y DW 0Ah					;initial y position of the right bar
	
	BAR_VELOCITY DW 0Ah					;velocity of the two bars
	

DATA ENDS 								;end of data segment definition

CODE SEGMENT PARA 'CODE' 				;begin of code segment named CODE definition

	MAIN PROC FAR 						;begin of MAIN procedure which is set to far (to be called from another segment)
	ASSUME CS:CODE,DS:DATA,SS:STACK		;assume as code, data and stack segments the respective registers
	PUSH AX								;store old AX value in stack
	MOV AX, DATA						;save on AX register the content of DATA segment
	MOV DS, AX							;save on DS segment the contents of AX
	POP AX								;restore old AX value
		
		CALL CLEAR_SCREEN
		
		CHECK_TIME:
			MOV AH, 2Ch					;get the system time
			INT 21h						;CH = hour(0 to 23) CL = minute (0 to 59) DH = second (0 to 59) DL = centiseconds (0 to 99)
			
			CMP DL, TIME_AUX			;is current time equals to the previous one (TIME_AUX)?
			JE CHECK_TIME				;if it is the same time, check again
			
;			if it's different, then reach this line and draw
			MOV TIME_AUX, DL			;update time to current time
			
			
			
			CALL CLEAR_SCREEN			;clear the screen
			CALL MOVE_BALL				;move the ball
			CALL DRAW_BALL				;draw the ball
			
			CALL MOVE_BARS				;move the bars
			CALL DRAW_BARS				;draw the bars
			
			
			JMP CHECK_TIME				;after everything, check time again
		
		RET
	MAIN ENDP
	
	MOVE_BALL PROC NEAR					;process ball movement
	
;		Move the ball horizontally
		MOV AX, BALL_VELOCITY_X 		;store ball x velocity to temp register AX
		ADD BALL_X, AX					;add the velocity to the current x value

;		Check if the ball passed left boundaries
;		If it's colliding, restart its position
		MOV AX, BALL_X					;store ball x position
		CMP AX, WINDOW_BOUNDS			;BALL_X < 0 + WINDOW_BOUNDS (y-> collision left)
		JGE	SKIP_R						;if it's less, negative the x velocity
		JMP RESTART_BALL
		SKIP_R:

;		Check if the ball passed right boundaries
;		If it's colliding, restart it's position
		MOV AX, WINDOW_WIDTH				
		SUB AX, BALL_SIZE
		SUB AX, WINDOW_BOUNDS
		CMP BALL_X, AX					;BALL_X >= WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS (y-> collision right)
		JLE SKIP_RESTART_BALL					;if greater, negative the x velocity
		JMP RESTART_BALL
		SKIP_RESTART_BALL:
				
;		Move the ball vertically
		MOV AX, BALL_VELOCITY_Y			;store y velocity to temp register AX
		ADD BALL_Y, AX					;add the velocity to the current y value
		
;		Check if the ball passed top boundaries
;		If it's colliding, reverse it's direction
		CMP BALL_Y, 00h					;BALL_X < 0 + WINDOW_BOUNDS (y-> collision left)
		JGE	SKIP_NEG_V					;if it's less, negative the x velocity
		JMP NEG_VELOCITY_Y
		SKIP_NEG_V:

;		Check if the ball passed bottom boundaries
;		If it's colliding, reverse it's direction
		MOV AX, WINDOW_HEIGHT			;move window height to AX
		SUB AX, BALL_SIZE				;subtract ball size from it
		SUB AX, WINDOW_BOUNDS			;subtract window bounds from it
		CMP BALL_Y, AX					;BALL_Y >= WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS (y-> collision right)
		JG NEG_VELOCITY_Y				;if greater, negative the y velocity
		
;		Using AABBs boxes method
;		Check if the ball is colliding with the right bar		
;		maxx1 				> minx2 	 && minx1  < maxx2 			 		 && maxy1 			   > miny2       && miny1  < maxy2
;		ball_x + ball_size > right_bar_x && ball_x < right_bar_x + bar_width && ball_y + ball_size > bar_right_y && ball_y < right_bar_y + bar_height
		MOV AX, BALL_X
		ADD AX, BALL_SIZE
		CMP AX, BAR_RIGHT_X
		JNGE CHECK_COLLISION_WITH_LEFT_BAR
		
		MOV AX, BAR_RIGHT_X
		ADD AX, BAR_WIDTH
		CMP BALL_X, AX
		JNLE CHECK_COLLISION_WITH_LEFT_BAR
		
		MOV AX, BALL_Y
		ADD AX, BALL_SIZE
		CMP BAR_RIGHT_Y, AX
		JNLE CHECK_COLLISION_WITH_LEFT_BAR
		
		MOV AX, BAR_RIGHT_Y
		ADD AX, BAR_HEIGHT
		CMP BALL_Y, AX
		JNLE CHECK_COLLISION_WITH_LEFT_BAR

;		If it reaches here, then it's colliding
		NEG BALL_VELOCITY_X
		
		RET
		
;		Check if the ball is colliding with the left bar
;		maxx1 				> minx2 	 && minx1  < maxx2 			 		 && maxy1 			   > miny2       && miny1  < maxy2
;		ball_x + ball_size > left_bar_x && ball_x < left_bar_x + bar_width && ball_y + ball_size > bar_left_y && ball_y < left_bar_y + bar_height
		CHECK_COLLISION_WITH_LEFT_BAR:
			
			MOV AX, BALL_X
			ADD AX, BALL_SIZE
			CMP AX, BAR_LEFT_X
			JNG EXIT_COLLISION
			
			MOV AX, BAR_LEFT_X
			ADD AX, BAR_WIDTH
			CMP BALL_X, AX
			JNL EXIT_COLLISION
			
			MOV AX, BALL_Y
			ADD AX, BALL_SIZE
			CMP BAR_LEFT_Y, AX
			JNL EXIT_COLLISION
			
			MOV AX, BAR_LEFT_Y
			ADD AX, BAR_HEIGHT
			CMP BALL_Y, AX
			JNL EXIT_COLLISION
			
;			If it reaches here, then collision happened
			NEG BALL_VELOCITY_X			;reverse the ball horizontal velocity
			RET
		
		NEG_VELOCITY_Y:					;reverses the ball direction
			NEG BALL_VELOCITY_Y 		;BALL_VELOCITY_Y = -BALL_VELOCITY_Y
		EXIT_COLLISION:
			RET
		RET
		
	MOVE_BALL ENDP
	
	RESTART_BALL PROC NEAR				;resets the ball to the intial value (ball_init(x/y))
		MOV AX, BALL_INIT_X
		MOV BALL_X, AX
		MOV AX, BALL_INIT_Y
		MOV BALL_Y, AX
		RET
	RESTART_BALL ENDP
	
	MOVE_BARS PROC NEAR					;movement of bars
	
;		left paddle movement
;		check if any key is being pressed (if not, check the other paddle)
		MOV AH, 01h
		INT 16h
		JZ CHECK_RIGHT_BAR_MOVEMENT				;ZF = 1, JZ -> jump if zero
		
;		check which key is being pressed (AL = ASCII character)
		MOV AH, 00h
		INT 16h
		
;		if it is 'w (77h)' or 'W (57h)' move up
		CMP AL, 77h			;'w'
		JE MOVE_LEFT_BAR_UP
		CMP AL, 57h			;'W'
		JE MOVE_LEFT_BAR_UP
		
		CMP AL, 73h			;'s'
		JE MOVE_LEFT_BAR_DOWN
		CMP AL, 53h			;'S'
		JE MOVE_LEFT_BAR_DOWN
		
		;if neither up or down
		JMP CHECK_RIGHT_BAR_MOVEMENT
		
		
		MOVE_LEFT_BAR_UP:
			MOV AX, BAR_VELOCITY				;store velocity in AX
			SUB BAR_LEFT_Y, AX					;subtract velocity from bar y position (to go up)
			
			MOV AX, WINDOW_BOUNDS				;store window bounds to AX to check for overflow
			CMP BAR_LEFT_Y, AX					;check if bar has reached the top bounds
			JL FIX_BAR_TOP_BOUNDS				;if exceeded top bounds, make it stop
			
			JMP CHECK_RIGHT_BAR_MOVEMENT		;else, check the right bar movement
			
			FIX_BAR_TOP_BOUNDS:
				MOV AX, WINDOW_BOUNDS			;move window bounds to AX
				MOV BAR_LEFT_Y, AX				;set bar y to window bounds
				JMP CHECK_RIGHT_BAR_MOVEMENT	;check the right bar movement
		
		MOVE_LEFT_BAR_DOWN:
			MOV AX, BAR_VELOCITY				;store velocity in AX
			ADD BAR_LEFT_Y, AX					;add velocity to current y value
			
			MOV AX, WINDOW_HEIGHT				;store window height to AX
			SUB AX, WINDOW_BOUNDS				;subtract window height from current bar y
			SUB AX, BAR_HEIGHT					;subtract bar height (equation now is window_height - window_bounds -  bar_height)
			CMP BAR_LEFT_Y, AX					;compare bar y to the above equation
			
			JG FIX_BAR_BOT_BOUNDS				;if greater, make it stop
			JMP CHECK_RIGHT_BAR_MOVEMENT
			
			FIX_BAR_BOT_BOUNDS:
				MOV BAR_LEFT_Y,AX				;make it stop(at the last AX value)
				JMP CHECK_RIGHT_BAR_MOVEMENT	;check right bar movement

		
;		right bar movement
		CHECK_RIGHT_BAR_MOVEMENT:
			
;			check which key is being pressed			
;			if it is 'O (4F)' or 'o (6F)' move up
			CMP AL, 4Fh
			JE MOVE_RIGHT_BAR_UP
			CMP AL, 6Fh
			JE MOVE_RIGHT_BAR_UP
			
;			if it is 'l (6C)' or 'L (4C)' move down
			CMP AL, 6Ch
			JE MOVE_RIGHT_BAR_DOWN
			CMP AL, 4Ch
			JE MOVE_RIGHT_BAR_DOWN
			
			
			JMP EXIT_BAR_MOVEMENT				;if it's neither of the two keys, exit
			
			MOVE_RIGHT_BAR_UP:
				MOV AX, BAR_VELOCITY			;BAR_RIGHT_Y += BAR_VELOCITY
				SUB BAR_RIGHT_Y, AX
				
				;check if it exceeded the limit
				MOV AX, WINDOW_BOUNDS			;bar y > window bounds
				CMP BAR_RIGHT_Y, AX				;if bar y <= window bounds
				JL FIX_RIGHT_BAR_TOP_BOUNDS
				JMP EXIT_BAR_MOVEMENT
				
				FIX_RIGHT_BAR_TOP_BOUNDS:
					MOV BAR_RIGHT_Y, AX
					JMP EXIT_BAR_MOVEMENT
			
			MOVE_RIGHT_BAR_DOWN:
				MOV AX, BAR_VELOCITY
				ADD BAR_RIGHT_Y, AX
				
				;check if it exceeded the limits
				;bar y + bar height >= WINDOW_HEIGHT - WINDOW_BOUNDS ? return
				MOV AX, WINDOW_HEIGHT
				SUB AX, WINDOW_BOUNDS
				SUB AX, BAR_HEIGHT
				CMP BAR_RIGHT_Y, AX
				JG FIX_RIGHT_BAR_BOT_BOUNDS
				JMP EXIT_BAR_MOVEMENT
				
				FIX_RIGHT_BAR_BOT_BOUNDS:
					MOV BAR_RIGHT_Y, AX
					JMP EXIT_BAR_MOVEMENT
				
			
			EXIT_BAR_MOVEMENT:
				RET
			
	MOVE_BARS ENDP
	
	
	
	DRAW_BARS PROC NEAR
		MOV CX, BAR_LEFT_X
		MOV DX, BAR_LEFT_Y
		
		DRAW_BAR_LEFT_HORIZONTAL:		
			MOV AH, 0Ch 	;set the configuartion to write a pixel
			MOV AL, 05h 	;set pixel color
			MOV BH, 0h		;set page number
			INT 10h			;execute 10h interrupt which writes a white pixel
			
			INC CX 			;CX += 1
			;check if we reached the column limit
			MOV AX, CX					;move new column to AX register
			SUB AX, BAR_LEFT_X			;subtract intial column value from the new column value
			CMP AX, BAR_WIDTH			;compare to the bar size
			JNG DRAW_BAR_LEFT_HORIZONTAL 	;if smaller or equal bar size, continue drawing columns, if not, continue the code below (check for rows)
			
			MOV CX, BAR_LEFT_X			;reset column register to the initial value
			INC DX						;increment rows by 1
			;check if we reached vertical limit
			MOV AX, DX					;save on AX register the new row value
			SUB AX, BAR_LEFT_Y 			;subtract the new row with initial row value
			CMP AX, BAR_HEIGHT			;compare to the bar size
			JNG DRAW_BAR_LEFT_HORIZONTAL;if smaller or equal bar size, go draw all columns for this row
		
		
		MOV CX, BAR_RIGHT_X
		MOV DX, BAR_RIGHT_Y
		
		DRAW_BAR_RIGHT_HORIZONTAL:		
			MOV AH, 0Ch 	;set the configuartion to write a pixel
			MOV AL, 05h 	;set pixel color
			MOV BH, 0h		;set page number
			INT 10h			;execute 10h interrupt which writes a white pixel
			
			INC CX 			;CX += 1
			;check if we reached the column limit
			MOV AX, CX					;move new column to AX register
			SUB AX, BAR_RIGHT_X			;subtract intial column value from the new column value
			CMP AX, BAR_WIDTH			;compare to the bar size
			JNG DRAW_BAR_RIGHT_HORIZONTAL 	;if smaller or equal bar size, continue drawing columns, if not, continue the code below (check for rows)
			
			MOV CX, BAR_RIGHT_X			;reset column register to the initial value
			INC DX						;increment rows by 1
			;check if we reached vertical limit
			MOV AX, DX					;save on AX register the new row value
			SUB AX, BAR_RIGHT_Y 			;subtract the new row with initial row value
			CMP AX, BAR_HEIGHT			;compare to the bar size
			JNG DRAW_BAR_RIGHT_HORIZONTAL;if smaller or equal bar size, go draw all columns for this row
		RET
	DRAW_BARS ENDP
	
	NEG_VELOCITY_X PROC NEAR
		NEG BALL_VELOCITY_X 	;BALL_VELOCITY_X = -BALL_VELOCITY_X
		RET
	NEG_VELOCITY_X ENDP
		
	CLEAR_SCREEN PROC NEAR
		MOV AX, 0013h ; set video mode (AH = 00, AL = 13h)
		INT 10h 	; execute 10h interrupt which loads video mode of AX
		
		MOV AH, 0Bh ; set configuration to background color
		MOV BH, 00h
		MOV BL, 00h ; black background color
		INT 10h		; execute 10h interrupt which changes backgorund color
		
		RET
	CLEAR_SCREEN ENDP
	
	DRAW_BALL PROC NEAR
		
		;write graphics pixel
		MOV CX, BALL_X 	;set initial x-axis pos
		MOV DX, BALL_Y 	;set initial y-axis pos
		
		DRAW_BALL_HORIZONTAL:		
			MOV AH, 0Ch 	;set the configuartion to write a pixel
			MOV AL, 0Fh 	;set pixel color
			MOV BH, 0h		;set page number
			INT 10h			;execute 10h interrupt which writes a white pixel
			
			INC CX 			;CX += 1
			;check if we reached the column limit
			MOV AX, CX					;move new column to AX register
			SUB AX, BALL_X				;subtract intial column value from the new column value
			CMP AX, BALL_SIZE			;compare to the ball size
			JNG DRAW_BALL_HORIZONTAL 	;if smaller or equal ball size, continue drawing columns, if not, continue the code below (check for rows)
			
			MOV CX, BALL_X				;reset column register to the initial value
			INC DX						;increment rows by 1
			;check if we reached vertical limit
			MOV AX, DX					;save on AX register the new row value
			SUB AX, BALL_Y 				;subtract the new row with initial row value
			CMP AX, BALL_SIZE			;compare to the ball size
			JNG DRAW_BALL_HORIZONTAL	;if smaller or equal ball size, go draw all columns for this row
		RET
	DRAW_BALL ENDP

CODE ENDS
END