
.data

iniciom:	.asciiz"\n¡Bienvenidos a la calculadora Linares/Madio la maravilla!"
mensaje:	.asciiz"\nIntroduce el primer numero porfavor (límite: 50 dígitos): "
texto1:		.asciiz"\nIntroduce el segundo numero porfavor (límite: 50 digitos): "
elegirop:	.asciiz"\n¿Operacion a realizar? Suma(0), Resta (1), Multiplicación(2),Salir(4): "
interrumpe:	.asciiz"\nError. Formato introducido incorrectamente."
errordi:	.asciiz"\nError. Favor introducir un numero antes de la coma."
error:		.asciiz"\nElija una opcion valida."
probcom:	.asciiz"\nLa coma decimal no está nivelada, por favor hacer coincidir manualmente la coma decimal entre los operandos (puede hacerlo añadiendo ceros a la derecha u izquierda según sea el caso)."
opinco:		.asciiz"\nEl numero es decimal, el tipo de numero introducido no está permitido en la operación a realizar."
resop1:		.asciiz"\nEl primer numero luego de añadirle ceros: "
resop2:		.asciiz"\nEl segundo numero luego de añadirle ceros: "
resufinalop:	.asciiz"\nEl resultado final es: "
saltarli:	.asciiz"\n"
auxop1:		.space 50
auxop2:		.space 50	
op1:		.space 50	
op2:		.space 50
acum:		.space 100
acumi2:		.space 100	
resufinal:	.space 100

.text

.globl main

#Registros:
.eqv respu, $s0		
.eqv Op1apu, $s1		
.eqv Op2apu, $s2	
.eqv Respapu, $s3	
.eqv COp2Apu, $s4  	#Apuntador op2
.eqv AcumApu, $s5	#Apuntador acumi para multiplicación y división		
.eqv cifra1, $s6
.eqv cifra2, $s7
.eqv tami, $t3
.eqv acumi, $t4
.eqv contador, $t5
.eqv conti2, $t6

#Registros libres para reutilización:  $t0, $t1, $t7, $t8, $t9, para usarlos debes inicializarlos antes en 0 (li $tx, 0)

#Macro para leer un entero:
.macro leer_int(%int)
li $v0, 5
syscall
move %int, $v0
.end_macro

#Macro para imprimir un entero:
.macro imprimir_int(%int)
li $v0, 1
add $a0, $zero, %int
syscall
.end_macro

#Macro para leer string:
.macro leer_string(%vector)
li $v0, 8
la $a0, %vector
li $a1, 50
syscall
.end_macro

#Macro para imprimir string:
.macro imprimir_string(%etiqueta)
li $v0, 4
la $a0, %etiqueta
syscall
.end_macro 

#Macro para terminar el programa:
.macro salir()
li $v0, 10
syscall
.end_macro

#Macro para validar la respu al seleccionar el tipo de operación aritmética:
.macro validar_respu(%int)
beqz %int, suma
beq 	%int, 1, resta
beq 	%int, 2, multiplicación
beq 	%int, 3, división
beq 	%int, 4, fin
imprimir_string(error)
imprimir_string(saltarli)
j check_respu
.end_macro

#Macro para validar los operandos en la cadena string:
.macro validar_operando(%etiqueta)
li $t0, 0
li $t1, 0
#$t2			#Para salir del macro de validación de operando.
li $t8, 0		#Para evitar poner más de una "," en el operando.
li tami, -2

lb $t1, %etiqueta($t0)
beq $t1, 45, siguiente	#Si es negativo en la primera posición, leerá el "-".
beq $t1, 44, NoDigito	#No leerá la "," en la primera posición.
j siga

etapa:
lb $t1, %etiqueta($t0)
j verificarN
punto_de_control:
#beq $t1, 10, flag
beqz $t1, flag
beq $t1, 44, verificarD
siga:
beq $t1, 10, siguiente
beq $t1, 48, siguiente
beq $t1, 49, siguiente
beq $t1, 50, siguiente
beq $t1, 51, siguiente
beq $t1, 52, siguiente
beq $t1, 53, siguiente
beq $t1, 54, siguiente
beq $t1, 55, siguiente
beq $t1, 56, siguiente
beq $t1, 57, siguiente
j abortar

verificarN:
addi $t0, $t0, -1
lb $t1, %etiqueta($t0)
beq $t1, 45, verificarS
addi $t0, $t0, 1 				#Se restablece la posición original
j punto_de_control

