
data segment   
     
     FIRSTDIGIT DB 1 DUP(?) 
     STRING DB "STRING$"
     pkey db "press any key...$"
     clearASCII DB "                          "
     NUMBERS	DB 00111111b, 00000110b, 01011011b, 01001111b, 01100110b, 01101101b, 01111101b, 00000111b, 01111111b, 01101111b,
                DB 01110111b, 01111100b, 00111001b, 01011110b, 01111001b, 01110001b
ends

stack segment
    dw   128  dup(0)
ends

code segment 

; CHECK TEMPERATURE ;    
START   PROC    FAR

; Store return address to OS:
 	PUSH    DS
 	MOV     AX, 0
 	PUSH    AX

; set segment registers:
 	MOV     AX, data
 	MOV     DS, AX
 	MOV     ES, AX

; initialization

	MOV CX, 8	; initialize all seven segment displays to empty
	MOV DX, 2030h
	MOV AL, 00h   
	
INIT:	
    OUT DX, AL
	INC DX
	LOOP INIT
	
THERMOMETER:	
	MOV DX, 2086h	; read temperature (8-bit input)
	IN  AL, DX	
	
	MOV BL, AL	; BX now has the temperature
	MOV BH, 0
	
	; display temperature on seven segment (using hexadecimal)
	
	MOV DX, 2030h 	; output most significant 4-bits
	MOV SI, BX
	AND SI, 00F0h
	MOV CL, 4
	ROR SI, CL
	MOV AL, NUMBERS[SI]
	OUT DX, AL

	MOV DX, 2031h 	; output least significant 4-bits
	MOV SI, BX
	AND SI, 000Fh
	MOV AL, NUMBERS[SI]
	OUT DX, AL
	
	MOV DX, 2032h	; output 'h' indicating hexadecimal key
	MOV AL, 01110100b
	OUT DX, AL  	 
	
	MOV DX, 2070h
    MOV CX, 7 
	
    cmp BX, 04Eh     ;hex for 38
    JL GREEN
    jmp RED
    
RED:
	MOV AL, 049h 
    OUT DX, AL 
    JMP THERMOMETER 
    
GREEN:
    MOV AL, 024h 
    OUT DX, AL     	
	JMP NEXT ; infinit loop 
	
START   ENDP


; GET INPUT USING KEYBOARD    
NEXT:
      
    MOV CX, 6
    MOV BX, 2040h
    
;MAIN   
    ; reset buffer indicator to allow more keys
	MOV DX, 2083h
	MOV AL, 00h
	OUT DX, AL
	CALL KEYBOARD
	CALL DISPLAY_DIGIT
    CALL CHECKFILE
	CALL CLEARDISPLAY1
	CALL CLEARDISPLAY2
	CALL EXIT
    
KEYBOARD:  

    MOV DX, 2083h 	; input data from keyboard (if buffer has key)
	IN  AL, DX    
	CMP AL, 00h
	JE  KEYBOARD      	; buffer has no key, check again
	
	; a new key was pressed
	MOV DX, 2082h	; read key (8-bit input)
	IN  AL, DX	

	aam                 ;ASCII adjust after manipulation- divides AL by 10 and stores quotient to AH, Remainder to AL
    add ax, 3030h       ;adds 3030h to ax para maging ASCIIang hexadecimal
    
    CMP CX, 6
    JE PUSH_DIGIT

DISPLAY_DIGIT:
    
	MOV DX, BX	; ASCII Display
	out DX, AL
	INC BX
	
	; reset buffer indicator to allow more keys
	MOV DX, 2083h
	MOV AL, 00h
	OUT DX, AL
	                     
	LOOP KEYBOARD ; infinite loop
	RET 
	
PUSH_DIGIT:  
    PUSH BX
    MOV BX, AX  
    AND BL,0FH
    MOV FIRSTDIGIT, BL
    POP BX
    RET

CHECKFILE:
    MOV AH, 09
    LEA DX, STRING
    INT 21h 
    RET
    	
CLEARDISPLAY1:
	MOV DX, 2039h
	MOV SI, 0
	MOV CX, 48
	RET

CLEARDISPLAY2:
	MOV AL, clearASCII[SI]
	out DX,AL
	INC SI
	INC DX 
	LOOP CLEARDISPLAY2
	RET

EXIT:
    MOV AH, 4CH
    INT 21H

	
ends

end start ; set entry point and stop the assembler.