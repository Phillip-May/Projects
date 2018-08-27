#include "p16F887.inc"

; CONFIG1
; __config 0x3FF5
    __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_OFF & _FCMEN_OFF & _LVP_ON
; CONFIG2
; __config 0x3FFF
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;**************** DEFINING VARIABLES ****************************************

    cblock	0x20		;Block of variables in PORT0
		
		; 21h used for 7segment converter

    endc
    ;prgFlags assigment
    ;b'76543210'
    ;bit 0 is for counting
    ;bit 1 is for if the digit 2 was already incremented this cycle
    ;
    ;Counting: 0 means not counting 1 means counting
    
    cblock      0x70		; Block of variables starts at address 70h
		W_TEMP		; 70h stores working register for interupts
		STATUS_TEMP	; 71h stores status register
		tmrDigit1	; LSB of time display
		tmrDigit2	; MSB of time display
		prgFlags	; Progress flags
		counter		; used for display delay
		counter2	; used for display delay
		GLOBALcounter	; used for number of cars passed by
		int_TEMPORARY	; used in EEPROM mode counter 1 or 2 could probably bw hijaked if needed
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
    
    BANKSEL	PORTA
    MOVLW	b'00001001'
    MOVWF	PORTA
    BANKSEL	PORTD

    BANKSEL	tmrDigit1
    INCF	tmrDigit1
    
    MOVFW	tmrDigit1
    MOVFW	tmrDigit2
    BANKSEL	TMR0
    MOVLW	.56			; Makes constant 200
    ADDWF	TMR0,1

    BANKSEL	INTCON			; In order to clear overflow flag 
    bcf		INTCON,TMR0IF		; clear interrupt flag TMR0IF
;************************ ISR context loading from datasheet ****************
    SWAPF 	STATUS_TEMP,W		;swap STATUS_TEMP register into W, sets bank to original state
    MOVWF 	STATUS		        ;move W into STATUS register
    SWAPF 	W_TEMP,F	  	;swap W_TEMP
    SWAPF 	W_TEMP,W          	;swap W_TEMP into W

    retfie		                ;Return from interrupt routine
       
;************************ MAIN PROGRAM **************************************
main                                ;Start of the main program
    
Call		mSETUP		    ;Setup for main loop

loop:

    
    
BANKSEL		PORTB
MOVFW		PORTB

BANKSEL		tmrDigit1
MOVFW		tmrDigit1

		
;Overflow checks		
;Checks if either digit is equal to 10
;tmrDigit1 overflow means increment digit2 and reset digit1
BANKSEL		tmrDigit1
MOVFW		tmrDigit1
BANKSEL		STATUS
ADDLW		b'11110110'
BTFSS		STATUS,C
GOTO		enddigit1overflow
BANKSEL		tmrDigit1
CLRF		tmrDigit1

BANKSEL		tmrDigit2
MOVFW		tmrDigit2
ADDLW		b'00000001'
MOVWF		tmrDigit2
		
enddigit1overflow:
;tmrDigit2 overflow means digit2 and set counting flag to 0 and clear timers
BANKSEL		tmrDigit2
MOVFW		tmrDigit2
BANKSEL		STATUS
ADDLW		b'11110110'
BTFSS		STATUS,C
GOTO		enddigit2overflow

BANKSEL		tmrDigit1
CLRF		tmrDigit2
BANKSEL		tmrDigit2
CLRF		tmrDigit2
;Set display to zero
BANKSEL		PORTC
CLRF		PORTC
;Clear flag for counting    
BANKSEL		prgFlags
BCF		prgFlags,0

enddigit2overflow:

;Global counter overflow check
;if it's 10 set it back to 1
BANKSEL		GLOBALcounter
MOVFW		GLOBALcounter
BANKSEL		STATUS
ADDLW		b'01101111'
BTFSS		STATUS,C
GOTO		endGLOBALcounteroverflow
BANKSEL		GLOBALcounter
CLRF		GLOBALcounter

endGLOBALcounteroverflow:
    
