###############################################################
# Leitor de Header de Imagem BitMap
###############################################################
# Formato
#	BMP Header - 14 bytes
#	DIB Header - 40 bytes

.data
	msgOffset:	.asciiz "Com qual offset deseja ler o header?  "
	msgBytesQuant:	.asciiz "Quantos bytes deseja ler?  "
	msgContinuar:	.asciiz "Deseja ler outra parte o header? (S - Sim, N - Não)  "
	resposta:	.asciiz "Valor:  "
	quebralinha:	.asciiz "\n"
	
	nomeArquivo:	.asciiz	"img.bmp"
	header:		.space	54

.text

	###############################################################
	# Abrindo o arquivo
	li		$v0, 13			# código para abrir arquivo
	la		$a0, nomeArquivo	# string com o nome do arquivo
	li		$a1, 0			# modo de abertura de arquivo
	li		$a2, 0			
	syscall					# abre o arquivo (descritor do arquivo em $v0)
	move		$s6, $v0		# salva o descritor do arquivo
	
	###############################################################
	# Lendo o arquivo
	li		$v0, 14			# código para ler um arquivo
	move		$a0, $s6		# descritor do arquivo
	la		$a1, header		# endereço do buffer
	li		$a2, 54			# tamanho do buffer
	syscall					# lê o arquivo

	###############################################################
	# Rotina de leitura das informações do header
	
	loop:
			li		$v0, 4			# código para imprimir string
			la   		$a0, msgOffset 		# string
			syscall
			li		$v0, 5			# código para ler inteiro
			syscall
			move		$t0, $v0		# salva o valor do offset em t0
   
			li		$v0, 4			# código para imprimir string
			la		$a0, msgBytesQuant	# string
			syscall
			li   		$v0, 5       		# código para ler inteiro
			syscall
			move		$t1, $v0		# salva a quantidade de bytes em t1
    
			li		$v0, 4			# código para imprimir string
			la		$a0, resposta		# string
			syscall

			move		$t4, $zero		# zera t4
			move		$t2, $t0		# copia o offset em t2
			addi		$t2, $t2, -1		# prepara t2 para o loop de ler bytes

	ler_byte:
			addi		$t2, $t2, 1		# move ponteiro para leitura da memória em 1 byte
			sll  		$t4, $t4, 8		# desloca o t4 para um novo byte
			
			lbu		$t3, header($t2)	# carrega o byte em t3
 
			or 	 	$t4, $t3, $t4		# concatena o novo byte em t4
			addi 		$t1, $t1, -1		# decrementa contador de bytes

			bnez		$t1, ler_byte		# volta para ler_byte até o contador ir a 0
    
			li		$v0, 34			# código para imprimir inteiro em hexadecimal
			move		$a0, $t4		# valor do header
			syscall					# imprimir valor do header em hexadecimal
    
			li		$v0, 4			# código para imprimir string
			la		$a0, quebralinha	# quebra a linha
			syscall
    
			li		$v0, 4			# código para imprimir string
			la		$a0, msgContinuar	# string
			syscall
			li		$v0, 12			# Código para ler character
			syscall
			
			move		$t5, $v0		# Salva responsta

			li		$v0, 4			# código para imprimir string
			la		$a0, quebralinha     	# quebra a linha
			syscall

			beq		$t5, 'S', loop		# Enquanto a resposta for S, volta para loop

	###############################################################
	# Fechando o arquivo
	li		$v0, 16			# código para fechar arquivo
	move		$a0, $s6		# descritor do arquivo
	syscall					# fecha o arquivo
	###############################################################
    










