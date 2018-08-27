#include "p16F887.inc"

; CONFIG1
; __config 0x3FF5
    __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_OFF & _FCMEN_OFF & _LVP_ON
; CONFIG2
; __config 0x3FFF
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;**************** DEFINING VARIABLES ****************************************
    cblock	0x20
		counter
    endc
    
    cblock      0x70		; Block of variables starts at address 70h
		W_TEMP		; 71h stores working register for interupts
		STATUS_TEMP	; 72h stores status register
		Delaycounter	; 73h stores counter for ISR delay
		ButtonP		; 74h stores button pressed
    endc						
       
;************************ START OF PROGRAM **********************************
    org         0x0000          ; Address of the first program instruction
    goto        main            ; Go to label "main"
       
;************************ INTERRUPT ROUTINE *********************************
    org         0x0004			; Interrupt vector
;************************ ISR contex saving from datasheet ******************
    MOVWF 	W_TEMP			;copy W to temp register,could be in either bank
    SWAPF	STATUS,W        	;swap status to be saved into W
    BCF 	STATUS,RP0	        ;change to bank 0 regardless of current bank
    MOVWF 	STATUS_TEMP		;save status to bank 0 register
;************************ Interupt service routine***************************

;Switch code to see if interupt was by timer0 or portB
    
BANKSEL		INTCON
BTFSC		INTCON,TMR0IF		; Test to see if interupt was by TMR0
GOTO		TMR0INTERUPT		; interupt for tmr0 interupt
GOTO		PORTBINTERUPT		; Clear means it was not tmr0
;in other words PORTB
TMR0INTERUPT:    

    
CALL		Loop7seg
    
    
;Clearing aditional flags as needed by the ISR
BANKSEL	INTCON				; In order to clear overflow flag 
bcf		INTCON,TMR0IF		; clear interrupt flag TMR0IF
BCF		STATUS,C		;Clear zero flag for shenanigans

BANKSEL		TMR0
CLRF		TMR0			; Reset tmr0 as ISR could last as long
    
BANKSEl		INTCON			; Clear interupt flag after routine
BCF		INTCON,RBIF    
    
GOTO		endISR			;end of interupt service routine
    
;Code if intereupt is done by portB
PORTBINTERUPT:     
;Software debounce circuit
;Will cause a minor delay and make sure B is still pressed
;If yes execute ISR if not exit
    

    
BANKSEL		Delaycounter
MOVLW		b'11111111'		; Max amount with one one loop
MOVWF		Delaycounter

ISRdelay:				; Fully decrement register
DECFSZ		Delaycounter
GOTO		ISRdelay
;When do do normal code

BANKSEl		INTCON			; Clear interupt flag after routine
BCF		INTCON,RBIF

    
BANKSEL		PORTB
BTFSC		PORTB,0			; Check if button still pressed
GOTO		endISR			; Skip the actual ISR when not
;it is so do ISR



    

;Add 1 to ButtonP always reverses bit 0
BANKSEL		ButtonP
MOVFW		ButtonP
ADDLW		b'00000001'		; Reverse bit 0
MOVWF		ButtonP

BANKSEL		TMR0
CLRF		TMR0			; Reset tmr0 as ISR could last as long
;as button is pressed
    
BANKSEl		INTCON			; Clear interupt flag after routine
BCF		INTCON,RBIF
endISR:
;************************ ISR context loading from datasheet ****************
    SWAPF 	STATUS_TEMP,W		;swap STATUS_TEMP register into W, sets bank to original state
    MOVWF 	STATUS		        ;move W into STATUS register
    SWAPF 	W_TEMP,F	  	;swap W_TEMP
    SWAPF 	W_TEMP,W          	;swap W_TEMP into W

    retfie		                ;Return from interrupt routine
       
;************************ MAIN PROGRAM **************************************
main                                ;Start of the main program
    
Call		mSETUP		    ;Setup for main loop
	
loop
    ;Do literally nothing
    goto        loop            ; Remain here

  
mSETUP
    ;All the setup for the main loop before the main code runs
    ;Includes allowing interupts, tmr0 interupt, setting oscillator
    ;speed to 250KHZ, reseting tmr0 and setting portA to digital out.
    
    ;Disable all interupts during setup
    BANKSEL	 INTCON		    ; In oder to disable all interupts during setup
    BCF		 INTCON,GIE	    ; Disabled during setup
    BSF		 INTCON,T0IE	    ; Disable interupt for timer0 as I will use polling

    banksel     OPTION_REG	    ; Bank containing register OPTION_REG
    clrf	OPTION_REG
    bcf         OPTION_REG,T0CS	    ; TMR0 counts pulses from oscillator       
    bcf         OPTION_REG,PSA	    ; Prescaler is assign to WDT

    BANKSEL	INTCON
    BSF		INTCON,RBIE	    ;Enable PORTB interupt
    BANKSEL	IOCB		    
    BSF		IOCB,IOCB0	    ;For only PORTB0
    
    BANKSEL	OSCCON		    ; Set clock to 250khz/ 010 6-4
    BCF		OSCCON,6
    BSF		OSCCON,5
    BCF		OSCCON,4
    
    