;Mode switch check
BANKSEL		PORTB
BTFSS		PORTB,5
CALL		EEPROMMODE
;Else do nothing
    
    
    
    
    
    
;Start button check 
BANKSEL		prgFlags		;Check that it's not already running
BTFSC		prgFlags,0		;Low means not running	
GOTO		ENDSTARTCHECK
;Only runs this when flag is not set
BANKSEL		PORTB
BTFSC		PORTB,1			;Active low butoon
GOTO		ENDSTARTCHECK
;Start is clear (being pressed)
BANKSEL		tmrDigit1
CLRF		tmrDigit1
BANKSEL		tmrDigit2
CLRF		tmrDigit2  
BSF		prgFlags,0		;Start counting  
;Need to set flags and reset counter
ENDSTARTCHECK:
;End of start button check

    
    
; Stopping check
BANKSEL		prgFlags  
BTFSS		prgFlags,0		;high means running
GOTO		ENDSTOPCHECK
;Check if counter is running hig
;Do this if flag is set (meaning stopped)
;Check if stop button was pressed
BANKSEL		PORTB
BTFSC		PORTB,4
GOTO		ENDSTOPCHECK


CALL		WRITECHANGE
BANKSEL		GLOBALcounter
MOVFW		GLOBALcounter	; increment 
ADDLW		b'00010000'
MOVWF		GLOBALcounter    
CALL		SAVERESULT	; Save the results

    
    
    
;lazy solution to delay being too short.
CALL		DISPLAYDELAY	; so you can read
CALL		DISPLAYDELAY	; so you can read
CALL		DISPLAYDELAY	; so you can read
;end of quick solution
;Reset the values
BANKSEL		tmrDigit1
CLRF		tmrDigit2
BANKSEL		tmrDigit2
CLRF		tmrDigit2
BANKSEL		prgFlags
BCF		prgFlags,0
BANKSEL		PORTC		; Set counter back to zero display
CLRF		PORTC
ENDSTOPCHECK:
;END of stopping check
    

BTFSC		prgFlags,0
Call		WRITECHANGE
;Only display a non zero value when counter is running and therefore reset properly
    
    goto        loop            ; Remain here

  
mSETUP
    ;All the setup for the main loop before the main code runs
    ;Includes allowing interupts, tmr0 interupt, setting oscillator
    ;speed to 2MHZ, reseting tmr0 and setting up pins.
    
    ;Disable all interupts during setup
    BANKSEL	 INTCON		    ; In oder to disable all interupts during setup
    BCF		 INTCON,GIE	    ; Disabled during setup


    
    
;START of PORTC setup    

    
    ;Set all pins to digital to avoid potential problems
    BANKSEL	ANSEL		    ;
    MOVLW	b'00000000'	    ;
    MOVWF	ANSEL		    ;Set PORTA to digital

    BANKSEL	ANSELH		    ;Set all of port A to digital IO
    MOVLW	b'00000000'	    ;
    MOVWF	ANSELH		    ;0 means digital

    ;PORTA setup
    BANKSEL	PORTA
    CLRF	PORTA
    BANKSEL	TRISA
    CLRF	TRISA
    
    ;PORTB setup (input)
    BANKSEL	PORTB
    CLRF	PORTB
    BANKSEL	TRISB
    MOVLW	b'11111111'
    MOVFW	TRISB    
    
    ;PORTC setup
    BANKSEL	PORTC		    
    CLRF	PORTC		      
    BANKSEL	TRISC		    
    CLRF	TRISC 
    
    ;PORTD setup
    BANKSEL	PORTD
    CLRF	PORTD
    BANKSEL	TRISD
    CLRF	TRISD
    

    BANKSEL	INTCON
    BSF		INTCON,T0IE	    ; Enables interupt for timer0 instead of polling
    
    BANKSEL	OSCCON		    ; Set clock to 2Mhz/ b'101' 6-4
    BSF		OSCCON,6
    BCF		OSCCON,5
    BSF		OSCCON,4
    
    
    BANKSEL	OPTION_REG	    ; Assign prescaller to WDT (1:1 tmr0)
    bcf         OPTION_REG,T0CS	    ; TMR0 counts pulses from instruction cycle       
    bcf         OPTION_REG,PSA	    ; Prescaler is assign to TIMER0
    ;Set prescaller to 1:256
    BSF		OPTION_REG,PS2
    BSF		OPTION_REG,PS1
    BSF		OPTION_REG,PS0
        
    
    banksel	TMR0		    ; Clear timer0 and counter
    clrf	TMR0
    clrf	counter

    ;Clear counters from previous run
    BANKSEL	tmrDigit1
    CLRF	tmrDigit1    
    BANKSEL	tmrDigit2
    CLRF	tmrDigit2
    BANKSEL	prgFlags
    CLRF	prgFlags
    BANKSEL	GLOBALcounter
    CLRF	GLOBALcounter
    
    
    ;Setup timer for first time
    BANKSEL	TMR0
    CLRF	TMR0
    MOVLW	.56			; Makes constant 200
    ADDWF	TMR0,1

    
 
