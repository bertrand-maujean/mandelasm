; Compilation par :
; $ nasm -g -f elf64 -l mandel.lst mandel.asm 
; $ ld mandel.o 
; $ ./a.out 
; site qui permet d'afficher les coordonnées, pour faire les animations :
; http://www.atopon.org/mandel/#




BITS 64
CPU X64


; *********************************************************
; * Constantes 
; *********************************************************
;CONST_NBDEC	equ 100


; *********************************************************
; * Données statiques
; *********************************************************
section .data

msg		db "Hello world", 10,0
largeur_ecran	dd 300	; sur 32 bits pour faciliter fild
hauteur_ecran	dd 100

xmin		dq -2.25
xmax		dq 0.75
ymin		dq -1.5
ymax		dq 1.5

max_iter	dq 64


un	dq 1.0e0
deux	dq 2.0e0
trois   dq 3.0e0
quatre  dq 4.0e0

car	db "X",0 ; utilisé pour appeler PrintZ sur des caractères
crlf	db 10,0



; *********************************************************
; * Données statiques non initialisées
; *********************************************************
section .bss


; terme courant de la suite Zn 
ZnR	resq 1
ZnI	resq 1

; Affixe du pixel en cours de calcul
CR	resq 1
CI	resq 1

; Coord sur l'ecran d'un caractere
I	resd 1
J	resd 1

; *********************************************************
; * Segment de code
; *********************************************************
section .text

global _start
_start:

	mov dword [J], 0
.bcleL:

	mov dword [I], 0


.bcleC:
	call calcule_point
	add al, 32
	mov byte [car], al
	mov rax, car
	call printz
	
	mov eax, [largeur_ecran]
	inc dword [I]
	cmp dword [I], eax
	jb .bcleC
	
	; fin d'une ligne, on envoie un crlf
	mov eax, crlf
	call printz
	
	mov eax, [hauteur_ecran]
	inc dword [J]
	cmp dword [J], eax
	jb .bcleL
	
	
	; sys_exit
	mov rax, 60
	mov rdi, 0
	syscall





calcule_point:
	mov eax, [I]
	cdqe
	push rax
	mov eax, [J]
	cdqe
	push rax
	call calcule_affixe
	pop qword [CI] ; partie reelle
	pop qword [CR] ; imaginaire
	
	; Met à zéro Zn
	fldz
	fst qword [ZnR]
	fstp qword [ZnI]
	
	mov r8,0 ; va contenir le nb d'iterations
	
.bcle1:	
	call iteration 
	
	fld1
	fld1
	faddp ; st0 = 2.0
	
	fcompp
	fstsw ax
	and ah, 0b01000111
	cmp ah, 0b00000001
	je .divergence
	 
	; Ici |Zn| < 2 
	inc r8
	cmp r8, [max_iter] ; fait jusqu'à 100 iterations
	jb .bcle1
	 
.divergence: ; traiter le cas |Zn| > 2
	; ici, r8 contient le nb d'iterations faites 
	mov rax, r8
	
	 
	ret
	 
	 
	


; *********************************************************
; * Calcule l'affixe correspondant à un caractère sur le terminal
; * Entrée : RDI, RSI = coordonnées i,j sur le terminal ascii
; * Sortie : RDI+i*RSI = affixe du point
; *********************************************************

; [rbp+24] : coord écran i à l'entrée, partie réelle au retour
; [rbp+16] : coord écran j à l'entrée, partie imaginaire au retour
; [rbp +8] : rip de retour
; [rbp +0] : ancien rbp
; [rbp -8] : var locale 1
; [rbp-16] : var locale 2 ... 

calcule_affixe:
	push rbp
	mov rbp, rsp
	sub rsp, 0 ; nb de variables locales à réserver
	
	finit
	
	; traite i et x
	fld qword [xmax]
	fld qword [xmin]
	fsub		; xmax-xmin
	fild qword [rbp+24]
	fmul	; * i
	fild dword [largeur_ecran]
	fdiv ; / largeur_ecran
	fld qword [xmin]
	fadd
	fstp qword [rbp+24]
	
	; traite j et y
	fld qword [ymax]
	fld qword [ymin]
	fsub
	fild qword [rbp+16]
	fmul
	fild dword [hauteur_ecran]
	fdiv
	fld qword [ymin]
	fadd
	fstp qword [rbp+16]
	
	mov rsp, rbp
	pop rbp
	ret
	


; *********************************************************
; * Itération : Zn <- Zn^2 + C
; * Sortie : sur la stack x87, module de Zn
; * Attention : la stack contient du coup une valeur de plus en sortie
; *********************************************************
iteration:
	fld qword [ZnR]
	fld st0
	fmulp ; re²
	fld qword [ZnI]
	fld st0
	fmulp ; Im^2 
	fsubp
	fld qword [CR] ; +Re(c)
	faddp
	; Ici, on laisse Re(Zn+1) sur la stack

	fld qword [ZnI]
	fld qword [ZnR]
	fmulp
	fld1
	fld1
	faddp
	fmulp
	fld qword [CI]
	faddp
	; ici on a Im(Zn+) en st0
	
	fstp qword [ZnI] ; stocke Zn+1
	fstp qword [ZnR]
	
	; calcul du module de Zn+1
	fld qword [ZnR]
	fld st0
	fmulp
	fld qword [ZnI]
	fld st0
	fmulp
	faddp
	fsqrt
	
	ret

; *********************************************************
; * Affiche sur stdout, une chaine ASCIIZ
; * Entrée : RAX=Adresse de la chaine
; *********************************************************
printz:
	push rbp
	mov rbp, rsp
	
	push rax
	push rbx
	push rcx
	push rdx
	push rsi
	push rdi
	push r11
	push r12
	push r13
	
	
	mov rdx,0
	mov rbx,rax
	
.b1:
	cmp byte [rbx], 0
	jz .fin_trouvee
	inc rbx
	inc rdx
	jmp .b1
	
	
.fin_trouvee: ; on est sur le 0 final
	cmp rdx,0
	jz .chaine_nulle	; la chaine etait de longueur nulle, on ne va pas faire un appel systeme pour ça
	
	mov rsi, rax
	mov rax, 1
	mov rdi, 1
	syscall
	
.chaine_nulle:
	pop r13
	pop r12
	pop r11
	pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	pop rax

	mov rsp, rbp
	pop rbp
	ret
	
