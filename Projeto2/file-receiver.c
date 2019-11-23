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

ack_pkt_t createAckPacket(uint32_t selective, uint32_t seq){
	ack_pkt_t new;

	new.seq_num = seq;
	new.selective_acks = selective;

	return new;
}

uint32_t advanceWindow(char* pipeline, uint32_t window_base, int window_size){
	for(uint32_t i = window_base;i < window_base + window_size;i++){
		if(!pipeline[i]){
			return i;
		}
		pipeline[i] = 0;
	}
	printf("Advance:%d\n", window_base+window_size);
	return window_base+window_size;
}

void insertWrite(data_pkt_t* chunk, FILE* fp){
	if(fseek(fp,MAX_CHUNK_SIZE*(chunk->seq_num -1),SEEK_SET) ==-1){
		perror("file-receiver:Error while seeking in file!");
		exit(-1);
	}

	if(fputs(chunk->data,fp) == -1){
		perror("file-receiver:Error while writing in file!");
		exit(-1);
	}
}

int main(int argc, char const *argv[])
{
	int port;
	int receiverSock;
	struct sockaddr_in receiverSock_addr;
	struct sockaddr_storage senderSock_addr;
	socklen_t senderSock_addr_len;

	int window_size;
	uint32_t window_base;
	char pipeline[1000000];
	data_pkt_t* chunk = (data_pkt_t*)malloc(sizeof(data_pkt_t));
	FILE* fp;

	//int seq_num;
	//int ack_mask;

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

	if ((window_size = atoi(argv[3])) > MAX_WINDOW_SIZE)
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

	//seq_num = 0;
	//ack_mask = 0;
	window_base = 1;
	fp = fopen(argv[1], "w+");
	if (fp == NULL) return -1;
	memset(pipeline,0,sizeof(pipeline));
	puts("Server opened on port 1234!");

	do
	{
		//ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags, struct sockaddr *src_addr, socklen_t *addrlen);
		if (recvfrom(receiverSock, (data_pkt_t*) chunk, sizeof(data_pkt_t), 0, (struct sockaddr*) &senderSock_addr, &senderSock_addr_len) == -1)
		{
			perror("file-receiver:Error while receiving!");
			close(receiverSock);
			exit(-1);
		}

		printf("%d\n", chunk->seq_num);
		printf("%d %d %d\n", !pipeline[chunk->seq_num],chunk->seq_num>= window_base,chunk->seq_num <= window_base+window_size);
		//Confirmar com o miguel que o pipeline diz se ja recebeu o pckt
		if(!pipeline[chunk->seq_num] && chunk->seq_num >= window_base && chunk->seq_num <= window_base+window_size){
			insertWrite(chunk,fp);
			pipeline[chunk->seq_num] = 1;
			puts("wrote");
		}

		if(chunk->seq_num == window_base){
			window_base = advanceWindow(pipeline,window_base,window_size);
			puts("advanced");
		}

		//Confirmar com o miguel como selective a mandar
		ack_pkt_t ack = createAckPacket(0, window_base);

		// ssize_t sendto(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen);
		if (sendto(receiverSock, &ack, sizeof(ack_pkt_t), 0, (struct sockaddr*) &senderSock_addr, senderSock_addr_len) == -1)
		{
			perror("file-receiver:Error while sending ACK!");
			close(receiverSock);
			exit(-1);
		}
	} while (strlen(chunk->data) == MAX_CHUNK_SIZE);
	fclose(fp);
	return 0;
}
