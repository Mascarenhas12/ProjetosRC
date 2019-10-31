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

chat-server: bin/chat-server.o  bin/list.o
	gcc -g -O3 -Werror -Wall -o chat-server bin/chat-server.o  bin/list.o

chat-client: bin/chat-client.o
	gcc -g -O3 -Werror -Wall -o chat-client bin/chat-client.o

bin/chat-server.o: src/chat-server.c hdr/list.h
	gcc -g -O3 -Werror -Wall -c src/chat-server.c -o bin/chat-server.o

bin/chat-client.o: src/chat-client.c
	gcc -g -O3 -Werror -Wall -c src/chat-client.c -o bin/chat-client.o

bin/list.o: src/list.c hdr/list.h
	gcc -g -O3 -Werror -Wall -c src/list.c -o bin/list.o

clean:
	rm -f chat-server bin/chat-server.o
	rm -f chat-client bin/chat-client.o
	rm -f bin/list.o
