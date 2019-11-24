# ================================================
# IST LEIC-T Redes de Computadores 19/20
# Project2 - Makefile
#
# Authors:
# Gonçalo Freire     - 90719
# Manuel Mascarenhas - 90751
# Miguel Levezinho   - 90756
# ================================================

default: file-receiver file-sender

file-receiver: file-receiver.o  window.o
	gcc -g -O3 -Werror -Wall -o file-receiver file-receiver.o window.o

file-sender: file-sender.o
	gcc -g -O3 -Werror -Wall -o file-sender file-sender.o

file-receiver.o: file-receiver.c window.h
	gcc -g -O3 -Werror -Wall -c file-receiver.c -o file-receiver.o

file-sender.o: file-sender.c
	gcc -g -O3 -Werror -Wall -c file-sender.c -o file-sender.o

window.o: window.c window.h
	gcc -g -O3 -Werror -Wall -c window.c -o window.o

clean:
	rm -f file-receiver file-receiver.o
	rm -f file-sender file-sender.o
	rm -f window.o
