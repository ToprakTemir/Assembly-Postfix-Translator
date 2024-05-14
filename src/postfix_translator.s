.macro print_zeros num_zeros
    mov $\num_zeros, %rcx
    call print_zeros
.endm

.macro print_one 
    movb $'1', (%r9)
    inc %r9
.endm

.macro print_space
    movb $' ', (%r9)              
    inc %r9
.endm

.macro print_imm_opcode
    # 0010011
    movb $'0', (%r9)
    inc %r9
    movb $'0', (%r9)
    inc %r9
    movb $'1', (%r9)
    inc %r9
    movb $'0', (%r9)
    inc %r9
    movb $'0', (%r9)
    inc %r9
    movb $'1', (%r9)
    inc %r9
    movb $'1', (%r9)
    inc %r9
.endm

.macro print_reg_opcode
    # 0110011
    movb $'0', (%r9)
    inc %r9
    movb $'1', (%r9)
    inc %r9
    movb $'1', (%r9)
    inc %r9
    movb $'0', (%r9)
    inc %r9
    movb $'0', (%r9)
    inc %r9
    movb $'1', (%r9)
    inc %r9
    movb $'1', (%r9)
    inc %r9
.endm

.macro print_newline
    movb $'\n', (%r9)
    inc %r9
.endm

.macro print_x1_x1_x2_opcode # print the "<label> x1 x1 x2 <opcode>" line after the label in RISC-V machine code
    
    # rs2 (x2 = 00010)
    print_zeros 3
    print_one
    print_zeros 1
    print_space
    
    # rs1 (x1 = 00001)
    print_zeros 4
    print_one
    print_space

    # funct3 (000)
    print_zeros 3
    print_space

    # rd (x1 = 00001)
    print_zeros 4
    print_one
    print_space
    
    print_reg_opcode

.endm

#########################################################################################

.section .bss
input_buffer: .space 256            # Allocate 256 bytes for input buffer
output_buffer: .space 4096          #TODO: decide the exact length

.section .data


.section .text
.global _start

_start:
    # Read input from standard input
    mov $0, %eax                    # syscall number for sys_read
    mov $0, %edi                    # file descriptor 0 (stdin)
    lea input_buffer(%rip), %rsi    # pointer to the input buffer
    mov $256, %edx                  # maximum number of bytes to read
    syscall                         # perform the syscall

    # indices for reading and writing inputs. As input is read, r8 is incremented.
    lea input_buffer(%rip), %r8     # index for input buffer
    lea output_buffer(%rip), %r9

    # we will always use r11 as x1, r12 as x2. 
    # r10 will hold the current token (entire number or operator)
    mov $0, %r10
    mov $0, %r11
    mov $0, %r12     

    xor %r15, %r15                  # clear r15, it holds whether \n is encountered
    jmp read_token

# Reading tokens from input. 
read_token:
    # rbx is used to store the current character.

    cmp $1, %r15        # if \n is encountered, go to print_output
    je print_output

    xor %rbx, %rbx      # clear rbx
    movb (%r8), %bl     # load the current character

    cmp $'\n', %rbx     # \n implies end of input
    je end_of_input

    cmp $' ', %rbx      # end of token
    je space_handler

    # checking if the character is a number
    sub $'0', %rbx
    cmp $9, %rbx
    jg read_token       # if the character is an operator, it will be dealt with in space_handler


    imul $10, %r10      # slide the current number one digit to the left
    add %rbx, %r10      # add the last digit to the number

    inc %r8             # increment input character counter
    jmp read_token      # read the next character

    end_of_input:
        mov $1, %r15   # set r15 to 1 to indicate that \n is encountered
        jmp space_handler


########## END OF READ_TOKEN ##########


space_handler:
    dec %r8            # decrement r8 to point to the last character before the space
    xor %rbx, %rbx
    movb (%r8), %bl    # load the token before the space to r10
    inc %r8            # restore r8

    cmp $'+', %rbx
    je _add
    cmp $'-', %rbx
    je _subtract
    cmp $'*', %rbx
    je _multiply
    cmp $'^', %rbx
    je _xor
    cmp $'&', %rbx
    je _and
    cmp $'|', %rbx
    je _or

    # if this point is reached, the token is a number
    jmp push_to_stack


push_to_stack:
    push %r10           # push the token to the stack
    mov $0, %r10        # clear r10
    inc %r8       
    jmp read_token

