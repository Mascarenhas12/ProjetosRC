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
#include "window.h"

#define MAX_CHUNK_SIZE 1000
#define MAX_SEQ_NUM 64


static ack_pkt_t build_ack_packet(int recv_seq, window_t* window, int* selective_acks)
{
	ack_pkt_t ack_packet;

	int i = 1;
	int w_base = get_base_w(window);

	if (recv_seq == w_base)
	{
		while (*selective_acks % 2)
		{
			*selective_acks /= 2;
			i++;
		}
		*selective_acks /= 2;
	}
	else
	{
		*selective_acks ^= (1 << (recv_seq - (w_base + 1)));
	}

	ack_packet.seq_num = advance_w(window, i);
	ack_packet.selective_acks = *selective_acks;

	return ack_packet;
}


static int insertWrite(data_pkt_t* chunk, FILE* fp)
{
	if (fseek(fp, MAX_CHUNK_SIZE * (chunk->seq_num - 1), SEEK_SET) == -1)
		return -1;

	if (fputs(chunk->data, fp) == -1)
		return -1;

	return 0;
}


static void exit_failure(int* exit_status, char* error_msg)
{
	perror(error_msg);
	*exit_status = -1;
}


int main(int argc, char const *argv[])
{
	int port;

	int receiverSock;
	struct sockaddr_in receiverSock_addr;
	struct sockaddr_storage senderSock_addr;
	socklen_t senderSock_addr_len;

	window_t* window;
	int selective_acks;

	data_pkt_t* chunk;
	ack_pkt_t ack_packet;

	FILE* fp;

	int exit_status;

	/* ======================================================================================== */
	/* Argument verification                                                                    */
	/* ======================================================================================== */


	if (argc < 4)
	{
		exit_failure(&exit_status, "file-receiver:Wrong number of arguments! <file> <port> <window_size>");
		exit(exit_status);
	}

	if ((port = atoi(argv[2])) > 65535)
	{
		exit_failure(&exit_status, "file-receiver:Invalid port number!");
		exit(exit_status);
	}

	if (atoi(argv[3]) > MAX_WINDOW_SIZE)
	{
		exit_failure(&exit_status, "file-receiver:Invalid window size!");
		exit(exit_status);
	}

	/* ======================================================================================== */
	/* Create and bind UDP socket                                                               */
	/* ======================================================================================== */


	if ((receiverSock = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
	{
		exit_failure(&exit_status, "file-receiver:Error creating receiver socket!");
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
		exit_failure(&exit_status, "file-receiver:Error while binding socket!");
		close(receiverSock);
		exit(exit_status);
	}

	/* ======================================================================================== */
	/* Open file and initialize variables                                                       */
	/* ======================================================================================== */


	if ((fp = fopen(argv[1], "wb+")) == NULL)
	{
		exit_failure(&exit_status, "file-receiver:Error opening file!");
		close(receiverSock);
		exit(exit_status);
	}

	chunk = (data_pkt_t*) malloc(sizeof(data_pkt_t));
	window = create_w(atoi(argv[3]), MAX_SEQ_NUM, 0);
	selective_acks = 0;
	exit_status = 0;

	puts("Server opened on port 1234!");


	/* ======================================================================================== */
	/* Receive and send loop                                                                    */
	/* ======================================================================================== */


	do
	{
		printf("Waiting for data...\n");
		if (recvfrom(receiverSock, (data_pkt_t*) chunk, sizeof(data_pkt_t), 0, (struct sockaddr*) &senderSock_addr, &senderSock_addr_len) == -1)
		{
			exit_failure(&exit_status, "file-receiver:Error while receiving!");
			break;
		}
		printf("RECV: %d SIZE: %lu\n", chunk->seq_num, sizeof(chunk->data));

		if (!contains_w(window, chunk->seq_num))
		{
			if (sendto(receiverSock, &ack_packet, sizeof(ack_pkt_t), 0, (struct sockaddr*) &senderSock_addr, senderSock_addr_len) == -1)
			{
				exit_failure(&exit_status, "file-receiver:Error while resending ACK!");
				break;
			}
		}
		else
		{
			if (insertWrite(chunk, fp) == -1)
			{
				exit_failure(&exit_status, "file-receiver:Error while seeking or writing in file!");
				break;
			}
			//printf("BEFORE:"); print_w(window);
			ack_packet = build_ack_packet(chunk->seq_num, window, &selective_acks);
			//printf("AFTER:"); print_w(window);

			printf("%d %d\n", ack_packet.seq_num, ack_packet.selective_acks);

			if (sendto(receiverSock, &ack_packet, sizeof(ack_pkt_t), 0, (struct sockaddr*) &senderSock_addr, senderSock_addr_len) == -1)
			{
				exit_failure(&exit_status, "file-receiver:Error while sending ACK!");
				break;
			}
		}
	}
	while (strlen(chunk->data) == MAX_CHUNK_SIZE);

	free_w(window);
	free(chunk);
	close(receiverSock);
	exit(exit_status);
}
