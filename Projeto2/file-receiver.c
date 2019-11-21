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
#include "packet-format.h"

#define MAX_CHUNK_SIZE 1000

int int main(int argc, char const *argv[])
{
	int port;
	int receiverSock;
	int senderSock;
	struct sockaddr_in receiverSock_addr;
	struct sockaddr_storage senderSock_addr;
	socklen_t senderSock_addr_len;

	int window_size;
	char pipeline[MAX_WINDOW_SIZE];
	data_pkt_t* chunk;

	int seq_num;
	int ack_mask;

	/* ======================================================================================== */
	/* Argument verification                                                                    */
	/* ======================================================================================== */

	if (argc < 4)
	{
		perror("file-receiver:Wrong number of arguments! <file> <port> <window_size>");
		exit(-1);
	}

	if ((port = atoi(argv[2])) > 65535)
	{
		perror("file-receiver:Invalid port number!");
		exit(-1);
	}

	if ((window_size = atoi(argv[4])) > MAX_WINDOW_SIZE)
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
	receiverSock_addr.sin_family = AF_INET;
	receiverSock_addr.sin_port = htons(port);
	receiverSock_addr.sin_addr.s_addr = INADDR_ANY;

	if ((bind(receiverSock, (struct sockaddr*) &receiverSock_addr, sizeof(receiverSock_addr))) == -1)
	{
		perror("file-receiver:Error while binding socket!");
		close(receiverSock);
		exit(-1);
	}

	seq_num = 0;
	ack_mask = 0;

	do
	{
		//ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags, struct sockaddr *src_addr, socklen_t *addrlen);
		if (recvfrom(receiverSock, (data_pkt_t*) chunk, sizeof(data_pkt_t), 0, (struct sockaddr*) &senderSock_addr, &senderSock_addr_len) == -1)
		{
			perror("file-receiver:Error while receiving!");
			close(receiverSock);
			exit(-1);
		}

		ack_pkt_t ack;
		ack.seq_num = ++seq_num;
		ack.selective_acks = 0;

		// ssize_t sendto(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen);
		if (sendto(receiverSock, &ack, sizeof(ack_pkt_t), 0, (struct sockaddr*) &senderSock_addr, &senderSock_addr_len) == -1)
		{
			perror("file-receiver:Error while sending ACK!");
			close(receiverSock);
			exit(-1);
		}
	} while (sizeof(chunk->data) == MAX_CHUNK_SIZE);


































	exit(0);
}