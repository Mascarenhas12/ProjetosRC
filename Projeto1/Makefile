TARGETS = client server

CC = gcc
CFLAGS = -Wall -Werror -O3

default : $( TARGETS )

%: %.o:

%: %.c
	$(CC) $(CFLAGS) -o src/$@ src/$<
clean :
	rm -f $(TARGETS)
