PROCESSOR 18F8722

#include <xc.inc>
    
; CONFIGURATION (DO NOT EDIT)
; CONFIG1H
CONFIG OSC = HSPLL      ; Oscillator Selection bits (HS oscillator, PLL enabled (Clock Frequency = 4 x FOSC1))
CONFIG FCMEN = OFF      ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
CONFIG IESO = OFF       ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)
; CONFIG2L
CONFIG PWRT = OFF       ; Power-up Timer Enable bit (PWRT disabled)
CONFIG BOREN = OFF      ; Brown-out Reset Enable bits (Brown-out Reset disabled in hardware and software)
; CONFIG2H
CONFIG WDT = OFF        ; Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit))
; CONFIG3H
CONFIG LPT1OSC = OFF    ; Low-Power Timer1 Oscillator Enable bit (Timer1 configured for higher power operation)
CONFIG MCLRE = ON       ; MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled)
; CONFIG4L
CONFIG LVP = OFF        ; Single-Supply ICSP Enable bit (Single-Supply ICSP disabled)
CONFIG XINST = OFF      ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))
CONFIG DEBUG = OFF      ; Disable In-Circuit Debugger

; Define space for the variables in RAM
PSECT udata_acs
break: DS 1
    
seq0: DS 1
seq1: DS 1
seq2: DS 1
seq3: DS 1
seq4: DS 1
seq5: DS 1
seq_index: DS 1
    
is_re_pressed: DS 1		    ; initialized in init ; note that we ignore RE6
is_re_released: DS 1		    ; initialized in init
is_seq_paused: DS 1		    ; initialized in init
is_rd0_changed: DS 1		    ; initialized in init

nonbusy_counter_hi: DS 1	    ; initialized in init
nonbusy_counter_lo: DS 1	    ; initialized in init
nonbusy_overflow_reg: DS 1	    ; initialized in init
nonbusy_wait_completed: DS 1	    ; initialized in init

busy_counter_hi: DS 1		    ; initialized in init
busy_counter_lo: DS 1		    ; initialized in init
busy_overflow_reg: DS 1		    ; initialized in init
    
PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto       main

PSECT CODE

; nonbusy_counter_value = 20 = 0x0014 (470 msec)
nonbusy_counter_value_hi equ	0x00
nonbusy_counter_value_lo equ	0x14
 
; busy_counter_value = 978 = 0x03D2 (1 sec)
busy_counter_value_hi equ    0x03  
busy_counter_value_lo equ    0xD2
 
main:
    call init
    loop:
	call inc_nonbusy_overflow_reg
	call check_button_press
	call check_button_release
	call seq_update_task
	call blink_RD0_LED	    ; note that if RD0 blink occurs, progress_sequence is called directly from blink_RD0_LED
	bra loop
    goto main

inc_nonbusy_overflow_reg:
    incf nonbusy_overflow_reg
    bz dec_nonbusy_counter
    return
    
dec_nonbusy_counter:
    decf nonbusy_counter_lo
    bnz return_from_any_function
    movf nonbusy_counter_lo, 0, 0
    iorwf nonbusy_counter_hi, 0, 0
    bz update_nonbusy_wait_completed
    setf nonbusy_counter_lo
    decf nonbusy_counter_hi
    return
   
update_nonbusy_wait_completed:
    bsf nonbusy_wait_completed, 0, 0
    movlw nonbusy_counter_value_hi  ; set the counter's low and high bytes
    movwf nonbusy_counter_hi, 0
    movlw nonbusy_counter_value_lo
    movwf nonbusy_counter_lo, 0
    
return_from_any_function:
    return
    
blink_RD0_LED:
    btfss nonbusy_wait_completed, 0, 0
    return
    movlw 1
    xorwf LATD, 1, 0
    call progress_sequence
    bcf nonbusy_wait_completed, 0, 0
    return
    