verificarS:
addi $t0, $t0, 1
lb $t1, %etiqueta($t0)
beq $t1, 10, abortar
j punto_de_control

verificarD:
addi $t8, $t8, 1
bgt $t8, 1, abortar
j verificarS_decimal
		
siguiente:
addi $t0, $t0, 1
addi tami, tami, 1
b etapa

verificarS_decimal:
addi $t0, $t0, -1
lb $t1, %etiqueta($t0)
beq $t1, 44, siga2
addi $t0, $t0, 1			#Vuelve a la posición original
j siguiente

siga2:
addi $t0, $t0, 1
lb $t1, %etiqueta($t0)
beq $t1, 10, abortar
j punto_de_control

#Aborta la lectura al conseguir un caracter que no corresponda a los numéricos ASCII:
abortar:
imprimir_string(interrumpe)
beqz $t2, check_numero1
j check_numero2

#Si se coloca una "," antes de poner algún valor numérico:
NoDigito:
imprimir_string(errordi)
beqz $t2, check_numero1
j check_numero2


#Condición de salida después de realizar el proceso del macro:
flag:
addi $t2, $t2, 1
beq $t2, 1, salida_macro1

j salida_macro2
.end_macro

#Operación de suma:
.macro sumar(%op1, %op2)

li $t0, 0	#Bandera para el acarreo al momento de una coma decimal.

la Op1apu, %op1
addi Op1apu, Op1apu, 49
	
la Op2apu, %op2
addi Op2apu, Op2apu, 49
	
la Respapu, resufinal
addi Respapu, Respapu, 50

suma:
beq contador, 100, finn
lb cifra1, (Op1apu)
subi cifra1, cifra1, 48
add acumi, acumi, cifra1

lb cifra2, (Op2apu)
subi cifra2, cifra2, 48
add acumi, acumi, cifra2

beq acumi, -8, excp		#Excepción para la coma decimal
regresa:
bgt acumi, 9, acarreo
addi acumi, acumi, 48
sb acumi, (Respapu)
li acumi, 0

apuntadores:
subi Op1apu, Op1apu, 1
subi Op2apu, Op2apu, 1
subi Respapu, Respapu, 1
addi contador, contador, 1
j suma
	
acarreo:
addi acumi, acumi, 38
sb acumi, (Respapu)
j verificarS					#Evitar que el acarreo caiga en la coma decimal
continuar:
li acumi, 1
j apuntadores
	
finn:
addi acumi, acumi, 48
sb acumi, (Respapu)
j termina

verificarS:
subi Op1apu, Op1apu, 1
lb cifra1, (Op1apu)
beq cifra1, 44, no_acarrear
addi Op1apu, Op1apu, 1
j continuar

excp:
addi acumi, acumi, 52
beq acumi, 44, excepc_confirmada		#Confirma si de verdad el número del acumi es una coma decimal
subi acumi, acumi, 52
j regresa

excepc_confirmada:
sb acumi, (Respapu)
li acumi, 0
beq $t0, 1, acarrea_uno
j apuntadores

acarrea_uno:
li $t0, 0
li acumi, 1
j apuntadores

no_acarrear:
li $t0, 1
li acumi, 0
addi Op1apu, Op1apu, 1
j apuntadores

.end_macro

#Operación de resta:
.macro restar(%op1, %op2)

la Op1apu, %op1
addi Op1apu, Op1apu, 49
	
la Op2apu, %op2
addi Op2apu, Op2apu, 49
	
la Respapu, resufinal
addi Respapu, Respapu, 50

resta:
beq contador, 100, finn
lb cifra1, (Op1apu)
subi cifra1, cifra1, 48

lb cifra2, (Op2apu)
subi cifra2, cifra2, 48

validacion2:							#valida quien es el mayor entre los dos digitos
bge cifra1,cifra2,resta12
blt cifra1,cifra2,verificar

verificar:								#verifica si el numero es de un solo digito al comprobar si el apuntador a la izquierda es igual a cero
subi Op1apu, Op1apu, 1	#si es igual a cero, salta a resta21, sino, pide prestaar
lb cifra1, (Op1apu)
beq cifra1, 48, resta21

prestaar:
addi Op1apu, Op1apu, 1	#suma 10 al digito que pide prestaar
lb cifra1, (Op1apu)
subi cifra1, cifra1, 48
add cifra1, cifra1, 10

