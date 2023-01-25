name "printer"

data segment   
     
     FIRSTDIGIT DB 1 DUP(?) 
     STRING1 DB "VALID$"   
     STRING2 DB "INVALID$"
     SLASH DB "\"
     SDATE DB "DATE: "
     ;pkey db "press any key...$"
     clearASCII DB "                                                      "
     NUMBERS	DB 00111111b, 00000110b, 01011011b, 01001111b, 01100110b, 01101101b, 01111101b, 00000111b, 01111111b, 01101111b,
                DB 01110111b, 01111100b, 00111001b, 01011110b, 01111001b, 01110001b    
     
     msg db "Magandang Araw!", 0Ah, 0Dh
     db "Ang iyong anak na si (PANGALAN) ", 0Ah, 0Dh      
     db "ay ligtas nang nakarating sa Technological University of the Philippines - MANILA", 0Ah, 0Dh
     db "sa oras na (INSERT TIME). ", 0Ah, 0Dh
     db "Maraming Salamat", 0Ah, 0Dh
     db 13, 9    ; carriage return and vertical tab 
     prompt  DB "Time:"    
     time DB "00:00:00",0 
     ;        01234567 -index       
ends

stack segment
    dw   128  dup(0)
ends

code segment 

; CHECK TEMPERATURE     
CHECK_TEMP   PROC    FAR

    ; Store return address to OS:
 	PUSH    DS
 	MOV     AX, 0
 	PUSH    AX

    ; set segment registers:
 	MOV     AX, data
 	MOV     DS, AX
 	MOV     ES, AX

    ; initialize all seven segment displays to empty
	MOV CX, 8	
	MOV DX, 2030h
	MOV AL, 00h   
	
INIT:	
    OUT DX, AL
	INC DX
	LOOP INIT
	
THERMOMETER:	
	MOV DX, 2086h	    ; read temperature (8-bit input)
	IN  AL, DX	
	
	MOV BL, AL	        ; BX now has the temperature
	MOV BH, 0
	
	; display temperature on seven segment (using hexadecimal)
	MOV DX, 2030h 	    ; output most significant 4-bits
	MOV SI, BX
	AND SI, 00F0h
	MOV CL, 4
	ROR SI, CL
	MOV AL, NUMBERS[SI]
	OUT DX, AL

	MOV DX, 2031h 	    ; output least significant 4-bits
	MOV SI, BX
	AND SI, 000Fh
	MOV AL, NUMBERS[SI]
	OUT DX, AL
	
	MOV DX, 2032h	    ; output 'h' indicating hexadecimal key
	MOV AL, 01110100b
	OUT DX, AL  	 
	
	MOV DX, 2070h
    MOV CX, 7 
	
    CMP BX, 04Eh        ;hex for 38
    JL GREEN
    JMP RED
    
RED:
	MOV AL, 049h 
    OUT DX, AL 
    JMP EXIT
    
GREEN:
    MOV AL, 024h 
    OUT DX, AL     	
	JMP GET_ID          ; infinit loop 
	
CHECK_TEMP  ENDP


; GET INPUT USING KEYBOARD    
GET_ID:    
    
    ; reset LEDs OUTPUT
    MOV DX, 2070h
    MOV AL, 00h
    OUT DX, AL
    
    ; reset buffer indicator to allow more keys
	MOV DX, 2083h
	MOV AL, 00h
	OUT DX, AL
	  
    MOV CX, 6
    MOV BX, 2040h
    
    ;MAIN   
	CALL KEYBOARD
	CALL DISPLAY_DIGIT
    CALL VERIFY
	CALL CLEARDISPLAY1
	CALL CLEARDISPLAY2
	CALL DISPLAY_TIME
	CALL SDATE1 
	CALL SDATE2
    CALL DISPLAY_DATE
	;CALL START_PRINT
	;CALL PRINT
	CALL EXIT
    
KEYBOARD:  

    MOV DX, 2083h 	    ; input data from keyboard (if buffer has key)
	IN  AL, DX    
	CMP AL, 00h
	JE  KEYBOARD      	; buffer has no key, check again
	
	; a new key was pressed
	MOV DX, 2082h	    ; read key (8-bit input)
	IN  AL, DX	

	AAM                 ;ASCII adjust after manipulation- divides AL by 10 and stores quotient to AH, Remainder to AL
    ADD ax, 3030h       ;adds 3030h to ax para maging ASCIIang hexadecimal
    
    CMP CX, 6
    JE PUSH_DIGIT

DISPLAY_DIGIT:
    
	MOV DX, BX	        ; ASCII Display
	OUT DX, AL
	INC BX
	
	; reset buffer indicator to allow more keys
	MOV DX, 2083h
	MOV AL, 00h
	OUT DX, AL
	                     
	LOOP KEYBOARD       ; infinite loop
	RET 
	
PUSH_DIGIT:  
    PUSH BX
    MOV BX, AX  
    AND BL,0FH
    MOV FIRSTDIGIT, BL
    POP BX
    RET

VERIFY:
    
    CMP FIRSTDIGIT, 01h
    JE VALID
    CMP FIRSTDIGIT, 02h
    JE VALID
    JG INVALID    
    RET