;Enable interupts after setup
    BANKSEL	INTCON		    ; Enable interupts after setup
    BSF		INTCON,GIE	    ; Enabled after setup

    
    RETURN	;End of setup

    
WRITECHANGE
    ;Write the values of tmrDigit1 and tmr Digit2 to portC
    ;Upper half of portC is connected to lower half of display so code here
    ;uses some weird unesary swapping.
    
    MOVLW	b'00000000'
    BANKSEL	tmrDigit1
    ADDWF	tmrDigit1,0
    SWAPF	tmrDigit1,0	
    BANKSEL	tmrDigit2
    ADDWF	tmrDigit2,0
    BANKSEL	PORTC
    MOVWF	PORTC
    
    

    
    return

DISPLAYDELAY
    ;For holding values shown on the 7segment for display purposes
    ;Just a standard software delay instead of using counters
    
    ;For debugging purposes this can be shorted or simply skipped
    
    ;Start
    MOVLW	b'11111111'
    MOVWF	counter2
	
    ;start inner
    DELAYOUTER:
    MOVLW	b'11111111'
    MOVWF	counter
    DELAYINNER:
    DECFSZ	counter
    GOTO	DELAYINNER
    ;end of inner
    DECFSZ	counter2
    GOTO	DELAYOUTER
    ;End of software delay
    
    
    return
    
SAVERESULT    
    ;SAVE the result to EEPROM
    ;Temporarilly disables INTERUPTS because datasheet said I should
    ;Also increments and updates display of global
    BANKSEL	 INTCON		    ; Disable interupt
    BCF		 INTCON,GIE	    ; 
    

    ;EEPROM write 2 bytes, 7segment display and global counter
    CALL	WRITECHANGE	    ;Convert 2 variables into one to save space
    ;*********************Start of EEPROM write code from datasheet*******************
    BANKSEL	EEADR		    ;EEADR is EEPROM adress
    BANKSEL	GLOBALcounter	    ;
    SWAPF	GLOBALcounter,0	    ;Current global counter is where value will be put
    BANKSEL	EEADR		    ;
    MOVWF	EEADR		    ;Location to write (current value of GLOBAl)
    BANKSEL	PORTC		    ;
    MOVFW	PORTC	    	    ;
    BANKSEL	EEADR		    ;Adding this in to make up for portc select
    MOVWF	EEDAT		    ;Data that will be saved
    BANKSEL	EECON1		    
    BCF		EECON1,EEPGD	    ;Point to DATA memory
    BSF		EECON1,WREN	    ;Enable writting to EEPROM
    
    BCF		INTCON, GIE	    ;Disable interupts
    BTFSC	INTCON, GIE	    ;Some stupid architecture limitation
    GOTO	$-2
    ;Begin required sequence
    MOVLW	55h
    MOVWF	EECON2		    ;Secret code or something to actually write		    
    MOVLW	0xAA
    ;So datasheet said use AAh here but that dosen't compile so I used 0xAA
    ;Hopefully this works
    MOVWF	EECON2		    ;Secret code part 2
    BSF		EECON1,WR	    ;Set WR bit to begin write
    BSF		INTCON,GIE	    ;Re enable interupts
    BCF		EECON1,WREN	    ;Disable EEPROM writes again,
    ;****************End of datasheet EEPROM write code**************************************		
    BANKSEL	STATUS		    ; Return back to bank 0 after code
    BCF		STATUS,RP0
    BCF		STATUS,RP1
    
    BANKSEL	INTCON		    ; 
    BSF		INTCON,GIE	    ; ReEnable interupt
    ;Update global display
    MOVFW	GLOBALcounter
    BANKSEL	PORTD
    MOVWF	PORTD        
    ;Sleep
    return
   