restaEspecial:
add acumi, acumi, cifra1
subu acumi, acumi, cifra2

addi acumi, acumi, 48
sb acumi, (Respapu)

#imprimir_int(acumi)
j apuntadorEspecial

resta12: 								#se resta el cifra1 al cifra2 por ser mayor que el
add acumi, acumi, cifra1
subu acumi, acumi, cifra2

addi acumi, acumi, 48
sb acumi, (Respapu)
#imprimir_int(acumi)
li acumi, 0
j apuntadores

resta21:
addi Op1apu, Op1apu, 1								#se resta el cifra2 al cifra1 por ser mayor que el
lb cifra1, (Op1apu)
subi cifra1, cifra1, 48
add acumi, acumi, cifra2
subu acumi, acumi, cifra1

apuntadores:							#apuntador normal cuando no se pide prestaar
subi Op1apu, Op1apu, 1
subi Op2apu, Op2apu, 1
subi Respapu, Respapu, 1
addi contador, contador, 1
j resta

apuntadorEspecial:					#se mueve el Op1apu a la izquierda y a la vez se resta 1 al nuevo cifra1
subi Op1apu, Op1apu, 1	#se aplica una vez que se tomó prestaar de un número
lb cifra1, (Op1apu)
subi cifra1, cifra1, 48
subi cifra1, cifra1, 1
addi cifra1, cifra1, 48
subi Op2apu, Op2apu, 1
subi Respapu, Respapu, 1
addi contador, contador, 1
li acumi, -1
j resta
	
finn:
addi acumi, acumi, 48
sb acumi, (Respapu)
j termina
.end_macro

#Operación de multiplicación:
.macro multiplicar(%op1, %op2)

#rellenar_res(resufinal)

li $t0, 0 	#Almacena el acarreo a sumar al siguiente digito.
li $t1, 0	#Bandera que registra un acarreo. Vale 1 si hay, 0 si no.

la Op1apu, %op1
addi Op1apu, Op1apu, 49
	
la Op2apu, %op2
addi Op2apu, Op2apu, 49
	
la AcumApu, acum
add AcumApu, AcumApu, 49

lb cifra2, (Op2apu)
subi cifra2, cifra2, 48

multiplica:
beq conti2, 50, termina
beq contador, 50, sumaAcum		

lb cifra1, (Op1apu)
subi cifra1, cifra1, 48
add acumi, acumi, cifra1

mul acumi, acumi, cifra2

beq $t1, 1, sumar_acarreo
j acarreo

sumar_acarreo:
add acumi, acumi, $t0
li $t1, 0
li $t0, 0

acarreo:
blt acumi, 10, acarrea_0
blt acumi, 20, acarrea_1
blt acumi, 30, acarrea_2
blt acumi, 40, acarrea_3
blt acumi, 50, acarrea_4
blt acumi, 60, acarrea_5
blt acumi, 70, acarrea_6
blt acumi, 80, acarrea_7
blt acumi, 90, acarrea_8

siga:
addi acumi, acumi, 38
sb acumi, (AcumApu)
j apuntadores

acarrea_0:
addi acumi, acumi, 48
sb acumi, (AcumApu)
j apuntadores

acarrea_1:
addi $t1, $t1, 1
addi $t0, $t0, 1
j siga

acarrea_2:
addi acumi, acumi, -10
addi $t1, $t1, 1
addi $t0, $t0, 2
j siga

acarrea_3:
addi acumi, acumi, -20
addi $t1, $t1, 1
addi $t0, $t0, 3
j siga

acarrea_4:
addi acumi, acumi, -30
addi $t1, $t1, 1
addi $t0, $t0, 4
j siga

acarrea_5:
addi acumi, acumi, -40
addi $t1, $t1, 1
addi $t0, $t0, 5
j siga

acarrea_6:
addi acumi, acumi, -50
addi $t1, $t1, 1
addi $t0, $t0, 6
j siga

acarrea_7:
addi acumi, acumi, -60
addi $t1, $t1, 1
addi $t0, $t0, 7
j siga

acarrea_8:
addi acumi, acumi, -70
addi $t1, $t1, 1
addi $t0, $t0, 8
j siga

apuntadores:
li acumi, 0
subi Op1apu, Op1apu, 1
subi AcumApu, AcumApu, 1
addi contador, contador, 1
j multiplica

