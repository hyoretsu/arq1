extern printf
extern scanf

section .data
    menu db "----- Bem vindo à Cifra de César! -----", 0AH, "1) Criptografar", 0AH, "2) Descriptografar", 0AH, "3) Criptoanálise", 0AH, "4) Sair", 0AH, "Sua escolha: ", 0AH, 0H
    strFormat db "%s", 0H

section .text
    global main

    main:
        call showMenu

        ret

    showMenu:
        mov rdi, strFormat
        mov rsi, menu
        call printf

        ret
