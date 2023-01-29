NAME "PRINTER" 

DATA SEGMENT
    
     FIRSTDIGIT DB 1 DUP(?) 
   
     CLEARASCII DB "                                                      "
     NUMBERS	DB 00111111B, 00000110B, 01011011B, 01001111B, 01100110B, 01101101B, 01111101B, 00000111B, 01111111B, 01101111B,
                DB 01110111B, 01111100B, 00111001B, 01011110B, 01111001B, 01110001B    
     
     ID DB "0000000.txt",0 
     ;      01234567 -index   

     filehandler dw ?  
     handle dw ?                     ;Creates variable to store file handle which identifies the file              
     TIME_IN db "TIME IN: "          ;creates text to write on file
     MSG  DB "MAGANDANG ARAW!", 0AH, 0DH
     DB "ANG IYONG ANAK AY LIGTAS NANG NAKARATING SA ", 0AH, 0DH      
     DB "TECHNOLOGICAL UNIVERSITY OF THE PHILIPPINES - MANILA", 0AH, 0DH                                
     DB "MARAMING SALAMAT", 0AH, 0DH
     DB 13, 9    ; CARRIAGE RETURN AND VERTICAL TAB  
     SDATE  DB "DATE:" 
     DATE DB "00\00\00 ", 0 
 ;            01234567 -INDEX  
     SPACE DB " ", 0AH, 0DH 
     PROMPT  DB "TIME:" 
     TIME DB "00:00:00", 0
 ;            01234567 -INDEX  
     MSG_END db 0      
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
    
 
    mov ax, @DATA ;storage ng data segment
    mov ds,ax
    lea bx, ID     ;load address ng ID
    MOV CX, 6   
      
    ;RESET BUFFER INDICATOR TO ALLOW MORE KEYS
	MOV DX, 2083H
	MOV AL, 00H
	OUT DX, AL
	  
    ;MOV CX, 6
    ;MOV BX, 2040H
    
    ;MAIN    
    
	CALL KEYBOARD
	mov  dx, offset ID 
    call OPEN_FILE
	CALL CLEARDISPLAY1
	CALL CLEARDISPLAY2
	CALL DISPLAY_TIME 
    CALL GET_DATE
    CALL WRITE_FILE
	CALL INIT_DATE   
	CALL DISP_GATE
	CALL START_PRINT
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

    MOV [BX], AX 
    INC BX 
    
    ; reset buffer indicator to allow more keys
	MOV DX, 2083h
	MOV AL, 00h
	OUT DX, AL
	
    LOOP KEYBOARD
    
    ;RESET LEDS OUTPUT
    MOV DX, 2070H
    MOV AL, 00H
    OUT DX, AL
    ;ASCII LCD
    mov dx,2040h
    mov si,0
    mov cx,6

DISPLAY_ID:
    mov al,ID[si]; print yung nasa string by their index 
    out dx,al
    inc si
    inc dx 
    loop DISPLAY_ID 
    RET 
    
OPEN_FILE:
    push ax
    push bx
    
    cmp cl,21d        
    je  CHECK_STATUS

CHECK_STATUS:    .
    mov al,0             ;READ ONLY MODE.
    mov ah,03dh          ;SERVICE TO OPEN FILE.
    int 21h
    jb  NOTOK            ;ERROR IF CARRY FLAG.
    je OK

OK:;DISPLAY OK MESSAGE.
    mov filehandler, ax  ;IF NO ERROR, NO JUMP. SAVE FILEHANDLER.
    ;GREEN LIGHT   
    MOV DX, 2070H 
    MOV AL, 024H 
    OUT DX, AL          
              
    jmp endOfFile

NOTOK:;DISPLAY ERROR MESSAGE.
    
    ;RED LIGHT
    MOV DX, 2070H
    MOV AL, 049H 
    OUT DX, AL
    
    CALL CLEARDISPLAY1
	CALL CLEARDISPLAY2
    CALL EXIT

endOfFile:
    pop bx
    pop ax
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
    MOV CX,14
    
NEXT:
    
    MOV AL, PROMPT[SI]  ;PRINT YUNG NASA STRING BY THEIR INDEX 
    OUT DX, AL
    INC SI
    INC DX
     
    LOOP NEXT
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
   
GET_DATE:

    TAB EQU 9           ;ASCII CODE  
    MOV AX, @DATA      ;STORAGE NG DATA SEGMENT
    MOV DS, AX
    LEA BX, DATE       ;PRINT YUNG STRING TIME 
    
    MOV AH, 2AH         ;HEXADECIMAL TO GET THE SYSTEM DATE
    INT 21H             ;EXECUTES
    
    ;AFTER THIS, NALAGAY NA SA DESIGNATED REGISTERS ANG DATE

    PUSH DX             ;STORE DX TO STACK 
    
