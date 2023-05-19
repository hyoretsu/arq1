extern printf
extern scanf

section .data
    invalidOptionMessage db "Comando não reconhecido, tente novamente.", 0AH, 0H
    menu db "----- Bem vindo à Cifra de César! -----", 0AH, "1) Criptografar", 0AH, "2) Descriptografar", 0AH, "3) Criptoanálise", 0AH, "4) Sair", 0AH, "Sua escolha: ", 0H
    option dd 0

    intFormat db "%d", 0H
    strFormat db "%s", 0H

    sys_exit dw 0

section .text
    global main

    main:
        call showMenu
        call getOption

        mov eax, [option]
        cmp eax, 1
            jl invalidOption
            je exit
        cmp eax, 2
            je exit
        cmp eax, 3
            je exit
        cmp eax, 4
            je exit
            jg invalidOption

        ret

    showMenu:
        mov rdi, strFormat
        mov rsi, menu
        mov rax, 0
        call printf

        ret

    getOption:
        mov rdi, intFormat
        mov rsi, option
        call scanf

        ret

    invalidOption:
        mov rdi, strFormat
        mov rsi, invalidOptionMessage
        mov rax, 0
        call printf

        ret

    exit:
        mov ebx, sys_exit
        mov eax, 1
        int 80h

        ret