progress_sequence:
    btfsc is_seq_paused, 0
    return
    
    movlw 0
    movwf break, 0
    cpfsgt seq_index, 0
    call progress_sequence_if_index_is_0
    btfsc break, 0, 0
    return
    movlw 1
    cpfsgt seq_index, 0
    call progress_sequence_if_index_is_1
    btfsc break, 0, 0
    return
    movlw 2
    cpfsgt seq_index, 0
    call progress_sequence_if_index_is_2
    btfsc break, 0, 0
    return
    movlw 3
    cpfsgt seq_index, 0
    call progress_sequence_if_index_is_3
    btfsc break, 0, 0
    return
    movlw 4
    cpfsgt seq_index, 0
    call progress_sequence_if_index_is_4
    btfsc break, 0, 0
    return
    movlw 5
    cpfsgt seq_index, 0
    call progress_sequence_if_index_is_5
    return
    
progress_sequence_if_index_is_0:
    movff seq0, LATC
    incf seq_index, 1, 0
    movlw 1
    movwf break, 0
    return
progress_sequence_if_index_is_1:
    movff seq1, LATC
    incf seq_index, 1, 0
    movlw 1
    movwf break, 0
    return
progress_sequence_if_index_is_2:
    movff seq2, LATC
    incf seq_index, 1, 0
    movlw 1
    movwf break, 0
    return
progress_sequence_if_index_is_3:
    movff seq3, LATC
    incf seq_index, 1, 0
    movlw 1
    movwf break, 0
    return
progress_sequence_if_index_is_4:
    movff seq4, LATC
    incf seq_index, 1, 0
    movlw 1
    movwf break, 0
    return
progress_sequence_if_index_is_5:
    movff seq5, LATC
    movlw 0
    movwf seq_index, 0
    movlw 1
    movwf break, 0
    return
    
check_button_press:
    btfsc PORTE, 0, 0
    bsf is_re_pressed, 0, 0
    btfsc PORTE, 1, 0
    bsf is_re_pressed, 1, 0
    btfsc PORTE, 2, 0
    bsf is_re_pressed, 2, 0
    btfsc PORTE, 3, 0
    bsf is_re_pressed, 3, 0
    btfsc PORTE, 4, 0
    bsf is_re_pressed, 4, 0
    btfsc PORTE, 5, 0
    bsf is_re_pressed, 5, 0
    btfsc PORTE, 7, 0
    bsf is_re_pressed, 7, 0
    return

check_button_release:
    call check_RE0_release
    call check_RE1_release
    call check_RE2_release
    call check_RE3_release
    call check_RE4_release
    call check_RE5_release
    call check_RE7_release
    return
    
check_RE0_release:
    btfss is_re_pressed, 0, 0	    ; if RE0 was not pressed, it cannot be released -> no need to proceed further
    return
    btfsc PORTE, 0, 0		    ; if RE0 is 1, it is still pressed -> no need to proceed further
    return
    bsf is_re_released, 0, 0
    bcf is_re_pressed, 0, 0
    return
check_RE1_release:
    btfss is_re_pressed, 1, 0	    ; if RE1 was not pressed, it cannot be released -> no need to proceed further
    return
    btfsc PORTE, 1, 0		    ; if RE1 is 1, it is still pressed -> no need to proceed further
    return
    bsf is_re_released, 1, 0
    bcf is_re_pressed, 1, 0
    return
check_RE2_release:
    btfss is_re_pressed, 2, 0
    return
    btfsc PORTE, 2, 0
    return
    bsf is_re_released, 2, 0
    bcf is_re_pressed, 2, 0
    return
check_RE3_release:
    btfss is_re_pressed, 3, 0
    return
    btfsc PORTE, 3, 0
    return
    bsf is_re_released, 3, 0
    bcf is_re_pressed, 3, 0
    return
check_RE4_release:
    btfss is_re_pressed, 4, 0	
    return
    btfsc PORTE, 4, 0		
    return
    bsf is_re_released, 4, 0
    bcf is_re_pressed, 4, 0
    return
check_RE5_release:
    btfss is_re_pressed, 5, 0	
    return
    btfsc PORTE, 5, 0		
    return
    bsf is_re_released, 5, 0
    bcf is_re_pressed, 5, 0
    return
check_RE7_release:
    btfss is_re_pressed, 7, 0	
    return
    btfsc PORTE, 7, 0		
    return
    bsf is_re_released, 7, 0
    bcf is_re_pressed, 7, 0
    movlw 1
    xorwf is_seq_paused, 1, 0	    ; toggle is_seq_paused when RE7 is released
    return
	
