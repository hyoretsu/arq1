global _start

section .bss
    fileBuffer resd 513
    fileHandle resd 1
    filename resb 4096 ; Max path size in Linux
    inputLength resd 1
    option resd 1
    outputFileHandle resd 1
    readBytes resd 1
    tmp resb 1

section .data
    askForKey db "Digite a chave de criptografia/descriptografia: ", 0H
    decryptionSuccessMessage db "Concluído, sua mensagem está disponível em 'output.txt'.", 0AH, 0H
    enterFilename db "Digite o caminho/nome do arquivo de entrada: ", 0H
    encryptionSuccessMessage db "Concluído, sua mensagem encriptada está disponível em 'output.txt'.", 0AH, 0H
    errorMessage db "Houve um erro inesperado, tente novamente.", 0H
    fileNotFoundMessage db "Este arquivo não existe, tente novamente.", 0AH, 0H
    invalidOptionMessage db "Comando não reconhecido, tente novamente.", 0H
    menu db "----- Bem vindo à Cifra de César! -----", 0AH, "1) Criptografar", 0AH, "2) Descriptografar", 0AH, "3) Criptoanálise", 0AH, "4) Sair", 0AH, "Sua escolha: ", 0H
    outputFilename db "output.txt", 0H
    secretKey dw 0 ; Encryption/decryption key

    stdin dd 0
    stdout dd 1
    read_only dd 0
    write_only dd 1
    read_write dd 2
    sys_read dd 0
    sys_write dd 1
    sys_open dd 2
    sys_close dd 3
    sys_exit dd 60
    sys_creat dd 85
    success dd 0

section .text
    _start:
        call showMenu
        call getOption

        mov eax, [option]
        cmp eax, "1"
            jl invalidOption
        cmp eax, "4"
            je exit
            jg invalidOption

        call endecodingPath

        call exit

    showMenu:
        mov rax, [sys_write]
        mov rdi, [stdout]
        mov rsi, menu
        mov rdx, 116
        syscall

        ret

    getOption:
        mov rax, [sys_read]
        mov rdi, [stdin]
        mov rsi, option
        mov rdx, 1
        syscall

        call cleanBuffer

        ret

    invalidOption:
        mov rax, [sys_write]
        mov rdi, [stdout]
        mov rsi, invalidOptionMessage
        mov rdx, 42
        syscall

        ret

    endecodingPath:
        mov rax, [sys_write]
        mov rdi, [stdout]
        mov rsi, enterFilename
        mov rdx, 45
        syscall

        ; Get input file path
        mov rax, [sys_read]
        mov rdi, [stdin]
        mov rsi, filename
        mov rdx, 4096 ; Max path size in Linux
        syscall

        mov byte [filename + rax - 1], 0H ; Remove newline to avoid errors

        ; Open input file
        mov rax, [sys_open]
        mov rdi, filename
        mov rsi, [read_only]
        syscall

        mov r10, endecodingPath
        cmp rax, 0 ; If errored (< 0)
        jl fileNotFound

        mov [fileHandle], rax

        ; Ask for the encryption/decryption key
        mov rax, [sys_write]
        mov rdi, [stdout]
        mov rsi, askForKey
        mov rdx, 48
        syscall

        mov rax, [sys_read]
        mov rdi, [stdin]
        mov rsi, secretKey
        mov rdx, 3
        syscall

        mov byte [secretKey + rax - 1], 0H ; Remove newline to avoid errors

        ; cmp rax, 3
        ; je cleanBuffer

        ; Create output file
        mov rax, [sys_creat]
        mov rdi, outputFilename
        mov rsi, 777q
        syscall
        mov [outputFileHandle], rax

        call endecryptLoop

        mov rax, [sys_write]
        mov rdi, [stdout]
        mov rsi, encryptionSuccessMessage
        mov rdx, 71
        syscall

        call _start

    endecryptLoop:
        ; Reading file
        mov rax, [sys_read]
        mov rdi, [fileHandle]
        mov rsi, fileBuffer
        mov rdx, 512
        syscall
        mov [readBytes], rax
        add byte [fileBuffer], 0H

        push secretKey
        push readBytes
        push fileBuffer
        cmp dword [readBytes], 0
        jg endecryptContent

        ret

    endecryptContent:
        push rbp
        mov rbp, rsp

        ; Moving stack into registers
        mov r8, [rbp + 8]
        mov r9, [rbp + 16]
        mov r10, [rbp + 24]

        mov r11, 0 ; Zerando o contador
        ; Ao mover o IF pra cá, evita dele realizar uma comparação para cada byte da mensagem
        mov eax, [option]
        cmp eax, "1"
            je encryptContentLoop
        cmp eax, "2"
            je decryptContentLoop

        mov rsp, rbp
        pop rbp

        call endecryptLoop

    encryptContentLoop:
        ; movzx ebx, byte [r11]
        movzx rsi, byte [r8 + r11]

        cmp r11, r9 ; Se o contador for igual à quantidade de bytes lidos
        je return

        ; movzx eax, byte [r10] ; Carrega a chave secreta para um registrador de 32-bits

        ; Este diabo não está funcionando, era pra adicionar a chave ao caractere e colocar ele no arquivo, mas ?????
        ; Tentando fazer essa soma eu até quebrei o resto do código e nem escreve no arquivo de saída mais
        add esi, dword [r10]

        mov rax, [sys_write]
        mov rdi, [outputFileHandle]
        mov rdx, 1
        syscall

        inc r11

        jmp encryptContentLoop

    decryptContentLoop:
        ; movzx ebx, byte [r11]
        movzx rsi, byte [r8 + r11]

        cmp r11, r9 ; Se o contador for igual à quantidade de bytes lidos
        je return

        ; movzx eax, byte [r10] ; Carrega a chave secreta para um registrador de 32-bits

        ; Este diabo não está funcionando, era pra adicionar a chave ao caractere e colocar ele no arquivo, mas ?????
        ; Tentando fazer essa soma eu até quebrei o resto do código e nem escreve no arquivo de saída mais
        sub esi, dword [r10]

        mov rax, [sys_write]
        mov rdi, [outputFileHandle]
        mov rdx, 1
        syscall

        inc r11

        jmp decryptContentLoop

    closeFile:
        mov rax, [sys_close]
        mov rdi, [fileHandle]
        syscall

        ret

    fileNotFound:
        mov rax, [sys_write]
        mov rdi, [stdout]
        mov rsi, fileNotFoundMessage
        mov rdx, 43
        syscall

        call r10

    cleanBuffer:
        mov rax, [sys_read]
        mov rdi, [stdin]
        mov rsi, tmp
        mov rdx, 1
        syscall

        ret

    errorExit:
        mov rax, [sys_write]
        mov rdi, [stdout]
        mov rsi, errorMessage
        mov rdx, 42

        call exit

    exit:
        mov rax, [sys_exit]
        mov rdi, success
        syscall

    return:
        ret
