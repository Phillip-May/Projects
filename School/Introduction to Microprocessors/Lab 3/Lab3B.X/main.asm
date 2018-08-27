#include "p16f887.inc"

; CONFIG1
; __config 0x33F5
 __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_OFF & _FCMEN_OFF & _LVP_ON
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

 ;Variable definint*****************************
 cblock 0x20
 counter1		    ;Used for inner loop
 counter2		    ;Use for outer loop
 endc
 ;**********************************************


org		00		    ;Fix the debugger

START
    
    ;Start of Part2 modification (datasheet page 64)
    BANKSEL	OSCCON		    ;
    MOVLW	b'00001000'	    ;
    MOVWF	OSCCON		    ;
    ;End of Part2 modification 
 
 
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
    movlw	b'00000010'
    movwf	counter2	    ;Set the outer loop to loop twice
    
    LEDoncycleouter:    
    BANKSEL	0		    ;Counter is stored in bank0
    movlw	h'FF'
    movwf	counter1	    ;Set the counter to loop 255 times
    
    
	LEDoncycle:
	decfsz	counter1	    ;
	GOTO	LEDoncycle	    ;Repeat cycle 255 times

    decfsz	counter2	    ;
    GOTO	LEDoncycleouter     ;Repeat cycle 2 times	
    
    ;Start of off cycle
    BANKSEL	PORTA		    ;Select the bank of PORTA
    MOVLW	b'00000000'	    ;So porta0-porta3 turn off
    MOVWF	PORTA		    ;
    
    movlw	b'00000010'
    movwf	counter2	    ;Set the counter for the outer loop to 2     
    
    ;LED OFF cycle outer start
    LEDoffcycleouter:
    
    BANKSEL	0		    ;Counter is stored in bank0
    movlw	h'FF'
    movwf	counter1	    ;Set the counter to loop 255 times
    
	;LED off inner part
	LEDoffcycleinner:
	decfsz	counter1	    ;
	GOTO	LEDoffcycleinner    ;Repeat cycle 255 times
    
    decfsz	counter2	    ;
    GOTO	LEDoffcycleouter    ;Repeat cycle 255 times
    	

    GOTO	Mainloopstart	    ;Repeat the on off cycle 
     
    GOTO $                          ; loop forever

END