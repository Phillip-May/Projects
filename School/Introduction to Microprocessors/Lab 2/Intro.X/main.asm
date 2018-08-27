#include "p16f887.inc"

; CONFIG1
; __config 0x33F5
 __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_OFF & _FCMEN_OFF & _LVP_ON
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF


RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

; TODO ADD INTERRUPTS HERE IF USED

MAIN_PROG CODE                      ; let linker place main program

START
    
    
    BANKSEL	PORTA		    ;Select the bank of PORTA
    CLRF	PORTA		    ;Initialise PORTA
    BANKSEL	ANSEL		    ;
    MOVLW	b'00000000'	    ;
    MOVWF	ANSEL		    ;0 means digital
    BANKSEL	TRISA		    ;Select the bank of TRISA
    MOVLW	b'00000000'
    MOVWF	TRISA		    ;Set port A0 to output, correct 
    BANKSEL	PORTA		    ;
    MOVLW	b'00000001'	    ;Move the 1 in binary to working register
    MOVWF	PORTA		    ;Set RA0 to high
    
    BANKSEL	PORTB
    CLRF	PORTB		    ;Initialise PORTB  
    BANKSEL	ANSELH		    ;Set port B to digital IO
    MOVLW	b'00000000'	    ;
    MOVWF	ANSELH		    ;0 means digital
    BANKSEL	TRISB		    ;Select the bank of TRISB
    MOVLW	b'11111111'
    MOVWF	TRISB		    ;Set port B0 to input, correct     
     
     
    
    
    Ifstart:
    BANKSEL	PORTB		    ;PortB for next bit check
    BTFSC	PORTB, 0	    ;Testing the bit of port 0
    GOTO	PRESSED		    ;Does not skip if clear, meaning pressed
    GOTO	NOTPRESSED	    ;Low means Clear which means button not pressed
    
    
    PRESSED:
    BANKSEL	PORTA		    ;
    MOVLW	b'00000000'	    ;Move the 1 in binary to working register
    MOVWF	PORTA		    ;Set RA0 to high
    BANKSEL	PORTB		    ;For the bit check
    GOTO	Ifstart
    
    NOTPRESSED:
    BANKSEL	PORTA		    ;
    MOVLW	b'00000001'	    ;Move the 1 in binary to working register
    MOVWF	PORTA		    ;Set RA0 to high
    BANKSEL	PORTB		    ;For the bit check
    
    GOTO	Ifstart		    ;Repeat the check
    
    GOTO $                          ; loop forever

    END