;START of PORTC setup    
    BANKSEL	PORTC		    ;For portA setup
    CLRF	PORTC		    ;Initialise PORTA
    BANKSEL	ANSEL		    ;
    MOVLW	b'00000000'	    ;
    MOVWF	ANSEL		    ;Set PORTA to digital
    BANKSEL	TRISC		    ;Select the bank of TRISA
    MOVLW	b'00000000'
    MOVWF	TRISC		    ;Set port A0 to output
    ;Bit 5 is input to not lock the port being used for tmr0 
    BANKSEL	ANSELH		    ;Set all of port A to digital IO
    MOVLW	b'00000000'	    ;
    MOVWF	ANSELH		    ;0 means digital
;end of PORTC setup
    
;Start of PORTB setup
    BANKSEL	PORTB		    ;For portB setup
    CLRF	PORTB		    ;Initialise PORTB
    BANKSEL	TRISB
    MOVLW	b'11111111'	    ;
    MOVWF	TRISB		    ;Set portB to output
    BANKSEL	WPUB
    CLRF	WPUB		    ;Maybe this is needed?
;end of PORTB setup

;Start of PORTA setup   
    BANKSEL	PORTA		    ;For portA setup
    CLRF	PORTA		    ;Initialise PORTA
    BANKSEL	TRISA		    ;Select the bank of TRISA
    MOVLW	b'00000000'
    MOVWF	TRISA		    ;Set port A0 to output
;end of PORTA setup
    
    
    
    BANKSEL	OPTION_REG		    ;Assign prescaller to tmr0
    BCF		OPTION_REG,PSA
    BANKSEL	OPTION_REG
    BSF		OPTION_REG,PS2		    ;Set prescaller to 1:265
    BSF		OPTION_REG,PS1
    BSF		OPTION_REG,PS0
    
    
    banksel	TMR0		    ; Clear timer0 and counter
    clrf	TMR0
    clrf	counter
;Enable interupts after setup
    BANKSEL	INTCON		    ; Enable interupts after setup
    BSF		INTCON,GIE	    ; Enabled after setup

    
    RETURN	;End of setup
    
intTO7seg
   
    ;Inputs an int in working
    ;Outputs to a seven segment display in working
    ;Code assumes common cathode for simplicty
    ;Runs as a "Lookup table"
    ;Probably messes with status flags,
    ;Also included code for A through F but program won't use it.
    ;PCL is a common register to all banks
    
    ;PCL is program counter least signifigant bit
    ;Each instruction is 1 byte so jumping that will jump to the correct retlw	
    ADDWF	PCL,f			; Jump working register lines down
    RETLW	b'00111111'		; 7 segment display for 0 return this
    RETLW	b'00000110'		; 7 segment display for 1 return this
    RETLW	b'01011011'		; 7 segment display for 2 return this 
    RETLW	b'01001111'		; 7 segment display for 3 return this 
    RETLW	b'01100110'		; 7 segment display for 4 return this
    RETLW	b'01101101'		; 7 segment display for 5 return this
    RETLW	b'01111101'		; 7 segment display for 6 return this 
    RETLW	b'00000111'		; 7 segment display for 7 return this
    RETLW	b'01111111'		; 7 segment display for 8 return this
    RETLW	b'01101111'		; 7 segment display for 9 return this
    RETLW	b'01110111'		; 7 segment display for A return this
    RETLW	b'01111100'		; 7 segment display for B return this
    RETLW	b'00111001'		; 7 segment display for C return this
    RETLW	b'01011110'		; 7 segment display for D return this
    RETLW	b'01111001'		; 7 segment display for E return this
    RETLW	b'01110001'		; 7 segment display for F return this
    
    return

Loop7seg

    ;Check if I increment or decrement counter
    ;Switch ButtonP bit0 = 1 means decrement vs bit0 = 0 means increment
    BANKSEL	ButtonP   
    BTFSS	ButtonP,0		; Check if increment or decrement
    GOTO	Elsepart
    BANKSEL	counter
    DECF	counter			; Decrement couter
    GOTO	Endifpart
    Elsepart:
    BANKSEL	counter
    INCF	counter			; increment counter  
    Endifpart:
    ;end of increment/decrement    
    
    ;Counter underflow check
    MOVFW	counter			; Check if counter is above
    ADDLW	b'11110000'		; 
    BANKSEL	STATUS			
    BTFSC	STATUS,C		; 
    GOTO	elseunderflow		; if underflow set to 9
    GOTO	endunderflow		; if nothing do nothing
elseunderflow:
    BANKSEL	STATUS			
    BCF		STATUS,C		;Clear changes to status
    BANKSEL	PORTA
    DECF	PORTA			;Change MSB which is PORTA
    MOVLW	b'00001001'		;Will only trigger on dec so set to 9
    MOVWF	counter			;Save modification
endunderflow:
    
    
    
    MOVFW	counter
    XORLW	.10			; Check is number is 10
    BANKSEL	STATUS			
    BTFSC	STATUS,Z		; 
    GOTO	Overflow
    GOTO	Nooverflow		; No over no counter change
    Overflow:
    CLRF	counter	    		; Reset to zero if is
    BANKSEL	PORTA
    INCF	PORTA			; Increment PORTA on overflow
    Nooverflow:
    BCF		STATUS,Z
    
    
    BANKSEL	0			
    MOVFW	counter			;For function
    CALL	intTO7seg		;Convert to seven segment out
    MOVWF	PORTC			;Output result to PORTA
    
    

    
    BANKSEL	INTCON			; In order to clear overflow flag 
    BCF		INTCON,TMR0IF		; clear interrupt flag TMR0IF
    BANKSEL	STATUS
    BCF		STATUS,C		; Clear carry flag from earlier check    
    
    
    
    
    return
    
    
    
    
    
end