sumaAcum:
rellenar_acum(acum)
#imprimir_string(acum)
#imprimir_string(resufinal)
#imprimir_string(acum)
#sumar_Acumulador(acum, resufinal)
#imprimir_string(saltarli)
#imprimir_string(resufinal)
#j termina
#addi conti2, conti2, 1
#li contador, 0			#Se pone el contador en 0
#li Op1apu, 0		#Se pone el registro del apuntador en 0
#li Op1apu, 0		#Se pone el registro del apuntador en 0
#li AcumApu, 0
#subi Op2apu, Op2apu, 1	#Se pasa al siguiente dígito del operando 2
#j multiplica
imprimir_string(resufinalop)
imprimir_string(saltarli)
imprimir_string(acum)
salir() 
.end_macro

#Operación de división:
.macro divir(%op1, %op2)

#rellenar_res(resufinal)

li $t0, 0 	#Almacena el acarreo a sumar al siguiente digito.
li $t1, 0	#Bandera que registra un acarreo. Vale 1 si hay, 0 si no.

la Op1apu, %op1
subi Op1apu, Op1apu, 49
	
la Op2apu, %op2
subi Op2apu, Op2apu, 49
	
la AcumApu, acum
subi AcumApu, AcumApu, 49

lb cifra2, (Op2apu)
subi cifra2, cifra2, 48

divide:
beq conti2, 50, termina
beq contador, 50, sumaAcum		

lb cifra1, (Op1apu)
subi cifra1, cifra1, 48
add acumi, acumi, cifra1

mul acumi, acumi, cifra2

beq $t1, 1, sumar_acarreo
j acarreo

sumar_acarreo:
add acumi, acumi, $t0
li $t1, 0
li $t0, 0

acarreo:
blt acumi, 10, acarrea_0
blt acumi, 20, acarrea_1
blt acumi, 30, acarrea_2
blt acumi, 40, acarrea_3
blt acumi, 50, acarrea_4
blt acumi, 60, acarrea_5
blt acumi, 70, acarrea_6
blt acumi, 80, acarrea_7
blt acumi, 90, acarrea_8

siga:
addi acumi, acumi, 38
sb acumi, (AcumApu)
j apuntadores

acarrea_0:
addi acumi, acumi, 48
sb acumi, (AcumApu)
j apuntadores

acarrea_1:
addi $t1, $t1, 1
addi $t0, $t0, 1
j siga

acarrea_2:
addi acumi, acumi, -10
addi $t1, $t1, 1
addi $t0, $t0, 2
j siga

acarrea_3:
addi acumi, acumi, -20
addi $t1, $t1, 1
addi $t0, $t0, 3
j siga

acarrea_4:
addi acumi, acumi, -30
addi $t1, $t1, 1
addi $t0, $t0, 4
j siga

acarrea_5:
addi acumi, acumi, -40
addi $t1, $t1, 1
addi $t0, $t0, 5
j siga

acarrea_6:
addi acumi, acumi, -50
addi $t1, $t1, 1
addi $t0, $t0, 6
j siga

acarrea_7:
addi acumi, acumi, -60
addi $t1, $t1, 1
addi $t0, $t0, 7
j siga

acarrea_8:
addi acumi, acumi, -70
addi $t1, $t1, 1
addi $t0, $t0, 8
j siga

apuntadores:
li acumi, 0
subi Op1apu, Op1apu, 1
subi AcumApu, AcumApu, 1
addi contador, contador, 1
j siga

sumaAcum:
rellenar_acum(acum)
#imprimir_string(acum)
#imprimir_string(resufinal)
#imprimir_string(acum)
#sumar_Acumulador(acum, resufinal)
#imprimir_string(saltarli)
#imprimir_string(resufinal)
#j termina
#addi conti2, conti2, 1
#li contador, 0			#Se pone el contador en 0
#li Op1apu, 0		#Se pone el registro del apuntador en 0
#li Op1apu, 0		#Se pone el registro del apuntador en 0
#li AcumApu, 0
#subi Op2apu, Op2apu, 1	#Se pasa al siguiente dígito del operando 2
#j multiplica
imprimir_string(resufinalop)
imprimir_string(saltarli)
imprimir_string(acum)
salir() 
.end_macro

#Rellenar con ceros el operando 1:
.macro rellenar_ceros(%operando)
li $t0, 0
li $t1, 0
li $t2, 0
li $t9, 50
li $t8, 0				
sub $t9, $t9, tami