print_load_to_x1:

    # printing imm value
    shr $1, %r11                   # shifts x1 to the right by 1, sets the carry flag to the digit shifted out

    setc %al
    add $'0', %al
    dec %rcx
    movb %al, (%r9, %rcx)          # write to the least significant digit (r9 is the start of the number)
    inc %rcx
    loop print_load_to_x1          # loop until rcx is 0

    add $12, %r9

    print_space

    # printing rs1 (always x0 = 000000)
    print_zeros 5                  # -12 bit imm- 00000
    print_space
    
    # printing funct3 (000)
    print_zeros 3                  # -12 bit imm- 00000 000 
    print_space

    # printing rd (x1 = 00001)
    print_zeros 4
    print_one                      
    print_space                    # -12 bit imm- 00000 000 00001

    print_imm_opcode               # -12 bit imm- 00000 000 00001 0010011

    print_newline

    ret


print_load_to_x2:
    # printing imm value
    
    shr $1, %r12                   # shifts x1 to the right by 1, sets the carry flag to the digit shifted out

    setc %al
    add $'0', %al
    dec %rcx
    movb %al, (%r9, %rcx)          # write to the least significant digit (r9 is the start of the number)
    inc %rcx
    loop print_load_to_x2          # loop until rcx is 0

    add $12, %r9

    print_space

    # printing rs1 (always x0 = 000000)
    print_zeros 5                  # -12 bit imm- 00000
    print_space
    
    # printing funct3 (000)
    print_zeros 3                  # -12 bit imm- 00000 000 
    print_space

    # printing rd (x2 = 0001)
    print_zeros 3
    print_one   
    print_zeros 1                   
    print_space                    # -12 bit imm- 00000 000 00010

    print_imm_opcode               # -12 bit imm- 00000 000 00010 0010011

    print_newline

    ret


print_zeros:
    movb $'0', (%r9)
    inc %r9
    loop print_zeros
    ret

# "addi x2, x0, imm \n addi x1, x0, imm" lines
load_x1_and_x2:
    pop %rdx                        # restore instruction pointer

    pop %r12                        # pop the first token
    mov $12, %rcx                   # loop counter for printing (12 characters will be printed)

    push %r12                      
    call print_load_to_x2
    pop %r12                        

    pop %r11                        # pop the second token
    mov $12, %rcx                   # loop counter

    push %r11
    call print_load_to_x1
    pop %r11

    push %rdx

    ret
    
####################  OPERATOR FUNCTIONS   #######################

_add: # printing out the RISC-V machine code for addition

    # 1) Loading r11 to x1 (addi x1, x0, r11) and r12 to x2 (addi x2, x0, r12)
    call load_x1_and_x2

    # 2) Adding x1 and x2  (add x1, x1, x2)
    
    # 2.1) "add" flag (0000000)
    print_zeros 7
    print_space 
    # 2.2) rest
    print_x1_x1_x2_opcode
    print_newline

    # push the sum to the stack to be used in the next operation
    add %r12, %r11     
    push %r11        
  
    inc %r8
    jmp read_token
    
_subtract:
    
    call load_x1_and_x2

    print_zeros 1
    print_one
    print_zeros 5
    print_space

    print_x1_x1_x2_opcode

    print_newline

    sub %r12, %r11
    push %r11

    inc %r8
    jmp read_token

_multiply:

    call load_x1_and_x2

    print_zeros 6
    print_one
    print_space

    print_x1_x1_x2_opcode

    print_newline

    imul %r12, %r11
    push %r11

    inc %r8
    jmp read_token


_xor:

    call load_x1_and_x2

    print_zeros 4
    print_one
    print_zeros 2
    print_space
    
    print_x1_x1_x2_opcode

    print_newline

    xor %r12, %r11
    push %r11

    inc %r8
    jmp read_token
    
_and:

    call load_x1_and_x2

    print_zeros 4
    print_one
    print_one
    print_one
    print_space
    
    print_x1_x1_x2_opcode

    print_newline

    and %r12, %r11
    push %r11

    inc %r8
    jmp read_token

_or:

    call load_x1_and_x2

    print_zeros 4
    print_one
    print_one
    print_zeros 1
    print_space
    
    print_x1_x1_x2_opcode

    print_newline

    and %r12, %r11
    push %r11

    inc %r8
    jmp read_token

#################################################################

print_output:
    # Assumes edx has size and rsi has address (popped from stack)    

    movb $'\n', (%r9)            # null character at the end of the output string
    inc %r9
    movb $0, (%r9)
    lea output_buffer(%rip), %rsi
    mov $4096, %edx
    mov $1, %eax              # syscall number for sys_write
    mov $1, %edi              # file descriptor 1 (stdout)
    syscall
    jmp exit_program

exit_program:
    # Exit the program
    mov $60, %eax               # syscall number for sys_exit
    xor %edi, %edi              # exit code 0
    syscall
