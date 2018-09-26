###############################################################
# Leitor de Imagem BitMap para Bitmap Display
###############################################################

.data
	header:		.space		54		# tamanho do header em bytes
	buffer:		.word		0	
	heap: 		.word   	0x10040000	# endereco do bitmap display
	
	msgCarregando:	.asciiz 	"Carregando imagem...\n"
	fimCarregando:	.asciiz 	"Carregamento feito!\n\n"
	opção1:		.asciiz 	"############ Menu ############\n1) Mostrar imagem no display"
	opção2:		.asciiz 	"2) Aplicar filtro 1"
	opção3:		.asciiz 	"3) Aplicar filtro 2"
	opção4:		.asciiz 	"4) Aplicar filtro 3"
	opção5:		.asciiz 	"5) Voltar a imagem original"
	opção6:		.asciiz 	"6) Exportar imagem"
	
	nomeArquivoIn:	.asciiz		"img.bmp"
	nomeArquivoOut:	.asciiz 	"out.bmp"

.text
	jal		Importar
	###############################################################
	# MENU
	
	jal		Display
	jal		Blur
	jal		Display
	jal		Exportar
	
	j		FIM	
	
Importar:
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
	# Obtendo informações
	li		$t0, 4			# contador
	move		$t1, $zero		# auxiliar
	
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
	
	andi		$s3, $s1, 0x00000003	# resX % 4 para descobrir o tamanho do padding	
	
	###############################################################
	# Abre espaço na memória
	sub		$sp, $sp, $s2		# Abre espaço na pilha
	move		$s5, $sp		# salva endereço da imagem contida na pilha (formato Bitmap)
	
	###############################################################
	# Salvando imagem na pilha
	li		$v0, 14			# código para ler um arquivo
	move		$a0, $s6		# descritor do arquivo
	move		$a1, $s5		# endereço do início da memória na pilha
	move		$a2, $s2		# tamanho do buffer
	syscall					# lê o arquivo
	
	###############################################################
	# Fechando o arquivo
	li		$v0, 16			# código para fechar arquivo
	move		$a0, $s6		# descritor do arquivo
	syscall					# fecha o arquivo
	
	jr		$ra
	
Display:
	
	###############################################################
	# Carregando imagem
	lw		$s4, heap		# salva endereço da imagem contida na heap (formato bitmap display)
	
	move		$t7, $s5		# contador geral do endereço na pilha
	
	move		$t0, $zero		# inicializa contador de pixels verticais
	loopY:
		addi		$t0, $t0, 1		# incrementa contador de pixels verticais
	
		subu 		$t5, $s1, $t0		# Calculo da posição - 4 * X * (Y - t0)
		sll 		$t5, $t5, 2
		mul		$t5, $t5, $s0
	
		addu		$t5, $t5, $s4		# soma a posição ao endereço inicial
						
		move		$t1, $zero		# inicializa contador de pixels horizontais
		loopX:
			addi		$t1, $t1, 1		# incrementa contador de pixels verticais
		
			move		$t3, $zero		# inicializa word do pixel
			move		$t6, $zero		# inicializa word auxiliar
		
			move		$t2, $t7		# salva posição do pixel
			addi		$t7, $t7, 3		# salta o contador para o fim do pixel RGB
		
			#obtem pixel RGB
			loopRGB:
				addi		$t7, $t7, -1		# reposiciona ponteiro para próxima cor
			
				sll		$t3, $t3, 8		# prepara word word para próxima cor
				lbu		$t6, ($t7)		# obtem cor
				or		$t3, $t3, $t6		# armazena na word
			
				bne  		$t2, $t7 , loopRGB
			addiu		$t7, $t7, 3
		
			# salva pixel na memória		
			sw		$t3, ($t5)		# salva word
			addi 		$t5, $t5, 4
	
			bne		$t1, $s1, loopX		# Se iguais, fim dos pixels horizontais
	
		# Tratar padding
		add		$t7, $t7, $s3		# reposiciona ponteiro para pular padding
		
	bne		$t0, $s0, loopY		# Se iguais, fim dos pixels verticais
	
	jr		$ra
	
