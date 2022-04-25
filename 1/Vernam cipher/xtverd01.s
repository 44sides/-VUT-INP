; Vernamova sifra na architekture DLX
; Vladyslav Tverdokhlib xtverd01
; r2-r7-r19-r22-r26-r0 my registers
; 97-122 ASCII alphabet

        .data 0x04          ; zacatek data segmentu v pameti
login:  .asciiz "xtverd01"  ; <-- nahradte vasim loginem
cipher: .space 9 ; sem ukladejte sifrovane znaky (za posledni nezapomente dat 0)

        .align 2            ; dale zarovnavej na ctverice (2^2) bajtu
laddr:  .word login         ; 4B adresa vstupniho textu (pro vypis)
caddr:  .word cipher        ; 4B adresa sifrovaneho retezce (pro vypis)

        .text 0x40          ; adresa zacatku programu v pameti
        .global main        ; 

main:	addi r22,r0,-1      ; counter (index)
	addi r2,r0,0        ; symbol parity indicator

start:	addi r22,r22,1      ; iteration

	lb r19, login(r22)  ; load a symbol from login

	sgti r26,r19,96     ; checks if a symbol is letter
	beqz r26, quit      ;
	; branch delay slots
	nop
	nop

	beqz r2, even       ; checks on even parity
	nop
	nop

	; replacement for odd parity
	subi r19,r19,22      ; substracts key symbol
	addi r2,r0,0         ; indicator change
	slti r26,r19,97      ; checks on underflow
	beqz r26, store
	nop
	nop
	addi r19,r19,26      ; rotating
	j store
	nop
	nop

	; replacement for even parity
even:	addi r19,r19,20      ; adds key symbol
	addi r2,r0,1			     ; indicator change
	sgti r26,r19,122     ; checks on overflow
	beqz r26, store
	nop
	nop
	subi r19,r19,26      ; rotating

store:sb cipher(r22), r19    ; store to cipher from r19
	j start              ; returns back
	nop
	nop

quit:	sb cipher(r22), r0   ; NULL at the end
end:    addi r14, r0, caddr ; <-- pro vypis sifry nahradte laddr adresou caddr
        trap 5  ; vypis textoveho retezce (jeho adresa se ocekava v r14)
        trap 0  ; ukonceni simulace