VALID: 
    
    MOV DX, 2070h 
    MOV AL, 024h 
    OUT DX, AL
       
    RET

INVALID:
    
    MOV DX, 2070h
    MOV AL, 049h 
    OUT DX, AL
    
    JMP EXIT
    RET
    	
CLEARDISPLAY1: 

	MOV DX, 2039h
	MOV SI, 0
	MOV CX, 48
	RET

CLEARDISPLAY2:

	MOV AL, clearASCII[SI]
	OUT DX,AL
	INC SI
	INC DX 
	LOOP CLEARDISPLAY2
	RET

EXIT:   

    MOV AH, 4CH
    INT 21H 
    
    
; TIME
	
DISPLAY_TIME PROC
    
     MOV AX, @DATA ;storage ng data segment
     MOV DS, AX
     LEA BX, time  ;print yung string time 
                      
     CALL GET_TIME  ;get time 
     CALL ASCII    ;display in ascii lcd                           
     RET
     
DISPLAY_TIME ENDP 

GET_TIME PROC    
    
    PUSH AX                      
    PUSH CX
                           
    MOV AH, 2CH  ;get time                
    INT 21H

    ;store yung hr,time,ss sa al register
                           
    MOV AL, CH   ;hour                 
    CALL CONVERT                  
    MOV [BX], AX ;add yung value ng hour sa index 0 at 1
                      
    MOV AL, CL    ;minute                    
    CALL CONVERT                  
    MOV [BX + 3], AX ;add yung value ng minute sa index 3at 4
                                                             
    MOV AL, DH    ;seconds                
    CALL CONVERT                   
    MOV [BX + 6], AX ;add yung value ng minute sa index 6 at 7
                                                                       
    POP CX                        
    POP AX                        
    RET
                               
GET_TIME ENDP 

;ACII LCD

ASCII PROC
    mov dx,2040h
    mov si,0
    mov cx,48
    
NEXT:
    
    MOV AL, prompt[si]; print yung nasa string by their index 
    OUT DX, AL
    INC SI
    INC DX
     
    LOOP NEXT
    RET

DISPLAY:
    
    MOV AL, time[si]; print yung nasa string by their index 
    OUT DX, AL
    INC SI
    INC DX 
    LOOP DISPLAY
    RET

ASCII ENDP

CONVERT PROC     ;convertion to string
         
    PUSH DX                      
    MOV AH, 0                     
    MOV DL, 10                   
    DIV DL                        
    OR AX, 3030H                  
    POP DX                        
    RET

CONVERT ENDP  

; DATE 
SDATE1: 

	MOV DX, 2050h
	MOV SI, 0
	MOV CX, 48
	RET

SDATE2:

	MOV AL, SDATE[SI]
	out DX,AL
	INC SI
	INC DX 
	LOOP SDATE2
	RET  
   
DISPLAY_DATE:


    TAB EQU 9           ;ASCII Code 
    
    MOV AH, 2AH         ;hexadecimal to get the system date
    INT 21H             ;executes
    
    ;after this, nalagay na sa designated registers ang date
    
    PUSH AX             ;store ax to stack
    PUSH DX             ;store dx to stack 
    
;month 
    MOV AL, DH          ;copy dh to al (since dh contains the month and al is the register for arithmetic)
    MOV DX, 2055H
    CALL CONVERT_DATE 
    
;day 
    POP DX              ;retrieve dx from stack (dl contains day)
    MOV AL, DL          ;copy dl to al
    MOV DX, 2057H
    CALL DISPLAY_SLASH
    MOV DX, 2058H
    CALL CONVERT_DATE
                
;year      
         
    SUB CX, 2000        ;subtract 2000 to cx since it cna only store to digit
    MOV AX, CX          ;copy cx to al (since cx contains year
    MOV DX, 2060H
    CALL DISPLAY_SLASH
    MOV DX, 2061H
    CALL CONVERT_DATE 
    CALL START_PRINT
    RET
    
CONVERT_DATE:                ;function to convert hexadecimal to ASCII
    
    AAM                 ;ASCII adjust after manipulation- divides AL by 10 and stores quotient to AH, Remainder to AL
    ADD AX, 3030h       ;adds 3030h to ax para maging ASCIIang hexadecimal
                        
    MOV BX, AX          ;copy ang ax sa bx kasi mababago ang value ng ax dahil sa printing          
                         
    MOV AL, BH
    MOV AH, BL
    
    ;MOV DX, 2040h	    ;ASCII LCD Display
	OUT DX, AX
	INC DX
  
    RET 

DISPLAY_SLASH:  

    PUSH AX
    MOV SI, 0
    MOV AL, SLASH[SI]
	out DX,AL
	POP AX
	RET

START_PRINT:  

    MOV DL, 12      ; form feed code. new page.
    MOV AH, 5
    INT 21H

    MOV SI, OFFSET msg
    mov cx, OFFSET msg_end - OFFSET msg

PRINT:
    MOV DL, [SI]
    MOV AH, 5       ; MS-DOS print function.
    INT 21H
    INC SI	        ; next char.
    LOOP PRINT
   
    MOV AX, 0       ; wait for any key...
    INT 16H

    MOV DL, 12      ; form feed code. page out!
    MOV AH, 5
    INT 21h 
    RET	  
    
ends   