etapa2:
beq $t8, 50, finalizar
blt $t8, $t9, es_cero
lb $t1, %operando($t0)
move $t2, $t1
sb $t2, op1($t8)
addi $t0, $t0, 1
addi $t8, $t8, 1
j etapa2

es_cero:
li $t2, 48
sb $t2, op1($t8)
addi $t8, $t8, 1
j etapa2

finalizar:
imprimir_string(op1)
.end_macro

#Rellenar con ceros el operando 2:
.macro rellenar_ceros2(%operando)
li $t0, 0
li $t1, 0
li $t2, 0
li $t9, 50
li $t8, 0
sub $t9, $t9, tami

etapa2:
beq $t8, 100, finalizar2
blt $t8, $t9, es_cero2
lb $t1, %operando($t0)
move $t2, $t1
sb $t2, op2($t8)
addi $t0, $t0, 1
addi $t8, $t8, 1
j etapa2

es_cero2:
li $t2, 48
sb $t2, op2($t8)
addi $t8, $t8, 1
j etapa2

finalizar2:
imprimir_string(op2)
.end_macro

#Validación de decimales, o sea, comprobar que las comas estén puestas en la misma posición en ambos operandos:
.macro validar_decimales(%op1, %op2)
li $t0, 0
li $t1, 0
li $t2, 0	#Guarda la posición de la coma en el operando 1, una vez es captada.
li $t7, 0	#Guarda la posición de la coma en el operando 2, una vez es captada.
li $t8, 0	#Contador para op1
li $t9, 0	#Contador para op2


#Recorrer el operando 1:
etapa:
beq $t0, 100, reiniciar
lb $t1, %op1($t0)
beq $t1, 44, guarda_posicion
siga:
addi $t8, $t8, 1
addi $t0, $t0, 1
j etapa

guarda_posicion:
move $t2, $t8
j siga

#Recorrer el operando 2:
reiniciar:
li $t0, 0
li $t1, 0
etapa2:
beq $t0, 100, evaluar
lb $t1, %op2($t0)
beq $t1, 44, guarda_posicion2
siga2:
addi $t9, $t9, 1
addi $t0, $t0, 1
j etapa2

guarda_posicion2:
move $t7, $t9
j siga2

evaluar:
beqz $t2, sin_coma
bne  $t2, $t7, imprime_error
j finn

imprime_error:
imprimir_string(probcom)
j fin

sin_coma:
beqz $t7, finn
imprimir_string(probcom)
j fin

finn:
.end_macro

#Validación para evitar operandos con decimales en la multiplicación y división:
.macro validar_decimales2(%op1)
li $t0, 0
li $t1, 0

#Recorrer el operando 1:
etapa:
beq $t0, 50, finn
lb $t1, %op1($t0)
beq $t1, 44, es_decimal
siga:
addi $t0, $t0, 1
j etapa

es_decimal:
imprimir_string(opinco)
j fin

finn:
.end_macro

#Macro que rellena el acumi de la multiplicación con ceros:
.macro rellenar_acum(%acumi)
li $t0, 49
li $t1, 0
li $t2, 0
li $t7, 99
li $t8, 0

bgtz $t8, resta_Acum

etapa:
beq $t7, -1, finn
lb $t1, %acumi($t0)
move $t2, $t1
beq $t0, -1, es_cero
sb $t2, %acumi($t7)
siga:
addi $t0, $t0, -1
addi $t7, $t7, -1
j etapa

es_cero:
li $t2, 48
sb $t2, %acumi($t7)
j siga

resta_Acum:
li $t2, 48
sb $t2, %acumi($t7)
subi $t7, $t7, 1
j etapa

finn: addi $t8, $t8, 1
.end_macro

#Macro para rellenar el resufinal con 0:
.macro rellenar_res(%resufinal)
li $t0, 0
li $t1, 0

etapa:
beq $t0, 100, finn
lb $t1, %resufinal($t0)
li $t1, 48
sb $t1, %resufinal($t0)
addi $t0, $t0, 1
j etapa

finn:
.end_macro

.macro sumar_Acumulador(%acumi, %resufinal)
li AcumApu, 0
li Respapu, 0
li contador, 0
li cifra1, 0
li cifra2, 0
#li $t9, 199

la AcumApu, %acumi
add AcumApu, AcumApu, 99
		
