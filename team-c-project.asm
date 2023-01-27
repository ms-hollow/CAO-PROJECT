NAME "PRINTER" 

DATA SEGMENT   
     
     FIRSTDIGIT DB 1 DUP(?) 
     STRING1 DB "VALID$"   
     STRING2 DB "INVALID$"
     SLASH DB "\"
     SDATE DB "DATE: "
     ;PKEY DB "PRESS ANY KEY...$"
     CLEARASCII DB "                                                      "
     NUMBERS	DB 00111111B, 00000110B, 01011011B, 01001111B, 01100110B, 01101101B, 01111101B, 00000111B, 01111111B, 01101111B,
                DB 01110111B, 01111100B, 00111001B, 01011110B, 01111001B, 01110001B    
     
     MSG DB "MAGANDANG ARAW!", 0AH, 0DH
     DB "ANG IYONG ANAK NA SI (PANGALAN) ", 0AH, 0DH      
     DB "AY LIGTAS NANG NAKARATING SA TECHNOLOGICAL UNIVERSITY OF THE PHILIPPINES - MANILA", 0AH, 0DH
     DB "SA ORAS NA (INSERT TIME). ", 0AH, 0DH
     DB "MARAMING SALAMAT", 0AH, 0DH
     DB 13, 9    ; CARRIAGE RETURN AND VERTICAL TAB  
     
     ID DB "0000000.TXT",0 
     ;      01234567 -INDEX   

     FILEHANDLER DW ? 
     OKOPEN      DB 'OPEN OK$'
     FAILEDOPEN  DB 'ERROR OPEN$'

     HANDLE DW ?                     ;CREATES VARIABLE TO STORE FILE HANDLE WHICH IDENTIFIES THE FILE              
     TEXT DB "TIME IN: " ;CREATES TEXT TO WRITE ON FILE
     TEXT_SIZE = $ - OFFSET TEXT        ;ASSIGN SIZE  
     
     PROMPT  DB "TIME:" 
     TIME DB "00:00:00",0 
 ;            01234567 -INDEX  

         
ENDS

STACK SEGMENT
    DW   128  DUP(0)
ENDS

CODE SEGMENT 

; CHECK TEMPERATURE     
CHECK_TEMP   PROC    FAR

    ; STORE RETURN ADDRESS TO OS:
 	PUSH    DS
 	MOV     AX, 0
 	PUSH    AX

    ; SET SEGMENT REGISTERS:
 	MOV     AX, DATA
 	MOV     DS, AX
 	MOV     ES, AX

    ; INITIALIZE ALL SEVEN SEGMENT DISPLAYS TO EMPTY
	MOV CX, 8	
	MOV DX, 2030H
	MOV AL, 00H   
	
INIT:	
    OUT DX, AL
	INC DX
	LOOP INIT
	
THERMOMETER:	
	MOV DX, 2086H	        ;READ TEMPERATURE (8-BIT INPUT)
	IN  AL, DX	
	
	MOV BL, AL	            ;BX NOW HAS THE TEMPERATURE
	MOV BH, 0
	
	; DISPLAY TEMPERATURE ON SEVEN SEGMENT (USING HEXADECIMAL)
	MOV DX, 2030H 	        ;OUTPUT MOST SIGNIFICANT 4-BITS
	MOV SI, BX
	AND SI, 00F0H
	MOV CL, 4
	ROR SI, CL
	MOV AL, NUMBERS[SI]
	OUT DX, AL

	MOV DX, 2031H 	        ;OUTPUT LEAST SIGNIFICANT 4-BITS
	MOV SI, BX
	AND SI, 000FH
	MOV AL, NUMBERS[SI]
	OUT DX, AL
	
	MOV DX, 2032H	        ;OUTPUT 'H' INDICATING HEXADECIMAL KEY
	MOV AL, 01110100B
	OUT DX, AL  	 
	
	MOV DX, 2070H
    MOV CX, 7 
	
    CMP BX, 04EH            ;HEX FOR 38
    JL GREEN
    JMP RED
    
RED:
	MOV AL, 049H 
    OUT DX, AL 
    JMP EXIT
    
GREEN:
    MOV AL, 024H 
    OUT DX, AL     	
	JMP GET_ID              ;INFINIT LOOP 
	
CHECK_TEMP  ENDP


