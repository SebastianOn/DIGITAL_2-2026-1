.equ UART_BASE, 0x400000  
.equ DPRAM_BASE, 0x450000  

.equ IO_LEDS, 4
.equ IO_UART_DAT, 8
.equ IO_UART_CNTL, 16
.section .text
.globl start 
.globl blinker
.globl put_hello

calculator:
#   li   gp,UART_BASE
#   li   gp, DPRAM_BASE
#   li   sp,0x10040
   li   sp,0x1000
   li 	t3, 10
   li   t4, '*'
   li	t5, '/'
   li	t6, 35
loopM:	
	//la   a0, command
	//call putstring

	addi a1, x0, 0
	li t0, 6 //Numero maximo de digitos a ingresar para evitar desborde 

Op_A:
	slli a1, a1, 4 // Desplazo a1 4 bits a la izquierda para hacer espacio 
					//para el siguiente digito
	call TCL //Se lee el teclado y se guarda el valor en a0
	addi a0, a0, -0x30 //Se pasa de asccii a binario
	bge a0,t3, end_A //Dado que los asccii de numeros van del 0x30 al 0x39,
					// si el valor es mayor a 9, se sale del bucle porque no se ingreso un 
					//numero sino un operador
	bgt x0,a0, end_A//Si el valor es menor a 0, se sale del bucle porque no se ingreso un 
					//numero sino un operador
	add a1, a0, a1 //Se suma el digito ingresado a a1
	mv a0, a1 //Se pasa el valor de a1 a a0 para poder imprimirlo en el display
	call print_led //Se imprime el valor ingresado en el display
	addi t0, t0, -1 //Se decrementa el contador de digitos ingresados
	beqz t0, bcd2bin_A //Si se ingresaron 6 digitos, se sale del bucle
	j Op_A //Se vuelve a leer el teclado sino se ha ingresado un operador y
		 // no se han ingresado 6 digitos
end_A:
	addi a0, a0, 0x30 //Ya que el valor de a0 es un operador,
					//Se restaura su valor en asccii 
	srli a1, a1, 4 //Se devulve el desplazamiento ya que el valor leido no fue un digito sino un operador
bcd2bin_A:
	mv a3, a0 //Se guarda el operador ingresado en a3 para poder compararlo despues
	mv a0, a1   Se pone en a0 a1 para poder pasarlo el la función RDD_hw que lo pasa a binario
	call RDD_hw 
	mv a1, a0 Se guarda en a1 el binario resultante
Operador:
	beq  t4, a3, Ld_operador //Si el operador ingresado es *, se salta a Ld_operador
	beq  t5, a3, Ld_operador //Si el operador ingresado es /, se salta a Ld_operador
	beq  t6, a3, Ld_operador //Si el operador ingresado es #, se salta a Ld_operador
	j loopM //Aqui se llega cuando se ingresan mas de 6 digitos, por lo que se reinicia todo
Ld_operador:
	addi a2, x0, 0 //Inicializa a2 en 0
	li t0, 6 //Numero maximo de digitos a ingresar para evitar desborde 

Op_B: //Homologo a Op_A, pero para el segundo operando
	slli a2, a2, 4
	call TCL  
	addi a0, a0, -0x30
	bge a0,t3, end_B
	bgt x0,a0, end_B
	add a2, a0, a2 
	mv a0, a2  
	call print_led 
	addi t0, t0, -1
	beqz t0, bcd2bin_B
	j Op_B
end_B:
	srli a2, a2, 4
bcd2bin_B:
	mv a0, a2
	call RDD_hw
	mv a2, a0	

	//la   a0, result
	//call putstring

	mv   a0,a1
	mv   a1,a2
	
Selector:
	beq a3, t5, divide //Se llama a la funcion division si operador es /
	beq a3, t6, root //Se llama a la funcion raiz cuadrada si operador es #
	call mult_hw //Por descarte se llama multiplicacion si operador es *
	j    print_res
divide:
	call div_hw
	j	print_res
root:
	mv a0,a1
	call sqrt_hw
print_res:		
	call DD_hw //Se pasa de binario a bcd
	call print_led //Se imprime
	call print
	
	j    loopM
putstring:
	addi sp,sp,-4 # save ra on the stack
	sw ra,0(sp)   # (need to do that for functions that call functions)
	mv t2,a0	
.L1:    lbu a0,0(t2)
	beqz a0,.L2
	call putchar
	addi t2,t2,1	
	j .L1
.L2:    lw ra,0(sp)  # restore ra
	addi sp,sp,4 # restore sp
	ret	

.section .data
command:
	.asciz "\n\r - Enter two operands - \n\r"
operator:
	.asciz "\n\rEnter operator \n\r"
result:
	.asciz "\n\rResult = "

