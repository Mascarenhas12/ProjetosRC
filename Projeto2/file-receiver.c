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

#include <arpa/inet.h>
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
	int w_size = get_size_w(window);

	if (recv_seq >= w_base && recv_seq < w_base + w_size)
	{
		if (recv_seq == w_base)
		{
			while (*selective_acks % 2)
			{
				*selective_acks /= 2;
				i++;
			}
			*selective_acks /= 2;

			ack_packet.seq_num = htonl(advance_w(window, i));
		}
		else
		{
			*selective_acks |= (1 << (recv_seq - (w_base + 1)));
			ack_packet.seq_num = htonl(w_base);
		}
	}
	else
	{
		ack_packet.seq_num = htonl(w_base);
	}

	ack_packet.selective_acks = htonl(*selective_acks);

	return ack_packet;
}


static int write_file_chunk(char* buffer, int cursor, int data_size, FILE* fp)
{
	if (fseek(fp, cursor * MAX_CHUNK_SIZE, SEEK_SET) == -1)
		return -1;

	if (fwrite(buffer, 1, data_size, fp) < data_size && ferror(fp))
		return -1;

	return 0;
}


static int valid_sender(int* sender_port, uint32_t* sender_host, struct sockaddr_in* senderSock_addr)
{
	if (*sender_port == -1)
	{
		*sender_port = ntohs(senderSock_addr->sin_port);
		*sender_host = senderSock_addr->sin_addr.s_addr;
	}
	else if (senderSock_addr->sin_addr.s_addr != *sender_host ||
	ntohs(senderSock_addr->sin_port) != *sender_port)
	{
		return 0;
	}

	return 1;
}


int main(int argc, char const *argv[])
{
	/* ======================================================================================== */
	/* Variables declaration                                                                    */
	/* ======================================================================================== */

	int port;
	int sender_port;
	uint32_t sender_host;

	FILE* fp;

	int receiverSock;
	struct sockaddr_in receiverSock_addr;
	struct sockaddr_in senderSock_addr;
	socklen_t senderSock_addr_len;

	window_t* window;
	int selective_acks;
	int last_packet_sn;

	int bytes_recv;
	data_pkt_t* chunk;
	ack_pkt_t ack_packet;

	int exit_status;

	/* ======================================================================================== */
	/* Basic argument verification                                                              */
	/* ======================================================================================== */
	puts("Start!");

	if (argc != 4)
	{
		perror("file-receiver:Wrong number of arguments! <file> <port> <window_size>");
		exit(-1);
	}

	if ((port = atoi(argv[2])) > 65535 || port < 0)
	{
		perror("file-receiver:Invalid port number!");
		exit(-1);
	}

	if (atoi(argv[3]) > MAX_WINDOW_SIZE || atoi(argv[3]) <= 0)
	{
		perror("file-receiver:Invalid window size!");
		exit(-1);
	}

	/* ======================================================================================== */
	/* Create and bind UDP socket                                                               */
	/* ======================================================================================== */


	if ((receiverSock = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
	{
		perror("file-receiver:Error creating receiver socket!");
		exit(-1);
	}

	memset(&senderSock_addr, 0, sizeof(senderSock_addr));
	senderSock_addr_len = sizeof(struct sockaddr_in);
	sender_port = -1;
	sender_host = -1;

	memset(&receiverSock_addr, 0, sizeof(receiverSock_addr));
	receiverSock_addr.sin_family = AF_INET;
	receiverSock_addr.sin_port = htons(port);
	receiverSock_addr.sin_addr.s_addr = INADDR_ANY;

	if (setsockopt(receiverSock, SOL_SOCKET, SO_REUSEADDR, &(int){1}, sizeof(int)) == -1)
	{
		perror("file-receiver:Error setting socket options!");
		close(receiverSock);
		exit(-1);
	}

	if ((bind(receiverSock, (struct sockaddr*) &receiverSock_addr, sizeof(receiverSock_addr))) == -1)
	{
		perror("file-receiver:Error while binding socket!");
		close(receiverSock);
		exit(-1);
	}

	/* ======================================================================================== */
	/* Open file and initialize variables                                                       */
	/* ======================================================================================== */


	if ((fp = fopen(argv[1], "wb+")) == NULL)
	{
		perror("file-receiver:Error opening file!");
		close(receiverSock);
		exit(-1);
	}

	chunk = (data_pkt_t*) malloc(sizeof(data_pkt_t));
	window = create_w(atoi(argv[3]), -1, 0);
	selective_acks = 0;
	last_packet_sn = -1;
	exit_status = 0;

	puts("Server opened on port 1234.");


	/* ======================================================================================== */
	/* Receive and send loop                                                                    */
	/* ======================================================================================== */

	printf("FR - WINDOW: "); print_w(window);
	fflush(stdout);
	do
	{
		printf("FR - Waiting for data...\n");
		fflush(stdout);
		if ((bytes_recv = recvfrom(receiverSock, (data_pkt_t*) chunk, sizeof(data_pkt_t), 0,
		(struct sockaddr*) &senderSock_addr, &senderSock_addr_len)) == -1)
		{
			perror("file-receiver:Error while receiving!");
			exit_status = -1;
			break;
		}

		if (!valid_sender(&sender_port, &sender_host, &senderSock_addr))
		{
			printf("FR - RECV FROM OTHER SENDER. WILL IGNORE\n");
			continue;
		}

		puts("Received!");
		fflush(stdout);
		chunk->seq_num = ntohl(chunk->seq_num);

		printf("FR - RECV: %d SIZE: %d\n", chunk->seq_num, bytes_recv - 4);
		fflush(stdout);

		if (contains_w(window, chunk->seq_num))
		{
			if (write_file_chunk(chunk->data, chunk->seq_num - 1, bytes_recv - sizeof(int), fp) == -1)
			{
				perror("file-receiver:Error while seeking or writing in file!");
				exit_status = -1;
				break;
			}
		}

		ack_packet = build_ack_packet(chunk->seq_num, window, &selective_acks);

		printf("FR - WINDOW: "); print_w(window);

		if (sendto(receiverSock, &ack_packet, sizeof(ack_pkt_t), 0,
		(struct sockaddr*) &senderSock_addr, senderSock_addr_len) == -1)
		{
			perror("file-receiver:Error while sending ACK!");
			exit_status = -1;
			break;
		}
		printf("FR - SENT: %d S_ACK: %d\n", ntohl(ack_packet.seq_num), ntohl(ack_packet.selective_acks));

		fflush(stdout);
		if (bytes_recv != sizeof(data_pkt_t))
			last_packet_sn = chunk->seq_num;
	}
	while (last_packet_sn == -1 || get_base_w(window) <= last_packet_sn);

	if (exit_status != -1)
		puts("Finished receiving data.");

	free_w(window);
	free(chunk);
	close(receiverSock);
	exit(exit_status);
}