EEPROMMODE
    ;EEPROM viewer mode code
    ;Make sure program is not actvely running.
    BANKSEL		prgFlags		;Check that it's not already running
    BTFSC		prgFlags,0		;Low means not running	
    RETURN					;Do not go into EEPROM mode
    BANKSEL		int_TEMPORARY
    CLRF		int_TEMPORARY
    CALL		DISPLAYDELAY		;Give user time to release the button after pressing it.
    CALL		DISPLAYDELAY		;Give user time to release the button after pressing it.
    CALL		DISPLAYDELAY		;Give user time to release the button after pressing it.
    EEPROMstart:
    
    
    
    BTFSS	PORTB,5		    ; exit test
    GOTO	EEPROMend	    ; If exit button pressed exit
    ;button not pressed
    ;For now try displaying the first value only

;Start of int_TEMPORARY increment and decrement checks
;Check if Viewmode should be incremented    
    BANKSEL		PORTB
    BTFSC		PORTB,4			;Active low butoon
    GOTO		ENDINCCHECK
    ;Decrement button clear (being pressed)    
    INCF		int_TEMPORARY    
    ENDINCCHECK:
;Check if viewmode should be decremented
    BANKSEL		PORTB
    BTFSC		PORTB,1			;Active low butoon
    GOTO		ENDDECCHECK
;Decrement button clear (being pressed)    
    DECF		int_TEMPORARY    
    ENDDECCHECK:
;int_TEMPORARY overflow and underflow checks
BANKSEL		int_TEMPORARY
MOVFW		int_TEMPORARY
BANKSEL		STATUS
ADDLW		b'11110110'
BTFSS		STATUS,C
GOTO		inttempoverflowcheck
;Else
CLRF		int_TEMPORARY
    
inttempoverflowcheck:
BANKSEL		int_TEMPORARY
MOVFW		int_TEMPORARY
BANKSEL		STATUS
XORLW		b'11111111'
BTFSS		STATUS,Z
GOTO		inttempunderflowcheck
;Else
BANKSEL		int_TEMPORARY
CLRF		int_TEMPORARY
MOVLW		b'00001001'
MOVWF		int_TEMPORARY
    
inttempunderflowcheck:
    
    
    
    BANKSEL	int_TEMPORARY
    MOVFW	int_TEMPORARY
    ;MOVLW	b'00000001'	    ;For testing
;*************************EEPROM read code from datasheet************************
    BANKSEL	EEADR
    MOVWF	EEADR		    ; Data memory
    BANKSEL	EECON1		    ;
    BCF		EECON1, EEPGD	    ; Point to data memory?
    BSF		EECON1, RD	    ; EE Read?
    BANKSEL	EEDAT
    MOVF	EEDAT,w		    ;W = EEDAT
    BCF		STATUS, RP1	    ;Return to Bank 0
;************************EEPROM read code from datasheet end********************
    BANKSEL	PORTC
    MOVWF	PORTC		    ;Show EEPROM value on PORTC
    BANKSEL	int_TEMPORARY
    SWAPF	int_TEMPORARY,0	    ;Put int_temporary on portD for output
    MOVWF	PORTD
    
    CALL	DISPLAYDELAY	    ;Slow down loop to allow user to release button
    GOTO	EEPROMstart
    
  
    
    
    EEPROMend:
    BANKSEL	PORTC
    MOVLW	b'00000000'			;Set counter back to displaying 0
    MOVWF	PORTC				
    BANKSEL	GLOBALcounter
    MOVFW	GLOBALcounter
    BANKSEL	PORTD				;Restore global counter to normal
    MOVWF	PORTD  
    
    CALL	DISPLAYDELAY		;Give user time to release the button after pressing it.
    CALL	DISPLAYDELAY		;Give user time to release the button after pressing it.
    return
    
    
end