la Respapu, %resufinal
addi Respapu, Respapu, 99

beq contador, 100, finn
lb cifra1, (AcumApu)
subi cifra1, cifra1, 48
add acumi, acumi, cifra1

lb cifra2, (Respapu)
subi cifra2, cifra2, 48
add acumi, acumi, cifra2

regresa:
bgt acumi, 9, acarreo
addi acumi, acumi, 48
sb acumi, (Respapu)
li acumi, 0

apuntadores:
subi AcumApu, AcumApu, 1
subi Respapu, Respapu, 1
addi contador, contador, 1
j suma
	
acarreo:
addi acumi, acumi, 38
sb acumi, (Respapu)	
continuar:
li acumi, 1
j apuntadores
	
finn:
addi acumi, acumi, 48
sb acumi, (Respapu)

#subi $t9, $t9, 1
.end_macro

#Macro para determinar si el número es negativo:
.macro determinar_negativo(%op1, %op2)
li $t0, 0
li $t1, 0
li $t7, 0 	#Si se prende el operando 1 es negativo
li $t8, 0 	#Si se prende el operando 2 es negativo

#Recorrer el operando 1:
recorrer_op1:
beq $t0, 50, reiniciar
lb $t1, %op1($t0)
beq $t1, 45, es_negativo1
siga1:
addi $t0, $t0, 1
j recorrer_op1

es_negativo1:
li $t1, 48
sb $t1, %op1($t0)
addi $t7, $t7, 1
j siga1

reiniciar:
li $t0,0
li $t1,0
recorrer_op2:
beq $t0, 50, finn
lb $t1, %op2($t0)
beq $t1, 45, es_negativo2
siga2:
addi $t0, $t0, 1
j recorrer_op2

es_negativo2:
li $t1, 48
sb $t1, %op2($t0)
addi $t8, $t8, 1
j siga2

finn:
.end_macro

#############################################################
#Inicio del programa:
main:

#Imprime mensajes iniciales y elegirop los operandos:
imprimir_string(iniciom)

check_numero1:		#Regresa aquí si al chequear el op1, este es incorrecto.
imprimir_string(mensaje)
leer_string(auxop1)
validar_operando(auxop1)
salida_macro1:
imprimir_string(saltarli)	
imprimir_string(resop1)
imprimir_string(saltarli)	
rellenar_ceros(auxop1)
imprimir_string(saltarli)


check_numero2:		#Regresa aquí si al chequear el op2, este es incorrecto.
imprimir_string(texto1)
leer_string(auxop2)
validar_operando(auxop2)
salida_macro2:
imprimir_string(saltarli)	
imprimir_string(resop2)
imprimir_string(saltarli)	
rellenar_ceros2(auxop2)
imprimir_string(saltarli)	

#Validaciones:
validar_decimales(op1, op2)

#Pregunta el tipo de operación aritmética a realizar:
check_respu:		#Regresa aquí si al chequear la respu no esta en el intervalo dado.
imprimir_string(elegirop) 
leer_int(respu)
validar_respu(respu)

#Suma los números:
suma:
determinar_negativo(op1, op2)
	beq $t7, $t8, es_suma	#Si los signos de ambos operandos son iguales, se procede a sumar. Sino se restan (suma negativa)
	restar(op1, op2)
	es_suma: sumar(op1, op2)
	
#Resta los números:
resta:
determinar_negativo(op1, op2)
	beq $t7, $t8, es_resta	#Si los signos de ambos operandos son iguales, se procede a restar (Ejm: (1)-(1)=1-1 / (-1)-(-1)=-1+1). Sino se suman (Ejm: (-1)-(1)= -1-1 / (1)-(-1)=1+1)
	sumar(op1, op2)
	es_resta: restar(op1,op2)

#Multiplica los números:
multiplicación:				#Solo hace multiplicación por un dígito (Un solo dígito del op2 multiplica a los 100 dígitos del op1)
validar_decimales2(op1)	#Comprueba que los operandos no sean decimales 
multiplicar(op1, op2)

#Divide los números
división:
validar_decimales2(op1)	#Comprueba que los operandos no sean decimales
divir(op1, op2)

#Imprime el resufinal de la operación escogida:
termina:
imprimir_string(resufinalop)
imprimir_string(saltarli)
imprimir_string(resufinal) 

#Termina el programa:
fin: salir()