; GET INPUT USING KEYBOARD    
GET_ID:    
    
    ; RESET LEDS OUTPUT
    MOV DX, 2070H
    MOV AL, 00H
    OUT DX, AL
      
    MOV AX, @DATA ;STORAGE NG DATA SEGMENT
    MOV DS,AX
    LEA BX, ID     ;LOAD ADDRESS NG ID
    MOV CX, 6   
      
    ;RESET BUFFER INDICATOR TO ALLOW MORE KEYS
	MOV DX, 2083H
	MOV AL, 00H
	OUT DX, AL
	  
    ;MOV CX, 6
    ;MOV BX, 2040H
    
    ;MAIN    
    
	CALL KEYBOARD
	MOV  DX, OFFSET ID 
    CALL OPEN_FILE
    CALL WRITE_FILE

	;CALL DISPLAY_DIGIT
    ;CALL VERIFY
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
                           
    MOV DX, 2083H 	; INPUT DATA FROM KEYBOARD (IF BUFFER HAS KEY)
	IN  AL, DX    
	CMP AL, 00H
	JE  KEYBOARD      	; BUFFER HAS NO KEY, CHECK AGAIN 
	
	; A NEW KEY WAS PRESSED
	MOV DX, 2082H	; READ KEY (8-BIT INPUT)
	IN  AL, DX	

	AAM                 ;ASCII ADJUST AFTER MANIPULATION- DIVIDES AL BY 10 AND STORES QUOTIENT TO AH, REMAINDER TO AL
    ADD AX, 3030H       ;ADDS 3030H TO AX PARA MAGING ASCIIANG HEXADECIMAL

    MOV [BX], AX 
    INC BX 
    
    ; RESET BUFFER INDICATOR TO ALLOW MORE KEYS
	MOV DX, 2083H
	MOV AL, 00H
	OUT DX, AL
	
    LOOP KEYBOARD
    
;ASCII LCD

INIT_ASCII:
    MOV DX,2040H
    MOV SI,0
    MOV CX,6

DISPLAY_ID:
    MOV AL,ID[SI]; PRINT YUNG NASA STRING BY THEIR INDEX 
    OUT DX,AL
    INC SI
    INC DX 
    LOOP DISPLAY_ID 
    RET 
    
OPEN_FILE:
    PUSH AX
    PUSH BX
    
    CMP CL,21D        
    JE  CHECK_STATUS

CHECK_STATUS:    .
    MOV AL,0             ;READ ONLY MODE.
    MOV AH,03DH          ;SERVICE TO OPEN FILE.
    INT 21H
    JB  NOTOK            ;ERROR IF CARRY FLAG.
    JE OK

OK:;DISPLAY OK MESSAGE.
    MOV FILEHANDLER, AX  ;IF NO ERROR, NO JUMP. SAVE FILEHANDLER.
    MOV DX,OFFSET OKOPEN
    MOV AH,09H
    INT 021H
    ;GREEN LIGHT   
    MOV DX, 2070H 
    MOV AL, 024H 
    OUT DX, AL          
              
    JMP ENDOFFILE
    ; ---------------------------------------------------------------------

NOTOK:;DISPLAY ERROR MESSAGE.
    MOV DX,OFFSET FAILEDOPEN
    MOV AH,09H
    INT 021H  
    ;RED LIGHT
    MOV DX, 2070H
    MOV AL, 049H 
    OUT DX, AL
    
    JMP EXIT

ENDOFFILE:
    POP BX
    POP AX
    RET

WRITE_FILE:
    MOV AX, CS
    MOV DX, AX
    MOV ES, AX
    
    MOV AH, 3CH           ;FUNCTION NUMBER TO CREATE FILE
    MOV CX, 0
    MOV DX, OFFSET ID   ;GET OFFSET ADDRESS
    INT 21H
    MOV HANDLE, AX   
    
    MOV AH, 40H           ;FUNCTION NUMBER TO WRITE ON FILE
    MOV BX, HANDLE
    MOV DX, OFFSET TEXT
    MOV CX, TEXT_SIZE
    INT 21H
    
    MOV AH, 3EH          ;FUNCTION NUMBER TO CLOSE FILE
    MOV BX, HANDLE
    INT 21H 
    RET         
    	
CLEARDISPLAY1: 

	MOV DX, 2039H
	MOV SI, 0
	MOV CX, 48
	RET

CLEARDISPLAY2:

	MOV AL, CLEARASCII[SI]
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
    
     MOV AX, @DATA      ;STORAGE NG DATA SEGMENT
     MOV DS, AX
     LEA BX, TIME       ;PRINT YUNG STRING TIME 
                      
     CALL GET_TIME      ;GET TIME 
     CALL ASCII         ;DISPLAY IN ASCII LCD                           
     RET
     
DISPLAY_TIME ENDP 

