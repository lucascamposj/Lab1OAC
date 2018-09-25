###############################################################
# Leitor de Imagem BitMap para Bitmap Display
###############################################################

.data
	header:		.space		54		# tamanho do header em bytes
	buffer:		.word		0	
	heap: 		.word   	0x10040000	# endereco do bitmap display
	
	nomeArquivoIn:	.asciiz		"img.bmp"
	nomeArquivoOut:	.asciiz 	"out.bmp"

.text

lerImagem:

	###############################################################
	# Abrindo o arquivo
	li		$v0, 13			# código para abrir arquivo
	la		$a0, nomeArquivoIn	# string com o nome do arquivo
	li		$a1, 0			# modo de abertura de arquivo
	li		$a2, 0			
	syscall					# abre o arquivo (descritor do arquivo em $v0)
	move		$s6, $v0		# salva o descritor do arquivo
	
	###############################################################
	# Salvando o Header
	li		$v0, 14			# código para ler um arquivo
	move		$a0, $s6		# descritor do arquivo
	la		$a1, header		# endereço do buffer
	li		$a2, 54			# tamanho do buffer
	syscall					# lê o arquivo
	
	###############################################################
	# Obtendo resolução
	li		$t0, 4
	move		$t1, $zero
res:	
	addi		$t0, $t0, -1
	sll 		$s2, $s2, 8
	sll 		$s1, $s1, 8
	sll 		$s0, $s0, 8
	
	lbu 		$t1, header+18($t0)	# $s0 - Quantidade de pixels verticais
	or 		$s0, $s0, $t1
	
	lbu		$t1, header+22($t0)	# $s1 - Quantidade de pixels horizontais
	or 		$s1, $s1, $t1
	
	lbu		$t1, header+34($t0)	# $s2 - Tamanho em bytes do bitmap 
	or 		$s2, $s2, $t1
	
	bnez 		$t0, res 		
	
	##############################################################
	# Abre espaço na pilha
	sub		$sp, $sp, $s2
	
	###############################################################
	# Salvando imagem na pilha
	li		$v0, 14			# código para ler um arquivo
	move		$a0, $s6		# descritor do arquivo
	move		$a1, $sp		# endereço do início da memória na pilha
	move		$a2, $s2		# tamanho do buffer
	syscall					# lê o arquivo
	
	###############################################################
	# Fechando o arquivo
	li		$v0, 16			# código para fechar arquivo
	move		$a0, $s6		# descritor do arquivo
	syscall					# fecha o arquivo
	
	###############################################################
	# Carregando imagem
	
	
	move		$t7, $sp		# contador geral do endereço na pilha
	andi		$t4, $s1, 0x00000003	# resX % 4 para descobrir o tamanho do padding
	
	move		$t0, $zero		# contador de pixels verticais
	
	lw		$s4, heap
loopY:
	addi		$t0, $t0, 1
	subu 		$t5, $s1, $t0
	sll 		$t5, $t5, 2
	mul		$t5, $t5, $s0
	addu		$t5, $t5, $s4
						# 4 * X * (Y - t0)
	
	move		$t1, $zero		# contador de pixels horizontais
	loopX:
		addi		$t1, $t1, 1
		
		move		$t3, $zero		# word do pixel
		move		$t6, $zero		# word auxiliar
		li		$t2, 3
		addi		$t7, $t7, 3
		#obtem pixel RGB
		loopRGB:
			addi		$t2, $t2, -1
			addi		$t7, $t7, -1
			
			sll		$t3, $t3, 8
			lbu		$t6, ($t7)
			or		$t3, $t3, $t6
			
			bnez 		$t2, loopRGB
		
		# salva pixel na memória		
		sw		$t3, ($t5)
		addi 		$t5, $t5, 4
		addiu		$t7, $t7, 3
	
		bne		$t1, $s1, loopX		# Se iguais, fim dos pixels horizontais
	
	# Tratar padding
	beqz		$t4, sempadding
	
	add		$t7, $t7, $t4
	
sempadding:
	bne		$t0, $s0, loopY		# Se iguais, fim dos pixels verticais
	
	###############################################################
	# Carregando novo BitMap da heap na memória
	
	move		$t7, $sp		# contador geral do endereço na pilha
	andi		$t4, $s1, 0x00000003	# resX % 4 para descobrir o tamanho do padding
	
	move		$t0, $zero		# contador de pixels verticais
	
	lw		$s4, heap
loopY2:
	addi		$t0, $t0, 1
	subu 		$t5, $s1, $t0
	sll 		$t5, $t5, 2
	mul		$t5, $t5, $s0
	addu		$t5, $t5, $s4
						# 4 * X * (Y - t0)
	
	move		$t1, $zero		# contador de pixels horizontais
	loopX2:
		addi		$t1, $t1, 1
		
		move		$t3, $zero		# word do pixel
		
		# obtem pixel da memória		
		lw		$t3, ($t5)
		
		li		$t2, 3
		addi		$t7, $t7, 0
		# salva pixel RGB
		loopRGB2:
			addi		$t2, $t2, -1
			
			
			sb		$t3, ($t7)
			srl 		$t3, $t3, 8
			
			addi		$t7, $t7, 1
			
			bnez 		$t2, loopRGB2
		
		addi 		$t5, $t5, 4
		#addiu		$t7, $t7, 0
			
		bne		$t1, $s1, loopX2		# Se iguais, fim dos pixels horizontais
	
	# Tratar padding
	beqz		$t4, sempadding2
	
	add		$t7, $t7, $t4
	
sempadding2:
	bne		$t0, $s0, loopY2		# Se iguais, fim dos pixels verticais

	###############################################################
	# Abrindo o arquivo
	li		$v0, 13			# código para abrir arquivo
	la		$a0, nomeArquivoOut	# string com o nome do arquivo
	li		$a1, 1			# modo de abertura de arquivo - Escrita
	li		$a2, 0			
	syscall					# abre o arquivo (descritor do arquivo em $v0)
	move		$s6, $v0		# salva o descritor do arquivo
	
	###############################################################
	# Escreve o Header
	li		$v0, 15			# código para ler um arquivo
	move		$a0, $s6		# descritor do arquivo
	la		$a1, header		# endereço do buffer
	li		$a2, 54			# tamanho do buffer
	syscall					# lê o arquivo
	
	###############################################################
	# Escreve o BitMap
	li		$v0, 15			# código para ler um arquivo
	move		$a0, $s6		# descritor do arquivo
	move		$a1, $sp		# endereço do buffer
	move		$a2, $s2		# tamanho do buffer
	syscall					# lê o arquivo
	


