# ================================================
# IST LEIC-T Redes de Computadores 19/20
# Project1 - Makefile
#
# Authors:
# Gonçalo Freire		 - 90719
# Manuel Mascarenhas - 90751
# Miguel Levezinho   - 90756
# ================================================

default: server client

server: bin/server.o  bin/list.o
	gcc -g -O3 -Werror -Wall -o server bin/server.o  bin/list.o

client: bin/client.o
	gcc -g -O3 -Werror -Wall -o client bin/client.o

bin/server.o: src/server.c hdr/list.h
	gcc -g -O3 -Werror -Wall -c src/server.c -o bin/server.o

bin/client.o: src/client.c
	gcc -g -O3 -Werror -Wall -c src/client.c -o bin/client.o

bin/list.o: src/list.c hdr/list.h
	gcc -g -O3 -Werror -Wall -c src/list.c -o bin/list.o

clean:
	rm -f server bin/server.o
	rm -f client bin/client.o
	rm -f bin/list.o
