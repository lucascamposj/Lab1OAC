###############################################################
# Leitor de Imagem BitMap para Bitmap Display
###############################################################

.data
	nomeArquivo:	.asciiz		"img.bmp"

	header:		.space		54		# tamanho do header em bytes
	heap: 		.word   	0x10008000	# endereco do bitmap display
	buffer:		.word		0	

.text 
 	lw		$s3, heap
	###############################################################
	# Abrindo o arquivo
	li		$v0, 13			# código para abrir arquivo
	la		$a0, nomeArquivo	# string com o nome do arquivo
	li		$a1, 0			# modo de abertura de arquivo
	li		$a2, 0			
	syscall					# abre o arquivo (descritor do arquivo em $v0)
	move		$s6, $v0		# salva o descritor do arquivo
	
	###############################################################
	# Salvando o Header
	li		$v0, 14			# código para ler um arquivo
	move		$a0, $s6		# descritor do arquivo
	la		$a1, header		# endereço do buffer
	li		$a2, 18			# tamanho do buffer
	syscall					# lê o arquivo
	
	###############################################################
	# Obtendo resolução
	li		$v0, 14			# código para ler um arquivo
	move		$a0, $s6		# descritor do arquivo
	la		$a1, buffer		# endereço do buffer
	li		$a2, 4			# tamanho do buffer
	syscall					# lê o arquivo
	
	lw		$s0, buffer		# total de pixels horizontais
	
	li		$v0, 14			# código para ler um arquivo
	move		$a0, $s6		# descritor do arquivo
	la		$a1, buffer		# endereço do buffer
	li		$a2, 4			# tamanho do buffer
	syscall					# lê o arquivo
	
	lw		$s1, buffer		# total de pixels verticais
	
	###############################################################
	# Continuação do salvamento do header
	li		$v0, 14			# código para ler um arquivo
	move		$a0, $s6		# descritor do arquivo
	la		$a1, header+26		# endereço do buffer
	li		$a2, 28			# tamanho do buffer
	syscall					# lê o arquivo
	
	###############################################################
	# Salvando imagem na heap
	
	andi		$t4, $s1, 0x00000003	# resX % 4 para descobrir o tamanho do padding
	
	move		$t0, $zero		# contador de pixels verticais
loopY:
	addi		$t0, $t0, 1
	subu 		$t5, $s1, $t0
	sll 		$t5, $t5, 2
	mul		$t5, $t5, $s0
	addu		$t5, $t5, $s3
						# 12 * X * (Y - t0)
	
	move		$t1, $zero		# contador de pixels horizontais
	loopX:
		addi		$t1, $t1, 1
		
		move		$t3, $zero		# word do pixel
		
		#obtem pixel RGB
		li		$v0, 14			# código para ler um arquivo
		move		$a0, $s6		# descritor do arquivo
		la		$a1, buffer		# endereço do buffer
		li		$a2, 3			# tamanho do buffer
		syscall					# lê o arquivo
		
		# salva pixel na memória
		lw		$t3, buffer		
		sw		$t3, ($t5)
		addi 		$t5, $t5, 4
	
		bne		$t1, $s1, loopX		# Se iguais, fim dos pixels horizontais
	
	# Tratar padding
	beqz		$t4, sempadding
	
	li 		$v0, 14			# código para ler um arquivo
	move		$a0, $s6		# descritor do arquivo
	la		$a1, buffer		# endereço do buffer
	move		$a2, $t4		# tamanho do buffer
	syscall					# lê o arquivo
	
sempadding:
	bne		$t0, $s0, loopY		# Se iguais, fim dos pixels verticais
	
	###############################################################
	# Fechando o arquivo
	li		$v0, 16			# código para fechar arquivo
	move		$a0, $s6		# descritor do arquivo
	syscall					# fecha o arquivo