GET_TIME PROC    
    
    PUSH AX                      
    PUSH CX
                           
    MOV AH, 2CH         ;GET TIME                
    INT 21H

    ;STORE YUNG HR,TIME,SS SA AL REGISTER
                           
    MOV AL, CH          ;HOUR                 
    CALL CONVERT                  
    MOV [BX], AX        ;ADD YUNG VALUE NG HOUR SA INDEX 0 AT 1
                      
    MOV AL, CL          ;MINUTE                    
    CALL CONVERT                  
    MOV [BX + 3], AX    ;ADD YUNG VALUE NG MINUTE SA INDEX 3AT 4
                                                             
    MOV AL, DH          ;SECONDS                
    CALL CONVERT                   
    MOV [BX + 6], AX    ;ADD YUNG VALUE NG MINUTE SA INDEX 6 AT 7
                                                                       
    POP CX                        
    POP AX                        
    RET
                               
GET_TIME ENDP 

;ACII LCD

ASCII PROC
    MOV DX,2040H
    MOV SI,0
    MOV CX,48
    
NEXT:
    
    MOV AL, PROMPT[SI]  ;PRINT YUNG NASA STRING BY THEIR INDEX 
    OUT DX, AL
    INC SI
    INC DX
     
    LOOP NEXT
    RET

DISPLAY:
    
    MOV AL, TIME[SI]    ;PRINT YUNG NASA STRING BY THEIR INDEX 
    OUT DX, AL
    INC SI
    INC DX 
    LOOP DISPLAY
    RET

ASCII ENDP

CONVERT PROC            ;CONVERTION TO STRING
         
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

	MOV DX, 2050H
	MOV SI, 0
	MOV CX, 48
	RET

SDATE2:

	MOV AL, SDATE[SI]
	OUT DX,AL
	INC SI
	INC DX 
	LOOP SDATE2
	RET  
   
DISPLAY_DATE:

    TAB EQU 9           ;ASCII CODE 
    
    MOV AH, 2AH         ;HEXADECIMAL TO GET THE SYSTEM DATE
    INT 21H             ;EXECUTES
    
    ;AFTER THIS, NALAGAY NA SA DESIGNATED REGISTERS ANG DATE
    
    PUSH AX             ;STORE AX TO STACK
    PUSH DX             ;STORE DX TO STACK 
    
;MONTH 
    MOV AL, DH          ;COPY DH TO AL (SINCE DH CONTAINS THE MONTH AND AL IS THE REGISTER FOR ARITHMETIC)
    MOV DX, 2055H
    CALL CONVERT_DATE 
    
;DAY 
    POP DX              ;RETRIEVE DX FROM STACK (DL CONTAINS DAY)
    MOV AL, DL          ;COPY DL TO AL
    MOV DX, 2057H
    CALL DISPLAY_SLASH
    MOV DX, 2058H
    CALL CONVERT_DATE
                
;YEAR      
         
    SUB CX, 2000        ;SUBTRACT 2000 TO CX SINCE IT CNA ONLY STORE TO DIGIT
    MOV AX, CX          ;COPY CX TO AL (SINCE CX CONTAINS YEAR
    MOV DX, 2060H
    CALL DISPLAY_SLASH
    MOV DX, 2061H
    CALL CONVERT_DATE 
    ;CALL START_PRINT
    RET
    
CONVERT_DATE:           ;FUNCTION TO CONVERT HEXADECIMAL TO ASCII
    
    AAM                 ;ASCII ADJUST AFTER MANIPULATION- DIVIDES AL BY 10 AND STORES QUOTIENT TO AH, REMAINDER TO AL
    ADD AX, 3030H       ;ADDS 3030H TO AX PARA MAGING ASCIIANG HEXADECIMAL
                        
    MOV BX, AX          ;COPY ANG AX SA BX KASI MABABAGO ANG VALUE NG AX DAHIL SA PRINTING          
                         
    MOV AL, BH
    MOV AH, BL
    
    ;MOV DX, 2040H	    ;ASCII LCD DISPLAY
	OUT DX, AX
	INC DX
    RET 

DISPLAY_SLASH:  

    PUSH AX
    MOV SI, 0
    MOV AL, SLASH[SI]
	OUT DX,AL
	POP AX
	RET

START_PRINT:  

    MOV DL, 12      ; FORM FEED CODE. NEW PAGE.
    MOV AH, 5
    INT 21H

    MOV SI, OFFSET MSG
    MOV CX, OFFSET MSG_END - OFFSET MSG

PRINT:
    MOV DL, [SI]
    MOV AH, 5       ; MS-DOS PRINT FUNCTION.
    INT 21H
    INC SI	        ; NEXT CHAR.
    LOOP PRINT
   
    MOV AX, 0       ; WAIT FOR ANY KEY...
    INT 16H

    MOV DL, 12      ; FORM FEED CODE. PAGE OUT!
    MOV AH, 5
    INT 21H 
    RET	  
    
ENDS   