seq_update_task:
    movlw 0
    btfsc is_re_released, 0, 0
    call inc_seq0
    btfsc is_re_released, 1, 0
    call inc_seq1
    btfsc is_re_released, 2, 0
    call inc_seq2
    btfsc is_re_released, 3, 0
    call inc_seq3
    btfsc is_re_released, 4, 0
    call inc_seq4
    btfsc is_re_released, 5, 0
    call inc_seq5
    return
	
inc_seq0:
    bcf is_re_released, 0, 0
    incf seq0, 1, 0
    movlw 10
    cpfseq seq0, 0
    return
    movlw 0
    movwf seq0, 0
    return
inc_seq1:
    bcf is_re_released, 1, 0
    incf seq1, 1, 0
    movlw 10
    cpfseq seq1, 0
    return
    movlw 0
    movwf seq1, 0
    return
inc_seq2:
    bcf is_re_released, 2, 0
    incf seq2, 1, 0
    movlw 10
    cpfseq seq2, 0
    return
    movlw 0
    movwf seq2, 0
    return
inc_seq3:
    bcf is_re_released, 3, 0
    incf seq3, 1, 0
    movlw 10
    cpfseq seq3, 0
    return
    movlw 0
    movwf seq3, 0
    return
inc_seq4:
    bcf is_re_released, 4, 0
    incf seq4, 1, 0
    movlw 10
    cpfseq seq4, 0
    return
    movlw 0
    movwf seq4, 0
    return
inc_seq5:
    bcf is_re_released, 5, 0
    incf seq5, 1, 0
    movlw 10
    cpfseq seq5, 0
    return
    movlw 0
    movwf seq5, 0
    return
	
init:
    movlw 2			    ; initialize the sequence
    movwf seq0, 0
    movlw 6
    movwf seq1, 0
    movlw 4
    movwf seq2, 0
    movlw 3
    movwf seq3, 0
    movlw 2
    movwf seq4, 0
    movlw 5
    movwf seq5, 0		
    
    setf nonbusy_wait_completed, 0
    clrf seq_index, 0
    clrf nonbusy_overflow_reg, 0
    clrf busy_overflow_reg, 0
    clrf is_re_pressed, 0
    clrf is_re_released, 0
    clrf is_seq_paused, 0

    movlw busy_counter_value_hi     ; set the busy counter's low and high bytes
    movwf busy_counter_hi, 0
    movlw busy_counter_value_lo
    movwf busy_counter_lo, 0
    movlw nonbusy_counter_value_hi  ; set the nonbusy counter's low and high bytes
    movwf nonbusy_counter_hi, 0
    movlw nonbusy_counter_value_lo
    movwf nonbusy_counter_lo, 0
    
    setf TRISE, 0		    ; open PORT E for reading
    clrf TRISC, 0		    ; open PORT C for writing
    clrf TRISD, 0		    ; open PORT D for writing
    
    movlw 0xFF
    movwf LATC, 0		    ; LED ON all 8 bits of LAT C
    movwf LATD, 0		    ; LED ON all 8 bits of LAT D
    
    call busy_wait
    
    ledoff_c_d:
	movlw 0x00
	movwf LATC, 0
	movwf LATD, 0
	bsf is_rd0_changed, 0
    
    return
	
busy_decrement_counter:		    ; decrement the two byte counter
    decf busy_counter_lo, 1, 0
    bnz busy_wait		    ; nothing more to do if low byte is not zero
    
    movff busy_counter_lo, WREG	    ; check if both bytes are zero
    iorwf busy_counter_hi, 0, 0
    bz ledoff_c_d
    
    setf busy_counter_lo, 0	    ; low is zero so reset it and decrement the high byte
    decf busy_counter_hi, 1, 0
    
    goto busy_wait    
    
busy_wait:			    ; delay loop
    incf busy_overflow_reg, 1, 0    ; 1 cycle
    bz busy_decrement_counter
    goto busy_wait		    ; 2 cycles
    
end resetVec