/* ================================================
 * IST LEIC-T Redes de Computadores 19/20
 * Project2 - file-receiver.c
 *
 * Authors:
 * Gonçalo Freire     - 90719
 * Manuel Mascarenhas - 90751
 * Miguel Levezinho   - 90756
 * ================================================
 */

#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#define MAX_WINDOW_SIZE 32
#define CHUNK_SIZE 1000

int int main(int argc, char const *argv[])
{
	int port;
	int receiverSock;
	int senderSock;
	struct sockaddr_in receiverSock_addr;
	struct sockaddr_storage senderSock_addr;
	socklen_t senderSock_addr_len;

	int n;
	char chunk[CHUNK_SIZE];

	/* ======================================================================================== */
	/* Argument verification                                                                    */
	/* ======================================================================================== */

	if (argc < 4)
	{
		perror("file-receiver:Wrong number of arguments! <file> <port> <window_size>");
		exit(-1);
	}

	if ((port = atoi(argv[3])) > 65535)
	{
		perror("file-receiver:Invalid port number!");
		exit(-1);
	}

	if (atoi(argv[4]) > MAX_WINDOW_SIZE)
	{
		perror("file-receiver:Invalid window size!");
		exit(-1);
	}

	/* ======================================================================================== */
	/* Create UDP socket                                                                        */
	/* ======================================================================================== */

	if ((receiverSock = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
	{
		perror("file-receiver:Error creating receiver socket!");
		exit(-1);
	}

	memset(&senderSock_addr, 0, sizeof(senderSock_addr));
	senderSock_addr_len = sizeof(struct sockaddr_storage);

	memset(&receiverSock_addr, 0, sizeof(receiverSock_addr));
	serverSock_addr.sin_family = AF_INET;
	serverSock_addr.sin_port = htons(port);
	serverSock_addr.sin_addr.s_addr = INADDR_ANY;

	if ((bind(receiverSock, (struct sockaddr*) &receiverSock_addr, sizeof(receiverSock_addr))) == -1)
	{
		perror("file-receiver:Error while binding socket!");
		close(receiverSock);
		exit(-1);
	}

	//ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags, struct sockaddr *src_addr, socklen_t *addrlen);
	if ((n = recvfrom(receiverSock, (char*) chunk, CHUNK_SIZE, 0, (struct sockaddr*) &senderSock_addr, &senderSock_addr_len)) == -1)
	{
		perror("file-receiver:Error while receiving!");
		close(receiverSock);
		exit(-1);
	}

	// ssize_t sendto(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen);
	if (sendto(receiverSock, (char*) b, CHUNK_SIZE, 0, (struct sockaddr*) &senderSock_addr, &senderSock_addr_len) == -1)
	{
		perror("file-receiver:Error while sending ACK!");
		close(receiverSock);
		exit(-1);
	}


































	exit(0);
}