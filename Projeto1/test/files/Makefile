# ================================================
# IST LEIC-T Redes de Computadores 19/20
# Project1 - Makefile
#
# Authors:
# Gonçalo Freire		 - 90719
# Manuel Mascarenhas - 90751
# Miguel Levezinho   - 90756
# ================================================

default: chat-server chat-client

chat-server: chat-server.o  list.o
	gcc -g -O3 -Werror -Wall -o chat-server chat-server.o  list.o

chat-client: chat-client.o
	gcc -g -O3 -Werror -Wall -o chat-client chat-client.o

chat-server.o: chat-server.c list.h
	gcc -g -O3 -Werror -Wall -c chat-server.c -o chat-server.o

chat-client.o: chat-client.c
	gcc -g -O3 -Werror -Wall -c chat-client.c -o chat-client.o

list.o: list.c list.h
	gcc -g -O3 -Werror -Wall -c list.c -o list.o

clean:
	rm -f chat-server chat-server.o
	rm -f chat-client chat-client.o
	rm -f list.o
