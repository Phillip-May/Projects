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
    ;Start of port setup
    BANKSEL	PORTA		    ;Select the bank of PORTA
    CLRF	PORTA		    ;Initialise PORTA
    BANKSEL	ANSEL		    ;
    MOVLW	b'00000000'	    ;
    MOVWF	ANSEL		    ;0 means digital
    BANKSEL	TRISA		    ;Select the bank of TRISA
    MOVLW	b'00010000'
    MOVWF	TRISA		    ;Set port A0 to output, correct 
    ;Port4 needs to be input for timer0
    BANKSEL	TMR0
    CLRF	TMR0
 
 
    ;Pin 6 will be used Tmr0in
    BANKSEL	OPTION_REG	    ;Select the bank for option reg
    MOVLW	b'00110000'	    ;
    IORWF	OPTION_REG	    ;
    ;Set clk0in to enabled, uses "or" to not change other bits
    
StartLEDinc:
    BANKSEL	TMR0
    MOVFW	TMR0
    BANKSEL	PORTA
    MOVWF	PORTA
    GOTO	StartLEDinc
 

    END