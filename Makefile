mandel: mandel.o
	ld -o mandel mandel.o

mandel.o:
	nasm -g -f elf64 -l mandel.lst mandel.asm 