Exportar:
	
	###############################################################
	# Carregando novo BitMap da heap na memória da imagem
	
	move		$t7, $s5		# contador geral do endereço na pilha
	move		$t0, $zero		# contador de pixels verticais
	
	loopY2:						
		addi		$t0, $t0, 1		# incrementa contador de pixels verticais
	
		subu 		$t5, $s1, $t0		# Calculo da posição - 4 * X * (Y - t0)
		sll 		$t5, $t5, 2
		mul		$t5, $t5, $s0
	
		addu		$t5, $t5, $s4		# soma a posição ao endereço inicial
	
		move		$t1, $zero		# contador de pixels horizontais
		loopX2:
			addi		$t1, $t1, 1
			
			move		$t3, $zero		# word do pixel
		
			# obtem pixel da memória		
			lw		$t3, ($t5)
			addi 		$t5, $t5, 4
		
			move		$t2, $t7
			addi		$t2, $t2, 3
			# salva pixel RGB
			loopRGB2:
				sb		$t3, ($t7)
				srl 		$t3, $t3, 8
			
				addi		$t7, $t7, 1
			
				bne 		$t2, $t7, loopRGB2
			
			bne		$t1, $s1, loopX2		# Se iguais, fim dos pixels horizontais
	
		# Tratar padding
		add		$t7, $t7, $s3

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
	li		$v0, 15			# código para escrever em um arquivo
	move		$a0, $s6		# descritor do arquivo
	la		$a1, header		# endereço do buffer
	li		$a2, 54			# tamanho do buffer
	syscall					# lê o arquivo
	
	###############################################################
	# Escreve o BitMap
	li		$v0, 15			# código para escrever em um arquivo
	move		$a0, $s6		# descritor do arquivo
	move		$a1, $s5		# endereço do buffer
	move		$a2, $s2		# tamanho do buffer
	syscall					# escreve no arquivo
	
	jr		$ra
	
Blur:
	li		$a0, 5
	
	move		$a1, $a0
	mul		$a1, $a1, $a1 		# $a1 armazena a quantidade de pixels por janela
	
	srl		$a2, $a0, 1			# Divide tam da janela por 2
	
	
	move		$t0, $zero		# inicializa contador de pixels verticais
	blurY:	
		move		$t1, $zero		# inicializa contador de pixels horizontais
		blurX:
			move		$t7, $zero
			move		$t8, $zero
			move		$t9, $zero
			
			
			move		$t2, $zero
			janelaY:
				
				move		$t3, $zero
				janelaX:
										
 					#  if (0 < (t0 - a0 + t2) < $s0) and (0 < (t1 - a0 + t3) < $s1)
 					sub		$t4, $t0, $a2		# $t4 -> posY 
 					add		$t4, $t4, $t2
 					bltz  		$t4, Borda
					bge  		$t4, $s0, Borda
					
					sub		$t5, $t1, $a2		# $t5 -> posX
 					add		$t5, $t5, $t3
 					bltz  		$t5, Borda
					bge  		$t5, $s1, Borda
					
					# Pega pixel e acumula na memória
					# Localização pixel na heap -> 4(posX + $s1 * posY)
					mul		$t6, $s1, $t4
					add		$t6, $t6, $t5
					sll		$t6, $t6, 2
					add		$t6, $t6, $s4
					
					move		$t4, $zero
					
					# Acumula cada cor
					lw		$t6, ($t6)
					
					and		$t4, $t6, 0x000000FF
					add		$t7, $t7, $t4 
					srl		$t6, $t6, 8
					
					and		$t4, $t6, 0x000000FF
					add		$t8, $t8, $t4
					srl		$t6, $t6, 8
					
					and		$t4, $t6, 0x000000FF
					add		$t9, $t9, $t4
					
					Borda:
				addi		$t3, $t3, 1
				blt 		$t3, $a0, janelaX
				# FIM janelaX
				
			addi		$t2, $t2, 1
			blt		$t2, $a0, janelaY
			#FIM janelaY
			
			# Divide pixel e  armazena
			divu		$t7, $t7, $a1
			divu		$t8, $t8, $a1
			divu		$t9, $t9, $a1
			
			# Salvar pixel no local -> (Y - 1 - y)(Padding + 3X) + 3x
			addi		$t4, $s0, -1
			sub		$t4, $t4, $t0
			
			mul 		$t5, $s1, 3
			add		$t5, $t5, $s3
			
			mul		$t4, $t4, $t5
			mul 		$t5, $t1, 3
			add		$t4, $t4, $t5
			
			add		$t4, $t4, $s5
			
			sb		$t7, 0($t4)
			sb		$t8, 1($t4)
			sb		$t9, 2($t4)
			
	
		addi		$t1, $t1, 1		# incrementa contador de pixels horizontas
		blt 		$t1, $s1, blurX		# Enquanto $t1 < $s1
		# FIM BlurX
		
	addi		$t0, $t0, 1			
	blt		$t0, $s0, blurY		# Enquanto $t0 < $s0
	# FIM	BlurY
	
	jr		$ra

FIM:
	###############################################################
	# Fim do programa
	li		$v0, 10			# código para fechar arquivo
	syscall	