;MONTH 
    MOV AL, DH          ;COPY DH TO AL (SINCE DH CONTAINS THE MONTH AND AL IS THE REGISTER FOR ARITHMETIC)
    CALL CONVERT_DATE
    MOV [BX], AX 
    
;DAY 
    POP DX              ;RETRIEVE DX FROM STACK (DL CONTAINS DAY)
    MOV AL, DL          ;COPY DL TO AL
    CALL CONVERT_DATE
    MOV [BX+3], AX
                
;YEAR      
    
    SUB CX, 2000        ;SUBTRACT 2000 TO CX SINCE IT CNA ONLY STORE TO DIGIT
    MOV AX, CX          ;COPY CX TO AL (SINCE CX CONTAINS YEAR
    CALL CONVERT_DATE
    MOV [BX+6], AX
    MOV DX, 2055H
	MOV SI, 0
	MOV CX, 8 
    RET
    
CONVERT_DATE:           ;FUNCTION TO CONVERT HEXADECIMAL TO ASCII
    
    AAM                 ;ASCII ADJUST AFTER MANIPULATION- DIVIDES AL BY 10 AND STORES QUOTIENT TO AH, REMAINDER TO AL
    ADD AX, 3030H       ;ADDS 3030H TO AX PARA MAGING ASCIIANG HEXADECIMAL
    PUSH BX                    
    MOV BX, AX          ;COPY ANG AX SA BX KASI MABABAGO ANG VALUE NG AX DAHIL SA PRINTING                              
    MOV AL, BH          ;INTERCHANGE VALUES
    MOV AH, BL
    POP BX   
    RET  

INIT_DATE: 

	MOV DX, 2050H
	MOV SI, 0
	MOV CX, 14         ;SINCE 14 ANG CX, PATI KUNG ANO YUNG NASA BABA NG SDATE NAPI-PRINT NIYA, WHICH IS YUNG MISMONG DATE.

DISPLAY_DATE:

	MOV AL, SDATE[SI]
	OUT DX,AL
	INC SI
	INC DX 
	LOOP DISPLAY_DATE
	RET  

WRITE_FILE:
    mov ax, cs
    mov dx, ax
    mov es, ax
    
    mov ah, 3ch           ;Function number to create file
    mov cx, 0
    mov dx, offset ID   ;get offset address
    int 21h
    mov handle, ax   
    
    mov ah, 40h           ;Function number to write on file
    mov bx, handle
    mov dx, offset SDATE  ;Print sa file yung "TIME IN" " na string
    mov cx, 5
    int 21h  
    
    mov ah, 40h           ;Function number to write on file
    mov bx, handle
    mov dx, offset DATE   ;Print sa file yung mismong time
    mov cx, 8
    int 21h
    
    mov ah, 40h           ;Function number to write on file
    mov bx, handle
    mov dx, offset TIME_IN ;Print sa file yung "TIME IN" " na string
    mov cx, 9
    int 21h  
    
    mov ah, 40h           ;Function number to write on file
    mov bx, handle
    mov dx, offset TIME   ;Print sa file yung mismong time
    mov cx, 8
    int 21h
    
    mov ah, 3eh          ;Function number to close file
    mov bx, handle
    int 21h 
    RET         

DISP_GATE PROC    


DISP_GATE  ENDP
    
    
    MOV AX, GREETINGS     ;STORAGE NG DATA SEGMENT
    MOV DS, AX
    ; CLEAR YUNG PUSH BUTTON    
    MOV AL, 00h
	MOV DX, 2080h
	OUT DX, AL	

INPUT:

	MOV DX, 2080h ; input data from switches
	IN  AX, DX    ; 16-bit input  
 
	MOV DX, 2000h
	MOV BX, 00h	 
	
	cmp ax, 02h   ;1
	je GATE1LOOP
	cmp ax, 04h   ;2
	je GATE2LOOP
	cmp ax, 08h
	je GATE3LOOP
	
	JNE INPUT 
    
GATE1LOOP:
    
	MOV SI, 0

GATE01:
	MOV AL,Gate1[BX][SI]
	out dx,al
	INC SI
	INC DX

	CMP SI, 5
	LOOPNE GATE01

	ADD BX, 5
	CMP BX, 40
	JL GATE1LOOP
	JE DOTC 
	
	
GATE2LOOP:
	MOV SI, 0
	;MOV CX, 5

GATE02:
	MOV AL,Gate2[BX][SI]
	out dx,al
	INC SI
	INC DX

	CMP SI, 5
	LOOPNE GATE02

	ADD BX, 5
	CMP BX, 40
	JL GATE2LOOP
	JE DOTC 
	
GATE3LOOP:
	MOV SI, 0
	;MOV CX, 5

GATE03:
	MOV AL,Gate3[BX][SI]
	out dx,al
	INC SI
	INC DX

	CMP SI, 5
	LOOPNE GATE03

	ADD BX, 5
	CMP BX, 40
	JL GATE3LOOP 
	JE DOTC
	
DOTC:	

    MOV DX, 2000h
	MOV BX, 00h    
 
CLEARLOOP: 

	MOV SI, 0
	
CLDISPLAY:
    
	MOV AL,00h
	out dx,al
	INC SI
	INC DX

	CMP SI, 5
	LOOPNE CLDISPLAY

	ADD BX, 5
	CMP BX, 40 
	JL CLEARLOOP

DOTW:	

    MOV DX, 2000h
	MOV BX, 00h
    
WELLOOP: 

	MOV SI, 0
	MOV CX, 5  
	
WELDISPLAY:

	MOV AL,Welcome[BX][SI]
	out dx,al
	INC SI
	INC DX

	CMP SI, 5
	LOOPNE WELDISPLAY

	ADD BX, 5
	CMP BX, 40
	JL WELLOOP
	
    RET
	
START_PRINT:  
    
    MOV AX, DATA     ;STORAGE NG DATA SEGMENT
    MOV DS, AX
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
     
    MOV DL, 12      ; FORM FEED CODE. PAGE OUT!
    MOV AH, 5
    INT 21H 
    RET	  

GREETINGS SEGMENT
    
Welcome DB 01111111b, 00100000b, 00011000b, 00100000b, 01111111b; w
        DB 01111111b, 01001001b, 01001001b, 01001001b, 01000001b; E
        DB 01111111b, 01000000b, 01000000b, 01000000b, 01000000b; L
        DB 00111110b, 01000001b, 01000001b, 01000001b, 00100010b; C
        DB 00111110b, 01000001b, 01000001b, 01000001b, 00111110b; O
        DB 01111111b, 00000010b, 00001100b, 00000010b, 01111111b; M
        DB 01111111b, 01001001b, 01001001b, 01001001b, 01000001b; E
        DB 00000000B, 01011111B, 00000000B, 01011111B, 00000000B; !!  
        
          ;1          2          3          4          5
Gate1   DB 00000000b, 00000000b, 00000000b, 00000000b, 00000000b
        DB 00111110b, 01000001b, 01001001b, 01001001b, 01111010b; G
        DB 01111110b, 00010001b, 00010001b, 00010001b, 01111110b; A
        DB 00000001b, 00000001b, 01111111b, 00000001b, 00000001b; T
        DB 01111111b, 01001001b, 01001001b, 01001001b, 01000001b; E
        DB 00000000b, 00000000b, 00000000b, 00000000b, 00000000b
        DB 01000100b, 01000010b, 01111111b, 01000000b, 01000000b; 1
        DB 00000000b, 00000000b, 00000000b, 00000000b, 00000000b
                                                                 
Gate2   DB 00000000b, 00000000b, 00000000b, 00000000b, 00000000b
        DB 00111110b, 01000001b, 01001001b, 01001001b, 01111010b; G
        DB 01111110b, 00010001b, 00010001b, 00010001b, 01111110b; A
        DB 00000001b, 00000001b, 01111111b, 00000001b, 00000001b; T
        DB 01111111b, 01001001b, 01001001b, 01001001b, 01000001b; E
        DB 00000000b, 00000000b, 00000000b, 00000000b, 00000000b
        DB 01000010b, 01100001b, 01010001b, 01001001b, 01000110b; 1
        DB 00000000b, 00000000b, 00000000b, 00000000b, 00000000b
        
Gate3   DB 00000000b, 00000000b, 00000000b, 00000000b, 00000000b
        DB 00111110b, 01000001b, 01001001b, 01001001b, 01111010b; G
        DB 01111110b, 00010001b, 00010001b, 00010001b, 01111110b; A
        DB 00000001b, 00000001b, 01111111b, 00000001b, 00000001b; T
        DB 01111111b, 01001001b, 01001001b, 01001001b, 01000001b; E
        DB 00000000b, 00000000b, 00000000b, 00000000b, 00000000b
        DB 00100010b, 01001001b, 01001001b, 01001001b, 00110110b; 1
        DB 00000000b, 00000000b, 00000000b, 00000000b, 00000000b
          ;1234567  
    ENDS    
ENDS