#include "p16f887.inc"

; CONFIG1
; __config 0x33F5
 __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_OFF & _FCMEN_OFF & _LVP_ON
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

 ;Variable definint*****************************
 cblock 0x20
 counter1
 endc
 ;**********************************************


org		00		    ;Fix the debugger

START
    
    ;Start of port setup
    BANKSEL	PORTA		    ;Select the bank of PORTA
    CLRF	PORTA		    ;Initialise PORTA
    BANKSEL	ANSEL		    ;
    MOVLW	b'00000000'	    ;
    MOVWF	ANSEL		    ;0 means digital
    BANKSEL	TRISA		    ;Select the bank of TRISA
    MOVLW	b'00000000'
    MOVWF	TRISA		    ;Set port A0 to output, correct 

    BANKSEL	ANSELH		    ;Set all of port A to digital IO
    MOVLW	b'00000000'	    ;
    MOVWF	ANSELH		    ;0 means digital
  
    ;End of port setup
    Mainloopstart:
    
    BANKSEL	PORTA		    ;Select the bank of PORTA
    MOVLW	b'11111111'	    ;So porta0-porta3 turn on
    MOVWF	PORTA		    ;
    
    BANKSEL	0		    ;Counter is stored in bank0
    movlw	h'FF'
    movwf	counter1	    ;Set the counter to loop 255 times  
    LEDoncycle:
    decfsz	counter1	    ;
    GOTO	LEDoncycle	    ;Repeat cycle 255 times
    
    
    BANKSEL	PORTA		    ;Select the bank of PORTA
    MOVLW	b'00000000'	    ;So porta0-porta3 turn off
    MOVWF	PORTA		    ;
    
    ;Start of off cycle
    BANKSEL	0		    ;Counter is stored in bank0
    movlw	h'FF'
    movwf	counter1	    ;Set the counter to loop 255 times 
    LEDoffcycle:
    decfsz	counter1	    ;
    GOTO	LEDoffcycle	    ;Repeat cycle 255 times
    
    GOTO	Mainloopstart	    ;Repeat the on off cycle 
     
     
    

    
    GOTO $                          ; loop forever

    END