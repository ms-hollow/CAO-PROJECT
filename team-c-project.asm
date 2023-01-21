

start:

    MOV CX, 2040h
  
KEYBOARD:
    MOV DX, 2083h 	; input data from keyboard (if buffer has key)
	IN  AL, DX    
	CMP AL, 00h
	JE  KEYBOARD      	; buffer has no key, check again
	
	; a new key was pressed
	MOV DX, 2082h	; read key (8-bit input)
	IN  AL, DX	
	
	MOV BL, AL	; BX now has the key
	MOV BH, 0   
	
	aam                 ;ASCII adjust after manipulation- divides AL by 10 and stores quotient to AH, Remainder to AL
    add ax, 3030h       ;adds 3030h to ax para maging ASCIIang hexadecimal
	       
;ASCII LCD
    
	MOV DX, CX	; ASCII Display
	OUT DX, AL
	INC CX
	
	; reset buffer indicator to allow more keys
	MOV DX, 2083h
	MOV AL, 00h
	OUT DX, AL
	
	JMP KEYBOARD ; infinite loop    

ends

end start ; set entry point and stop the assembler.

